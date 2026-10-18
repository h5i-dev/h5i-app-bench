#!/usr/bin/env bash
# Same HTTP shell as optimized CPU; eight policy transitions use the GPU worker.
set -euo pipefail
cd "$(dirname "$0")/../rust-h5i-optimized"
export CARGO_TARGET_DIR="${CONDUIT_GPU_TARGET_DIR:-/var/tmp/conduit-gpu-server-target}"
export PORT="${PORT:-8006}"
export DATABASE_URL="${DATABASE_URL:-postgres://conduit:conduit@127.0.0.1:54329/conduit}"
export JWT_SECRET="${JWT_SECRET:-conduit-benchmark-secret}"
export DB_POOL="${DB_POOL:-32}" WEB_CONCURRENCY="${WEB_CONCURRENCY:-4}"
export CUDA_PATH="${CUDA_PATH:-/usr/local/cuda-12.6}"
export LD_LIBRARY_PATH="$CUDA_PATH/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
: "${CONDUIT_GPU_PTX:?set CONDUIT_GPU_PTX to conduit_gpu_device.ptx}"
export BINDGEN_EXTRA_CLANG_ARGS="${BINDGEN_EXTRA_CLANG_ARGS:--I/usr/lib/gcc/x86_64-linux-gnu/13/include}"
cargo build --release -p conduit-server --features gpu
exec "$CARGO_TARGET_DIR/release/conduit-server"
