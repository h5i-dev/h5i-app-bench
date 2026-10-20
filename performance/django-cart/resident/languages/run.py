"""Compare independent language ports on exported exact resident update traces."""
import argparse
import array
import csv
import hashlib
import itertools
import json
import os
from pathlib import Path
import subprocess
import sys
import time
from summarize import summarize, VARIANTS, SHAPES, SMOKE
HERE = Path(__file__).resolve().parent
APP = HERE.parents[1]
BIN = Path('/var/tmp/h5i-gpu-target/release/examples')
PTX = Path('/var/tmp/h5i-gpu-target/nvptx64-nvidia-cuda/release/django_cart_compact_device.ptx')
PYTHON = '/var/tmp/cart-language-venv/bin/python'
ORACLE = Path('/var/tmp/cart-lines-oracle.json')
ENV = {**os.environ, 'CUDA_VISIBLE_DEVICES':'0', 'LD_LIBRARY_PATH':'/usr/local/cuda-12.6/lib64',
       'OMP_NUM_THREADS':'1','OPENBLAS_NUM_THREADS':'1','MKL_NUM_THREADS':'1'}

def digest(p):
    h = hashlib.sha256()
    with open(p,'rb') as f:
        while b:=f.read(8<<20): h.update(b)
    return h.hexdigest()

def command(fixture, variant, rep):
    if variant.startswith('go-'): cmd=['/var/tmp/cart-resident-go']
    elif variant.startswith('javascript-'): cmd=['node','--max-old-space-size=8192',str(HERE/'main.mjs')]
    elif variant.startswith('python-'): cmd=[PYTHON,str(HERE/'main.py')]
    else: cmd=[str(BIN/'language_reference')]
    cmd += [str(fixture),variant,str(rep)]
    if variant.startswith(('rust','gpu')): cmd.append(str(PTX))
    return ['taskset','-c','64-67',*cmd]

