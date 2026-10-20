# django-cart: increasing work per cart

Fixed **4,096 carts**; 32, 128, 512, 2048 lines/cart. 216 points, 3 repetitions × 5 s after 1 s warmup. **5,951,875 responses checked; zero HTTP or exact-value failures.**

Each individual HTTP request returns one cart total. Batches coalesce requests into one SQL read; CUDA uploads fresh input and downloads every total. CPU and GPU use identical prices, quantities and discounts. Native SQL baselines keep SUM in PostgreSQL. No Django deployment speedup is measured.

| Lines/cart | Line rows | Clients | Best SQL req/s | Best CPU batch req/s | GPU scalar req/s | GPU cooperative req/s | Best GPU / CPU | Best GPU / SQL |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 32 | 131,072 | 16 | 24055 (go-sql) | 4871 (rust-cpu-batch) | 3939 | 3945 | 0.81× | 0.16× |
| 32 | 131,072 | 256 | 26276 (go-sql) | 18094 (go-batch) | 11365 | 11539 | 0.64× | 0.44× |
| 128 | 524,288 | 16 | 20720 (go-sql) | 3181 (go-batch) | 1820 | 1875 | 0.59× | 0.09× |
| 128 | 524,288 | 256 | 21534 (go-sql) | 5599 (go-batch) | 4377 | 4448 | 0.79× | 0.21× |
| 512 | 2,097,152 | 16 | 6689 (go-sql) | 1089 (go-batch) | 875 | 886 | 0.81× | 0.13× |
| 512 | 2,097,152 | 256 | 6781 (go-sql) | 1392 (go-batch) | 1081 | 1096 | 0.79× | 0.16× |
| 2048 | 8,388,608 | 16 | 1465 (go-sql) | 270 (go-batch) | 223 | 228 | 0.85× | 0.16× |
| 2048 | 8,388,608 | 256 | 1459 (go-sql) | 306 (go-batch) | 255 | 250 | 0.83× | 0.17× |

Best-of ratios above select implementations within each measured shape; they are descriptive, not a preselected production policy. See all repetitions and variability below.

## Where the time goes

The following uses the serial Rust CPU and cooperative GPU, at the highest measured concurrency. Each phase is amortized over completed HTTP requests within a repetition, then averaged across repetitions. The CPU compute share covers only these three measured phases; queueing, HTTP and reply handling are excluded.

| Lines | CPU fetch µs/request | CPU pack µs/request | CPU compute µs/request | CPU compute share | GPU fetch µs/request | GPU pack µs/request | GPU complete compute µs/request |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 32 | 58.138 | 13.455 | 0.100 | 0.14% | 66.869 | 13.871 | 4.571 |
| 128 | 169.953 | 49.333 | 0.310 | 0.14% | 170.412 | 49.025 | 3.678 |
| 512 | 704.109 | 199.876 | 1.000 | 0.11% | 701.906 | 198.912 | 5.677 |
| 2048 | 3250.447 | 519.208 | 11.513 | 0.30% | 3447.691 | 528.745 | 21.065 |

GPU compute includes allocation and transfers, not just arithmetic. Increasing line count also increases database work, decoded rows and transferred bytes. These measurements distinguish a larger input from a computation bottleneck.

## All implementations

