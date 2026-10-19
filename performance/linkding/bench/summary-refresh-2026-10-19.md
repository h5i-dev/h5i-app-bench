# Linkding summary refresh

The overview still used the 2026-10-17 full-suite results after the engine
SQL modes, seed statistics and optimized get handler changed on 2026-10-18.
The shorter attribution experiments were published separately and did not
replace those rows. This run measures the affected implementations with the
full-suite workload and durations.

## Scope

- Normal `rust-h5i`: list, search, search_tag, get, create, update, archive,
  tags and mixed, at 1/16/64/256 clients, three repetitions each.
- `rust-h5i-optimized`: get and mixed at the same client counts and repetitions.
- Normal-engine complex search retains its [separate measurement](complex-engine-2026-10-19.md).
  The other-language complex-search results also retain their separate run.

The site now selects configured runs in order, replacing each matching
implementation/scenario/concurrency point. Both overview and details use the
same selected rows; details link their dates to the source CSV. The existing
[paired search run](text-search-2026-10-17.md) supplies search, complex search
and mixed for its measured implementations and client counts, rather than
only complex search. Conduit's paired policy run supplies both CPU and GPU
rows at 1/16 clients. Unchanged routes retain their earlier measurements.

## Conditions

Application source: `e3b31b254b62ac0db4140277ad9a4c875ed1dd2d`, with no application
or dependency changes during this refresh. Normal-engine h5i dependency:
`8e764ab849f71e771bc8d026491a3c104f8cb6a5`. Both servers are built with
`cargo build --release --locked`, rustc 1.98.1.

The unchanged shared workload and seed use 100,000 bookmarks, 2,000 tags
and 50 users. Every point restarts the server and reseeds the database,
including `ANALYZE` on the engine's tables. Warmup is 10 seconds, measurement
30 seconds, with the shared workload's five-second graceful stop. Throughput
uses k6's actual runtime, including drain. Percentiles and request rates are
means of three repetitions; percentiles are not pooled.
HTTP failure counts cover completed requests; the finite graceful stop can
interrupt remaining work under overload.

Five slots run concurrently on a shared dual AMD EPYC 7502 host (128 logical
CPUs). Each slot has four server, four database and four client CPUs:

| Slot | Server | PostgreSQL | k6 |
| --- | --- | --- | --- |
| 0 | 0–3 | 4–7 | 8–11 |
| 1 | 12–15 | 16–19 | 20–23 |
| 2 | 24–27 | 28–31 | 32–35 |
| 3 | 36–39 | 40–43 | 44–47 |
| 4 | 48–51 | 52–55 | 56–59 |

Each server uses four Tokio workers and a 32-connection pool. PostgreSQL 16
containers each use 512 MiB shared buffers, 200 connections and 1 GiB shared
memory, with affinity set inside the container. Databases and captures are
under `/var/tmp`. A slot takes the next scenario/client-count task after its
three repetitions finish; the raw run manifest records assignments.

The older full-suite Linkding run used three CPUs each for server/database/client;
the paired text-search and complex-search runs use four. Host load, slots and
dates also differ. These results update current-implementation measurements;
cross-run rankings do not isolate a code-only speedup.

## Results

All 132 measurement points completed (44 conditions, three repetitions each).
The measured run recorded 5,873,825 requests; its 132 warmups recorded
1,885,642 requests. Both had zero HTTP failures and zero failed checks.
The graceful-stop limitation above still applies.

At 16 clients:

| Implementation | Scenario | Requests/s | p99 ms |
| --- | --- | ---: | ---: |
| rust-h5i | list | 106.82 | 423.43 |
| rust-h5i | search | 6.69 | 3558.03 |
| rust-h5i | search_tag | 1809.79 | 16.35 |
| rust-h5i | get | 2988.60 | 12.00 |
| rust-h5i-optimized | get | 7168.65 | 6.44 |
| rust-h5i | create | 264.91 | 91.70 |
| rust-h5i | update | 1122.40 | 26.07 |
| rust-h5i | archive | 2225.82 | 18.33 |
| rust-h5i | tags | 1570.81 | 20.64 |
| rust-h5i | mixed | 18.51 | 3836.78 |
| rust-h5i-optimized | mixed | 80.48 | 963.47 |

[All client counts](results/summary-refresh-2026-10-19/summary.md) ·
[Summary CSV](results/summary-refresh-2026-10-19/summary.csv) ·
[Individual repetitions](results/summary-refresh-2026-10-19/points.csv)

## Reproduce

```sh
python3 performance/linkding/bench/refresh-summary.py \
  --out /var/tmp/ld-summary-refresh-new-run
```

Archive `summary.csv`, `summary.md` and `points.csv` from the output directory
under `bench/results/<run-name>/`, then add that summary to Linkding’s
`summaries` list in `performance/site.py` and run `python3 performance/site.py`.

The output directory must not exist. The runner removes its five temporary
PostgreSQL containers when finished. Raw k6 summaries, warmups, logs,
artifact hashes and run metadata remain at `/var/tmp/ld-summary-refresh-20261019`.
