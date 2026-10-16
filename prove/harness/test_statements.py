"""Protect the original selected statements while proof bodies are replaced."""
import re
import subprocess
import unittest

import bench


class OriginalStatementTests(unittest.TestCase):
    def test_selected_statement_types_are_unchanged(self):
        originals = {}
        selected = [task for task in bench.tasks(extra=False).values()
                    if task["src"].startswith("bench:ports/")]
        self.assertEqual(len(selected), 103)
        for task in selected:
            path = str((bench.src_dir(task) / "proofs" / f"{task['module']}.lean").relative_to(bench.ROOT))
            if path not in originals:
                originals[path] = subprocess.check_output(
                    ["git", "show", f"HEAD:{path}"], cwd=bench.ROOT, text=True)
            name = task["theorem"].rsplit(".", 1)[1]
            match = re.search(rf"^theorem {re.escape(name)}\b(.*?)\s:=(?:\s|$)",
                              originals[path], re.S | re.M)
            self.assertIsNotNone(match, task["id"])
            self.assertEqual(match.group(1).rstrip(), bench.statement(task), task["id"])


if __name__ == "__main__":
    unittest.main()
