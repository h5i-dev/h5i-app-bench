#!/usr/bin/env bash
# Run bench-all.sh for the implementations at once, each on its own CPUs
# and its own Postgres container, then write the summary.
#
# CPU layout uses physical cores 0-63. Each implementation gets 4 server
# cores, 4 Postgres cores, and 4 k6 cores:
#
#   impl      server  postgres  k6     pg port  http
#   fastapi   0-3     4-7       8-11   5440     8101
#   go        12-15   16-19     20-23  5441     8102
#   fastify   24-27   28-31     32-35  5442     8103
#   rust-h5i  36-39   40-43     44-47  5443     8104
#   upstream  48-51   52-55     56-59  5444     8105
#
# The script re-launches itself under setsid nohup and returns at once.
# Progress: /var/tmp/ld-logs/<impl>/bench-all.log; done marker:
# /var/tmp/ld-logs/parallel.done. Pass implementation names to run a subset.
#
# Published shape (the defaults of bench-all.sh):
#   BENCH_WARMUP=10 BENCH_DURATION=30 BENCH_REPEATS=3
#   BENCH_CONCURRENCY="1 16 64 256"
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGS="${LOG_ROOT:-/var/tmp/ld-logs}"
OUT="${BENCH_OUT:-$ROOT/bench/results}"
PY="${PY:-python3}"

if [ -z "${LD_DETACHED:-}" ]; then
  mkdir -p "$LOGS"
  LD_DETACHED=1 setsid nohup "$0" "$@" > "$LOGS/parallel.log" 2>&1 < /dev/null &
  echo "started; log $LOGS/parallel.log"
  exit 0
fi

if [ "$#" -eq 0 ]; then
  set -- fastapi go fastify rust-h5i rust-h5i-optimized upstream rust-h5i-gpu
fi

# Seven variants share physical cores 0-62: 3 server, 3 Postgres, 3 k6 each.
# Ports and container names take an optional prefix/base so a run can stay off
# any stale containers from an earlier run.
layout() {
  case "$1" in
    fastapi)             echo "0-2 3-5 6-8 5468 8101" ;;
    go)                  echo "9-11 12-14 15-17 5461 8102" ;;
    fastify)             echo "18-20 21-23 24-26 5462 8103" ;;
    rust-h5i)            echo "27-29 30-32 33-35 5463 8104" ;;
    rust-h5i-optimized)  echo "36-38 39-41 42-44 5466 8106" ;;
    upstream)            echo "45-47 48-50 51-53 5464 8105" ;;
    rust-h5i-gpu)        echo "54-56 57-59 60-62 5467 8107" ;;
    *) return 1 ;;
  esac
}

rm -f "$LOGS/parallel.done"
mkdir -p "$OUT"
pids=()
names=()
for name in "$@"; do
  read -r server pg k6 port http < <(layout "$name") || { echo "unknown: $name"; exit 2; }
  mkdir -p "$LOGS/$name"
  echo "START $name server=$server pg=$pg k6=$k6 pgport=$port http=$http $(date -Is)"
  (
    export SERVER_CPUS="$server" PG_CPUS="$pg" K6_CPUS="$k6"
    export LINKDING_PG_CONTAINER="${PG_PREFIX:-linkding-pg-}$name" LINKDING_PG_PORT="$port"
    export LINKDING_PG_DATA="${PG_DATA_ROOT:-/var/tmp}/linkding-pg-data-${PG_PREFIX:-}$name"
    export BENCH_PORT="$http"
    export LOG_DIR="$LOGS/$name" BENCH_OUT="$OUT" BENCH_NO_SUMMARY=1
    exec bash "$ROOT/scripts/bench-all.sh" "$name"
  ) > "$LOGS/$name/bench-all.log" 2>&1 &
  pids+=("$!")
  names+=("$name")
  sleep 20
done

status=0
for i in "${!pids[@]}"; do
  if ! wait "${pids[$i]}"; then
    echo "FAILED ${names[$i]} $(date -Is)"
    status=1
  fi
done

"$PY" "$ROOT/bench/summarize.py" "$OUT" || status=1
echo "PARALLEL_DONE status=$status $(date -Is)" | tee "$LOGS/parallel.done"
exit "$status"
