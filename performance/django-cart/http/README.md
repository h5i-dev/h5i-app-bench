# Live HTTP and SQL batching

`GET /carts/{id}/total` accepts an individual cart ID. Batch variants combine
independent requests from multiple connections, issue **one SQL query per
batch**, calculate the requested totals, and return each request's JSON
`{"id":1,"total_cents":123}`. The load generator never sends a pre-batched body.

This adapts the pinned django-cart pricing contract to a read-only API. The
upstream has no equivalent HTTP endpoint. Integer-cents tables are specific to
this benchmark; session lookup, authentication, writes, checkout transactions,
discount eligibility and tax/shipping plugins are outside its scope. This is
not a port of the complete Django application, a Django throughput score, or a
proof of an h5i-app engine speedup. The GPU path uses h5i's NVVM launch shell;
the new pricing code has differential tests and no Lean proof.

| Variant | Database | Calculation |
| --- | --- | --- |
| `go-sql`, `javascript-sql`, `rust-sql` | One SQL `SUM(price * quantity)` per request, up to 16 connections | Final discount and cents rounding on CPU |
| `go-batch`, `javascript-batch`, `rust-cpu-batch` | One shared worker, one `WHERE id = ANY(...)` raw-line query per batch | Sum, discount and rounding on CPU |
| `rust-gpu-single` | Same raw-line worker, batch limit 1, no collection delay | Fresh CUDA upload, kernel and complete result download per request |
| `rust-gpu-batch` | Same raw-line worker, up to 256 requests, 1 ms collection window | Fresh CUDA upload, kernel and complete result download per batch |

The SQL aggregate baseline follows the upstream's database-side summary model.
The batched CPU/GPU pair uses identical SQL, queueing and packed rows; it
isolates computation placement. Comparing native SQL to batching additionally
changes the database execution model and connection concurrency. All eight
variants run sequentially with the same four server CPU cores, four PostgreSQL
cores and four client cores. Go has `GOMAXPROCS=4`, Rust has four Tokio workers,
and Node.js uses its normal single event loop. Each batch path has one active
SQL worker; increasing connection parallelism is a separate tuning experiment.

The queue holds up to 4,096 waiting requests and returns 503 when full. The
collection deadline is measured from the first arrival; already-pending work
is drained up to the batch limit. Waiting behind the active batch can exceed
1 ms, and Node.js timers have a 1 ms floor. Reported end-to-end latency includes
both effects. Repeated IDs in a batch share fetched rows. Each new batch reads
PostgreSQL again, packs the returned lines and, for CUDA, transposes them to
SoA, allocates/uploads fresh buffers, launches, synchronizes, downloads and
validates every total. There is no resident input cache between batches.

The GPU has one thread per unique requested cart. A 65,536-cart database does
not imply a 65,536-cart GPU launch: only requests actually collected within the
batch are sent to CUDA. Average observed batch sizes appear on the dashboard.

## Correctness and measurement

The build first checks each language against 4,146 cases using the pinned
Django Decimal implementation, 49 actual ORM cases and six invalid snapshots.
The HTTP runner loads the valid corpus into PostgreSQL and checks all 4,146
responses from each variant. It changes an empty cart to a nonempty cart with
a nonconsecutive item slot, verifies the committed value immediately, deletes
the item and verifies zero. It also checks invalid IDs and missing carts.

The measured matrix has 4,096 and 65,536 carts, 32 lines per cart (131,072 and
2,097,152 item rows), and 1, 16, 64 and 256 concurrent clients. A deterministic
rotating ID sequence includes all three discount kinds and legacy percentages
above 100%. k6 checks the exact ID and cents for **every response**. The same
sequence is used by all variants, although faster implementations naturally
reach more IDs in the fixed measurement interval. No think time is inserted.

Each point starts a fresh server, warms up for one second, measures for five
seconds, and repeats three times. Variant order is deterministically shuffled
within each dataset/client/repetition block. PostgreSQL persists across those
variants, so results describe warm/shared-buffer conditions rather than a
controlled cold-cache experiment. All cores are on one shared host; clocks,
other workloads, NUMA placement and power are uncontrolled. CUDA context/module
initialization and database seeding occur before timing. No cost or power
comparison is made.

`points.csv` records k6 throughput/latency, exact-check failures, server request
counts, SQL calls, launches, mean batch size, mean queue wait, and sampled peak
server RSS/CPU. Resource sampling uses `/proc` every 100 ms and excludes the
PostgreSQL process and GPU memory. CPU percent aggregates all server threads,
so it may exceed 100%. Queue wait ends when a batch begins its SQL query.
`max_batch_since_start` includes warmup; the mean is from measured counter
deltas. The summarizer rejects incomplete/duplicate points, any HTTP/check
failure, and inconsistent request/SQL/launch accounting. Percentiles, counters
and peak resources in `summary.csv` are means across repetitions; RPS also
reports sample standard deviation.

## Reproduce

Requires Docker with a local `postgres:16` image, k6, Python 3.12+, Go, Node.js,
stable Rust, CUDA 12.6, an RTX 3090-compatible GPU and the existing pinned NVVM
nightly setup (see the parent README). Default artifact paths match the existing
benchmark toolchain under `/var/tmp`; all runner paths and CPU sets can be
overridden with `--help`.

```sh
GO_BIN=/var/tmp/go/bin/go performance/django-cart/http/build.sh
python3 performance/django-cart/http/run.py
python3 performance/django-cart/http/summarize.py
python3 performance/site.py
```

The runner owns a uniquely named temporary PostgreSQL container and removes it
on completion or an interrupt. It uses a `taskset` entrypoint to pin PostgreSQL
because this host does not enforce Docker's cgroup cpuset. See `environment.json`
for the image ID, actual PID 1 affinity, source/artifact hashes and tool versions.
Raw k6 exports and server logs remain under `--work`; the joined per-repetition
points, conformance evidence, metadata and generated summaries are published in
[results/2026-10-19](results/2026-10-19).

## Increasing work per cart

The [line-count experiment](lines/README.md) holds the population at 4,096 carts
and measures 32, 128, 512 and 2,048 lines per requested cart. It adds four-worker
CPU and cooperative CUDA baselines, with phase timings for SQL fetch/decode,
packing and complete CPU/GPU calculation. Its results appear in a separate
dashboard section, preserving the original 32-line experiment above.
