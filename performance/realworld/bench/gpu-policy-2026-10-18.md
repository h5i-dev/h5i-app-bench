# Shared Conduit HTTP benchmark with optional GPU policies

The CPU and GPU executables were built from `2a4f25c`, based on upstream main
`4c3dcb5`. The GPU backend uses h5i main `b8cbcfd`, including the generic
`Backend` interface. Both executables share the existing optimized Conduit
server source; the GPU build enables its optional `gpu` feature.

This measures the existing REST application through HTTP, JWT authentication,
SQL reads/writes and transactions, policy decisions, and JSON responses.
It uses the unchanged seven scenarios in `workload.js`, the normal seed,
`bench-all.sh`, process sampler and summarizer. It does not measure the browser
UI or any new bulk-compute endpoint. Earlier cross-language overview results
remain separate because their CPU allocations and measurement scope differ.

## GPU scope

Eight existing pure policy transitions have a device implementation:
`CurrentUser`, `Feed`, `DeleteArticle`, `DeleteComment`, `Follow`, `Unfollow`,
`Favorite`, and `Unfavorite`. These are small authorization/state decisions,
often only a few integer comparisons. Input validation, JWT, bcrypt, SQL and
serialization remain on CPU. GPU execution does not replace the database.

In this workload, `feed`, `create` (its authenticated-user check), `favorite`,
and their portion of `mixed` execute GPU decisions. Guest `list` and `slug`,
and `login`, do not execute this subset and are negative controls. The other
GPU operations are exercised by the shared API conformance suite. No heavier
computation, bulk API, altered traffic mix or extra scan was added to favor GPU.

A dedicated worker owns one CUDA context, stream and reusable device buffers.
It drains up to 128 already queued decisions, with no wait to fill a batch.
Initialization must succeed for the GPU server to start. Runtime failures,
invalid output or a full queue use the original CPU decision and log fallback
counts. Normal CPU builds require no CUDA runtime. The device implementation
is checked against the CPU oracle; the existing Lean proofs cover the CPU
kernel, not a formal CPU/GPU equivalence theorem.

## Conditions

Each point starts with a reseeded database and fresh server: 100 users, 10,000
articles, two tags per article, 10,000 comments, 1,000 follows and 5,000 favorites.
Ten seconds of warmup precede 30 seconds of measurement; writes during warmup
remain in the database, as in the existing harness. Concurrency is 1 and 16,
with three repetitions. Login uses bcrypt cost 12. Request rates include k6's
graceful stop (up to 60 seconds for login, 15 seconds for other scenarios).

Two independent CPU/GPU pairs run concurrently, with the scenarios split into
two lanes. Each server uses four Tokio threads and a 32-connection SQL pool;
each gets four server, four PostgreSQL and four client CPUs. CPU affinities do
not overlap. Each pair has its own GPU, and every server has its own PostgreSQL
16.15 container (512 MiB shared buffers, 200 maximum connections). The load
generator is k6 2.3.0. Server startup and CUDA initialization precede warmup;
the measurements cover warm request handling, not cold starts.

| Lane / variant | Scenarios | Server CPUs | PostgreSQL CPUs | Client CPUs | GPU |
| --- | --- | --- | --- | --- | --- |
| 0 / CPU | list, feed, create, mixed | 0–3 | 4–7 | 8–11 | none |
| 0 / GPU | list, feed, create, mixed | 12–15 | 16–19 | 20–23 | 0 |
| 1 / CPU | slug, login, favorite | 24–27 | 28–31 | 32–35 | none |
| 1 / GPU | slug, login, favorite | 36–39 | 40–43 | 44–47 | 1 |

Host: dual AMD EPYC 7502, NVIDIA RTX 3090 GPUs, driver 560.35.03, CUDA 12.6.
The host is shared; clocks and NUMA placement are not fixed. Executables and PTX
were built with release profiles and locked dependencies. The local run metadata
records the clean source revision, artifact SHA-256 hashes and CPU/GPU layout.

## Results

Means of three repetitions. Latency columns average per-repetition percentiles;
they are not pooled percentiles. Dispersion, CPU usage and memory are in the
linked standard summaries. Ratios compare the same HTTP server with and
without the GPU feature.

