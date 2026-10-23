"""Framework comparison. Raw artifacts stay local; publish only summaries."""
import argparse
import csv
import importlib.util
import json
import os
from pathlib import Path
import random
import signal
import subprocess
import sys
import time
import urllib.request

HERE = Path(__file__).resolve().parent
APP = HERE.parent
spec = importlib.util.spec_from_file_location('cart_http', APP / 'http/run.py')
http = importlib.util.module_from_spec(spec)
spec.loader.exec_module(http)
IMPLEMENTATIONS = ['rust-h5i', 'rust-h5i-optimized', 'rust-h5i-gpu', 'fastapi', 'go', 'fastify']
# Reuse the exact Decimal/ORM/freshness/error-status gates, without changing
# the historical batching runner's variant definitions on disk.
http.VARIANTS = {name: ('rust', 'gpu' if name == 'rust-h5i-gpu' else 'sql', 1, 0) for name in IMPLEMENTATIONS}


class Resources(http.Resources):
    """RSS and CPU for the whole server tree, including Python/Node workers."""
    def sample(self):
        ticks = os.sysconf('SC_CLK_TCK')
        previous = None
        while not self.done.is_set():
            pending, seen = [self.pid], set()
            rss = cpu = 0
            while pending:
                pid = pending.pop()
                if pid in seen:
                    continue
                seen.add(pid)
                try:
                    proc = Path(f'/proc/{pid}')
                    fields = (proc / 'stat').read_text().rsplit(')', 1)[1].split()
                    cpu += (int(fields[11]) + int(fields[12])) / ticks
                    for line in (proc / 'status').read_text().splitlines():
                        if line.startswith('VmRSS:'):
                            rss += int(line.split()[1]) / 1024
                    for children in (proc / 'task').glob('*/children'):
                        pending.extend(map(int, children.read_text().split()))
                except (FileNotFoundError, ProcessLookupError):
                    pass
            now = time.monotonic()
            self.rss = max(self.rss, rss)
            if previous:
                self.cpu = max(self.cpu, (cpu - previous[1]) / (now - previous[0]) * 100)
            previous = (now, cpu)
            self.done.wait(.1)


