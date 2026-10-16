#!/usr/bin/env bash
# Reset the shared database and run the Hurl suite against each implementation.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DATABASE_URL="${DATABASE_URL:-postgres://linkding:linkding@127.0.0.1:${LINKDING_PG_PORT:-5440}/linkding}"
export WEB_CONCURRENCY="${WEB_CONCURRENCY:-1}"
export DB_POOL="${DB_POOL:-8}"
export PIP_CACHE_DIR="${PIP_CACHE_DIR:-/var/tmp/ld-pip-cache}"
export npm_config_cache="${npm_config_cache:-/var/tmp/npm-cache}"
export GOPATH="${GOPATH:-/var/tmp/ld-gopath}"
export GOCACHE="${GOCACHE:-/var/tmp/ld-gocache}"
export GOMODCACHE="${GOMODCACHE:-/var/tmp/ld-gomodcache}"
export CARGO_HOME="${CARGO_HOME:-/var/tmp/ld-cargo-home}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/var/tmp/ld-target}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/var/tmp/ld-xdg-cache}"
export PATH="/var/tmp/go/bin:${PATH}"
LOG_DIR="${LOG_DIR:-/var/tmp/ld-logs}"
CPUS="${TEST_CPUS:-64-127}"
mkdir -p "$LOG_DIR" "$CARGO_HOME" "$GOPATH" "$GOCACHE" "$GOMODCACHE" "$XDG_CACHE_HOME"

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
  for i in $(seq 1 120); do
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
  setsid nice -n 19 taskset -c "$CPUS" "$dir/run.sh" > "$LOG_DIR/${name}.log" 2>&1 &
  pids+=("$!")
  wait_health "$port"
  HOST="http://127.0.0.1:${port}" "$ROOT/scripts/test-one.sh"
  kill -- -"${pids[-1]}" >/dev/null 2>&1 || true
  unset 'pids[-1]'
  sleep 0.3
}

if [ "$#" -eq 0 ]; then
  set -- fastapi go fastify rust-h5i-optimized
fi

for name in "$@"; do
  case "$name" in
    fastapi) run_impl fastapi 8101 "$ROOT/fastapi" ;;
    go) run_impl go 8102 "$ROOT/go" ;;
    fastify) run_impl fastify 8103 "$ROOT/fastify" ;;
    rust-h5i-optimized) run_impl rust-h5i-optimized 8104 "$ROOT/rust-h5i-optimized" ;;
    *) echo "unknown implementation: $name" >&2; exit 2 ;;
  esac
done

echo "all requested API suites passed"
