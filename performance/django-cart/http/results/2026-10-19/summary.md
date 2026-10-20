# django-cart HTTP batching evaluation

At 65,536 carts and 256 clients, batched GPU throughput is **0.88× the matched Rust CPU batch**, **0.57× the fastest native SQL baseline (go-sql)**, and **14.78× GPU without batching**. Its observed batch averages 96.62 requests; mean queue wait is 6.611 ms and p99 HTTP latency is 46.358 ms.

Increasing the database from 4,096 to 65,536 carts at 256 clients changes GPU batch throughput from 11547 to 11559 req/s (1.00×). Database size and GPU batch size are distinct; only collected requests are uploaded.

192 points; 3 repetitions × 5 s after 1 s warmup. 32 lines/cart. 7,473,782 measured responses checked for exact cents; zero errors.

HTTP → queue → fresh PostgreSQL rows → CPU/CUDA → JSON. No GPU input residency between batches. Native SQL baselines perform the upstream-style SUM in PostgreSQL. These are read-only adapters, not a full Django deployment.

| Carts | Clients | Implementation | req/s ± stdev | p99 ms | Mean batch | Queue ms | SQL/run | GPU launches/run |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 4096 | 1 | go-sql | 1131 ± 8 | 0.843 | 1.00 | 0.000 | 5654 | 0 |
| 4096 | 1 | javascript-sql | 990 ± 9 | 1.061 | 1.00 | 0.000 | 4952 | 0 |
| 4096 | 1 | rust-sql | 929 ± 13 | 1.165 | 1.00 | 0.000 | 4644 | 0 |
| 4096 | 1 | rust-gpu-single | 598 ± 13 | 1.650 | 1.00 | 0.020 | 2990 | 2990 |
| 4096 | 1 | rust-cpu-batch | 432 ± 7 | 2.345 | 1.00 | 1.063 | 2163 | 0 |
| 4096 | 1 | go-batch | 427 ± 3 | 2.356 | 1.00 | 1.079 | 2133 | 0 |
| 4096 | 1 | javascript-batch | 379 ± 6 | 3.023 | 1.00 | 1.075 | 1894 | 0 |
| 4096 | 1 | rust-gpu-batch | 361 ± 4 | 2.845 | 1.00 | 1.064 | 1805 | 1805 |
| 4096 | 16 | go-sql | 22046 ± 28 | 1.631 | 1.00 | 0.000 | 110292 | 0 |
| 4096 | 16 | rust-sql | 12175 ± 77 | 2.035 | 1.00 | 0.000 | 60889 | 0 |
| 4096 | 16 | javascript-sql | 10315 ± 120 | 2.992 | 1.00 | 0.000 | 51588 | 0 |
| 4096 | 16 | rust-cpu-batch | 4805 ± 21 | 4.462 | 8.10 | 1.068 | 2969 | 0 |
| 4096 | 16 | go-batch | 4427 ± 199 | 5.102 | 10.05 | 1.146 | 2253 | 0 |
| 4096 | 16 | rust-gpu-batch | 4172 ± 291 | 5.007 | 7.95 | 1.326 | 2625 | 2625 |
| 4096 | 16 | javascript-batch | 3025 ± 124 | 13.184 | 8.00 | 2.141 | 1891 | 0 |
| 4096 | 16 | rust-gpu-single | 808 ± 13 | 21.566 | 1.00 | 18.138 | 4055 | 4055 |
| 4096 | 64 | go-sql | 24829 ± 100 | 9.907 | 1.00 | 0.000 | 124196 | 0 |
| 4096 | 64 | go-batch | 13203 ± 68 | 10.637 | 28.31 | 1.380 | 2334 | 0 |
| 4096 | 64 | javascript-sql | 12663 ± 94 | 11.091 | 1.00 | 0.000 | 63367 | 0 |
| 4096 | 64 | rust-sql | 12370 ± 94 | 10.679 | 1.00 | 0.000 | 61913 | 0 |
| 4096 | 64 | rust-cpu-batch | 10586 ± 161 | 12.080 | 28.64 | 1.932 | 1850 | 0 |
| 4096 | 64 | rust-gpu-batch | 7236 ± 111 | 14.225 | 30.74 | 3.152 | 1179 | 1179 |
| 4096 | 64 | javascript-batch | 6496 ± 41 | 21.950 | 30.97 | 4.019 | 1050 | 0 |
| 4096 | 64 | rust-gpu-single | 813 ± 28 | 84.435 | 1.00 | 76.423 | 4127 | 4127 |
| 4096 | 256 | go-sql | 24463 ± 59 | 35.043 | 1.00 | 0.000 | 122503 | 0 |
| 4096 | 256 | go-batch | 17551 ± 309 | 40.469 | 63.26 | 3.259 | 1390 | 0 |
| 4096 | 256 | javascript-sql | 13536 ± 145 | 46.478 | 1.00 | 0.000 | 67871 | 0 |
| 4096 | 256 | rust-cpu-batch | 13119 ± 194 | 44.331 | 70.33 | 5.313 | 936 | 0 |
| 4096 | 256 | rust-sql | 12427 ± 51 | 40.904 | 1.00 | 0.000 | 62388 | 0 |
| 4096 | 256 | rust-gpu-batch | 11547 ± 146 | 48.408 | 88.83 | 6.344 | 654 | 654 |
| 4096 | 256 | javascript-batch | 9699 ± 220 | 55.230 | 90.72 | 8.964 | 537 | 0 |
| 4096 | 256 | rust-gpu-single | 796 ± 14 | 334.496 | 1.00 | 307.982 | 4234 | 4234 |
| 65536 | 1 | go-sql | 1070 ± 12 | 0.862 | 1.00 | 0.000 | 5349 | 0 |
| 65536 | 1 | javascript-sql | 960 ± 27 | 1.064 | 1.00 | 0.000 | 4801 | 0 |
| 65536 | 1 | rust-sql | 913 ± 60 | 1.165 | 1.00 | 0.000 | 4566 | 0 |
| 65536 | 1 | rust-gpu-single | 584 ± 4 | 1.684 | 1.00 | 0.020 | 2920 | 2920 |
| 65536 | 1 | rust-cpu-batch | 424 ± 2 | 2.315 | 1.00 | 1.063 | 2120 | 0 |
| 65536 | 1 | go-batch | 415 ± 8 | 2.394 | 1.00 | 1.078 | 2076 | 0 |
| 65536 | 1 | javascript-batch | 372 ± 3 | 3.193 | 1.00 | 1.074 | 1863 | 0 |
| 65536 | 1 | rust-gpu-batch | 354 ± 5 | 2.919 | 1.00 | 1.064 | 1770 | 1770 |
| 65536 | 16 | go-sql | 17995 ± 158 | 2.515 | 1.00 | 0.000 | 90031 | 0 |
| 65536 | 16 | rust-sql | 11922 ± 130 | 2.245 | 1.00 | 0.000 | 59624 | 0 |
| 65536 | 16 | javascript-sql | 10535 ± 21 | 3.059 | 1.00 | 0.000 | 52685 | 0 |
| 65536 | 16 | rust-cpu-batch | 4817 ± 267 | 4.719 | 8.68 | 0.962 | 2808 | 0 |
| 65536 | 16 | go-batch | 4428 ± 113 | 5.298 | 8.79 | 1.114 | 2542 | 0 |
| 65536 | 16 | rust-gpu-batch | 3958 ± 269 | 5.512 | 7.93 | 1.375 | 2498 | 2498 |
| 65536 | 16 | javascript-batch | 2841 ± 32 | 13.040 | 7.99 | 2.290 | 1779 | 0 |
| 65536 | 16 | rust-gpu-single | 807 ± 14 | 22.315 | 1.00 | 18.155 | 4049 | 4049 |
| 65536 | 64 | go-sql | 20170 ± 414 | 14.073 | 1.00 | 0.000 | 100903 | 0 |
| 65536 | 64 | go-batch | 13125 ± 146 | 10.390 | 27.98 | 1.322 | 2347 | 0 |
| 65536 | 64 | javascript-sql | 12310 ± 163 | 11.986 | 1.00 | 0.000 | 61608 | 0 |
| 65536 | 64 | rust-sql | 12242 ± 100 | 11.572 | 1.00 | 0.000 | 61269 | 0 |
| 65536 | 64 | rust-cpu-batch | 9572 ± 110 | 12.237 | 29.58 | 2.148 | 1620 | 0 |
| 65536 | 64 | rust-gpu-batch | 6719 ± 193 | 13.935 | 31.17 | 3.424 | 1079 | 1079 |
| 65536 | 64 | javascript-batch | 5967 ± 18 | 23.452 | 31.32 | 4.384 | 954 | 0 |
| 65536 | 64 | rust-gpu-single | 770 ± 10 | 87.187 | 1.00 | 80.567 | 3915 | 3915 |
| 65536 | 256 | go-sql | 20282 ± 633 | 34.274 | 1.00 | 0.000 | 101745 | 0 |
| 65536 | 256 | go-batch | 14842 ± 259 | 39.793 | 54.47 | 3.529 | 1370 | 0 |
| 65536 | 256 | javascript-sql | 13743 ± 123 | 41.915 | 1.00 | 0.000 | 68900 | 0 |
| 65536 | 256 | rust-cpu-batch | 13085 ± 186 | 43.354 | 81.59 | 5.269 | 806 | 0 |
| 65536 | 256 | rust-sql | 12361 ± 199 | 40.494 | 1.00 | 0.000 | 62039 | 0 |
| 65536 | 256 | rust-gpu-batch | 11559 ± 803 | 46.358 | 96.62 | 6.611 | 600 | 600 |
| 65536 | 256 | javascript-batch | 8967 ± 134 | 54.643 | 100.19 | 10.069 | 450 | 0 |
| 65536 | 256 | rust-gpu-single | 782 ± 10 | 337.964 | 1.00 | 312.874 | 4171 | 4171 |

Latency percentiles and counters are means across repetitions. Mean batch is requests / SQL calls per repetition; includes duplicate-ID coalescing. Counts reflect the entire measured k6 run, including completion after the duration. RPS uses k6 elapsed time. CPU peak and RSS cover only the server process; PostgreSQL has a separate four-core allocation. See [method and limitations](../../README.md), [raw points](points.csv), [correctness](conformance.json) and [environment](environment.json).
