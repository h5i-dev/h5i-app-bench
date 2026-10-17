#!/usr/bin/env bash
# Reset the shared database and run the RealWorld Hurl suite against each
# implementation. A failing suite stops the script.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DATABASE_URL="${DATABASE_URL:-postgres://conduit:conduit@127.0.0.1:54329/conduit}"
export JWT_SECRET="${JWT_SECRET:-conduit-benchmark-secret}"
export WEB_CONCURRENCY="${WEB_CONCURRENCY:-1}"
export DB_POOL="${DB_POOL:-8}"
LOG_DIR="${LOG_DIR:-/var/tmp/rw-logs}"
mkdir -p "$LOG_DIR"

"$ROOT/scripts/up-db.sh" --reset

pids=()
cleanup() {
  local pid
  for pid in "${pids[@]:-}"; do
    kill -- -"$pid" >/dev/null 2>&1 || kill "$pid" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

wait_health() {
  local port="$1"
  local i
  for i in $(seq 1 90); do
    if curl -sf "http://127.0.0.1:${port}/healthz" >/dev/null; then
      return 0
    fi
    sleep 0.5
  done
  echo "server on port $port did not become ready" >&2
  return 1
}

run_impl() {
  local name="$1"
  local port="$2"
  local dir="$3"
  echo "=== $name :$port ==="
  setsid "$dir/run.sh" > "$LOG_DIR/${name}.log" 2>&1 &
  pids+=("$!")
  PORT="$port" wait_health "$port"
  HOST="http://127.0.0.1:${port}" "$ROOT/scripts/test-one.sh"
  kill -- -"${pids[-1]}" >/dev/null 2>&1 || true
  unset 'pids[-1]'
  # Let the port go free before the next server.
  sleep 0.3
}

if [ "$#" -eq 0 ]; then
  set -- fastapi go fastify rust-h5i-optimized
fi

for name in "$@"; do
  case "$name" in
    fastapi) run_impl fastapi 8001 "$ROOT/fastapi" ;;
    go) run_impl go 8002 "$ROOT/go" ;;
    fastify) run_impl fastify 8003 "$ROOT/fastify" ;;
    rust-h5i-optimized) run_impl rust-h5i-optimized 8004 "$ROOT/rust-h5i-optimized" ;;
    rust-h5i) run_impl rust-h5i 8005 "$ROOT/rust-h5i" ;;
    *) echo "unknown implementation: $name" >&2; exit 2 ;;
  esac
done

echo "all requested API suites passed"
