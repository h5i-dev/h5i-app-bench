# django-cart framework comparison

The main performance summary compares the same implementations and displays the
same HTTP metrics as RealWorld and linkding, in this order:

`rust-h5i`, `rust-h5i-optimized`, `rust-h5i-gpu`, `fastapi`, `go`, `fastify`.

Each request is `GET /carts/{id}/total`, returning exact integer cents from the
same committed PostgreSQL rows. The two datasets have 4,096 / 65,536 carts and
32 lines per cart. There is no collection window or cross-request batching.
The contract is the pinned upstream library's bounded pricing subset, described
in the [parent README](../README.md); it excludes sessions, auth, writes,
checkout and custom tax/shipping. This is a read-only adapter comparison.

| Implementation | Execution |
| --- | --- |
| `rust-h5i` | Actual h5i-app PostgreSQL Engine and Store. One complete cart is one tenant; generated table reads access views over the shared source tables. CPU pricing runs in Kernel::transition. The default transaction path includes locking/clock handling. No partial-state or read-only overrides. |
| `rust-h5i-optimized` | Rust axum/sqlx, PostgreSQL SUM, the shared integer pricing kernel; MODE=sql in the Rust server. |
| `rust-h5i-gpu` | Validated Rust axum/sqlx/CUDA adapter, one SQL/CUDA worker, one request per launch, fresh upload and full download; MODE=gpu, BATCH_MAX=1, BATCH_WAIT_US=0. |
| `fastapi` | Python FastAPI, asyncpg, PostgreSQL SUM; four uvicorn workers. |
| `go` | Go net/http, pgx, PostgreSQL SUM; four Go scheduler threads. |
| `fastify` | Node.js Fastify, postgres.js, PostgreSQL SUM; four cluster workers. |

The application pricing kernel and its adapter have differential tests, **no
application-specific Lean proof**. This qualification also applies to the
`rust-h5i-optimized` label here. h5i-app supplies the engine and GPU launch shell.
Engine views use cart ID as tenant ID and expose the complete state, so
committed public-table updates are visible immediately without copying seeds
or maintaining a separate cache. Physical tables and indexes remain shared.

Every server gets four CPU cores, PostgreSQL another four, k6 another four.
Rust CPU/Go use 32 DB connections; Python/Node use eight per worker (32 total).
The CUDA adapter has one SQL/CUDA worker. Its connection/launch serialization
is part of that implementation, and is not a bound on GPU performance.

For every dataset, run 1/16/64/256 clients, 10 s warmup, 30 s measurement,
three repetitions, no think time. Reseed and restart for each point. Variant
order is deterministically shuffled within each repetition. k6 checks every
response's ID and exact cents. Report means for requests/s, p50/p90/p99 latency,
failed requests, peak RSS MiB and peak CPU percent; RPS also has sample standard
deviation. Resources cover the entire server process tree, including workers;
PostgreSQL and GPU memory are excluded. This is a shared-host, warm-buffer
experiment with uncontrolled clocks/NUMA. No cost or power comparison.

Before timing, every implementation must pass all 4,146 upstream Decimal
fixtures, two committed item changes (including a nonconsecutive item slot),
and three invalid/missing-ID status cases. The conformance runner also requires
actual GPU launches. All six passed these gates on 2026-10-22. CPU variants also
passed a short k6 smoke run; smoke timings are not published. Standard
performance results are pending because all four GPUs were occupied by other
compute processes. The published page shows unmeasured values, preserving the
old measurements in a separate supplemental section.

## Reproduce

The existing [HTTP build](../http/README.md) prepares the upstream fixtures,
checker and pinned CUDA artifacts. This comparison adds stable Rust, FastAPI
and Fastify builds:

```sh
GO_BIN=/var/tmp/go/bin/go bash performance/django-cart/http/build.sh
GO_BIN=/var/tmp/go/bin/go bash performance/django-cart/comparison/build.sh
python3 performance/django-cart/comparison/run.py --conformance-only
python3 performance/django-cart/comparison/run.py
python3 performance/django-cart/comparison/summarize.py \
  performance/django-cart/comparison/results/2026-10-22
python3 performance/site.py
```

The runner refuses timed GPU runs when external compute processes already use
the selected GPU. It does not stop those processes. Use `--gpu-device` to select
an idle device. Conformance remains available under contention because it
publishes no performance scores. The date directory defaults to the UTC run
date; update `performance/site.py` to select a later dated result directory.

`--help` exposes artifact paths, CPU affinity and smoke-run options. The
summarizer refuses shortened runs, missing implementations, failed correctness
gates, invalid/duplicate points, request errors and incomplete grids. A complete
run has 144 points and produces the same summary.csv fields and Markdown
metric columns as the other applications. Only summary CSV/JSON/Markdown is
eligible for tracking. Raw k6 output, points, logs, metadata and conformance
evidence remain local under the existing ignore policy.

The historical [request batching](../http/README.md),
[line scaling](../http/lines/README.md), snapshot and resident experiments retain
their original names, conditions and results. They supply no framework scores.
