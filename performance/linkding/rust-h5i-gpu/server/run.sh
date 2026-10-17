#!/usr/bin/env bash
# Launch the GPU linkding server for the benchmark harness.
#
# Builds on first use (device PTX + server with the `gpu` feature), pins the
# process to one CUDA device, points it at the compiled PTX, and execs it.
# Host-only: needs a GPU and the Rust-CUDA toolchain. The harness pins the CPU
# set with taskset around this script; the GPU is chosen here.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

# Build artifacts (off NFS), matching build.sh / build-device.sh.
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/var/tmp/h5i-gpu-server-target}"
BIN="$CARGO_TARGET_DIR/release/linkding-gpu-server"
PTX="${H5I_GPU_PTX:-/var/tmp/h5i-gpu-target/nvptx64-nvidia-cuda/release/linkding_gpu_device.ptx}"

if [ ! -x "$BIN" ] || [ ! -f "$PTX" ]; then
  bash "$here/build.sh"
fi

# One device for a reproducible measurement.
export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-0}"
export LD_LIBRARY_PATH="/usr/local/cuda-12.6/lib64:${LD_LIBRARY_PATH:-}"
export H5I_GPU_PTX="$PTX"

# DATABASE_URL, PORT, DB_POOL and WEB_CONCURRENCY come from the harness env.
exec "$BIN"
