# Engine cost: Linkding and Conduit

Remeasured 2026-10-18 with PostgreSQL data, raw captures, logs, temporary files,
binaries and experiment worktrees on **`/dev/shm` (tmpfs)**. This supersedes the
`/var/tmp` measurements published in `253a07a`. The old experiment's temporary
artifacts and approximately 13 GiB of database data were removed from `/var/tmp`.
This is an HTTP end-to-end profile, not a kernel microbenchmark or a Go/Rust/GPU ranking.

The normal applications retain h5i `3fcbcdafdfdd759bfa52c765ce8dd2f73c88a26e`
and application benchmark base `671bf10`. The same release binaries were copied
without rebuilding; latest h5i main was not substituted. The profiling runner is
based on `253a07a`, with the storage changes accompanying this report.

## Decision

Both engine and application work deserve investigation, depending on the endpoint.
Start with Linkding search's application read plan; examine transaction round trips
for light reads; examine application counter contention and engine admission for
writes. Do not weaken isolation or bypass proved logic for a faster score.

`engine` includes application database reads and waits; it is not generic framework
CPU overhead. Pool wait measures queueing behind capacity, not proof that a larger
pool improves throughput.

All **60 profile points** completed with matching HTTP, engine and k6 counters:
**1,308,812 requests**. Each of 20 scenario/concurrency groups has three repetitions.
There were **510 failed HTTP requests**, all in Conduit favorite at concurrency
64; the per-point summaries retain errors.

Representative per-request mean wall times, in milliseconds. Load includes nested
conversion, and these columns are not all exclusive CPU costs.

| Application / endpoint | Concurrency | HTTP | Pool wait | Lock wait | Load | Kernel |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Linkding get | 1 | 2.336 | 0.002 | 0.000 | 1.267 | 0.003 |
| Linkding search | 1 | 962.695 | 0.007 | 0.000 | 900.590 | 40.980 |
| Linkding search | 64 | 13,303.812 | 5,491.696 | 0.000 | 7,691.850 | 50.927 |
| Linkding create | 64 | 2,061.473 | 995.587 | 1,031.601 | 29.893 | 0.007 |
| Conduit slug | 1 | 1.645 | 0.002 | 0.000 | 0.797 | 0.002 |
| Conduit list | 64 | 61.888 | 30.650 | 0.000 | 18.608 | 0.151 |
| Conduit create | 64 | 235.068 | 116.872 | 114.481 | 0.702 | 0.004 |
| Conduit favorite | 64 | 12.322 | 6.017 | 2.376 | 0.884 | 0.002 |

For light reads, BEGIN + COMMIT averages
1.022 ms
of 2.336 ms for Linkding get, and
0.801 ms
of 1.645 ms for Conduit slug.
SQL construction averages 0.079/0.060 ms;
generic row decoding 0.005/0.004 ms.
These fixed boundaries deserve investigation before rewriting these kernels.

Linkding search converts **287,002 rows/request**.
At concurrency 1, load averages 900.590 ms, including
85.913 ms of generic row conversion and
17.714 ms of snapshot decoding;
kernel evaluation averages 40.980 ms.
Reducing the candidate snapshot remains the principal application opportunity.

At concurrency 64, pool + advisory-lock waits account for
98.3%
of Linkding create and
98.4%
of Conduit create. Moving the wait or increasing pool capacity does not remove
the serialized critical section.

Full summaries: [profile-summary.csv](results/2026-10-18/profile-summary.csv),
[per-repetition points](results/2026-10-18/profile-points.csv),
[control points](results/2026-10-18/control-points.csv), and
[storage/run summary](results/2026-10-18/storage-summary.csv).

## What to investigate next

1. **Application read plans/indexes for Linkding search.** Free-text search falls
   back to `Pred::All` within the owner/scope; the kernel filters that snapshot.
   A conservative SQL prefilter must have no false negatives under the existing
   ASCII semantics. Preserve pagination, counts, ownership, relations and query
   syntax. Changing the read plan requires extraction and rechecking sufficiency,
   frame and count proofs. Do not assume SQL `ILIKE` equals the kernel predicate.
2. **Shared engine for light reads.** Investigate fewer wire round trips and less
   repeated plan/SQL construction while preserving `SERIALIZABLE READ ONLY
   DEFERRABLE` snapshot semantics. Table reads are already pipelined and prepared
   statements cached. Generic row conversion is a nested measured cost.
