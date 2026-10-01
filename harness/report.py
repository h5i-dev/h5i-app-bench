"""Summarize results/runs/*/result.json as a Markdown table, one row per run,
and per model totals.

  python3 harness/report.py [--csv]
"""
import json, sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def runs():
    for f in sorted((ROOT / "results/runs").glob("*/result.json")):
        r = json.loads(f.read_text())
        if r.get("infra_error"):
            continue
        yield f.parent.name, r


def main():
    rows = []
    for name, r in runs():
        g = r["grade"]
        rows.append({
            "task": r["task"], "model": r["model"], "agent": r.get("agent", "codex"),
            "passed": g["passed"], "wall_min": round(r["wall_s"] / 60, 1), "cost_usd": r["cost_usd"],
            "lake_runs": r["lake_runs"], "lake_failures": r["lake_failures"],
            "first_clean": r.get("lake_first_clean"), "proof_loc": g.get("proof_loc"),
            "reason": "" if g["passed"] else g.get("reason", ""),
        })
    if "--csv" in sys.argv:
        print(",".join(rows[0]) if rows else "")
        for x in rows:
            print(",".join(str(v) for v in x.values()))
        return
    cols = list(rows[0]) if rows else []
    print("| " + " | ".join(cols) + " |")
    print("|" + "---|" * len(cols))
    for x in rows:
        print("| " + " | ".join(str(v) for v in x.values()) + " |")
    tot = defaultdict(lambda: [0, 0, 0.0, 0.0])
    for x in rows:
        t = tot[x["model"]]
        t[0] += 1
        t[1] += x["passed"]
        t[2] += x["cost_usd"]
        t[3] += x["wall_min"]
    print("\n| model | runs | solved | cost (USD) | minutes |\n|---|---|---|---|---|")
    for m, (n, s, c, w) in sorted(tot.items()):
        print(f"| {m} | {n} | {s} | {c:.2f} | {w:.0f} |")


if __name__ == "__main__":
    main()
