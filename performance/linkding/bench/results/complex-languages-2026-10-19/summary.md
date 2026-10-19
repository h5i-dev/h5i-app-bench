# Benchmark summary

Means of the recorded repetitions. Requests/s is k6 `http_reqs.rate`.
Latencies are milliseconds (`p(50)`, `p(90)`, `p(99)`). Errors are the
mean count of failed HTTP requests. RSS is the peak sum of VmRSS across
the server process tree, in MiB. CPU percent is 100 for one core.

## search_complex

| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| fastapi | 1 | 1.2 | 819.04 | 827.19 | 845.09 | 0.0 | 219.4 | 7 |
| fastapi | 16 | 4.9 | 3213.42 | 3610.72 | 5258.82 | 0.0 | 223.6 | 37 |
| go | 1 | 2.3 | 436.23 | 438.28 | 440.20 | 0.0 | 15.7 | 4 |
| go | 16 | 4.9 | 2429.70 | 4678.22 | 4730.04 | 0.0 | 16.8 | 8 |
| fastify | 1 | 2.2 | 450.91 | 464.70 | 479.38 | 0.0 | 389.6 | 9 |
| fastify | 16 | 4.9 | 2437.35 | 4607.81 | 4699.83 | 0.0 | 398.7 | 26 |

