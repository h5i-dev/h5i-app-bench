# Shared Linkding search and mixed HTTP remeasurement

Based on upstream main `894ebcc`, with the bounded resident worker and cache
configuration fixes reapplied (`82d144e`, `0759321`). The shared workload and
controlled runner were committed in `717d834` before this measurement.

This extends the existing Linkding API benchmark. It uses the same
`bench/workload.js`, `scripts/bench-all.sh`, seed, process sampler and summarizer
as the other endpoint scenarios. It measures HTTP requests through
authentication, database operations, search, pagination, tag fetching and JSON
responses. It does not measure the HTML UI, metadata scraping or background
jobs, which the existing benchmark also excludes.

## Workloads and conditions

- The original `search`: `q=alpha`, 1000 active matches, first page of 20.
- New `search_complex`:
  `(alpha or missing) and not (absent or unknown) and (example or bookmark) and not (zeta and beta)`.
  Same 1000 active matches and first page of 20. This avoids attributing the
  smaller response of an empty search to GPU acceleration. It is a synthetic
  boolean query on the existing seed, not a production query trace.
- The original `mixed`: intended operation distribution of 40% list, 20% simple
  search, 15% get, 10% tags, 8% update, 5% archive and 2% create. Selection follows
  the existing per-VU deterministic sequence; finite runs need not realize
  precisely these percentages. Warmup writes remain in the measurement dataset,
  as in the existing benchmark.

Each point reseeds 100000 bookmarks, 2000 tags and 50 users, stops the previous
server before reseeding, and starts a fresh server. This prevents stale resident
indices after direct SQL reseeding. Ten seconds of warmup precede 30 seconds of
measurement; concurrency 1 and 16, three repetitions. Initial index creation is
in warmup, while write-triggered invalidations and rebuilds during `mixed` are
included in measured requests. This is not a cold-start measurement.

Four variants run concurrently on disjoint CPU sets and separate PostgreSQL
16.15 containers (512 MiB shared buffers, 200 maximum connections):

| Variant | Server CPUs | PostgreSQL CPUs | Client CPUs |
| --- | --- | --- | --- |
| optimized SQL (`rust-h5i-optimized`) | 0–3 | 4–7 | 8–11 |
| resident CPU scan (`rust-h5i-cpu-scan`) | 12–15 | 16–19 | 20–23 |
| resident GPU scan (`rust-h5i-gpu`) | 24–27 | 28–31 | 32–35 |
| upstream Linkding 1.47.0 | 36–39 | 40–43 | 44–47 |

Host: dual AMD EPYC 7502, RTX 3090 device 0, NVIDIA driver 560.35.03, CUDA 12.6.
The machine is shared; clocks and NUMA allocation are not fixed. CPU affinity
was verified for native processes, PostgreSQL and the upstream container.
Native servers use four Tokio threads and a 32-connection database pool. CPU/GPU
scan builds use eight cache entries, a 256 MiB index budget and queue capacity
32. Upstream uses its pinned image's two-process/two-thread uWSGI configuration.

The CPU/GPU scan executables are the previously saved builds from `61e3cdb`;
their server, packing and backend sources are identical to `717d834`. PTX is
unchanged. The optimized SQL server was rebuilt from this worktree in release
mode with its lockfile. Artifact hashes, image digests, hardware, affinity,
configuration and benchmark revision are retained with the local raw results.
The scan binaries depend on h5i `0d52512`; the separate h5i API generalization
`15814c6` is not part of these executables and is not credited with a speedup.

## Results

Results are the mean of three repetitions. The latency columns average each
repetition's percentile; they are not percentiles pooled across requests. k6
request rate includes request draining, with the original five-second graceful
stop. See the published standard summary for dispersion, request counts and memory.

| Scenario | Concurrency | CPU scan req/s | GPU req/s | GPU / CPU throughput | CPU p99 ms | GPU p99 ms |
| --- | --- | --- | --- | --- | --- | --- |
| search | 1 | 34.69 | 65.26 | 1.88x | 34.54 | 15.89 |
| search | 16 | 96.32 | 668.96 | 6.94x | 201.47 | 46.30 |
| search_complex | 1 | 10.72 | 48.29 | 4.50x | 105.79 | 21.18 |
| search_complex | 16 | 15.26 | 190.91 | 12.51x | 1130.57 | 90.00 |
| mixed | 1 | 8.76 | 7.37 | 0.84x | 682.12 | 827.12 |
| mixed | 16 | 32.24 | 35.67 | 1.11x | 2720.28 | 2833.57 |

