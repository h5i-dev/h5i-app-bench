"""A dashboard must not silently join incomparable language measurements."""
import csv
import importlib.util
from pathlib import Path
import shutil
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("cart_summary", Path(__file__).with_name("summarize.py"))
summary = importlib.util.module_from_spec(spec)
spec.loader.exec_module(summary)


class ComparisonGateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        original = Path(__file__).parent / "results/2026-10-19-scale"
        for name in ["points.csv", "go.csv", "javascript.csv"]:
            shutil.copyfile(original / name, self.root / name)

    def mutate_go(self, change):
        path = self.root / "go.csv"
        with path.open() as f:
            reader = csv.DictReader(f)
            fields, rows = reader.fieldnames, list(reader)
        change(rows)
        with path.open("w") as f:
            writer = csv.DictWriter(f, fieldnames=fields)
            writer.writeheader()
            writer.writerows(rows)

    def test_full_measured_grid(self):
        result = summary.summarize(self.root / "points.csv")
        self.assertEqual(len(result["points"]), 21)
        self.assertEqual(set(result["points"][0]["ms"]), set(summary.IMPLS))

    def test_rejects_different_data(self):
        self.mutate_go(lambda rows: rows[0].update(checksum="999"))
        with self.assertRaisesRegex(ValueError, "checksum mismatch"):
            summary.summarize(self.root / "points.csv")

    def test_rejects_missing_point(self):
        self.mutate_go(lambda rows: rows.pop())
        with self.assertRaisesRegex(ValueError, "Incomplete"):
            summary.summarize(self.root / "points.csv")

    def test_rejects_duplicate(self):
        self.mutate_go(lambda rows: rows.append(rows[0]))
        with self.assertRaisesRegex(ValueError, "Duplicate"):
            summary.summarize(self.root / "points.csv")


if __name__ == "__main__":
    unittest.main()
