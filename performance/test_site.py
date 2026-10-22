"""Regression checks for replacing historical performance points."""
import csv
from pathlib import Path
import tempfile
import unittest
import json
import subprocess
from unittest.mock import patch

import importlib.util

spec = importlib.util.spec_from_file_location("performance_site", Path(__file__).with_name("site.py"))
site = importlib.util.module_from_spec(spec)
spec.loader.exec_module(site)


class MeasurementSelectionTests(unittest.TestCase):
    def test_framework_comparison_keeps_strategy_results_separate(self):
        self.assertEqual([a['id'] for a in site.APPS], ['realworld', 'linkding', 'django-cart'])
        cart = site.load(site.APPS[-1])
        self.assertEqual([i['id'] for i in cart['impls']], site.COMPARISON_ORDER)
        self.assertEqual(cart['rows'], [])
        self.assertEqual(cart['concurrency'], [1, 16, 64, 256])
        self.assertEqual([s['id'] for s in cart['scenarios']], ['total_4096', 'total_65536'])
        experiments = [site.load(a) for a in site.SUPPLEMENTAL_APPS]
        self.assertEqual([a['id'] for a in experiments], ['django-cart-batching', 'django-cart-lines'])
        self.assertIn('go-sql', [i['id'] for i in experiments[0]['impls']])
        self.assertGreater(len(experiments[0]['rows']), 0)

    def test_overview_renders_identical_columns_and_pending_details(self):
        # Exercise the actual JS renderer against the generated data, including
        # absent framework values and preserved supplemental measurements.
        data = json.loads((site.HERE.parent / 'docs/performance/data.json').read_text())
        script = (site.HERE.parent / 'docs/performance/performance.js').read_text().split('\nmain().catch')[0]
        check = r'''
const vm = require('node:vm');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const input = JSON.parse(fs.readFileSync(0, 'utf8'));
const target = {innerHTML: ''};
const context = vm.createContext({document: {querySelector: () => target, querySelectorAll: () => []}});
vm.runInContext(input.script, context);
context.fixture = input.data;
vm.runInContext('DATA = fixture; renderOverview()', context);
const heads = [...target.innerHTML.matchAll(/<thead>(.*?)<\/thead>/gs)].map(m =>
  [...m[1].matchAll(/<span class="impl[^"]*">([^<]+)<\/span>/g)].map(n => n[1]));
assert.equal(heads.length, 3);
for (const head of heads) assert.deepEqual(head, input.order);
const detail = vm.runInContext('pick["django-cart"] = "total_4096"; renderApp(DATA.apps[2])', context);
assert.ok(!detail.includes('NaN') && !detail.includes('Infinity'));
assert.equal((detail.match(/class="sub"/g) || []).length, 6);
const supplemental = vm.runInContext('for (const app of allApps()) pick[app.id] = app.scenarios[0].id; renderSections(DATA.supplemental_apps)', context);
assert.ok(supplemental.includes('go-sql') && supplemental.includes('rust-gpu-batch'));
'''
        result = subprocess.run(['node', '-e', check], input=json.dumps(dict(data=data, script=script, order=site.COMPARISON_ORDER)),
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_new_run_replaces_old_point_and_retains_other_clients(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            results = root / "linkding/bench/results"
            results.mkdir(parents=True)
            fields = ["impl", "scenario", "concurrency", "reps", *site.FIELDS]

            def write(name, points):
                path = results / name
                path.parent.mkdir(parents=True, exist_ok=True)
                with path.open("w") as f:
                    writer = csv.DictWriter(f, fieldnames=fields)
                    writer.writeheader()
                    for clients, rps in points:
                        writer.writerow(dict(impl="rust-h5i", scenario="search", concurrency=clients,
                                             reps=3, **dict.fromkeys(site.FIELDS, rps)))

            write("summary.csv", [(1, 1), (16, 2), (64, 3)])
            write("refresh-2026-10-19/summary.csv", [(1, 10), (16, 20)])
            app = dict(id="linkding", title="linkding", upstream="", about="", seed="",
                       scenarios={"search": "q=alpha"}, summaries=["refresh-2026-10-19/summary.csv"])
            with patch.object(site, "HERE", root), patch.object(site, "last_change", return_value="2026-10-17"):
                data = site.load(app)
                rows = data["rows"]
                self.assertEqual([(r["concurrency"], r["rps"]) for r in rows], [(1, 10), (16, 20), (64, 3)])
                self.assertEqual(rows[1]["measured"], "2026-10-19")
                self.assertTrue(rows[1]["source"].endswith("refresh-2026-10-19/summary.csv"))
                self.assertEqual(data["measured"], "2026-10-17–2026-10-19")
                write("refresh-2026-10-19/summary.csv", [(16, 20), (16, 30)])
                with self.assertRaisesRegex(ValueError, "Duplicate measurement"):
                    site.load(app)

    def test_dated_results_directory_and_batch_counters(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);results=root / "django-cart/http/results/2026-10-19";results.mkdir(parents=True)
            fields=["impl","scenario","concurrency","reps",*site.FIELDS,"mean_batch","mean_queue_wait_ms","sql_queries","gpu_launches"]
            with (results/"summary.csv").open("w") as f:
                writer=csv.DictWriter(f,fieldnames=fields);writer.writeheader()
                writer.writerow(dict(impl="rust-gpu-batch",scenario="total_4096",concurrency=16,reps=3,**dict.fromkeys(site.FIELDS,1),mean_batch=8,mean_queue_wait_ms=1,sql_queries=100,gpu_launches=100))
            app=dict(id="django-cart",title="totals",upstream="",about="",seed="",scenarios={"total_4096":"total"},results="http/results/2026-10-19")
            with patch.object(site,"HERE",root):data=site.load(app)
            self.assertEqual(data["rows"][0]["mean_batch"],8)
            self.assertEqual(data["rows"][0]["measured"],"2026-10-19")
            self.assertTrue(data["rows"][0]["source"].endswith("django-cart/http/results/2026-10-19/summary.csv"))
            self.assertFalse(data["impls"][0]["h5i"])

    def test_shared_directory_and_unmeasured_phases(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); results = root/'django-cart/http/lines/results/2026-10-19'
            results.mkdir(parents=True)
            fields = ['impl', 'scenario', 'concurrency', 'reps', *site.FIELDS,
                      'sql_fetch_ms_per_batch', 'pack_ms_per_batch', 'compute_ms_per_batch']
            with (results/'summary.csv').open('w') as f:
                writer = csv.DictWriter(f, fieldnames=fields); writer.writeheader()
                for impl, phase in [('go-sql', ''), ('rust-gpu-cooperative', .125)]:
                    writer.writerow(dict(impl=impl, scenario='lines_2048', concurrency=256,
                        reps=3, **dict.fromkeys(site.FIELDS, 1),
                        **dict.fromkeys(fields[-3:], phase)))
            app = dict(id='django-cart-lines', directory='django-cart', title='scaling',
                       nav_title='Cart scaling', upstream='', about='', seed='',
                       results='http/lines/results/2026-10-19', scenarios={'lines_2048': 'total'})
            with patch.object(site, 'HERE', root): data = site.load(app)
            self.assertNotIn('compute_ms_per_batch', data['rows'][0])
            self.assertEqual(data['rows'][1]['compute_ms_per_batch'], .125)
            self.assertIn('/django-cart/http/lines/', data['rows'][1]['source'])
            self.assertTrue(data['source'].endswith('/django-cart'))
            self.assertEqual(data['nav_title'], 'Cart scaling')


if __name__ == "__main__":
    unittest.main()
