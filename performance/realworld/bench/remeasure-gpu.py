#!/usr/bin/env python3
"""Paired Conduit CPU/GPU HTTP runs using the existing shared benchmark harness.

Raw artifacts stay in --out locally. Publish only generated summary.csv,
summary.md and points.csv. Requires prebuilt servers/PTX, Docker, k6 and Hurl.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
SCENARIOS = 'list slug feed login create favorite mixed'.split()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    for name in ('cpu-bin', 'gpu-bin', 'ptx', 'out'):
        p.add_argument('--' + name, type=Path, required=True)
    p.add_argument('--concurrency', default='1 16')
    p.add_argument('--repeats', type=int, default=3)
    p.add_argument('--warmup', type=int, default=10)
    p.add_argument('--duration', type=int, default=30)
    p.add_argument('--lanes', type=int, choices=(1, 2), default=1,
                   help='two lanes use 48 CPU IDs and GPUs 0/1, splitting scenarios')
    p.add_argument('--pg-port-base', type=int, default=15610)
    p.add_argument('--http-port-base', type=int, default=18310)
    args = p.parse_args()
    for artifact in (args.cpu_bin, args.gpu_bin, args.ptx):
        if not artifact.is_file():
            p.error(f'missing artifact: {artifact}')
    args.out = args.out.resolve()
    args.out.mkdir(parents=True, exist_ok=False)
    prefix = f'h5i-conduit-gpu-{os.getpid()}'
    metadata = {k: str(v) if isinstance(v, Path) else v for k, v in vars(args).items()}
    metadata.update(started_utc=time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
                    revision=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                    worktree_dirty=bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT)),
                    sha256={k: hashlib.sha256(v.read_bytes()).hexdigest()
                            for k, v in vars(args).items() if k.endswith('_bin') or k == 'ptx'},
                    layout=[])
    jobs, containers, logs = [], [], []
    try:
        for lane in range(args.lanes):
            scenarios = SCENARIOS[lane::args.lanes]
            for variant, binary in [('rust-h5i-optimized', args.cpu_bin), ('rust-h5i-gpu', args.gpu_bin)]:
                idx = lane * 2 + (variant == 'rust-h5i-gpu')
                first = int(idx) * 12
                container = f'{prefix}-{idx}'
                log_dir = args.out / 'logs' / f'lane{lane}-{variant}'
                log_dir.mkdir(parents=True)
                env = dict(os.environ, SERVER_CPUS=f'{first}-{first+3}', PG_CPUS=f'{first+4}-{first+7}',
                           K6_CPUS=f'{first+8}-{first+11}', CONDUIT_PG_CONTAINER=container,
                           CONDUIT_PG_PORT=str(args.pg_port_base+idx), CONDUIT_PG_DATA=f'/var/tmp/{container}',
                           BENCH_PORT=str(args.http_port_base+idx), BENCH_OUT=str(args.out),
                           LOG_DIR=str(log_dir), BENCH_NO_SUMMARY='1', BENCH_STRICT='1',
                           BENCH_SCENARIOS=' '.join(scenarios), BENCH_CONCURRENCY=args.concurrency,
                           BENCH_REPEATS=str(args.repeats), BENCH_WARMUP=str(args.warmup),
                           BENCH_DURATION=str(args.duration), BENCH_SERVER_BIN=str(binary.resolve()),
                           CUDA_VISIBLE_DEVICES=str(lane), CONDUIT_GPU_PTX=str(args.ptx.resolve()),
                           LD_LIBRARY_PATH='/usr/local/cuda-12.6/lib64:' + os.environ.get('LD_LIBRARY_PATH', ''))
                env.pop('DATABASE_URL', None)
                containers.append(container)
                subprocess.run(['bash', str(ROOT / 'scripts/up-db.sh')], env=env, check=True,
                               stdout=subprocess.DEVNULL)
                subprocess.run(['docker', 'exec', '--user', 'postgres', container, 'sh', '-c',
                                'for proc in /proc/[0-9]*; do taskset -apc ' + env['PG_CPUS'] +
                                ' "${proc##*/}" >/dev/null 2>&1 || true; done'], check=True)
                metadata['layout'].append(dict(impl=variant, scenarios=scenarios,
                    **{k: env[k] for k in ('SERVER_CPUS','PG_CPUS','K6_CPUS','CUDA_VISIBLE_DEVICES','BENCH_PORT')}))
                log = (log_dir / 'bench-all.log').open('w')
                logs.append(log)
                jobs.append(subprocess.Popen(['bash', str(ROOT / 'scripts/bench-all.sh'), variant],
                                             env=env, stdout=log, stderr=subprocess.STDOUT))
        (args.out / 'run.json').write_text(json.dumps(metadata, indent=2) + '\n')
        codes = [job.wait() for job in jobs]
        metadata.update(exit_codes=codes, completed_utc=time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()))
        (args.out / 'run.json').write_text(json.dumps(metadata, indent=2) + '\n')
        subprocess.run(['python3', str(ROOT / 'bench/summarize.py'), str(args.out)], check=True)
        if any(codes):
            raise SystemExit('A benchmark failed; inspect local logs and partial results.')
    finally:
        for job in jobs:
            if job.poll() is None:
                job.terminate()
        for job in jobs:
            job.wait()
        for log in logs:
            log.close()
        for container in reversed(containers):
            subprocess.run(['docker', 'rm', '-f', container], stdout=subprocess.DEVNULL, check=False)


if __name__ == '__main__':
    main()
