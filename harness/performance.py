"""Run paired Rust benchmarks and preserve reproducibility metadata."""
import argparse
import hashlib
import json
import os
import platform
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def capture(cmd):
    return subprocess.check_output(cmd, cwd=ROOT, text=True).strip()


def source_hashes(files):
    return {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
            if p.is_file() else None for p in files}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--app", choices=["nora", "tuwunel", "rustfs", "kanidm", "artifactkeeper", "oxicloud"], default="nora")
    ap.add_argument("--rounds", type=int)
    ap.add_argument("--profile", choices=["default", "pure-only"], default="default")
    args = ap.parse_args()
    if args.profile == "pure-only" and args.app not in ("oxicloud", "artifactkeeper"):
        ap.error("pure-only currently applies to OxiCloud and Artifact Keeper")
    rounds = args.rounds if args.rounds is not None else (100_000 if args.profile == "pure-only" else {"tuwunel":10, "artifactkeeper":10, "kanidm":100, "oxicloud":2}.get(args.app,100_000))
    if rounds <= 0:
        ap.error("rounds must be positive")
    base = ROOT / "ports" / args.app
    manifest = str((base / "difftest/Cargo.toml").relative_to(ROOT))
    cmd = ["cargo", "run", "--release", "--locked", "--manifest-path", manifest,
           "--bin", "performance", "--", str(rounds)]
    if args.profile == "pure-only":
        cmd.append("--pure-only")
    files = sorted(set([*base.glob("kernel/src/**/*.rs"),
             *base.glob("difftest/upstream/**/*.rs"),
             *base.glob("difftest/upstream/**/Cargo.toml"),
             *base.glob("difftest/src/**/*.rs"),
             base / "difftest/Cargo.lock", ROOT / manifest,
             base / "kernel/Cargo.toml", Path(__file__)]))
    if (base / "upstream-src").exists():
        files += sorted(p for p in (base / "upstream-src").rglob("*")
                        if p.is_file() and p.suffix in (".rs", ".toml"))
    run = {"timestamp": datetime.now(timezone.utc).isoformat(),
           "measurement_status": "pilot_not_publication",
           "rustc": capture(["rustc", "-Vv"]), "host": platform.platform(),
           "cpu": next((l.split(":", 1)[1].strip() for l in Path("/proc/cpuinfo").read_text().splitlines()
                        if l.startswith("model name")), platform.processor()),
           "load_average_before": os.getloadavg(),
           "revision": capture(["git", "rev-parse", "HEAD"]),
           "worktree": capture(["git", "status", "--short"]),
           "app": args.app,
           "profile": args.profile,
           "upstream_revision": {"nora": "f864a9a", "tuwunel": "7801b8e", "rustfs": "e870a6d", "kanidm":"f608c4f", "artifactkeeper":"7c42891", "oxicloud":"8c0dd33"}[args.app], "command": cmd,
           "source_sha256": source_hashes(files)}
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    run["source_sha256_after"] = source_hashes(files)
    run["sources_stable"] = run["source_sha256"] == run["source_sha256_after"]
    if not run["sources_stable"]:
        run["measurement_status"] = "invalid_sources_changed_during_run"
    run["load_average_after"] = os.getloadavg()
    run.update(exit_code=result.returncode, stderr=result.stderr)
    run["measurements"] = [json.loads(l) for l in result.stdout.splitlines()] if result.returncode == 0 else []
    if result.returncode:
        run["stdout"] = result.stdout
    out = ROOT / "results/performance"
    out.mkdir(parents=True, exist_ok=True)
    path = out / (datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ") + f"-{args.app}.json")
    path.write_text(json.dumps(run, indent=2) + "\n")
    print(path.relative_to(ROOT))
    for row in run["measurements"]:
        print(f"{row['benchmark']}: {row['kernel_over_upstream']:.3f}x")
    if result.returncode:
        raise SystemExit(result.stderr)
    if not run["sources_stable"]:
        raise SystemExit("Sources changed during measurement; result retained as invalid evidence.")


if __name__ == "__main__":
    main()
