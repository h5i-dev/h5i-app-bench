"""Inventory and recertify existing proofs, independently of model scores.

python3 harness/coverage.py
python3 harness/coverage.py --check nora-digest
python3 harness/coverage.py --check-all
"""
import argparse
import hashlib
import json
import re
import tempfile
from datetime import datetime, timezone
from pathlib import Path

import bench

ROOT = bench.ROOT


def workspace_current(tid, t):
    src = bench.src_dir(t)
    ws = ROOT / "tasks" / tid / "workspace"
    manifest_path = ws / "proofs/lake-manifest.json"
    manifest_matches = (manifest_path.exists()
                        and manifest_path.read_text() == bench.manifest(t))
    paths = [Path("proofs/lean-toolchain"),
             *[Path("proofs") / g for g in t["given"]],
             *[p.relative_to(src) for p in (src / "proofs/generated").glob("*.lean")],
             *[p.relative_to(src) for p in (src / "kernel/src").glob("*.rs")]]
    return ws.exists() and manifest_matches and all((ws / p).exists() and (src / p).read_bytes() == (ws / p).read_bytes()
                               for p in paths)


def environment(t):
    src = bench.src_dir(t)
    files = [ROOT / "harness/bench.py", ROOT / "dataset/tasks.toml",
             src / "proofs/lean-toolchain",
             src / "proofs/lake-manifest.json",
             *sorted((src / "kernel/src").glob("*.rs")),
             *sorted((src / "proofs/generated").glob("*.lean")),
             *[src / "proofs" / g for g in t["given"]],
             *sorted(bench.APPLIB.rglob("*.lean"))]
    inputs = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in files
              if ".lake" not in p.parts}
    # The isolated grader imports Spec/generated/library, not Properties.
    # Only the selected statement is read from Properties. Changing another
    # proof body therefore cannot change this certification boundary.
    inputs["target_statement_sha256"] = hashlib.sha256(bench.statement(t).encode()).hexdigest()
    inputs["certificate_boundary_version"] = "2"
    return inputs


def candidates(tid):
    """Historical success is a candidate, never current certification."""
    app = tid.split("-", 1)[0]
    maintained = ROOT / "ports" / app / "proofs/solutions" / tid / "Solution.lean"
    if maintained.exists():
        yield str(maintained.relative_to(ROOT)), maintained.read_text()
    for result in sorted((ROOT / "results/runs").glob("*/result.json")):
        r = json.loads(result.read_text())
        solution = result.parent / "workspace/proofs/Solution.lean"
        if r.get("task") == tid and r.get("grade", {}).get("passed") and solution.exists():
            yield str(solution.relative_to(ROOT)), solution.read_text()
    # The proof a previous certificate accepted, so a changed input can be
    # rechecked even after its original source (a run, the archive) is gone.
    accepted = ROOT / "results/verification" / tid / "Solution.lean"
    if accepted.exists():
        yield str(accepted.relative_to(ROOT)), accepted.read_text()
    archive = ROOT / "docs/data/tasks" / f"{tid}.json"
    if archive.exists():
        for p in json.loads(archive.read_text()).get("proofs", []):
            if p.get("code"):
                yield str(archive.relative_to(ROOT)) + ":" + p["column"], p["code"]


def compatible_candidates(tid):
    """Keep historical text intact; expose namespace-only migration explicitly."""
    for source, code in candidates(tid):
        if "hiding lit" not in code:
            adapted = re.sub(r"^(open[^\n]*?)\s+H5iAppLib\s*$",
                             r"\1\nopen H5iAppLib hiding lit", code, flags=re.M)
            if adapted != code:
                yield source + ":hide-lib-lit", adapted
        yield source, code


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", nargs="+", default=[])
    ap.add_argument("--check-all", action="store_true")
    ap.add_argument("--certificate-only", action="store_true",
                    help="Check only the named tasks without rewriting the shared coverage ledger")
    args = ap.parse_args()
    if args.certificate_only and (not args.check or args.check_all):
        ap.error("--certificate-only requires --check and cannot accompany --check-all")
    all_tasks = bench.tasks(extra=False)
    tasks = {tid: t for tid, t in all_tasks.items() if t["src"].startswith("bench:ports/")}
    legacy = [tid for tid in all_tasks if tid not in tasks]
    unknown = set(args.check) - tasks.keys()
    if unknown:
        ap.error(f"unknown tasks: {sorted(unknown)}")
    out = ROOT / "results/verification"
    out.mkdir(parents=True, exist_ok=True)
    rows = []
    for tid, t in tasks.items():
        if args.certificate_only and tid not in args.check:
            continue
        # Deduplicate proofs published both in runs and the dashboard.
        proofs = {}
        for source, code in compatible_candidates(tid):
            digest = hashlib.sha256(code.encode()).hexdigest()
            proofs.setdefault(digest, (source, code))
        row = {"id": tid, "repo": t["repo"], "src": t["src"],
               "theorem": t["theorem"], "candidates": len(proofs),
               "status": "candidate" if proofs else "missing", "checks": []}
        certificate = out / tid / "certificate.json"
        accepted = out / tid / "Solution.lean"
        if certificate.exists() and accepted.exists():
            saved = json.loads(certificate.read_text())
            if (saved.get("grade", {}).get("passed") and saved.get("inputs") == environment(t)
                    and saved.get("sha256") == hashlib.sha256(accepted.read_bytes()).hexdigest()):
                row["status"] = "previously_checked"
                row["certificate"] = str(certificate.relative_to(ROOT))
        if proofs and (tid in args.check or (args.check_all and row["status"] != "previously_checked")):
            inputs = environment(t)
            if not workspace_current(tid, t):
                bench.build(tid)
            for digest, (source, code) in proofs.items():
                with tempfile.TemporaryDirectory(dir=out) as tmp:
                    path = Path(tmp) / "Solution.lean"
                    path.write_text(code)
                    grade = bench.grade(tid, path)
                row["checks"].append({"source": source, "sha256": digest, "grade": grade,
                    "checked_at": datetime.now(timezone.utc).isoformat(), "inputs": inputs})
                dest = out / tid
                dest.mkdir(exist_ok=True)
                (dest / "attempts.json").write_text(json.dumps(row["checks"], indent=2) + "\n")
                print(f"{tid}: {'accepted' if grade['passed'] else grade.get('reason')}", flush=True)
                if grade["passed"]:
                    (dest / "Solution.lean").write_text(code)
                    # Preserve evidence per task even if a later check is interrupted.
                    (dest / "certificate.json").write_text(json.dumps(row["checks"][-1], indent=2) + "\n")
                    row["status"] = "checked"
                    break
            if proofs and row["status"] != "checked":
                row["status"] = "failed"
        rows.append(row)
        # Checkpoint the current invocation; never count old certificates as fresh.
        summary = {"selected_specs": len(tasks), "legacy_tasks_outside_port_corpus": legacy,
                   "inventoried_specs": len(rows),
                   "with_candidates": sum(r["candidates"] > 0 for r in rows),
                   "checked_this_run": sum(r["status"] == "checked" for r in rows),
                   "accepted_specs": sum(r["status"] in ("checked", "previously_checked") for r in rows),
                   "selected_spec_completion_percent": 100 * sum(r["status"] in ("checked", "previously_checked") for r in rows) / len(tasks),
                   "upstream_code_coverage_percent": None,
                   "tasks": rows}
        if not args.certificate_only:
            (out / "coverage.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps({k: v for k, v in summary.items() if k != "tasks"}, indent=2))


if __name__ == "__main__":
    main()
