"""Compact update transport and pinned staging; encoding remains inside timing."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time
from summarize import summarize

HERE = Path(__file__).resolve().parent
APP = HERE.parents[2]

def main():
    p = argparse.ArgumentParser(__doc__)
    p.add_argument('--out', type=Path, default=HERE/'results/2026-10-20')
    p.add_argument('--smoke', action='store_true')
    args = p.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    binary = '/var/tmp/h5i-gpu-target/release/examples/resident_transport'
    ptx = '/var/tmp/h5i-gpu-target/nvptx64-nvidia-cuda/release/django_cart_compact_device.ptx'
    oracle = '/var/tmp/cart-lines-oracle.json'
    digest = lambda f: hashlib.sha256(Path(f).read_bytes()).hexdigest()
    old = json.loads((APP/'resident/scale/results/2026-10-19/environment.json').read_text())
    assert digest(oracle) == old['oracle_sha256']
    original_ptx='/var/tmp/h5i-gpu-target/nvptx64-nvidia-cuda/release/django_cart_resident_device.ptx'
    assert digest(original_ptx) == old['artifact_sha256'][original_ptx]
    sources = ['resident/scale/transport/'+s for s in ['run.py','summarize.py','build.sh']]
    sources += ['rust-h5i-gpu/backend-nvvm/examples/resident_transport.rs',
                'rust-h5i-gpu/backend-nvvm/examples/resident_scale.rs',
                'rust-h5i-gpu/backend-nvvm/resident-device/src/lib.rs',
                'rust-h5i-gpu/backend-nvvm/compact-device/src/lib.rs',
                'rust-h5i-gpu/backend-nvvm/compact-device/Cargo.toml',
                'rust-h5i-gpu/backend-nvvm/compact-device/Cargo.lock',
                'rust-h5i-gpu/backend-nvvm/Cargo.toml','rust-h5i-gpu/backend-nvvm/Cargo.lock',
                'rust-h5i-gpu/src/pricing.rs','rust-h5i-gpu/src/wide.rs']
    command = ['taskset','-c','64-67',binary,ptx,oracle,str(args.out/'conformance.json')]
    if args.smoke: command.append('--smoke')
    metadata = dict(utc=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),command=command,
        cpu_affinity=[64,65,66,67],source_sha256={s:digest(APP/s) for s in sources},
        artifact_sha256={s:digest(s) for s in [binary,ptx,original_ptx]},oracle_sha256=digest(oracle),
        upstream_commit=old['upstream_commit'],versions=old['versions'],
        gpu_at_start=subprocess.check_output(['nvidia-smi','--query-gpu=index,name,uuid,driver_version,temperature.gpu','--format=csv'],text=True),
        config=dict(shapes=[[64,32,0],[64,32,1],[64,32,16]] if args.smoke else [[4096,512,16],[65536,2048,1],[65536,2048,16],[65536,2048,64]],
                    repeats=3,warmup=8,iterations=50,smoke=args.smoke),
        note='Same canonical u64 commands, changing traces and independent full-rescan oracle. Packing/staging, upload, kernels, complete download and owned output allocation all timed. Updates packed into one u64, with cart ID taken from query[k%n]; validated bounds and routing outside timing for all paths. Reusable pinned buffers require timed source copy/encoding and pinned output to owned Vec. Controls use original host calls and original kernel source compiled into the new separate PTX. Original PTX/artifacts preserved. Event replays separate from plain headline, recorded on same stream; event upload for synchronous pageable calls includes host idle gaps. Pinned transfers/kernels ordered in one stream, no overlap across rounds. Event readout included in events-mode total and retained in timer_tail_us. Parallel encoding uses the same persistent four-worker Rayon pool and same four-core CPU allocation; serial encoding retained. CPU4 baseline from previous best implementation. No HTTP/database/CDC, shared host, uncontrolled clocks/NUMA/cache')
    (args.out/'environment.json').write_text(json.dumps(metadata,indent=2)+'\n')
    with (args.out/'rounds.csv').open('w') as f:
        subprocess.run(command,stdout=f,check=True,env={**os.environ,'CUDA_VISIBLE_DEVICES':'0','LD_LIBRARY_PATH':'/usr/local/cuda-12.6/lib64'})
    summarize(args.out,smoke=args.smoke)

if __name__=='__main__':main()
