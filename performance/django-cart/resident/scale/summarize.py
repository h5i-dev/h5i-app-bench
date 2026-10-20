"""Validate and publish the larger resident-update sweep."""
import csv
import itertools
import json
import math
from pathlib import Path
import statistics
import sys

IMPLS=['cpu-scan-1','cpu-scan-4','cpu-delta','cpu-delta-grouped','cpu-delta-4','gpu-scan','gpu-delta']
CAPS=[512,2048]
POPULATIONS=[4096,16384,65536]
FACTORS=[1,16,64]
METRICS=['mean_us','p50_us','p99_us','init_ms']

def summarize(root):
    root=Path(root)
    gates=json.loads((root/'conformance.json').read_text())
    for cap,count in zip([32,128,512,2048],[166,190,214,238]):
        if gates[str(cap)] != dict(decimal_cases=count,variants=7): raise ValueError('missing upstream gate')
    expected=set(itertools.product(IMPLS,CAPS,POPULATIONS,FACTORS,range(3)))
    seen={}; checksums={}
    with (root/'points.csv').open() as f:
        for raw in csv.DictReader(f):
            row={k: (v if k=='impl' else float(v) if k in METRICS else int(v)) for k,v in raw.items()}
            if any(not math.isfinite(v) or v<0 for k,v in row.items() if k!='impl'): raise ValueError('invalid metric')
            n=row['carts']; u=row['updates'];cap=row['lines']
            key=(row['impl'],cap,n,u//n if n else -1,row['repeat'])
            if key in seen or key not in expected or u%n: raise ValueError('duplicate or unexpected point')
            if any(row[k]<=0 for k in METRICS) or row['p99_us']<row['p50_us']: raise ValueError('invalid timing')
            if (row['queries'],row['iterations'],row['checked_totals'],row['input_bytes'],row['command_bytes'],row['result_bytes']) != (n,50,n*58,n*(2*cap+3)*8,(n+u*4)*8,n*8): raise ValueError('incorrect accounting')
            shape=(cap,n,u); checksums.setdefault(shape,row['checksum'])
            if checksums[shape]!=row['checksum']: raise ValueError('mutation mismatch')
            seen[key]=row
    if set(seen)!=expected: raise ValueError(f'incomplete grid: {len(seen)}/{len(expected)}')
    points=[]; rows=[]
    for cap,n,factor in itertools.product(CAPS,POPULATIONS,FACTORS):
        timings={}
        for impl in IMPLS:
            samples=[seen[impl,cap,n,factor,rep] for rep in range(3)]
            t={k:statistics.mean(s[k] for s in samples) for k in METRICS}
            t['stdev_us']=statistics.stdev(s['mean_us'] for s in samples)
            timings[impl]=t
            rows.append(dict(impl=impl,lines=cap,carts=n,queries=n,updates=n*factor,reps=3,**t))
        cpu=min((i for i in IMPLS if i.startswith('cpu')),key=lambda i:timings[i]['mean_us'])
        gpu=min((i for i in IMPLS if i.startswith('gpu')),key=lambda i:timings[i]['mean_us'])
        ratio=timings[cpu]['mean_us']/timings[gpu]['mean_us']
        points.append(dict(lines=cap,carts=n,queries=n,updates=n*factor,factor=factor,timings=timings,best_cpu=cpu,best_gpu=gpu,ratio=ratio))
    with (root/'summary.csv').open('w') as f:
        w=csv.DictWriter(f,fieldnames=rows[0]); w.writeheader();w.writerows(rows)
    checked=sum(r['checked_totals'] for r in seen.values())
    data=dict(measured='2026-10-19',checked_totals=checked,measurement_points=len(seen),implementations=IMPLS,points=points)
    (root/'summary.json').write_text(json.dumps(data,indent=1)+'\n')
    report=['# Resident cart population/update scaling','',f'**{len(seen)} verified points; {checked:,} exact totals checked.** Seven implementations, three repeats of 50 measured rounds after eight warmups. All seven pass the 808-case upstream Decimal corpus. Every warmup and timed output is checked against a separate full-rescan oracle outside the timer.','',
        'CPU/GPU ratios include the fastest measured implementation on each side, including grouped single/four-thread CPU incremental totals. Above 1 favors GPU. GPU time includes update/ID upload, kernels, synchronization, full download and error checks. Initial placement is separate. Calculation timings, not HTTP throughput.','',
        '| Lines | Carts/queries | Updates/cart | Best CPU | CPU µs | Best GPU | GPU µs | CPU/GPU |','| --- | --- | --- | --- | ---: | --- | ---: | ---: |']
    for p in points:
        t=p['timings']; c=p['best_cpu']; g=p['best_gpu']
        report.append(f"| {p['lines']} | {p['carts']} | {p['factor']} | {c} | {t[c]['mean_us']:.3f} | {g} | {t[g]['mean_us']:.3f} | {p['ratio']:.2f}× |")
    report += ['', '## Scope and limits','',
        '- All population carts are queried in every batch, in a fixed permuted order. Values and patched slots change every round. Cardinalities and discount metadata remain fixed. Valid, normalized replacements are round-robin across carts; patched slots and query IDs are unique within each round. No updates are stale in the next query.',
        '- CPU delta preserves the original event-order implementation. CPU delta grouped applies all patches for a cart together, retaining its subtotal in a local variable; CPU delta 4 uses the same cart-grouped algorithm with four persistent Rayon workers. This avoids comparing the GPU only to a weaker CPU update order. Both retain rows, subtotals and final totals.',
        '- Each variant independently retains the complete population. Large traces and independent oracle state are built outside timing. CPUs 64–67 and RTX 3090 device 0; synchronous batches with no transfer/launch overlap. Variant order rotates/reverses. Shared-host activity, clock, NUMA and cache effects are uncontrolled. Three-repeat sample variability and iteration p50/p99 are in CSV/JSON; averaged percentiles are not pooled. With 50 iterations, the reported p99 is the maximum round.',
        '- Initial allocation/copy/upload/subtotal setup is separately recorded as init_ms; generation, CUDA context/module loading, trace validation and oracle comparisons are excluded. The update/query means do not amortize startup or rebuilds.',
        '- No HTTP, database commit, CDC delivery, durable recovery, concurrent writers, insertion/deletion, retries or cross-process coherence. This tests line-price/quantity replacement under the existing total contract. Go/JavaScript are not measured in this resident sweep. These are measured implementations, not optimal CPU/GPU bounds.','',
        '[Method](../../README.md) · [All implementation timings](summary.csv) · [Raw repetitions](points.csv) · [Upstream checks](conformance.json) · [Environment/hashes](environment.json)','']
    (root/'summary.md').write_text('\n'.join(report))
    print(f'{len(seen)} verified scale points; {checked:,} exact totals -> {root}/summary.md')
    return data

if __name__=='__main__': summarize(sys.argv[1])
