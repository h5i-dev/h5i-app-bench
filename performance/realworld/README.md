# RealWorld (Conduit) backends

Five implementations of the [RealWorld API](https://github.com/realworld-apps/realworld),
four sharing one PostgreSQL schema and one on h5i-app's own tables, plus a
load benchmark.

| Directory | Stack |
| --- | --- |
| `spec/` | Pinned upstream OpenAPI document and Hurl suite |
| `fastapi/` | Python, FastAPI, asyncpg, uvicorn |
| `go/` | Go, chi, pgx |
| `fastify/` | TypeScript, Fastify, postgres.js |
| `rust-h5i-optimized/` | Rust, axum, sqlx, h5i-app kernel and Lean proofs |
| `rust-h5i/` | Rust, axum, the h5i-app engine (`h5i-app-pg`): Conduit: kernel, server and Lean proofs, on h5i `main` (pinned in `Cargo.lock` and `proofs/lake-manifest.json`) |
| `bench/` | Seed, k6 scenarios, raw results, summary |
| `schema.sql` | The shared database |

## Contract

`spec/UPSTREAM_COMMIT` is `ebbcdeb8d55b42a3a613c787560498b8ef10003f` of
`realworld-apps/realworld`. `spec/api/hurl` is the source of truth.
`spec/fetch.sh` checks that commit out again.

Every server uses:

- PostgreSQL database `postgres://conduit:conduit@127.0.0.1:54329/conduit`
- bcrypt cost **12**, a hard-coded constant in each server
- JWT **HS256**, claim `sub` = user id, expiry 60 days
- default secret `conduit-benchmark-secret` (`JWT_SECRET`)
- header `Authorization: Token <jwt>`
- the same slug rules (ASCII lowercasing, collapsed hyphens, numeric suffix)

List responses omit `body`. Articles are ordered by `created_at` descending,
then `id` descending. Default page size is 20.

## Database

```sh
performance/realworld/scripts/up-db.sh          # start Postgres 16 and apply schema.sql
performance/realworld/scripts/up-db.sh --reset  # drop public and reapply
```

The container is `conduit-pg` (`postgres:16`, `max_connections=200`,
`shared_buffers=512MB`). When the host allows it, the script pins that
process tree to CPUs 8–15.

## Tests

Hurl is expected at `/var/tmp/tools/hurl`.

```sh
performance/realworld/scripts/test-all.sh                 # the four, ports 8001–8004
performance/realworld/scripts/test-all.sh rust-h5i    # port 8005
performance/realworld/scripts/test-all.sh fastapi         # one implementation
HOST=http://127.0.0.1:8001 performance/realworld/scripts/test-one.sh
```

`WEB_CONCURRENCY` defaults to 1 in the test script and to 4 in each `run.sh`.
FastAPI and Fastify open `DB_POOL` connections per worker (default 8), so four
workers open 32. Go and the Rust server are one process; their `run.sh`
defaults `DB_POOL` to 32. The test script sets `DB_POOL` to 8 for every server.

## Run

```sh
export DATABASE_URL=postgres://conduit:conduit@127.0.0.1:54329/conduit
export JWT_SECRET=conduit-benchmark-secret
export WEB_CONCURRENCY=4

performance/realworld/fastapi/run.sh     # 127.0.0.1:8001  uvicorn workers = WEB_CONCURRENCY
performance/realworld/go/run.sh          # 127.0.0.1:8002  GOMAXPROCS = WEB_CONCURRENCY
performance/realworld/fastify/run.sh     # 127.0.0.1:8003  node cluster size = WEB_CONCURRENCY
performance/realworld/rust-h5i-optimized/run.sh    # 127.0.0.1:8004  tokio worker threads = WEB_CONCURRENCY
performance/realworld/rust-h5i/run.sh  # 127.0.0.1:8005  tokio worker threads = WEB_CONCURRENCY
```

Release builds: `cargo build --release` (target dir `/var/tmp/rw-target`),
`go build`, Node `NODE_ENV=production`. Toolchains that are not already on
the machine live under `/var/tmp` (`/var/tmp/go`, `/var/tmp/tools`).

## Benchmark

`scripts/bench-all.sh` reseeds identical data, pins the server to CPUs 0–3
and k6 to CPUs 4–7, and writes raw JSON plus `bench/results/summary.md`.
The load shape, production process settings, and kernel microbenchmark are
in `bench/README.md`. The published run uses 10 s warmup, 30 s measure,
3 repetitions, and concurrency 1, 16, 64, and 256. Login then allows up to
60 s for in-flight requests to finish. Other scenarios allow 15 s.

## Proofs

`rust-h5i-optimized` keeps authorization and validation in `kernel/`. `h5i app extract`
writes `proofs/generated/`. `h5i app check` builds the Lean proofs and rejects
`sorry` and new axioms.

The kernel also decides login from user-existence/password-match observations,
resolves verified JWT claims to actors (strictly `exp > now`, positive parsed
subject, existing user), and rejects username/email conflicts in that order.
User response fields follow a kernel policy: email and token require an
identified self-view; profiles always omit both. The shell serializes every
user/profile object through that policy.

The shell retains bcrypt (including the dummy hash on unknown-user login),
JWT signature verification/signing, claim/header decoding, and the clock:
these are library operations or environmental observations. PostgreSQL reads,
transactions, and unique constraints supply existence/conflict facts and enforce
atomic writes; username/email constraint failures also use the kernel conflict
decision. HTTP/JSON encoding and SQL execution remain shell I/O. Slug collision
retries and their storage errors remain with persistence. Per-viewer following
and favorited observations still come from SQL joins.

## rust-h5i

`rust-h5i/` is Conduit's home: its kernel (`kernel/`), server
(`server/`), Lean proofs (`proofs/`) and their gate (`h5i-app.toml`;
`h5i app extract --check`, `h5i app check`, 627 theorems) live there, with
the same layout as `rust-h5i-optimized/` (see `rust-h5i/README.md`). It is a standard h5i-app application: every request runs in the
`h5i-app-pg` engine, which loads the rows the kernel's extracted read plan
names (`Frame.frame` proves they are enough), calls the kernel, and stores
the writes the kernel plans in one SERIALIZABLE transaction; read-only
commands run on a deferrable read-only snapshot. It passes the same pinned
Hurl suite.

Its rows live in h5i-app's own tables (schema `conduit`, a `tenant_id` in
every key, text as UTF-8 `bytea`, times in milliseconds), not in
`schema.sql`'s. The benchmark gives it the same data: each point runs
`bench/seed.sql` as for the others and then `bench/seed_h5i_app.sql`, which
copies those rows (ids, slugs, bcrypt hashes, timestamps) into its tables
and sets its id counters to continue after them.
`bench/check_h5i_app_seed.sql` compares the two row for row.

What differs from the other four, as `rust-h5i/README.md` lists: request
validation, bcrypt, JWTs, slugs and the clock are in the shell, as in
`rust-h5i-optimized`; the login reads the stored hash through the engine and the
kernel accepts it only if it equals the stored one; `tagList` comes back
sorted by tag (the order the tags table loads), where the shared schema
keeps the order given, so seeded articles list e.g. `["tag0", "tag19"]`
instead of `["tag19", "tag0"]`.
