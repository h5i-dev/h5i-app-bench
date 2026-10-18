# Linkding search: execution plans and seed statistics

This follows the [HTTP engine profile](../../engine-profile/REPORT.md). It
investigates database work before changing the application's extracted read
plans. It uses the existing Linkding HTTP workload, not a kernel microbenchmark.

## What the queries do

For `GET /api/bookmarks/?q=alpha&limit=20`, the normal `rust-h5i` read plan loads
the caller's entire unarchived scope. SQL does not receive the search term:
`simple_query` accepts tag/keyword queries, and `list_reads` uses the whole scope
for other searches. The kernel then searches and pages the loaded bookmarks.
On the benchmark seed this converts 287,002 physical rows per request: 95,000
bookmarks, 190,000 bookmark/tag links, 2,000 tags, a user and a token. The response
contains 20 bookmarks and a total count of 1,000.

The captured SQL explicitly orders the returned rows by their schema keys.
The two relationship queries also repeat the bookmark-scope selection in nested
`IN` subqueries. An additional `(tenant_id, owner, archived, added, id)` bookmark
index did not improve the diagnostic search or list-count plans and is **not shipped**.

## Initialization correction

The shared `seed.sql` ends with a database-wide `ANALYZE`, but it runs **before**
`seed_h5i_app.sql` copies the data into the engine's tables. Unlike Conduit's
engine seed, Linkding's engine seed did not analyze its newly loaded tables.
`TRUNCATE` resets the engine tables' relation cardinality estimates. During a
baseline point, `pg_class` reported `reltuples = -1` and `relpages = 0` for both
bookmarks and links despite their newly populated data. An earlier `ANALYZE`
of the previous dataset therefore does not establish the current estimates;
autoanalyze timing can also affect results.

The correction explicitly analyzes the eight seeded engine tables after
commit, outside warmup and measurement. It applies to the normal `rust-h5i`
implementation; the SQL-based optimized/GPU variants use the already-analyzed
shared tables. This fixes initialization consistency. It is not a general
application search optimization.

A diagnostic on a retained dataset illustrates the risk: one relationship join
estimated 199 rows but returned 189,992, selecting 94,996 index probes. After
`ANALYZE`, that query used a hash join and aggregation. These were diagnostic
`EXPLAIN ANALYZE` executions on a previously used dataset, not throughput
comparisons; full plans and database files remain local.

## PostgreSQL container capacity

