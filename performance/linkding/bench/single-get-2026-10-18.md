# Linkding optimized single-bookmark retrieval

2026-10-18. Based on benchmark revision `48dd5b48805d74ff7b6ab173d3d8835598e14ded`.
The only application-code change is
`rust-h5i-optimized/server/src/main.rs::bookmark_get`.

## Change and safety boundary

The optimized server used to fetch a bookmark for the kernel's ownership check,
then fetch the same ID again for the response. It now retains the first row,
passes the same existence/owner/shared facts to the unchanged `ReadBookmark`
decision, and serializes that retained row only after authorization succeeds.
This removes one sequential SELECT and one pool checkout on a successful get;
authentication and tag lookup remain. Invalid IDs, absent rows, invalid tokens,
guests and other owners still follow the existing refusal path.

The kernel, generated Lean, theorem sources, schema and dependencies are
unchanged. `h5i app check` passes: 16 theorems in one module, with only
`propext`, `Classical.choice` and `Quot.sound`. Release Rust tests pass
(two parser tests). Both before and after pass all nine shared Hurl files,
200 HTTP requests each, including authentication, ownership, sharing and tags.
The shell and handwritten SQL remain outside the Lean proof boundary;
rechecking the kernel does not constitute a proof of the HTTP/database shell.
The response now uses the row whose ownership was checked, removing the second
bookmark-read race. Authentication and tags still use separate database reads;
this is not a new transaction or snapshot guarantee.

## HTTP results

| Clients | Before req/s | After req/s | After / before | Go req/s | Before p99 ms | After p99 ms | Go p99 ms |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 331.60 | 399.48 | 1.20x | 402.78 | 9.90 | 8.71 | 8.58 |
| 64 | 2866.83 | 3676.61 | 1.28x | 6450.85 | 40.07 | 32.59 | 23.29 |

Means of three repetitions. Percentile columns average the per-repetition
percentiles, rather than pooling requests. See [summary CSV](results/single-get-2026-10-18/summary.csv)
for dispersion and [per-point CSV](results/single-get-2026-10-18/points.csv).
All 18 measured points completed: 636,179 HTTP requests, zero failed
requests and zero failed k6 checks. Warmup results are excluded.

## Conditions and interpretation

The existing shared `get` workload performs HTTP authentication, bookmark
retrieval, ownership enforcement, tag lookup and JSON response generation;
it varies bookmark IDs over the shared seed of 100000 bookmarks and 2000 tags.
Each point stops the server, reseeds and ANALYZEs the shared tables, restarts
the server, warms up for five seconds, then measures for 15 seconds, with the
existing five-second drain and one TCP connection per request. Concurrency is
1 and 64. Each variant uses four server CPUs, four PostgreSQL CPUs and four client
CPUs, four runtime workers and a 32-connection pool. Three variants run
concurrently in independent PostgreSQL containers. PostgreSQL 16 uses 512 MiB
shared buffers and 1 GiB shared memory per container, with data on `/dev/shm`.

| Slot | Server CPUs | PostgreSQL CPUs | Client CPUs |
| --- | --- | --- | --- |
| A | 0–3 | 4–7 | 8–11 |
| B | 12–15 | 16–19 | 20–23 |
| C | 24–27 | 28–31 | 32–35 |

The assignment to slots A/B/C is before/after/Go, after/Go/before, then
Go/before/after. Each implementation occupies each slot once. Each point
reseeds its slot's database and starts a fresh server. This measures variants
in the same time window and balances CPU/database placement across repeats.
The two Rust binaries use identical locked dependencies and release build
settings; only the route change differs. Go is rebuilt from the same benchmark
revision. Builds, tests and proofs finish before load measurement.

Host: dual AMD EPYC 7502; Rust 1.98.1, Go 1.27.2. The host is shared; clocks
and NUMA placement are not controlled. Other CPU-heavy jobs were active during
the experiment. Concurrent runs and slot rotation reduce time/placement bias,
but do not provide isolation or a confidence interval. Artifact hashes,
environment and raw k6/server logs remain locally under
`/dev/shm/h5i-single-get`; only CSV/Markdown summaries are published.

A separate logged HTTP request for bookmark 18 confirms four executed SELECTs
before and three after, with bookmark SELECTs falling from two to one and an
identical response body ([checks CSV](results/single-get-2026-10-18/checks.csv)).
SQL logging was enabled only for this diagnostic, not the throughput runs.
This validates the removed round trip; it does not attribute every change in
HTTP timing to that round trip.

### Earlier sequential series

Before the concurrent run, all three variants were measured sequentially in
rotating order, also with three repetitions and concurrency 1/64. During this
series the host load rose sharply: a read-only observation recorded load
averages of `207.66, 77.75, 29.45` and four CPU-heavy processes each using
roughly 26–29 logical CPUs. Other jobs were left untouched. Sequential results
were sensitive to timing: at 64 clients the before runs were approximately
6334, 3396 and 4247 req/s. We therefore added the concurrent, placement-balanced
comparison above rather than interpreting a sequential average as a causal
speedup. All sequential observations are retained in
[serial summary](results/single-get-2026-10-18/serial-summary.csv) and
[serial points](results/single-get-2026-10-18/serial-points.csv): 18 points,
784,795 measured requests, zero failed requests/checks. The two series are
not pooled. The sequential averages were 375.97 → 484.02 req/s at one client
and 4658.89 → 4263.05 at 64 clients; the latter is a regression in that series,
not an omitted measurement. No assertion about its exact cause follows from
the host-load observation alone.

These results supersede neither the original cross-language table nor the
SQL-mode/list experiments: CPU allocation, run length and toolchain differ.
Only optimized single-bookmark retrieval changed. The normal h5i-app engine,
GPU implementation, list, search, writes and mixed workloads were not changed
or remeasured. The paired Go numbers apply to this endpoint and setup only.
No claim about power/cost or whole-application speed follows from them.

## Reproduction

Save release binaries from revision `48dd5b4` (before), this revision (after),
and its unchanged Go implementation. Put build outputs, Go/Cargo caches and
temporary files under `/dev/shm`. Then run the committed controlled runner:

```sh
python3 performance/linkding/bench/remeasure-get.py \
  --before /dev/shm/get-binaries/before \
  --after /dev/shm/get-binaries/after \
  --go /dev/shm/get-binaries/go \
  --out /dev/shm/linkding-get-reproduction
```

The output directory must not exist. Defaults are the measured CPU slots,
PostgreSQL ports 15725–15727, HTTP ports 18425–18427, five-second warmup,
15-second measurement, concurrency 1/64 and three slot rotations. The runner
uses the existing `scripts/bench-all.sh` and `bench/workload.js`; it records
binary hashes/configuration and removes its own containers afterwards.
It requires Docker, prebuilt binaries and k6 (override `--k6` if needed).
Conformance and proof validation are separate: run `scripts/test-one.sh`
against each Rust binary using a private database, and `h5i app check` on
`rust-h5i-optimized`. Publish only summary files, retaining raw outputs locally.
