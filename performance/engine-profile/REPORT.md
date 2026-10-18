# Engine cost: Linkding and Conduit

Measured 2026-10-18. This is an HTTP end-to-end profiling experiment, not a
kernel microbenchmark or a new Go/Rust/GPU ranking. The normal applications use
their original h5i pin, `3fcbcdafdfdd759bfa52c765ce8dd2f73c88a26e`; the benchmark
base is `671bf10`. Latest h5i main was not substituted for that pin.

## Decision

Both shared engine work and application-specific work deserve investigation.
The dominant cause changes with the endpoint. Start with the application read
plan for Linkding text search; examine transaction round trips for light reads;
examine application counter contention and engine connection admission for
writes. Do not replace the proved execution path with hand-written optimized
SQL or weaken transaction isolation to get a better score.

`engine` time includes the application's database reads and waits. It is not a
measurement of generic framework CPU overhead. Likewise, a pool wait is queueing
behind limited capacity, not automatically a reason to increase the pool size.

All 60 profile points completed and matched their counter deltas: 1,278,942 HTTP requests. Each of the 20 scenario/concurrency groups has three repetitions. Only Conduit favorite at concurrency 64 has measured HTTP failures (611 requests); see the failure discussion below.

Representative per-request means, in milliseconds. `load` includes nested conversion; columns are not all exclusive CPU costs.

| Application / endpoint | Concurrency | HTTP | Pool wait | Lock wait | Load | Kernel |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Linkding get | 1 | 1.958 | 0.002 | 0.000 | 1.124 | 0.003 |
| Linkding search | 1 | 1,026.339 | 0.005 | 0.000 | 965.295 | 41.621 |
| Linkding search | 64 | 13,539.468 | 5,619.437 | 0.000 | 7,804.950 | 50.089 |
| Linkding create | 64 | 1,999.451 | 966.191 | 1,000.007 | 28.592 | 0.007 |
| Conduit slug | 1 | 1.536 | 0.002 | 0.000 | 0.743 | 0.002 |
| Conduit list | 64 | 60.530 | 29.978 | 0.000 | 18.022 | 0.145 |
| Conduit create | 64 | 261.752 | 130.012 | 127.596 | 0.746 | 0.004 |
| Conduit favorite | 64 | 15.233 | 7.446 | 2.969 | 1.062 | 0.002 |

For light reads, BEGIN + COMMIT averages 0.788 ms of 1.958 ms for Linkding get, and 0.748 ms of 1.536 ms for Conduit slug. SQL construction averages 0.079/0.059 ms; generic row decoding 0.005/0.004 ms. Those fixed boundaries deserve investigation before rewriting these kernels.

Linkding text search converts **287,002 rows per request**. At concurrency 1, its load phase averages 965 ms, including 84.6 ms of generic row conversion and 20.0 ms of snapshot decoding; the kernel is 41.6 ms. Reducing the candidate snapshot is the largest application-specific opportunity. At concurrency 64, queueing adds substantial latency.

At concurrency 64, pool + advisory-lock waits account for about **98%** of the observed Linkding create mean and **98%** of Conduit create. These waits explain latency under contention; moving the wait or increasing the pool does not eliminate the serialized critical section.

Full summaries: [profile-summary.csv](results/2026-10-18/profile-summary.csv), [per-repetition points](results/2026-10-18/profile-points.csv), and [control points](results/2026-10-18/control-points.csv).

## What to investigate next

1. **Application query plans and indexes first for Linkding search.** Ordinary
   free-text search falls back to `Pred::All` within the selected owner/scope;
   the kernel filters that snapshot. A conservative SQL prefilter could reduce
   the snapshot, but it must have no false negatives under the existing ASCII
   search semantics. Pagination, counts, ownership, tag/bundle relations and
   supported query syntax must remain correct. Changing that read plan requires
   extraction and rechecking the affected sufficiency, frame and count proofs.
   SQL `ILIKE` alone must not be assumed equivalent to the kernel predicate.
2. **Shared engine for light read-only requests.** Measure ways to reduce wire
   round trips and repeated plan/SQL construction while retaining the same
   `SERIALIZABLE READ ONLY DEFERRABLE` transaction and snapshot semantics. The
   engine already pipelines table reads and caches prepared statements; these
   are not missing features. Generic row conversion is a nested measured cost,
   not a justification for changing application decisions.
3. **Write contention spans app and engine.** Both applications serialize creates
   on an application counter key. Connection acquisition precedes advisory-lock
   acquisition, so blocked writers occupy scarce pool connections. Investigate
   the query plans/indexes used inside the critical section as well: Linkding
   create spends about 29 ms loading only a few rows at concurrency 64. A small
   result set does not imply a cheap database query. Reducing this critical
   section could help throughput without removing the counter lock. Also study
   admission before occupying a connection, retaining the database lock for
   cross-process correctness. This alone cannot increase throughput through the
   same serialized counter. A different ID allocation strategy changes application
   logic and storage assumptions and needs corresponding reproof.
