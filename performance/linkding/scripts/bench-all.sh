#!/usr/bin/env bash
# Load-test every linkding implementation and write raw JSON plus a summary.
#
# Defaults are the published run: 10s warmup, 30s measure, 3 repetitions,
# concurrency 1, 16, 64, and 256. Each point reseeds the database.
#
#   BENCH_WARMUP=10 BENCH_DURATION=30 BENCH_REPEATS=3
#   BENCH_CONCURRENCY="1 16 64 256"
#   BENCH_SCENARIOS="list search search_complex search_tag get create update archive tags mixed"
#   BENCH_SERVER_BIN=/absolute/path/to/prebuilt/server (one implementation only)
#   BENCH_IMPL_LABEL=rust-h5i-cpu-scan (label a CPU-only GPU-server build)
#   BENCH_STRICT=1 (stop on failed warmup/measurement checks)
#   BENCH_OUT=linkding/bench/results
#   SERVER_CPUS=0-3 K6_CPUS=8-11 PG_CPUS=4-7
#   LINKDING_PG_CONTAINER=linkding-pg-fastapi LINKDING_PG_PORT=5440
#   BENCH_NO_SUMMARY=1
#   ./bench-all.sh [fastapi|go|fastify|rust-h5i|upstream ...]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PG_CONTAINER="${LINKDING_PG_CONTAINER:-linkding-pg}"
PG_PORT="${LINKDING_PG_PORT:-5440}"
export DATABASE_URL="${DATABASE_URL:-postgres://linkding:linkding@127.0.0.1:${PG_PORT}/linkding}"
export LINKDING_PG_CONTAINER="$PG_CONTAINER"
export LINKDING_PG_PORT="$PG_PORT"
SERVER_CPUS="${SERVER_CPUS:-0-3}"
K6_CPUS="${K6_CPUS:-8-11}"
export CARGO_HOME="${CARGO_HOME:-/var/tmp/ld-cargo-home}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/var/tmp/ld-target}"
export GOPATH="${GOPATH:-/var/tmp/ld-gopath}"
export GOCACHE="${GOCACHE:-/var/tmp/ld-gocache}"
export GOMODCACHE="${GOMODCACHE:-/var/tmp/ld-gomodcache}"
export PIP_CACHE_DIR="${PIP_CACHE_DIR:-/var/tmp/ld-pip-cache}"
export npm_config_cache="${npm_config_cache:-/var/tmp/npm-cache}"
export PATH="/var/tmp/go/bin:/home/ht2673/.nvm/versions/node/v24.21.0/bin:${PATH}"
K6="${K6:-/var/tmp/tools/k6}"
PY="${PY:-python3}"
OUT="${BENCH_OUT:-$ROOT/bench/results}"
WARMUP="${BENCH_WARMUP:-10}"
DURATION="${BENCH_DURATION:-30}"
REPEATS="${BENCH_REPEATS:-3}"
CONCURRENCIES="${BENCH_CONCURRENCY:-1 16 64 256}"
SCENARIOS="${BENCH_SCENARIOS:-list search search_complex search_tag get create update archive tags mixed}"
LOG_DIR="${LOG_DIR:-/var/tmp/ld-logs}"
TOKEN="$(printf 'a%.0s' {1..40})"
UPSTREAM_NAME="${LINKDING_UPSTREAM_CONTAINER:-linkding-upstream}"
mkdir -p "$OUT" "$LOG_DIR" "$CARGO_HOME" "$CARGO_TARGET_DIR"
echo $$ > "$LOG_DIR/bench-all.pid"

if [ "$#" -eq 0 ]; then
  set -- fastapi go fastify rust-h5i
fi
if [ -n "${BENCH_SERVER_BIN:-}${BENCH_IMPL_LABEL:-}" ] && [ "$#" -ne 1 ]; then
  echo 'BENCH_SERVER_BIN and BENCH_IMPL_LABEL require one implementation' >&2
  exit 2
fi

if [ "$#" -eq 1 ] && [ "$1" = "upstream" ]; then
  export LINKDING_SKIP_SCHEMA=1
fi
"$ROOT/scripts/up-db.sh" >/dev/null
unset LINKDING_SKIP_SCHEMA

