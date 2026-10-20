"""Validate complete phase runs and summarize repetition means, preserving integer checksums."""
import csv
import itertools
import json
import math
from pathlib import Path
import statistics

SHAPES = [(4096,512,16),(65536,2048,1),(65536,2048,16),(65536,2048,64)]
MODES = [('cpu-delta-4','plain')]+list(itertools.product(['gpu-scan','gpu-delta'],['plain','host','events']))
METRICS = ['total_us','upload_us','enqueue_us','sync_us','alloc_us','download_us','validate_us','device_update_or_fused_us','device_scan_us','timer_tail_us']
HOST = METRICS[1:7]

def summarize(root,smoke=False):
    root=Path(root)
    shapes=[(64,32,1),(64,32,16)] if smoke else SHAPES
    gates=json.loads((root/'conformance.json').read_text())
    if gates!={str(cap):dict(decimal_cases=count,variants=7) for cap,count in zip([32,128,512,2048],[166,190,214,238])}:
        raise ValueError('Missing upstream conformance gate')
    expected={(n,cap,n*f,rep,v,m,r) for (n,cap,f),rep,(v,m),r in itertools.product(shapes,range(3),MODES,range(58))}
    seen=set();checks={};groups={};checked=0
    with (root/'rounds.csv').open() as file:
        for row in csv.DictReader(file):
            n,cap,u,rep,r=(int(row[k]) for k in ['carts','lines','updates','repeat','round'])
            key=(n,cap,u,rep,row['variant'],row['mode'],r)
            if key not in expected or key in seen:raise ValueError(f'Unexpected/duplicate round {key}')
            seen.add(key)
            if (row['warmup']!=str(r<8).lower() or int(row['checked_totals'])!=n or
                int(row['command_bytes'])!=(n+4*u)*8 or int(row['result_bytes'])!=n*8):raise ValueError('Bad counts/bytes')
            checked+=n
            ck=(n,cap,u,r);checksum=int(row['checksum'])
            if ck in checks and checks[ck]!=checksum:raise ValueError('Checksum differs across modes/repetitions')
            checks[ck]=checksum
            values={k:float(row[k]) for k in METRICS}
            if any(not math.isfinite(v) or v<0 for v in values.values()) or values['total_us']<=0:raise ValueError('Invalid timing')
            if row['mode']!='plain' and abs(sum(values[k] for k in HOST)-values['total_us'])>0.001:raise ValueError('Host phases do not sum to total')
            if row['mode']!='events' and any(values[k]!=0 for k in METRICS[7:9]):raise ValueError('Unexpected device timestamps')
            if row['variant']=='gpu-delta' and values['device_scan_us']!=0:raise ValueError('Fused delta must not have separate scan')
            if r>=8:groups.setdefault(key[:-1],[]).append(values)
    if seen!=expected:raise ValueError(f'Missing rounds: {len(expected-seen)}')
    points=[]
    for n,cap,f in shapes:
        modes=[]
        for variant,mode in MODES:
            repeats=[{k:statistics.mean(v[k] for v in groups[n,cap,n*f,rep,variant,mode]) for k in METRICS} for rep in range(3)]
            timing={k:dict(mean=statistics.mean(r[k] for r in repeats),stdev=statistics.stdev(r[k] for r in repeats)) for k in METRICS}
            modes.append(dict(variant=variant,mode=mode,timings=timing,repeats=repeats))
        points.append(dict(carts=n,lines=cap,factor=f,command_bytes=(n+4*n*f)*8,result_bytes=n*8,modes=modes))
    data=dict(date='2026-10-20',shapes=len(shapes),rounds=len(seen),checked_totals=checked,points=points)
    (root/'summary.json').write_text(json.dumps(data,indent=2)+'\n')
    lines=['# Changing resident update phase measurements','','Times are µs/batch, means of three repetition means (50 changing rounds after eight warmups).',
           'Host phases are disjoint. Device event intervals overlap enqueue/synchronization and are a separate instrumented replay; do not add them to host phases.',
           'Upload/download are synchronous pageable-buffer API wall times, including staging/driver overhead. Initial placement is excluded.','','| Carts | Lines | Updates/cart | Variant | Mode | Total ± SD | Upload | Enqueue | Sync | Allocate | Download | Validate | Device update/fused | Device scan | Timer tail |',
           '| ---: | ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |']
    for p in points:
        for m in p['modes']:
            t=m['timings'];values=[f"{t[k]['mean']:.3f}" for k in METRICS[1:]]
            lines.append('| '+' | '.join(map(str,[p['carts'],p['lines'],p['factor'],m['variant'],m['mode'],f"{t['total_us']['mean']:.3f} ± {t['total_us']['stdev']:.3f}",*values]))+' |')
    lines+=['',f"All {len(seen):,} rounds checked: {checked:,} exact totals, plus 808 upstream cases × seven implementations.",'']
    (root/'summary.md').write_text('\n'.join(lines))
    print(f'Validated {len(seen)} rounds, {checked} exact totals.')
    return data
