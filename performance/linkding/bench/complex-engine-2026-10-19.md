# Linkding complex search: h5i engine

Measured 2026-10-19 with the normal `rust-h5i` server, using application sources
at `e3b31b254b62ac0db4140277ad9a4c875ed1dd2d` and locked h5i dependency
`8e764ab849f71e771bc8d026491a3c104f8cb6a5`. Application sources and dependencies
were unchanged. The runner built the server with `cargo build --release --locked`
and rustc 1.98.1.

## Workload and conditions

The shared `workload.js` sends this URL-encoded query:

```text
GET /api/bookmarks/?q=(alpha or missing) and not (absent or unknown) and (example or bookmark) and not (zeta and beta)&limit=20
```

Each request checks HTTP 200, exactly 1,000 matches and a page of 20 results.
The unchanged seed has 100,000 bookmarks, 2,000 tags and 50 users;
`seed_h5i_app.sql` copies it into the engine's tables and runs `ANALYZE`.
Each point starts a fresh server and reseeds the database, then runs a
10-second warmup and 30-second measurement. Concurrency is 1 and 16,
with three repetitions each.

The server uses four workers and a connection pool of 32. Server CPUs are
0–3, PostgreSQL CPUs 4–7 and k6 CPUs 8–11. PostgreSQL 16 runs in a dedicated
container with 512 MiB shared buffers, 200 connections and 1 GiB shared memory;
affinity is set inside the container. Host: dual AMD EPYC 7502, 128 logical
CPUs; shared machine, clocks and NUMA placement not fixed. k6 version: 2.3.0.

Only this variant ran in this invocation. The [other-language run](complex-languages-2026-10-19.md)
ran three variants concurrently; the [earlier Rust run](text-search-2026-10-17.md)
ran four. Query, seed, durations, concurrency and CPU counts match, but
cross-run rankings describe those runs rather than isolate GPU speedup.

This server uses the h5i-app-pg engine and evaluates search on CPU after
loading scoped data from PostgreSQL. The resident CPU/GPU search servers
have a different data path. Their paired results are in the earlier Rust report.

## Results

Means of three repetitions. p99 is the mean of per-run percentiles,
not a pooled percentile; req/s includes k6's graceful stop.

| Clients | req/s | req/s stdev | p99 ms |
| ---: | ---: | ---: | ---: |
| 1 | 1.62 | 0.02 | 654.41 |
| 16 | 8.61 | 0.08 | 3106.85 |

All six measured points passed: 963 HTTP requests, zero HTTP failures
and zero failed response checks. All six warmups also passed.

Archived [summary CSV](results/complex-engine-2026-10-19/summary.csv),
[summary Markdown](results/complex-engine-2026-10-19/summary.md) and
[per-point CSV](results/complex-engine-2026-10-19/points.csv).

## Reproduction and artifacts

```sh
python3 performance/linkding/bench/remeasure-complex.py \
  --implementations rust-h5i \
  --out /var/tmp/h5i-complex-engine-new-run \
  --pg-port-base 15740 --http-port-base 18440
```

The output directory must not exist. The runner removes its temporary
PostgreSQL container after completion. Raw k6 JSON, warmups, server logs,
binary hash and run metadata remain at `/var/tmp/h5i-complex-engine-20261019`.