3. **Write contention across app and engine.** Creates serialize on an application
   counter key. Pool acquisition precedes advisory-lock acquisition, occupying
   connections while blocked. Investigate admission and the SQL/indexes inside
   the critical section, retaining database locks for cross-process correctness.
   Different ID allocation changes application logic/storage assumptions and
   requires corresponding reproof.
4. **Conduit favorite predicate-lock capacity.** A pristine binary also fails
   on tmpfs: **461 / 218,849 requests** across three concurrency-64
   repetitions. Its PostgreSQL log records 461 `out of shared memory`
   errors with `max_pred_locks_per_transaction` hints. Changing the host data
   directory did not resolve that limit. Retain `SERIALIZABLE` and separately
   investigate capacity and query plans; no configuration fix is claimed here.

Optimized/GPU variants need separate attribution; their HTTP/SQL shell differs.
This experiment does not establish an optimization that beats Go.

## Method and limits

Host: AMD EPYC 7502, two sockets, 128 logical CPUs. Each server, PostgreSQL and k6
gets four logical CPUs; Tokio has four workers and the pool has 32 connections.
Release binaries use rustc 1.98.1; k6 is v2.3.0. PostgreSQL 16 retains
`max_connections=200`, `shared_buffers=512MB` and default predicate-lock limits.
Linkding uses CPUs 0–3 / 4–7 / 8–11; Conduit 12–15 / 16–19 / 20–23.

Five scenarios/app, concurrency 1/64, three repetitions, 5 s warmup and 15 s
arrival window. Each point reseeds and restarts through the existing HTTP harness.
Linkding's local workload copy allows a 120 s graceful drain; RPS uses actual k6
elapsed time including drain. Failed points are retained, not hidden or counted
as passing. Quiescent before/after counter deltas must match completed requests.

DB bind mounts were verified to originate in `/dev/shm`; output mount types and
free bytes before/after each run are recorded locally and summarized in git.
The minimum of these recorded free-space samples was **84.2 GiB**.
The runner defaults DB/temp/cache paths to `/dev/shm`, checks for 4 GiB free
before starting, and does not fall back to `/var/tmp`. PostgreSQL settings were
unchanged. This removes the `/var` capacity dependency for experiment data;
it is not a controlled measurement of a tmpfs-versus-disk speedup.

Wall times include scheduling and queueing. Pipelined SQL futures overlap;
do not add their summed lifetimes to load. Load combines DB execution,
protocol/network, scheduling and conversion; DB CPU versus I/O is not isolated.

Pristine/probed controls use identical CPU allocations within each app:
24–27 / 28–31 / 32–35 for Linkding, 48–51 / 52–55 / 56–59 for Conduit.
Order: pristine/on/on/pristine/pristine/on; 3 s warmup, 10 s measurement,
concurrency 64, one point per run, three runs per mode.

| Control | Pristine RPS, mean ± SD | Probed RPS, mean ± SD | Observed difference |
| --- | ---: | ---: | ---: |
| Linkding get | 3,809 ± 50 | 3,670 ± 230 | -3.7% |
| Conduit slug | 10,070 ± 2,981 | 11,905 ± 1,467 | +18.2% |

These noisy controls do **not** establish zero overhead, a stable overhead bound,
or a speedup from probes. Positive differences and large variation are consistent with
host/order effects and prevent attributing these differences to probes. CPU pinning does not isolate memory or scheduling; profiles
and controls share a host. Use these results to prioritize large bottlenecks,
not small percentage improvements. Future changes need pristine before/after
measurements with identical workloads and guarantee scope.

## Safety and validation

No kernel, extracted read/count plan, extraction configuration, generated Lean,
handwritten theorem, SQL, lock or isolation level changed. This storage rerun
uses the same binaries previously validated by HTTP conformance (Linkding
9 files / 200 requests; Conduit 13 files / 154 requests) and release kernel tests
(Linkding 4, Conduit 2). Counter/request agreement is checked for all new points.

Lean was not rerun; no new proof is claimed for timing instrumentation. Existing
proofs cover each application's `h5i-app.toml` claims, not the entire HTTP/DB stack.
Future logic changes require extraction and reproof; engine/store/compiler
changes also require reviewing refinement and concurrency assumptions.

Only summary CSVs and documentation are committed. Raw JSON, counters and logs
remain in `/dev/shm`. See [README](README.md) for reproduction and stage definitions.