| Scenario | Concurrency | Optimized SQL req/s | CPU scan req/s | GPU req/s | Upstream req/s |
| --- | --- | --- | --- | --- | --- |
| search | 1 | 4.72 | 34.69 | 65.26 | 4.95 |
| search | 16 | 19.52 | 96.32 | 668.96 | 13.53 |
| search_complex | 1 | 2.26 | 10.72 | 48.29 | 1.86 |
| search_complex | 16 | 5.00 | 15.26 | 190.91 | 4.15 |
| mixed | 1 | 15.89 | 8.76 | 7.37 | 9.88 |
| mixed | 16 | 84.31 | 32.24 | 35.67 | 34.00 |

All 72 measurement points completed: 128022 measured HTTP requests, zero HTTP
failures and zero failed k6 checks. The complex search count/page checks passed
on every request. CPU and GPU also passed the expanded shared `search.hurl`
fixture (42 requests each), including the new expression on varied bookmarks.
A short four-variant smoke run preceded the full run; its timings are not used
here. The [summary](results/text-search-2026-10-17/summary.md) and
[per-point CSV](results/text-search-2026-10-17/points.csv) are published.
Raw k6 JSON, metadata and validation/server logs remain local and are not committed.

The measured `717d834` harness always stopped on k6 failures. The subsequent
compatibility adjustment makes that behavior explicit as `BENCH_STRICT=1` in
the controlled runner, while preserving the ordinary harness's ability to
continue recording overload failures. All measured points passed; this
reporting-policy adjustment does not require repeating their timings.

## Interpretation and scope

CPU scan and GPU scan use the same application source, resident-index design
and result path, so this is the useful comparison for optional GPU offload.
Optimized SQL and upstream also differ in query execution, caching and server
architecture; their ratios are not GPU-only speedups.

The large search-only gains do not carry over to mixed traffic. At concurrency
1, GPU throughput is lower than CPU scan; at concurrency 16, the gain is small
and p99 latency is slightly worse. Optimized SQL is faster than either scan
backend in this mixed workload. This is a useful limit of the optional backend,
not evidence that every request should use GPU search.

No SQL fallback was logged during either read-only text-search scenario for
CPU/GPU scan. Mixed concurrency-16 logs show invalidation-driven SQL fallback
on both paths. The code conservatively invalidates the index on writes and
loads the owner's searchable facts again; GPU index construction also creates
a CUDA context/module and uploads the columns. These are plausible sources of
the mixed-workload overhead, based on code and fallback logs. This run did not
separately time those stages, so it cannot assign the slowdown quantitatively.
Reusing the CUDA context, updating an index incrementally, or avoiding rebuilds
when writes are frequent are better next investigations than inferring
application-wide speedup from kernel or read-only search timings.

Only the two text searches and the existing mixed workload were rerun, for four
variants at concurrency 1/16. The full nine original endpoint scenarios, the
other languages, the h5i-app engine variant, and concurrency 64/256 were not
remeasured here. Existing published results remain separate because their CPU
allocations and measurement scope differ. This report does not establish a
whole-application speedup or a cost/power advantage.

## Reproduction

Build and retain separate CPU-only and GPU-feature binaries of
`rust-h5i-gpu/server`, plus a release build of `rust-h5i-optimized`. Then run:

```sh
python3 performance/linkding/bench/remeasure-text.py \
  --cpu-bin /var/tmp/h5i-remeasure-20261017/bin/cpu \
  --gpu-bin /var/tmp/h5i-remeasure-20261017/bin/gpu \
  --sql-bin performance/linkding/rust-h5i-optimized/target/release/linkding-server \
  --ptx /var/tmp/h5i-gpu-target/nvptx64-nvidia-cuda/release/linkding_gpu_device.ptx \
  --out /var/tmp/h5i-text-full-20261017
```

The output path must not exist. The runner uses its own containers and removes
them afterwards. Raw JSON/logs remain in the local output directory. Only
`summary.csv`, `summary.md` and `points.csv` are committed under
`bench/results/text-search-2026-10-17/`, following the existing benchmark convention.