def main():
    p=argparse.ArgumentParser(__doc__);p.add_argument('--smoke',action='store_true');p.add_argument('--phase',choices=['all','cpu','gpu'],default='all');p.add_argument('--out',type=Path);p.add_argument('--fixtures',type=Path);a=p.parse_args()
    out=a.out or HERE/'results/2026-10-20'; fixtures=a.fixtures or Path('/var/tmp/cart-language-fixtures-smoke' if a.smoke else '/var/tmp/cart-language-fixtures')
    out.mkdir(parents=True,exist_ok=True);(out/'raw').mkdir(exist_ok=True)
    subprocess.run(['taskset','-c','64-67',str(BIN/'export_languages'),str(fixtures),str(ORACLE),*(['--smoke'] if a.smoke else [])],check=True,env=ENV)
    paths=[APP/'rust-h5i-gpu/src/pricing.rs',APP/'rust-h5i-gpu/src/wide.rs',APP/'rust-h5i-gpu/backend-nvvm/Cargo.toml',APP/'rust-h5i-gpu/backend-nvvm/Cargo.lock',APP/'rust-h5i-gpu/backend-nvvm/examples/resident_scale.rs',APP/'rust-h5i-gpu/backend-nvvm/examples/resident_transport.rs',*HERE.glob('*.py'),HERE/'main.go',HERE/'main.mjs',HERE/'build.sh',APP/'rust-h5i-gpu/backend-nvvm/examples/export_languages.rs',APP/'rust-h5i-gpu/backend-nvvm/examples/language_reference.rs']
    variants=[v for v in VARIANTS if a.phase=='all' or v.startswith('gpu')==(a.phase=='gpu')]
    meta=dict(phase=a.phase,variants=variants,utc=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),smoke=a.smoke,cpu_affinity=[64,65,66,67],
      sources={str(p.relative_to(APP)):digest(p) for p in paths},artifacts={str(p):digest(p) for p in [BIN/'export_languages',BIN/'language_reference',Path('/var/tmp/cart-resident-go'),PTX]},
      oracle_sha256=digest(ORACLE),fixtures={str(p.relative_to(fixtures)):digest(p) for p in fixtures.glob('*/*')},
      versions={k:subprocess.check_output(v,text=True,env=ENV).strip() for k,v in {'go':['/var/tmp/go/bin/go','version'],'node':['node','--version'],'python':[PYTHON,'--version'],'numpy':[PYTHON,'-c','import numpy;print(numpy.__version__)'],'gpu':['nvidia-smi','--query-gpu=index,name,uuid,driver_version','--format=csv']}.items()},commands=[],
      note='Same canonical u64 fixture trace exported verbatim from earlier Rust generator; every round independently rescanned in exporter, every full result verified by each port. All implementations restricted to CPU64-67; 1-worker, 4-worker, Python four persistent fork processes (no shared GIL), and NumPy one-thread native vectorization. Dispatch/join and fresh complete owned result included. Python initial subtotal caches read from exporter outside timing; upstream gates independently recompute subtotals and all totals finished in Python. Full initial state placement, file load, input validation and reference checks excluded. No HTTP/SQL/CDC; shared host, uncontrolled clocks/NUMA/cache. No concurrent benchmark processes; rotated/reversed order across repetitions. GC enabled.')
    gates={}
    for v in variants:
        gates[v]={}
        for cap,count in [(32,166),(128,190),(512,214),(2048,238)]:
            cmd=command(fixtures/f'gate-{cap}',v,0)
            dest=out/'raw'/f'gate-{cap}-{v}.csv'
            print(f'gate {v} cap={cap}',flush=True)
            with dest.open('w') as f:subprocess.run(cmd,stdout=f,check=True,env=ENV)
            rows=list(csv.reader(dest.read_text().splitlines()));assert len(rows)==1 and rows[0][:3]==[v,'0','0'] and int(rows[0][5])==count
            gates[v][str(cap)]=count
    (out/f'conformance-{a.phase}.json').write_text(json.dumps(gates,indent=2)+'\n')
    fields=['carts','lines','factor','variant','repeat','round','total_us','init_ms','checked_totals','checksum']
    with (out/f'rounds-{a.phase}.csv').open('w') as f:
        writer=csv.writer(f);writer.writerow(fields);f.flush()
        for n,cap,factor in SMOKE if a.smoke else SHAPES:
            fixture=fixtures/f'{n}-{cap}-{factor}'
            for rep in range(3):
                offset=(rep*3)%len(variants)
                order=variants[offset:]+variants[:offset]
                if rep%2:order=order[::-1]
                for v in order:
                    if v.startswith('gpu'):
                        apps=subprocess.check_output(['nvidia-smi','--query-compute-apps=gpu_uuid,pid,process_name','--format=csv,noheader'],text=True)
                        gpu0=subprocess.check_output(['nvidia-smi','-i','0','--query-gpu=uuid','--format=csv,noheader'],text=True).strip()
                        if any(line.startswith(gpu0+',') for line in apps.splitlines()):
                            raise RuntimeError('GPU 0 has another compute process; refusing contaminated timing')
                    cmd=command(fixture,v,rep);meta['commands'].append(cmd)
                    print(f'run {n}x{cap} updates/cart={factor} rep={rep} {v}',flush=True)
                    dest=out/'raw'/f'{n}-{cap}-{factor}-{rep}-{v}.csv'
                    with dest.open('w') as raw:subprocess.run(cmd,stdout=raw,check=True,env=ENV)
                    for row in csv.reader(dest.read_text().splitlines()):writer.writerow([n,cap,factor,*row])
                    f.flush()
                    (out/f'environment-{a.phase}.json').write_text(json.dumps(meta,indent=2)+'\n')
    # Expected checksums are computed once per fixture from exact u64 data.
    expected={}
    for n,cap,factor in SMOKE if a.smoke else SHAPES:
        a64=array.array('Q');
        with (fixtures/f'{n}-{cap}-{factor}'/'expected.bin').open('rb') as f:a64.fromfile(f,n*58)
        expected[f'{n}-{cap}-{factor}']=[sum(a64[r*n:(r+1)*n])%(1<<64) for r in range(58)]
    (out/'expected_checksums.json').write_text(json.dumps(expected,indent=2)+'\n')
    if a.phase=='all':
        (out/'rounds.csv').write_text((out/'rounds-all.csv').read_text())
        (out/'conformance.json').write_text((out/'conformance-all.json').read_text())
        (out/'environment.json').write_text((out/'environment-all.json').read_text())
        summarize(out,smoke=a.smoke)
    elif a.phase=='cpu':
        summarize(out,smoke=a.smoke,phase='cpu')
    else:
        cpu=json.loads((out/'environment-cpu.json').read_text())
        if cpu['sources']!=meta['sources'] or cpu['artifacts']!=meta['artifacts'] or cpu['fixtures']!=meta['fixtures']:
            raise ValueError('CPU/GPU sources, artifacts or fixtures differ')
        (out/'rounds.csv').write_text((out/'rounds-cpu.csv').read_text()+'\n'.join((out/'rounds-gpu.csv').read_text().splitlines()[1:])+'\n')
        combined={**json.loads((out/'conformance-cpu.json').read_text()),**gates}
        (out/'conformance.json').write_text(json.dumps(combined,indent=2)+'\n')
        (out/'environment.json').write_text(json.dumps(dict(cpu=cpu,gpu=meta,note='CPU and GPU measured in separate phases because all GPUs were occupied during the initial CPU run.'),indent=2)+'\n')
        summarize(out,smoke=a.smoke)

if __name__=='__main__':main()
