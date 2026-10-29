"""Keep current source reach separate from the immutable benchmark history."""
import copy
import hashlib
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import dashboard


class DashboardAccountingTests(unittest.TestCase):
    def refresh(self, extraction):
        index = {
            "apps": {"example": {"specs": 1, "accepted": 1, "spec_loc": 2,
                                  "proof_loc": 3, "upstream_reached": 19}},
            "stats": {}, "models": [{"name": "original", "accepted": 99}],
            "tasks": [{"status": "accepted", "runs": ["original proof"]},
                      {"status": "unproved", "runs": []}],
        }
        history = copy.deepcopy((index["tasks"], index["models"]))
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            port = root / "ports/example"
            (port / "proofs").mkdir(parents=True)
            (port / "proofs/Properties.lean").write_text("theorem p : True := by trivial\n")
            manifest = port / "h5i-app.toml"
            manifest.write_text('[check]\ntheorems = ["example.p"]\n')
            mapping = root / "harness/source-mappings/example.json"
            mapping.parent.mkdir(parents=True)
            mapping.write_text("{}")
            row = {"passed": True, "gated_theorems": ["example.p"],
                   "source_sha256": {"ports/example/h5i-app.toml": hashlib.sha256(manifest.read_bytes()).hexdigest()},
                   "finished_at": "2026-10-29", "log": "check.log"}
            reach = {"upstream_reached": 23, "upstream_revision": "pin",
                     "mapping_sha256": "hash", "meaning": "deduplicated dependency reach"}
            with patch.object(dashboard, "ROOT", root), patch.object(dashboard, "gates", return_value={}), \
                 patch("project_reach.fresh_gate", return_value=row), \
                 patch("project_reach.fresh_extraction", return_value=extraction), \
                 patch("project_reach.measure", return_value=reach) as measure:
                dashboard.refresh_project_checks(index)
                self.assertEqual(measure.call_count, int(bool(extraction)))
        self.assertEqual((index["tasks"], index["models"]), history)
        self.assertEqual(index["stats"]["benchmark_properties"], 2)
        self.assertEqual(index["stats"]["benchmark_accepted"], 1)
        self.assertEqual(index["stats"]["benchmark_upstream_reached"], 19)
        return index

    def test_formal_gate_without_fresh_extraction_has_no_current_source_credit(self):
        index = self.refresh(None)
        self.assertEqual(index["stats"]["current_source_matched_lines"], 0)
        self.assertEqual(index["stats"]["historical_fallback_lines"], 19)
        self.assertFalse(index["stats"]["whole_project_verified"])
        self.assertEqual(index["apps"]["example"]["coverage_basis"], "historical_benchmark_snapshot")

    def test_fresh_source_replaces_overlapping_benchmark_lines(self):
        index = self.refresh({"log": "extract.log"})
        self.assertEqual(index["stats"]["current_source_matched_lines"], 23)
        self.assertEqual(index["stats"]["historical_fallback_lines"], 0)
        self.assertEqual(index["stats"]["upstream_reached"], 23)
        self.assertTrue(index["stats"]["whole_project_verified"])


if __name__ == "__main__":
    unittest.main()
