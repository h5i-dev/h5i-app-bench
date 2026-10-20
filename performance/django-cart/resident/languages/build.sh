#!/usr/bin/env bash
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
backend="$here/../../rust-h5i-gpu/backend-nvvm"
export CARGO_HOME=/var/tmp/h5i-gpu-cargo-home CARGO_TARGET_DIR=/var/tmp/h5i-gpu-target RUSTUP_HOME=/var/tmp/h5i-gpu-rustup TMPDIR=/var/tmp
export CUDA_PATH=/usr/local/cuda-12.6
export LD_LIBRARY_PATH=/usr/local/cuda-12.6/nvvm/lib64:/usr/local/cuda-12.6/lib64:$RUSTUP_HOME/toolchains/nightly-2026-04-02-x86_64-unknown-linux-gnu/lib
export BINDGEN_EXTRA_CLANG_ARGS=-I/usr/lib/gcc/x86_64-linux-gnu/13/include
cargo +nightly-2026-04-02 build --release --manifest-path "$backend/Cargo.toml" --example export_languages --example language_reference --locked -j 4
/var/tmp/go/bin/go build -o /var/tmp/cart-resident-go "$here/main.go"
