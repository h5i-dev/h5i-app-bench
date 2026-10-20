"""Larger resident update batches; independent of the earlier measured sources."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time
from summarize import summarize

HERE = Path(__file__).resolve().parent
APP = HERE.parent.parent

def main():
    p = argparse.ArgumentParser(__doc__)
    p.add_argument('--out', type=Path, default=HERE / 'results/2026-10-19')
    p.add_argument('--smoke', action='store_true')
    args = p.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    binary = '/var/tmp/h5i-gpu-target/release/examples/resident_scale'
    ptx = '/var/tmp/h5i-gpu-target/nvptx64-nvidia-cuda/release/django_cart_resident_device.ptx'
    oracle = '/var/tmp/cart-lines-oracle.json'
    digest = lambda f: hashlib.sha256(Path(f).read_bytes()).hexdigest()
    old = json.loads((APP / 'resident/results/2026-10-19/environment.json').read_text())
    assert digest(oracle) == old['oracle_sha256']
    assert digest(ptx) == old['artifact_sha256'][ptx]
    sources = ['resident/scale/run.py', 'resident/scale/summarize.py', 'resident/scale/build.sh',
               'rust-h5i-gpu/backend-nvvm/examples/resident_scale.rs',
               'rust-h5i-gpu/backend-nvvm/resident-device/src/lib.rs',
               'rust-h5i-gpu/backend-nvvm/Cargo.toml', 'rust-h5i-gpu/backend-nvvm/Cargo.lock',
               'rust-h5i-gpu/src/pricing.rs', 'rust-h5i-gpu/src/wide.rs']
    command = ['taskset', '-c', '64-67', binary, ptx, oracle, str(args.out / 'conformance.json')]
    if args.smoke: command.append('--smoke')
    metadata = dict(utc=time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()), command=command,
        cpu_affinity=[64,65,66,67], source_sha256={s:digest(APP/s) for s in sources},
        artifact_sha256={s:digest(s) for s in [binary,ptx]}, oracle_sha256=digest(oracle),
        upstream_commit=old['upstream_commit'], versions=old['versions'],
        gpu_at_start=subprocess.check_output(['nvidia-smi','--query-gpu=index,name,uuid,driver_version,temperature.gpu','--format=csv'],text=True),
        config=dict(populations=[64] if args.smoke else [4096,16384,65536],lines=[32] if args.smoke else [512,2048],update_factors=[0,1,16] if args.smoke else [1,16,64],repeats=3,iterations=50,warmup=8,smoke=args.smoke),
        note='All population carts queried; same normalized updates and complete outputs on CPU/GPU. Includes single/four-thread grouped CPU delta, original CPU delta, one/four-thread scans, GPU scan/delta. GPU command upload and complete download included. No HTTP/database/CDC; initial placement separate. Shared host, uncontrolled clocks/NUMA/cache.')
    (args.out/'environment.json').write_text(json.dumps(metadata,indent=2)+'\n')
    with (args.out/'points.csv').open('w') as f:
        subprocess.run(command, stdout=f, check=True, env={**os.environ,'CUDA_VISIBLE_DEVICES':'0','LD_LIBRARY_PATH':'/usr/local/cuda-12.6/lib64'})
    if not args.smoke: summarize(args.out)
    else: print('Smoke passed; every output checked, not published as a measurement grid.')

if __name__ == '__main__': main()
