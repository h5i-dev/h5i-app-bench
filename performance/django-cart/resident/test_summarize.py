import csv
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('resident_summary', Path(__file__).with_name('summarize.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PublicationTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.gates = {str(c): dict(decimal_cases=n, variants=5) for c, n in zip(module.CAPS, [166, 190, 214, 238])}
        (self.root / 'conformance.json').write_text(json.dumps(self.gates))
        self.rows = []
        for impl in module.IMPLS:
            for cap in module.CAPS:
                for n in module.QUERIES:
                    for u in [0, 1, n, n*16]:
                        for rep in range(3):
                            self.rows.append(dict(impl=impl, lines=cap, carts=4096, queries=n, updates=u, repeat=rep, iterations=100, checked_totals=n*108, mean_us=10+rep, p50_us=9+rep, p99_us=15+rep, init_ms=1, input_bytes=4096*(2*cap+3)*8, command_bytes=(n+4*u)*8, result_bytes=n*8, checksum=100))

    def write(self, rows):
        with (self.root / 'points.csv').open('w') as f:
            w = csv.DictWriter(f, fieldnames=self.rows[0])
            w.writeheader(); w.writerows(rows)

    def test_complete(self):
        self.write(self.rows)
        data = module.summarize(self.root)
        self.assertEqual(len(data['points']), 64)
        self.assertEqual(data['points'][0]['timings']['cpu-delta']['mean_us'], 11)
        self.assertEqual(data['points'][0]['timings']['cpu-delta']['stdev_us'], 1)
        self.assertEqual(data['checked_totals'], sum(r['checked_totals'] for r in self.rows))

    def test_invalid_points(self):
        for field, value in [('updates', 2), ('queries', 0), ('iterations', 99), ('checked_totals', 1), ('input_bytes', 1), ('command_bytes', 1), ('result_bytes', 1), ('checksum', 1), ('mean_us', float('nan')), ('p99_us', 0)]:
            with self.subTest(field=field):
                bad = [dict(r) for r in self.rows]
                bad[0][field] = value
                self.write(bad)
                with self.assertRaises(ValueError):
                    module.summarize(self.root)
        for rows in [self.rows[:-1], self.rows + [self.rows[0]]]:
            self.write(rows)
            with self.assertRaises(ValueError):
                module.summarize(self.root)

    def test_missing_upstream_gate(self):
        self.write(self.rows)
        self.gates['2048']['variants'] = 4
        (self.root / 'conformance.json').write_text(json.dumps(self.gates))
        with self.assertRaises(ValueError):
            module.summarize(self.root)


if __name__ == '__main__':
    unittest.main()