| Lines | Clients | Implementation | req/s ± stdev | p99 ms | Requests/batch | Queue ms | Fetch ms/batch | Pack ms/batch | Compute ms/batch |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 32 | 16 | go-sql | 24055 ± 251 | 1.432 | 1.00 | 0.000 | — | — | — |
| 32 | 16 | rust-sql | 12443 ± 171 | 1.970 | 1.00 | 0.000 | — | — | — |
| 32 | 16 | javascript-sql | 10613 ± 41 | 2.930 | 1.00 | 0.000 | — | — | — |
| 32 | 16 | rust-cpu-batch | 4871 ± 90 | 4.550 | 8.04 | 1.096 | 1.4840 | 0.1135 | 0.0013 |
| 32 | 16 | rust-cpu-parallel | 4861 ± 47 | 4.536 | 8.18 | 1.086 | 1.4422 | 0.1158 | 0.0435 |
| 32 | 16 | go-batch | 4222 ± 95 | 4.999 | 11.95 | 1.217 | — | — | — |
| 32 | 16 | rust-gpu-cooperative | 3945 ± 289 | 5.297 | 7.96 | 1.474 | 1.4569 | 0.1157 | 0.4307 |
| 32 | 16 | rust-gpu-batch | 3939 ± 290 | 5.226 | 7.97 | 1.491 | 1.4571 | 0.1142 | 0.4370 |
| 32 | 16 | javascript-batch | 3056 ± 83 | 12.611 | 8.03 | 2.111 | — | — | — |
| 32 | 256 | go-sql | 26276 ± 227 | 32.758 | 1.00 | 0.000 | — | — | — |
| 32 | 256 | go-batch | 18094 ± 233 | 38.121 | 70.65 | 3.470 | — | — | — |
| 32 | 256 | rust-cpu-parallel | 14230 ± 541 | 41.416 | 78.54 | 5.009 | 4.3583 | 0.9804 | 0.0554 |
| 32 | 256 | javascript-sql | 13986 ± 180 | 41.712 | 1.00 | 0.000 | — | — | — |
| 32 | 256 | rust-cpu-batch | 13635 ± 282 | 42.782 | 76.61 | 5.323 | 4.4534 | 1.0304 | 0.0076 |
| 32 | 256 | rust-sql | 12792 ± 388 | 38.102 | 1.00 | 0.000 | — | — | — |
| 32 | 256 | rust-gpu-cooperative | 11539 ± 402 | 44.861 | 98.07 | 6.890 | 6.5631 | 1.3602 | 0.4478 |
| 32 | 256 | rust-gpu-batch | 11365 ± 413 | 46.006 | 97.09 | 6.927 | 6.4832 | 1.3326 | 0.6073 |
| 32 | 256 | javascript-batch | 9740 ± 192 | 53.318 | 101.91 | 9.464 | — | — | — |
| 128 | 16 | go-sql | 20720 ± 247 | 1.538 | 1.00 | 0.000 | — | — | — |
| 128 | 16 | rust-sql | 11237 ± 291 | 2.152 | 1.00 | 0.000 | — | — | — |
| 128 | 16 | javascript-sql | 10496 ± 100 | 3.225 | 1.00 | 0.000 | — | — | — |
| 128 | 16 | go-batch | 3181 ± 99 | 7.681 | 8.54 | 1.671 | — | — | — |
| 128 | 16 | rust-cpu-batch | 2597 ± 117 | 8.101 | 8.03 | 2.514 | 2.6262 | 0.4433 | 0.0031 |
| 128 | 16 | rust-cpu-parallel | 2517 ± 61 | 8.820 | 8.00 | 2.650 | 2.6762 | 0.4392 | 0.0434 |
| 128 | 16 | javascript-batch | 1894 ± 320 | 23.636 | 8.06 | 3.699 | — | — | — |
| 128 | 16 | rust-gpu-cooperative | 1875 ± 125 | 9.909 | 8.03 | 3.670 | 3.3930 | 0.4426 | 0.4333 |
| 128 | 16 | rust-gpu-batch | 1820 ± 19 | 9.855 | 8.03 | 3.568 | 3.4731 | 0.4445 | 0.4722 |
| 128 | 256 | go-sql | 21534 ± 415 | 34.044 | 1.00 | 0.000 | — | — | — |
| 128 | 256 | javascript-sql | 13636 ± 258 | 42.608 | 1.00 | 0.000 | — | — | — |
| 128 | 256 | rust-sql | 11624 ± 210 | 38.095 | 1.00 | 0.000 | — | — | — |
| 128 | 256 | go-batch | 5599 ± 20 | 63.979 | 125.55 | 17.335 | — | — | — |
| 128 | 256 | rust-cpu-batch | 4532 ± 219 | 78.620 | 125.27 | 23.599 | 21.2902 | 6.1886 | 0.0389 |
| 128 | 256 | rust-gpu-cooperative | 4448 ± 173 | 83.571 | 125.36 | 23.306 | 21.3624 | 6.1464 | 0.4611 |
| 128 | 256 | rust-gpu-batch | 4377 ± 65 | 76.315 | 126.70 | 24.348 | 21.3202 | 6.8156 | 0.5900 |
| 128 | 256 | rust-cpu-parallel | 4364 ± 127 | 81.182 | 123.94 | 24.143 | 21.4840 | 6.6609 | 0.0804 |
| 128 | 256 | javascript-batch | 3873 ± 27 | 106.666 | 118.64 | 25.285 | — | — | — |
| 512 | 16 | go-sql | 6689 ± 81 | 3.626 | 1.00 | 0.000 | — | — | — |
| 512 | 16 | javascript-sql | 6366 ± 109 | 4.295 | 1.00 | 0.000 | — | — | — |
| 512 | 16 | rust-sql | 5228 ± 74 | 5.092 | 1.00 | 0.000 | — | — | — |
| 512 | 16 | go-batch | 1089 ± 11 | 18.379 | 8.03 | 6.240 | — | — | — |
| 512 | 16 | rust-cpu-batch | 932 ± 7 | 18.344 | 8.01 | 6.630 | 6.8084 | 1.7534 | 0.0098 |
| 512 | 16 | rust-cpu-parallel | 932 ± 9 | 18.566 | 8.05 | 7.490 | 6.7646 | 1.7431 | 0.0993 |
| 512 | 16 | javascript-batch | 888 ± 15 | 40.661 | 8.12 | 7.805 | — | — | — |
| 512 | 16 | rust-gpu-cooperative | 886 ± 5 | 21.220 | 8.03 | 7.809 | 6.8405 | 1.7424 | 0.4451 |
| 512 | 16 | rust-gpu-batch | 875 ± 10 | 19.714 | 8.02 | 6.638 | 6.8091 | 1.7401 | 0.5875 |
| 512 | 256 | go-sql | 6781 ± 84 | 41.614 | 1.00 | 0.000 | — | — | — |
| 512 | 256 | javascript-sql | 6640 ± 102 | 153.292 | 1.00 | 0.000 | — | — | — |
| 512 | 256 | rust-sql | 5594 ± 110 | 48.465 | 1.00 | 0.000 | — | — | — |
| 512 | 256 | go-batch | 1392 ± 16 | 209.269 | 125.30 | 73.039 | — | — | — |
| 512 | 256 | rust-cpu-batch | 1103 ± 18 | 250.710 | 123.44 | 87.185 | 86.9114 | 24.6706 | 0.1235 |
| 512 | 256 | rust-gpu-cooperative | 1096 ± 2 | 263.053 | 125.58 | 88.242 | 88.1455 | 24.9780 | 0.7129 |
| 512 | 256 | rust-cpu-parallel | 1096 ± 36 | 255.277 | 124.72 | 79.906 | 88.7029 | 24.4297 | 0.1634 |
| 512 | 256 | rust-gpu-batch | 1081 ± 14 | 260.907 | 125.19 | 84.984 | 89.1605 | 24.9043 | 1.2623 |
| 512 | 256 | javascript-batch | 1077 ± 1 | 739.381 | 116.43 | 97.478 | — | — | — |
| 2048 | 16 | go-sql | 1465 ± 2 | 19.764 | 1.00 | 0.000 | — | — | — |
| 2048 | 16 | javascript-sql | 1465 ± 6 | 19.965 | 1.00 | 0.000 | — | — | — |
| 2048 | 16 | rust-sql | 1379 ± 7 | 20.967 | 1.00 | 0.000 | — | — | — |
| 2048 | 16 | go-batch | 270 ± 4 | 67.742 | 8.12 | 25.081 | — | — | — |
| 2048 | 16 | javascript-batch | 231 ± 1 | 99.691 | 8.00 | 30.465 | — | — | — |
| 2048 | 16 | rust-cpu-batch | 230 ± 2 | 73.669 | 8.27 | 20.688 | 28.5821 | 7.1667 | 0.0365 |
| 2048 | 16 | rust-cpu-parallel | 230 ± 1 | 74.033 | 8.13 | 20.193 | 28.0453 | 7.1176 | 0.1083 |
| 2048 | 16 | rust-gpu-cooperative | 228 ± 2 | 74.077 | 8.10 | 27.315 | 27.8749 | 7.0217 | 0.5033 |
| 2048 | 16 | rust-gpu-batch | 223 ± 1 | 77.854 | 8.02 | 19.745 | 27.9680 | 6.9109 | 1.0097 |
| 2048 | 256 | go-sql | 1459 ± 15 | 183.275 | 1.00 | 0.000 | — | — | — |
| 2048 | 256 | javascript-sql | 1427 ± 3 | 396.650 | 1.00 | 0.000 | — | — | — |
| 2048 | 256 | rust-sql | 1382 ± 10 | 194.823 | 1.00 | 0.000 | — | — | — |
| 2048 | 256 | go-batch | 306 ± 28 | 1362.534 | 122.34 | 186.267 | — | — | — |
| 2048 | 256 | rust-cpu-batch | 263 ± 9 | 1404.831 | 122.03 | 144.394 | 396.6001 | 63.3929 | 1.4073 |
| 2048 | 256 | rust-cpu-parallel | 262 ± 2 | 1412.403 | 127.81 | 129.311 | 417.4702 | 66.5095 | 0.2977 |
| 2048 | 256 | rust-gpu-batch | 255 ± 2 | 1461.221 | 115.58 | 274.804 | 383.2990 | 62.4596 | 4.0371 |
| 2048 | 256 | rust-gpu-cooperative | 250 ± 22 | 1630.958 | 125.00 | 226.209 | 431.5952 | 66.1243 | 2.6262 |
| 2048 | 256 | javascript-batch | 241 ± 4 | 1796.315 | 114.89 | 445.051 | — | — | — |

Rust batch phases are means per SQL batch. Fetch includes PostgreSQL execution, network transfer and sqlx decoding; pack includes extracting decoded fields and constructing snapshots. Compute includes CPU calculation, or GPU transpose where needed, allocation, upload, launch, synchronization, full result download and validation. These phases exclude queueing, HTTP and map/reply overhead; they are not kernel-only timings. Other implementations have no phase instrumentation (—). Percentiles and per-batch means are averaged across repetitions.

The scalar GPU launches at most two 128-thread blocks at the configured 256-request maximum. Cooperative launches one 32-thread block per distinct cart. This experiment compares these implementations, not an optimally tuned GPU bound.

Native SQL uses 16 connections; each batched variant has one active SQL worker. Every server, PostgreSQL and k6 receives four CPU cores on the same shared host. Rust parallel uses four Rayon workers within the same server CPU allocation. Warm database conditions, uncontrolled clocks/NUMA and short runs limit generalization.

[GPU placement diagnostic](placement.md) · [Method and reproduction](../../README.md)
