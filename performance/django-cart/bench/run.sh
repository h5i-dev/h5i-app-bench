#!/usr/bin/env bash
# Full, fail-closed upstream/CPU/GPU correctness gate before writing measurements.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
app=$(dirname "$here")
source_dir=${DJANGO_CART_SOURCE:-/var/tmp/h5i-bench-django-cart-src}
venv=${DJANGO_CART_VENV:-/var/tmp/django-cart-bench-venv}
fixtures=${DJANGO_CART_FIXTURES:-/var/tmp/django-cart-fixtures.bin}
"$app/upstream/fetch.sh" "$source_dir"
python3 -m venv "$venv"
"$venv/bin/pip" install -r "$here/requirements.txt"
export CARGO_TARGET_DIR=/var/tmp/django-cart-target
cargo test --manifest-path "$app/rust-h5i-gpu/Cargo.toml" --locked
cargo build --release --manifest-path "$app/rust-h5i-gpu/Cargo.toml" --locked
"$venv/bin/python" "$here/check.py" --source "$source_dir" \
  --checker "$CARGO_TARGET_DIR/release/cart-check" --fixtures "$fixtures"
go_bin=${GO_BIN:-go}
node_bin=${NODE_BIN:-node}
"$go_bin" -C "$app/go" build -o /var/tmp/django-cart-go .
"$venv/bin/python" "$here/check.py" --source "$source_dir" \
  --checker /var/tmp/django-cart-go check --fixtures "$fixtures"
"$venv/bin/python" "$here/check.py" --source "$source_dir" \
  --checker "$node_bin" "$app/javascript/main.mjs" check --fixtures "$fixtures"
if [[ ${1:-} == --cpu-only ]]; then exit 0; fi
export CARGO_HOME=/var/tmp/h5i-gpu-cargo-home CARGO_TARGET_DIR=/var/tmp/h5i-gpu-target RUSTUP_HOME=/var/tmp/h5i-gpu-rustup TMPDIR=/var/tmp
export CART_LAYOUT=${CART_LAYOUT:-soa}
export CUDA_PATH=/usr/local/cuda-12.6 CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-0}
export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64
export BINDGEN_EXTRA_CLANG_ARGS=-I/usr/lib/gcc/x86_64-linux-gnu/13/include
"$app/rust-h5i-gpu/backend-nvvm/build-device.sh"
cargo +nightly-2026-04-02 build --release --manifest-path "$app/rust-h5i-gpu/backend-nvvm/Cargo.toml" --example measure --locked -j 8
out=${1:-$here/results/$(date +%F)-scale-$CART_LAYOUT}
mkdir -p "$out"
temp=$(mktemp "$out/.points.XXXXXX")
"$CARGO_TARGET_DIR/release/examples/measure" \
  "$CARGO_TARGET_DIR/nvptx64-nvidia-cuda/release/django_cart_gpu_device.ptx" "$fixtures" > "$temp"
mv "$temp" "$out/points.csv"
{
  date -u
  "$go_bin" version
  "$node_bin" --version
  rustc --version
  uname -a
  lscpu
  nvidia-smi
  taskset -pc $$
  echo "CART_LAYOUT=$CART_LAYOUT"
  echo "CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"
  git -C "$source_dir" rev-parse HEAD
  sha256sum "$fixtures" "$CARGO_TARGET_DIR/release/examples/measure" /var/tmp/django-cart-go
  sha256sum "$app/javascript/main.mjs" "$app/go/main.go" "$app/rust-h5i-gpu/src/pricing.rs" \
    "$app/rust-h5i-gpu/backend-nvvm/device/src/lib.rs" "$app/rust-h5i-gpu/backend-nvvm/src/lib.rs"
} > "$out/environment.txt"
/var/tmp/django-cart-go > "$out/go.csv"
"$node_bin" "$app/javascript/main.mjs" > "$out/javascript.csv"
"$venv/bin/python" "$here/summarize.py" "$out/points.csv"
