# Linkding: scalar subqueries for unique membership

Follow-up: [selectable SQL modes and fixed-offset list measurement](sql-modes-2026-10-18.md).

This follows the [seed-statistics experiment](search-plan-2026-10-18.md).
It changes the engine's SQL renderer, while retaining the application's
extracted decisions, read plans, count plans, isolation and locks.

## Change and safety boundary

Previously, the engine rendered membership in every nested read as `IN
(SELECT ...)`. The Linkding owner lookup reads a token by its primary key.
It can return at most one row, but the general membership form allowed
PostgreSQL to choose a hash/semi join and scan many bookmarks. The renderer
now emits scalar `= (SELECT ...)` only when conjunctions of equality predicates
fix **every primary-key column** of the inner table. Every read already fixes
the tenant. Partial compound keys, disjunctions and other multirow lookups
keep `IN`; `LIMIT 1` alone is not treated as proof of uniqueness.

The scalar form allows PostgreSQL to compute the lookup once as an InitPlan
and use its value in the outer scan. This does not introduce a token cache,
a new index, stale reads, approximate counts or another transaction boundary.
It is an engine optimization rather than a Linkding kernel rewrite.

Both membership columns must already be non-nullable. An empty scalar
subquery produces SQL UNKNOWN rather than `IN`'s FALSE. These select the same
rows in this positive `AND`/`OR` predicate language. Adding negation would
require revisiting the rewrite. The cardinality argument relies on the
existing physical schema's tenant-scoped primary key.

`compile_read` remains outside extraction and is differential-tested against
the reference evaluator; this change does **not** formally verify the read
SQL compiler. The existing application and SQL/write proofs remain unchanged.
No generated Lean is edited, and no theorem or axiom gate is weakened.

## Validation

- All seven SQL renderer unit tests pass.
- The PostgreSQL read suite passes, including 3,200 randomized reads and the
  bounded prepared-statement cache test. A new 120-case suite compares both
  rows and exact counts for scalar and non-scalar membership: empty lookups,
  compound keys, duplicate projections, both tenant datasets, windows and
  `AND`/`OR` contexts.
- Linkding's nine Hurl files pass: 200 HTTP requests, including search after
  create/update/delete, visibility, authentication, pagination and bundles.
- `h5i app check` passes for the SQL crate (203 theorems in four modules)
  and Linkding (493 theorems in nine modules, including ownership, read-plan,
  frame and count gates). Only `propext`, `Classical.choice` and `Quot.sound`
  are accepted, as before. Application extraction inputs are unchanged;
  existing generated artifacts and proof sources are rechecked.

## Method and provenance

