# Benchmark summary

Means of the recorded repetitions. Requests/s is k6 `http_reqs.rate`.
Latencies are milliseconds (`p(50)`, `p(90)`, `p(99)`). Errors are the
mean count of failed HTTP requests. RSS is the peak sum of VmRSS across
the server process tree, in MiB. CPU percent is 100 for one core.

## search_complex

| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rust-h5i | 1 | 1.6 | 617.51 | 636.97 | 654.41 | 0.0 | 374.8 | 98 |
| rust-h5i | 16 | 8.6 | 1804.94 | 2516.85 | 3106.85 | 0.0 | 1742.7 | 392 |

