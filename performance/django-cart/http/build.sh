#!/usr/bin/env bash
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
app=$(dirname "$here")
GO_BIN=${GO_BIN:-go} "$app/bench/run.sh" --cpu-only
npm --prefix "$app/javascript" ci --ignore-scripts
"$app/rust-h5i-gpu/backend-nvvm/build-device.sh"
export CARGO_HOME=/var/tmp/h5i-gpu-cargo-home CARGO_TARGET_DIR=/var/tmp/h5i-gpu-target RUSTUP_HOME=/var/tmp/h5i-gpu-rustup TMPDIR=/var/tmp
export CUDA_PATH=/usr/local/cuda-12.6 LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64 BINDGEN_EXTRA_CLANG_ARGS=-I/usr/lib/gcc/x86_64-linux-gnu/13/include
cargo +nightly-2026-04-02 build --release --manifest-path "$app/rust-h5i-gpu/backend-nvvm/Cargo.toml" --example serve --locked -j 8
