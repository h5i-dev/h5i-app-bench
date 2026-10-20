"""Validate complete transport comparisons, then report plain timing and separate events."""
import csv
import itertools
import json
import math
from pathlib import Path
import statistics

SHAPES=[(4096,512,16),(65536,2048,1),(65536,2048,16),(65536,2048,64)]
VARIANTS=['cpu-delta-4']+[f'gpu-{kernel}-{transport}' for transport in ['pageable','pinned','compact-pageable','compact-pinned'] for kernel in ['scan','delta']]
VARIANTS += [f'gpu-{kernel}-compact-{transport}-encode4' for transport in ['pageable','pinned'] for kernel in ['scan','delta']]
MODES=[(v,m) for v in VARIANTS for m in (['plain','events'] if 'pinned' in v or 'compact' in v else ['plain'])]
METRICS=['total_us','encoding_us','event_upload_us','event_kernels_us','event_download_us','timer_tail_us']

def summarize(root,smoke=False):
    root=Path(root)
    shapes=[(64,32,0),(64,32,1),(64,32,16)] if smoke else SHAPES
    gates=json.loads((root/'conformance.json').read_text())
    if gates!={str(c):dict(decimal_cases=n,variants=17) for c,n in zip([32,128,512,2048],[166,190,214,238])}:raise ValueError('Missing upstream gate')
    expected={(n,cap,n*f,rep,v,m,r) for (n,cap,f),rep,(v,m),r in itertools.product(shapes,range(3),MODES,range(58))}
    seen=set();checks={};groups={};init={};checked=0
    with (root/'rounds.csv').open() as file:
        for row in csv.DictReader(file):
            n,cap,u,rep,r=(int(row[k]) for k in ['carts','lines','updates','repeat','round'])
            v,mode=row['variant'],row['mode'];key=(n,cap,u,rep,v,mode,r)
            if key not in expected or key in seen:raise ValueError(f'Unexpected/duplicate round {key}')
            seen.add(key)
            command_bytes=0 if v.startswith('cpu') else (n+u*(1 if 'compact' in v else 4))*8
            if (row['warmup']!=str(r<8).lower() or int(row['checked_totals'])!=n or int(row['source_bytes'])!=(n+4*u)*8 or
                int(row['command_bytes'])!=command_bytes or int(row['result_bytes'])!=n*8):raise ValueError('Incorrect counts/bytes')
            checked+=n;ck=(n,cap,u,r);checksum=int(row['checksum'])
            if ck in checks and checks[ck]!=checksum:raise ValueError('Checksum mismatch')
            checks[ck]=checksum
            values={k:float(row[k]) for k in METRICS};initial=float(row['init_ms'])
            if any(not math.isfinite(a) or a<0 for a in [*values.values(),initial]) or values['total_us']<=0:raise ValueError('Invalid timing')
            if values['encoding_us']>values['total_us'] or values['timer_tail_us']>values['total_us']:raise ValueError('Invalid phase bounds')
            if mode=='plain' and any(values[k]!=0 for k in METRICS[2:5]):raise ValueError('Unexpected events')
            if 'pinned' not in v and values['event_download_us']!=0:raise ValueError('Pageable download has no device event')
            if key[:-1] in init and init[key[:-1]]!=initial:raise ValueError('Changing initialization metric')
            init[key[:-1]]=initial
            if r>=8:groups.setdefault(key[:-1],[]).append(values)
    if seen!=expected:raise ValueError(f'Missing rounds: {len(expected-seen)}')
    points=[]
    for n,cap,f in shapes:
        timings=[]
        for variant,mode in MODES:
            repeats=[{k:statistics.mean(v[k] for v in groups[n,cap,n*f,rep,variant,mode]) for k in METRICS} for rep in range(3)]
            metrics={k:dict(mean=statistics.mean(r[k] for r in repeats),stdev=statistics.stdev(r[k] for r in repeats)) for k in METRICS}
            timings.append(dict(variant=variant,mode=mode,timings=metrics,repeats=repeats,
                init_ms=statistics.mean(init[n,cap,n*f,rep,variant,mode] for rep in range(3)),
                command_bytes=0 if variant.startswith('cpu') else (n+n*f*(1 if 'compact' in variant else 4))*8))
        plain={r['variant']:r['timings']['total_us']['mean'] for r in timings if r['mode']=='plain'}
        best=min((v for v in VARIANTS if v.startswith('gpu')),key=plain.get)
        points.append(dict(carts=n,lines=cap,factor=f,source_bytes=(n+n*f*4)*8,result_bytes=n*8,modes=timings,best_gpu=best,ratio=plain['cpu-delta-4']/plain[best],
            speedup_vs_legacy=min(plain['gpu-scan-pageable'],plain['gpu-delta-pageable'])/plain[best]))
    data=dict(date='2026-10-20',variants=VARIANTS,rounds=len(seen),checked_totals=checked,points=points)
    (root/'summary.json').write_text(json.dumps(data,indent=2)+'\n')
    lines=['# Compact update transport measurements','','All times µs/batch; means ± sample SD across three repetition means. 50 timed changing rounds after eight warmups.',
           'Encoding/staging and complete owned output are included. Plain modes drive ratios; events are separate diagnostic replays, with readout included in their total.',
           'Event upload for synchronous pageable calls includes host idle gaps and is not DMA-only. Initial placement is separate.','','| Carts | Lines | Updates/cart | Variant | Mode | Total ± SD | Encode/stage | Device upload interval | Device kernels | Device download | Timer tail | Command bytes | Init ms |',
           '| ---: | ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |']
    for p in points:
        for m in p['modes']:
            t=m['timings'];values=[f"{t[k]['mean']:.3f}" for k in METRICS[1:]]
            lines.append('| '+' | '.join(map(str,[p['carts'],p['lines'],p['factor'],m['variant'],m['mode'],f"{t['total_us']['mean']:.3f} ± {t['total_us']['stdev']:.3f}",*values,m['command_bytes'],f"{m['init_ms']:.3f}"]))+' |')
    lines+=['',f'{len(seen):,} checked rounds, {checked:,} exact totals, plus 808 upstream cases × 17 implementations.','']
    (root/'summary.md').write_text('\n'.join(lines));print(f'Validated {len(seen)} rounds, {checked} exact totals.')
    return data
