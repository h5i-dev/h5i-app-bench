# Resident incremental totals across languages

Independent Go, JavaScript and Python implementations now share the resident
update workload with Rust and CUDA. This is a calculation/update batch benchmark,
not a Django, HTTP, SQL or language-wide throughput score.

[Dashboard](../../../../docs/performance/index.html#cart-resident-languages)
[All timings](results/2026-10-20/summary.md)

## Findings

New CPU measurements, milliseconds per batch; mean of three repetition means.
Four workers/processes for Rust, Go, JavaScript and CPython; NumPy uses one native thread.
GPU is the fastest earlier uncontended path for that shape, explicitly a reference.
All one-worker results and mean ± SD remain in [the complete table](results/2026-10-20/summary.md).

| Carts × lines | Updates/cart | Rust 4 | Go 4 | JS 4 | CPython 4 processes | NumPy | Prior GPU reference |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 4,096 × 512 | 16 | 0.541 | 0.711 | 1.413 | 15.880 | 7.247 | 0.239 |
| 65,536 × 2,048 | 1 | 2.522 | 2.678 | 6.568 | 36.072 | 15.207 | 0.361 |
| 65,536 × 2,048 | 16 | 11.707 | 15.367 | 19.758 | 230.525 | 146.102 | 2.861 |
| 65,536 × 2,048 | 64 | 50.340 | 70.102 | 57.788 | 871.038 | 579.362 | 10.859 |

Go is close to Rust for one replacement/cart. At 64 replacements/cart, JavaScript
four workers outperform Go four workers in this port, while Rust remains fastest.
CPython four processes substantially improve on its one-process loop, and NumPy
is stronger again, but neither matches the compiled/JIT CPU paths in these traces.

Against the earlier GPU references, the fastest newly measured CPU gives ratios
of 2.26×, 6.98×, 4.09×, 4.64× in table order. None reaches 10×.
Python-to-GPU reference ratios exceed 10×, but that does not establish a 10×
advantage over the strongest CPU baseline. These are cross-run reference ratios,
not contemporary GPU speedups; the CPU run occurred while external GPU jobs were active.

All 6,264 new changing CPU rounds passed exact comparisons for 314,302,464 totals,
plus 808 upstream Decimal cases per implementation. All four prior GPU paths
match every new round checksum. No contended GPU trial is substituted into the comparison table. A subsequent
explicitly contended diagnostic is reported separately below.

## GPU availability and reference policy

External vLLM jobs occupied all four GPUs at 100% utilization during the new CPU
measurements. Read-only process inspection
confirmed these were another user's vLLM generation workers, not abandoned cart
benchmark processes. Initial contended GPU trials were discarded. A subsequent deliberate diagnostic
rerun is retained separately, without replacing the baseline timings. The dashboard explicitly
labels GPU values reused from the [earlier transport experiment](../scale/transport/README.md),
with its UTC timestamp. These are reference ratios, not contemporary measured
speedups. The CPU timings and cross-language comparisons are newly measured.
The four reused GPU paths' per-round checksums must match every new expected
trace checksum; their reported means/SD are recomputed from the old raw rounds.
No contended GPU value is substituted into that reference.

The CPU-only validator requires all nine CPU implementations and the full
four-shape/three-repetition grid. Publication records the earlier GPU evidence
hashes separately. The full contemporary validator still requires all thirteen
implementations. GPU timing refuses to run if device 0 has another compute
process. If GPU 0 becomes free, `--phase gpu` can add a fresh run to a completed
`--phase cpu` run; source, artifact and fixture hashes must match exactly.
GPU and CPU phases then remain separate runs, rather than being described as
interleaved samples. The default `--phase all` interleaves implementations.

## GPU rerun under external contention

GPU timing was possible despite external vLLM jobs reporting 100% device utilization.
The explicit diagnostic rerun used the fixed previous best GPU path per shape,
the same input and full owned output, three repetitions, eight warmups and 50
timed rounds. The original uncontended GPU values remain the main comparison
baseline; CPU and GPU measurement times remain explicitly different.
The contended rerun is a supplemental diagnostic, not a replacement speedup.

| Carts × lines | Updates/cart | GPU rerun ms | Prior uncontended GPU ms | Current / prior |
| --- | ---: | ---: | ---: | ---: |
| 4,096 × 512 | 16 | 2.325 | 0.239 | 9.72× |
| 65,536 × 2,048 | 1 | 2.315 | 0.361 | 6.41× |
| 65,536 × 2,048 | 16 | 3.168 | 2.861 | 1.11× |
| 65,536 × 2,048 | 64 | 14.239 | 10.859 | 1.31× |

All 696 rounds passed exact validation of 34,922,496 returned totals, plus 808
upstream cases each for the scan and delta GPU paths. Utilization and competing
processes were captured before and after each repetition. The effect of
contention differs by shape; these measurements do not identify a particular
scheduling or transfer component as the cause.

[Rerun mean ± SD](results/2026-10-20-contended/summary.md) · [Diagnostic runner](../measure_contended_languages.py)

## Common input and output

The exporter copies `initial`, `apply` and `trace` verbatim from the earlier
resident Rust experiment. It writes little-endian u64 rows, canonical commands
and expected outputs into external fixtures under `/var/tmp`. Every expected
output is produced by a full rescan after applying that round's changes,
independent of the incremental caches used for timing. Every implementation
checks every returned value outside timing. No per-query sample or checksum-only
validation replaces those exact comparisons. Checksums additionally compare
all rounds across all implementations and repetitions.

A command contains explicit u64 query IDs followed by four u64 fields per
replacement: cart, slot, price and quantity. Distinct queried carts and the
original round-robin routing make cart ownership independent between workers.
Changed slots are distinct within each batch. Prices, quantities and slots
change on every round, with periodic maximum values. The workload has 4,096
carts × 512 lines × 16 replacements/cart, then 65,536 carts × 2,048 lines with
1, 16 or 64 replacements/cart. All carts are queried on every batch.

There are eight changing warmups and 50 timed changing rounds, repeated three
times with reset state and rotated/reversed implementation order. Output order
follows query IDs. Each timed call returns a freshly owned complete array of
exact integer cents. Update application, subtotal and discount computation,
worker dispatch/join, output allocation and collection are included. GPU paths
also include compact encoding where applicable, upload, synchronization and full
download. Cache rows, sums and totals remain resident between batches for every
implementation. There is no omitted update delivery inside the command-to-result
boundary, reduced output or stale-cache shortcut.

Fixture loading, input validation, initial placement/cache construction, worker
creation, CUDA context/module loading and reference validation are outside batch
timing. The binary fixtures contain canonical u64 words; JavaScript reads each
command's low u32 after checking all high words are zero. It retains eight bytes
per word, with no packing shortcut. Its row storage uses Float64Array: all
subtotal integers fit exactly below 2^53, and quotient/remainder discount
rounding avoids unsafe scaled intermediates. Go/Rust use u64; Python uses
arbitrary-precision integers and array/memoryview u64 storage; NumPy uses uint64
with bounded intermediates below 2^64.

## Implementations and worker budgets

| Label | Timed implementation |
| --- | --- |
| `rust-1`, `rust-4` | Previous grouped incremental CPU algorithm, one or four persistent Rayon workers |
| `go-1`, `go-4` | Independent grouped incremental algorithm, sequential or four persistent goroutines; GOMAXPROCS=4 |
| `javascript-1`, `javascript-4` | Independent grouped incremental algorithm, sequential or four persistent Node worker threads with shared retained rows/caches/commands |
| `python-1`, `python-4` | Ordinary CPython loops, sequential or four persistent fork processes using shared retained rows/caches/commands |
| `python-numpy` | Native NumPy vectorized gathers, per-cart reductions and scatter updates; native library thread counts fixed to one |
| `gpu-scan-pageable`, `gpu-delta-pageable` | Unchanged legacy GPU paths |
| `gpu-scan-compact-pinned-encode4`, `gpu-delta-compact-pinned-encode4` | Compact updates with reusable pinned input/output and four-worker encoding |

All processes and their workers inherit affinity to CPUs 64–67. The one-worker
labels specify application computation workers, not a prohibition on runtime
GC/helper threads. Runtime garbage collection is enabled. Four-process Python
has no shared GIL. Worker dispatch and waiting, plus copying shared results into
an owned output for JavaScript/Python, are inside timing. No benchmark processes
run concurrently; external jobs can still affect the shared host. NumPy is a separate, stronger Python baseline; its native
loops are not described as CPython loop performance.

All Python modes use NumPy for untimed input validation only. The timed
`python-1` and `python-4` paths execute ordinary Python loops. Their initial
subtotals are imported from the exporter's retained-state fixture to avoid
repeatedly scanning billions of Python objects outside timing. Initial totals
are always calculated in Python. At each upstream correctness gate, Python
independently recalculates every initial subtotal too. Other language paths
construct initial caches from rows. `init_ms` therefore records different
initialization work and is not a fair cache-construction speed comparison.

## Validation and limits

Every implementation passes 808 cases from the pinned Django Decimal oracle:
166/190/214/238 cases at 32/128/512/2,048-line caps, including empty/sparse carts,
maximum values and percentage/fixed discount rounding. A separate smoke matrix
covers zero, one and sixteen replacements/cart at 64 carts × 32 lines, through
all implementations and all 58 changing steps and three repetitions.

The publication validator rejects missing/duplicate grid points, invalid times,
wrong output counts and checksum mismatches against the exact output fixtures.
Checksums are parsed as integers. Means and sample SD use three repetition means,
not pooled per-round SD. Raw gate and round records, source/binary/PTX hashes,
fixture hashes, runtime versions and exact commands are retained.

RTX 3090 device 0; shared EPYC host, uncontrolled clocks, NUMA/cache placement and
background activity. GPU scan versus delta is selected only within each reported
shape and the individual paths remain visible. CPU comparisons retain one/four
worker variants rather than assuming four is always faster. No language is
claimed optimal from one port. Database reads/commits, CDC, HTTP, inserts/deletes,
concurrent writers and durable coherence remain outside this experiment.

## Reproduce

Use the existing pinned [CUDA/Rust toolchain](../README.md#reproduce), Go at
`/var/tmp/go/bin/go`, Node, and a Python 3.12 venv at `/var/tmp/cart-language-venv`
with `numpy==2.4.6`. External fixtures require at least 18 GB of free disk and the
largest shapes need tens of GB of host RAM. Build the independent compact PTX
with `../scale/transport/build.sh` first if it does not exist.

```sh
bash performance/django-cart/resident/languages/build.sh
python3 performance/django-cart/resident/languages/run.py --smoke --out /var/tmp/cart-languages-smoke
python3 performance/django-cart/resident/languages/run.py --phase cpu
python3 performance/django-cart/resident/publish_languages.py
# After GPU 0 is free, replace references with fresh GPU measurements:
python3 performance/django-cart/resident/languages/run.py --phase gpu
python3 -m unittest discover -s performance/django-cart/resident/languages -p 'test_*.py'
python3 performance/site.py
```

Fixtures and binaries stay outside the repository. The output directory defaults
to `results/2026-10-20`; `--out` and `--fixtures` override it. The original measured
Rust/GPU source files, binaries, PTX and result directories are preserved.
