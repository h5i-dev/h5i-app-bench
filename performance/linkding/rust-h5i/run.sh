#!/usr/bin/env bash
# Release build. WEB_CONCURRENCY is the Tokio worker-thread count.
# One process, DB_POOL connections (default 32). Tables live in the schema
# `h5iapp` of the database; the server creates them at start, and
# bench/seed_h5i_app.sql copies the shared schema's rows into them.
set -euo pipefail
cd "$(dirname "$0")"
export CARGO_HOME="${CARGO_HOME:-/var/tmp/ld-cargo-home}"
# Its own target directory: the dependency graph (h5i-app) is not rust-h5i-optimized's.
export CARGO_TARGET_DIR="${H5I_APP_TARGET_DIR:-/var/tmp/ld-target-h5i-app}"
mkdir -p "$CARGO_HOME" "$CARGO_TARGET_DIR"
export PORT="${PORT:-8106}"
export DATABASE_URL="${DATABASE_URL:-postgres://linkding:linkding@127.0.0.1:5440/linkding}"
export DB_POOL="${DB_POOL:-32}"
export WEB_CONCURRENCY="${WEB_CONCURRENCY:-4}"
cargo build --release -p linkding-server
exec "$CARGO_TARGET_DIR/release/linkding-server"
