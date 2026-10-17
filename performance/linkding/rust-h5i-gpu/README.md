# rust-h5i-gpu — linkding bookmark search on the GPU

A GPU variant of the linkding bookmark-search benchmark. It **reuses** the
verified `linkding-kernel` from [`../rust-h5i/kernel`](../rust-h5i/kernel) (the
parser and the real `bookmark_matches` matcher) and **imports** the GPU launch
shell `h5i-app-gpu` from the h5i framework. The only GPU-specific code here is:

- `src/predicate.rs` — a bounded, allocation-free restatement of linkding's
  postfix AST evaluator, compiled onto the device (the Vec-based kernel cannot
  run under `no_std`/no-alloc). It is differential-checked against the real
  `linkding-kernel::bookmark_matches` (see `src/lib.rs` tests).
- `src/pack.rs` — packs bookmarks and a parsed query into the flat SoA columns
  the kernel reads.
- `backend-nvvm/` — the Rust-CUDA resident launch of the `linkding_batch`
  kernel, built on `h5i-app-gpu`'s NVVM shell.

Nothing here reimplements linkding; the predicate above is the device kernel,
verified against the library.

## CPU core (runs anywhere, incl. CI)

```
cargo test        # packs rows, evaluates on CPU, checks against bookmark_matches
```

## GPU benchmark (host-only — needs a GPU, CUDA 12.6 + libNVVM, the Rust-CUDA nightly)

There is **no GPU in GitHub Actions**, so the GPU path is never built in CI. On
a CUDA host:

```
backend-nvvm/setup.sh         # one-time toolchain (Rust-CUDA nightly, under /var/tmp)
backend-nvvm/measure.sh       # builds the linkding_batch PTX and runs the benchmark
```

## Measured (100k bookmarks, GPU 0 = RTX 3090, CUDA 12.6)

| Query        | CPU 16 threads | Resident GPU | GPU, uploading each call |
|--------------|---------------:|-------------:|-------------------------:|
| `alpha`      | 5.35 ms        | **0.39 ms**  | 10.05 ms                 |
| eight terms  | 28.23 ms       | **5.70 ms**  | 17.12 ms                 |

Resident GPU is ~**13.7×** the bounded 16-thread CPU scan for the heavy query,
once the bookmark columns are resident on the device (the one-time upload
dominates a cold call, so residency is the point). These are scan times, not
end-to-end HTTP latency. Correctness: the device predicate matches the
independent `bookmark_matches` and the CPU path byte-for-byte across the
differential suite.

Trusted: rustc, NVVM/libNVVM, the driver, and the launch/layout/bounds shell.
Lean says nothing about GPU execution; equivalence is established empirically by
the differential tests, not proved. FNV-1a tag hashes can collide; fixed
text/tag/node capacities reject oversized inputs.
