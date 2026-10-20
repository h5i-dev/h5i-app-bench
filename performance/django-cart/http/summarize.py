"""Validate a complete, error-free HTTP run and publish repetition means."""
import csv
import itertools
import json
import math
from pathlib import Path
import statistics
import sys

METRICS=['rps','p50_ms','p90_ms','p99_ms','errors','rss_peak_mb','cpu_peak_pct','mean_batch','mean_queue_wait_ms','sql_queries','gpu_launches','http_requests','batches']


def summarize(root):
    root=Path(root)
    config=json.loads((root/'environment.json').read_text())['config']
    conformance=json.loads((root/'conformance.json').read_text())
    expected=set(itertools.product(config['variants'],[f'total_{n}' for n in config['carts']],config['concurrency'],range(config['repeats'])))
    points={}
    for raw in csv.DictReader((root/'points.csv').read_text().splitlines()):
        row={k:(v if k in ('impl','scenario') else float(v)) for k,v in raw.items()}
        key=(row['impl'],row['scenario'],int(row['concurrency']),int(row['repeat']))
        if key in points:raise ValueError(f'duplicate point: {key}')
        if any(not math.isfinite(v) or v<0 for v in row.values() if isinstance(v,float)):raise ValueError(f'invalid metric: {key}')
        if row['errors'] or row['checks_failed']:raise ValueError(f'failed requests: {key}')
        if row['http_requests']!=row['server_requests']:raise ValueError(f'HTTP accounting: {key}')
        if row['sql_queries']!=row['batches']:raise ValueError(f'SQL accounting: {key}')
        if row['http_requests']<=0 or row['batches']<=0:raise ValueError(f'empty measurement: {key}')
        if not math.isclose(row['mean_batch'],row['http_requests']/row['batches']):raise ValueError(f'batch accounting: {key}')
        if 'gpu' in row['impl'] and row['gpu_launches']!=row['batches']:raise ValueError(f'GPU accounting: {key}')
        if 'gpu' not in row['impl'] and row['gpu_launches']!=0:raise ValueError(f'unexpected GPU: {key}')
        if row['max_batch_since_start']>(1 if row['impl'].endswith('sql') or row['impl'].endswith('single') else 256):raise ValueError(f'batch limit: {key}')
        points[key]=row
    if set(points)!=expected:raise ValueError(f'incomplete grid: missing={len(expected-set(points))}, extra={len(set(points)-expected)}')
    for name in config['variants']:
        if conformance[name]['decimal_cases']!=4146 or conformance[name]['freshness_updates']!=2 or conformance[name]['error_status_cases']!=3:raise ValueError(f'missing correctness gate: {name}')
    rows=[]
    for name,n,clients in itertools.product(config['variants'],config['carts'],config['concurrency']):
        samples=[points[name,f'total_{n}',clients,r] for r in range(config['repeats'])]
        rows.append(dict(impl=name,scenario=f'total_{n}',concurrency=clients,reps=len(samples),rps_stdev=statistics.stdev(r['rps'] for r in samples) if len(samples)>1 else 0,**{k:statistics.mean(r[k] for r in samples) for k in METRICS}))
    with (root/'summary.csv').open('w') as f:
        writer=csv.DictWriter(f,fieldnames=['impl','scenario','concurrency','reps','rps_stdev',*METRICS]);writer.writeheader();writer.writerows(rows)
    lookup={(r['impl'],r['scenario'],r['concurrency']):r for r in rows}
    largest=f"total_{max(config['carts'])}";clients=max(config['concurrency'])
    highlights=[]
    if all((name,largest,clients) in lookup for name in ('rust-gpu-batch','rust-cpu-batch','rust-gpu-single','go-sql','javascript-sql','rust-sql')):
        gpu=lookup['rust-gpu-batch',largest,clients];cpu=lookup['rust-cpu-batch',largest,clients]
        single=lookup['rust-gpu-single',largest,clients]
        best=max((lookup[n,largest,clients] for n in ('go-sql','javascript-sql','rust-sql')),key=lambda r:r['rps'])
        highlights=[f"At {max(config['carts']):,} carts and {clients} clients, batched GPU throughput is **{gpu['rps']/cpu['rps']:.2f}× the matched Rust CPU batch**, **{gpu['rps']/best['rps']:.2f}× the fastest native SQL baseline ({best['impl']})**, and **{gpu['rps']/single['rps']:.2f}× GPU without batching**. Its observed batch averages {gpu['mean_batch']:.2f} requests; mean queue wait is {gpu['mean_queue_wait_ms']:.3f} ms and p99 HTTP latency is {gpu['p99_ms']:.3f} ms.", '']
        if len(config['carts'])>1:
            small=lookup['rust-gpu-batch',f"total_{min(config['carts'])}",clients]
            highlights += [f"Increasing the database from {min(config['carts']):,} to {max(config['carts']):,} carts at {clients} clients changes GPU batch throughput from {small['rps']:.0f} to {gpu['rps']:.0f} req/s ({gpu['rps']/small['rps']:.2f}×). Database size and GPU batch size are distinct; only collected requests are uploaded.", '']
    report=['# django-cart HTTP batching evaluation','',*highlights,f"{len(points)} points; {config['repeats']} repetitions × {config['duration']} s after {config['warmup']} s warmup. {config['lines']} lines/cart. {sum(int(r['http_requests']) for r in points.values()):,} measured responses checked for exact cents; zero errors.",'','HTTP → queue → fresh PostgreSQL rows → CPU/CUDA → JSON. No GPU input residency between batches. Native SQL baselines perform the upstream-style SUM in PostgreSQL. These are read-only adapters, not a full Django deployment.','', '| Carts | Clients | Implementation | req/s ± stdev | p99 ms | Mean batch | Queue ms | SQL/run | GPU launches/run |','| --- | --- | --- | --- | --- | --- | --- | --- | --- |']
    for r in sorted(rows,key=lambda r:(int(r['scenario'].split('_')[1]),r['concurrency'],-r['rps'])):
        report.append(f"| {r['scenario'].split('_')[1]} | {r['concurrency']} | {r['impl']} | {r['rps']:.0f} ± {r['rps_stdev']:.0f} | {r['p99_ms']:.3f} | {r['mean_batch']:.2f} | {r['mean_queue_wait_ms']:.3f} | {r['sql_queries']:.0f} | {r['gpu_launches']:.0f} |")
    report+=['','Latency percentiles and counters are means across repetitions. Mean batch is requests / SQL calls per repetition; includes duplicate-ID coalescing. Counts reflect the entire measured k6 run, including completion after the duration. RPS uses k6 elapsed time. CPU peak and RSS cover only the server process; PostgreSQL has a separate four-core allocation. See [method and limitations](../../README.md), [raw points](points.csv), [correctness](conformance.json) and [environment](environment.json).','']
    (root/'summary.md').write_text('\n'.join(report))
    print(f'{len(points)} checked points -> {root}/summary.csv')
    return rows


if __name__=='__main__':summarize(sys.argv[1] if len(sys.argv)>1 else Path(__file__).parent/'results/2026-10-19')
