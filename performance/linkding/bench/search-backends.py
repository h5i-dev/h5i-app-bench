#!/usr/bin/env python3
"""Compare SQL, packed CPU and resident GPU HTTP search on one seeded DB.

Read-only: does not create/reseed the DB or build binaries. Each point restarts
the server, checks its entire first response against SQL, then warms and loads
it with k6. Run against a dedicated DB with schema.sql + bench/seed.sql.
"""
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time
import urllib.parse
import urllib.request


QUERIES = {
    'alpha': 'alpha',
    'heavy': '(alpha or beta) and not (missing or absent) and (gamma or delta) and not (unknown and zeta)',
}


def get(url, token):
    request = urllib.request.Request(url, headers={'Authorization': 'Token ' + token})
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def cpu_seconds(pid):
    fields = Path(f'/proc/{pid}/stat').read_text().split(') ', 1)[1].split()
    return (int(fields[11]) + int(fields[12])) / os.sysconf('SC_CLK_TCK')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cpu-bin', required=True, type=Path)
    parser.add_argument('--gpu-bin', required=True, type=Path)
    parser.add_argument('--ptx', required=True, type=Path)
    parser.add_argument('--database-url', required=True)
    parser.add_argument('--out', required=True, type=Path)
    parser.add_argument('--port', type=int, default=18179)
    parser.add_argument('--server-cpus', default='0-3')
    parser.add_argument('--client-cpus', default='8-11')
    parser.add_argument('--k6', default='/var/tmp/tools/k6')
    parser.add_argument('--warmup', type=int, default=3)
    parser.add_argument('--duration', type=int, default=10)
    parser.add_argument('--repeats', type=int, default=3)
    parser.add_argument('--concurrency', type=int, nargs='+', default=[1, 16])
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    token = 'a' * 40
    base = f'http://127.0.0.1:{args.port}'
    metadata = {key: str(value) if isinstance(value, Path) else value
                for key, value in vars(args).items() if key != 'database_url'}
    metadata['sha256'] = {key: hashlib.sha256(path.read_bytes()).hexdigest()
                          for key, path in [('cpu', args.cpu_bin), ('gpu', args.gpu_bin), ('ptx', args.ptx)]}
    metadata['started_utc'] = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
    metadata['revision'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
    metadata['gpu'] = subprocess.check_output(['nvidia-smi', '--query-gpu=index,name,driver_version', '--format=csv'], text=True)
    (args.out / 'metadata.json').write_text(json.dumps(metadata, indent=2) + '\n')
    gold = {}
    columns = ['backend', 'query', 'concurrency', 'repeat', 'count', 'cold_ms',
               'rps', 'p50_ms', 'p95_ms', 'p99_ms', 'failed', 'check_fails',
               'server_cpu_cores', 'server_peak_rss_kib']
    with (args.out / 'points.csv').open('w') as points:
        writer = csv.DictWriter(points, fieldnames=columns)
        writer.writeheader()
        for rep in range(args.repeats):
            # Rotate the backend order, with SQL first in repeat 0 for the oracle.
            order = ['sql', 'cpu', 'gpu']
            order = order[rep % 3:] + order[:rep % 3]
            for name, query in QUERIES.items():
                url = base + '/api/bookmarks/?' + urllib.parse.urlencode({'q': query, 'limit': 20})
                for concurrency in args.concurrency:
                    for backend in order:
                        tag = f'{backend}_{name}_c{concurrency}_r{rep + 1}'
                        env = dict(os.environ, DATABASE_URL=args.database_url, PORT=str(args.port),
                                   WEB_CONCURRENCY='4', DB_POOL='32', H5I_SEARCH_QUEUE='32',
                                   H5I_SEARCH_CACHE_ENTRIES='0' if backend == 'sql' else '8',
                                   H5I_SEARCH_CACHE_MIB='256', H5I_GPU_PTX=str(args.ptx.resolve()),
                                   CUDA_VISIBLE_DEVICES='0')
                        binary = args.gpu_bin if backend == 'gpu' else args.cpu_bin
                        with (args.out / f'{tag}.server.log').open('w') as log:
                            server = subprocess.Popen(['taskset', '-c', args.server_cpus, str(binary.resolve())],
                                                      env=env, stdout=log, stderr=log)
                            try:
                                for _ in range(200):
                                    if server.poll() is not None:
                                        raise RuntimeError(f'{tag}: server exited')
                                    try:
                                        with urllib.request.urlopen(base + '/healthz', timeout=2) as health:
                                            assert health.status == 200
                                        break
                                    except Exception:
                                        time.sleep(0.05)
                                else:
                                    raise RuntimeError(f'{tag}: health timeout')
                                started = time.perf_counter()
                                response = get(url, token)
                                cold_ms = (time.perf_counter() - started) * 1000
                                if name not in gold:
                                    assert backend == 'sql'
                                    gold[name] = response
                                    (args.out / f'{name}.oracle.json').write_text(json.dumps(response, indent=2) + '\n')
                                assert response == gold[name], f'{tag}: first response differs from SQL'
                                for phase, duration in [('warmup', args.warmup), ('measure', args.duration)]:
                                    before = cpu_seconds(server.pid)
                                    wall = time.perf_counter()
                                    summary = args.out / f'{tag}.{phase}.json'
                                    command = ['taskset', '-c', args.client_cpus, args.k6, 'run', '--quiet',
                                               '--summary-export', str(summary), '-e', f'URL={url}',
                                               '-e', f'TOKEN={token}', '-e', f'EXPECTED_COUNT={response["count"]}',
                                               '-e', f'VUS={concurrency}', '-e', f'DURATION={duration}s',
                                               str(Path(__file__).with_suffix('.js'))]
                                    with (args.out / f'{tag}.{phase}.log').open('w') as client_log:
                                        subprocess.run(command, stdout=client_log, stderr=subprocess.STDOUT, check=True)
                                    cores = (cpu_seconds(server.pid) - before) / (time.perf_counter() - wall)
                                metrics = json.loads(summary.read_text())['metrics']
                                server_log = (args.out / f'{tag}.server.log').read_text()
                                if backend == 'sql':
                                    assert 'resident search cache disabled' in server_log, f'{tag}: SQL mode not active'
                                else:
                                    assert 'SQL fallback' not in server_log, f'{tag}: unexpectedly fell back to SQL'
                                trend = metrics['http_req_duration']
                                rss = next(line.split()[1] for line in Path(f'/proc/{server.pid}/status').read_text().splitlines()
                                           if line.startswith('VmHWM:'))
                                row = dict(backend=backend, query=name, concurrency=concurrency, repeat=rep + 1,
                                           count=response['count'], cold_ms=cold_ms, rps=metrics['http_reqs']['rate'],
                                           p50_ms=trend['p(50)'], p95_ms=trend['p(95)'], p99_ms=trend['p(99)'],
                                           failed=metrics['http_req_failed']['value'], check_fails=metrics['checks']['fails'],
                                           server_cpu_cores=cores, server_peak_rss_kib=rss)
                                writer.writerow(row)
                                points.flush()
                                print(f'{tag}: {row["rps"]:.1f} req/s p50={row["p50_ms"]:.2f}ms '
                                      f'p99={row["p99_ms"]:.2f}ms cold={cold_ms:.1f}ms', flush=True)
                            finally:
                                server.terminate()
                                try:
                                    server.wait(timeout=10)
                                except subprocess.TimeoutExpired:
                                    server.kill()
                                    server.wait()


if __name__ == '__main__':
    main()
