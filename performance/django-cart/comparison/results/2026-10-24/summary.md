# Benchmark summary

Fresh seed, 10 s warmup, 30 s measurement; means of three repetitions. One HTTP request returns one cart total from fresh PostgreSQL data. No request batching.

Requests/s is k6 http_reqs.rate. Latencies are milliseconds. RSS is the peak sum across the server process tree in MiB. CPU percent is 100 for one core.

The h5i engine executes complete per-cart tenants through its default transaction path. Cart pricing has differential checks, no application-specific Lean proof. CUDA uses one SQL/CUDA worker and fresh upload/download per request.

Not measured in this run: rust-h5i-gpu.

## total_4096

| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rust-h5i | 1 | 423.7 | 2.22 | 2.54 | 3.24 | 0.0 | 5.7 | 39.6 |
| rust-h5i | 16 | 5632.9 | 2.66 | 3.11 | 4.03 | 0.0 | 7.7 | 198.7 |
| rust-h5i | 64 | 8162.1 | 7.57 | 8.97 | 11.99 | 0.0 | 9.9 | 246.7 |
| rust-h5i | 256 | 8082.9 | 31.14 | 34.97 | 43.73 | 0.0 | 16.2 | 247.6 |
| rust-h5i-optimized | 1 | 1084.1 | 0.76 | 0.91 | 1.14 | 0.0 | 5.7 | 39.7 |
| rust-h5i-optimized | 16 | 15647.8 | 0.88 | 1.19 | 1.87 | 0.0 | 7.5 | 210.9 |
| rust-h5i-optimized | 64 | 18477.0 | 3.09 | 4.47 | 9.31 | 0.0 | 9.7 | 237.4 |
| rust-h5i-optimized | 256 | 18443.5 | 12.80 | 17.59 | 36.41 | 0.0 | 16.4 | 234.3 |
| fastapi | 1 | 23.1 | 42.87 | 43.77 | 46.21 | 0.0 | 217.7 | 22.9 |
| fastapi | 16 | 372.6 | 42.80 | 43.49 | 45.03 | 0.0 | 220.8 | 138.1 |
| fastapi | 64 | 1481.0 | 42.82 | 44.53 | 48.51 | 0.0 | 228.6 | 154.0 |
| fastapi | 256 | 5560.7 | 44.25 | 50.41 | 68.55 | 0.0 | 240.8 | 309.9 |
| go | 1 | 1313.5 | 0.60 | 0.70 | 0.91 | 0.0 | 18.1 | 59.3 |
| go | 16 | 22311.5 | 0.54 | 0.92 | 1.93 | 0.0 | 19.8 | 246.1 |
| go | 64 | 28654.6 | 1.60 | 4.09 | 9.46 | 0.0 | 24.4 | 295.6 |
| go | 256 | 27135.6 | 4.73 | 13.78 | 27.93 | 0.0 | 31.8 | 291.8 |
| fastify | 1 | 1200.1 | 0.66 | 0.78 | 1.04 | 0.0 | 516.6 | 173.9 |
| fastify | 16 | 19567.2 | 0.64 | 0.98 | 2.20 | 0.0 | 910.2 | 334.8 |
| fastify | 64 | 26329.2 | 1.77 | 4.39 | 10.00 | 0.0 | 946.1 | 392.2 |
| fastify | 256 | 25945.0 | 6.40 | 15.38 | 31.37 | 0.0 | 958.8 | 421.0 |

## total_65536

| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rust-h5i | 1 | 393.6 | 2.32 | 2.63 | 2.95 | 0.0 | 5.5 | 39.5 |
| rust-h5i | 16 | 5528.6 | 2.71 | 3.15 | 4.00 | 0.0 | 7.5 | 198.7 |
| rust-h5i | 64 | 7847.0 | 7.89 | 9.21 | 11.41 | 0.0 | 9.9 | 240.9 |
| rust-h5i | 256 | 7908.3 | 32.10 | 34.49 | 39.92 | 0.0 | 16.1 | 241.0 |
| rust-h5i-optimized | 1 | 967.0 | 0.80 | 0.95 | 1.16 | 0.0 | 5.6 | 39.6 |
| rust-h5i-optimized | 16 | 14932.2 | 0.93 | 1.23 | 1.82 | 0.0 | 7.3 | 208.1 |
| rust-h5i-optimized | 64 | 17137.3 | 3.20 | 5.27 | 11.27 | 0.0 | 9.6 | 234.8 |
| rust-h5i-optimized | 256 | 17018.2 | 13.47 | 18.90 | 32.60 | 0.0 | 15.9 | 234.4 |
| fastapi | 1 | 23.1 | 42.87 | 43.78 | 45.89 | 0.0 | 217.3 | 19.4 |
| fastapi | 16 | 372.0 | 42.80 | 43.26 | 44.81 | 0.0 | 221.0 | 139.1 |
| fastapi | 64 | 1484.5 | 42.79 | 43.93 | 46.87 | 0.0 | 228.1 | 171.0 |
| fastapi | 256 | 5730.0 | 43.84 | 46.65 | 62.47 | 0.0 | 244.3 | 316.3 |
| go | 1 | 1123.3 | 0.67 | 0.74 | 0.97 | 0.0 | 18.2 | 55.8 |
| go | 16 | 20899.3 | 0.55 | 1.07 | 2.17 | 0.0 | 19.9 | 258.1 |
| go | 64 | 24064.2 | 1.76 | 5.34 | 11.96 | 0.0 | 24.6 | 298.5 |
| go | 256 | 23394.5 | 5.79 | 17.69 | 30.37 | 0.0 | 30.8 | 286.7 |
| fastify | 1 | 1056.1 | 0.73 | 0.83 | 1.11 | 0.0 | 489.3 | 161.7 |
| fastify | 16 | 18934.8 | 0.63 | 1.10 | 2.38 | 0.0 | 884.7 | 327.4 |
| fastify | 64 | 22601.6 | 1.98 | 5.49 | 12.06 | 0.0 | 947.8 | 398.3 |
| fastify | 256 | 22752.6 | 6.62 | 18.81 | 31.39 | 0.0 | 957.2 | 409.1 |

See [method and reproduction](../../README.md). Raw samples and conformance logs stay local.
