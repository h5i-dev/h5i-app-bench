# Resident cart data with visible updates

**960 verified points; 116,328,960 exact totals checked**, including eight warmups per point. Fixed 4,096 carts; 32/128/512/2,048 lines; 8/128/256/4,096 queries per batch; zero/one/one-per-query/sixteen-per-query line replacements before each query batch. Three repetitions of 100 changing rounds. All five implementations also pass the 808-case upstream Decimal corpus.

These are calculation timings, not HTTP request rates. Data is retained on each backend; each round applies the same replacement events, then returns all requested totals from the updated state. Query IDs rotate across the population. CPU/GPU incremental versions maintain exact subtotals and cached final totals. Both must observe updates in the very next query. No stale results or delayed propagation are allowed within this process.

## Mean microseconds per update-and-query batch

Scan compares the fastest measured one/four-worker CPU full rescan with GPU full rescan. Best CPU/GPU also allows cached incremental totals on both. Ratios above 1 favor GPU. Timings are means of three repetition means; per-repetition variability is in the CSV/JSON.

| Lines | Queries | Updates | CPU scan 1T µs | CPU scan 4T µs | CPU delta µs | GPU scan µs | GPU delta µs | Scan CPU/GPU | Best CPU/GPU |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 32 | 8 | 0 | 0.428 | 12.584 | 0.042 | 17.768 | 16.549 | 0.02× | 0.00× |
| 32 | 8 | 1 | 0.475 | 12.423 | 0.064 | 20.312 | 17.284 | 0.02× | 0.00× |
| 32 | 8 | 8 | 0.446 | 12.468 | 0.124 | 20.299 | 17.410 | 0.02× | 0.01× |
| 32 | 8 | 128 | 0.583 | 12.726 | 0.571 | 20.683 | 23.865 | 0.03× | 0.03× |
| 32 | 128 | 0 | 6.117 | 22.030 | 0.159 | 18.730 | 17.507 | 0.33× | 0.01× |
| 32 | 128 | 1 | 5.785 | 22.050 | 0.161 | 20.879 | 18.178 | 0.28× | 0.01× |
| 32 | 128 | 128 | 5.940 | 22.224 | 1.471 | 21.414 | 19.389 | 0.28× | 0.08× |
| 32 | 128 | 2048 | 10.628 | 27.143 | 11.174 | 32.923 | 40.762 | 0.32× | 0.32× |
| 32 | 256 | 0 | 11.774 | 23.185 | 0.256 | 18.736 | 17.349 | 0.63× | 0.01× |
| 32 | 256 | 1 | 11.061 | 22.937 | 0.289 | 21.227 | 18.337 | 0.52× | 0.02× |
| 32 | 256 | 256 | 11.188 | 27.128 | 2.768 | 21.552 | 19.518 | 0.52× | 0.14× |
| 32 | 256 | 4096 | 23.126 | 40.102 | 21.084 | 39.367 | 47.482 | 0.59× | 0.54× |
| 32 | 4096 | 0 | 189.027 | 131.288 | 3.327 | 33.407 | 29.031 | 3.93× | 0.11× |
| 32 | 4096 | 1 | 179.817 | 111.575 | 3.189 | 33.565 | 26.348 | 3.32× | 0.12× |
| 32 | 4096 | 4096 | 195.965 | 144.903 | 51.470 | 53.301 | 46.459 | 2.72× | 1.11× |
| 32 | 4096 | 65536 | 450.101 | 407.872 | 442.285 | 230.962 | 228.157 | 1.77× | 1.79× |
| 128 | 8 | 0 | 1.921 | 15.118 | 0.069 | 18.297 | 15.599 | 0.10× | 0.00× |
| 128 | 8 | 1 | 1.966 | 15.088 | 0.089 | 20.782 | 15.892 | 0.09× | 0.01× |
| 128 | 8 | 8 | 1.934 | 15.044 | 0.154 | 20.553 | 16.211 | 0.09× | 0.01× |
| 128 | 8 | 128 | 2.428 | 16.207 | 0.977 | 20.271 | 23.438 | 0.12× | 0.05× |
| 128 | 128 | 0 | 23.639 | 29.155 | 0.149 | 18.640 | 16.429 | 1.27× | 0.01× |
| 128 | 128 | 1 | 23.673 | 29.842 | 0.229 | 21.370 | 16.658 | 1.11× | 0.01× |
| 128 | 128 | 128 | 24.076 | 29.052 | 1.875 | 21.747 | 17.741 | 1.11× | 0.11× |
| 128 | 128 | 2048 | 33.434 | 38.160 | 18.069 | 34.239 | 45.741 | 0.98× | 0.53× |
| 128 | 256 | 0 | 43.859 | 37.689 | 0.275 | 19.696 | 16.703 | 1.91× | 0.02× |
| 128 | 256 | 1 | 44.129 | 38.635 | 0.373 | 22.185 | 17.442 | 1.74× | 0.02× |
| 128 | 256 | 256 | 45.377 | 39.844 | 3.849 | 23.054 | 18.655 | 1.73× | 0.21× |
| 128 | 256 | 4096 | 65.601 | 63.797 | 42.881 | 43.765 | 57.565 | 1.46× | 0.98× |
| 128 | 4096 | 0 | 642.080 | 347.631 | 3.622 | 41.942 | 25.621 | 8.29× | 0.14× |
| 128 | 4096 | 1 | 657.919 | 343.404 | 4.364 | 47.050 | 27.913 | 7.30× | 0.16× |
| 128 | 4096 | 4096 | 655.190 | 359.694 | 64.671 | 66.615 | 50.868 | 5.40× | 1.27× |
| 128 | 4096 | 65536 | 956.802 | 620.638 | 651.650 | 243.311 | 328.724 | 2.55× | 2.55× |
| 512 | 8 | 0 | 7.807 | 16.793 | 0.077 | 22.560 | 15.463 | 0.35× | 0.00× |
| 512 | 8 | 1 | 7.996 | 17.148 | 0.188 | 25.055 | 16.206 | 0.32× | 0.01× |
| 512 | 8 | 8 | 8.084 | 17.180 | 0.382 | 24.980 | 16.231 | 0.32× | 0.02× |
| 512 | 8 | 128 | 9.062 | 18.665 | 2.708 | 25.389 | 25.474 | 0.36× | 0.11× |
| 512 | 128 | 0 | 128.462 | 64.967 | 0.151 | 23.164 | 16.580 | 2.80× | 0.01× |
| 512 | 128 | 1 | 128.795 | 65.000 | 0.365 | 25.815 | 16.768 | 2.52× | 0.02× |
| 512 | 128 | 128 | 127.649 | 67.930 | 4.737 | 26.107 | 17.668 | 2.60× | 0.27× |
| 512 | 128 | 2048 | 149.006 | 95.954 | 60.490 | 40.827 | 47.073 | 2.35× | 1.48× |
| 512 | 256 | 0 | 258.694 | 114.691 | 0.334 | 24.166 | 15.916 | 4.75× | 0.02× |
| 512 | 256 | 1 | 256.534 | 129.285 | 0.509 | 26.468 | 17.033 | 4.88× | 0.03× |
| 512 | 256 | 256 | 251.771 | 120.386 | 9.287 | 27.357 | 18.751 | 4.40× | 0.50× |
| 512 | 256 | 4096 | 299.242 | 188.960 | 133.180 | 48.001 | 59.851 | 3.94× | 2.77× |
| 512 | 4096 | 0 | 4169.142 | 1429.498 | 4.369 | 72.029 | 24.724 | 19.85× | 0.18× |
| 512 | 4096 | 1 | 4171.502 | 1419.888 | 3.674 | 75.467 | 26.787 | 18.81× | 0.14× |
| 512 | 4096 | 4096 | 4202.776 | 1468.114 | 169.638 | 97.618 | 50.510 | 15.04× | 3.36× |
| 512 | 4096 | 65536 | 4925.516 | 2322.151 | 1836.039 | 281.604 | 340.140 | 8.25× | 6.52× |
| 2048 | 8 | 0 | 21.482 | 23.787 | 0.104 | 40.785 | 15.018 | 0.53× | 0.01× |
| 2048 | 8 | 1 | 21.849 | 24.981 | 0.251 | 42.965 | 15.965 | 0.51× | 0.02× |
| 2048 | 8 | 8 | 21.633 | 24.968 | 0.474 | 43.266 | 15.884 | 0.50× | 0.03× |
| 2048 | 8 | 128 | 23.311 | 26.427 | 3.351 | 43.756 | 25.396 | 0.53× | 0.13× |
| 2048 | 128 | 0 | 342.684 | 186.024 | 0.151 | 42.156 | 15.436 | 4.41× | 0.01× |
| 2048 | 128 | 1 | 344.943 | 217.139 | 0.399 | 44.695 | 16.578 | 4.86× | 0.02× |
| 2048 | 128 | 128 | 345.803 | 228.773 | 7.085 | 44.706 | 17.843 | 5.12× | 0.40× |
| 2048 | 128 | 2048 | 372.628 | 214.314 | 69.520 | 60.133 | 46.617 | 3.56× | 1.49× |
| 2048 | 256 | 0 | 686.612 | 384.004 | 0.290 | 45.097 | 15.731 | 8.52× | 0.02× |
| 2048 | 256 | 1 | 681.524 | 375.856 | 0.524 | 46.787 | 16.678 | 8.03× | 0.03× |
| 2048 | 256 | 256 | 690.233 | 348.851 | 12.005 | 47.767 | 18.088 | 7.30× | 0.66× |
| 2048 | 256 | 4096 | 738.899 | 392.511 | 140.142 | 69.574 | 59.356 | 5.64× | 2.36× |
| 2048 | 4096 | 0 | 11057.545 | 4103.900 | 4.226 | 197.558 | 24.218 | 20.77× | 0.17× |
| 2048 | 4096 | 1 | 11026.580 | 4106.654 | 3.734 | 200.757 | 25.789 | 20.46× | 0.14× |
| 2048 | 4096 | 4096 | 11267.813 | 4398.116 | 187.159 | 223.418 | 49.036 | 19.69× | 3.82× |
| 2048 | 4096 | 65536 | 12241.499 | 5592.263 | 1989.707 | 404.902 | 337.318 | 13.81× | 5.90× |

