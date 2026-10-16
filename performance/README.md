# Web performance benchmark

Real REST APIs written in Rust on [h5i-app](https://github.com/h5i-dev/h5i)
and in Go, TypeScript and Python, on the same PostgreSQL data. Every
implementation passes the same conformance suite before it is measured.
Results: <https://benchmark.h5i.dev/performance/>.

| Directory | API | Implementations |
| --- | --- | --- |
| [`realworld/`](realworld) | [RealWorld (Conduit)](https://github.com/realworld-apps/realworld): users, articles, comments, follows, favorites | `rust-h5i`, `rust-h5i-optimized`, `go`, `fastify`, `fastapi` |
| [`linkding/`](linkding) | [linkding](https://github.com/sissbruecker/linkding) 1.47.0 bookmarks API | `rust-h5i-optimized`, `go`, `fastify`, `fastapi`, and the upstream image |

Two Rust implementations use h5i-app:

- `rust-h5i` is a standard h5i-app application. Every request runs in the
  h5i-app engine (`h5i-app-pg`): it loads the rows the kernel's read plan
  names, calls the kernel, and stores the writes the kernel plans. The
  kernel, the read plan's sufficiency and the writes are proved in Lean.
- `rust-h5i-optimized` keeps the same kind of kernel with Lean proofs, but
  the server issues its own SQL through sqlx. The queries are tuned by hand
  and are not covered by the proofs.

The upstream linkding image is measured as a reference. The site does not
show it.

Each directory has its own README with the contract, the database, the Hurl
suite and the run commands. `bench/README.md` there has the load shape, and
`bench/results/` the summaries (`summary.md`, `summary.csv`, `points.csv`).
Raw k6 JSON is not committed.

After a benchmark's `summarize.py` has rewritten its `summary.csv`, refresh the
site's data:

```sh
python3 performance/site.py          # writes docs/performance/data.json
```
