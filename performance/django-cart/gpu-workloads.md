# Where GPU pricing could help

## Completed follow-ups

The [32–2,048-line HTTP sweep](http/lines/results/2026-10-19/summary.md)
now includes phase attribution and cooperative CUDA. Fetching/packing still
dominates and GPU does not beat the best CPU/SQL adapter. The
[placement diagnostic](http/lines/results/2026-10-19/placement.md) separates
allocation, transfer and resident calculation costs.

The [resident update experiment](resident/README.md) then retains rows on both
CPU and GPU, applies identical changes, and checks immediate visibility. It
includes CPU/GPU incremental subtotals. At 2,048 lines × 4,096 queried carts,
one replacement per cart takes 187.159 µs on CPU delta versus 49.036 µs on GPU
delta (3.82×). With only one replacement across 128 queried carts, CPU delta
takes 0.399 µs versus 16.578 µs on GPU delta. Large update batches can benefit;
sparse updates favor CPU. These are in-process calculation measurements, with
GPU command upload and complete result download; database commit/CDC, HTTP and
durable cache synchronization remain unmeasured. CPU delta is single-threaded;
parallel CPU delta was not measured in that initial experiment. The
[larger-batch follow-up](resident/scale/README.md) adds grouped single/four-thread
CPU delta and scales population and update counts. See the linked methods for
all limits.

That follow-up checked 378 points and 628,604,928 exact totals. Its fastest CPU
path was grouped four-thread delta in every shape. The maximum measured GPU
advantage was **5.94×** at 65,536 carts × 2,048 lines, one changed line per cart
(CPU 2.290 ms, GPU 0.385 ms). No shape reached 10×; more updates did not
monotonically improve the ratio. The earlier 512-line/4,096-cart/16-updates shape
fell to 1.79× with the parallel CPU baseline. Larger data alone does not establish
the desired speedup for this sum contract.

## Original workload assessment

The original HTTP experiment evaluates one cart per request, at most 32 lines.
Growing the database increases the number of possible cart IDs, not the work
in one request. Its collector accepts at most 256 requests, and duplicate IDs
can further reduce the number of GPU threads. A large database alone does not
make this a large GPU calculation.

The current kernel maps one unique cart to one thread, with 128 threads per
block. Thus the HTTP batch limit permits at most two blocks per launch; the
262,144-cart snapshot uses 2,048 blocks. This is a concrete parallelism limit,
not evidence that the HTTP path has saturated GPU compute. Increasing an online
collection window also adds latency, so bulk jobs need a separate latency and
throughput target.

The original HTTP measurements include queueing, PostgreSQL, packing,
allocation, transfer, calculation and JSON without timing these phases
separately. The later line-count sweep adds this attribution.

## Evidence from the existing snapshot experiment

Median repetition means for 262,144 carts × 32 lines, in milliseconds:

| Path | Time |
| --- | ---: |
| Rust, 16 CPU threads | 2.882119 |
| GPU with inputs already resident, full output download | 0.619836 |
| GPU with input upload on every iteration | 149.375756 |
| Initial resident-input preparation/upload, separately recorded | 151.553882 |

See the [snapshot summary](bench/results/2026-10-19-scale-soa/summary.md)
and [method](README.md#measurement). These are calculation measurements, not
HTTP times. The resident path is 4.65× faster than the measured 16-thread CPU
path. Fresh transfer eliminates that advantage. Residency excludes initial
preparation/upload; it includes launches, synchronization and complete totals
download. Input packing from a live database is excluded from both snapshot
paths. The CPU baseline also receives already-loaded input.

The measured resident loop repeats unchanged input. An application could cache
those totals on the CPU, too. Repeating that loop does not demonstrate useful
application acceleration.

## Candidate: bulk repricing after changes

Evaluate many carts against a changed product-price table. Keep cart membership
and quantities resident, update changed prices, and recompute affected totals.
Return or persist results tied to the committed price version. This makes reuse
useful: the large membership data persists while the calculation's inputs and
answers change.

This is a new workload. The pinned django-cart contract stores each item's
price; it does not specify that catalogue changes retroactively reprice carts.
A benchmark must define that behavior explicitly. Compare a CPU implementation
with the same resident data, reverse index of affected carts, incremental
updates, and ability to cache unaffected totals. Repricing every cart on the GPU
while the CPU updates only affected carts would be a different comparison.

Measure small and large change fractions. A small update touching few carts
may favor the CPU even when a global price change favors GPU throughput.

## First controlled extension: more work per cart

Sweep 32, 128, 512 and 2,048 lines per cart while independently varying the
number of requested carts. The current 32-line cap is a benchmark packing and
validation limit, not a limit established for the upstream library. This sweep
requires variable-size storage and equivalent correctness checks in every
implementation; simply changing a generator argument would not extend the
current fixed-width kernel, schema or adapters.

Keep PostgreSQL SUM and optimized CPU baselines. More lines increase both
arithmetic and transferred bytes, so this does not improve arithmetic intensity
by itself. In the current one-thread-per-cart mapping, more lines also do not
increase the number of blocks. Compare a cooperative per-cart reduction as a
separate GPU implementation when carts are large; retain its launch and
reduction overhead in measured costs.

For heavier computation per byte, a further extension could determine discount
eligibility from many item/category/quantity conditions or evaluate valid
promotion combinations. Specify actual business rules, expected output and a
correctness oracle first. These are additional application semantics: the
pinned pricing calculation receives an already-applied discount and does not
perform that rule search. An artificial repeat loop would not establish an
application speedup.

The [line-count evaluation](http/lines/README.md) now implements this sweep with
Go, JavaScript, PostgreSQL SUM, Rust serial/parallel CPU and both scalar and
cooperative CUDA. [Measured results](http/lines/results/2026-10-19/summary.md)
include fresh-input HTTP throughput and fetch/pack/compute attribution.

## Candidate: evaluate multiple discount scenarios

For a frozen, versioned snapshot, calculate many distinct discount scenarios
and return their totals or a defined aggregate. Input membership can be reused
across scenarios, with small parameter updates. The existing none/percentage/
fixed discount contract can supply a first experiment without inventing new
pricing rules.

Both CPU and GPU should precompute each cart's subtotal once. Merely rerunning
the 32-line sum for every discount would miss that valid optimization. After
this optimization the remaining arithmetic is cheap, so scenario count,
parameter transfer and output size decide whether GPU execution helps. Complex
promotion eligibility or optimization would need a separately specified
contract and correctness oracle.

## Evaluation needed before publishing a speedup

Use the same logical operation and output for CPU and GPU. Sweep cart count,
affected-cart fraction and scenario count independently; do not use database
size as a substitute for GPU batch size. Include tuned multithreaded CPU and
Go/JavaScript implementations, and a database-side baseline where applicable.

Record initial load, committed-update propagation, affected-set construction,
packing/upload, calculation, download and result publication separately, plus
whole-operation latency and sustained throughput. Report both cold-start and
steady-state results. Include output bytes, CPU/GPU memory, queueing, p99 and
freshness checks under updates. Allow the CPU the same residency, caching and
precomputation optimizations.

These are proposed application experiments. The existing snapshot results show
potential under residency, and the [HTTP evaluation](http/README.md) evaluates
live request batching; neither measures these proposed update/scenario jobs.