class Bench(http.Bench):
    def start_db(self):
        super().start_db()
        # Install engine metadata once, then expose the shared physical data
        # as complete per-cart tenants. No stale copy or separate freshness path.
        self.start('rust-h5i', 'install')
        self.sql((HERE / 'engine-views.sql').read_text())
        self.stop()
        path = self.out / 'environment.json'
        meta = json.loads(path.read_text())
        sources = [p for folder in ['comparison', 'fastapi', 'fastify', 'rust-h5i']
                   for p in (APP / folder).rglob('*')
                   if p.is_file() and not any(part in ('node_modules', '__pycache__', 'results', 'target') for part in p.parts)]
        meta['source_sha256'].update({str(p.relative_to(APP)): http.digest(p) for p in sources})
        meta['artifact_sha256'].update({p: http.digest(p) for p in [self.args.engine, self.args.go]})
        meta['note'] = 'Framework comparison: one cart/HTTP request, fresh PostgreSQL, no request batching. Four server cores. Python/Node use four workers with eight connections each; Rust CPU and Go use 32 connections. GPU uses the validated single-request CUDA adapter with one SQL/CUDA worker, fresh transfers and no collection window. h5i engine uses complete per-cart tenants and the default transaction path. Pricing has differential tests, no application-specific Lean proof.'
        path.write_text(json.dumps(meta, indent=2) + '\n')

    def start(self, name, label):
        commands = {
            'rust-h5i': [self.args.engine],
            'rust-h5i-optimized': [self.args.engine],
            'rust-h5i-gpu': [self.args.rust],
            'go': [self.args.go, 'serve'],
            'fastapi': [self.args.python, '-m', 'uvicorn', 'app:app', '--app-dir', str(APP / 'fastapi'), '--host', '127.0.0.1', '--port', str(self.http_port), '--workers', '4', '--no-access-log'],
            'fastify': [self.args.node, str(APP / 'fastify/server.mjs')],
        }
        env = {**os.environ, 'DATABASE_URL': self.url, 'PORT': str(self.http_port),
               'MODE': 'engine' if name == 'rust-h5i' else 'gpu' if name == 'rust-h5i-gpu' else 'sql',
               'BATCH_MAX': '1', 'BATCH_WAIT_US': '0', 'DB_POOL': '32', 'WEB_CONCURRENCY': '4',
               'GOMAXPROCS': '4', 'PTX': self.args.ptx, 'CUDA_VISIBLE_DEVICES': self.args.gpu_device,
               'LD_LIBRARY_PATH': '/usr/local/cuda-12.6/lib64'}
        self.log = (self.work / f'{label}-{name}.log').open('w')
        self.server = subprocess.Popen(['taskset', '-c', self.args.server_cpus, *commands[name]], env=env,
                                       stdout=self.log, stderr=subprocess.STDOUT, start_new_session=True)
        for _ in range(400):
            if self.server.poll() is not None:
                raise RuntimeError(f'{name} exited; see {self.log.name}')
            try:
                with urllib.request.urlopen(self.base + '/health', timeout=.3) as response:
                    if response.status == 200:
                        return
            except OSError:
                pass
            time.sleep(.05)
        raise RuntimeError(f'{name} startup timeout; see {self.log.name}')

    def stop(self):
        if self.server:
            # uvicorn and Node cluster workers are in the same process group.
            try:
                os.killpg(self.server.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                self.server.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(self.server.pid, signal.SIGKILL)
                self.server.wait()
            self.server = None
        if self.log:
            self.log.close()
            self.log = None

    def measure(self):
        fields = ['impl', 'scenario', 'concurrency', 'repeat', 'rps', 'p50_ms', 'p90_ms', 'p99_ms',
                  'errors', 'checks_failed', 'http_requests', 'rss_peak_mb', 'cpu_peak_pct']
        with (self.out / 'points.csv').open('w') as f:
            writer = csv.DictWriter(f, fieldnames=fields)
            writer.writeheader()
            for carts in self.args.carts:
                for clients in self.args.concurrency:
                    for rep in range(self.args.repeats):
                        names = list(self.args.variants)
                        random.Random(carts + clients * 31 + rep * 104729).shuffle(names)
                        for name in names:
                            self.seed(carts)
                            self.start(name, f'{carts}-{clients}-{rep}')
                            if self.args.warmup:
                                self.k6(name, clients, carts, rep, warm=True)
                            with Resources(self.server.pid) as resources:
                                data = self.k6(name, clients, carts, rep)['metrics']
                            latency = data['http_req_duration']
                            writer.writerow(dict(impl=name, scenario=f'total_{carts}', concurrency=clients, repeat=rep,
                                rps=data['http_reqs']['rate'], p50_ms=latency['p(50)'], p90_ms=latency['p(90)'], p99_ms=latency['p(99)'],
                                errors=data['http_req_failed']['passes'], checks_failed=data['checks']['fails'],
                                http_requests=data['http_reqs']['count'], rss_peak_mb=resources.rss, cpu_peak_pct=resources.cpu))
                            f.flush()
                            self.stop()
                            print('POINT', name, carts, clients, rep, flush=True)


def main():
    p = argparse.ArgumentParser(__doc__)
    p.add_argument('--out', default=str(HERE / 'results' / time.strftime('%Y-%m-%d', time.gmtime())))
    p.add_argument('--work', default='/var/tmp/cart-comparison-run')
    p.add_argument('--engine', default='/var/tmp/cart-comparison-target/release/cart-server')
    p.add_argument('--go', default='/var/tmp/cart-comparison-go')
    p.add_argument('--go-bin', default='/var/tmp/go/bin/go')
    p.add_argument('--python', default='/var/tmp/cart-comparison-venv/bin/python')
    p.add_argument('--node', default='node')
    p.add_argument('--rust', default='/var/tmp/h5i-gpu-target/release/examples/serve')
    p.add_argument('--ptx', default='/var/tmp/h5i-gpu-target/nvptx64-nvidia-cuda/release/django_cart_gpu_device.ptx')
    p.add_argument('--gpu-device', default='0')
    p.add_argument('--fixtures', default='/var/tmp/django-cart-fixtures.bin')
    p.add_argument('--checker', default='/var/tmp/django-cart-target/release/cart-check')
    p.add_argument('--k6', default='/var/tmp/k6-extract/k6-v2.3.0-linux-amd64/k6')
    p.add_argument('--server-cpus', default='64-67')
    p.add_argument('--pg-cpus', default='68-71')
    p.add_argument('--client-cpus', default='72-75')
    p.add_argument('--carts', type=int, nargs='+', default=[4096, 65536])
    p.add_argument('--concurrency', type=int, nargs='+', default=[1, 16, 64, 256])
    p.add_argument('--duration', type=int, default=30)
    p.add_argument('--warmup', type=int, default=10)
    p.add_argument('--repeats', type=int, default=3)
    p.add_argument('--variants', nargs='+', choices=IMPLEMENTATIONS, default=IMPLEMENTATIONS)
    p.add_argument('--conformance-only', action='store_true')
    args = p.parse_args()
    args.lines = 32
    if min(args.carts + args.concurrency + [args.duration, args.repeats]) < 1 or args.warmup < 0:
        p.error('counts and duration must be positive; warmup must be nonnegative')
    if 'rust-h5i-gpu' in args.variants and not args.conformance_only:
        active = subprocess.check_output(['nvidia-smi', '-i', args.gpu_device, '--query-compute-apps=pid', '--format=csv,noheader'], text=True).strip()
        if active:
            p.error('GPU has external compute processes; rerun when idle (conformance-only remains available)')
    bench = Bench(args)
    try:
        bench.start_db()
        bench.oracle()
        if not args.conformance_only:
            bench.measure()
    finally:
        bench.cleanup()


if __name__ == '__main__':
    main()
