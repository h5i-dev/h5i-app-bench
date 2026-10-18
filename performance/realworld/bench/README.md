# Conduit load benchmark

`scripts/bench-all.sh` reseeds Postgres, starts one implementation, and runs
k6. The published configuration is:

| Setting | Value |
| --- | --- |
| Load generator | k6 v2 at `/var/tmp/tools/k6` |
| Warmup | 10 s, discarded |
| Measure | 30 s, then up to 15 s graceful stop (60 s for login) |
| Repetitions | 3 |
| Concurrency | 1, 16, 64, 256 virtual users |
| Server CPUs | 0–3 (`taskset`) |
| k6 CPUs | 4–7 |
| Postgres CPUs | 8–15 (pinned by `scripts/up-db.sh`) |
| Database | reseeded before every point |

Production settings during the bench (not the API-test defaults):

| Implementation | Processes | Pool |
| --- | --- | --- |
| FastAPI | uvicorn `--workers 4`, no access log | `DB_POOL=8` per worker (32 total) |
| Go | one process, `GOMAXPROCS=4` | `DB_POOL=32` |
| Fastify | `NODE_ENV=production`, cluster size 4, `UV_THREADPOOL_SIZE=4` | `DB_POOL=8` per worker (32 total) |
| rust-h5i-optimized | `cargo --release`, tokio worker threads 4 | `DB_POOL=32` |
| rust-h5i | `cargo --release`, tokio worker threads 4 | `DB_POOL=32` |

## Seed

`seed.sql` loads 100 users (`user1@bench.test` … `user100@bench.test`,
password `password123`, one shared bcrypt cost-12 hash), 20 tags, 10 000
articles (`article-1` … `article-10000`), two tags per article, 10 000
comments, 1 000 follows (each user follows the next 10), and 5 000 favorites.
User 1's token is an HS256 JWT with `sub` = `1`, minted by the script.

rust-h5i stores its rows in h5i-app's tables (schema `conduit`), so
for it every point also runs `seed_h5i_app.sql` after `seed.sql`: it copies
the rows `seed.sql` just loaded, with the same ids, slugs, hashes and
timestamps, and sets the id counters past them. `check_h5i_app_seed.sql`
compares both sets of tables row for row (every `diff` is 0).

rust-h5i shares rust-h5i-optimized's CPUs in `scripts/bench-parallel.sh` (server
48–51, Postgres 52–55, k6 56–63) with its own container
`conduit-pg-rust-h5i` on port 54335, so it runs on its own:
`scripts/bench-parallel.sh rust-h5i`.

## Scenarios

| Name | Requests |
| --- | --- |
| `list` | `GET /api/articles`, rotating limit 20 with offset 0, a later offset, and `tag=tagN` |
| `slug` | `GET /api/articles/article-N` |
| `feed` | `GET /api/articles/feed?limit=20` with user 1's token |
| `login` | `POST /api/users/login` for a rotating user |
| `create` | `POST /api/articles` as user 1 |
| `favorite` | `POST /api/articles/article-N/favorite` as user 1 with body `{}`, N in 5001–10000 |
| `mixed` | 50% list, 20% slug, 15% feed, 10% favorite, 5% create |

Login is its own scenario. bcrypt cost 12 dominates that row. k6's
requests/s uses the whole elapsed window, including the graceful stop while
in-flight logins finish.

## Results

Each point writes:

- `results/<impl>_<scenario>_c<conc>_r<rep>.summary.json` — k6 `--summary-export`
- `results/<impl>_<scenario>_c<conc>_r<rep>.meta.json` — peak RSS and CPU

`bench/summarize.py` reads those files and writes `results/points.csv`,
`results/summary.csv`, and `results/summary.md`. `bench-all.sh` runs it at
the end. Run it again with `python3 performance/realworld/bench/summarize.py performance/realworld/bench/results`.

RSS is the peak sum of `VmRSS` for every process in the server session.
CPU percent sums that session; 100 means one fully busy core. Samples are
taken about four times a second during the measured window.

## Kernel overhead

`rust-h5i-optimized/kernel-bench` calls `transition` on `Command::Favorite` and the
same branch inlined, for 2 000 000 iterations. `bench-all.sh` runs it three
times on CPUs 0–3 and appends JSON lines to `results/kernel-bench.jsonl`.
That is the kernel measurement: the HTTP server always calls the kernel.

## Paired optional GPU measurement

The GPU variant is explicit: `CONDUIT_GPU_PTX=/path/conduit_gpu_device.ptx
scripts/bench-all.sh rust-h5i-gpu`. Build instructions and policy scope are in
[`../rust-h5i-gpu/README.md`](../rust-h5i-gpu/README.md). It shares the optimized
CPU server's source; no new workload or database schema is introduced.
`scripts/test-all.sh rust-h5i-gpu` runs the same pinned Hurl suite.

For isolated CPU/GPU comparisons, use prebuilt release executables:

```sh
python3 performance/realworld/bench/remeasure-gpu.py \
  --cpu-bin /path/to/cpu/conduit-server \
  --gpu-bin /path/to/gpu/conduit-server \
  --ptx /path/to/conduit_gpu_device.ptx --out /var/tmp/conduit-gpu-run
```

The default is all seven shared scenarios, concurrency 1/16, three repetitions,
10 s warmup and 30 s measurement. Each variant has four server, four PostgreSQL
and four client CPUs on disjoint affinity, four Tokio threads and a pool of 32.
The runner starts its own databases, records local artifact hashes and run
configuration, and removes only its containers afterwards. `--lanes 2` splits
scenarios across two independent CPU/GPU pairs (48 CPU IDs, GPUs 0 and 1).
Use one lane on hosts with only one GPU. Raw JSON, logs and metadata remain
local; publish only `summary.csv`, `summary.md` and `points.csv`.

`BENCH_SERVER_BIN` bypasses builds for a prebuilt single-variant run and
`BENCH_PORT` selects its HTTP port. `BENCH_STRICT=1` makes failed warmups or
measurements stop the harness. Both failed HTTP requests and failed k6 checks
are thresholds; ordinary sweeps still record overload failures and continue.
GPU is optional and not included in the default portable sweep.
