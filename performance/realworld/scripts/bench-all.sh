#!/usr/bin/env bash
# Load-test every Conduit implementation and write raw JSON plus a summary.
#
# Defaults are the published run: 10s warmup, 30s measure, 3 repetitions,
# concurrency 1, 16, 64, and 256. Each point reseeds the database.
#
#   BENCH_WARMUP=10 BENCH_DURATION=30 BENCH_REPEATS=3
#   BENCH_CONCURRENCY="1 16 64 256"
#   BENCH_SCENARIOS="list slug feed login create favorite mixed"
#   BENCH_OUT=realworld/bench/results
#   SERVER_CPUS=0-3 K6_CPUS=4-7 PG_CPUS=8-15 CONDUIT_PG_CONTAINER=conduit-pg
#   CONDUIT_PG_PORT=54329 BENCH_NO_SUMMARY=1 (scripts/bench-parallel.sh sets these)
#   ./bench-all.sh [fastapi|go|fastify|rust-h5i-optimized|rust-h5i ...]
#
# rust-h5i keeps its rows in h5i-app's own tables (schema conduit); each
# point loads seed.sql and then copies it there (bench/seed_h5i_app.sql).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PG_CONTAINER="${CONDUIT_PG_CONTAINER:-conduit-pg}"
export DATABASE_URL="${DATABASE_URL:-postgres://conduit:conduit@127.0.0.1:${CONDUIT_PG_PORT:-54329}/conduit}"
SERVER_CPUS="${SERVER_CPUS:-0-3}"
K6_CPUS="${K6_CPUS:-4-7}"
export JWT_SECRET="${JWT_SECRET:-conduit-benchmark-secret}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/var/tmp/rw-target}"
K6="${K6:-/var/tmp/tools/k6}"
PY="${PY:-/var/tmp/rw-fastapi-venv/bin/python}"
OUT="${BENCH_OUT:-$ROOT/bench/results}"
WARMUP="${BENCH_WARMUP:-10}"
DURATION="${BENCH_DURATION:-30}"
REPEATS="${BENCH_REPEATS:-3}"
CONCURRENCIES="${BENCH_CONCURRENCY:-1 16 64 256}"
SCENARIOS="${BENCH_SCENARIOS:-list slug feed login create favorite mixed}"
LOG_DIR="${LOG_DIR:-/var/tmp/rw-logs}"
# bcrypt cost 12 of password123. Same hash on every seed.
HASH='$2b$12$iqGgOt4pkKoY.6s31.69rOVX2v.VemPSDFrDUk/AzZdKwqoXHjy8S'
mkdir -p "$OUT" "$LOG_DIR"
echo $$ > "$LOG_DIR/bench-all.pid"

if [ "$#" -eq 0 ]; then
  set -- fastapi go fastify rust-h5i-optimized
fi

"$ROOT/scripts/up-db.sh" >/dev/null

seed_db() {
  docker exec -i "$PG_CONTAINER" psql -U conduit -d conduit -v ON_ERROR_STOP=1 \
    -v hash="$HASH" < "$ROOT/bench/seed.sql" >/dev/null
  if [ "${1:-}" = rust-h5i ]; then
    docker exec -i "$PG_CONTAINER" psql -U conduit -d conduit -v ON_ERROR_STOP=1 \
      < "$ROOT/bench/seed_h5i_app.sql" >/dev/null
  fi
}

TOKEN="$("$PY" - <<'PY'
import os, time, jwt
print(jwt.encode(
    {"sub": "1", "exp": int(time.time()) + 60 * 24 * 3600},
    os.environ["JWT_SECRET"],
    algorithm="HS256",
))
PY
)"

server_pid=""
cleanup() {
  if [ -n "${server_pid:-}" ]; then
    kill -- -"$server_pid" >/dev/null 2>&1 || kill "$server_pid" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

wait_health() {
  local port="$1"
  local i
  for i in $(seq 1 120); do
    if curl -sf "http://127.0.0.1:${port}/healthz" >/dev/null; then
      return 0
    fi
    sleep 0.5
  done
  echo "POINT_FAIL server on port $port did not become ready" >&2
  return 1
}

free_port() {
  local port="$1"
  local pids
  pids="$(ss -lptn "sport = :$port" 2>/dev/null | awk -F'pid=' 'NR>1 {split($2,a,","); print a[1]}' | sort -u || true)"
  local pid
  for pid in $pids; do
    if [ -n "$pid" ]; then
      kill -- -"$pid" >/dev/null 2>&1 || kill "$pid" >/dev/null 2>&1 || true
    fi
  done
}

start_server() {
  local name="$1"
  local port="$2"
  local dir="$3"
  cleanup
  server_pid=""
  free_port "$port"
  sleep 0.3
  case "$name" in
    fastapi|fastify)
      export WEB_CONCURRENCY=4
      export DB_POOL=8
      ;;
    go|rust-h5i-optimized|rust-h5i)
      export WEB_CONCURRENCY=4
      export DB_POOL=32
      ;;
  esac
  export PORT="$port"
  setsid taskset -c "$SERVER_CPUS" "$dir/run.sh" > "$LOG_DIR/bench-${name}.log" 2>&1 &
  server_pid=$!
  wait_health "$port"
}