The h5i implementation is
[`444e9b5`](https://github.com/h5i-dev/h5i/commit/444e9b54114baac336d989445140d6e8a7b7b9eb),
based on main `b8cbcfd`. To isolate the renderer from other engine changes
since the benchmark's dependency pin, both measured binaries use h5i
`3fcbcdafdfdd759bfa52c765ce8dd2f73c88a26e`, with the same
[aggregate timing probes](../../engine-profile/README.md). The after binary
adds only the renderer change. Application code and non-h5i dependencies are
identical. This experiment does not update the applications' default lockfiles
to an unmerged engine branch.

The benchmark base is `ec1b19d2911c387bc0a9bae11c4c33e53351e242`.
Both sides explicitly analyze the same seeded tables and use fresh PostgreSQL
16 containers with 1 GiB shared memory and 512 MB shared buffers. Each point
reseeds the database and restarts the server. The three scenarios are the
existing HTTP get, list and text-search workloads, at 1 and 64 clients, with
three repetitions, 5 s warmup and 15 s arrival windows. Search requests drain
fully, with a 120 s grace period; throughput includes drain time. There are
four server CPUs, four PostgreSQL CPUs and four client CPUs in disjoint sets,
four Tokio workers and 32 pool connections.

The first search baseline overlapped proof builds and is excluded from the
main comparison. After both full blocks and proof checks finished, all six
search baseline points were rerun. Get/list use the first before block; search
uses this final baseline block. The initial search means are retained only in
`search-recheck.csv` as a sensitivity check. Thus search is measured in
after/before order, and get/list in before/after order.

These are HTTP end-to-end measurements with timing probes enabled, including
authentication, SQL, row decoding, kernel execution, pagination and JSON
responses. Parent timers are inclusive; summed SQL-query times overlap with
pipelined work and must not be added to load time. Both blocks run sequentially
on a shared host, with uncontrolled clocks and NUMA placement. Short runs and
list offsets introduce variance. These results do not establish performance
against Go or uninstrumented deployments. Conduit, writes, mixed traffic and
optimized/GPU variants are not remeasured here. The earlier published tables
remain separate.

All experiment data, temporary files, build outputs and raw captures use
`/dev/shm`. Only this report and summary CSVs are committed.

## Reproduce

Follow the [engine profiling setup](../../engine-profile/README.md) at the
benchmark base above, using the pinned h5i revision. Build and save the original
instrumented release binary. Copy the updated renderer into that disposable
h5i checkout, rebuild, and save the second binary. From a local h5i clone
containing the implementation commit, export the source file:

```sh
git show 444e9b54114baac336d989445140d6e8a7b7b9eb:crates/h5i-app-pgsql/src/read.rs \
  > /dev/shm/read-after.rs
```

After building the before binary, copy that file over
`crates/h5i-app-pgsql/src/read.rs` in the pinned disposable h5i checkout. Its
other difference from the original pin is an updated test-path doc comment.
Keep the same instrumentation and Cargo dependencies for both builds. Run sequentially, from the benchmark:

```sh
python3 performance/engine-profile/run.py --app linkding \
  --binary /dev/shm/bin/before --out /dev/shm/scalar-before \
  --scenarios 'search get list' --concurrency '1 64' \
  --repeats 3 --warmup 5 --duration 15 --pg-port 15724 --http-port 18424
python3 performance/engine-profile/run.py --app linkding \
  --binary /dev/shm/bin/after --out /dev/shm/scalar-after \
  --scenarios 'search get list' --concurrency '1 64' \
  --repeats 3 --warmup 5 --duration 15 --pg-port 15724 --http-port 18424
python3 performance/engine-profile/run.py --app linkding \
  --binary /dev/shm/bin/before --out /dev/shm/scalar-before-search \
  --scenarios 'search' --concurrency '1 64' \
  --repeats 3 --warmup 5 --duration 15 --pg-port 15725 --http-port 18425
python3 performance/engine-profile/summarize.py /dev/shm/scalar-before \
  /dev/shm/scalar-before-search --replace-duplicates --out /dev/shm/summary-before
python3 performance/engine-profile/summarize.py /dev/shm/scalar-after \
  --out /dev/shm/summary-after
```

The renderer patch SHA-256 is
`dbebdb8c4d3d8ae8f129aabc594a3856a3a85a5a3c326077afdca9412da8c64f`.
Binary and seed hashes, actual container shared-memory capacity, timestamps
and request counts are recorded in the accompanying run summary.

## HTTP results

Mean of three repetitions per point; completed HTTP requests per second.

| Scenario | Clients | Before RPS | After RPS | After / before | Before p99 ms | After p99 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| get | 1 | 480.17 | 490.78 | 1.02× | 2.16 | 2.22 |
| get | 64 | 11443.34 | 11180.28 | 0.98× | 9.10 | 9.20 |
| list | 1 | 21.81 | 22.23 | 1.02× | 70.19 | 73.51 |
| list | 64 | 120.26 | 107.66 | 0.90× | 723.42 | 984.53 |
| search | 1 | 1.87 | 2.40 | 1.28× | 572.42 | 462.41 |
| search | 64 | 7.70 | 11.81 | 1.53× | 9441.85 | 6931.04 |

All 36 selected points pass: **1,076,011 HTTP requests, zero failed requests**.
The [summary CSVs](results/scalar-membership-2026-10-18/comparison.csv),
[run provenance](results/scalar-membership-2026-10-18/runs.csv) and
[validation summary](results/scalar-membership-2026-10-18/checks.csv) accompany
this report. Per-point files contain aggregate statistics, not request logs.

Search throughput increases **1.28×** at one client and
**1.53×** at 64 clients. Single-client mean server HTTP time
falls from 533 to 415 ms, and
load time from 478 to 355 ms.
At 64 clients, mean load time falls from 3834 to
2414 ms. Loaded rows remain **287,002** per search
request: 95,000 bookmarks, 190,000 links, 2,000 tags, a token and a user.
The HTTP response still contains 20 bookmarks and an exact total of 1,000.
This supports a query-execution improvement, without a smaller search snapshot
or a faster application kernel.

**This is not a uniform improvement.** Get throughput changes by roughly ±2%.
List throughput is 1.02× baseline at one client and
0.90× at 64 clients; concurrency-64 p99 rises from
723 to 985 ms. The before list
RPS standard deviations are 7.57 and
32.33; after they are
0.03 and 8.10. List offsets
and row counts vary slightly between runs. The high variance limits attribution,
but the lower concurrency-64 throughput and worse tail latency are retained,
not presented as a win. The engine change is published on an experiment branch;
these results do not justify updating all applications' default dependency pins.

### Search baseline recheck

The first search baseline is excluded because proof builds overlapped it.
The final baseline runs after all proof checks and the after block. Both have
the same before binary and seed; the following sensitivity summary does not
add the initial points to the main comparison.

| Clients | Initial baseline RPS | Final baseline RPS | Final / initial |
| --- | ---: | ---: | ---: |
| 1 | 1.86 | 1.87 | 1.00× |
| 64 | 7.63 | 7.70 | 1.01× |

## Next step

Search still spends most of its time loading the entire caller scope. Reducing
that snapshot is the larger application-level opportunity. A narrower plan must
preserve ASCII folding, legacy/lax search, tags, visibility, ordering, pagination
and exact counts, with extraction and renewed plan/frame/count proofs. A text
index that is not referenced by the read predicate will not achieve that.

The list regression/variance also remains an open issue. Further work should
separate its count query from page loading and verify any revised strategy on
fresh, repeated HTTP runs before adopting a default. Neither approximate counts
nor weaker transaction guarantees are used here.
