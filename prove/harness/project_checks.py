"""Run standard h5i-app project checks and retain their complete output."""
import argparse
import hashlib
import json
import os
import re
import signal
import subprocess
import tomllib
from datetime import datetime, timezone
from pathlib import Path
from project_reach import project_files

ROOT = Path(__file__).resolve().parent.parent
APPS = ("nora", "artifactkeeper", "kanidm", "rustfs", "tuwunel", "oxicloud")


def run_check(command, cwd, stream, timeout):
    """Bound the entire process group, including Lake/Lean descendants."""
    with subprocess.Popen(command, cwd=cwd, stdout=stream, stderr=subprocess.STDOUT,
                          start_new_session=True) as process:
        try:
            return process.wait(timeout=timeout), False
        except subprocess.TimeoutExpired:
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                pass
            # A child can ignore SIGTERM even after the parent has exited.
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait()
            stream.write(f"\nproject_checks: timed out after {timeout} seconds; process group stopped\n")
            return 124, True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("check", "prove", "extract-check"))
    parser.add_argument("--app", nargs="+", choices=APPS, default=list(APPS))
    parser.add_argument("--timeout", type=int, default=1800,
                        help="maximum seconds per app, including child processes (default: 1800)")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
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
        if args.action == "extract-check" and os.environ.get("GIT_WORK_TREE"):
            row["extraction_source_path_root"] = os.environ["GIT_WORK_TREE"]
        print(f"{app}: running {' '.join(command)}", flush=True)
        log = output / f"{app}.log"
        with log.open("w") as stream:
            code, timed_out = run_check(command, ROOT, stream, args.timeout)
        row.update(exit_code=code, passed=code == 0, timed_out=timed_out,
                   timeout_seconds=args.timeout,
                   finished_at=datetime.now(timezone.utc).isoformat(),
                   log=str(log.relative_to(ROOT)))
        reports = sorted((base / ".h5i/app/runs").glob("*/run.json"))
        if reports and args.action in ("check", "prove"):
            report = json.loads(reports[-1].read_text())
            if report.get("started", 0) >= datetime.fromisoformat(row["started_at"]).timestamp() - 1:
                row["reported_stages"] = [{k: s[k] for k in ("name", "status", "seconds") if k in s}
                                          for s in report.get("stages", [])]
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
