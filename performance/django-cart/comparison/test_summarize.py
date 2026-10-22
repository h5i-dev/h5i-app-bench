import csv
import itertools
import json
from pathlib import Path
import tempfile
import unittest

from summarize import IMPLEMENTATIONS, METRICS, summarize


class PublicationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.config = dict(variants=IMPLEMENTATIONS, carts=[4096, 65536], concurrency=[1, 16, 64, 256],
                           repeats=3, warmup=10, duration=30, lines=32)
        self.write_config()
        (self.root / 'conformance.json').write_text(json.dumps({i: dict(decimal_cases=4146, freshness_updates=2, error_status_cases=3) for i in IMPLEMENTATIONS}))
        self.rows = [dict(impl=i, scenario=f'total_{c}', concurrency=n, repeat=r,
                          **{**dict.fromkeys(METRICS, 1), 'errors': 0}, checks_failed=0, http_requests=10)
                     for i, c, n, r in itertools.product(IMPLEMENTATIONS, [4096, 65536], [1, 16, 64, 256], range(3))]
        self.write_points()

    def write_config(self):
        (self.root / 'environment.json').write_text(json.dumps(dict(config=self.config)))

    def write_points(self):
        with (self.root / 'points.csv').open('w') as f:
            writer = csv.DictWriter(f, fieldnames=list(self.rows[0]))
            writer.writeheader()
            writer.writerows(self.rows)

    def test_complete_run_has_standard_metric_columns_and_implementation_order(self):
        rows = summarize(self.root)
        self.assertEqual(len(rows), 48)
        self.assertEqual(list(dict.fromkeys(r['impl'] for r in rows)), IMPLEMENTATIONS)
        report = (self.root / 'summary.md').read_text()
        self.assertIn('| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |', report)
        self.assertNotIn('points.csv', report)

    def test_smoke_timings_cannot_be_published(self):
        self.config['duration'] = 1
        self.write_config()
        with self.assertRaisesRegex(ValueError, 'publication requires'):
            summarize(self.root)

    def test_missing_point_duplicate_and_http_failure_are_rejected(self):
        last = self.rows.pop()
        self.write_points()
        with self.assertRaisesRegex(ValueError, 'incomplete grid'):
            summarize(self.root)
        self.rows.extend([last, last])
        self.write_points()
        with self.assertRaisesRegex(ValueError, 'duplicate point'):
            summarize(self.root)
        self.rows.pop()
        self.rows[-1]['checks_failed'] = 1
        self.write_points()
        with self.assertRaisesRegex(ValueError, 'failed or empty'):
            summarize(self.root)

    def test_missing_correctness_gate_is_rejected(self):
        (self.root / 'conformance.json').write_text('{}')
        with self.assertRaisesRegex(ValueError, 'missing correctness gate'):
            summarize(self.root)


if __name__ == '__main__':
    unittest.main()
