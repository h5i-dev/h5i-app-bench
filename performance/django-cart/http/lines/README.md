# Increasing the work per cart

This experiment measures **32, 128, 512 and 2,048 lines per cart** through the
same `GET /carts/{id}/total` API. The population stays at 4,096 carts, so the
PostgreSQL item table contains 131,072, 524,288, 2,097,152 and 8,388,608 rows.
Unlike the earlier database-size sweep, every requested cart now requires more
line work. The 32-line original snapshot format and HTTP adapters remain
available; separate wide adapters use a runtime-sized row format.

[Measured results](results/2026-10-19/summary.md) are published to the normal
[performance dashboard](../../../../docs/performance/index.html).

## Implementations and controlled conditions

| Implementation | SQL work | Calculation |
| --- | --- | --- |
| Go / JavaScript / Rust `*-sql` | Per-request PostgreSQL `SUM(price * quantity)`, pool of 16 | CPU applies discount and rounds cents |
| Go / JavaScript / Rust `*-batch` CPU | One shared worker, one raw-line query for collected cart IDs | Sequential line sum and discount |
| `rust-cpu-parallel` | Same raw-line batch query | Four persistent Rayon workers distribute carts, summing each cart's lines sequentially |
| `rust-gpu-batch` | Same raw-line batch query | One GPU thread per cart, SoA input |
| `rust-gpu-cooperative` | Same raw-line batch query | One 32-thread warp/block per cart; lanes sum disjoint lines, then perform a warp reduction; row-major input |

Every batched adapter collects up to 256 requests with a 1 ms collection
window and a bounded 4,096-request queue. One SQL worker serializes batches.
Duplicate cart IDs share fetched data within a batch; every new batch reads
PostgreSQL. CUDA allocates and transfers fresh input each time and downloads
all totals. The scalar GPU transpose is included in its computation-stage and
HTTP time. The cooperative kernel reads adjacent item prices/quantities in
adjacent lanes and needs no transpose. The scalar grid is `ceil(carts/128)` blocks: at this experiment's 256-request
limit it launches at most two blocks. Cooperative launches one 32-thread block
per distinct cart, at most 256 blocks. These mappings do not establish optimal
GPU utilization or the best possible CUDA implementation. Neither GPU implementation keeps input
resident across HTTP batches. A CPU/GPU comparison therefore includes placement
costs; it does not compare kernel arithmetic alone.

The Rust serial CPU/GPU pair isolates placement with the same fetch, packing,
queue and response code. The parallel CPU is an additional stronger baseline.
Native SQL avoids sending raw lines to the server and uses a different query
and connection model; its performance remains part of the comparison.

Each server, PostgreSQL and k6 gets four separate CPU cores (64–67, 68–71 and
72–75 respectively). Rust's four Rayon workers share its server's four-core
allocation with HTTP threads. Go uses `GOMAXPROCS=4`; Node uses its normal event
loop. CUDA uses RTX 3090 device 0. No CPU cache of totals is enabled. The read
API and fixed generator have the same no-cache semantics in all variants.

The matrix has nine implementations × four line counts × 16/256 concurrent
clients × three repetitions: **216 points**. Each point uses a fresh server,
one-second warmup and five-second measurement; variant order is deterministically
shuffled within each line-count/client/repetition block. PostgreSQL remains
running across variants. Seeding and CUDA context/module initialization are
excluded. Data comes from the same deterministic generator as the previous
HTTP experiment; counts, prices, quantities and discount kinds are identical
between implementations.

k6 precomputes the expected totals once per process into a `SharedArray`.
Response checks perform a lookup, rather than recomputing 2,048 lines in every
virtual user on every response. Each response must have the exact cart ID and
integer cents. The number of requested carts is fixed independently of lines.

## Correctness and numeric bounds

`oracle.py` checks the pinned upstream commit and calls its actual unmodified
Django `Cart.total()`/discount methods, supplying a Decimal subtotal. It produces
166/190/214/238 cases at 32/128/512/2,048 lines. Cases cover empty and sparse
carts, counts around 32/128/512 boundaries, full carts, maximum prices and
quantities, percentage rounding, percentages above 100%, fixed discounts and
128 random cases per shape. Four additional cases within each reported count
exercise actual ORM `SUM` at that full line count; SQLite amounts are exactly
representable. These correctness runs are not Django performance results.

Before load, all nine servers must agree with every case at each line cap.
Committed insert/delete checks use a nonconsecutive final slot and verify the
very next response. Invalid and missing IDs are checked too. The cooperative
kernel's correctness checks include fewer than 32 lines, empty input carts,
uneven line counts, and full-size boundary values.

