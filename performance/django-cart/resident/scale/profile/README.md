# Changing resident update phase diagnostics

This replays the [larger resident benchmark](../README.md) with phase attribution.
The original sources, binaries, PTX and results remain unchanged. The host
example copies its generator, independent full-rescan oracle, CPU paths and
GPU calls, and reuses the same resident PTX. This is a synchronous Rust
calculation diagnostic, excluding SQL/HTTP, CDC and durable cache coherence.

[Dashboard](../../../../../docs/performance/index.html#cart-update-phases)
[All phase measurements](results/2026-10-20/summary.md)

## Findings

**Command upload is the largest measured interval in the useful GPU paths;
result download is much smaller.** The upload API includes pageable staging
and driver costs, so this identifies an input-path bottleneck without proving
that PCIe bandwidth itself is the limiting resource.

The earlier 1.79× condition (4,096 × 512, 16 replacements/cart) reproduced at
**1.75×** with plain timing: CPU4 **527.384 ± 41.276 µs**, GPU scan
**301.852 ± 30.274 µs**. A separate host-timestamp replay took
**284.463 ± 2.733 µs**: upload **158.217 µs (55.6%)**, enqueue **5.502 µs**,
remaining execution/sync **106.771 µs**, allocate **0.650 µs**, download
**10.840 µs (3.8%)**, validation **2.482 µs**. Its event replay measured update
**18.126 µs** and full scan **52.891 µs**, with total **289.504 µs**.
These intervals are separate observations, not an additive decomposition of
the original plain total.

Host replay for the fastest GPU variant selected by this diagnostic's plain
means (all times ms; percentages of that host replay):

| Carts × lines | Updates/cart | GPU | Total ± SD | Upload | Execute/sync | Download | Upload share |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 4,096 × 512 | 16 | scan | 0.284 ± 0.003 | 0.158 | 0.107 | 0.011 | 55.6% |
| 65,536 × 2,048 | 1 | delta | 0.632 ± 0.410 | 0.437 | 0.084 | 0.061 | 69.2%* |
| 65,536 × 2,048 | 16 | delta | 3.611 ± 0.030 | 2.640 | 0.811 | 0.071 | 73.1% |
| 65,536 × 2,048 | 64 | delta | 14.749 ± 0.204 | 11.386 | 3.198 | 0.075 | 77.2% |

*The one-update delta host replay has a large upload outlier. Its three total
means were 0.393 / 0.398 / 1.105 ms; upload means were 0.199 / 0.204 / 0.909 ms.
The plain replay was 0.397 ± 0.005 ms and the event replay 0.398 ± 0.001 ms.
The inflated 69.2% share is not a stable estimate. No outliers were removed.
The small-shape delta event replay also had a large upload outlier:
0.586 ± 0.400 ms total versus 0.339 ± 0.002 ms host. Its change cannot be
attributed entirely to event overhead. Both the full per-round data and
repetition means are retained.

At 65,536 carts, delta's event update/gather intervals were **63.492 / 808.435 /
3,201.690 µs** for 1/16/64 updates/cart. Full scan itself remained about
**2.50 ms** across those update counts; scan-path update intervals grew from
23.364 to 427.978 to 1,706.129 µs. Scanning unchanged lines is substantial work,
which explains why attributing every path's time to transfers would be wrong.

Plain CPU4/GPU ratios in this diagnostic were **1.75 / 5.75 / 3.38 / 3.54×** in
the table's shape order. At 64 replacements/cart, delta was faster than scan
in this replay; the earlier sweep selected scan. Shared-host variation and
mode instrumentation mean these observations do not revise the earlier sweep
or establish a universal winner.

The [compact-input and pinned-buffer follow-up](../transport/README.md) now
evaluates this command input path: reduce the
32-byte replacement representation and redundant cart/query IDs, then compare
page-locked staging and reusable host buffers with the same CPU workload and
complete output contract. Kernel time remains significant. Result download
alone offers little headroom in the high-update cases; these measurements do
not demonstrate that eliminating upload would deliver 10× overall.

## Measurement

Four conditions: 4,096 carts × 512 lines with 16 replacements/cart (the earlier
1.79× result), and 65,536 carts × 2,048 lines with 1/16/64 replacements/cart.
Every retained cart is queried after the current batch's changes. Each mode
starts from the same initial state and replays the same 58 changing steps:
eight warmups and 50 timed rounds. Three repetitions rotate/reverse mode order.

Seven variant/mode pairs are measured:

- Four-thread grouped CPU delta, original wall timing.
- GPU scan and GPU delta, original wall timing (`plain`).
- Both GPU paths with host timestamps between the existing calls (`host`).
- Both paths with those timestamps and CUDA events around kernels (`events`).

Host intervals are disjoint and sum to `total_us`: command upload, function
lookup/kernel enqueue, final stream synchronization, output allocation,
complete output download and error-sentinel validation. There is no added
synchronization between update and scan kernels. Host timings include driver
calls and pageable-buffer staging; they do **not** isolate PCIe DMA duration.
The synchronization interval includes remaining GPU execution and waiting
costs, not just overhead. Upload includes query IDs and all changed values;
query construction is outside timing, as in the original benchmark.

Device events are allocated outside timing and recorded in the same stream.
The scan path reports update and full-scan intervals. Delta updates cached
subtotals and gathers totals in one kernel, so only a fused interval is
reported. Event intervals can include gaps while the host enqueues work;
they are not pure arithmetic time. They overlap host enqueue/sync and come
from a separate instrumented replay, so must **not** be added to host phases
or subtracted from a different replay as an exact overhead decomposition.
Event-readout/wrapper time after the measured `total_us` is separately retained
as `timer_tail_us`. The plain replay provides the comparison without events.
Mode differences include instrumentation and uncontrolled host variation.

Every warmup and timed output vector must exactly match the independent
full-rescan trace oracle. All seven original implementations also pass the
808 upstream Django Decimal cases before the measurements. Publication rejects
missing/duplicate rounds, invalid/nonfinite times, wrong counts/bytes,
nonadditive host phases and checksum differences across modes/repetitions.
Checksums are read as integers. Initial placement, trace/oracle generation,
CUDA context/module loading and all correctness comparisons are outside timing.

Summary means and sample standard deviations use three repetition means.
Raw rounds retain warmups, every phase, output checksum and byte counts. CPU
cores 64–67 and RTX 3090 device 0 match the previous study; clocks, NUMA, cache
state and other host activity are uncontrolled. There are 4,872 checked rounds
and 244,457,472 exact totals, plus the upstream gate. These diagnostics do not
replace the earlier 18-shape comparison.

## Reproduce

Use the [same toolchain and resident PTX](../../README.md#reproduce):

```sh
bash performance/django-cart/resident/scale/profile/build.sh
python3 performance/django-cart/resident/scale/profile/run.py --smoke --out /var/tmp/cart-resident-phase-smoke
python3 performance/django-cart/resident/scale/profile/run.py
python3 -m unittest discover -s performance/django-cart/resident/scale/profile -p 'test_*.py'
python3 performance/site.py
```

The smoke uses 64 carts × 32 lines with 1/16 replacements/cart and is not
published as the full measurement grid. `environment.json` records commands,
hardware, affinity and source/artifact/oracle hashes. No network service or
database is needed for this measurement.
