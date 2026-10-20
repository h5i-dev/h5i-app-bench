"""Reject incomplete grids and mismatched exact checksums before publishing."""
import csv
import itertools
import json
import math
from pathlib import Path
import statistics

SHAPES=[(4096,512,16),(65536,2048,1),(65536,2048,16),(65536,2048,64)]
SMOKE=[(64,32,0),(64,32,1),(64,32,16)]
VARIANTS=['rust-1','rust-4','go-1','go-4','javascript-1','javascript-4','python-1','python-4','python-numpy','gpu-scan-pageable','gpu-delta-pageable','gpu-scan-compact-pinned-encode4','gpu-delta-compact-pinned-encode4']

def summarize(root,smoke=False,phase=None):
    root=Path(root);shapes=SMOKE if smoke else SHAPES
    variants=[v for v in VARIANTS if phase!='cpu' or not v.startswith('gpu')]
    suffix='-cpu' if phase=='cpu' else ''
    gates=json.loads((root/f'conformance{suffix}.json').read_text());required={str(c):n for c,n in [(32,166),(128,190),(512,214),(2048,238)]}
    if gates!={v:required for v in variants}:raise ValueError('Incomplete conformance')
    for cap,count in required.items():
        sums=set()
        for v in variants:
            rows=list(csv.reader((root/'raw'/f'gate-{cap}-{v}.csv').read_text().splitlines()))
            if len(rows)!=1 or rows[0][:3]!=[v,'0','0'] or int(rows[0][5])!=count:raise ValueError('Bad conformance record')
            sums.add(int(rows[0][6]))
        if len(sums)!=1:raise ValueError('Conformance checksum mismatch')
    expected_checks=json.loads((root/'expected_checksums.json').read_text())
    keys={(n,c,f,v,rep,r) for (n,c,f),v,rep,r in itertools.product(shapes,variants,range(3),range(58))}
    seen=set();groups={};initial={};checked=0
    for row in csv.DictReader((root/f'rounds{suffix}.csv').read_text().splitlines()):
        n,c,f,rep,r=(int(row[k]) for k in ['carts','lines','factor','repeat','round']);v=row['variant'];key=(n,c,f,v,rep,r)
        if key not in keys or key in seen:raise ValueError('Unexpected/duplicate round')
        seen.add(key)
        if int(row['checked_totals'])!=n:raise ValueError('Wrong output count')
        if int(row['checksum'])!=expected_checks[f'{n}-{c}-{f}'][r]:raise ValueError('Wrong exact checksum')
        checked+=n;t=float(row['total_us']);init=float(row['init_ms'])
        if not math.isfinite(t) or t<=0 or not math.isfinite(init) or init<0:raise ValueError('Invalid timing')
        run=key[:-1]
        if run in initial and initial[run]!=init:raise ValueError('Changing initialization')
        initial[run]=init
        if r>=8:groups.setdefault(run,[]).append(t)
    if keys!=seen:raise ValueError(f'Missing {len(keys-seen)} rounds')
    points=[]
    for n,c,f in shapes:
        timings=[]
        for v in variants:
            reps=[statistics.mean(groups[n,c,f,v,rep]) for rep in range(3)]
            timings.append(dict(variant=v,mean_us=statistics.mean(reps),stdev_us=statistics.stdev(reps),repeats_us=reps,init_ms=statistics.mean(initial[n,c,f,v,rep] for rep in range(3))))
        gpu=min((t for t in timings if t['variant'].startswith('gpu')),key=lambda t:t['mean_us'],default=None)
        cpu=min((t for t in timings if not t['variant'].startswith('gpu')),key=lambda t:t['mean_us'])
        points.append(dict(carts=n,lines=c,factor=f,timings=timings,best_cpu=cpu['variant'],best_gpu=gpu['variant'] if gpu else None,ratio=cpu['mean_us']/gpu['mean_us'] if gpu else None))
    data=dict(date='2026-10-20',variants=variants,rounds=len(seen),checked_totals=checked,points=points)
    (root/f'summary{suffix}.json').write_text(json.dumps(data,indent=2)+'\n')
    text=['# Resident update comparison across languages','','Times µs/batch, mean ± sample SD of three repetition means. Eight warmups, 50 timed changing rounds. Same exact canonical input and full fresh owned output; CPU/GPU placement outside batch timing. No SQL/HTTP.','','| Carts | Lines | Updates/cart | Implementation | Total µs ± SD | CPU / fastest GPU | Init ms |','| ---: | ---: | ---: | --- | ---: | ---: | ---: |']
    for p in points:
        g=next((t['mean_us'] for t in p['timings'] if t['variant']==p['best_gpu']),None)
        for t in p['timings']:
            ratio='—' if g is None or t['variant'].startswith('gpu') else f"{t['mean_us']/g:.2f}×"
            text.append(f"| {p['carts']} | {p['lines']} | {p['factor']} | {t['variant']} | {t['mean_us']:.3f} ± {t['stdev_us']:.3f} | {ratio} | {t['init_ms']:.3f} |")
    text+=['',f'{len(seen):,} checked changing rounds; {checked:,} exact totals, plus 808 upstream cases × {len(variants)} implementations.','']
    (root/f'summary{suffix}.md').write_text('\n'.join(text));print(f'Validated {len(seen)} rounds; {checked} exact totals.')
    return data