## Interpretation and limits

- GPU wall time includes the fresh query-ID/update-command upload to reusable buffers, ordered mutation/query kernels, stream synchronization, complete result download and error validation. It is not kernel-only time. CPU wall time includes event application, query calculation/gather and result allocation. Exact-result comparisons and the independent full-rescan oracle run outside the timer for both.
- CPU scan 4T uses four persistent Rayon workers. GPU scan uses one 32-thread block per queried cart. GPU delta uses one thread per queried cart, applying that cart's patches serially and updating its subtotal once. Both delta paths avoid rescanning lines; CPU delta needs no worker dispatch. These are implementations, not optimal hardware bounds.
- Initial population generation, CUDA context/module setup, trace generation and event validation are excluded. `init_ms` separately measures owned CPU placement or GPU allocation/upload; delta initialization includes a CPU subtotal pass for either backend. Every variant keeps the full 4,096-cart population, even for a small query batch. Read-only final totals may be cached on CPU and GPU.
- Replacement events have validated IDs, slots, prices and quantities. Within a batch each query cart is unique and each patched slot unique; patches are ordered round-robin across queried carts. Prices/quantities change each round, including maximum-bound values. Cart line counts and discount metadata are fixed. Inserts, deletes, retries, concurrent writers and conflict handling are not covered.
- This experiment starts from a normalized in-process event stream. It does not measure database commit, CDC delivery, durable recovery, cross-process cache coherence or HTTP queueing. It establishes immediate visibility only within this single process. Adding those costs may change the result.
- CPU and GPU each use CPUs 64–67, GPU device 0 (RTX 3090). Variant order rotates and reverses across repetitions; workload order is fixed. Shared host activity, clocks, NUMA placement and cache effects are uncontrolled. Data is repeatedly accessed, but query IDs and event values change. Short rounds are sensitive to timer/launch overhead.

[Method and reproduction](../../README.md) · [Summary CSV](summary.csv)
