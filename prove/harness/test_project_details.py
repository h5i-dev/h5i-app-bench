"""Check that the published proof browser covers the current, exact sources."""
import hashlib
import json
import tomllib
import unittest
from unittest.mock import patch
from pathlib import Path

from project_details import local_context, supporting_modules, write_details

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT.parent / "docs/prove/data"


class ProjectDetailsTests(unittest.TestCase):
    def test_stale_gate_cannot_publish_verified_property_details(self):
        index = json.loads((DATA / "index.json").read_text())
        with patch("project_details.fresh_gate", return_value=None), \
             patch("project_details.fresh_extraction", return_value=None):
            with self.assertRaisesRegex(ValueError, "missing or stale"):
                write_details(index, DATA)

    def test_local_helpers_and_open_proof_namespace(self):
        declarations = {"helper": "theorem helper : True := by exact Verified.Base.result",
                        "wrapper": "theorem wrapper : True := by exact helper"}
        helpers = local_context(declarations["wrapper"], declarations)
        self.assertEqual([h["name"] for h in helpers], ["helper"])
        modules = {"Verified.Base": {"code": "import Spec\ntheorem result : True := by trivial"},
                   "Spec": {"code": "def data := 0"},
                   "Verified.Other": {"code": "theorem unrelated : True := by trivial"}}
        self.assertEqual(supporting_modules("exact result", modules, "open Verified.Base\nopen Verified.Other"),
                         ["Spec", "Verified.Base"])

    def test_every_current_property_has_its_exact_coverage_source_pairs(self):
        index = json.loads((DATA / "index.json").read_text())
        rows = {t["id"]: t for t in index["project_tasks"]}
        expected = set()
        for app, info in index["apps"].items():
            with self.subTest(app=app):
                selected = tomllib.loads((ROOT / "ports" / app / "h5i-app.toml").read_text())["check"]["theorems"]
                expected.update(selected)
                asset = json.loads((DATA / "projects" / f"{app}.json").read_text())
                report = json.loads((ROOT / "results/source-coverage" / f"{app}-project-reach.json").read_text())
                self.assertEqual(set(asset["properties"]), set(selected))
                self.assertEqual(asset["revision"], report["upstream_revision"])
                for prop in report["properties"]:
                    name = prop["name"]
                    detail = asset["properties"][name]
                    self.assertEqual(detail["dependencies"], prop["generated_dependencies"])
                    self.assertIn("theorem " + name.rsplit(".", 1)[-1], detail["statement"])
                    self.assertEqual(rows[name]["app"], app)
                    expected_pairs = {}
                    for item in prop["items"]:
                        key = f"{item['file']}:{item['start']}-{item['end']}"
                        expected_pairs.setdefault(item["declaration"], []).append(key)
                        source = asset["upstream"][key]
                        self.assertEqual(hashlib.sha256(source["code"].encode()).hexdigest(), item["sha256"])
                        self.assertIn(asset["revision"], source["url"])
                    self.assertEqual(detail["items"], expected_pairs)
                    for declaration in detail["dependencies"]:
                        self.assertTrue(asset["declarations"][declaration]["code"].strip())
                    for module in detail["modules"]:
                        self.assertIn(module, asset["modules"])
        self.assertEqual(set(rows), expected)
        self.assertEqual(len(index["project_tasks"]), len(expected))
        self.assertEqual(len(rows), index["stats"]["properties"])


if __name__ == "__main__":
    unittest.main()