The first post-`ANALYZE` attempt used Docker's default 64 MiB container shared
memory. Its concurrency-64 search warmup failed 41 of 96 HTTP requests:
PostgreSQL's parallel-query dynamic shared memory reported `No space left on
device`. The host `/dev/shm` still had over 80 GiB available. The strict harness
stopped before measurement; the failed warmup is retained in
[`initial-failure.csv`](results/search-plan-2026-10-18/initial-failure.csv).

New Linkding PostgreSQL containers now use `--shm-size 1g`, configurable with
`LINKDING_PG_SHM_SIZE`. This shared setting applies to all Linkding
implementations. It changes capacity, not transaction semantics. Existing
containers are not automatically recreated. Both variants in the final
comparison are rerun in fresh containers with the same **1 GiB** setting;
the initial 64 MiB runs are excluded from that comparison. The profiler records
the actual container capacity in `run.json`.

## Measurement and guarantees

Both variants use the **same instrumented release binary**, with the existing
engine-profile counters outside extracted logic. The h5i pin remains
`3fcbcdafdfdd759bfa52c765ce8dd2f73c88a26e`. The benchmark baseline is `723d88e`;
the only application-initialization change is the post-seed `ANALYZE`.
The transition, read plan, count plan, SQL compiler, isolation and locks are
unchanged. No extracted Rust, generated Lean, handwritten proofs or theorem
gates change, and no new formal guarantee is claimed. Re-extraction/reproof is
not required for a statistics refresh.

The controlled comparison uses search, get and list, concurrency 1 and 64,
three repetitions, 5 s warmup and a 15 s arrival window. Each point reseeds and
restarts the application. Slow searches are fully drained with the profiling
harness's 120 s grace period; reported throughput includes drain time. Four
server CPUs, four PostgreSQL CPUs and four client CPUs are disjoint; Tokio has
four workers and the connection pool has 32 connections. PostgreSQL 16 uses
512 MB shared buffers. CPU affinity is identical across variants. The host is
shared and clocks/NUMA placement are not controlled.

Database files, binaries, temporary files and raw captures are on `/dev/shm`.
Only summary CSVs and this report are published. Existing published CPU/GPU and
cross-language tables are not replaced by this shorter attribution experiment.
Timing probes add overhead, and the before and after blocks run sequentially on
a shared host. This establishes neither an uninstrumented speedup nor a Go
comparison. Writes and mixed traffic are not remeasured here.

## HTTP results

Mean of three repetitions per point; RPS is completed HTTP requests per second.
These are end-to-end requests with timing probes enabled, including database
loading, the kernel, pagination and response serialization.

| Scenario | Clients | Before RPS | After RPS | After / before | Before p99 ms | After p99 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| get | 1 | 480.12 | 462.90 | 0.96× | 2.12 | 2.14 |
| get | 64 | 11407.44 | 11503.83 | 1.01× | 9.07 | 9.13 |
| list | 1 | 31.72 | 21.60 | 0.68× | 38.64 | 71.26 |
| list | 64 | 136.91 | 120.64 | 0.88× | 1392.85 | 721.51 |
| search | 1 | 0.97 | 1.87 | 1.93× | 1106.92 | 562.41 |
| search | 64 | 4.13 | 7.54 | 1.83× | 16575.97 | 9626.76 |

All 36 measured points passed, totaling 1,088,988 HTTP requests with zero failed
requests. See [run metadata](results/search-plan-2026-10-18/runs.csv),
[comparison](results/search-plan-2026-10-18/comparison.csv) and the before/after
profile summaries in that directory. Only summaries are committed.

Search throughput increases 1.93× at one client and 1.83× at 64 clients.
Single-client mean HTTP time drops from 1,031 to 535 ms. Mean database-load time
drops from 971 to 478 ms while loaded rows remain 287,002. This supports a
query-planning explanation, rather than a faster kernel or fewer loaded rows.

**This is not a uniform improvement.** Get throughput stays close to baseline,
but list throughput falls to 0.68× at one client and 0.88× at 64 clients. List
results also vary substantially across the after repetitions (RPS standard
deviation 7.77 and 32.69 respectively). Different randomly selected offsets mean
list row counts differ slightly between runs. The seed correction is retained
for consistent initialized statistics, not presented as an all-endpoint speedup.

A follow-up diagnostic of the existing list query (`limit=20&offset=100`) found
the count scanning 95,000 active bookmarks in a hash join. The count took about
46 ms; the bookmark/tag page queries each took about 0.5–2 ms. Adding the
candidate composite index left the count's sequential-scan/hash-join plan in
place and did not improve it. This is a single-request diagnostic on the retained
after dataset, not another throughput comparison. No index is added to the app.

## Reproduce

Build the instrumented Linkding binary as described in the
[profiling instructions](../../engine-profile/README.md). Save the original
engine seed, then use the same binary for both runs:

```sh
git show 723d88e:performance/linkding/bench/seed_h5i_app.sql > /dev/shm/seed-before.sql
python3 performance/engine-profile/run.py --app linkding \
  --binary /dev/shm/bin/instrumented-linkding-server \
  --engine-seed-sql /dev/shm/seed-before.sql \
  --out /dev/shm/search-before --scenarios 'search get list' \
  --concurrency '1 64' --repeats 3 --warmup 5 --duration 15
python3 performance/engine-profile/run.py --app linkding \
  --binary /dev/shm/bin/instrumented-linkding-server \
  --out /dev/shm/search-after --scenarios 'search get list' \
  --concurrency '1 64' --repeats 3 --warmup 5 --duration 15
```

The runner snapshots the engine seed in each local output directory and records
its hash, together with the binary hash. The existing profile summarizer checks
that HTTP completions, engine invocations and k6 requests agree.

## Next application change

Statistics do not reduce the 287,002 loaded rows. A text index alone cannot
filter these queries because the SQL predicate does not contain the text term.
The next substantial change is a narrower, proved search read plan, rather than
an additional unreferenced index. It must preserve ASCII case folding, legacy
and lax search, tag matching, bundles, visibility, ordering and the total count.
The stored text is `bytea`; replacing the predicate with locale-dependent
`ILIKE` would not establish equivalent semantics.

The list count is a second application read/count-plan target. Any narrower
count must preserve visibility and exact totals; avoiding it or serving an
approximation would change the API.

Such a change needs extraction and rechecking the affected read-plan,
count and frame proofs, plus database differential tests for any new SQL
predicate. This experiment deliberately does not introduce that semantic change.
