import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import coverage


class WorkspaceFreshnessTests(unittest.TestCase):
    def test_certificate_ignores_proof_body_but_tracks_statement(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            src = root / "ports/example"
            files = [root / "harness/bench.py", root / "dataset/tasks.toml",
                     src / "proofs/lean-toolchain", src / "proofs/lake-manifest.json",
                     src / "proofs/Spec.lean", src / "proofs/Properties.lean"]
            for path in files:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("original")
            task = {"module": "Properties", "given": ["Spec.lean"]}
            with patch.object(coverage, "ROOT", root), patch.object(
                coverage.bench, "src_dir", return_value=src
            ), patch.object(coverage.bench, "APPLIB", root / "library"), patch.object(
                coverage.bench, "statement", return_value="(n : Nat) : n = n"
            ) as statement:
                initial = coverage.environment(task)
                (src / "proofs/Properties.lean").write_text("integrated proof body")
                self.assertEqual(initial, coverage.environment(task))
                statement.return_value = "(n : Nat) : n = 0"
                self.assertNotEqual(initial, coverage.environment(task))
                statement.return_value = "(n : Nat) : n = n"
                (src / "proofs/Spec.lean").write_text("changed policy")
                self.assertNotEqual(initial, coverage.environment(task))

    def test_manifest_change_invalidates_workspace(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            src = root / "ports/example"
            workspace = root / "tasks/example/workspace"
            for base in (src, workspace):
                (base / "proofs/generated").mkdir(parents=True)
                (base / "kernel/src").mkdir(parents=True)
                (base / "proofs/lean-toolchain").write_text("lean-pinned")
                (base / "proofs/lake-manifest.json").write_text("pinned-library")
            with patch.object(coverage, "ROOT", root), patch.object(
                coverage.bench, "src_dir", return_value=src
            ), patch.object(coverage.bench, "manifest", return_value="pinned-library"):
                self.assertTrue(coverage.workspace_current("example", {"given": []}))
                (workspace / "proofs/lake-manifest.json").write_text("other-library")
                self.assertFalse(coverage.workspace_current("example", {"given": []}))


if __name__ == "__main__":
    unittest.main()
