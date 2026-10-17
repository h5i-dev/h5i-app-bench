#!/usr/bin/env bash
# Build the GPU linkding server: the device PTX, then the server with the
# `gpu` feature (the Rust-CUDA resident launch).
#
# Host-only. Needs the Rust-CUDA nightly, libNVVM 12.6 and a CUDA device, so it
# never runs in CI; the benchmark harness calls it on a GPU host. Without a GPU
# build the CPU scan path (`cargo build --release` with no feature) is correct
# and portable; this script is only for the end-to-end GPU measurement.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
crate="$here/.."

# Toolchain and caches live off NFS, shared with build-device.sh.
export CARGO_HOME="${CARGO_HOME:-/var/tmp/h5i-gpu-cargo-home}"
export RUSTUP_HOME="${RUSTUP_HOME:-/var/tmp/h5i-gpu-rustup}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/var/tmp/h5i-gpu-server-target}"
export CUDA_PATH="${CUDA_PATH:-/usr/local/cuda-12.6}"
export CUDA_ROOT="$CUDA_PATH"
export TMPDIR="${TMPDIR:-/var/tmp}"
export PATH="/usr/local/cuda/bin:$PATH"
export LD_LIBRARY_PATH="$CUDA_PATH/nvvm/lib64:$CUDA_PATH/lib64"
# libclang here ships no builtin headers, so point bindgen (cust) at gcc's.
export LIBCLANG_PATH="${LIBCLANG_PATH:-/lib/x86_64-linux-gnu}"
gccinc="$(ls -d /usr/lib/gcc/x86_64-linux-gnu/*/include 2>/dev/null | sort -V | tail -1)"
export BINDGEN_EXTRA_CLANG_ARGS="-I$gccinc -I/usr/include -I$CUDA_PATH/include"
export CPATH="$gccinc:/usr/include"

# 1) device PTX (nvptx64 target, its own toolchain invocation)
bash "$crate/backend-nvvm/build-device.sh"

# 2) the server, with the GPU feature
nice -n 19 taskset -c "${BUILD_CPUS:-64-127}" \
  cargo build --release --features gpu -j "${BUILD_JOBS:-8}" --manifest-path "$here/Cargo.toml"

echo "built $CARGO_TARGET_DIR/release/linkding-gpu-server"
echo "ptx   $CARGO_TARGET_DIR/../h5i-gpu-target/nvptx64-nvidia-cuda/release/linkding_gpu_device.ptx" 2>/dev/null || true
