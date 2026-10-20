"""Publish only a complete, correct, accounted line-count experiment."""
import csv
import itertools
import json
import math
from pathlib import Path
import statistics
import sys

METRICS=['rps','p50_ms','p90_ms','p99_ms','errors','rss_peak_mb','cpu_peak_pct','mean_batch','mean_queue_wait_ms','sql_queries','gpu_launches','http_requests','batches']
PHASES=['sql_fetch_ms_per_batch','pack_ms_per_batch','compute_ms_per_batch']
EXPECTED_CASES={32:166,128:190,512:214,2048:238}

def summarize(root):
 root=Path(root);config=json.loads((root/'environment.json').read_text())['config'];conformance=json.loads((root/'conformance.json').read_text())
 expected=set(itertools.product(config['variants'],config['line_counts'],config['concurrency'],range(config['repeats'])))
 points={}
 for raw in csv.DictReader((root/'points.csv').read_text().splitlines()):
  row={k:(v if k in ('impl','scenario') else (None if v=='' else float(v))) for k,v in raw.items()}
  key=(row['impl'],int(row['lines']),int(row['concurrency']),int(row['repeat']))
  if key in points:raise ValueError(f'duplicate point: {key}')
  if row['scenario']!=f"lines_{int(row['lines'])}" or row['carts']!=config['dataset_carts']:raise ValueError(f'dataset mismatch: {key}')
  if any(not math.isfinite(v) or v<0 for v in row.values() if isinstance(v,float)):raise ValueError(f'invalid metric: {key}')
  if any(row[k] is None for k in METRICS):raise ValueError(f'missing metric: {key}')
  if row['errors'] or row['checks_failed']:raise ValueError(f'failed responses: {key}')
  if row['http_requests']<=0 or row['batches']<=0:raise ValueError(f'empty point: {key}')
  if row['http_requests']!=row['server_requests'] or row['sql_queries']!=row['batches']:raise ValueError(f'accounting: {key}')
  if not math.isclose(row['mean_batch'],row['http_requests']/row['batches']):raise ValueError(f'batch accounting: {key}')
  if row['cart_rows']>row['http_requests'] or row['cart_rows']<=0:raise ValueError(f'cart accounting: {key}')
  if ('gpu' in row['impl'] and row['gpu_launches']!=row['batches']) or ('gpu' not in row['impl'] and row['gpu_launches']!=0):raise ValueError(f'GPU accounting: {key}')
  if not 1<=row['max_batch_since_start']<=(1 if row['impl'].endswith('sql') else 256):raise ValueError(f'batch limit: {key}')
  if row['impl'].endswith('sql') and row['batches']!=row['http_requests']:raise ValueError(f'SQL request accounting: {key}')
  instrumented=row['impl'].startswith('rust-') and not row['impl'].endswith('sql')
  if any((row[k] is not None)!=instrumented for k in PHASES):raise ValueError(f'phase coverage: {key}')
  points[key]=row
 if set(points)!=expected:raise ValueError(f'incomplete grid: missing={len(expected-set(points))}, extra={len(set(points)-expected)}')
 for name,cap in itertools.product(config['variants'],config['line_counts']):
  gate=conformance[f'{cap}:{name}']
  if gate['decimal_cases']!=EXPECTED_CASES[cap] or gate['orm_cases']!=4 or gate['freshness_updates']!=2 or gate['error_status_cases']!=3:raise ValueError(f'correctness gate: {cap}:{name}')
 rows=[]
 for name,cap,clients in itertools.product(config['variants'],config['line_counts'],config['concurrency']):
  samples=[points[name,cap,clients,r] for r in range(config['repeats'])]
  rows.append(dict(impl=name,scenario=f'lines_{cap}',lines=cap,carts=config['dataset_carts'],concurrency=clients,reps=len(samples),rps_stdev=statistics.stdev(r['rps'] for r in samples) if len(samples)>1 else 0,**{k:statistics.mean(r[k] for r in samples) if samples[0][k] is not None else '' for k in [*METRICS,*PHASES]}))
 with (root/'summary.csv').open('w') as f:
  w=csv.DictWriter(f,fieldnames=rows[0]);w.writeheader();w.writerows(rows)
 measured=sum(int(r['http_requests']) for r in points.values());lookup={(r['impl'],r['lines'],r['concurrency']):r for r in rows}
 report=['# django-cart: increasing work per cart','',f"Fixed **{config['dataset_carts']:,} carts**; {', '.join(map(str,config['line_counts']))} lines/cart. {len(points)} points, {config['repeats']} repetitions × {config['duration']} s after {config['warmup']} s warmup. **{measured:,} responses checked; zero HTTP or exact-value failures.**",'','Each individual HTTP request returns one cart total. Batches coalesce requests into one SQL read; CUDA uploads fresh input and downloads every total. CPU and GPU use identical prices, quantities and discounts. Native SQL baselines keep SUM in PostgreSQL. No Django deployment speedup is measured.','', '| Lines/cart | Line rows | Clients | Best SQL req/s | Best CPU batch req/s | GPU scalar req/s | GPU cooperative req/s | Best GPU / CPU | Best GPU / SQL |','| --- | --- | --- | --- | --- | --- | --- | --- | --- |']
 for cap,clients in itertools.product(config['line_counts'],config['concurrency']):
  def best(names):return max((lookup[n,cap,clients] for n in names if (n,cap,clients) in lookup),key=lambda r:r['rps'])
  sql=best(['go-sql','javascript-sql','rust-sql']);cpu=best(['go-batch','javascript-batch','rust-cpu-batch','rust-cpu-parallel']);gpu=best(['rust-gpu-batch','rust-gpu-cooperative'])
  scalar=lookup.get(('rust-gpu-batch',cap,clients));coop=lookup.get(('rust-gpu-cooperative',cap,clients))
  report.append(f"| {cap} | {cap*config['dataset_carts']:,} | {clients} | {sql['rps']:.0f} ({sql['impl']}) | {cpu['rps']:.0f} ({cpu['impl']}) | {scalar['rps']:.0f} | {coop['rps']:.0f} | {gpu['rps']/cpu['rps']:.2f}× | {gpu['rps']/sql['rps']:.2f}× |")
 report+=['','Best-of ratios above select implementations within each measured shape; they are descriptive, not a preselected production policy. See all repetitions and variability below.','','## Where the time goes','','The following uses the serial Rust CPU and cooperative GPU, at the highest measured concurrency. Each phase is amortized over completed HTTP requests within a repetition, then averaged across repetitions. The CPU compute share covers only these three measured phases; queueing, HTTP and reply handling are excluded.','','| Lines | CPU fetch µs/request | CPU pack µs/request | CPU compute µs/request | CPU compute share | GPU fetch µs/request | GPU pack µs/request | GPU complete compute µs/request |','| --- | --- | --- | --- | --- | --- | --- | --- |']
 for cap in config['line_counts']:
  phase=[]
  for name in ['rust-cpu-batch','rust-gpu-cooperative']:
   samples=[points[name,cap,max(config['concurrency']),r] for r in range(config['repeats'])]
   phase.append([statistics.mean(r[k]*r['batches']/r['http_requests']*1000 for r in samples) for k in PHASES])
  cpu,gpu=phase
  report.append(f"| {cap} | {cpu[0]:.3f} | {cpu[1]:.3f} | {cpu[2]:.3f} | {cpu[2]/sum(cpu)*100:.2f}% | {gpu[0]:.3f} | {gpu[1]:.3f} | {gpu[2]:.3f} |")
 report+=['','GPU compute includes allocation and transfers, not just arithmetic. Increasing line count also increases database work, decoded rows and transferred bytes. These measurements distinguish a larger input from a computation bottleneck.','','## All implementations','','| Lines | Clients | Implementation | req/s ± stdev | p99 ms | Requests/batch | Queue ms | Fetch ms/batch | Pack ms/batch | Compute ms/batch |','| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |']
 for r in sorted(rows,key=lambda r:(r['lines'],r['concurrency'],-r['rps'])):
  phase=['—' if r[k]=='' else f'{r[k]:.4f}' for k in PHASES]
  report.append(f"| {r['lines']} | {r['concurrency']} | {r['impl']} | {r['rps']:.0f} ± {r['rps_stdev']:.0f} | {r['p99_ms']:.3f} | {r['mean_batch']:.2f} | {r['mean_queue_wait_ms']:.3f} | {' | '.join(phase)} |")
 report+=['','Rust batch phases are means per SQL batch. Fetch includes PostgreSQL execution, network transfer and sqlx decoding; pack includes extracting decoded fields and constructing snapshots. Compute includes CPU calculation, or GPU transpose where needed, allocation, upload, launch, synchronization, full result download and validation. These phases exclude queueing, HTTP and map/reply overhead; they are not kernel-only timings. Other implementations have no phase instrumentation (—). Percentiles and per-batch means are averaged across repetitions.','', 'The scalar GPU launches at most two 128-thread blocks at the configured 256-request maximum. Cooperative launches one 32-thread block per distinct cart. This experiment compares these implementations, not an optimally tuned GPU bound.', '', 'Native SQL uses 16 connections; each batched variant has one active SQL worker. Every server, PostgreSQL and k6 receives four CPU cores on the same shared host. Rust parallel uses four Rayon workers within the same server CPU allocation. Warm database conditions, uncontrolled clocks/NUMA and short runs limit generalization.','', '[GPU placement diagnostic](placement.md) · [Method and reproduction](../../README.md) · [Per-repetition CSV](points.csv) · [Correctness](conformance.json) · [Environment and source hashes](environment.json)','']
 (root/'summary.md').write_text('\n'.join(report))
 print(f'{len(points)} verified points, {measured:,} exact responses -> {root}/summary.csv')
 return rows

if __name__=='__main__':summarize(sys.argv[1] if len(sys.argv)>1 else Path(__file__).parent/'results/2026-10-19')
