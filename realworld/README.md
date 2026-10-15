# RealWorld (Conduit) backends

Four implementations of the [RealWorld API](https://github.com/realworld-apps/realworld),
sharing one PostgreSQL schema, plus a load benchmark.

| Directory | Stack |
| --- | --- |
| `spec/` | Pinned upstream OpenAPI document and Hurl suite |
| `fastapi/` | Python, FastAPI, asyncpg, uvicorn |
| `go/` | Go, chi, pgx |
| `fastify/` | TypeScript, Fastify, postgres.js |
| `rust-h5i/` | Rust, axum, sqlx, h5i-app kernel and Lean proofs |
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
realworld/scripts/up-db.sh          # start Postgres 16 and apply schema.sql
realworld/scripts/up-db.sh --reset  # drop public and reapply
```

The container is `conduit-pg` (`postgres:16`, `max_connections=200`,
`shared_buffers=512MB`). When the host allows it, the script pins that
process tree to CPUs 8–15.

## Tests

Hurl is expected at `/var/tmp/tools/hurl`.

```sh
realworld/scripts/test-all.sh                 # all four, ports 8001–8004
realworld/scripts/test-all.sh fastapi         # one implementation
HOST=http://127.0.0.1:8001 realworld/scripts/test-one.sh
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

realworld/fastapi/run.sh     # 127.0.0.1:8001  uvicorn workers = WEB_CONCURRENCY
realworld/go/run.sh          # 127.0.0.1:8002  GOMAXPROCS = WEB_CONCURRENCY
realworld/fastify/run.sh     # 127.0.0.1:8003  node cluster size = WEB_CONCURRENCY
realworld/rust-h5i/run.sh    # 127.0.0.1:8004  tokio worker threads = WEB_CONCURRENCY
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

`rust-h5i` keeps authorization and validation in `kernel/`. `h5i app extract`
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
