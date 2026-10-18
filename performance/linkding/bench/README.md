# Benchmark

Latest follow-up: [single-get, creation and search improvements](hotpaths-2026-10-18.md).

Follow-up: [selectable SQL modes and fixed-offset list measurement](sql-modes-2026-10-18.md).

The [unique-membership SQL experiment](scalar-membership-2026-10-18.md)
measures an engine renderer optimization separately from the published
cross-language and CPU/GPU results.

`scripts/bench-parallel.sh` runs FastAPI, Go, Fastify, Rust, and the upstream
linkding 1.47.0 image together. Each one has its own Postgres 16 container
(`linkding-pg-<impl>` on ports 5440–5444) and its own CPUs.

The seed is 50 users, 100000 bookmarks owned by alice, and 2000 tags (`tag0`
through `tag1999`) also owned by alice. Two tags are attached to each bookmark.
Every 50th title contains the word `alpha`. The client token is alice's
40-character key. `bench/seed.sql` loads `schema.sql`. `bench/seed_upstream.sql`
loads the Django tables after the image has migrated.

Scenarios: `list`, `search` (`q=alpha`), `search_complex`, `search_tag` (`#tagN`), `get`,
`create`, `update`, `archive`, `tags`, and `mixed`.

Defaults: 10 s warmup, 30 s measure, 3 repetitions, concurrency 1, 16, 64, and
256. k6 writes `http_reqs` rate and `p(50)` / `p(90)` / `p(99)`.
`sample_proc.py` records peak RSS and CPU for the server process tree.
`summarize.py` writes `points.csv`, `summary.csv`, and `summary.md`.

`search_complex` evaluates
`(alpha or missing) and not (absent or unknown) and (example or bookmark) and not (zeta and beta)`.
Both text-search scenarios return 1000 active bookmarks, with 20 on the first
page of the shared 100000-row seed. The complex scenario checks the count and
page length as well as HTTP status. It is a synthetic query on the existing
dataset, not a production traffic trace. The original `mixed` remains 40% list,
20% simple search, 15% get, 10% tags, 8% update, 5% archive and 2% create.

Every point now stops the server before reseeding and restarts it afterwards:
direct SQL reseeding cannot invalidate a resident CPU/GPU index. Index building
is in warmup; rebuilds caused by writes during `mixed` are in the measurement.
The shared k6 workload detects failed HTTP/status checks. The usual harness
records `POINT_FAIL` and continues, retaining overload observations as before;
`BENCH_STRICT=1` stops on a failed point. The controlled runner below enables
strict mode. Client logs are saved beside the summaries.

For a controlled remeasurement of the affected search scenarios and mixed
traffic, use the same harness with prebuilt servers:

```sh
python3 performance/linkding/bench/remeasure-text.py \
  --cpu-bin /absolute/path/to/cpu-only/linkding-gpu-server \
  --gpu-bin /absolute/path/to/gpu/linkding-gpu-server \
  --sql-bin /absolute/path/to/optimized/linkding-server \
  --ptx /absolute/path/to/linkding_gpu_device.ptx \
  --out /absolute/path/to/new-results
```

This runs `search`, `search_complex` and `mixed`, with 10 s warmup, 30 s measure,
three repetitions and concurrency 1/16 by default (`--concurrency '1 16 64 256'`
for the full concurrency sweep). Variants are optimized SQL, the same GPU-server
source built without GPU support (`rust-h5i-cpu-scan`), the GPU build, and the
pinned upstream image. Each has four server, four PostgreSQL and four client
CPUs, with independent temporary databases and ports. The runner saves artifact
hashes, revision, configuration, raw k6 JSON/logs and standard summaries, then
removes its containers. Raw JSON, logs and metadata stay local; publish only
`summary.csv`, `summary.md` and `points.csv`, as in the existing results directories.
Only the search and mixed subset is rerun; this does
not replace published results for the other endpoints or implementations.
CPU/GPU comparisons isolate the scan backend; comparisons with optimized SQL
or upstream also include differences in indexing, language and architecture.

The [2026-10-17 remeasurement](text-search-2026-10-17.md) records all 72 points,
including the mixed workload where GPU acceleration has little benefit.

```sh
performance/linkding/scripts/bench-parallel.sh
BENCH_DURATION=3 BENCH_REPEATS=1 BENCH_CONCURRENCY=1 performance/linkding/scripts/bench-parallel.sh fastapi
```

Ports 5440 and 8105 are also used by the conformance database `linkding-pg` and
the image container `linkding-up`. Stop those before a run that includes
fastapi or upstream.

The [optimized single-get experiment](single-get-2026-10-18.md) removes a duplicate bookmark
lookup and compares before/after HTTP throughput with a freshly measured Go
server. It is separate from the original cross-language ranking.
