#!/usr/bin/env bash
# Production-style uvicorn. WEB_CONCURRENCY workers (default 4), DB_POOL each.
set -euo pipefail
cd "$(dirname "$0")"
PORT="${PORT:-8101}"
WORKERS="${WEB_CONCURRENCY:-4}"
export DATABASE_URL="${DATABASE_URL:-postgres://linkding:linkding@127.0.0.1:5440/linkding}"
export DB_POOL="${DB_POOL:-8}"
export PIP_CACHE_DIR="${PIP_CACHE_DIR:-/var/tmp/ld-pip-cache}"
export PYTHONNOUSERSITE=1
VENV="${VENV:-/var/tmp/ld-fastapi-venv}"
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
