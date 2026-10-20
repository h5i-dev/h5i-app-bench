"""Measure resident carts with visible updates, without HTTP or database work."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

from summarize import summarize

HERE = Path(__file__).resolve().parent
APP = HERE.parent


def main():
    p = argparse.ArgumentParser(__doc__)
    p.add_argument('--out', type=Path, default=HERE / 'results/2026-10-19')
    p.add_argument('--binary', default='/var/tmp/h5i-gpu-target/release/examples/resident_updates')
    p.add_argument('--ptx', default='/var/tmp/h5i-gpu-target/nvptx64-nvidia-cuda/release/django_cart_resident_device.ptx')
    p.add_argument('--oracle', default='/var/tmp/cart-lines-oracle.json')
    p.add_argument('--cpus', default='64-67')
    args = p.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    digest = lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
    oracle_hash = digest(args.oracle)
    previous = json.loads((APP / 'http/lines/results/2026-10-19/environment.json').read_text())
    if oracle_hash != previous['oracle_sha256']:
        raise ValueError('oracle differs from the upstream-verified line-count corpus')
    sources = ['resident/run.py', 'resident/summarize.py', 'resident/build.sh',
               'rust-h5i-gpu/backend-nvvm/examples/resident_updates.rs',
               'rust-h5i-gpu/backend-nvvm/resident-device/src/lib.rs',
               'rust-h5i-gpu/backend-nvvm/resident-device/Cargo.toml',
               'rust-h5i-gpu/backend-nvvm/resident-device/Cargo.lock',
               'rust-h5i-gpu/backend-nvvm/Cargo.toml', 'rust-h5i-gpu/backend-nvvm/Cargo.lock',
               'rust-h5i-gpu/src/pricing.rs', 'rust-h5i-gpu/src/wide.rs']
    command = ['taskset', '-c', args.cpus, args.binary, args.ptx, args.oracle, str(args.out / 'conformance.json')]
    metadata = dict(utc=time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()), command=command,
                    cpu_affinity=json.loads(subprocess.check_output(['taskset', '-c', args.cpus, 'python3', '-c', 'import os,json;print(json.dumps(sorted(os.sched_getaffinity(0))))'], text=True)),
                    source_sha256={s: digest(APP / s) for s in sources},
                    artifact_sha256={s: digest(s) for s in [args.binary, args.ptx]},
                    oracle_sha256=oracle_hash, upstream_commit=previous['upstream_commit'],
                    versions=previous['versions'],
                    gpu_at_start=subprocess.check_output(['nvidia-smi', '--query-gpu=index,name,uuid,driver_version,temperature.gpu', '--format=csv'], text=True),
                    config=dict(carts=4096, lines=[32, 128, 512, 2048], queries=[8, 128, 256, 4096], update_profiles=['none', 'one', 'per-query', 'sixteen-per-query'], repeats=3, iterations=100, warmup=8),
                    note='Resident calculation experiment, no HTTP/SQL/commit/CDC. Same ordered, validated line-replacement events on CPU/GPU; every warmup/timed result checked against full-rescan oracle outside timing. GPU includes command upload, ordered update/query kernels, synchronization and complete result download. Initial placement is measured separately.')
    (args.out / 'environment.json').write_text(json.dumps(metadata, indent=2) + '\n')
    with (args.out / 'points.csv').open('w') as f:
        subprocess.run(command, stdout=f, check=True, env={**os.environ, 'CUDA_VISIBLE_DEVICES': '0', 'LD_LIBRARY_PATH': '/usr/local/cuda-12.6/lib64'})
    summarize(args.out)


if __name__ == '__main__':
    main()
