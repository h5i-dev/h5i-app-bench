#!/usr/bin/env bash
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
app=$(dirname "$(dirname "$here")")
GO_BIN=${GO_BIN:-/var/tmp/go/bin/go} "$app/http/build.sh"
"${GO_BIN:-/var/tmp/go/bin/go}" -C "$app/go" build -o /var/tmp/django-cart-go-lines .
/var/tmp/django-cart-bench-venv/bin/python "$here/oracle.py"
export CARGO_HOME=/var/tmp/h5i-gpu-cargo-home CARGO_TARGET_DIR=/var/tmp/h5i-gpu-target RUSTUP_HOME=/var/tmp/h5i-gpu-rustup TMPDIR=/var/tmp
export CUDA_PATH=/usr/local/cuda-12.6 LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64 BINDGEN_EXTRA_CLANG_ARGS=-I/usr/lib/gcc/x86_64-linux-gnu/13/include
cargo +nightly-2026-04-02 build --release --manifest-path "$app/rust-h5i-gpu/backend-nvvm/Cargo.toml" --example serve_lines --example profile_lines --locked -j 8