Unit prices are bounded to 99,999,999 cents and quantity to 1–1,000. At 2,048
lines the maximum subtotal is 204,799,997,952,000 cents. Subtotals remain exactly
representable as JavaScript integers; percentage rounding uses quotient and
remainder, avoiding unsafe scaled floating-point values. Rust/Go's scaled
intermediates stay below `u64::MAX`. The existing none/percentage/fixed discount
contract, half-up cents rounding and zero default tax/shipping are unchanged.
2,048 lines is this experiment's bound, not an upstream maximum. Eligibility,
promotion search, sessions and checkout transactions are not added.

## Reported measurements and limits

`points.csv` contains every repetition's HTTP throughput, p50/p90/p99, zero-error
checks, request/SQL/launch counts, actual requests per batch, queue wait, and
sampled peak server CPU/RSS. Sampling is every 100 ms and excludes PostgreSQL
and GPU memory. CPU percent aggregates threads and can exceed 100%.

The four Rust batch variants additionally record these wall-time phases:

- **Fetch**: PostgreSQL query execution, network transfer and sqlx row decoding.
- **Pack**: extracting decoded fields, growing buffers and constructing snapshots.
- **Compute**: serial/parallel CPU pricing, or complete GPU preparation, fresh
  allocation/upload, kernel, synchronization, full download and error validation.

They are averages per SQL batch, not per request. The compute timer excludes
ID→total map construction and response delivery. Queue time, HTTP and other
unmeasured overhead prevent these phase means from summing to an HTTP percentile.
GPU compute is deliberately not presented as kernel-only time. SQL/Go/Node
variants do not have these phase timers, represented as unmeasured rather than
zero. `summary.csv` reports means across repetitions and sample RPS deviation.

The summarizer refuses incomplete/duplicate grids, any HTTP or value-check
failure, missing conformance, incorrect cart population/line count, nonfinite
metrics and inconsistent request/SQL/launch/batch accounting.

These are read-only adapters for a library contract, not measurements of a
Django deployment or an h5i engine speedup. All processes share one host;
NUMA placement, clocks, background activity and power are uncontrolled.
PostgreSQL/cache conditions are warm from seeding and previous variants,
not a controlled cold-cache experiment. The largest table exceeds the
configured 512 MB PostgreSQL buffer pool; OS caching is not isolated.
Short repeated runs support this host's comparison, not a production SLA.

Increasing lines scales both the sum's arithmetic and the raw data fetched,
decoded and uploaded. It does not increase arithmetic work per input byte.
This sweep therefore tests the full-fetch architecture, not whether an
efficiently supplied GPU can outperform CPU aggregation. A follow-up that
removes repeated fetch/packing would need equivalent CPU and GPU data reuse,
exact results, and measured update propagation as well as query latency.
The separate placement diagnostic below excludes SQL; it does not supply that
missing end-to-end experiment.

## Reproduce

Requirements and toolchain pins are the same as the [parent HTTP benchmark](../README.md).
Default tools and artifacts live under `/var/tmp`; all runner paths can be
changed with `--help`.

```sh
performance/django-cart/http/lines/build.sh
python3 performance/django-cart/http/lines/run.py
python3 performance/django-cart/http/lines/summarize.py
python3 performance/site.py
```

The runner creates and removes its own temporary PostgreSQL container. It
records the actual database process affinity, Docker image ID, tool versions,
source and binary/PTX hashes and oracle hash in `environment.json`.
Raw k6 exports and server logs remain in `/var/tmp/cart-lines-evaluation`.
The committed artifacts contain the complete joined per-repetition points,
correctness gates, metadata and generated summary.

## GPU implementation and placement diagnostic

A separate [placement diagnostic](results/2026-10-19/placement.md) compares the
same scalar/cooperative kernels with fresh allocation, reusable buffers with
fresh uploads, and resident input. It also reports CUDA event intervals around
individual kernel launches. It runs after HTTP load, using 8/128/256 carts per
batch, one/four CPU workers, three repetitions and 100 iterations per sample.
It diagnoses the current implementation; it does not establish optimal CUDA
performance or an HTTP speedup from residency. Frozen inputs, fixed method
order and event/host submission overhead limit interpretation.

Build the diagnostic example with the same environment as `build.sh`, adding
`--example profile_lines` to the Cargo build. Then, after the HTTP run finishes:

```sh
python3 performance/django-cart/http/lines/profile.py
```

Buffer reuse is a measured diagnostic path and has not been applied to the
HTTP servers. Allocation/copy/launch overlap, pinned host buffers, different
block sizes and larger batches remain possible implementation improvements.
