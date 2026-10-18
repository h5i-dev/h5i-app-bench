# Optional Conduit GPU policy backend

This is the full existing optimized Conduit HTTP server, with eight small
application policy transitions dispatched to a CUDA worker: `CurrentUser`,
`Feed`, `DeleteArticle`, `DeleteComment`, `Follow`, `Unfollow`, `Favorite`, and
`Unfavorite`. The HTTP shell, SQL, JWT, bcrypt, input validation, serialization,
and verified CPU kernel are shared with `rust-h5i-optimized`; no copied server.
The normal CPU build has no CUDA runtime dependency.

`src/predicate.rs` is the allocation-free device implementation. `pack` and
`decode` map observations and decisions to the existing kernel. A CPU test
compares 8,192 combinations with the existing `transition`, including guests,
missing resources, owner mismatches and idempotent transitions. CUDA tests check
actual device execution, invalid inputs and batch boundaries. This is
conformance testing, not a formal CPU/GPU equivalence proof; the existing Lean
proofs apply to the CPU kernel.

One dedicated thread owns the h5i NVVM context, stream and reusable device
buffers. A bounded queue holds 128 requests; it batches up to 128 already queued
policies without waiting to fill a batch. GPU initialization must succeed at
startup, preventing accidental CPU-only benchmark results. Queue saturation,
worker errors or invalid output fall back to the original pure CPU decision,
with rate-limited fallback counts in the local server log. The h5i `Backend`
trait and `Output::validate` are reused. There is no GPU database or change to
transaction semantics.

## Build and test

On a CUDA host, first provision the same Rust-CUDA environment as Linkding:

```sh
performance/linkding/rust-h5i-gpu/backend-nvvm/setup.sh
performance/realworld/rust-h5i-gpu/backend-nvvm/build-device.sh
export CONDUIT_GPU_PTX=/var/tmp/h5i-gpu-target/nvptx64-nvidia-cuda/release/conduit_gpu_device.ptx
performance/realworld/rust-h5i-gpu/run.sh
# Separate terminal, after preparing the normal Conduit database:
HOST=http://127.0.0.1:8006 performance/realworld/scripts/test-one.sh
```

The checked-in backend lockfile pins `glam` to 0.30.10, matching the Rust-CUDA
revision's device API. Run the portable oracle test without CUDA:

```sh
cargo test --release --manifest-path performance/realworld/rust-h5i-gpu/Cargo.toml --locked
```

Device tests (with the PTX environment above):

```sh
CUDA_PATH=/usr/local/cuda-12.6 \
BINDGEN_EXTRA_CLANG_ARGS=-I/usr/lib/gcc/x86_64-linux-gnu/13/include \
LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64 \
cargo test --release --manifest-path performance/realworld/rust-h5i-gpu/backend-nvvm/Cargo.toml --locked --lib -- --ignored
```

## Workload scope

The unchanged seven HTTP scenarios remain the comparison. `feed`, `create`,
`favorite` and their portion of `mixed` execute GPU policy decisions. Guest
`list` and `slug`, and bcrypt-dominated `login`, do not execute this subset and
serve as controls. A policy decision is tiny, often just several comparisons;
no useful GPU speedup is presumed. No artificial bulk API, extra scanning or
heavier computation is added to make the GPU look better.