seed_db() {
  local name="$1"
  if [ "$name" = "upstream" ]; then
    docker exec -i "$PG_CONTAINER" psql -U linkding -d linkding -v ON_ERROR_STOP=1 \
      < "$ROOT/bench/seed_upstream.sql" >/dev/null
  else
    docker exec -i "$PG_CONTAINER" psql -U linkding -d linkding -v ON_ERROR_STOP=1 \
      < "$ROOT/bench/seed.sql" >/dev/null
  fi
  # rust-h5i (the h5i-app engine) keeps its rows in its own schema `h5iapp`,
  # which the server creates at start. Copy the shared dataset into it so the
  # engine sees the same bookmarks, tags and tokens as the SQL variants.
  if [ "$name" = "rust-h5i" ]; then
    docker exec -i "$PG_CONTAINER" psql -U linkding -d linkding -v ON_ERROR_STOP=1 \
      < "$ROOT/bench/seed_h5i_app.sql" >/dev/null
  fi
}

server_pid=""
upstream_started=0
cleanup() {
  if [ "$upstream_started" = 1 ]; then
    docker rm -f "$UPSTREAM_NAME" >/dev/null 2>&1 || true
    upstream_started=0
  fi
  if [ -n "${server_pid:-}" ]; then
    kill -- -"$server_pid" >/dev/null 2>&1 || kill "$server_pid" >/dev/null 2>&1 || true
    server_pid=""
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

wait_health() {
  local name="$1"
  local port="$2"
  local url="http://127.0.0.1:${port}/healthz"
  if [ "$name" = "upstream" ]; then
    url="http://127.0.0.1:${port}/api/bookmarks/shared/"
  fi
  local i
  local tries=120
  if [ "$name" = "upstream" ]; then
    tries=240
  fi
  for i in $(seq 1 "$tries"); do
    if curl -sf "$url" >/dev/null; then
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

pin_tree() {
  local pid="$1"
  taskset -acp "$SERVER_CPUS" "$pid" >/dev/null 2>&1 || true
  local child
  for child in $(pgrep -P "$pid" 2>/dev/null || true); do
    pin_tree "$child"
  done
}

start_upstream() {
  local port="$1"
  cleanup
  server_pid=""
  free_port "$port"
  docker rm -f "$UPSTREAM_NAME" >/dev/null 2>&1 || true
  docker run -d --name "$UPSTREAM_NAME" --network host \
    -e LD_SERVER_HOST=127.0.0.1 \
    -e LD_SERVER_PORT="$port" \
    -e LD_DB_ENGINE=postgres \
    -e LD_DB_HOST=127.0.0.1 \
    -e LD_DB_PORT="$PG_PORT" \
    -e LD_DB_DATABASE=linkding \
    -e LD_DB_USER=linkding \
    -e LD_DB_PASSWORD=linkding \
    -e LD_DISABLE_BACKGROUND_TASKS=True \
    -e LD_SUPERUSER_NAME=alice \
    -e LD_SUPERUSER_PASSWORD=alice-pass-123 \
    sissbruecker/linkding:1.47.0 >/dev/null
  upstream_started=1
  wait_health upstream "$port"
  server_pid="$(docker inspect -f '{{.State.Pid}}' "$UPSTREAM_NAME")"
  pin_tree "$server_pid"
}

start_server() {
  local name="$1"
  local port="$2"
  local dir="$3"
  if [ "$name" = "upstream" ]; then
    start_upstream "$port"
    return
  fi
  cleanup
  server_pid=""
  free_port "$port"
  sleep 0.3
  case "$name" in
    fastapi|fastify)
      export WEB_CONCURRENCY=4
      export DB_POOL=8
      ;;
    go|rust-h5i|rust-h5i-optimized|rust-h5i-gpu)
      export WEB_CONCURRENCY=4
      export DB_POOL=32
      ;;
  esac
  export PORT="$port"
  setsid taskset -c "$SERVER_CPUS" "${BENCH_SERVER_BIN:-$dir/run.sh}" >> "${SERVER_LOG:-$LOG_DIR/bench-${name}.log}" 2>&1 &
  server_pid=$!
  wait_health "$name" "$port"
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
    "$ROOT/bench/workload.js" > "${summary%.json}.log" 2>&1
}

