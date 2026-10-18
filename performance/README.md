# Web performance benchmark

Real REST APIs written in Rust on [h5i-app](https://github.com/h5i-dev/h5i)
and in Go, TypeScript and Python, on the same PostgreSQL data. Every
implementation passes the same conformance suite before it is measured.
Results: <https://benchmark.h5i.dev/performance/>.

| Directory | API | Implementations |
| --- | --- | --- |
| [`realworld/`](realworld) | [RealWorld (Conduit)](https://github.com/realworld-apps/realworld): users, articles, comments, follows, favorites | `rust-h5i`, `rust-h5i-optimized`, `go`, `fastify`, `fastapi` |
| [`linkding/`](linkding) | [linkding](https://github.com/sissbruecker/linkding) 1.47.0 bookmarks API | `rust-h5i`, `go`, `fastify`, `fastapi`, and the upstream image |

`rust-h5i` runs every request through the h5i-app engine (`h5i-app-pg`), whose
read plan and frame theorem are proved. `rust-h5i-optimized` keeps its decisions
in an h5i-app kernel with Lean proofs but does its own hand-written SQL.

Each directory has its own README with the contract, the database, the Hurl
suite and the run commands. `bench/README.md` there has the load shape, and
`bench/results/` the summaries (`summary.md`, `summary.csv`, `points.csv`).
Raw k6 JSON is not committed.

Engine-stage attribution experiments, with unchanged kernels and proof sources,
live in [`engine-profile/`](engine-profile). These diagnostic runs are separate
from the published cross-framework performance ranking.

After a benchmark's `summarize.py` has rewritten its `summary.csv`, refresh the
site's data:

```sh
python3 performance/site.py          # writes docs/performance/data.json
```
