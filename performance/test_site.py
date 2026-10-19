"""Regression checks for replacing historical performance points."""
import csv
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import importlib.util

spec = importlib.util.spec_from_file_location("performance_site", Path(__file__).with_name("site.py"))
site = importlib.util.module_from_spec(spec)
spec.loader.exec_module(site)


class MeasurementSelectionTests(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
