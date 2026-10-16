#!/usr/bin/env bash
# Production-style uvicorn: WEB_CONCURRENCY workers (default 4), no access log.
set -euo pipefail
cd "$(dirname "$0")"
PORT="${PORT:-8001}"
WORKERS="${WEB_CONCURRENCY:-4}"
export DATABASE_URL="${DATABASE_URL:-postgres://conduit:conduit@127.0.0.1:54329/conduit}"
export JWT_SECRET="${JWT_SECRET:-conduit-benchmark-secret}"
export DB_POOL="${DB_POOL:-8}"
VENV="${VENV:-/var/tmp/rw-fastapi-venv}"
if [ ! -x "$VENV/bin/uvicorn" ]; then
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install --upgrade pip
  "$VENV/bin/pip" install -r requirements.txt
fi
exec "$VENV/bin/uvicorn" app.main:app \
  --host 127.0.0.1 \
  --port "$PORT" \
  --workers "$WORKERS" \
  --no-access-log \
  --log-level warning \
  --timeout-keep-alive 30
