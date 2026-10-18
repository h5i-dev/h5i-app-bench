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

Resident GPU is ~**13.7×** the bounded 16-thread CPU scan for `alpha` and
~**5.0×** for eight terms,
once the bookmark columns are resident on the device (the one-time upload
dominates a cold call, so residency is the point). These are scan times, not
end-to-end HTTP latency. Correctness: the device predicate matches the
independent `bookmark_matches` and the CPU path byte-for-byte across the
differential suite.

Trusted: rustc, NVVM/libNVVM, the driver, and the launch/layout/bounds shell.
Lean says nothing about GPU execution; equivalence is established empirically by
the differential tests, not proved. FNV-1a tag hashes can collide; fixed
text/tag/node capacities reject oversized inputs.

## HTTP search execution and cache limits

The server creates, uses and destroys resident indices on one dedicated OS
thread, including their CUDA contexts. A bounded queue keeps synchronous
upload/scan/download work off Tokio workers. CPU-only builds use the same
queue and cache with the packed CPU predicate.

`H5I_SEARCH_QUEUE` defaults to 32 queued jobs, `H5I_SEARCH_CACHE_ENTRIES` to 8
indices, and `H5I_SEARCH_CACHE_MIB` to 256 MiB. Cache accounting includes host
column capacities and device columns/output buffers, but excludes CUDA
context/module overhead, temporary query buffers and SQL load results. The
queue limit bounds job count, not the total size of bookmark facts awaiting
upload. Indices are evicted in least-recently-used order. Setting the entry
or byte budget to zero disables index construction and keeps SQL search.

Every successful API write invalidates all indices. Generation checks reject
loads/scans that overlap invalidation, including a DB load started before a
write. This is a process-local read cache; writes from other server processes
or direct SQL clients do not invalidate it. It does not provide transaction
snapshot isolation across the scan and subsequent SQL listing query.

A full/stopped queue, initialization failure, exhausted cache budget, malformed
output, or any row error returns to the existing SQL search predicate. Oversized
fields, tag sets and queries must therefore never silently become missing
search results. CPU-only builds reject the same bounded-predicate errors.

The timings above are historical scan measurements. The worker/cache changes
need fresh HTTP measurements before drawing conclusions about request speedup.

Worker/cache regression checks (use `--release` on space-limited checkouts):

```sh
cargo test --release --workspace --locked
# CUDA host, with the existing linkding_batch PTX:
LINKDING_TEST_PTX=/path/to/linkding_gpu_device.ptx \
  cargo test --release -p linkding-gpu-server --features gpu --locked -- --ignored
```

The ignored GPU test exercises multiple resident owners, cache reuse,
invalidation and row-error rejection on a real device. The shared HTTP suite
also includes `tests/resident-search.hurl` for update/delete invalidation,
tenant isolation and SQL fallback for a field exceeding the device capacity.
