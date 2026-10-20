# Compact updates and reusable page-locked staging

This evaluates input-path changes identified by the [phase diagnostic](../profile/README.md),
using the same changing canonical command trace and independent full-rescan oracle.
The previous measured sources, binaries, PTX and result directories remain intact.

[Dashboard](../../../../../docs/performance/index.html#cart-update-transport)
[All measurements](results/2026-10-20/summary.md)

## Findings

Compact updates plus reusable pinned input/output and four-worker encoding are
fastest in all four shapes. Times below include encoding, staging, update
upload, GPU work, synchronization and a complete freshly owned result vector.
CPU is the same four-worker grouped incremental implementation. Legacy GPU is
the faster of its unchanged scan and delta paths in this run.

| Carts × lines | Updates/cart | CPU4 µs | Legacy GPU µs | Optimized GPU µs | GPU improvement | CPU4 / optimized GPU |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 4,096 × 512 | 16 | 663.026 | 272.943 | 239.171 | 1.14× | 2.77× |
| 65,536 × 2,048 | 1 | 2,035.768 | 380.069 | 361.218 | 1.05× | 5.64× |
| 65,536 × 2,048 | 16 | 10,967.178 | 3,591.773 | 2,860.982 | 1.26× | 3.83× |
| 65,536 × 2,048 | 64 | 53,042.363 | 13,717.546 | 10,859.331 | 1.26× | 4.88× |

No measured shape reaches 10× against CPU4. The first shape's CPU mean varies
substantially across repetitions (663.026 ± 163.623 µs), so its increased CPU/GPU
ratio compared with earlier experiments cannot all be credited to this change.
Its GPU improvement is 272.943 ± 0.744 → 239.171 ± 3.958 µs. Larger-shape CPU
standard deviations are 48.339, 33.466 and 50.250 µs; optimized GPU standard
deviations are 1.646, 14.890 and 69.031 µs, respectively. These describe three
repetition means, not confidence intervals. See the full table for every path.

Pinning alone loses to legacy pageable input in all four shapes: staging from
the canonical input consumes its transfer advantage. Serial compact+pinned
encoding also fails to improve the two larger update-heavy shapes. For 64
updates/cart, serial compact delta takes 14,328.033 µs, including 9,521.574 µs
encoding; four-worker encoding reduces these to 10,859.331 and 6,279.534 µs.
Packing/staging still consumes about 58% of the optimized batch wall time.

The separate event replay of this largest optimized shape measures encoding
6,241.493 µs, upload interval 1,384.769 µs, kernels 3,094.051 µs and download
27.383 µs (total 10,839.027 µs). Result download is about 0.3%; input preparation
and update processing matter much more. Upload is much smaller after shrinking
134,742,016 bytes to 34,078,720 bytes. A future native compact event source could
avoid reading and repacking the legacy stream, but that is a different input
contract and is not established by this experiment. This is a resident compute
benchmark, not a Django/HTTP application speedup.

## Wire format and contract

A legacy replacement consists of four u64 values (cart ID, slot, price, quantity):
32 bytes. A compact replacement is one u64: slot in bits 0–10, price in bits
11–37, quantity in bits 38–47. Slots 0–2,047, prices 0–99,999,999 cents and
quantities 1–1,000 fit exactly. Explicit u64 query IDs precede the replacements
in both formats. For replacement `k`, cart ID comes from query `k % queries`.

This uses the existing experiment's round-robin event-routing contract, verified
outside timing for the input of every path. It is not a general format for
arbitrarily ordered, conflicting events. Queries are distinct and updated slots
within each cart are distinct, as before. Price/quantity values and slots change
between rounds, including boundary values. Cart counts and discount metadata
stay fixed. Host boundary checks cover slot/price/quantity encoding; every
changing output is checked exactly, including stale-cache detection.

Total upload bytes change from `8 × (queries + 4 × replacements)` to
`8 × (queries + replacements)`:

| Carts × lines | Replacements/cart | Legacy bytes | Compact bytes |
| --- | ---: | ---: | ---: |
| 4,096 × 512 | 16 | 2,129,920 | 557,056 |
| 65,536 × 2,048 | 1 | 2,621,440 | 1,048,576 |
| 65,536 × 2,048 | 16 | 34,078,720 | 8,912,896 |
| 65,536 × 2,048 | 64 | 134,742,016 | 34,078,720 |

## Comparison

Thirteen plain paths per shape: CPU grouped delta with four persistent workers;
GPU scan/delta using legacy pageable commands; legacy commands with pinned
staging; compact commands with reusable pageable staging; and compact commands
with reusable pinned staging. Compact pageable/pinned paths also have four-worker
encoder variants, retaining both GPU kernels. No updates or queries are omitted.

All implementations consume the same canonical legacy command slices. The CPU
already consumes this representation directly. GPU compaction reads and encodes
them **inside** the timer. Pinned legacy paths copy canonical commands into
reusable locked input inside the timer. Compact paths encode directly into
their reusable pageable/locked input. Query-ID copying is included. No prepacked
or preuploaded changing data is used for the headline numbers. Serial encoding/staging is retained. The `encode4` variants pack replacements
with the same persistent four-worker Rayon pool used by the CPU4 pricing
implementation. Query-ID copying remains serial. All variants run within the
same four-core allocation; encoding time includes worker dispatch/join.

Legacy pageable controls retain the original host `Gpu::run` calls. Their
unchanged GPU source is compiled alongside the compact kernels in a new
independent device crate/PTX. Compact scan changes update decoding and retains
the original scan algorithm. Compact delta retains one thread per cart and
serially applies that cart's patches while updating a cached subtotal.

Pinned transfers use reusable `LockedBuffer` allocations, asynchronous upload,
kernels and full asynchronous download in the same stream, then synchronize.
Buffers remain alive and immutable while copies are pending, and the stream
is joined on submission failures too. After the join, pinned output is copied
into a fresh owned `Vec`, inside timing, to preserve the output contract.
Pageable outputs also allocate and return a complete fresh vector. There is no
cross-batch pipeline, stale result or reduced-result shortcut.

Initial placement, cache initialization and host/device staging allocation are
recorded as `init_ms` outside batch timing. Trace generation, full-rescan oracle
work, input validation, CUDA context/module loading and exact comparisons are
outside timing, matching the previous experiment. Each variant/mode resets its
retained rows and replays all 58 changing steps: eight warmups and 50 timed
rounds, three repetitions with rotating/reversed variant order.

## Separate event diagnostics

The ten new GPU paths also replay the full trace with CUDA events. This gives
23 variant/mode pairs per shape and 16,008 checked rounds across four shapes:
803,217,408 exact output totals, plus 808 upstream Django Decimal cases checked
on five CPU and twelve GPU paths (17 implementations). A separate smoke covers
zero/one/sixteen replacements per cart at 64 carts × 32 lines.

Events are allocated outside timing. Markers on the same stream bracket upload,
kernels and (for pinned paths) download. Device intervals include any gaps while
the host submits work; particularly for synchronous pageable upload they do
not isolate DMA. They are separate replays and must not be added to plain-run
totals. `encoding_us` is host preparation time. `timer_tail_us` records the
wrapper/event-readout tail, included in the outer `total_us`, including in
plain-mode totals where only small wrapper overhead remains. Uninstrumented
legacy controls and CPU have zero encoding/event metrics, not a claim of zero
internal staging work. Pageable download is outside the device event markers
but remains inside complete batch wall time.

Means and sample standard deviations use three repetition means, not pooled
standard deviations. Every per-round value and checksum is retained. Publication
rejects missing/duplicate rounds, inconsistent checksums, wrong command/source/
result bytes or counts, invalid timings and incomplete upstream conformance.
Integers are read without floating-point checksum conversion. Source, PTX,
binary and oracle hashes, commands and hardware are in `environment.json`.

CPUs 64–67 and RTX 3090 device 0 match earlier runs. The host is shared; clocks,
NUMA placement, cache state and other activity are uncontrolled. Measurements
exclude SQL/HTTP, database commits, CDC, durable cache coherence, concurrent
writers, inserts/deletes and retries. This does not establish an application
speedup or the performance of an already-native compact input protocol.

## Reproduce

Use the [existing toolchain](../../README.md#reproduce). The independent compact
device crate has its own lockfile and PTX; building does not overwrite previous
measured binaries or PTX:

```sh
bash performance/django-cart/resident/scale/transport/build.sh
python3 performance/django-cart/resident/scale/transport/run.py --smoke --out /var/tmp/cart-transport-smoke
python3 performance/django-cart/resident/scale/transport/run.py
python3 -m unittest discover -s performance/django-cart/resident/scale/transport -p 'test_*.py'
python3 performance/site.py
```
