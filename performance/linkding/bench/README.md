# Benchmark

`scripts/bench-parallel.sh` runs FastAPI, Go, Fastify, Rust, and the upstream
linkding 1.47.0 image together. Each one has its own Postgres 16 container
(`linkding-pg-<impl>` on ports 5440–5444) and its own CPUs.

The seed is 50 users, 100000 bookmarks owned by alice, and 2000 tags (`tag0`
through `tag1999`) also owned by alice. Two tags are attached to each bookmark.
Every 50th title contains the word `alpha`. The client token is alice's
40-character key. `bench/seed.sql` loads `schema.sql`. `bench/seed_upstream.sql`
loads the Django tables after the image has migrated.

Scenarios: `list`, `search` (`q=alpha`), `search_tag` (`#tagN`), `get`,
`create`, `update`, `archive`, `tags`, and `mixed`.

Defaults: 10 s warmup, 30 s measure, 3 repetitions, concurrency 1, 16, 64, and
256. k6 writes `http_reqs` rate and `p(50)` / `p(90)` / `p(99)`.
`sample_proc.py` records peak RSS and CPU for the server process tree.
`summarize.py` writes `points.csv`, `summary.csv`, and `summary.md`.

```sh
performance/linkding/scripts/bench-parallel.sh
BENCH_DURATION=3 BENCH_REPEATS=1 BENCH_CONCURRENCY=1 performance/linkding/scripts/bench-parallel.sh fastapi
```

Ports 5440 and 8105 are also used by the conformance database `linkding-pg` and
the image container `linkding-up`. Stop those before a run that includes
fastapi or upstream.
