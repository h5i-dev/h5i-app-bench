# CUDA placement diagnostic

This is a calculation diagnostic, separate from HTTP rankings. It uses the same two kernels and pricing code as the line-count HTTP run, with already-packed snapshots. Each measured method recomputes totals; CPU/GPU output vectors are checked exactly. Three repetitions average 100 iterations after eight warmup passes; CPU has one or four persistent workers on four logical CPUs. CUDA context initialization and input generation are excluded.

- **Fresh** uses the actual HTTP GPU helper: host transpose for scalar, device allocation, input/output initialization copies, launch, synchronization, full download, validation and deallocation.
- **Reuse + upload** keeps device buffers but uploads fresh input each call. Scalar still transposes each call. Cooperative input needs no transpose.
- **Resident** uses the actual helper with unchanged input already uploaded. Includes launch, synchronization, result allocation, full download and validation. A CPU could cache unchanged totals too; this is not an application speedup.
- **Device event** records CUDA events around one kernel launch on resident input, synchronizing each iteration. Excludes transfer, allocation and download; event/host submission gaps can affect short intervals. It is not a profiler measurement of active kernel cycles.

## Mean microseconds per complete batch

CPU means use six repetition means (three alongside each GPU layout); GPU columns each use three. All CPU implementations recalculate the same total, including input validation and output allocation.

| Lines | Carts/batch | CPU 1T µs | CPU 4T µs | Scalar fresh µs | Cooperative fresh µs | Cooperative reuse + upload µs | Cooperative resident µs | Cooperative device event µs |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 32 | 8 | 0.320 | 11.832 | 36.999 | 28.432 | 18.064 | 14.799 | 5.318 |
| 32 | 128 | 5.125 | 20.111 | 50.429 | 32.406 | 31.908 | 15.177 | 4.955 |
| 32 | 256 | 10.190 | 23.635 | 63.455 | 39.396 | 35.288 | 15.345 | 5.075 |
| 128 | 8 | 1.162 | 14.595 | 62.786 | 30.263 | 19.375 | 15.373 | 5.969 |
| 128 | 128 | 18.498 | 27.283 | 112.277 | 50.747 | 42.511 | 14.822 | 5.375 |
| 128 | 256 | 37.456 | 37.620 | 171.336 | 75.654 | 72.748 | 15.032 | 5.442 |
| 512 | 8 | 4.045 | 16.337 | 158.082 | 36.543 | 33.968 | 17.360 | 7.832 |
| 512 | 128 | 66.040 | 49.494 | 553.942 | 300.781 | 123.378 | 17.429 | 7.507 |
| 512 | 256 | 132.982 | 89.922 | 753.318 | 364.083 | 181.015 | 18.311 | 7.653 |
| 2048 | 8 | 15.730 | 22.774 | 525.495 | 62.372 | 55.959 | 25.611 | 16.519 |
| 2048 | 128 | 253.802 | 209.233 | 1588.494 | 487.079 | 288.440 | 28.731 | 16.903 |
| 2048 | 256 | 510.178 | 273.015 | 3948.299 | 810.575 | 490.849 | 39.535 | 27.956 |

These batches cover low-load batches (~8 carts), the larger observed batches (~128), and the configured 256-request maximum. They are synthetic full carts, not a replay of the precise HTTP batch membership. Frozen, repeatedly accessed host input has different cache conditions from decoded SQL rows. Layout and method order are fixed; clocks, NUMA and shared-host activity are uncontrolled. Buffer reuse is measured as a diagnostic and has not been integrated into the HTTP implementation. The resident case does not measure update propagation or residency maintenance.

[HTTP results](summary.md) · [Method](../../README.md)
