"""Validate the complete resident-update matrix and publish calculation timings."""
import csv
import itertools
import json
import math
from pathlib import Path
import statistics
import sys

IMPLS = ['cpu-scan-1', 'cpu-scan-4', 'cpu-delta', 'gpu-scan', 'gpu-delta']
CAPS = [32, 128, 512, 2048]
QUERIES = [8, 128, 256, 4096]
METRICS = ['mean_us', 'p50_us', 'p99_us', 'init_ms']


def summarize(root):
    root = Path(root)
    gates = json.loads((root / 'conformance.json').read_text())
    for cap, count in zip(CAPS, [166, 190, 214, 238]):
        if gates[str(cap)] != dict(decimal_cases=count, variants=5):
            raise ValueError('missing upstream correctness gate')
    expected = {(impl, cap, n, u, rep) for impl, cap, n, rep in itertools.product(IMPLS, CAPS, QUERIES, range(3)) for u in [0, 1, n, n*16]}
    seen = {}
    checksums = {}
    for raw in csv.DictReader((root / 'points.csv').open()):
        row = {k: (v if k == 'impl' else float(v)) for k, v in raw.items()}
        if any(not math.isfinite(v) or v < 0 for k, v in row.items() if k != 'impl'):
            raise ValueError('invalid metric')
        key = (row['impl'], row['lines'], row['queries'], row['updates'], row['repeat'])
        if key in seen or key not in expected:
            raise ValueError('duplicate or unexpected point')
        _, cap, n, u, _ = key
        if any(row[k] <= 0 for k in METRICS) or row['p99_us'] < row['p50_us']:
            raise ValueError('invalid timing')
        if (row['carts'], row['iterations'], row['checked_totals'], row['input_bytes'], row['command_bytes'], row['result_bytes']) != (4096, 100, n*108, 4096*(2*cap+3)*8, (n+4*u)*8, n*8):
            raise ValueError('incorrect dataset or accounting')
        shape = (cap, n, u)
        checksums.setdefault(shape, raw['checksum'])
        if checksums[shape] != raw['checksum']:
            raise ValueError('cross-implementation mutation result mismatch')
        seen[key] = row
    if set(seen) != expected:
        raise ValueError(f'incomplete resident grid: {len(seen)}/{len(expected)}')
    rows = []
    points = []
    for cap, n in itertools.product(CAPS, QUERIES):
        for profile, u in zip(['none', 'one', 'per-query', 'sixteen-per-query'], [0, 1, n, n*16]):
            measurements = {}
            for impl in IMPLS:
                samples = [seen[impl, cap, n, u, rep] for rep in range(3)]
                values = {k: statistics.mean(s[k] for s in samples) for k in METRICS}
                values['stdev_us'] = statistics.stdev(s['mean_us'] for s in samples)
                measurements[impl] = values
                rows.append(dict(impl=impl, lines=cap, carts=4096, queries=n, updates=u, profile=profile, reps=3, **values))
            points.append(dict(lines=cap, queries=n, updates=u, profile=profile, timings=measurements))
    with (root / 'summary.csv').open('w') as f:
        writer = csv.DictWriter(f, fieldnames=rows[0])
        writer.writeheader(); writer.writerows(rows)
    checked = sum(int(r['checked_totals']) for r in seen.values())
    data = dict(measured='2026-10-19', checked_totals=checked, implementations=IMPLS, points=points)
    (root / 'summary.json').write_text(json.dumps(data, indent=1) + '\n')
    report = ['# Resident cart data with visible updates', '',
              f'**{len(seen)} verified points; {checked:,} exact totals checked**, including eight warmups per point. Fixed 4,096 carts; 32/128/512/2,048 lines; 8/128/256/4,096 queries per batch; zero/one/one-per-query/sixteen-per-query line replacements before each query batch. Three repetitions of 100 changing rounds. All five implementations also pass the 808-case upstream Decimal corpus.', '',
              'These are calculation timings, not HTTP request rates. Data is retained on each backend; each round applies the same replacement events, then returns all requested totals from the updated state. Query IDs rotate across the population. CPU/GPU incremental versions maintain exact subtotals and cached final totals. Both must observe updates in the very next query. No stale results or delayed propagation are allowed within this process.', '',
              '## Mean microseconds per update-and-query batch', '',
              'Scan compares the fastest measured one/four-worker CPU full rescan with GPU full rescan. Best CPU/GPU also allows cached incremental totals on both. Ratios above 1 favor GPU. Timings are means of three repetition means; per-repetition variability is in the CSV/JSON.', '',
              '| Lines | Queries | Updates | CPU scan 1T µs | CPU scan 4T µs | CPU delta µs | GPU scan µs | GPU delta µs | Scan CPU/GPU | Best CPU/GPU |',
              '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |']
    for point in points:
        t = point['timings']; us = [t[i]['mean_us'] for i in IMPLS]
        scan = min(us[:2])/us[3]; best = min(us[:3])/min(us[3:])
        report.append(f"| {point['lines']} | {point['queries']} | {point['updates']} | " + ' | '.join(f'{v:.3f}' for v in us) + f' | {scan:.2f}× | {best:.2f}× |')
    report += ['', '## Interpretation and limits', '',
               '- GPU wall time includes the fresh query-ID/update-command upload to reusable buffers, ordered mutation/query kernels, stream synchronization, complete result download and error validation. It is not kernel-only time. CPU wall time includes event application, query calculation/gather and result allocation. Exact-result comparisons and the independent full-rescan oracle run outside the timer for both.',
               '- CPU scan 4T uses four persistent Rayon workers. GPU scan uses one 32-thread block per queried cart. GPU delta uses one thread per queried cart, applying that cart\'s patches serially and updating its subtotal once. Both delta paths avoid rescanning lines; CPU delta needs no worker dispatch. These are implementations, not optimal hardware bounds.',
               '- Initial population generation, CUDA context/module setup, trace generation and event validation are excluded. `init_ms` separately measures owned CPU placement or GPU allocation/upload; delta initialization includes a CPU subtotal pass for either backend. Every variant keeps the full 4,096-cart population, even for a small query batch. Read-only final totals may be cached on CPU and GPU.',
               '- Replacement events have validated IDs, slots, prices and quantities. Within a batch each query cart is unique and each patched slot unique; patches are ordered round-robin across queried carts. Prices/quantities change each round, including maximum-bound values. Cart line counts and discount metadata are fixed. Inserts, deletes, retries, concurrent writers and conflict handling are not covered.',
               '- This experiment starts from a normalized in-process event stream. It does not measure database commit, CDC delivery, durable recovery, cross-process cache coherence or HTTP queueing. It establishes immediate visibility only within this single process. Adding those costs may change the result.',
               '- CPU and GPU each use CPUs 64–67, GPU device 0 (RTX 3090). Variant order rotates and reverses across repetitions; workload order is fixed. Shared host activity, clocks, NUMA placement and cache effects are uncontrolled. Data is repeatedly accessed, but query IDs and event values change. Short rounds are sensitive to timer/launch overhead.', '',
               '[Method and reproduction](../../README.md) · [Per-repetition CSV](points.csv) · [Summary CSV](summary.csv) · [Upstream conformance](conformance.json) · [Environment and hashes](environment.json)', '']
    (root / 'summary.md').write_text('\n'.join(report))
    print(f'{len(seen)} verified resident points, {checked:,} exact totals -> {root}/summary.md')
    return data


if __name__ == '__main__':
    summarize(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).parent / 'results/2026-10-19')
