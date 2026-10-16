#!/usr/bin/env bash
# Release build. WEB_CONCURRENCY is the Tokio worker-thread count.
# One process, DB_POOL connections (default 32). Tables live in the schema
# `conduit` of the database; the server creates them at start.
set -euo pipefail
cd "$(dirname "$0")"
# Its own target directory: the dependency graph (h5i-app) is not rust-h5i's.
export CARGO_TARGET_DIR="${H5I_APP_TARGET_DIR:-/var/tmp/rw-target-h5i-app}"
export PORT="${PORT:-8005}"
export DATABASE_URL="${DATABASE_URL:-postgres://conduit:conduit@127.0.0.1:54329/conduit}"
export JWT_SECRET="${JWT_SECRET:-conduit-benchmark-secret}"
export DB_POOL="${DB_POOL:-32}"
export WEB_CONCURRENCY="${WEB_CONCURRENCY:-4}"
export LISTEN="127.0.0.1:${PORT}"
cargo build --release -p conduit-server
exec "$CARGO_TARGET_DIR/release/conduit-server"
