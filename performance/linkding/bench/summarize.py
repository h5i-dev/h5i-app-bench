#!/usr/bin/env python3
"""Turn bench/results/*.summary.json and *.meta.json into CSV and markdown."""
import csv
import json
import math
import statistics
import sys
from collections import defaultdict
from pathlib import Path

SCENARIOS = [
    "list",
    "search",
    "search_tag",
    "get",
    "create",
    "update",
    "archive",
    "tags",
    "mixed",
]
IMPLS = ["fastapi", "go", "fastify", "rust-h5i-optimized", "rust-h5i", "upstream"]


def load_point(summary_path: Path):
    meta_path = summary_path.with_name(summary_path.name.replace(".summary.json", ".meta.json"))
    summary = json.loads(summary_path.read_text())
    meta = json.loads(meta_path.read_text()) if meta_path.exists() else {}
    metrics = summary.get("metrics", {})
    reqs = metrics.get("http_reqs", {})
    dur = metrics.get("http_req_duration", {})
    failed = metrics.get("http_req_failed", {})
    return {
        "impl": meta.get("impl", ""),
        "scenario": meta.get("scenario", ""),
        "concurrency": int(meta.get("concurrency", 0)),
        "rep": int(meta.get("rep", 0)),
        "rps": float(reqs.get("rate", 0.0)),
        "p50_ms": float(dur.get("p(50)", dur.get("med", 0.0))),
        "p90_ms": float(dur.get("p(90)", 0.0)),
        "p99_ms": float(dur.get("p(99)", 0.0)),
        "errors": int(failed.get("passes", 0)),
        "requests": int(reqs.get("count", 0)),
        "rss_peak_kb": int(meta.get("rss_peak_kb", 0)),
        "cpu_peak_pct": float(meta.get("cpu_peak_pct", 0.0)),
        "cpu_avg_pct": float(meta.get("cpu_avg_pct", 0.0)),
    }


def mean(xs):
    return statistics.fmean(xs) if xs else 0.0


def stdev(xs):
    return statistics.stdev(xs) if len(xs) > 1 else 0.0


def fmt(n, digits):
    if isinstance(n, float) and (math.isnan(n) or math.isinf(n)):
        return ""
    return f"{n:.{digits}f}"


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "results")
    points = [load_point(p) for p in sorted(root.glob("*.summary.json"))]
    raw_path = root / "points.csv"
    with raw_path.open("w", newline="") as fh:
        fields = [
            "impl",
            "scenario",
            "concurrency",
            "rep",
            "rps",
            "p50_ms",
            "p90_ms",
            "p99_ms",
            "errors",
            "requests",
            "rss_peak_kb",
            "cpu_peak_pct",
            "cpu_avg_pct",
        ]
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        for row in points:
            writer.writerow(row)

    groups = defaultdict(list)
    for row in points:
        groups[(row["impl"], row["scenario"], row["concurrency"])].append(row)

    summary_rows = []
    for key in sorted(
        groups,
        key=lambda k: (
            SCENARIOS.index(k[1]) if k[1] in SCENARIOS else 99,
            IMPLS.index(k[0]) if k[0] in IMPLS else 99,
            k[2],
        ),
    ):
        rows = groups[key]
        summary_rows.append(
            {
                "impl": key[0],
                "scenario": key[1],
                "concurrency": key[2],
                "reps": len(rows),
                "rps": mean([r["rps"] for r in rows]),
                "rps_stdev": stdev([r["rps"] for r in rows]),
                "p50_ms": mean([r["p50_ms"] for r in rows]),
                "p90_ms": mean([r["p90_ms"] for r in rows]),
                "p99_ms": mean([r["p99_ms"] for r in rows]),
                "errors": mean([r["errors"] for r in rows]),
                "rss_peak_mb": mean([r["rss_peak_kb"] for r in rows]) / 1024.0,
                "cpu_peak_pct": mean([r["cpu_peak_pct"] for r in rows]),
                "cpu_avg_pct": mean([r["cpu_avg_pct"] for r in rows]),
            }
        )

    sum_path = root / "summary.csv"
    with sum_path.open("w", newline="") as fh:
        fields = list(summary_rows[0].keys()) if summary_rows else ["impl"]
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        for row in summary_rows:
            writer.writerow(row)

    lines = [
        "# Benchmark summary",
        "",
        "Means of the recorded repetitions. Requests/s is k6 `http_reqs.rate`.",
        "Latencies are milliseconds (`p(50)`, `p(90)`, `p(99)`). Errors are the",
        "mean count of failed HTTP requests. RSS is the peak sum of VmRSS across",
        "the server process tree, in MiB. CPU percent is 100 for one core.",
        "",
    ]
    current = None
    for row in summary_rows:
        if row["scenario"] != current:
            current = row["scenario"]
            lines.append(f"## {current}")
            lines.append("")
            lines.append(
                "| impl | conc | req/s | p50 ms | p90 ms | p99 ms | errors | RSS MiB | CPU peak % |"
            )
            lines.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- |")
        lines.append(
            "| {impl} | {concurrency} | {rps} | {p50} | {p90} | {p99} | {errors} | {rss} | {cpu} |".format(
                impl=row["impl"],
                concurrency=row["concurrency"],
                rps=fmt(row["rps"], 1),
                p50=fmt(row["p50_ms"], 2),
                p90=fmt(row["p90_ms"], 2),
                p99=fmt(row["p99_ms"], 2),
                errors=fmt(row["errors"], 1),
                rss=fmt(row["rss_peak_mb"], 1),
                cpu=fmt(row["cpu_peak_pct"], 0),
            )
        )
    lines.append("")
    (root / "summary.md").write_text("\n".join(lines) + "\n")
    print(f"wrote {raw_path}")
    print(f"wrote {sum_path}")
    print(f"wrote {root / 'summary.md'}")


if __name__ == "__main__":
    main()
