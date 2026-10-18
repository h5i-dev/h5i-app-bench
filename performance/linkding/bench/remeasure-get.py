#!/usr/bin/env python3
"""Compare prebuilt get-route variants concurrently, rotating CPU/DB slots.

Raw outputs stay in a new /dev/shm directory. Publish only summary CSV/Markdown.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import socket
import subprocess

SLOTS = [('0-3', '4-7', '8-11'), ('12-15', '16-19', '20-23'),
         ('24-27', '28-31', '32-35')]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ['before', 'after', 'go']:
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--k6', type=Path, default=Path('/var/tmp/tools/k6'))
    parser.add_argument('--pg-port', type=int, default=15725)
    parser.add_argument('--http-port', type=int, default=18425)
    args = parser.parse_args()
    out = args.out.resolve()
    if not out.is_relative_to('/dev/shm') or out.exists():
        parser.error('--out must be a new directory under /dev/shm')
    binaries = {n: getattr(args, n).resolve() for n in ['before', 'after', 'go']}
    for binary in [*binaries.values(), args.k6]:
        if not binary.is_file() or not os.access(binary, os.X_OK):
            parser.error(f'not executable: {binary}')
    # The shared harness owns its HTTP port and may stop its previous listener.
    # Check that the ports are unused before allowing it to start.
    for port in [args.pg_port + i for i in range(3)] + [args.http_port + i for i in range(3)]:
        with socket.socket() as sock:
            sock.bind(('127.0.0.1', port))
    root = Path(__file__).resolve().parents[1]
    containers = [f'h5i-single-get-{os.getpid()}-{i}' for i in range(3)]
    existing = subprocess.check_output(['docker', 'ps', '-a', '--format', '{{.Names}}'], text=True).splitlines()
    if any(c in existing for c in containers):
        parser.error('experiment container name already exists')
    out.mkdir(parents=True)
    env = os.environ | {
        'TMPDIR': '/dev/shm', 'BENCH_WARMUP': '5', 'BENCH_DURATION': '15',
        'BENCH_REPEATS': '1', 'BENCH_CONCURRENCY': '1 64', 'BENCH_SCENARIOS': 'get',
        'BENCH_STRICT': '1', 'BENCH_NO_SUMMARY': '1', 'WEB_CONCURRENCY': '4',
        'LINKDING_PG_SHM_SIZE': '1g', 'K6': str(args.k6.resolve()),
    }
    for key in ['CARGO_HOME', 'CARGO_TARGET_DIR', 'GOPATH', 'GOCACHE', 'GOMODCACHE',
                'PIP_CACHE_DIR', 'npm_config_cache', 'XDG_CACHE_HOME']:
        env[key] = str(out / key.lower())
    metadata = {
        'revision': subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD'], text=True).strip(),
        'binaries': {n: {'path': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
                     for n, p in binaries.items()},
        'slots': SLOTS, 'containers': containers, 'warmup_s': 5, 'measurement_s': 15,
        'concurrency': [1, 64], 'orders': [['before', 'after', 'go'], ['after', 'go', 'before'], ['go', 'before', 'after']],
    }
    (out / 'metadata.json').write_text(json.dumps(metadata, indent=2) + '\n')

    def arm(rep, name, slot):
        server, pg, client = SLOTS[slot]
        arm_env = env | {
            'SERVER_CPUS': server, 'PG_CPUS': pg, 'K6_CPUS': client,
            'BENCH_SERVER_BIN': str(binaries[name]), 'BENCH_IMPL_LABEL': name,
            'BENCH_OUT': str(out / f'{name}-r{rep}'),
            'LOG_DIR': str(out / f'logs-{name}-r{rep}'),
            'LINKDING_PG_CONTAINER': containers[slot],
            'LINKDING_PG_PORT': str(args.pg_port + slot),
            'LINKDING_PG_DATA': str(out / f'pg-{slot}'),
            'DATABASE_URL': f'postgres://linkding:linkding@127.0.0.1:{args.pg_port + slot}/linkding',
            'BENCH_PORT': str(args.http_port + slot),
        }
        with (out / f'{name}-r{rep}.log').open('w') as log:
            subprocess.run([str(root / 'scripts/bench-all.sh'),
                            'go' if name == 'go' else 'rust-h5i-optimized'],
                           env=arm_env, stdout=log, stderr=subprocess.STDOUT, check=True)
        return name

    try:
        for rep, order in enumerate(metadata['orders'], 1):
            with ThreadPoolExecutor(max_workers=3) as pool:
                futures = [pool.submit(arm, rep, name, i) for i, name in enumerate(order)]
                for future in futures:
                    print('MEASURED', rep, future.result(), flush=True)
    finally:
        # Names were checked absent and are reserved exclusively for this run.
        for container in containers:
            subprocess.run(['docker', 'rm', '-f', container], stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL, check=False)


if __name__ == '__main__':
    main()
