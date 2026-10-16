#!/usr/bin/env bash
# Release build. WEB_CONCURRENCY is the Tokio worker-thread count.
# One process, DB_POOL connections (default 32).
set -euo pipefail
cd "$(dirname "$0")"
export CARGO_HOME="${CARGO_HOME:-/var/tmp/ld-cargo-home}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/var/tmp/ld-target}"
export PATH="/var/tmp/go/bin:${PATH}"
mkdir -p "$CARGO_HOME" "$CARGO_TARGET_DIR"
export PORT="${PORT:-8104}"
export DATABASE_URL="${DATABASE_URL:-postgres://linkding:linkding@127.0.0.1:5440/linkding}"
export DB_POOL="${DB_POOL:-32}"
export WEB_CONCURRENCY="${WEB_CONCURRENCY:-4}"
cargo build --release -p linkding-server
exec "$CARGO_TARGET_DIR/release/linkding-server"