prebuild() {
  if [ -n "${BENCH_SERVER_BIN:-}" ]; then
    test -x "$BENCH_SERVER_BIN"
    return
  fi
  if printf '%s\n' "$@" | grep -qx rust-h5i; then
    (cd "$ROOT/rust-h5i" && cargo build --release -p linkding-server)
  fi
}

prebuild "$@"

for name in "$@"; do
  label="${BENCH_IMPL_LABEL:-$name}"
  case "$name" in
    fastapi) port=8101; dir="$ROOT/fastapi" ;;
    go) port=8102; dir="$ROOT/go" ;;
    fastify) port=8103; dir="$ROOT/fastify" ;;
    rust-h5i) port=8104; dir="$ROOT/rust-h5i" ;;
    rust-h5i-optimized) port=8106; dir="$ROOT/rust-h5i-optimized" ;;
    rust-h5i-gpu) port=8107; dir="$ROOT/rust-h5i-gpu/server" ;;
    upstream) port=8105; dir="" ;;
    *) echo "unknown implementation: $name" >&2; exit 2 ;;
  esac
  # Parallel runs pass PORT through the environment. A single bench-all.sh
  # keeps the fixed ports above.
  if [ -n "${BENCH_PORT:-}" ]; then
    port="$BENCH_PORT"
  fi
  echo "START $name :$port"
  start_server "$name" "$port" "$dir"
  if [ "$name" = "upstream" ]; then
    seed_db upstream
  fi
  BASE="http://127.0.0.1:${port}"
  for scenario in $SCENARIOS; do
    for conc in $CONCURRENCIES; do
      for rep in $(seq 1 "$REPEATS"); do
        tag="${label}_${scenario}_c${conc}_r${rep}"
        SERVER_LOG="$LOG_DIR/${tag}.server.log"
        echo "SEED $tag"
        if [ "$name" = "upstream" ]; then
          # Under overload uWSGI keeps working through its listen queue after
          # k6 stops, so its writes would land after the reseed. Restart it.
          start_server "$name" "$port" "$dir"
          seed_db upstream
        else
          # Direct SQL reseeding cannot notify resident indices. Stop before
          # the seed (also drain writes), then rebuild during the warmup.
          cleanup
          seed_db "$name"
          start_server "$name" "$port" "$dir"
        fi
        if [ "$name" = "upstream" ]; then
          :
        elif ! curl -sf "$BASE/healthz" >/dev/null; then
          echo "POINT_FAIL $tag server died; restarting" >&2
          start_server "$name" "$port" "$dir"
        fi
        if ! run_k6 "$WARMUP" "$LOG_DIR/warmup-${tag}.json"; then
          echo "POINT_FAIL $tag warmup checks failed" >&2
          if [ "${BENCH_STRICT:-0}" = 1 ]; then exit 1; fi
        fi
        meta_tmp="$OUT/${tag}.meta.json"
        summary="$OUT/${tag}.summary.json"
        "$PY" -u "$ROOT/bench/sample_proc.py" "$server_pid" > "$meta_tmp.sample" &
        sampler=$!
        measure_failed=0
        if ! run_k6 "$DURATION" "$summary"; then
          echo "POINT_FAIL $tag k6 exited non-zero" >&2
          measure_failed=1
        fi
        kill "$sampler" >/dev/null 2>&1 || true
        wait "$sampler" >/dev/null 2>&1 || true
        "$PY" - "$meta_tmp" "$meta_tmp.sample" "$label" "$scenario" "$conc" "$rep" "$WARMUP" "$DURATION" <<'PY'
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
        if [ "$measure_failed" = 1 ] && [ "${BENCH_STRICT:-0}" = 1 ]; then exit 1; fi
      done
    done
  done
  cleanup
  server_pid=""
done

if [ -z "${BENCH_NO_SUMMARY:-}" ]; then
  "$PY" "$ROOT/bench/summarize.py" "$OUT"
fi
echo "BENCH_DONE $OUT"
