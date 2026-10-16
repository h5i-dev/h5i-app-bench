#!/usr/bin/env bash
# Run bench-all.sh for the four implementations at once, each on its own
# CPUs and its own Postgres container, then write the summary.
#
# CPU layout (physical cores only; the SMT siblings 64-127 are left unused).
# Each 4-core group is one CCX of the EPYC 7502 (its own L3 slice), and each
# implementation stays on one NUMA node:
#
#   impl      server  postgres  k6     node  pg port
#   fastapi   0-3     4-7       8-15   0     54331
#   go        16-19   20-23     24-31  0     54332
#   fastify   32-35   36-39     40-47  1     54333
#   rust-h5i-optimized  48-51   52-55     56-63  1     54334
#   rust-h5i 48-51 52-55   56-63  1     54335  (shares rust-h5i-optimized's CPUs:
#                                                   run it alone, by name)
#
# The script re-launches itself under setsid nohup and returns at once.
# Progress: /var/tmp/rw-logs/<impl>/bench-all.log; done marker:
# /var/tmp/rw-logs/parallel.done. Pass implementation names to run a subset.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGS="${LOG_ROOT:-/var/tmp/rw-logs}"
OUT="${BENCH_OUT:-$ROOT/bench/results}"
PY="${PY:-/var/tmp/rw-fastapi-venv/bin/python}"

if [ -z "${RW_DETACHED:-}" ]; then
  mkdir -p "$LOGS"
  RW_DETACHED=1 setsid nohup "$0" "$@" > "$LOGS/parallel.log" 2>&1 < /dev/null &
  echo "started; log $LOGS/parallel.log"
  exit 0
fi

if [ "$#" -eq 0 ]; then
  set -- fastapi go fastify rust-h5i-optimized
fi

layout() {
  case "$1" in
    fastapi)  echo "0-3 4-7 8-15 54331" ;;
    go)       echo "16-19 20-23 24-31 54332" ;;
    fastify)  echo "32-35 36-39 40-47 54333" ;;
    rust-h5i-optimized) echo "48-51 52-55 56-63 54334" ;;
    rust-h5i) echo "48-51 52-55 56-63 54335" ;;
    *) return 1 ;;
  esac
}

rm -f "$LOGS/parallel.done"
mkdir -p "$OUT"
pids=()
for name in "$@"; do
  read -r server pg k6 port < <(layout "$name") || { echo "unknown: $name"; exit 2; }
  mkdir -p "$LOGS/$name"
  echo "START $name server=$server pg=$pg k6=$k6 port=$port $(date -Is)"
  (
    export SERVER_CPUS="$server" PG_CPUS="$pg" K6_CPUS="$k6"
    export CONDUIT_PG_CONTAINER="conduit-pg-$name" CONDUIT_PG_PORT="$port"
    export CONDUIT_PG_DATA="/var/tmp/conduit-pg-data-$name"
    export LOG_DIR="$LOGS/$name" BENCH_OUT="$OUT" BENCH_NO_SUMMARY=1
    exec bash "$ROOT/scripts/bench-all.sh" "$name"
  ) > "$LOGS/$name/bench-all.log" 2>&1 &
  pids+=("$!")
  # Stagger the starts so builds and container boots do not overlap.
  sleep 20
done

status=0
for i in "${!pids[@]}"; do
  if ! wait "${pids[$i]}"; then
    echo "FAILED ${*:$((i+1)):1} $(date -Is)"
    status=1
  fi
done

"$PY" "$ROOT/bench/summarize.py" "$OUT" || status=1
echo "PARALLEL_DONE status=$status $(date -Is)" | tee "$LOGS/parallel.done"
exit "$status"
