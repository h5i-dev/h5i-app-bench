#!/usr/bin/env bash
# Release build of the GPU linkding server. Serves the full REST API; the
# search endpoints scan a GPU-resident bookmark index (host needs a GPU + the
# Rust-CUDA toolchain). Non-search endpoints run on the h5i-app engine like
# rust-h5i. WEB_CONCURRENCY is the Tokio worker-thread count.
set -euo pipefail
cd "$(dirname "$0")"
export CARGO_HOME="${CARGO_HOME:-/var/tmp/ld-cargo-home}"
export CARGO_TARGET_DIR="${H5I_GPU_TARGET_DIR:-/var/tmp/ld-target-h5i-gpu}"
mkdir -p "$CARGO_HOME" "$CARGO_TARGET_DIR"
export PORT="${PORT:-8107}"
export DATABASE_URL="${DATABASE_URL:-postgres://linkding:linkding@127.0.0.1:5440/linkding}"
export DB_POOL="${DB_POOL:-32}"
export WEB_CONCURRENCY="${WEB_CONCURRENCY:-4}"
cargo build --release -p linkding-gpu-server
exec "$CARGO_TARGET_DIR/release/linkding-gpu-server"
