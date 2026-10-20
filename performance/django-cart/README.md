# django-cart performance

An application-computation benchmark based on
[bmentges/django-cart](https://github.com/bmentges/django-cart), pinned to
**3.1.1**, commit `6b3daa26842c978b9520d479c4d33e3620e731a2`.
The upstream is a session-backed Django library, not a REST service. Four
experiments share its checked pricing contract:

- [HTTP/SQL batching](http/README.md): real HTTP requests, a bounded collection
  queue, fresh PostgreSQL reads, CPU/GPU calculation and JSON responses. Includes
  native SQL aggregate baselines in Go, Node.js and Rust, and GPU single/batch
  ablations. [Results](http/results/2026-10-19/summary.md) feed the normal dashboard.
- [Lines per cart](http/lines/README.md): fixed 4,096 carts, increasing each
  cart from 32 to 128, 512 and 2,048 lines. Compares SQL SUM, Go/Node/Rust CPU
  batching, four-worker CPU and scalar/cooperative CUDA with fresh transfers.
  [Results](http/lines/results/2026-10-19/summary.md) feed the normal dashboard.
- Snapshot pricing below: already-loaded cart snapshots, from one cart through
  large batches, with resident and upload-each GPU timings. These remain
  supplemental calculation measurements, separate from HTTP rankings.
- [Resident carts with updates](resident/README.md): retain the same rows on CPU
  and GPU, apply replacements, and immediately query updated totals. Includes
  incremental subtotals on both, command transfer and result download.
  [Results](resident/results/2026-10-19/summary.md) appear separately on the dashboard.
  The [larger-batch follow-up](resident/scale/README.md) adds parallel incremental
  CPU totals and scales to 65,536 carts and 64 replacements per cart.

These experiments do not measure the performance of a deployed Django application.

[GPU workload candidates](gpu-workloads.md) explains the measured residency
advantage and proposes bulk repricing and discount-scenario experiments with
CPU caching, update propagation and complete-operation costs included.

| Directory | Role |
| --- | --- |
| `upstream/` | Commit pin, reproducible SSH fetch, upstream MIT license |
| `rust-h5i-gpu/src/pricing.rs` | Allocation-free integer pricing shared by CPU and CUDA |
| `rust-h5i-gpu/backend-nvvm/` | Rust-CUDA device kernel and h5i NVVM launch shell |
| `go/`, `javascript/` | Independent Go and Node.js sequential baselines |
| `bench/check.py` | Independent oracle using the pinned upstream's actual methods |
| `bench/run.sh` | Correctness gates, Cross-language CPU/GPU measurement, environment capture |
| `bench/results/` | Snapshot timings, generated summary, host conditions |
| `http/` | Live request batching, SQL, load driver, correctness gates and HTTP results |

## Contract

Each snapshot has 0–32 lines, nonnegative two-decimal unit prices up to
999,999.99, quantity 1–1,000 per line, and an already-applied discount:
none, percentage (two decimal places), or fixed amount. Discount values are
bounded to 999,999.99. These are **benchmark bounds**, a subset of the upstream
model's range. Oversized or malformed snapshots produce an error.

Prices use integer cents. Percentage discounts retain four extra decimal
places until the final `ROUND_HALF_UP` rounding to cents. Discounts clamp to
the subtotal, including legacy percentages over 100%. Empty carts and zero
prices are supported. Tax and shipping use the upstream defaults, both zero.
Custom tax/shipping plugins are outside this contract.

`check.py` computes exact Decimal subtotals from the snapshot, supplies them
to the facade's summary cache, then calls the unmodified upstream
`Cart.total()`, including `discount_amount()`, `Discount.calculate_discount()`,
`tax()` and `shipping()`. It checks 4,146 deterministic/random cases against
the Rust, Go and Node.js implementations and emits the identical corpus for GPU
checking. Another 49 small cases exercise the actual ORM `Cart.summary()` and
`total()` in an in-memory SQLite database. Six invalid snapshots check error
handling; GPU checks also cover empty batches and 127/128/129-thread boundaries.

The measured Rust, Go, Node.js and GPU paths all sum the snapshot's price × quantity
lines and compute its final total. The oracle runner supplies correctness
evidence, not a Django performance score. In the real library, `summary()`
uses a database aggregate; replacing this with snapshot computation changes
the execution model. The snapshot measurements exclude session lookup, database
reads/writes, snapshot packing, HTTP, JSON, and discount eligibility or checkout
transactions. They do not establish a speedup over a Django deployment.

## Run

CPU correctness, with Python 3.12+, stable Rust, Go, Node.js, and GitHub SSH access:

```sh
performance/django-cart/bench/run.sh --cpu-only
```

The runner pins Python dependencies in a venv under `/var/tmp`, fetches the
upstream commit, and builds/checks the CPU code. The source checkout, venv and
fixture paths can be overridden with `DJANGO_CART_SOURCE`, `DJANGO_CART_VENV`
and `DJANGO_CART_FIXTURES`. Set `GO_BIN` and `NODE_BIN` if they are outside PATH.

GPU additionally needs an NVIDIA GPU, CUDA 12.6, and the existing Rust-CUDA
nightly/backend setup shared with linkding:

```sh
performance/linkding/rust-h5i-gpu/backend-nvvm/setup.sh # once, if absent
taskset -c 64-79 performance/django-cart/bench/run.sh
# Optional output directory:
taskset -c 64-79 performance/django-cart/bench/run.sh /var/tmp/cart-results
```

The device target is `compute_86` (RTX 3090). `CUDA_VISIBLE_DEVICES` defaults
to 0. The h5i launch shell is pinned to
`0d52512471d09f13db79230a05ea9387ef18f637`; Rust-CUDA is pinned to
`3a82c35a7196731fb60eebdac2a40d2b1bf0ba95`. Commit both Cargo lockfiles:
Rust-CUDA's broad glam constraint requires the compatible locked 0.30.10.

The new pricing core has differential tests, **no Lean proof**. h5i supplies
the NVVM context/module/stream shell; this experiment does not run requests
through the h5i-app PostgreSQL engine.

## Measurement

For each of 1, 8 and 32 lines per cart, run batches of 1, 16, 256, 4,096,
65,536, 262,144 and 1,048,576 carts. All implementations process the same immutable snapshots and
return the full ordered vector of totals. Each measured repetition checks its
last output vector against the sequential CPU reference.
Eight untimed warmup passes precede each shape. Three repetitions each average 100 iterations for smaller batches and 10 for
batches of at least 4,096. The summary takes the median of those three means.

- **Go / Node.js:** single-thread calculation and output allocation, independently
  implemented. Node.js uses Float64Array and quotient/remainder arithmetic to
  preserve exact cents even when a scaled subtotal would exceed 2**53; it does
  not pay per-line BigInt overhead. Runtime GC is included; packing is excluded.
- **CPU 1:** optimized Rust, sequential calculation and output allocation.
- **CPU 16:** the same function on a persistent 16-thread Rayon pool, including
  scheduling, output allocation and collection. Pool creation is excluded.
- **GPU resident:** reuse uploaded snapshots and device output buffers; include
  launch, synchronization, full result download, allocation and error validation.
- **GPU upload each:** allocate and upload the full fixed-width snapshots on
  each call (including host transpose in SoA mode), then calculate, download, validate and free the device buffers.

The default GPU mode is **SoA**: host upload transposes rows into columns so
adjacent GPU threads read adjacent words. This transpose is timed in the
initial upload and every upload-each call. Resident timing excludes it because
that data is reused. `CART_LAYOUT=aos` selects the original row layout for an
ablation. CPU baselines keep their contiguous row layout. Both GPU kernels use
the same validated pricing function and pass the same upstream fixture corpus.

The 67-word snapshot reserves all 32 line slots even for small carts. Upload
costs therefore reflect this layout. Residency is a workload assumption:
changing snapshots must be uploaded again. This is not a live cache and has
no write invalidation protocol. Context/module initialization, warmup upload,
packing, cost and power are excluded. `upload_ms` records the initial upload
separately. Measurements run in the fixed order CPU 1, CPU 16, resident GPU,
upload-each GPU on a shared host; clocks and NUMA placement are uncontrolled.

See [the SoA results](bench/results/2026-10-19-scale-soa/summary.md)
and [original row-layout scaling](bench/results/2026-10-19-scale/summary.md).
Only aggregate summaries (`summary.json`, `summary.csv`, `summary.md`) and the
placement report are committed. Raw samples, logs, environment dumps and
validation output stay local and are ignored by Git. The summarizer
rejects incomplete grids, duplicate points and cross-language checksum or
iteration mismatches. Each repetition validates its full last result vector;
checksums additionally check that the languages use matching generated data.
The dashboard uses the fastest measured CPU baseline per shape for its ratio.
Results are calculation microbenchmarks, **not application query batching**.

```sh
python3 performance/django-cart/bench/summarize.py \
  performance/django-cart/bench/results/2026-10-19-scale-soa/points.csv
```

The [resident cross-language follow-up](resident/languages/README.md) measures Go,
JavaScript, CPython and NumPy on the same retained data and changing updates as
Rust/GPU, with complete output. GPU references are explicitly labelled when
fresh measurements are prevented by external GPU workloads.
