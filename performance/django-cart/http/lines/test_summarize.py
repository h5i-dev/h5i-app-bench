"""Publication gates for the line-count experiment."""
import csv
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('lines_summary', HERE / 'summarize.py')
summary = importlib.util.module_from_spec(spec)
spec.loader.exec_module(summary)
VARIANTS = ['go-sql', 'javascript-sql', 'rust-sql', 'go-batch', 'javascript-batch',
            'rust-cpu-batch', 'rust-cpu-parallel', 'rust-gpu-batch', 'rust-gpu-cooperative']

class PublicationTests(unittest.TestCase):
    def fixture(self, root):
        config = dict(variants=VARIANTS, line_counts=[32], concurrency=[16], repeats=2,
                      dataset_carts=4096, duration=5, warmup=1)
        (root / 'environment.json').write_text(json.dumps(dict(config=config)))
        gates = {f'32:{name}': dict(decimal_cases=166, orm_cases=4,
                 freshness_updates=2, error_status_cases=3) for name in VARIANTS}
        (root / 'conformance.json').write_text(json.dumps(gates))
        rows = []
        for name in VARIANTS:
            for rep in range(2):
                row = dict.fromkeys(summary.METRICS, 1)
                row.update(impl=name, scenario='lines_32', lines=32, carts=4096,
                           concurrency=16, repeat=rep, rps=100+rep*20, errors=0,
                           checks_failed=0, http_requests=100, server_requests=100,
                           batches=100 if name.endswith('sql') else 10,
                           sql_queries=100 if name.endswith('sql') else 10, cart_rows=100,
                           mean_batch=1 if name.endswith('sql') else 10,
                           max_batch_since_start=1 if name.endswith('sql') else 10,
                           gpu_launches=10 if 'gpu' in name else 0)
                row.update(dict.fromkeys(summary.PHASES,
                    0.1 if name.startswith('rust-') and not name.endswith('sql') else ''))
                rows.append(row)
        return rows

    def write(self, root, rows):
        with (root / 'points.csv').open('w') as f:
            writer = csv.DictWriter(f, fieldnames=rows[0])
            writer.writeheader()
            writer.writerows(rows)

    def test_complete_means_and_absent_phase_data(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); rows = self.fixture(root); self.write(root, rows)
            result = summary.summarize(root)
            self.assertEqual(len(result), 9)
            self.assertEqual(result[0]['rps'], 110)
            self.assertAlmostEqual(result[0]['rps_stdev'], 2**0.5*10)
            self.assertEqual(result[0]['compute_ms_per_batch'], '')
            self.assertEqual(result[-1]['compute_ms_per_batch'], .1)
            self.assertIn('1,800 responses checked', (root/'summary.md').read_text())
            self.assertIn('| 32 | 10.000 | 10.000 | 10.000 | 33.33%',
                          (root/'summary.md').read_text())

    def test_rejects_bad_measurements(self):
        changes = [('errors', 1), ('checks_failed', 1), ('lines', 128),
                   ('carts', 65536), ('gpu_launches', 1), ('rps', 'nan'),
                   ('sql_queries', 9), ('server_requests', 99),
                   ('mean_batch', 9), ('compute_ms_per_batch', .2)]
        for field, value in changes:
            with self.subTest(field=field), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp); rows = self.fixture(root); rows[0][field] = value
                self.write(root, rows)
                with self.assertRaises(ValueError): summary.summarize(root)
        for duplicate in (False, True):
            with self.subTest(duplicate=duplicate), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp); rows = self.fixture(root)
                rows = rows + [rows[0]] if duplicate else rows[:-1]
                self.write(root, rows)
                with self.assertRaises(ValueError): summary.summarize(root)

    def test_rejects_missing_conformance(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); self.write(root, self.fixture(root))
            gates = json.loads((root/'conformance.json').read_text())
            gates['32:rust-gpu-cooperative']['freshness_updates'] = 0
            (root/'conformance.json').write_text(json.dumps(gates))
            with self.assertRaisesRegex(ValueError, 'correctness gate'): summary.summarize(root)

if __name__ == '__main__': unittest.main()
