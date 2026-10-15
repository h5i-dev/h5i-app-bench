# Linkding API backends

Four implementations of the [linkding](https://github.com/sissbruecker/linkding) REST API, one shared PostgreSQL schema, a Hurl conformance suite checked against the pinned upstream image, and a load benchmark. The upstream server is included in the benchmark as a reference.

| Directory | Stack |
| --- | --- |
| `upstream/` | Pinned tag, commit, and image notes |
| `fastapi/` | Python, FastAPI, asyncpg, uvicorn |
| `go/` | Go, chi, pgx |
| `fastify/` | TypeScript, Fastify, postgres.js |
| `rust-h5i/` | Rust, axum, sqlx, h5i-app kernel and Lean proofs |
| `tests/` | Hurl suite |
| `bench/` | Seed, k6 scenarios, raw results, summary |
| `schema.sql` | Shared database for the four implementations |
| `scripts/` | Database, tests, and the parallel benchmark |

## Scope

The pinned release is linkding **1.47.0** (`24b5ad6cc9bde497b5d1b1e86aed5a2fb7d25c2f`), image `sissbruecker/linkding:1.47.0`. `upstream/fetch.sh` clones that tag. The Hurl suite was run against the image.

Covered:

- `Authorization: Token …` (the `Bearer` keyword is accepted the same way)
- `GET/POST /api/bookmarks/`, `GET /api/bookmarks/archived/`, `GET /api/bookmarks/shared/`
- `GET/PUT/PATCH/DELETE /api/bookmarks/{id}/`
- `POST /api/bookmarks/{id}/archive/` and `…/unarchive/`
- `GET /api/bookmarks/check/`
- tag and bundle list, create, get, update, and delete
- `GET /api/user/profile/`
- pagination (`limit` / `offset`, `next` / `previous`)
- the search query language (terms, `#tags`, `!unread`, `!untagged`, `and` / `or` / `not`, quotes)
- owner-only reads and writes, and the shared-bookmark list

Not covered: the HTML UI, favicon and preview files, website-metadata fetching, archive.org snapshot jobs, background tasks, and import/export. Creating or checking a bookmark does no network I/O. `website_title`, `website_description`, `favicon_url`, and `preview_image_url` are null. `web_archive_snapshot_url` is the computed Wayback URL from `date_added` and the stored URL. `?disable_scraping` is accepted and ignored. The check endpoint returns empty metadata and an empty `auto_tags` list. Profile `version` is `1.47.0`.

The reference process is the image's uWSGI configuration (`processes = 2`, `threads = 2`). Benchmark runs set `LD_SERVER_HOST=127.0.0.1` and `LD_DISABLE_BACKGROUND_TASKS=True`.

## Database

The four implementations share `schema.sql`. The upstream container uses Django's tables and is seeded separately (`bench/seed_upstream.sql`).

```sh
linkding/scripts/up-db.sh           # Postgres 16, container linkding-pg, port 5440
linkding/scripts/up-db.sh --reset   # drop public and reapply schema.sql
```

Default URL: `postgres://linkding:linkding@127.0.0.1:5440/linkding`.

`scripts/test-upstream.sh` uses `linkding-pg-probe` on port 5449 and the image on port 8105. The parallel benchmark gives each implementation its own Postgres container on ports 5440–5444.

## Tests

Hurl is expected at `/var/tmp/tools/hurl`. Each file starts from the five fixture users (alice, bob, cara, dave, erin) and an empty bookmark, tag, and bundle set.

```sh
linkding/scripts/test-upstream.sh          # suite against the pinned image
linkding/scripts/test-all.sh               # fastapi, go, fastify, rust-h5i
linkding/scripts/test-all.sh fastapi       # one implementation
HOST=http://127.0.0.1:8101 linkding/scripts/test-one.sh
```

Ports: FastAPI 8101, Go 8102, Fastify 8103, Rust 8104, upstream 8105.

`WEB_CONCURRENCY` defaults to 1 in the test script and to 4 in each `run.sh`. FastAPI and Fastify open `DB_POOL` connections per worker (default 8). Go and Rust are one process; their `run.sh` defaults `DB_POOL` to 32. The test script sets `DB_POOL` to 8 for every server.

## Run

```sh
export DATABASE_URL=postgres://linkding:linkding@127.0.0.1:5440/linkding
export WEB_CONCURRENCY=4

linkding/fastapi/run.sh    # 127.0.0.1:8101  uvicorn workers = WEB_CONCURRENCY
linkding/go/run.sh         # 127.0.0.1:8102  GOMAXPROCS = WEB_CONCURRENCY
linkding/fastify/run.sh    # 127.0.0.1:8103  node cluster size = WEB_CONCURRENCY
linkding/rust-h5i/run.sh   # 127.0.0.1:8104  tokio worker threads = WEB_CONCURRENCY
```

## Benchmark

`scripts/bench-parallel.sh` runs the four implementations and the upstream image at once, each with its own Postgres container and a disjoint CPU set. Scenarios cover bookmark list, text search, `#tag` search, get, create, update, archive, tag list, and a mixed workload. The seed is 50 users, 100000 bookmarks, and 2000 tags. Metrics are requests/s, p50/p90/p99, errors, and peak RSS and CPU. The published shape is 10 s warmup, 30 s measure, 3 repetitions, and concurrency 1, 16, 64, and 256.

## Proofs

`rust-h5i/kernel` holds authorization, visibility, validation, pagination, and the search parser and match predicate. The HTTP process looks up tokens and rows and calls the kernel. `h5i app extract` writes `rust-h5i/proofs/generated/`. `h5i app check` builds the Lean proofs and rejects `sorry` and new axioms.

Search term matching in the kernel folds ASCII case. SQL `ILIKE` and stored `name_lower` follow the same ASCII inputs used by the suite.
