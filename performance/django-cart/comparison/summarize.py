"""Publish only a complete standard framework comparison with correctness gates."""
import csv
import itertools
import json
import math
from pathlib import Path
import statistics
import sys

from run import IMPLEMENTATIONS

METRICS = ['rps', 'p50_ms', 'p90_ms', 'p99_ms', 'errors', 'rss_peak_mb', 'cpu_peak_pct']


def summarize(root):
    root = Path(root)
    config = json.loads((root / 'environment.json').read_text())['config']
    if (set(config['variants']) != set(IMPLEMENTATIONS) or config['concurrency'] != [1, 16, 64, 256]
            or config['repeats'] != 3 or config['warmup'] != 10 or config['duration'] != 30
            or config['lines'] != 32 or config['carts'] != [4096, 65536]):
        raise ValueError('publication requires all six implementations and the standard dataset/timing/client matrix')
    gates = json.loads((root / 'conformance.json').read_text())
    for name in IMPLEMENTATIONS:
        gate = gates.get(name, {})
        if any(gate.get(k) != n for k, n in [('decimal_cases', 4146), ('freshness_updates', 2), ('error_status_cases', 3)]):
            raise ValueError(f'missing correctness gate: {name}')
    expected = set(itertools.product(IMPLEMENTATIONS, [f'total_{n}' for n in config['carts']], config['concurrency'], range(3)))
    points = {}
    with (root / 'points.csv').open() as f:
        for raw in csv.DictReader(f):
            row = {k: v if k in ('impl', 'scenario') else float(v) for k, v in raw.items()}
            if any(not math.isfinite(v) or v < 0 for v in row.values() if isinstance(v, float)):
                raise ValueError('invalid metric')
            if any(row[k] != int(row[k]) for k in ('concurrency', 'repeat', 'http_requests')):
                raise ValueError('fractional count')
            key = row['impl'], row['scenario'], int(row['concurrency']), int(row['repeat'])
            if key in points:
                raise ValueError(f'duplicate point: {key}')
            if row['errors'] or row['checks_failed'] or row['http_requests'] <= 0 or row['rps'] <= 0:
                raise ValueError(f'failed or empty measurement: {key}')
            if not row['p50_ms'] <= row['p90_ms'] <= row['p99_ms']:
                raise ValueError(f'invalid latency order: {key}')
            points[key] = row
    if set(points) != expected:
        raise ValueError(f'incomplete grid: missing={len(expected - set(points))}, extra={len(set(points) - expected)}')
    rows = []
    for name, carts, clients in itertools.product(IMPLEMENTATIONS, config['carts'], config['concurrency']):
        samples = [points[name, f'total_{carts}', clients, rep] for rep in range(3)]
        rows.append(dict(impl=name, scenario=f'total_{carts}', concurrency=clients, reps=3,
                         rps_stdev=statistics.stdev(r['rps'] for r in samples),
                         **{k: statistics.mean(r[k] for r in samples) for k in METRICS}))
    with (root / 'summary.csv').open('w') as f:
        writer = csv.DictWriter(f, fieldnames=['impl', 'scenario', 'concurrency', 'reps', 'rps_stdev', *METRICS])
        writer.writeheader()
        writer.writerows(rows)
    report = ['# Benchmark summary', '',
              'Fresh seed, 10 s warmup, 30 s measurement; means of three repetitions. '
              'One HTTP request returns one cart total from fresh PostgreSQL data. No request batching.', '',
              'Requests/s is k6 http_reqs.rate. Latencies are milliseconds. RSS is the peak sum '
              'across the server process tree in MiB. CPU percent is 100 for one core.', '',
              'The h5i engine executes complete per-cart tenants through its default transaction path. '
              'Cart pricing has differential checks, no application-specific Lean proof. '
              'CUDA uses one SQL/CUDA worker and fresh upload/download per request.', '']
    for carts in config['carts']:
        report += [f'## total_{carts}', '',
                   '| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |',
                   '| --- | --- | --- | --- | --- | --- | --- | --- | --- |']
        for r in rows:
            if r['scenario'] == f'total_{carts}':
                report.append(f"| {r['impl']} | {r['concurrency']} | {r['rps']:.1f} | {r['p50_ms']:.2f} | {r['p90_ms']:.2f} | {r['p99_ms']:.2f} | {r['errors']:.1f} | {r['rss_peak_mb']:.1f} | {r['cpu_peak_pct']:.1f} |")
        report.append('')
    report += ['See [method and reproduction](../../README.md). Raw samples and conformance logs stay local.', '']
    (root / 'summary.md').write_text('\n'.join(report))
    (root / 'summary.json').write_text(json.dumps({'config': config, 'rows': rows}, indent=2) + '\n')
    return rows


if __name__ == '__main__':
    summarize(sys.argv[1])
