#!/usr/bin/env bash
# Build the linkding_batch device PTX and run the resident-GPU benchmark.
# Host-only: needs the Rust-CUDA nightly + libNVVM + a GPU. Never runs in CI.
set -euo pipefail
cd "$(dirname "$0")"
export CARGO_HOME=/var/tmp/h5i-gpu-cargo-home CARGO_TARGET_DIR=/var/tmp/h5i-gpu-target RUSTUP_HOME=/var/tmp/h5i-gpu-rustup TMPDIR=/var/tmp CUDA_VISIBLE_DEVICES=0
export CUDA_PATH=/usr/local/cuda-12.6 PATH=/usr/local/cuda/bin:$PATH
export BINDGEN_EXTRA_CLANG_ARGS=-I/usr/lib/gcc/x86_64-linux-gnu/13/include
# device PTX (nvptx64 target, built by build-device.sh)
./build-device.sh
nice -n 19 taskset -c 64-127 cargo +nightly-2026-04-02 build --release --example measure --locked -j 8
export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64
exec nice -n 19 taskset -c 64-127 "$CARGO_TARGET_DIR/release/examples/measure" \
  "$CARGO_TARGET_DIR/nvptx64-nvidia-cuda/release/linkding_gpu_device.ptx"
