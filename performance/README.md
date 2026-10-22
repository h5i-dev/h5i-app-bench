# Web performance benchmark

Real REST APIs written in Rust on [h5i-app](https://github.com/h5i-dev/h5i)
and in Go, TypeScript and Python, on the same PostgreSQL data. Every
implementation passes the same conformance suite before it is measured.
Results: <https://benchmark.h5i.dev/performance/>.

| Directory | API | Implementations |
| --- | --- | --- |
| [`realworld/`](realworld) | [RealWorld (Conduit)](https://github.com/realworld-apps/realworld): users, articles, comments, follows, favorites | `rust-h5i`, `rust-h5i-optimized`, `go`, `fastify`, `fastapi` |
| [`linkding/`](linkding) | [linkding](https://github.com/sissbruecker/linkding) 1.47.0 bookmarks API | `rust-h5i`, `go`, `fastify`, `fastapi`, and the upstream image |
| [`django-cart/`](django-cart) | Read-only cart totals adapters for pinned django-cart pricing | `rust-h5i`, `rust-h5i-optimized`, `rust-h5i-gpu`, `fastapi`, `go`, `fastify` (standard comparison awaits measurement) |

`rust-h5i` runs every request through the h5i-app engine (`h5i-app-pg`).
In RealWorld and linkding, the read plan and frame theorem have Lean proofs;
their optimized adapters use hand-written SQL with proved application kernels.
The django-cart adapters currently have differential checks rather than
application-specific Lean proofs, as detailed below.

RealWorld and linkding have their own README with the contract, the database, the Hurl
suite and the run commands. `bench/README.md` there has the load shape, and
`bench/results/` the summaries (`summary.md`, `summary.csv`, `points.csv`).
Raw k6 JSON is not committed.

[`django-cart/`](django-cart) uses the same six-column framework comparison as
RealWorld and linkding. Its [standard runner](django-cart/comparison/README.md)
checks all six implementations against pinned `bmentges/django-cart` 3.1.1 and
measures one cart total per HTTP request, fresh PostgreSQL reads, 10 s warmup,
30 s measurement and three repetitions at 1/16/64/256 clients. Cart pricing has
differential checks, no application-specific Lean proof. Standard results are
currently unmeasured; the page shows dashes until a complete run is available.

The existing [HTTP batching](django-cart/http/README.md) and
[line scaling](django-cart/http/lines/README.md) results retain their original
implementation names in the dashboard's supplemental experiments. Snapshot,
[resident updates](django-cart/resident/README.md), and
[larger batches](django-cart/resident/scale/README.md) remain separate calculation
experiments. They do not populate the framework comparison.

Engine-stage attribution experiments, with unchanged kernels and proof sources,
live in [`engine-profile/`](engine-profile). These diagnostic runs are separate
from the published cross-framework performance ranking.

After a benchmark's `summarize.py` has rewritten its `summary.csv`, refresh the
site's data:

```sh
python3 performance/site.py          # writes docs/performance/data.json
```

The overview defaults to 16 clients so Conduit's GPU results and Linkding's
`search_complex` results are visible. It omits the upstream and resident CPU-scan
columns; the application details retain both. The generator also loads the
targeted summaries listed in `site.py`, with their separate conditions noted
on the page. See [the complex-search comparison](linkding/bench/complex-languages-2026-10-19.md)
for the additional Go, FastAPI and Fastify measurements, and the
[h5i engine run](linkding/bench/complex-engine-2026-10-19.md).

Configured supplemental summaries replace earlier rows with the same
implementation, scenario and concurrency. Both the overview and details use
these selected rows. The details link each measurement date to its source CSV;
the application heading shows the date range across the selected runs.

The overview always uses the same implementation columns, in this order:
`rust-h5i`, `rust-h5i-optimized`, `rust-h5i-gpu`, `fastapi`, `go`, `fastify`.
Missing measurements appear as dashes. Supplemental execution-strategy results
are loaded separately and never renamed or used to fill these columns.
