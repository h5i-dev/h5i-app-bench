# Benchmark summary

Means of the recorded repetitions. Requests/s is k6 `http_reqs.rate`.
Latencies are milliseconds (`p(50)`, `p(90)`, `p(99)`). Errors are the
mean count of failed HTTP requests. RSS is the peak sum of VmRSS across
the server process tree, in MiB. CPU percent is 100 for one core.

## list

| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rust-h5i-optimized | 1 | 83.4 | 8.04 | 26.77 | 32.69 | 0.0 | 7.2 | 9.7 |
| rust-h5i-optimized | 16 | 766.3 | 13.81 | 49.68 | 78.78 | 0.0 | 10.6 | 69.3 |
| rust-h5i-gpu | 1 | 82.8 | 8.16 | 26.81 | 32.65 | 0.0 | 93.7 | 9.7 |
| rust-h5i-gpu | 16 | 769.7 | 13.79 | 49.40 | 78.82 | 0.0 | 97.2 | 69.3 |

## slug

| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rust-h5i-optimized | 1 | 1110.2 | 0.79 | 0.87 | 0.96 | 0.0 | 6.5 | 29.9 |
| rust-h5i-optimized | 16 | 13560.1 | 0.79 | 1.36 | 8.89 | 0.0 | 9.4 | 206.4 |
| rust-h5i-gpu | 1 | 1118.4 | 0.78 | 0.87 | 1.00 | 0.0 | 93.3 | 31.0 |
| rust-h5i-gpu | 16 | 14174.0 | 0.77 | 1.29 | 8.55 | 0.0 | 96.4 | 228.2 |

## feed

| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rust-h5i-optimized | 1 | 187.8 | 5.21 | 5.51 | 5.80 | 0.0 | 10.8 | 20.2 |
| rust-h5i-optimized | 16 | 2194.9 | 6.86 | 10.43 | 14.30 | 0.0 | 10.8 | 163.4 |
| rust-h5i-gpu | 1 | 179.6 | 5.46 | 5.78 | 6.10 | 0.0 | 97.8 | 25.7 |
| rust-h5i-gpu | 16 | 2201.7 | 6.89 | 10.36 | 13.99 | 0.0 | 97.8 | 174.2 |

## login

| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rust-h5i-optimized | 1 | 3.8 | 259.51 | 260.01 | 260.47 | 0.0 | 9.7 | 102.2 |
| rust-h5i-optimized | 16 | 15.4 | 1035.93 | 1074.51 | 1113.43 | 0.0 | 10.1 | 404.3 |
| rust-h5i-gpu | 1 | 3.8 | 260.87 | 261.46 | 261.96 | 0.0 | 96.7 | 102.3 |
| rust-h5i-gpu | 16 | 15.4 | 1038.07 | 1071.29 | 1104.02 | 0.0 | 97.1 | 403.4 |

## create

| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rust-h5i-optimized | 1 | 196.2 | 4.95 | 5.31 | 5.64 | 0.0 | 10.8 | 23.4 |
| rust-h5i-optimized | 16 | 216.3 | 46.73 | 171.19 | 363.18 | 0.0 | 10.8 | 40.4 |
| rust-h5i-gpu | 1 | 190.8 | 5.13 | 5.47 | 5.78 | 0.0 | 97.8 | 28.2 |
| rust-h5i-gpu | 16 | 209.9 | 48.72 | 177.08 | 367.29 | 0.0 | 97.8 | 45.0 |

## favorite

| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rust-h5i-optimized | 1 | 504.5 | 1.81 | 2.08 | 2.63 | 0.0 | 10.2 | 27.7 |
| rust-h5i-optimized | 16 | 4457.2 | 2.05 | 9.96 | 19.18 | 0.0 | 10.3 | 185.0 |
| rust-h5i-gpu | 1 | 439.2 | 2.07 | 2.62 | 3.15 | 0.0 | 97.3 | 42.6 |
| rust-h5i-gpu | 16 | 4725.1 | 2.07 | 5.91 | 17.90 | 0.0 | 97.3 | 234.2 |

## mixed

| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rust-h5i-optimized | 1 | 121.5 | 6.67 | 18.58 | 35.13 | 0.0 | 10.8 | 12.8 |
| rust-h5i-optimized | 16 | 1001.1 | 10.26 | 38.48 | 68.70 | 0.0 | 11.1 | 85.8 |
| rust-h5i-gpu | 1 | 123.9 | 6.72 | 18.05 | 33.75 | 0.0 | 97.8 | 12.9 |
| rust-h5i-gpu | 16 | 982.9 | 10.21 | 39.43 | 71.16 | 0.0 | 97.9 | 91.5 |
