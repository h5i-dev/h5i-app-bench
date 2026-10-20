"""Publish current CPU data against explicitly labelled earlier GPU references.

No contended GPU samples are used. This is deliberately separate from the
full contemporary CPU+GPU validator in languages/summarize.py.
"""
import csv
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import statistics

HERE = Path(__file__).resolve().parent
ROOT = HERE / 'languages/results/2026-10-20'
GPU_ROOT = HERE / 'scale/transport/results/2026-10-20'

def digest(p):
    h=hashlib.sha256()
    with open(p,'rb') as f:
        while b:=f.read(8<<20):h.update(b)
    return h.hexdigest()

def main():
    spec=importlib.util.spec_from_file_location('language_summary',HERE/'languages/summarize.py')
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    cpu=module.summarize(ROOT,phase='cpu')
    current=json.loads((ROOT/'environment-cpu.json').read_text())
    for path,expected in current['sources'].items():
        if digest(HERE.parent/path)!=expected:raise ValueError(f'Changed measured source {path}')
    for path,expected in current['artifacts'].items():
        if digest(path)!=expected:raise ValueError(f'Changed measured artifact {path}')
    previous=json.loads((GPU_ROOT/'summary.json').read_text())
    gpu_meta=json.loads((GPU_ROOT/'environment.json').read_text())
    expected=json.loads((ROOT/'expected_checksums.json').read_text())
    wanted=['gpu-scan-pageable','gpu-delta-pageable','gpu-scan-compact-pinned-encode4','gpu-delta-compact-pinned-encode4']
    groups={};seen=set()
    for row in csv.DictReader((GPU_ROOT/'rounds.csv').read_text().splitlines()):
        if row['variant'] not in wanted or row['mode']!='plain':continue
        n,cap,u,rep,r=(int(row[k]) for k in ['carts','lines','updates','repeat','round'])
        v=row['variant'];key=(n,cap,u//n,v,rep,r)
        if u%n or key in seen or int(row['checked_totals'])!=n:raise ValueError('Bad prior GPU grid')
        seen.add(key)
        if int(row['checksum'])!=expected[f'{n}-{cap}-{u//n}'][r]:raise ValueError('Prior GPU trace differs')
        if r>=8:groups.setdefault(key[:-1],[]).append(float(row['total_us']))
    import itertools
    grid={(n,c,f,v,rep,r) for (n,c,f),v,rep,r in itertools.product(module.SHAPES,wanted,range(3),range(58))}
    if seen!=grid:raise ValueError('Incomplete prior GPU grid')
    data={**cpu,'variants':cpu['variants']+wanted,'historical_gpu':True,
          'gpu_reference_utc':gpu_meta['utc'],'cpu_measurement_utc':current['utc'],
          'gpu_reference_source':'resident/scale/transport/results/2026-10-20',
          'note':'CPU timings are new. GPU timings are earlier uncontended measurements, not rerun concurrently: all four GPUs were occupied by external vLLM jobs. Ratios are references, not contemporary speedups. rounds/checked_totals count the new CPU run only.'}
    for point in data['points']:
        n,c,f=point['carts'],point['lines'],point['factor']
        prior=next(p for p in previous['points'] if (p['carts'],p['lines'],p['factor'])==(n,c,f))
        for v in wanted:
            source=next(m for m in prior['modes'] if m['variant']==v and m['mode']=='plain')
            means=[statistics.mean(groups[n,c,f,v,rep]) for rep in range(3)]
            mean,sd=statistics.mean(means),statistics.stdev(means)
            if not math.isclose(mean,source['timings']['total_us']['mean'],rel_tol=1e-12) or not math.isclose(sd,source['timings']['total_us']['stdev'],rel_tol=1e-12):raise ValueError('Prior GPU summary differs')
            point['timings'].append(dict(variant=v,mean_us=mean,stdev_us=sd,repeats_us=means,init_ms=source['init_ms'],historical=True))
        gpu=min((t for t in point['timings'] if t['variant'].startswith('gpu')),key=lambda t:t['mean_us'])
        best=next(t for t in point['timings'] if t['variant']==point['best_cpu'])
        point['best_gpu']=gpu['variant'];point['ratio']=best['mean_us']/gpu['mean_us']
    (ROOT/'summary.json').write_text(json.dumps(data,indent=2)+'\n')
    lines=['# Resident language comparison with earlier GPU references','',data['note'],'',
      'CPU: mean ± sample SD of three repetition means, eight changing warmups and 50 timed rounds each. All update work and full fresh owned results included. GPU input/output costs are included in the earlier run too.','',
      '| Carts | Lines | Updates/cart | Implementation | Total µs ± SD | CPU / prior GPU (reference) |','| ---: | ---: | ---: | --- | ---: | ---: |']
    for p in data['points']:
        gpu=next(t['mean_us'] for t in p['timings'] if t['variant']==p['best_gpu'])
        for t in p['timings']:
            historical=t.get('historical',False);label=t['variant']+(' (prior run)' if historical else '')
            ratio='—' if historical else f"{t['mean_us']/gpu:.2f}×"
            lines.append(f"| {p['carts']} | {p['lines']} | {p['factor']} | {label} | {t['mean_us']:.3f} ± {t['stdev_us']:.3f} | {ratio} |")
    lines+=['',f"New CPU run: {cpu['rounds']:,} checked rounds, {cpu['checked_totals']:,} exact totals; 808 upstream cases × 9 CPU implementations.",
        'The four reused GPU paths cover 2,784 earlier rounds and 139,689,984 exact totals; every round checksum agrees with the new trace fixtures. The complete earlier transport experiment has additional paths and diagnostics.','']
    (ROOT/'summary.md').write_text('\n'.join(lines))
    provenance=dict(cpu=current,historical_gpu=gpu_meta,publisher_sha256=digest(Path(__file__)),
       evidence_sha256={str(p.relative_to(HERE.parent)):digest(p) for p in [ROOT/'summary-cpu.json',ROOT/'rounds-cpu.csv',ROOT/'expected_checksums.json',GPU_ROOT/'summary.json',GPU_ROOT/'rounds.csv',GPU_ROOT/'environment.json']},note=data['note'])
    (ROOT/'environment.json').write_text(json.dumps(provenance,indent=2)+'\n')
    print('Published current CPU results with explicitly labelled prior GPU references.')

if __name__=='__main__':main()
