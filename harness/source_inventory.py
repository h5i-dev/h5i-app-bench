"""Inventory pinned upstream Rust denominators, independently of proof counts.

Bare upstream repositories live in results/upstream/<app>.git. Counts include
test code and use physical, nonblank lines (including comments): this baseline
must not be divided into historical logical-line port counts.
"""
import argparse
import io
import json
import subprocess
import tarfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES = {
    "nora": ("f864a9a", "nora-registry/src"),
    "artifactkeeper": ("7c42891", "backend/src"),
    "kanidm": ("f608c4f", "server/lib/src"),
    "rustfs": ("e870a6d", "crates/policy/src/policy"),
    "tuwunel": ("7801b8e", "src"),
    "oxicloud": ("8c0dd33", "src"),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", nargs="+", choices=SOURCES, default=list(SOURCES))
    args = parser.parse_args()
    output = ROOT / "results/source-coverage"
    output.mkdir(parents=True, exist_ok=True)
    rows = []
    for app in args.app:
        pin, scope = SOURCES[app]
        repository = ROOT / "results/upstream" / f"{app}.git"
        revision = subprocess.check_output(["git", "-C", str(repository), "rev-parse", pin], text=True).strip()
        print(f"{app}: reading {revision}:{scope}", flush=True)
        archive = subprocess.check_output(["git", "-C", str(repository), "archive", revision, scope])
        files = []
        with tarfile.open(fileobj=io.BytesIO(archive)) as tree:
            for entry in tree:
                if not entry.isfile() or not entry.name.endswith(".rs"):
                    continue
                text = tree.extractfile(entry).read().decode("utf-8")
                lines = text.splitlines()
                files.append({"path": entry.name, "physical_lines": len(lines),
                              "nonblank_physical_lines": sum(bool(line.strip()) for line in lines)})
        row = {"app": app, "upstream_revision": revision, "scope": scope,
               "denominator_kind": "selected_upstream_module_scope_including_tests_and_comments",
               "rust_files": len(files), "physical_lines": sum(f["physical_lines"] for f in files),
               "nonblank_physical_lines": sum(f["nonblank_physical_lines"] for f in files),
               "files": sorted(files, key=lambda f: f["path"]),
               "verified_source_coverage_percent": None,
               "limitation": "A mapped, deduplicated numerator with this same counting convention is still required; a property proof does not verify every behavior of its function."}
        rows.append(row)
        report = {"timestamp": datetime.now(timezone.utc).isoformat(), "apps": rows}
        (output / "inventory.json").write_text(json.dumps(report, indent=2) + "\n")
        print(f"{app}: {row['rust_files']} Rust files, {row['nonblank_physical_lines']} nonblank lines", flush=True)


if __name__ == "__main__":
    main()
