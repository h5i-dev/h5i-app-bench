#!/usr/bin/env bash
# Run a list of tasks on one model, CONC at a time, detached from the terminal.
#
#   scripts/run-batch.sh <model> <agent> [conc=3] [minutes=40] [tasks=dataset/subset20.txt]
#
# The script re-launches itself under `setsid nohup` and returns at once, so a
# batch of several hours survives a dropped SSH connection or the launching
# shell exiting. Progress goes to results/campaigns/<stamp>-<agent>-<model>.log.
#
# BENCH_UPSTREAM and BENCH_API_KEY must be set (see README); BENCH_LEAN,
# BENCH_PACKAGES and BENCH_APPLIB are passed through to bench.py if set.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
MODEL=${1:?model} AGENT=${2:?agent} CONC=${3:-3} MIN=${4:-40} TASKS=${5:-dataset/subset20.txt}

if [ -z "${H5IAB_DETACHED:-}" ]; then
  : "${BENCH_UPSTREAM:?set BENCH_UPSTREAM}" "${BENCH_API_KEY:?set BENCH_API_KEY}"
  mkdir -p "$ROOT/results/campaigns"
  log="$ROOT/results/campaigns/$(date +%Y%m%d-%H%M%S)-$AGENT-${MODEL//\//_}.log"
  H5IAB_DETACHED=1 setsid nohup "$0" "$@" > "$log" 2>&1 < /dev/null &
  echo "started (pid $!); log: $log"
  exit 0
fi

cd "$ROOT"
export PATH="$HOME/.elan/bin:$PATH" MODEL AGENT MIN
one() {
  echo "[$(date +%T)] START $1"
  python3 harness/run.py "$1" "$MODEL" --agent "$AGENT" --minutes "$MIN" > /dev/null 2>&1
  local r
  r=$(ls -dt results/runs/*-"$1"-"${MODEL//\//_}"* 2>/dev/null | head -1)
  echo "[$(date +%T)] DONE  $1 $(python3 -c "import json,sys; r=json.load(open(sys.argv[1])); print('PASS' if r['grade']['passed'] else 'fail', round(r['wall_s']/60,1), 'min', r['grade'].get('reason') or '')" "$r/result.json" 2>/dev/null || echo 'no result')"
}
export -f one
echo "[$(date +%T)] $MODEL / $AGENT, $CONC at a time, $MIN min, tasks from $TASKS"
grep -vE '^\s*(#|$)' "$TASKS" | xargs -P "$CONC" -I{} bash -c 'one "$1"' _ {}
echo "[$(date +%T)] ALL DONE"
