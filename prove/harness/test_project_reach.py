import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from project_reach import dependencies, executable_lines, fresh_gate, project_files, theorem_type


class ProjectReachTests(unittest.TestCase):
    def test_proof_body_does_not_seed_reach(self):
        text = "theorem p (h : kernel.allowed x = ok true) : True := by\n  exact unrelated.big_proof\n"
        statement = theorem_type(text, "App.Properties.p")
        self.assertIn("kernel.allowed", statement)
        self.assertNotIn("big_proof", statement)

    def test_only_extracted_dependencies_are_followed(self):
        gen = {"kernel.allowed": {"kind": "def", "lean": "/-- [other.huge] -/\ndef kernel.allowed := helper.check"},
               "helper.check": {"kind": "def", "lean": "def helper.check := ok true"},
               "other.huge": {"kind": "def", "lean": "def other.huge := ok true"}}
        self.assertEqual(dependencies("kernel.allowed x = ok true", gen), {"kernel.allowed", "helper.check"})

    def test_duplicate_and_missing_statements_fail_closed(self):
        for text in ("theorem q : True := by trivial", "theorem p : True := by trivial\ntheorem p : True := by trivial"):
            with self.assertRaises(ValueError):
                theorem_type(text, "p")

    def test_ambiguous_methods_do_not_seed_reach(self):
        gen = {name: {"kind": "def", "lean": f"def {name} := ok true"}
               for name in ("left.Policy.validate", "right.Policy.validate")}
        self.assertEqual(dependencies("Policy.validate p = ok true", gen), set())
        self.assertEqual(dependencies("p.validate = ok true", gen), set())
        self.assertEqual(dependencies("other.Policy.validate p = ok true", gen), set())
        self.assertEqual(dependencies("left.Policy.validate p = ok true", gen),
                         {"left.Policy.validate"})
        self.assertEqual(dependencies("demo_kernel.left.Policy.validate p = ok true", gen),
                         {"left.Policy.validate"})

    def test_code_lines_are_physical_identities(self):
        self.assertEqual(executable_lines("// docs\n#[inline]\nfn x() {\n\n/* skip\nend */\n}\n"), {3, 7})

    def test_build_configuration_is_a_gate_input(self):
        with tempfile.TemporaryDirectory() as directory:
            port = Path(directory)
            (port / "kernel/.cargo").mkdir(parents=True)
            for relative in ("kernel/Cargo.toml", "kernel/Cargo.lock", "kernel/build.rs",
                             "kernel/.cargo/config.toml"):
                path = port / relative
                path.write_text("input")
                self.assertIn(path, project_files(port))

    def test_gate_rejects_new_inputs_and_latest_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            port = root / "ports/example"
            (port / "kernel/src").mkdir(parents=True)
            (port / "proofs").mkdir()
            (port / "h5i-app.toml").write_text('[check]\ntheorems = ["example.p"]\n')
            (port / "proofs/Properties.lean").write_text("theorem p : True := by trivial\n")
            evidence = root / "results/project-checks/001"
            evidence.mkdir(parents=True)
            row = {"app": "example", "command": ["h5i", "app", "check"], "passed": True,
                   "gated_theorems": ["example.p"],
                   "source_sha256": {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
                                     for p in project_files(port)}}
            (evidence / "summary.json").write_text(json.dumps([row]))
            self.assertIsNotNone(fresh_gate("example", root))
            added = port / "proofs/New.lean"
            added.write_text("-- input absent from old gate\n")
            self.assertIsNone(fresh_gate("example", root))
            added.unlink()
            later = root / "results/project-checks/002"
            later.mkdir()
            (later / "summary.json").write_text(json.dumps([row | {"passed": False}]))
            self.assertIsNone(fresh_gate("example", root))


if __name__ == "__main__":
    unittest.main()
