#!/usr/bin/env python3
"""Remeasure Linkding results affected by the 2026-10-18 changes.

Use the published workload, 10s warmup, 30s measurement and three repetitions.
Five independent slots each have four server, database and client CPUs.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import queue
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
NORMAL = 'list search search_tag get create update archive tags mixed'.split()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    tasks = queue.Queue()
    for impl, scenarios in [('rust-h5i', NORMAL), ('rust-h5i-optimized', ['get', 'mixed'])]:
        for scenario in scenarios:
            for concurrency in (1, 16, 64, 256):
                tasks.put((impl, scenario, concurrency))
    metadata = dict(started_utc=time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
                    revision=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                    warmup=10, duration=30, repeats=3, graceful_stop=5, slots=[], binaries={},
                    sha256={str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                            for p in [ROOT/'bench/workload.js', ROOT/'bench/seed.sql', ROOT/'bench/seed_h5i_app.sql']})
    binaries = {}
    for impl in ('rust-h5i', 'rust-h5i-optimized'):
        target = Path('/var/tmp/ld-target-h5i-app' if impl == 'rust-h5i' else '/var/tmp/ld-target-summary-optimized')
        env = dict(os.environ, CARGO_HOME='/var/tmp/ld-cargo-home', CARGO_TARGET_DIR=str(target))
        subprocess.run(['cargo', 'build', '--release', '--locked', '-p', 'linkding-server'],
                       cwd=ROOT/impl, env=env, check=True)
        binaries[impl] = target/'release/linkding-server'
        metadata['binaries'][impl] = dict(path=str(binaries[impl]),
                                         sha256=hashlib.sha256(binaries[impl].read_bytes()).hexdigest())
    environments = []
    containers = []
    try:
        for slot in range(5):
            first = slot*12
            container = f'ld-summary-{os.getpid()}-{slot}'
            containers.append(container)
            env = dict(os.environ, SERVER_CPUS=f'{first}-{first+3}', PG_CPUS=f'{first+4}-{first+7}',
                       K6_CPUS=f'{first+8}-{first+11}', LINKDING_PG_CONTAINER=container,
                       LINKDING_PG_PORT=str(15750+slot), LINKDING_PG_DATA=f'/var/tmp/{container}',
                       BENCH_PORT=str(18450+slot), BENCH_OUT=str(out), BENCH_NO_SUMMARY='1',
                       BENCH_STRICT='0', BENCH_REPEATS='3', BENCH_WARMUP='10', BENCH_DURATION='30')
            for key in ('DATABASE_URL', 'BENCH_SERVER_BIN', 'BENCH_IMPL_LABEL'):
                env.pop(key, None)
            subprocess.run(['bash', str(ROOT/'scripts/up-db.sh')], env=env, check=True, stdout=subprocess.DEVNULL)
            subprocess.run(['docker', 'exec', '--user', 'postgres', container, 'sh', '-c',
                            'for proc in /proc/[0-9]*; do taskset -apc '+env['PG_CPUS']+
                            ' "${proc##*/}" >/dev/null 2>&1 || true; done'], check=True)
            environments.append(env)
            metadata['slots'].append({k: env[k] for k in ('SERVER_CPUS', 'PG_CPUS', 'K6_CPUS',
                                                        'LINKDING_PG_CONTAINER', 'LINKDING_PG_PORT', 'BENCH_PORT')})
        (out/'run.json').write_text(json.dumps(metadata, indent=2)+'\n')

        def worker(slot):
            results = []
            while True:
                try:
                    impl, scenario, concurrency = tasks.get_nowait()
                except queue.Empty:
                    return results
                label = f'{impl}_{scenario}_c{concurrency}'
                log_dir = out/'logs'/label
                log_dir.mkdir(parents=True)
                env = dict(environments[slot], BENCH_SERVER_BIN=str(binaries[impl]),
                           BENCH_SCENARIOS=scenario, BENCH_CONCURRENCY=str(concurrency), LOG_DIR=str(log_dir))
                with (log_dir/'bench-all.log').open('w') as log:
                    code = subprocess.run(['bash', str(ROOT/'scripts/bench-all.sh'), impl],
                                          env=env, stdout=log, stderr=subprocess.STDOUT).returncode
                results.append(dict(impl=impl, scenario=scenario, concurrency=concurrency, slot=slot, exit_code=code))
                print(f'DONE slot={slot} {label} exit={code}', flush=True)

        with ThreadPoolExecutor(max_workers=5) as executor:
            results = list(executor.map(worker, range(5)))
        metadata.update(completed_utc=time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
                        tasks=[row for slot in results for row in slot])
        (out/'run.json').write_text(json.dumps(metadata, indent=2)+'\n')
        subprocess.run(['python3', str(ROOT/'bench/summarize.py'), str(out)], check=True)
        if any(row['exit_code'] for row in metadata['tasks']):
            raise SystemExit('A task failed; inspect logs before publishing results.')
    finally:
        for container in containers:
            subprocess.run(['docker', 'rm', '-f', container], check=False, stdout=subprocess.DEVNULL)


if __name__ == '__main__':
    main()
