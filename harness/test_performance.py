"""Reproducibility identities for paired timing runs."""
import hashlib
import unittest
from pathlib import Path
from unittest.mock import patch

import performance


class SourceIdentityTests(unittest.TestCase):
    def test_hashes_have_workspace_relative_names(self):
        path = performance.ROOT / "harness/performance.py"
        with patch.object(Path, "is_file", return_value=True), \
                patch.object(Path, "read_bytes", return_value=b"original"):
            self.assertEqual(performance.source_hashes([path]), {
                "harness/performance.py": hashlib.sha256(b"original").hexdigest()})

    def test_mutation_changes_identity(self):
        path = performance.ROOT / "harness/performance.py"
        with patch.object(Path, "is_file", return_value=True), \
                patch.object(Path, "read_bytes", side_effect=[b"before", b"after"]):
            self.assertNotEqual(performance.source_hashes([path]),
                                performance.source_hashes([path]))

    def test_deleted_source_is_recorded(self):
        path = performance.ROOT / "harness/performance.py"
        with patch.object(Path, "is_file", return_value=False):
            self.assertEqual(performance.source_hashes([path]), {"harness/performance.py": None})


if __name__ == "__main__":
    unittest.main()
