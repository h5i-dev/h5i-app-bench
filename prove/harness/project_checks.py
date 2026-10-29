"""Run standard h5i-app project checks and retain their complete output."""
import argparse
import hashlib
import json
import re
import subprocess
import tomllib
from datetime import datetime, timezone
from pathlib import Path
from project_reach import project_files

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
        files = project_files(base)
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
        after = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                 for p in project_files(base)}
        row["inputs_unchanged"] = after == row["source_sha256"]
        if not row["inputs_unchanged"]:
            row.update(passed=False, source_changed_during_check=True)
        if row["passed"] and args.action in ("check", "prove"):
            gate = re.search(r"gate: (\d+) theorems in (\d+) modules checked", log.read_text())
            if gate:
                row.update(gated_theorems=tomllib.loads((base / "h5i-app.toml").read_text())["check"]["theorems"],
                           checked_theorems=int(gate[1]), checked_modules=int(gate[2]))
        rows.append(row)
        (output / "summary.json").write_text(json.dumps(rows, indent=2) + "\n")
        print(f"{app}: {'passed' if row['passed'] else 'failed'}; {row['log']}", flush=True)
    raise SystemExit(0 if all(row["passed"] for row in rows) else 1)


if __name__ == "__main__":
    main()
