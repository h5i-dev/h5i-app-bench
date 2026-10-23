#!/usr/bin/env bash
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
app=$(dirname "$here")
export CARGO_TARGET_DIR=${CARGO_TARGET_DIR:-/var/tmp/cart-comparison-target}
cargo build --release --locked --manifest-path "$app/rust-h5i/Cargo.toml"
(cd "$app/go" && "${GO_BIN:-go}" build -o /var/tmp/cart-comparison-go .)
npm --prefix "$app/fastify" ci --ignore-scripts
python3 -m venv /var/tmp/cart-comparison-venv
/var/tmp/cart-comparison-venv/bin/pip install -r "$app/fastapi/requirements.txt"
# CUDA device/host artifacts use their pinned nightly toolchain:
# GO_BIN=... ../http/build.sh (also runs the upstream Decimal oracle).
