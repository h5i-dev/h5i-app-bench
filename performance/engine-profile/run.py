#!/usr/bin/env python3
"""Profile an unchanged application through its existing k6 HTTP workload.

Probes are aggregate counters. Raw captures remain in --out, never in git.
Runs use private PostgreSQL containers and disjoint server/DB/client CPUs.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import time

BENCH = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--app', choices=['linkding', 'realworld'], required=True)
p.add_argument('--binary', type=Path, required=True)
p.add_argument('--engine-seed-sql', type=Path,
               help='Override the h5i-app seed for controlled initialization comparisons')
p.add_argument('--out', type=Path, required=True)
p.add_argument('--scratch-root', type=Path, default=Path('/dev/shm/h5i-engine-profile'),
               help='Database and temporary files; default is RAM-backed, with no disk fallback')
p.add_argument('--mode', choices=['on', 'off', 'pristine'], default='on')
p.add_argument('--scenarios', required=True)
p.add_argument('--concurrency', default='1 64')
p.add_argument('--repeats', type=int, default=3)
p.add_argument('--warmup', type=int, default=5)
p.add_argument('--duration', type=int, default=15)
p.add_argument('--cpu-base', type=int, default=0)
p.add_argument('--pg-port', type=int, default=15710)
p.add_argument('--http-port', type=int, default=18410)
p.add_argument('--python', default=os.environ.get('PY', 'python3'),
               help='Python with PyJWT installed for the existing Conduit harness')
p.add_argument('--keep-going', action='store_true',
               help='Retain failed points and continue; errors remain in summaries')
a = p.parse_args()
a.scratch_root = a.scratch_root.resolve()
a.scratch_root.mkdir(parents=True, exist_ok=True)
if shutil.disk_usage(a.scratch_root).free < 4 * 1024**3:
    p.error('scratch filesystem needs at least 4 GiB free')
a.out = a.out.resolve()
a.out.mkdir(parents=True, exist_ok=False)
root = BENCH / 'performance' / a.app
engine_seed = (a.engine_seed_sql or root/'bench/seed_h5i_app.sql').read_bytes()
(a.out/'engine-seed.sql').write_bytes(engine_seed)
container = f'h5i-engine-{a.app}-{os.getpid()}'
first = a.cpu_base
prefix = 'LINKDING' if a.app == 'linkding' else 'CONDUIT'
env = dict(os.environ, **{
    f'{prefix}_PG_CONTAINER': container, f'{prefix}_PG_PORT': str(a.pg_port),
    f'{prefix}_PG_DATA': str(a.scratch_root/container),
    'TMPDIR': str(a.scratch_root),
    'CARGO_HOME': str(a.scratch_root/'cargo-home'),
    'CARGO_TARGET_DIR': str(a.scratch_root/'target'),
    'GOPATH': str(a.scratch_root/'gopath'), 'GOCACHE': str(a.scratch_root/'go-cache'),
    'GOMODCACHE': str(a.scratch_root/'go-mod-cache'),
    'PIP_CACHE_DIR': str(a.scratch_root/'pip-cache'),
    'npm_config_cache': str(a.scratch_root/'npm-cache'),
    'SERVER_CPUS': f'{first}-{first+3}', 'PG_CPUS': f'{first+4}-{first+7}', 'K6_CPUS': f'{first+8}-{first+11}',
    'BENCH_PORT': str(a.http_port), 'BENCH_OUT': str(a.out), 'LOG_DIR': str(a.out/'logs'),
    'BENCH_NO_SUMMARY': '1', 'BENCH_STRICT': '0' if a.keep_going else '1', 'BENCH_SERVER_BIN': str(a.binary.resolve()),
    'BENCH_SCENARIOS': a.scenarios, 'BENCH_CONCURRENCY': a.concurrency,
    'BENCH_REPEATS': str(a.repeats), 'BENCH_WARMUP': str(a.warmup), 'BENCH_DURATION': str(a.duration),
    'H5I_ENGINE_PROFILE': '1' if a.mode == 'on' else '0', 'PY': a.python,
})
env.pop('DATABASE_URL', None)
workload = (root / 'bench/workload.js').read_text()
if a.app == 'linkding':
    workload = workload.replace("gracefulStop: '5s'", "gracefulStop: '120s'")
(a.out/'workload.js').write_text(workload)
script = (root / 'scripts/bench-all.sh').read_text()
script = script.replace('$ROOT/bench/workload.js', str(a.out/'workload.js'))
script = script.replace('$ROOT/bench/seed_h5i_app.sql', str(a.out/'engine-seed.sql'))
script = script.replace('ROOT="$(cd "$(dirname "$0")/.." && pwd)"', 'ROOT=' + shlex.quote(str(root)))
if a.mode == 'on':
    script = script.replace('        meta_tmp="$OUT/${tag}.meta.json"',
        '        curl --fail --silent "$BASE/__engine_profile" > "$OUT/${tag}.profile.before.csv"\n        meta_tmp="$OUT/${tag}.meta.json"')
    script = script.replace('        kill "$sampler"',
        '        curl --fail --silent "$BASE/__engine_profile" > "$OUT/${tag}.profile.after.csv"\n        kill "$sampler"')
(a.out/'bench.sh').write_text(script)
metadata = {k: str(v) if isinstance(v, Path) else v for k,v in vars(a).items()}
metadata.update(binary_sha256=hashlib.sha256(a.binary.read_bytes()).hexdigest(),
    engine_seed_sha256=hashlib.sha256(engine_seed).hexdigest(),
    bench_revision=subprocess.check_output(['git','rev-parse','HEAD'], cwd=BENCH,text=True).strip(),
    started_utc=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),
    layout={k:env[k] for k in ['SERVER_CPUS','PG_CPUS','K6_CPUS']},
    storage={
        'database_path': env[f'{prefix}_PG_DATA'],
        'temporary_path': env['TMPDIR'],
        'scratch_free_bytes_before': shutil.disk_usage(a.scratch_root).free,
        'scratch_mount': subprocess.check_output(['findmnt','-T',str(a.scratch_root),'-n','-o','TARGET,FSTYPE,SOURCE'],text=True).strip(),
        'output_mount': subprocess.check_output(['findmnt','-T',str(a.out),'-n','-o','TARGET,FSTYPE,SOURCE'],text=True).strip(),
    })
try:
    subprocess.run([str(root/'scripts/up-db.sh')],env=env,check=True,stdout=subprocess.DEVNULL)
    metadata['postgres_shm_size_bytes'] = int(subprocess.check_output(
        ['docker', 'inspect', '-f', '{{.HostConfig.ShmSize}}', container], text=True))
    subprocess.run(['docker','exec','--user','postgres',container,'sh','-c',
        'for proc in /proc/[0-9]*; do taskset -apc '+env['PG_CPUS']+' "${proc##*/}" >/dev/null 2>&1 || true; done'],check=True)
    with (a.out/'harness.log').open('w') as log:
        job = subprocess.run(['bash',str(a.out/'bench.sh'),'rust-h5i'],env=env,stdout=log,stderr=subprocess.STDOUT)
    metadata['exit_code'] = job.returncode
    subprocess.run(['python3',str(root/'bench/summarize.py'),str(a.out)],check=True)
    if job.returncode:
        raise SystemExit(f'Benchmark failed: {a.out}/harness.log')
finally:
    metadata['storage']['scratch_free_bytes_after']=shutil.disk_usage(a.scratch_root).free
    metadata['completed_utc']=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())
    (a.out/'run.json').write_text(json.dumps(metadata,indent=2)+'\n')
    with (a.out/'postgres.log').open('w') as log:
        subprocess.run(['docker','logs',container],stdout=log,stderr=subprocess.STDOUT,check=False)
    subprocess.run(['docker','rm','-f',container],check=False,stdout=subprocess.DEVNULL)
