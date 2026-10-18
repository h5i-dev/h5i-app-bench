# HTTP engine cost measurements

Results and optimization priorities: [2026-10-18 report](REPORT.md).

This experiment measures the normal `rust-h5i` Linkding and Conduit applications
through their existing HTTP workloads. It separates engine stages before choosing
an optimization. It does not change application decisions, SQL, transaction
isolation, locks, read plans, kernels, or proofs. GPU and optimized implementations
are not part of this attribution experiment.

The measured benchmark revision is `671bf10` (including the Linkding text-search
and Conduit GPU benchmark additions). Both normal applications pin h5i
`3fcbcdafdfdd759bfa52c765ce8dd2f73c88a26e` in their original Cargo locks. The
measurements describe that pinned engine, **not a rebuilt latest h5i main**.
Later engine changes must be measured separately before transferring numbers.

Only summary CSVs and the report belong in git. Raw logs, k6 JSON, counter
captures, copied harnesses and database files stay under `/dev/shm`.

## Reproduce

Use disposable worktrees for both repositories; the probe generator modifies
source files and Cargo patches in those worktrees. Install the prerequisites of
the existing performance harness, including k6, Docker, curl, taskset, findmnt and Python
with PyJWT (Conduit). See each application's README for build prerequisites.

```sh
git -C /path/to/h5i worktree add --detach /dev/shm/h5i-probe 3fcbcdafdfdd759bfa52c765ce8dd2f73c88a26e
git -C /path/to/h5i-app-bench worktree add --detach /dev/shm/bench-probe HEAD
cd /dev/shm/bench-probe
python3 performance/engine-profile/instrument.py /dev/shm/h5i-probe /dev/shm/bench-probe
cargo build --release --manifest-path performance/linkding/rust-h5i/Cargo.toml -p linkding-server
cargo build --release --manifest-path performance/realworld/rust-h5i/Cargo.toml -p conduit-server
```

The local path patches require a Cargo lock refresh; keep all non-h5i dependency
versions unchanged and inspect the lock diff. Build pristine control binaries
from another unmodified worktree with `--locked`, copying them to distinct paths
before rebuilding the instrumented versions.

```sh
python3 performance/engine-profile/run.py --app linkding \
  --binary /absolute/path/to/instrumented-linkding-server \
  --out /dev/shm/linkding-profile --scenarios 'get list search create mixed'
python3 performance/engine-profile/run.py --app realworld \
  --binary /absolute/path/to/instrumented-conduit-server \
  --out /dev/shm/conduit-profile --scenarios 'slug list create favorite mixed' \
  --python /path/to/python-with-pyjwt
python3 performance/engine-profile/summarize.py \
  /dev/shm/linkding-profile /dev/shm/conduit-profile \
  --out performance/engine-profile/results/2026-10-18
```

Defaults: concurrency 1 and 64, three repetitions, 5 s warmup and 15 s measurement,
four server CPUs, four PostgreSQL CPUs, four load-generator CPUs, four Tokio
workers, and a 32-connection pool. Change `--cpu-base`, `--pg-port` and
`--http-port` to use disjoint resources for concurrent experiments. Each run
creates and removes its own PostgreSQL container; raw output and DB files are
retained locally. Database and temporary files default to
`--scratch-root /dev/shm/h5i-engine-profile`, with a 4 GiB free-space preflight
and no disk fallback. Use `/dev/shm` for `--out` and binaries as well. Each
run records filesystem type and free bytes before/after in its local `run.json`.
Linkding gets a 120 s graceful drain in a **local copy** of the
workload to count all slow in-flight searches. The 15 s arrival window is unchanged.
Run `--mode pristine` against an unmodified binary for controls. `--mode off`
disables counters in an instrumented binary, which alone is not a pristine control.
The runner snapshots the h5i-app seed into the local output directory and records
its SHA-256. Use `--engine-seed-sql /absolute/path/to/seed.sql` to compare seed
initialization while keeping the application binary and workload identical.
`--keep-going` retains failed points and continues instead of stopping at the
first k6 threshold failure. It does not suppress errors in the output. For a
resumed run, pass `--replace-duplicates` to the profile summarizer: later inputs
replace identical app/scenario/concurrency/repetition points. Control runs can
be summarized with `summarize-controls.py RUN... --out control-points.csv`.

## What the counters mean

The timing endpoint is benchmark-only and must not be deployed publicly.
Counters are captured after warmup has drained and after measurement has drained.
The summarizer requires completed HTTP requests, engine invocations and k6
requests to agree exactly. It records all repetitions, request counts, RPS,
p99 latency, errors, retries and mean stage wall time per completed HTTP request.
Summary stage times are the arithmetic mean of repetition means.

- `http`: server middleware through response construction, excluding network
  transit and body transmission. k6 latency includes the client-visible path.
- `engine`: the whole engine call, including pool waits, retries and transactions.
- `pool`, `lock`, `unlock`, `begin`, `clock`, `load`, `kernel`, `write`, `commit`,
  `rollback`, `backoff`: aggregate wall time in the named stage. `load` includes
  database execution, network/protocol, scheduling and row/snapshot conversion.
- `sql_compile`, `sql_prepare`, `sql_query`, `pg_decode`, `snapshot_decode`:
  nested diagnostics inside loading/writing. `read_plan` measures application
  read-plan construction. Rows count the physical rows converted to generic
  values, including relationship rows, not only returned entities.

Parent and child timers are inclusive. **Do not add all columns.** In particular,
pipelined SQL futures overlap; `sql_query` is the sum of their lifetimes and can
exceed `load`. These are wall-time observations, not exclusive CPU samples.
The experiment does not isolate PostgreSQL compute, I/O and network costs within
`load`, or establish a speedup against Go. Machine noise and probe overhead must
be considered when interpreting small differences.

## Preserving existing guarantees

The original normal applications extract the transition, read-only predicate,
read plans and count plans. Their theorem gates include storage invariants,
read-plan sufficiency and frame properties; Linkding additionally gates ownership
and guest/token properties. See their `rust-h5i/h5i-app.toml` files for the exact
claims. This is not a proof of the complete HTTP/database/runtime stack.

The probes live outside extracted logic. Existing kernels, extraction
configuration, generated Lean and handwritten proofs are unchanged; no new
correctness theorem is claimed for timing instrumentation. Existing kernel tests
and HTTP conformance suites validate the instrumented binaries as a regression
check, not as a substitute for proof.

A later optimization must preserve that scope. A narrower application read plan
needs the corresponding sufficiency/frame/count proofs checked again. A changed
transition needs extraction and reproof of affected theorems. A SQL compiler,
store, lock or isolation change also needs its database/refinement assumptions
reviewed; retaining an unchanged kernel proof alone cannot establish its safety.
Do not disable isolation or locking to manufacture a performance gain.
