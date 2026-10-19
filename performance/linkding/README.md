# Linkding API backends

Latest measurements: [summary refresh](bench/summary-refresh-2026-10-19.md).

Implementation changes: [single-get, creation and search improvements](bench/hotpaths-2026-10-18.md).

Follow-up: [selectable SQL modes and fixed-offset list measurement](bench/sql-modes-2026-10-18.md).

Five implementations of the [linkding](https://github.com/sissbruecker/linkding) REST API, one shared PostgreSQL schema, a Hurl conformance suite checked against the pinned upstream image, and a load benchmark. The upstream server is included in the benchmark as a reference.

| Directory | Stack |
| --- | --- |
| `upstream/` | Pinned tag, commit, and image notes |
| `fastapi/` | Python, FastAPI, asyncpg, uvicorn |
| `go/` | Go, chi, pgx |
| `fastify/` | TypeScript, Fastify, postgres.js |
| `rust-h5i/` | Rust, axum, the h5i-app engine (`h5i-app-pg`): kernel, read plans and writes with Lean proofs |
| `rust-h5i-optimized/` | Rust, axum, sqlx, h5i-app kernel and Lean proofs |
| `rust-h5i-gpu/` | Rust-CUDA GPU scan of the linkding search predicate; reuses `rust-h5i/kernel` and imports the h5i `h5i-app-gpu` launch shell (host-only, no CI) |
| `tests/` | Hurl suite |
| `bench/` | Seed, k6 scenarios, raw results, summary |
| `schema.sql` | Shared database (rust-h5i copies it into its own tables) |
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

The implementations share `schema.sql`. rust-h5i keeps its rows in h5i-app's own tables (schema `h5iapp`), which `bench/seed_h5i_app.sql` fills from the shared tables. The upstream container uses Django's tables and is seeded separately (`bench/seed_upstream.sql`).

```sh
performance/linkding/scripts/up-db.sh           # Postgres 16, container linkding-pg, port 5440
performance/linkding/scripts/up-db.sh --reset   # drop public and reapply schema.sql
```

Default URL: `postgres://linkding:linkding@127.0.0.1:5440/linkding`.

`scripts/test-upstream.sh` uses `linkding-pg-probe` on port 5449 and the image on port 8105. The parallel benchmark gives each implementation its own Postgres container on ports 5440–5445.

## Tests

Hurl is expected at `/var/tmp/tools/hurl`. Each file starts from the five fixture users (alice, bob, cara, dave, erin) and an empty bookmark, tag, and bundle set.

```sh
performance/linkding/scripts/test-upstream.sh          # suite against the pinned image
performance/linkding/scripts/test-all.sh               # fastapi, go, fastify, rust-h5i-optimized
performance/linkding/scripts/test-all.sh fastapi       # one implementation
performance/linkding/scripts/test-all.sh rust-h5i      # rust-h5i (not in the default set)
HOST=http://127.0.0.1:8101 performance/linkding/scripts/test-one.sh
```

Ports: FastAPI 8101, Go 8102, Fastify 8103, rust-h5i-optimized 8104, upstream 8105, rust-h5i 8106.

`WEB_CONCURRENCY` defaults to 1 in the test script and to 4 in each `run.sh`. FastAPI and Fastify open `DB_POOL` connections per worker (default 8). Go and the Rust servers are one process; their `run.sh` defaults `DB_POOL` to 32. The test script sets `DB_POOL` to 8 for every server.

## Run

```sh
export DATABASE_URL=postgres://linkding:linkding@127.0.0.1:5440/linkding
export WEB_CONCURRENCY=4

performance/linkding/fastapi/run.sh    # 127.0.0.1:8101  uvicorn workers = WEB_CONCURRENCY
performance/linkding/go/run.sh         # 127.0.0.1:8102  GOMAXPROCS = WEB_CONCURRENCY
performance/linkding/fastify/run.sh    # 127.0.0.1:8103  node cluster size = WEB_CONCURRENCY
performance/linkding/rust-h5i-optimized/run.sh   # 127.0.0.1:8104  tokio worker threads = WEB_CONCURRENCY
performance/linkding/rust-h5i/run.sh             # 127.0.0.1:8106  tokio worker threads = WEB_CONCURRENCY
```

## Benchmark

`scripts/bench-parallel.sh` runs fastapi, go, fastify, rust-h5i-optimized and the upstream image at once, each with its own Postgres container and a disjoint CPU set. rust-h5i uses rust-h5i-optimized's CPUs and runs on its own: `scripts/bench-parallel.sh rust-h5i`. Scenarios cover bookmark list, text search, `#tag` search, get, create, update, archive, tag list, and a mixed workload. The seed is 50 users, 100000 bookmarks owned by alice, and 2000 tags. Metrics are requests/s, p50/p90/p99, errors, and peak RSS and CPU. The published shape is 10 s warmup, 30 s measure, 3 repetitions, and concurrency 1, 16, 64, and 256.

| Implementation | Server CPUs | Postgres CPUs | k6 CPUs | Postgres port | HTTP port |
| --- | --- | --- | --- | --- | --- |
| fastapi | 0-3 | 4-7 | 8-11 | 5440 | 8101 |
| go | 12-15 | 16-19 | 20-23 | 5441 | 8102 |
| fastify | 24-27 | 28-31 | 32-35 | 5442 | 8103 |
| rust-h5i-optimized | 36-39 | 40-43 | 44-47 | 5443 | 8104 |
| upstream | 48-51 | 52-55 | 56-59 | 5444 | 8105 |
| rust-h5i | 36-39 | 40-43 | 44-47 | 5445 | 8106 |

The [search execution-plan experiment](bench/search-plan-2026-10-18.md)
compares the normal engine application before and after analyzing its seeded
tables. It is separate from the published cross-language ranking. New
PostgreSQL containers allocate 1 GiB of shared memory for parallel queries
(`LINKDING_PG_SHM_SIZE` overrides this); existing containers keep their capacity.

The follow-up [scalar-membership experiment](bench/scalar-membership-2026-10-18.md)
keeps the application read plans and exact counts, and changes how the engine
renders primary-key membership lookups. It includes its own HTTP before/after
results and validation of the existing proof gates.

## Proofs

Both Rust implementations have a kernel extracted to Lean (`h5i app extract`
writes `proofs/generated/`; `h5i app check` builds the proofs and rejects
`sorry` and new axioms).

`rust-h5i` runs every request in the h5i-app engine: the kernel decides
authentication (from the token table), visibility, ownership, search
(including legacy search), bundles, ordering, paging and counts, and the
engine loads only the rows the kernel's read plan names and stores the
kernel's writes. Lean proves that every write is the caller's, that guests
write nothing, that read-only commands write nothing, that the store holds
what the kernel applies, and that every command's read plan loads enough
for the kernel to give the result it gives on the whole site
(`rust-h5i/README.md`).

`rust-h5i-optimized/kernel` holds authorization, visibility, validation,
pagination, and the search parser and match predicate. Its HTTP process looks
up tokens and rows with its own SQL and calls the kernel; that SQL is not
covered by the proofs. Search term matching in its kernel folds ASCII case.
SQL `ILIKE` and stored `name_lower` follow the same ASCII inputs used by the
suite. Legacy search, selected by the viewer's profile flag, is applied in
its HTTP process; the kernel evaluates the default query language.

The [optimized single-get experiment](bench/single-get-2026-10-18.md) removes a duplicate bookmark
lookup and compares before/after HTTP throughput with a freshly measured Go
server. It is separate from the original cross-language ranking.
