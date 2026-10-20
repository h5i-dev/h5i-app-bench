"""Phase attribution with paired, changing traces; retains earlier measured artifacts."""
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
    binary = '/var/tmp/h5i-gpu-target/release/examples/profile_resident_scale'
    ptx = '/var/tmp/h5i-gpu-target/nvptx64-nvidia-cuda/release/django_cart_resident_device.ptx'
    oracle = '/var/tmp/cart-lines-oracle.json'
    digest = lambda f: hashlib.sha256(Path(f).read_bytes()).hexdigest()
    old = json.loads((APP/'resident/scale/results/2026-10-19/environment.json').read_text())
    assert digest(oracle) == old['oracle_sha256']
    assert digest(ptx) == old['artifact_sha256'][ptx]
    sources = ['resident/scale/profile/'+s for s in ['run.py','summarize.py','build.sh']]
    sources += ['rust-h5i-gpu/backend-nvvm/examples/profile_resident_scale.rs',
                'rust-h5i-gpu/backend-nvvm/examples/resident_scale.rs',
                'rust-h5i-gpu/backend-nvvm/resident-device/src/lib.rs',
                'rust-h5i-gpu/backend-nvvm/Cargo.toml','rust-h5i-gpu/backend-nvvm/Cargo.lock',
                'rust-h5i-gpu/src/pricing.rs','rust-h5i-gpu/src/wide.rs']
    command = ['taskset','-c','64-67',binary,ptx,oracle,str(args.out/'conformance.json')]
    if args.smoke: command.append('--smoke')
    metadata = dict(utc=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),command=command,
        cpu_affinity=[64,65,66,67],source_sha256={s:digest(APP/s) for s in sources},
        artifact_sha256={s:digest(s) for s in [binary,ptx]},oracle_sha256=digest(oracle),
        upstream_commit=old['upstream_commit'],versions=old['versions'],
        gpu_at_start=subprocess.check_output(['nvidia-smi','--query-gpu=index,name,uuid,driver_version,temperature.gpu','--format=csv'],text=True),
        config=dict(shapes=[[64,32,1],[64,32,16]] if args.smoke else [[4096,512,16],[65536,2048,1],[65536,2048,16],[65536,2048,64]],
                    repeats=3,warmup=8,iterations=50,smoke=args.smoke),
        note='Identical trace generator and unchanged GPU kernels. Each mode resets state and replays every changing update; full oracle equality checked outside timers. Plain paths match earlier calls. Host mode adds wall timestamps without intermediate synchronization. Events mode adds CUDA timestamps around kernels, not copy operations. Device intervals can include enqueue gaps, are overlapping diagnostics, and must not be added to host sync/enqueue. Host upload/download include pageable staging and driver overhead; not PCIe-only timings. Event readout and wrapper timer tail separately reported. CPU4 uses same grouped delta implementation. No HTTP/DB/CDC. Shared host, clocks/NUMA/cache uncontrolled.')
    (args.out/'environment.json').write_text(json.dumps(metadata,indent=2)+'\n')
    with (args.out/'rounds.csv').open('w') as f:
        subprocess.run(command,stdout=f,check=True,env={**os.environ,'CUDA_VISIBLE_DEVICES':'0','LD_LIBRARY_PATH':'/usr/local/cuda-12.6/lib64'})
    summarize(args.out,smoke=args.smoke)

if __name__=='__main__':main()
