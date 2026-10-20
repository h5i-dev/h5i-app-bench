# Resident carts and immediately visible updates

The [full-fetch HTTP experiment](../http/lines/results/2026-10-19/summary.md)
spent over 99% of the measured CPU phases fetching and packing lines. Increasing
lines also increased that input cost, without increasing arithmetic per byte.
This experiment removes repeated full fetch/packing on **both** CPU and GPU.
It then measures line-update application and queries against resident state.

[Results](results/2026-10-19/summary.md) ·
[Interactive dashboard](../../../docs/performance/index.html#cart-resident)

The [larger-population follow-up](scale/README.md) adds grouped single/four-thread
CPU incremental totals and scales to 65,536 carts. The earlier results below
retain their original five implementations; use the follow-up for comparisons
against parallel CPU delta.

## Measured findings

The completed run checked **116,328,960 totals across 960 points**. Removing
repeated fetching exposes GPU wins for sufficiently large update batches,
including against CPU incremental totals. It does not make sparse updates a
good GPU workload. Representative means, including event application and result
retrieval, in microseconds per batch:

| Lines/cart | Queried carts | Line replacements | Best measured CPU | Best measured GPU | CPU/GPU |
| --- | --- | --- | ---: | ---: | ---: |
| 2,048 | 128 | 1 | 0.399 | 16.578 | 0.024× |
| 2,048 | 4,096 | 4,096 | 187.159 | 49.036 | 3.82× |
| 2,048 | 4,096 | 65,536 | 1,989.707 | 337.318 | 5.90× |
| 512 | 4,096 | 65,536 | 1,836.039 | 281.604 | 6.52× |

For 2,048 lines and 4,096 queries with no updates, GPU full scanning beats the
fastest measured CPU full scan by 20.77×. But CPU cached totals take 4.226 µs,
versus GPU cached totals at 24.218 µs. Reporting only the scan comparison would
hide the better CPU algorithm. Update volume and queried-cart count matter
more than line count alone; the largest line count is not always the fastest
GPU/CPU ratio.

CPU delta is single-threaded; the four-worker CPU path performs full rescans.
A parallel incremental CPU implementation was not measured in this initial run;
it is included in the [follow-up](scale/README.md). These ratios describe the
initial measured implementations. Go and JavaScript are
covered by the earlier HTTP comparisons, not this initial resident experiment.
The [cross-language resident follow-up](languages/README.md) adds Go, JavaScript,
CPython and NumPy with changing updates and complete outputs.
Database-to-cache delivery costs remain outside this experiment.

## What is compared

| Backend | Retained state | Per update-and-query batch |
| --- | --- | --- |
| CPU scan 1T | All cart rows | Apply replacements; fully recalculate queried carts |
| CPU scan 4T | All cart rows | Apply replacements; four persistent Rayon workers recalculate queried carts |
| CPU delta | Rows, subtotals and final totals | Adjust each changed line's contribution; update each changed cart's discount once; gather requested totals |
| GPU scan | All cart rows on GPU | Upload IDs/replacements; scatter changes; one 32-thread block recalculates each queried cart; download every result |
| GPU delta | Rows, subtotals and final totals on GPU | Upload IDs/replacements; one thread per query applies that cart's changes and updates cached totals; download every result |

CPU delta is an essential baseline: plain sums are incrementally maintainable.
Comparing only full rescans would overstate the value of GPU acceleration for
this contract. GPU delta receives the same opportunity to reuse subtotals.
All backends retain the same **4,096 carts**; a small query does not reduce
the resident population. Rows keep the existing wide snapshot layout. Values
are integer cents with the same discount and half-up rounding contract.

## Workload and measurement

- Lines/cart: **32, 128, 512, 2,048**.
- Queries/batch: **8, 128, 256, 4,096**, distinct IDs rotating through all carts.
  4,096 is a bulk calculation, beyond the earlier HTTP batch limit.
- Replacements before every batch: **0, 1, one per queried cart, sixteen per
  queried cart**. Both price and quantity are replaced; some events use maximum
  price/quantity bounds. Cart cardinality and discount metadata stay fixed.
- Three repetitions of 100 measured rounds after eight checked warmups. Five
  backends × four line counts × four batch sizes × four update profiles × three
  repetitions = **960 points**. Variant order rotates/reverses across repetitions.
- Each round starts from a normalized, valid event buffer. Query IDs are first,
  followed by `(cart, slot, new_price, new_quantity)` records. Changes are
  round-robin across query carts; there are no duplicate query IDs or patched
  slots within a round. This permits race-free GPU updates without atomics.
- CPU timers include applying events, calculating/gathering totals and result
  allocation. GPU timers include command upload to reusable buffers, all update
  and query kernels, synchronization, complete download and error checking.
  Timers stop before independent result comparisons on both CPU and GPU.
- Trace generation, validation of incoming events, independent oracle work,
  population generation and CUDA context/module setup are excluded. `init_ms`
  separately measures initial placement. Incremental initialization includes
  a host subtotal pass on either backend. Initial rebuild costs are not amortized
  into the repeated batch means.

CPU/GPU runs use CPUs 64–67 and RTX 3090 device 0. Four CPU workers share that
four-core affinity with the calling thread. Timings use the same shared host
as the HTTP experiment; clocks, NUMA, background activity and cache effects are
uncontrolled. These are synchronous batches with no queue/launch overlap.
Full scans validate every accessed line; delta paths rely on validated events
and retained invariants rather than revalidating unchanged rows.

## Freshness and correctness

Before timing, all five paths pass all 808 cases generated from the pinned
upstream Django Decimal methods: empty/sparse carts, boundary line counts,
maximum amounts/quantities, discount clamping and rounding. The corpus hash
must match the completed HTTP sweep's recorded upstream corpus.

Every warmup and measured output vector is checked exactly against a separate
full-rescan state machine after the same updates. Traces change values and
query membership across rounds. This detects stale totals, incorrect per-line
deltas, rounding differences and loss of earlier updates. Checksums must also
agree across all variants/repetitions. The summarizer rejects incomplete grids,
duplicates, invalid metrics or incorrect data/byte/check accounting.

This demonstrates update visibility **inside one process**. Database commit,
CDC delivery, durable recovery, concurrent writers, insertion/deletion, retry
semantics and cross-process coherence are not measured. It is not an HTTP
benchmark or a completed production cache architecture. A practical follow-up
must account for those costs before making an application speedup claim.

## Reproduce

Use the [existing CUDA toolchain](../README.md). The separate resident device
crate/lockfile preserves the earlier experiment's device source and PTX.
The NVVM codegen backend must already exist in `/var/tmp/h5i-gpu-target/release`.

```sh
bash performance/django-cart/resident/build.sh
# Regenerate only if the previously verified corpus is absent:
/var/tmp/django-cart-bench-venv/bin/python performance/django-cart/http/lines/oracle.py
python3 performance/django-cart/resident/run.py
python3 performance/site.py
```

The runner records source/binary/PTX/oracle hashes, affinity and hardware data.
`points.csv` preserves each repetition's mean and iteration p50/p99; the summary
averages repetition means and reports sample standard deviation. Averaged
percentiles are not pooled percentiles. Inspect initial placement separately
when evaluating startup/rebuild frequency.
