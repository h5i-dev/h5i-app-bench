#!/usr/bin/env python3
"""Measure complex search with the shared harness.

Uses temporary PostgreSQL containers, four server/database/client CPUs each,
and the existing seed and response checks. Raw artifacts remain in --out.
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
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--implementations', nargs='+', choices=('go', 'fastapi', 'fastify', 'rust-h5i'),
                   default=['go', 'fastapi', 'fastify'])
    p.add_argument('--concurrency', default='1 16')
    p.add_argument('--repeats', type=int, default=3)
    p.add_argument('--warmup', type=int, default=10)
    p.add_argument('--duration', type=int, default=30)
    p.add_argument('--pg-port-base', type=int, default=15730)
    p.add_argument('--http-port-base', type=int, default=18430)
    args = p.parse_args()
    args.out = args.out.resolve()
    args.out.mkdir(parents=True, exist_ok=False)
    metadata = {k: str(v) if isinstance(v, Path) else v for k, v in vars(args).items()}
    metadata.update(started_utc=time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
                    revision=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                    worktree_dirty=bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT)),
                    scenario='search_complex', layout=[],
                    sha256={str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest()
                            for path in (ROOT / 'bench/workload.js', ROOT / 'bench/seed.sql',
                                         ROOT / 'bench/seed_h5i_app.sql')})
    jobs, containers, logs = [], [], []
    try:
        for i, impl in enumerate(args.implementations):
            first = 12 * i
            container = f'h5i-complex-{os.getpid()}-{i}'
            log_dir = args.out / 'logs' / impl
            log_dir.mkdir(parents=True)
            env = dict(os.environ, SERVER_CPUS=f'{first}-{first+3}', PG_CPUS=f'{first+4}-{first+7}',
                       K6_CPUS=f'{first+8}-{first+11}', LINKDING_PG_CONTAINER=container,
                       LINKDING_PG_PORT=str(args.pg_port_base+i), LINKDING_PG_DATA=f'/var/tmp/{container}',
                       BENCH_PORT=str(args.http_port_base+i), BENCH_OUT=str(args.out), LOG_DIR=str(log_dir),
                       BENCH_NO_SUMMARY='1', BENCH_STRICT='1', BENCH_SCENARIOS='search_complex',
                       BENCH_CONCURRENCY=args.concurrency, BENCH_REPEATS=str(args.repeats),
                       BENCH_WARMUP=str(args.warmup), BENCH_DURATION=str(args.duration))
            for key in ('DATABASE_URL', 'BENCH_SERVER_BIN', 'BENCH_IMPL_LABEL'):
                env.pop(key, None)
            if impl == 'rust-h5i':
                env['CARGO_HOME'] = env.get('CARGO_HOME', '/var/tmp/ld-cargo-home')
                env['CARGO_TARGET_DIR'] = env.get('H5I_APP_TARGET_DIR', '/var/tmp/ld-target-h5i-app')
                subprocess.run(['cargo', 'build', '--release', '--locked', '-p', 'linkding-server'],
                               cwd=ROOT / 'rust-h5i', env=env, check=True)
                env['BENCH_SERVER_BIN'] = str(Path(env['CARGO_TARGET_DIR']) / 'release/linkding-server')
                metadata['engine_binary_sha256'] = hashlib.sha256(
                    Path(env['BENCH_SERVER_BIN']).read_bytes()).hexdigest()
            containers.append(container)
            subprocess.run(['bash', str(ROOT / 'scripts/up-db.sh')], env=env, check=True,
                           stdout=subprocess.DEVNULL)
            subprocess.run(['docker', 'exec', '--user', 'postgres', container, 'sh', '-c',
                            'for proc in /proc/[0-9]*; do taskset -apc ' + env['PG_CPUS'] +
                            ' "${proc##*/}" >/dev/null 2>&1 || true; done'], check=True)
            metadata['layout'].append(dict(impl=impl, **{k: env[k] for k in
                ('SERVER_CPUS', 'PG_CPUS', 'K6_CPUS', 'LINKDING_PG_PORT', 'BENCH_PORT')}))
            log = (log_dir / 'bench-all.log').open('w')
            logs.append(log)
            jobs.append(subprocess.Popen(['bash', str(ROOT / 'scripts/bench-all.sh'), impl],
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
