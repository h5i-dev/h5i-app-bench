"""Refresh the pinned circuit-breaker reference with explicit test adapters."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

PIN = "f864a9a95e8669b00202c18b0b774ab0fc2e56cc"
SOURCE = "nora-registry/src/circuit_breaker.rs"

source = subprocess.check_output(
    ["git", "--git-dir=" + sys.argv[1], "show", PIN + ":" + SOURCE], text=True
)
production = source.split("#[cfg(test)]")[0]
adapted = "\n".join(line for line in production.splitlines() if not line.startswith("//!"))
adapted = adapted.replace("use std::time::Instant;", "use crate::Instant;")
adapted = adapted.replace("Debug, Clone, serde::Serialize", "Debug, Clone")
root = Path(__file__).parent
(root / "reference.rs").write_text(
    "// Generated from the pinned source; only clock/derive adapters, see identity.json.\n"
    + adapted + "\n"
)
(root / "identity.json").write_text(json.dumps({
    "upstream_revision": PIN,
    "file": SOURCE,
    "file_sha256": hashlib.sha256(source.encode()).hexdigest(),
    "production_sha256": hashlib.sha256(production.encode()).hexdigest(),
    "adapters": [
        "Instant uses deterministic elapsed-second clock",
        "Remove serde serialization derive and inner module documentation",
        "Test crate supplies config, lock, metrics and logging adapters",
    ],
}, indent=2) + "\n")