run_k6() {
  local seconds="$1"
  local summary="$2"
  taskset -c "$K6_CPUS" "$K6" run \
    --quiet \
    --summary-export "$summary" \
    --summary-trend-stats 'avg,p(50),p(90),p(99)' \
    -e "BASE=$BASE" \
    -e "TOKEN=$TOKEN" \
    -e "SCENARIO=$scenario" \
    -e "VUS=$conc" \
    -e "DURATION=${seconds}s" \
    "$ROOT/bench/workload.js" >/dev/null
}

prebuild() {
  if printf '%s\n' "$@" | grep -qx rust-h5i-optimized; then
    (cd "$ROOT/rust-h5i-optimized" && cargo build --release -p conduit-server -p conduit-kernel-bench)
  fi
  if printf '%s\n' "$@" | grep -qx rust-h5i; then
    (cd "$ROOT/rust-h5i" && CARGO_TARGET_DIR="${H5I_APP_TARGET_DIR:-/var/tmp/rw-target-h5i-app}" cargo build --release)
  fi
}

kernel_bench() {
  local bin="$CARGO_TARGET_DIR/release/kernel-bench"
  if [ ! -x "$bin" ]; then
    (cd "$ROOT/rust-h5i-optimized" && cargo build --release -p conduit-kernel-bench)
  fi
  local i
  : > "$OUT/kernel-bench.jsonl"
  for i in 1 2 3; do
    taskset -c "$SERVER_CPUS" "$bin" >> "$OUT/kernel-bench.jsonl"
  done
}

prebuild "$@"

for name in "$@"; do
  case "$name" in
    fastapi) port=8001; dir="$ROOT/fastapi" ;;
    go) port=8002; dir="$ROOT/go" ;;
    fastify) port=8003; dir="$ROOT/fastify" ;;
    rust-h5i-optimized) port=8004; dir="$ROOT/rust-h5i-optimized" ;;
    rust-h5i) port=8005; dir="$ROOT/rust-h5i" ;;
    *) echo "unknown implementation: $name" >&2; exit 2 ;;
  esac
  echo "START $name :$port"
  start_server "$name" "$port" "$dir"
  BASE="http://127.0.0.1:${port}"
  for scenario in $SCENARIOS; do
    for conc in $CONCURRENCIES; do
      for rep in $(seq 1 "$REPEATS"); do
        tag="${name}_${scenario}_c${conc}_r${rep}"
        echo "SEED $tag"
        seed_db "$name"
        if ! curl -sf "$BASE/healthz" >/dev/null; then
          echo "POINT_FAIL $tag server died; restarting" >&2
          start_server "$name" "$port" "$dir"
        fi
        run_k6 "$WARMUP" "$LOG_DIR/warmup-${tag}.json" || true
        meta_tmp="$OUT/${tag}.meta.json"
        summary="$OUT/${tag}.summary.json"
        "$PY" -u "$ROOT/bench/sample_proc.py" "$server_pid" > "$meta_tmp.sample" &
        sampler=$!
        if ! run_k6 "$DURATION" "$summary"; then
          echo "POINT_FAIL $tag k6 exited non-zero" >&2
        fi
        kill "$sampler" >/dev/null 2>&1 || true
        wait "$sampler" >/dev/null 2>&1 || true
        "$PY" - "$meta_tmp" "$meta_tmp.sample" "$name" "$scenario" "$conc" "$rep" "$WARMUP" "$DURATION" <<'PY'
import json, sys
dest, sample, impl, scenario, conc, rep, warmup, duration = sys.argv[1:]
try:
    stats = json.load(open(sample))
except Exception:
    stats = {"rss_peak_kb": 0, "cpu_peak_pct": 0, "cpu_avg_pct": 0}
stats.update({
    "impl": impl,
    "scenario": scenario,
    "concurrency": int(conc),
    "rep": int(rep),
    "warmup_s": int(warmup),
    "duration_s": int(duration),
})
json.dump(stats, open(dest, "w"))
print("POINT", impl, scenario, "c="+conc, "r="+rep,
      "rss_kb="+str(stats["rss_peak_kb"]),
      "cpu_peak="+str(stats["cpu_peak_pct"]))
PY
        rm -f "$meta_tmp.sample"
        # Flag a high HTTP failure rate without stopping the sweep.
        "$PY" - "$summary" "$tag" <<'PY'
import json, sys
path, tag = sys.argv[1:]
try:
    data = json.load(open(path))
except Exception:
    print(f"POINT_FAIL {tag} missing summary", flush=True)
    raise SystemExit(0)
failed = data.get("metrics", {}).get("http_req_failed", {})
rate = float(failed.get("value", 0) or 0)
if rate > 0.01:
    print(f"POINT_FAIL {tag} http_req_failed={rate:.4f} passes={failed.get('passes')}", flush=True)
PY
      done
    done
  done
  cleanup
  server_pid=""
done

if printf '%s\n' "$@" | grep -qx rust-h5i-optimized || [ "$#" -eq 4 ]; then
  kernel_bench || echo "POINT_FAIL kernel-bench" >&2
fi

if [ -z "${BENCH_NO_SUMMARY:-}" ]; then
  "$PY" "$ROOT/bench/summarize.py" "$OUT"
fi
echo "BENCH_DONE $OUT"
