# Resident cart population/update scaling

**378 verified points; 628,604,928 exact totals checked.** Seven implementations, three repeats of 50 measured rounds after eight warmups. All seven pass the 808-case upstream Decimal corpus. Every warmup and timed output is checked against a separate full-rescan oracle outside the timer.

CPU/GPU ratios include the fastest measured implementation on each side, including grouped single/four-thread CPU incremental totals. Above 1 favors GPU. GPU time includes update/ID upload, kernels, synchronization, full download and error checks. Initial placement is separate. Calculation timings, not HTTP throughput.

| Lines | Carts/queries | Updates/cart | Best CPU | CPU µs | Best GPU | GPU µs | CPU/GPU |
| --- | --- | --- | --- | ---: | --- | ---: | ---: |
| 512 | 4096 | 1 | cpu-delta-4 | 114.011 | gpu-delta | 49.324 | 2.31× |
| 512 | 4096 | 16 | cpu-delta-4 | 507.564 | gpu-scan | 283.676 | 1.79× |
| 512 | 4096 | 64 | cpu-delta-4 | 1918.451 | gpu-scan | 809.769 | 2.37× |
| 512 | 16384 | 1 | cpu-delta-4 | 412.745 | gpu-delta | 130.065 | 3.17× |
| 512 | 16384 | 16 | cpu-delta-4 | 2505.540 | gpu-delta | 953.648 | 2.63× |
| 512 | 16384 | 64 | cpu-delta-4 | 7877.087 | gpu-scan | 3160.426 | 2.49× |
| 512 | 65536 | 1 | cpu-delta-4 | 1690.867 | gpu-delta | 625.457 | 2.70× |
| 512 | 65536 | 16 | cpu-delta-4 | 10721.317 | gpu-delta | 3572.798 | 3.00× |
| 512 | 65536 | 64 | cpu-delta-4 | 42432.661 | gpu-scan | 13381.435 | 3.17× |
| 2048 | 4096 | 1 | cpu-delta-4 | 101.995 | gpu-delta | 49.063 | 2.08× |
| 2048 | 4096 | 16 | cpu-delta-4 | 612.613 | gpu-delta | 337.591 | 1.81× |
| 2048 | 4096 | 64 | cpu-delta-4 | 2369.580 | gpu-scan | 945.978 | 2.50× |
| 2048 | 16384 | 1 | cpu-delta-4 | 367.220 | gpu-delta | 129.484 | 2.84× |
| 2048 | 16384 | 16 | cpu-delta-4 | 2632.594 | gpu-delta | 951.762 | 2.77× |
| 2048 | 16384 | 64 | cpu-delta-4 | 10047.521 | gpu-delta | 3644.688 | 2.76× |
| 2048 | 65536 | 1 | cpu-delta-4 | 2290.304 | gpu-delta | 385.272 | 5.94× |
| 2048 | 65536 | 16 | cpu-delta-4 | 12321.350 | gpu-delta | 3500.135 | 3.52× |
| 2048 | 65536 | 64 | cpu-delta-4 | 50854.511 | gpu-scan | 15173.386 | 3.35× |

## Scope and limits

- All population carts are queried in every batch, in a fixed permuted order. Values and patched slots change every round. Cardinalities and discount metadata remain fixed. Valid, normalized replacements are round-robin across carts; patched slots and query IDs are unique within each round. No updates are stale in the next query.
- CPU delta preserves the original event-order implementation. CPU delta grouped applies all patches for a cart together, retaining its subtotal in a local variable; CPU delta 4 uses the same cart-grouped algorithm with four persistent Rayon workers. This avoids comparing the GPU only to a weaker CPU update order. Both retain rows, subtotals and final totals.
- Each variant independently retains the complete population. Large traces and independent oracle state are built outside timing. CPUs 64–67 and RTX 3090 device 0; synchronous batches with no transfer/launch overlap. Variant order rotates/reverses. Shared-host activity, clock, NUMA and cache effects are uncontrolled. Three-repeat sample variability and iteration p50/p99 are in CSV/JSON; averaged percentiles are not pooled. With 50 iterations, the reported p99 is the maximum round.
- Initial allocation/copy/upload/subtotal setup is separately recorded as init_ms; generation, CUDA context/module loading, trace validation and oracle comparisons are excluded. The update/query means do not amortize startup or rebuilds.
- No HTTP, database commit, CDC delivery, durable recovery, concurrent writers, insertion/deletion, retries or cross-process coherence. This tests line-price/quantity replacement under the existing total contract. Go/JavaScript are not measured in this resident sweep. These are measured implementations, not optimal CPU/GPU bounds.

[Method](../../README.md) · [All implementation timings](summary.csv)