| Scenario | Clients | CPU req/s | GPU req/s | GPU / CPU | CPU p99 ms | GPU p99 ms |
| --- | --- | --- | --- | --- | --- | --- |
| list | 1 | 83.37 | 82.83 | 0.99× | 32.69 | 32.65 |
| list | 16 | 766.32 | 769.67 | 1.00× | 78.78 | 78.82 |
| slug | 1 | 1,110.16 | 1,118.36 | 1.01× | 0.96 | 1.00 |
| slug | 16 | 13,560.10 | 14,174.03 | 1.05× | 8.89 | 8.55 |
| feed | 1 | 187.76 | 179.55 | 0.96× | 5.80 | 6.10 |
| feed | 16 | 2,194.92 | 2,201.72 | 1.00× | 14.30 | 13.99 |
| login | 1 | 3.85 | 3.83 | 1.00× | 260.47 | 261.96 |
| login | 16 | 15.45 | 15.41 | 1.00× | 1,113.43 | 1,104.02 |
| create | 1 | 196.21 | 190.83 | 0.97× | 5.64 | 5.78 |
| create | 16 | 216.31 | 209.85 | 0.97× | 363.18 | 367.29 |
| favorite | 1 | 504.53 | 439.16 | 0.87× | 2.63 | 3.15 |
| favorite | 16 | 4,457.18 | 4,725.08 | 1.06× | 19.18 | 17.90 |
| mixed | 1 | 121.54 | 123.87 | 1.02× | 35.13 | 33.75 |
| mixed | 16 | 1,001.07 | 982.93 | 0.98× | 68.70 | 71.16 |

All 84 measurement points completed: 4,467,960 measured requests, zero HTTP
failures and zero failed k6 status checks. Every GPU point for `feed`, `create`,
`favorite` and `mixed` logged successful device execution. No runtime CPU
fallback or device failure was logged. The three control scenarios did not
launch a policy kernel. These logs include warmup as well as measurement.


## Validation and interpretation

Before timing, CPU and GPU each passed all 13 pinned Hurl files (154 HTTP
requests each). The portable oracle test compares 8,192 combinations with the
existing CPU transition, including unauthenticated actors, missing resources,
owner mismatches and idempotent transitions. Actual GPU tests passed empty,
1-, 127- and 128-row batches and rejection of oversized/invalid input. A short
seven-scenario smoke run also passed on both variants; its timings are excluded.

There is no consistent end-to-end throughput benefit in this workload. Mixed
throughput is 1.02x CPU at one client and 0.98x at 16; mixed p99 at 16 is
71.16 ms on GPU versus 68.70 ms on CPU. Feed is 0.96x/1.00x, and create is
0.97x at both concurrency levels. Favorite is 0.87x at one client and 1.06x
at 16. That last mean increase should not be treated as an established GPU
speedup: its GPU request-rate standard deviation is about 5%, and even the
non-offloaded `slug` control is 1.05x at 16 clients on the different CPU sets.

GPU host RSS is approximately 93–98 MiB, versus 7–11 MiB on CPU: about 87 MiB
additional resident host memory, including idle control scenarios. This is
process RSS, not GPU VRAM usage. GPU initialization and idle runtime costs
remain even when a route does not launch a device kernel.

This contrasts with the resident text-search workload in Linkding. Conduit's
policy subset does little computation, so GPU dispatch, copies and worker
scheduling add work around a very small decision. The unchanged SQL and other
application stages also remain in each HTTP request. This is an explanation
consistent with the code, not a measured decomposition of the bottleneck;
this run did not separately time those stages. CPU remains the default.

Only the CPU and optional GPU versions were remeasured, at concurrency 1/16.
These results do not establish behavior at higher concurrency, on other GPUs,
or a cost/power advantage. The different CPU affinities, shared machine and
fixed lane assignments can also affect small differences. The controls help
show this variation; a small ratio change is not by itself a GPU benefit.

## Reproduce

Follow [the GPU build instructions](../rust-h5i-gpu/README.md). Build the same
server in release mode, once without features and once with `--features gpu`,
using separate target directories so both executables are retained. Then run:

```sh
python3 performance/realworld/bench/remeasure-gpu.py \
  --cpu-bin /path/to/cpu/conduit-server \
  --gpu-bin /path/to/gpu/conduit-server \
  --ptx /path/to/conduit_gpu_device.ptx \
  --out /var/tmp/conduit-gpu-run --lanes 2
```

This run uses the runner defaults: all seven shared scenarios, concurrency 1/16,
three repetitions, 10 seconds warmup and 30 seconds measurement. Use one lane
(the default) on a host with only one GPU.

Only [aggregate CSV](results/gpu-policy-2026-10-18/summary.csv),
[Markdown summary](results/gpu-policy-2026-10-18/summary.md) and
[per-point CSV summaries](results/gpu-policy-2026-10-18/points.csv) are published.
Raw k6 JSON, metadata and validation/server logs remain local.
