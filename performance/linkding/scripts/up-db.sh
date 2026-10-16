#!/usr/bin/env bash
# Start Postgres 16 and apply performance/linkding/schema.sql.
#   ./up-db.sh           keep data, create anything missing
#   ./up-db.sh --reset   drop and recreate the public schema, then apply it
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="${LINKDING_PG_CONTAINER:-linkding-pg}"
PORT="${LINKDING_PG_PORT:-5440}"
DATA="${LINKDING_PG_DATA:-/var/tmp/linkding-pg-data}"
RESET=0
if [ "${1:-}" = "--reset" ]; then
  RESET=1
fi

if ! docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
  mkdir -p "$DATA"
  docker run -d --name "$NAME" \
    -e POSTGRES_USER=linkding \
    -e POSTGRES_PASSWORD=linkding \
    -e POSTGRES_DB=linkding \
    -p "127.0.0.1:${PORT}:5432" \
    -v "${DATA}:/var/lib/postgresql/data" \
    postgres:16 \
    -c max_connections=200 \
    -c shared_buffers=512MB
fi

if [ "$(docker inspect -f '{{.State.Running}}' "$NAME")" != "true" ]; then
  docker start "$NAME" >/dev/null
fi

ready=0
for _ in $(seq 1 60); do
  if docker exec "$NAME" pg_isready -U linkding -d linkding >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
if [ "$ready" != 1 ]; then
  echo "postgres did not become ready" >&2
  exit 1
fi

pin_tree() {
  local pid="$1"
  taskset -acp "${PG_CPUS:-64-71}" "$pid" >/dev/null 2>&1 || true
  local child
  for child in $(pgrep -P "$pid" 2>/dev/null || true); do
    pin_tree "$child"
  done
}
pg_pid="$(docker inspect -f '{{.State.Pid}}' "$NAME" 2>/dev/null || true)"
if [ -n "$pg_pid" ] && [ "$pg_pid" != "0" ]; then
  pin_tree "$pg_pid"
fi

if [ "$RESET" = 1 ]; then
  docker exec -i "$NAME" psql -U linkding -d linkding -v ON_ERROR_STOP=1 \
    -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null
fi

# The upstream image applies Django migrations itself. Skip schema.sql then.
if [ "${LINKDING_SKIP_SCHEMA:-0}" != 1 ]; then
  docker exec -i "$NAME" psql -U linkding -d linkding -v ON_ERROR_STOP=1 \
    < "$ROOT/schema.sql" >/dev/null
fi

echo "postgres://linkding:linkding@127.0.0.1:${PORT}/linkding"
