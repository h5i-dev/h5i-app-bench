"""Run differential/falsification suites with retained logs and source hashes."""
import argparse
import hashlib
import json
import os
import platform
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APPS = ["nora", "artifactkeeper", "kanidm", "rustfs", "tuwunel", "oxicloud"]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--apps", nargs="+", choices=APPS, default=APPS)
    args = ap.parse_args()
    out = ROOT / "results/equivalence" / datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    out.mkdir(parents=True)
    rows = []
    for app in args.apps:
        base = ROOT / "ports" / app
        files = sorted(set([*base.glob("kernel/src/**/*.rs"),
                           *base.glob("difftest/src/**/*.rs"),
                           *base.glob("difftest/upstream/**/*.rs"),
                           *base.glob("difftest/upstream/**/Cargo.toml"),
                           *base.glob("difftest/sqlx-mock/**/*.rs"),
                           base / "difftest/Cargo.toml", base / "difftest/Cargo.lock",
                           base / "kernel/Cargo.toml"]))
        if (base / "upstream-src").exists():
            files += sorted(p for p in (base / "upstream-src").rglob("*")
                            if p.is_file() and p.suffix in (".rs", ".toml", ".sql"))
        cmd = ["cargo", "test", "--release", "--locked", "--manifest-path",
               f"ports/{app}/difftest/Cargo.toml", "--", "--nocapture", "--test-threads=1"]
        log = out / f"{app}.log"
        start = time.monotonic()
        print(f"{app}: running; log {log.relative_to(ROOT)}", flush=True)
        with log.open("w") as stream:
            result = subprocess.run(cmd, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
        rows.append({"app": app, "command": cmd, "exit_code": result.returncode,
                     "elapsed_seconds": time.monotonic() - start,
                     "log": str(log.relative_to(ROOT)),
                     "source_sha256": {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                                       for p in files},
                     "evidence": "randomized differential and property tests; not formal equivalence"})
        summary = {"timestamp": datetime.now(timezone.utc).isoformat(),
                   "rustc": subprocess.check_output(["rustc", "-Vv"], text=True).strip(),
                   "host": platform.platform(), "selected_apps": args.apps,
                   "completed_apps": len(rows), "load_average": os.getloadavg(), "runs": rows}
        (out / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
        print(f"{app}: {'passed' if result.returncode == 0 else 'failed'}", flush=True)
    raise SystemExit(int(any(r["exit_code"] for r in rows)))


if __name__ == "__main__":
    main()
