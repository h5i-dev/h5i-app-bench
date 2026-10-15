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
| rust-h5i | `cargo --release`, tokio worker threads 4 | `DB_POOL=32` |

## Seed

`seed.sql` loads 100 users (`user1@bench.test` … `user100@bench.test`,
password `password123`, one shared bcrypt cost-12 hash), 20 tags, 10 000
articles (`article-1` … `article-10000`), two tags per article, 10 000
comments, 1 000 follows (each user follows the next 10), and 5 000 favorites.
User 1's token is an HS256 JWT with `sub` = `1`, minted by the script.

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
the end. Run it again with `python3 realworld/bench/summarize.py realworld/bench/results`.

RSS is the peak sum of `VmRSS` for every process in the server session.
CPU percent sums that session; 100 means one fully busy core. Samples are
taken about four times a second during the measured window.

## Kernel overhead

`rust-h5i/kernel-bench` calls `transition` on `Command::Favorite` and the
same branch inlined, for 2 000 000 iterations. `bench-all.sh` runs it three
times on CPUs 0–3 and appends JSON lines to `results/kernel-bench.jsonl`.
That is the kernel measurement: the HTTP server always calls the kernel.
