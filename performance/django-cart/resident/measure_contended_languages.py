"""Explicitly contended GPU diagnostic; never substitutes official timings."""
import csv
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import statistics
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / 'languages'))
from run import command, ENV, digest
from summarize import SHAPES


def snapshot():
    return dict(utc=datetime.now(timezone.utc).isoformat(),
        devices=subprocess.check_output(['nvidia-smi', '--query-gpu=index,uuid,utilization.gpu,memory.used', '--format=csv'], text=True),
        processes=subprocess.check_output(['nvidia-smi', '--query-compute-apps=gpu_uuid,pid,process_name,used_memory', '--format=csv'], text=True))


def main():
    prior = HERE / 'languages/results/2026-10-20'
    out = HERE / 'languages/results/2026-10-20-contended'
    out.mkdir(parents=True, exist_ok=False)
    (out / 'raw').mkdir()
    fixtures = Path('/var/tmp/cart-language-fixtures')
    expected = json.loads((prior / 'expected_checksums.json').read_text())
    cpu = json.loads((prior / 'environment-cpu.json').read_text())
    for file, sha in cpu['sources'].items():
        assert digest(HERE.parent / file) == sha, file
    for file, sha in cpu['artifacts'].items():
        assert digest(file) == sha, file
    baseline = json.loads((prior / 'summary.json').read_text())
    meta = dict(utc=datetime.now(timezone.utc).isoformat(), contended=True,
        note='Diagnostic with external vLLM processes active on GPU 0. Not an isolated CPU/GPU speedup. Fixed prior best GPU path per shape; same canonical fixture and full owned output, eight changing warmups and 50 timed changing rounds, three resets/repetitions. No competing processes stopped or modified. No official timings replaced.',
        sources=cpu['sources'], artifacts=cpu['artifacts'], fixtures=cpu['fixtures'],
        script_sha256=digest(Path(__file__)), commands=[], snapshots=[])
    results = []
    def save():
        (out / 'environment.json').write_text(json.dumps(meta, indent=2) + '\n')
    # The measured GPU code and PTX are unchanged. Recheck upstream gates too.
    gates = {}
    variants = ['gpu-scan-compact-pinned-encode4', 'gpu-delta-compact-pinned-encode4']
    for variant in variants:
        gates[variant] = {}
        for cap, count in [(32, 166), (128, 190), (512, 214), (2048, 238)]:
            cmd = command(fixtures / f'gate-{cap}', variant, 0)
            dest = out / 'raw' / f'gate-{cap}-{variant}.csv'
            print(f'gate {variant} cap={cap}', flush=True)
            with dest.open('w') as raw:
                subprocess.run(cmd, stdout=raw, check=True, env=ENV)
            rows = list(csv.reader(dest.read_text().splitlines()))
            assert len(rows) == 1 and rows[0][:3] == [variant, '0', '0'] and int(rows[0][5]) == count
            other = list(csv.reader((prior / 'raw' / f'gate-{cap}-rust-1.csv').read_text().splitlines()))
            assert int(rows[0][6]) == int(other[0][6])
            gates[variant][str(cap)] = count
    (out / 'conformance.json').write_text(json.dumps(gates, indent=2) + '\n')
    with (out / 'rounds.csv').open('w') as aggregate:
        writer = csv.writer(aggregate)
        writer.writerow(['carts', 'lines', 'factor', 'variant', 'repeat', 'round', 'total_us', 'init_ms', 'checked_totals', 'checksum'])
        for n, cap, factor in SHAPES:
            point = next(p for p in baseline['points'] if (p['carts'], p['lines'], p['factor']) == (n, cap, factor))
            variant = point['best_gpu']
            prior_us = next(t['mean_us'] for t in point['timings'] if t['variant'] == variant)
            means = []
            for rep in range(3):
                meta['snapshots'].append(dict(shape=[n, cap, factor], repeat=rep, before=snapshot()))
                cmd = command(fixtures / f'{n}-{cap}-{factor}', variant, rep)
                meta['commands'].append(cmd); save()
                dest = out / 'raw' / f'{n}-{cap}-{factor}-{rep}-{variant}.csv'
                print(f'run {n}x{cap} updates/cart={factor} rep={rep} {variant}', flush=True)
                with dest.open('w') as raw:
                    subprocess.run(cmd, stdout=raw, check=True, env=ENV)
                meta['snapshots'][-1]['after'] = snapshot(); save()
                rows = list(csv.reader(dest.read_text().splitlines()))
                assert len(rows) == 58
                for r, row in enumerate(rows):
                    assert row[:3] == [variant, str(rep), str(r)]
                    assert int(row[5]) == n
                    assert int(row[6]) == expected[f'{n}-{cap}-{factor}'][r]
                    assert math.isfinite(float(row[3])) and float(row[3]) > 0
                    writer.writerow([n, cap, factor, *row])
                aggregate.flush()
                means.append(statistics.mean(float(row[3]) for row in rows[8:]))
            mean = statistics.mean(means)
            results.append(dict(carts=n, lines=cap, factor=factor, variant=variant,
                mean_us=mean, stdev_us=statistics.stdev(means), repeats_us=means,
                prior_gpu_us=prior_us, slowdown_vs_prior=mean/prior_us))
    data = dict(contended=True, note=meta['note'], rounds=696,
        checked_totals=sum(n for n, _, _ in SHAPES)*58*3, points=results)
    (out / 'summary.json').write_text(json.dumps(data, indent=2) + '\n')
    lines = ['# GPU rerun under external contention', '', meta['note'], '',
        '| Carts × lines | Updates/cart | Current GPU µs ± SD | Prior GPU µs | Current / prior |',
        '| --- | ---: | ---: | ---: | ---: |']
    for p in results:
        lines.append(f"| {p['carts']:,} × {p['lines']:,} | {p['factor']} | {p['mean_us']:.3f} ± {p['stdev_us']:.3f} | {p['prior_gpu_us']:.3f} | {p['slowdown_vs_prior']:.2f}× |")
    lines += ['', f"{data['rounds']:,} rounds, {data['checked_totals']:,} exact totals; 808 upstream cases for each of two GPU paths.", '']
    (out / 'summary.md').write_text('\n'.join(lines))
    print('\n'.join(lines), flush=True)


if __name__ == '__main__':
    main()
