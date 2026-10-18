# Benchmark summary

Means of the recorded repetitions. Requests/s is k6 `http_reqs.rate`.
Latencies are milliseconds (`p(50)`, `p(90)`, `p(99)`). Errors are the
mean count of failed HTTP requests. RSS is the peak sum of VmRSS across
the server process tree, in MiB. CPU percent is 100 for one core.

## search

| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rust-h5i-optimized | 1 | 4.7 | 211.29 | 213.49 | 214.99 | 0.0 | 7.1 | 6 |
| rust-h5i-optimized | 16 | 19.5 | 819.94 | 869.50 | 913.51 | 0.0 | 10.2 | 9 |
| rust-h5i-cpu-scan | 1 | 34.7 | 28.20 | 29.99 | 34.54 | 0.0 | 106.4 | 196 |
| rust-h5i-cpu-scan | 16 | 96.3 | 164.72 | 174.07 | 201.47 | 0.0 | 577.4 | 358 |
| rust-h5i-gpu | 1 | 65.3 | 15.15 | 15.56 | 15.89 | 0.0 | 191.1 | 21 |
| rust-h5i-gpu | 16 | 669.0 | 22.64 | 34.14 | 46.30 | 0.0 | 645.7 | 112 |
| upstream | 1 | 5.0 | 200.45 | 210.87 | 221.08 | 0.0 | 239.5 | 36 |
| upstream | 16 | 13.5 | 1176.61 | 1236.20 | 1273.92 | 0.0 | 245.3 | 64 |
## search_complex

| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rust-h5i-optimized | 1 | 2.3 | 442.76 | 445.01 | 446.96 | 0.0 | 7.0 | 3 |
| rust-h5i-optimized | 16 | 5.0 | 2367.53 | 4546.82 | 4618.01 | 0.0 | 9.6 | 7 |
| rust-h5i-cpu-scan | 1 | 10.7 | 93.27 | 97.85 | 105.79 | 0.0 | 104.5 | 336 |
| rust-h5i-cpu-scan | 16 | 15.3 | 1038.38 | 1064.18 | 1130.57 | 0.0 | 582.7 | 398 |
| rust-h5i-gpu | 1 | 48.3 | 20.31 | 20.79 | 21.18 | 0.0 | 180.6 | 43 |
| rust-h5i-gpu | 16 | 190.9 | 83.39 | 87.01 | 90.00 | 0.0 | 651.0 | 134 |
| upstream | 1 | 1.9 | 535.40 | 547.03 | 566.85 | 0.0 | 237.9 | 21 |
| upstream | 16 | 4.1 | 3855.29 | 3915.16 | 3942.89 | 0.0 | 243.7 | 46 |
## mixed

| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rust-h5i-optimized | 1 | 15.9 | 28.83 | 247.43 | 253.76 | 0.0 | 7.6 | 6 |
| rust-h5i-optimized | 16 | 84.3 | 49.66 | 811.70 | 890.06 | 0.0 | 10.6 | 22 |
| rust-h5i-cpu-scan | 1 | 8.8 | 30.74 | 651.59 | 682.12 | 0.0 | 247.8 | 101 |
| rust-h5i-cpu-scan | 16 | 32.2 | 53.57 | 2371.84 | 2720.28 | 0.0 | 791.8 | 347 |
| rust-h5i-gpu | 1 | 7.4 | 30.63 | 798.57 | 827.12 | 0.0 | 343.9 | 99 |
| rust-h5i-gpu | 16 | 35.7 | 37.36 | 2308.32 | 2833.57 | 0.0 | 839.8 | 357 |
| upstream | 1 | 9.9 | 110.09 | 197.48 | 208.44 | 0.0 | 240.1 | 47 |
| upstream | 16 | 34.0 | 421.36 | 783.36 | 1008.39 | 0.0 | 247.8 | 164 |

