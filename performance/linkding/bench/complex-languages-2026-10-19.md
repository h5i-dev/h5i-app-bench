# Linkding complex search: Go, FastAPI and Fastify

Measured 2026-10-19 using application sources at `e3b31b254b62ac0db4140277ad9a4c875ed1dd2d`.
Only the runner and site/reporting files were changed for this measurement.
This supplements the [Rust CPU/GPU text-search run](text-search-2026-10-17.md)
so the overview can show the same complex-search scenario across languages.

## Workload and conditions

The unchanged shared `workload.js` sends:

```text
GET /api/bookmarks/?q=(alpha or missing) and not (absent or unknown) and (example or bookmark) and not (zeta and beta)&limit=20
```

The query is URL encoded. Every request checks HTTP 200, an exact count of
1,000 and a first page of 20 results. This is a synthetic eight-term boolean
query, on the existing seed of 100,000 bookmarks, 2,000 tags and 50 users.

Each point starts with a fresh server and reseeded database, then 10 seconds
of warmup and 30 seconds of measurement. Concurrency is 1 and 16, with three
repetitions. Three variants run concurrently with separate PostgreSQL 16
containers (512 MiB shared buffers, 200 connections, 1 GiB shared memory).
Go uses four GOMAXPROCS and a pool of 32; Python and TypeScript use four
workers with a pool of eight each. Server, PostgreSQL and client CPU sets do
not overlap. PostgreSQL affinity is set inside each container.

| Variant | Server CPUs | PostgreSQL CPUs | k6 CPUs |
| --- | --- | --- | --- |
| Go | 0–3 | 4–7 | 8–11 |
| FastAPI | 12–15 | 16–19 | 20–23 |
| Fastify | 24–27 | 28–31 | 32–35 |

Host: dual AMD EPYC 7502, 128 logical CPUs; shared machine, clocks and NUMA
placement not fixed. Go 1.27.2, Python 3.12.3, Node 24.21.0, k6 2.3.0.
Application dependency manifests and lockfiles are unchanged.

## Results

Requests/s and p99 are means of three repetitions; p99 is the mean of
per-repetition percentiles, not a pooled percentile. Request rate includes
k6's graceful stop. Standard deviation is across the three request rates.

| Implementation | Clients | req/s | req/s stdev | p99 ms |
| --- | ---: | ---: | ---: | ---: |
| fastapi | 1 | 1.22 | 0.00 | 845.09 |
| fastapi | 16 | 4.91 | 0.02 | 5258.82 |
| go | 1 | 2.29 | 0.00 | 440.20 |
| go | 16 | 4.87 | 0.00 | 4730.04 |
| fastify | 1 | 2.21 | 0.02 | 479.38 |
| fastify | 16 | 4.88 | 0.02 | 4699.83 |

All 18 measurement points passed: 1,910 measured HTTP requests, zero
HTTP failures and zero failed response checks. All 18 warmups also passed.
The existing shared count/page checks ran on every complex-search request.

The overview combines these results with the Rust SQL, resident CPU scan and
GPU scan results from 2026-10-17. The earlier Rust run used the same query,
seed, durations, concurrency and per-variant CPU counts, but ran on a different
date with different slot assignments and four concurrent variants. Cross-run
rankings are descriptive, not a matched GPU-only speedup. Use the paired CPU
scan/GPU scan results in the earlier report for that comparison. This run does
not measure the h5i-app engine ([measured separately](complex-engine-2026-10-19.md)),
64/256 clients, other scenarios or application-wide
performance. Unmeasured cells remain `–`.

## Reproduction and artifacts

```sh
python3 performance/linkding/bench/remeasure-complex.py \
  --out /var/tmp/h5i-complex-languages-new-run
```

The output directory must not exist. The runner uses separate temporary
PostgreSQL containers and removes them after completion. Generated
[summary CSV](results/complex-languages-2026-10-19/summary.csv),
[summary Markdown](results/complex-languages-2026-10-19/summary.md) and
[per-point CSV](results/complex-languages-2026-10-19/points.csv) are retained in
the repository. Raw k6 JSON, warmup results, server logs and run metadata remain
local at `/var/tmp/h5i-complex-languages-20261019`.
