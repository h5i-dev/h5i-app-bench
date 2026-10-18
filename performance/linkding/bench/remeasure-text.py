#!/usr/bin/env python3
"""Run the shared Linkding harness for text search and mixed traffic.

Uses isolated, temporary databases and the existing workload.js, seeding,
sampling and summarizer. Requires prebuilt CPU/GPU/optimized SQL servers,
Docker, k6, taskset and the linkding:1.47.0 image. Does not build or publish.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]


def main():
    p = argparse.ArgumentParser(description=__doc__)
    for name in ('cpu-bin', 'gpu-bin', 'sql-bin', 'ptx', 'out'):
        p.add_argument('--' + name, required=True, type=Path)
    p.add_argument('--concurrency', default='1 16')
    p.add_argument('--repeats', type=int, default=3)
    p.add_argument('--warmup', type=int, default=10)
    p.add_argument('--duration', type=int, default=30)
    p.add_argument('--pg-port-base', type=int, default=15570)
    p.add_argument('--http-port-base', type=int, default=18270)
    args = p.parse_args()
    for path in (args.cpu_bin, args.gpu_bin, args.sql_bin, args.ptx):
        if not path.is_file():
            p.error(f'missing artifact: {path}')
    args.out = args.out.resolve()
    args.out.mkdir(parents=True, exist_ok=False)
    prefix = f'h5i-text-{os.getpid()}'
    variants = [('rust-h5i-optimized', 'rust-h5i-optimized', args.sql_bin),
                ('rust-h5i-cpu-scan', 'rust-h5i-gpu', args.cpu_bin),
                ('rust-h5i-gpu', 'rust-h5i-gpu', args.gpu_bin),
                ('upstream', 'upstream', None)]
    metadata = {k: str(v) if isinstance(v, Path) else v for k, v in vars(args).items()}
    metadata.update(started_utc=time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
                    revision=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                    scenarios='search search_complex mixed',
                    sha256={k: hashlib.sha256(v.read_bytes()).hexdigest()
                            for k, v in vars(args).items() if k.endswith('_bin') or k == 'ptx'},
                    layout=[])
    jobs, containers, logs = [], [], []
    try:
        for i, (label, implementation, binary) in enumerate(variants):
            first = 12 * i
            container = f'{prefix}-{i}'
            upstream = f'{prefix}-upstream'
            log_dir = args.out / 'logs' / label
            log_dir.mkdir(parents=True)
            env = dict(os.environ, SERVER_CPUS=f'{first}-{first+3}', PG_CPUS=f'{first+4}-{first+7}',
                       K6_CPUS=f'{first+8}-{first+11}', LINKDING_PG_CONTAINER=container,
                       LINKDING_PG_PORT=str(args.pg_port_base+i),
                       LINKDING_PG_DATA=f'/var/tmp/{container}',
                       LINKDING_UPSTREAM_CONTAINER=upstream,
                       BENCH_PORT=str(args.http_port_base+i), BENCH_OUT=str(args.out),
                       LOG_DIR=str(log_dir), BENCH_NO_SUMMARY='1', BENCH_IMPL_LABEL=label,
                       BENCH_SCENARIOS=metadata['scenarios'], BENCH_CONCURRENCY=args.concurrency,
                       BENCH_REPEATS=str(args.repeats), BENCH_WARMUP=str(args.warmup),
                       BENCH_DURATION=str(args.duration), CUDA_VISIBLE_DEVICES='0',
                       H5I_GPU_PTX=str(args.ptx.resolve()),
                       LD_LIBRARY_PATH='/usr/local/cuda-12.6/lib64:' + os.environ.get('LD_LIBRARY_PATH', ''),
                       H5I_SEARCH_CACHE_ENTRIES='8', H5I_SEARCH_CACHE_MIB='256', H5I_SEARCH_QUEUE='32')
            env.pop('DATABASE_URL', None)
            env.pop('BENCH_SERVER_BIN', None)
            if binary:
                env['BENCH_SERVER_BIN'] = str(binary.resolve())
            containers.append(container)
            if implementation == 'upstream':
                env['LINKDING_SKIP_SCHEMA'] = '1'
                containers.append(upstream)
            subprocess.run([str(ROOT / 'scripts/up-db.sh')], env=env, check=True,
                           stdout=subprocess.DEVNULL)
            # Pin from inside the container: host proc namespaces/permissions
            # can otherwise make a best-effort taskset silently do nothing.
            subprocess.run(['docker', 'exec', '--user', 'postgres', container, 'sh', '-c',
                            'for proc in /proc/[0-9]*; do taskset -apc ' + env['PG_CPUS'] +
                            ' "${proc##*/}" >/dev/null 2>&1 || true; done'], check=True)
            layout = {k: env[k] for k in ('SERVER_CPUS', 'PG_CPUS', 'K6_CPUS', 'LINKDING_PG_PORT', 'BENCH_PORT')}
            metadata['layout'].append(dict(impl=label, **layout))
            log = (log_dir / 'bench-all.log').open('w')
            logs.append(log)
            jobs.append(subprocess.Popen(['bash', str(ROOT / 'scripts/bench-all.sh'), implementation],
                                         env=env, stdout=log, stderr=subprocess.STDOUT))
        (args.out / 'run.json').write_text(json.dumps(metadata, indent=2) + '\n')
        codes = [job.wait() for job in jobs]
        metadata['exit_codes'] = dict(zip([v[0] for v in variants], codes))
        metadata['completed_utc'] = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
        (args.out / 'run.json').write_text(json.dumps(metadata, indent=2) + '\n')
        subprocess.run(['python3', str(ROOT / 'bench/summarize.py'), str(args.out)], check=True)
        if any(codes):
            raise SystemExit('A benchmark failed; inspect logs and partial results.')
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
