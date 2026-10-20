# Larger resident cart update batches

This follows the [4,096-cart resident experiment](../README.md), testing whether
larger batches still give GPU wins against parallel incremental CPU totals.
The existing cart-total semantics are unchanged; this is not a new promotion
or repricing contract.

[Results](results/2026-10-19/summary.md) ·
[Dashboard](../../../../docs/performance/index.html#cart-resident-scale)

## Findings

**No measured shape reached 10× against the fastest CPU implementation.**
The maximum was **5.94×**, at 65,536 carts × 2,048 lines with one changed line
per cart. Four-thread CPU delta took **2.290 ± 0.123 ms**, and GPU delta took
**0.385 ± 0.003 ms** per batch (mean ± sample standard deviation of three
repetition means). The paired repetition ratios were 5.59×, 6.03× and 6.21×.

At 65,536 carts × 2,048 lines:

| Replacements/cart | Best CPU ms | Best GPU ms | CPU/GPU |
| --- | ---: | ---: | ---: |
| 1 | 2.290 | 0.385 | 5.94× |
| 16 | 12.321 | 3.500 | 3.52× |
| 64 | 50.855 | 15.173 | 3.35× |

All 18 shapes selected grouped four-thread CPU delta as the fastest CPU path.
The earlier 512-line, 4,096-cart, 16-update/cart shape, reported at 6.52× against
single-thread CPU delta, measured **1.79×** here with the parallel baseline.
Increasing update volume did not monotonically increase the GPU advantage.
The largest event buffer is 134,742,016 bytes per batch; command transfer remains
included even though the full population is resident. This sweep does not
attribute GPU time among transfer and kernels, so it cannot establish which
phase dominates. A [separate changing-trace phase diagnostic](profile/README.md)
now measures upload, kernels, synchronization and full result download for four
selected conditions, retaining this sweep unchanged. The subsequent
[compact-input/pinned-buffer comparison](transport/README.md) includes encoding
costs and one/four-worker encoders.

All **378 points** completed with **628,604,928 exact totals checked**, plus
the upstream corpus. These findings apply to the measured total/update
implementations. Raising cart count or update volume alone did not demonstrate
a 10× gain; more computation per transferred byte is a separate workload to
evaluate, rather than an established result of this experiment.

## Matrix

- Retained carts and queried carts per batch: **4,096 / 16,384 / 65,536**.
  Every batch queries the entire retained population, in a permuted order.
- Lines/cart: **512 / 2,048**. Initial prices, quantities and discounts use the
  earlier deterministic generator. Each backend owns the full population.
- Updates/cart/batch: **1 / 16 / 64** distinct line replacements. Both price
  and quantity change, including maximum bounds. The event buffer is ordered
  round-robin across carts; line slots advance between rounds. No delay in
  update visibility is allowed. Counts and discount metadata remain fixed.
- Seven implementations × 18 shapes × three repetitions = **378 points**.
  Eight warmups followed by **50** measured changing rounds per point.
  Workload order is fixed; variant order rotates and reverses between repeats.

## CPU comparison

The earlier event-order incremental CPU path remains in the comparison, along
with one/four-thread full scans and both GPU paths. Two new CPU paths group all
patches for a cart, keeping its subtotal in a local variable and applying the
final discount once. The grouped algorithm runs on one thread or four
persistent Rayon workers. Both retain full rows, subtotals and final totals.
The reported CPU/GPU ratio takes the fastest of **all five CPU paths** and the
fastest of **both GPU paths**, based on the three-repetition mean per shape.

The parallel incremental implementation assigns each queried cart exclusively
to one worker. The query IDs are asserted unique before timing; the generated
round-robin trace gives every patch of a cart to that same owner. Full vectors
are checked after every round. No conflicting writers or arbitrary event
routing are covered by this contract.

## Measurement and correctness

CPU timing covers event application, subtotal/discount calculation and output
allocation/gather. GPU uses the unchanged resident kernels and reusable device
buffers: timings include fresh query/update upload, update/query kernels,
synchronization, complete output allocation/download and error checks. No
kernel-only numbers are used for the headline comparison.

A separate full-rescan oracle consumes every update while traces are built
outside timing. Every warmup and timed output must match exactly. All seven
implementations first pass the same 808 cases from the pinned upstream Django
Decimal corpus, whose hash must match the previous verified experiment.
The publication script rejects missing/duplicate points, incorrect byte/check
counts, nonfinite metrics or checksum differences across paths/repetitions.

Initial placement is recorded separately as `init_ms` and is not amortized into
batch means. CPU placement copies rows; GPU placement allocates/uploads them.
Incremental initialization computes host subtotals and final totals for either
backend. Population/trace generation, input validation, independent oracle work,
CUDA context and module loading are outside timing. At 65,536 × 2,048 lines,
each implementation retains about 2 GiB of cart rows. Large host-side traces
are also retained; this benchmark intentionally trades memory for reuse.

Runs share CPUs 64–67 and RTX 3090 device 0 with the earlier resident study.
Clocks, NUMA placement, cache effects and shared-host activity are uncontrolled.
Summary means and sample standard deviations use three repetition means.
p50/p99 are averages of within-repetition iteration percentiles, not pooled
percentiles; at 50 rounds, nearest-rank p99 is the maximum round.

This is a synchronous in-process Rust calculation benchmark. Database commits,
CDC delivery, durable recovery, concurrent writers, inserts/deletes, retries,
cross-process coherence, HTTP and Go/JavaScript are outside its scope. No claim
about a deployed Django service or optimal CPU/GPU hardware bounds follows.

## Reproduce

Keep the [previous toolchain and resident PTX](../README.md#reproduce). The new
host example and result directory preserve all earlier measured sources and
artifacts. Build the device PTX with the original resident build script if it
is not already available, then:

```sh
bash performance/django-cart/resident/scale/build.sh
python3 performance/django-cart/resident/scale/run.py --smoke --out /var/tmp/cart-resident-scale-smoke
python3 performance/django-cart/resident/scale/run.py
python3 -m unittest discover -s performance/django-cart/resident/scale -p 'test_*.py'
python3 performance/site.py
```

The smoke run checks zero/one/one-per-cart/sixteen-per-cart updates at 64 carts
and 32 lines using all seven paths, but is not published as the complete grid.
The full runner records exact source/artifact/oracle hashes, hardware and CPU
allocation in `environment.json`; raw per-repetition timings are in `points.csv`.
