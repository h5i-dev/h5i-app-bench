#!/usr/bin/env bash
# Release build. WEB_CONCURRENCY is the Tokio worker-thread count.
# One process, DB_POOL connections (default 32).
set -euo pipefail
cd "$(dirname "$0")"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/var/tmp/rw-target}"
export PORT="${PORT:-8004}"
export DATABASE_URL="${DATABASE_URL:-postgres://conduit:conduit@127.0.0.1:54329/conduit}"
export JWT_SECRET="${JWT_SECRET:-conduit-benchmark-secret}"
export DB_POOL="${DB_POOL:-32}"
export WEB_CONCURRENCY="${WEB_CONCURRENCY:-4}"
cargo build --release -p conduit-server
exec "$CARGO_TARGET_DIR/release/conduit-server"