4. **Resolve Conduit favorite resource failures before ranking its speed.** The
   instrumented database log reports `out of shared memory` with a hint to
   increase `max_pred_locks_per_transaction`. Unmodified binaries also fail the
   same workload. Retain `SERIALIZABLE`; separately test predicate-lock capacity
   and query plans. The current experiment does not change database settings or
   establish that configuration alone fixes every error.

For the optimized and GPU variants, a separate profile is needed: their HTTP/SQL
shell differs from this engine path. These measurements do not establish which
optimization would beat Go, or by how much.

## Method and limits

Host: AMD EPYC 7502, two sockets, 128 logical CPUs. Each server, PostgreSQL and k6
gets its own four logical CPUs; Tokio has four workers and the pool has 32
connections. Release builds use rustc 1.98.1; k6 is v2.3.0.
PostgreSQL 16 uses the existing harness settings (`max_connections=200`,
`shared_buffers=512MB`, default predicate-lock limits). Linkding profiling
uses CPU groups 0–3 / 4–7 / 8–11; Conduit uses 12–15 / 16–19 / 20–23.
Applications seed and restart through the existing harness for each point.
Five scenarios per application, concurrency 1/64, three repetitions, 5 s warmup
and a 15 s arrival window. Linkding's local workload copy allows 120 s for slow
in-flight requests to drain. Reported RPS uses k6's actual elapsed measurement,
including drain, not a fixed 15 s divisor.

Times are mean wall time per completed request, then averaged across repetitions.
They include scheduling/queueing; these are not CPU samples. SQL query futures
are pipelined: their summed lifetimes overlap and must not be added to the
parent load time. Load combines database execution, protocol/network, scheduling
and conversion. No database CPU versus I/O attribution is claimed.

Before/after snapshots are taken with warmup and measurement requests drained.
The summarizer checks that HTTP counter deltas, engine invocations and k6
request counts agree exactly. Conduit favorite failures stopped the initial
strict run; its favorite/mixed scenarios were resumed with failures retained.
Later captures replace the repeated initial favorite points, not count them twice.

Control binaries were built from the original locked dependencies, without probes.
Controls used the same per-app CPU allocation for pristine/instrumented pairs.
An initial sequential control and two alternating batches were retained in
`control-points.csv`; the final batch used pristine/on/on/pristine/pristine/on
order, 3 s warmup and 10 s measure at concurrency 64.

| Final control | Pristine RPS, mean ± SD | Probed RPS, mean ± SD | Observed difference |
| --- | ---: | ---: | ---: |
| Linkding get | 3,870 ± 14 | 3,814 ± 88 | −1.5% |
| Conduit slug | 12,970 ± 640 | 13,629 ± 44 | +5.1% |

These are not proof of zero instrumentation overhead or an overhead bound.
Earlier controls showed substantially different throughput, and a positive
instrumented difference indicates environmental/order variation. Runs share a
host even though their CPU sets and database instances are disjoint; CPU pinning
does not isolate memory, storage or scheduler effects. Treat small timing
percentages cautiously. The experiment supports prioritizing large bottlenecks,
not claiming a small speedup. Future changes need pristine before/after runs
with the same workload and guarantee scope.

Conduit favorite also failed without probes: **455 / 195,232 requests** across
three concurrency-64 repetitions. Its error rates are evidence to investigate,
not a passing benchmark score.

## Safety and validation

No kernel, extracted read/count plan, extraction configuration, generated Lean,
handwritten theorem, SQL, lock or transaction isolation was changed. Timing
probes and a benchmark-only counter endpoint were added in disposable worktrees;
application path patches are not part of the final benchmark source changes.

The instrumented binaries passed the existing HTTP conformance suites:
Linkding 9 files / 200 requests, Conduit 13 files / 154 requests. Release kernel
tests passed: Linkding 4 tests, Conduit 2 tests. Python probe/aggregation scripts
compile, and the diff passes whitespace validation.

The Lean sources are unchanged; this experiment did not rerun Lean or prove
new instrumentation. Existing proofs cover the claims gated by each application's
`h5i-app.toml`, not all runtime/database behavior. Future logic changes require
re-extraction and reproof; engine/store/compiler changes also need their trusted
refinement and concurrency assumptions reviewed. HTTP regression tests alone
cannot preserve a formal guarantee after such a change.

Only aggregate CSVs and this report are retained in git. Raw JSON, counter
captures, server/database logs and build artifacts stay outside the repository.
See [README](README.md) for reproduction and counter definitions.
