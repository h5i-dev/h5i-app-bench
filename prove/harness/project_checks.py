"""Run standard h5i-app project checks and retain their complete output."""
import argparse
import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APPS = ("nora", "artifactkeeper", "kanidm", "rustfs", "tuwunel", "oxicloud")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("check", "prove", "extract-check"))
    parser.add_argument("--app", nargs="+", choices=APPS, default=list(APPS))
    args = parser.parse_args()
    output = ROOT / "results/project-checks" / datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    output.mkdir(parents=True)
    rows = []
    for app in args.app:
        base = ROOT / "ports" / app
        files = [base / "h5i-app.toml", *base.glob("kernel/src/**/*.rs"),
                 *base.glob("proofs/**/*.lean"), base / "proofs/lean-toolchain",
                 base / "proofs/lake-manifest.json"]
        files = sorted(p for p in files if ".lake" not in p.parts)
        command = ["h5i", "app", "extract", "--check"] if args.action == "extract-check" else ["h5i", "app", args.action]
        command.append(str(base.relative_to(ROOT)))
        row = {"app": app, "command": command,
               "started_at": datetime.now(timezone.utc).isoformat(),
               "source_sha256": {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}}
        print(f"{app}: running {' '.join(command)}", flush=True)
        log = output / f"{app}.log"
        with log.open("w") as stream:
            process = subprocess.run(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
        row.update(exit_code=process.returncode, passed=process.returncode == 0,
                   finished_at=datetime.now(timezone.utc).isoformat(),
                   log=str(log.relative_to(ROOT)))
        rows.append(row)
        (output / "summary.json").write_text(json.dumps(rows, indent=2) + "\n")
        print(f"{app}: {'passed' if row['passed'] else 'failed'}; {row['log']}", flush=True)
    raise SystemExit(0 if all(row["passed"] for row in rows) else 1)


if __name__ == "__main__":
    main()
