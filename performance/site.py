"""Write the data behind the performance page (docs/performance/, served at
benchmark.h5i.dev/performance/) from each application's summary.csv and the
supplemental summaries configured in APPS (later runs replace matching points).

  python3 performance/site.py [out.json]

The default output is docs/performance/data.json. Run it after a benchmark's
summarize.py has rewritten bench/results/summary.csv.
"""
import csv, json, re, subprocess, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = "https://github.com/h5i-dev/h5i-app-bench/tree/main/performance"

# Shared across apps. The h5i Rust variants differ in meaning per app (the same
# id names the engine in one app and the hand-written-SQL build in another), so
# their descriptions live in each app's own `stacks` below.
STACKS = {
    "go": "Go, chi, pgx",
    "fastify": "TypeScript, Fastify, postgres.js",
    "fastapi": "Python, FastAPI, asyncpg, uvicorn",
    "upstream": "linkding 1.47.0 image: Django, uWSGI",
}
H5I = {"rust-h5i", "rust-h5i-optimized", "rust-h5i-cpu-scan", "rust-h5i-gpu"}
H5I_ORDER = ["rust-h5i", "rust-h5i-optimized", "rust-h5i-gpu", "rust-h5i-cpu-scan"]

APPS = [
    {
        "id": "realworld",
        "summaries": ["gpu-policy-2026-10-18/summary.csv"],
        "measurement_note": "CPU/GPU policies: paired run at 1/16 clients on 2026-10-18. Other results use the earlier run; CPU allocations differ.",
        "title": "RealWorld (Conduit)",
        "stacks": {
            "rust-h5i": "Rust, axum, the h5i-app engine (h5i-app-pg) with Lean proofs",
            "rust-h5i-optimized": "Rust, axum, sqlx, h5i-app kernel with Lean proofs",
            "rust-h5i-gpu": "Rust, axum, sqlx, optional CUDA policy decisions (CPU kernel has Lean proofs; GPU checked by conformance tests)",
        },
        "upstream": "https://github.com/realworld-apps/realworld",
        "about": "RealWorld blogging API. All implementations pass the same Hurl suite.",
        "seed": "100 users, 10,000 articles with two tags each, 10,000 comments, 1,000 follows, 5,000 favorites.",
        "scenarios": {
            "list": "GET /api/articles: limit 20 at offset 0, a later offset, and tag=tagN",
            "slug": "GET /api/articles/article-N",
            "feed": "GET /api/articles/feed?limit=20 as user 1",
            "login": "POST /api/users/login, bcrypt cost 12",
            "create": "POST /api/articles as user 1",
            "favorite": "POST /api/articles/article-N/favorite as user 1",
            "mixed": "50% list, 20% slug, 15% feed, 10% favorite, 5% create",
        },
    },
    {
        "id": "linkding",
        "title": "linkding",
        "summaries": [
            "text-search-2026-10-17/summary.csv",
            "complex-languages-2026-10-19/summary.csv",
            "complex-engine-2026-10-19/summary.csv",
            "summary-refresh-2026-10-19/summary.csv",
        ],
        "measurement_note": "2026-10-19 refresh: h5i engine, optimized get/mixed. Complex search and CPU/GPU search use separate runs. Dates and source CSVs appear in the details; cross-run CPU allocations differ.",
        "stacks": {
            "rust-h5i": "Rust, axum, the h5i-app engine (h5i-app-pg): kernel, read plans and writes with Lean proofs",
            "rust-h5i-optimized": "Rust, axum, sqlx, h5i-app kernel with Lean proofs",
            "rust-h5i-cpu-scan": "Rust, axum, sqlx, resident search index evaluated on CPU",
            "rust-h5i-gpu": "Rust, axum, sqlx, GPU-resident search index (Rust-CUDA), with SQL fallback",
        },
        "upstream": "https://github.com/sissbruecker/linkding",
        "about": "Bookmark REST API, checked against linkding 1.47.0. Upstream results appear below.",
        "seed": "50 users, 100,000 bookmarks and 2,000 tags owned by one user, two tags per bookmark.",
        "scenarios": {
            "list": "GET /api/bookmarks/?limit=20 at a rotating offset",
            "search": "GET /api/bookmarks/?q=alpha&limit=20",
            "search_tag": "GET /api/bookmarks/?q=#tagN&limit=20",
            "search_complex": "GET /api/bookmarks/: eight-term boolean text search (1000 matches)",
            "get": "GET /api/bookmarks/{id}/",
            "create": "POST /api/bookmarks/ with two tags",
            "update": "PATCH /api/bookmarks/{id}/ (title)",
            "archive": "POST /api/bookmarks/{id}/archive/",
            "tags": "GET /api/tags/?limit=20 at a rotating offset",
            "mixed": "40% list, 20% search, 15% get, 10% tags, 8% update, 5% archive, 2% create",
        },
    },
]

FIELDS = ["rps", "rps_stdev", "p50_ms", "p90_ms", "p99_ms", "errors", "rss_peak_mb", "cpu_peak_pct"]


def last_change(path):
    out = subprocess.run(["git", "log", "-1", "--format=%cs", "--follow", "--diff-filter=AM", "--", path],
                         cwd=HERE, capture_output=True, text=True).stdout.strip()
    return out or None


def load(app):
    path = HERE / app["id"] / "bench/results/summary.csv"
    # Later configured runs replace the same implementation/scenario/client
    # point. Appending duplicates left .find() rendering the stale first row.
    points = {}
    for summary in ["summary.csv", *app.get("summaries", [])]:
        summary_path = path.parent / summary
        date = re.search(r"\d{4}-\d{2}-\d{2}", summary)
        measured = date.group() if date else last_change(summary_path)
        source = f"{REPO.replace('/tree/', '/blob/')}/{app['id']}/bench/results/{summary}"
        seen = set()
        with summary_path.open() as f:
            for r in csv.DictReader(f):
                key = (r["impl"], r["scenario"], int(r["concurrency"]))
                if key in seen:
                    raise ValueError(f"Duplicate measurement in {summary_path}: {key}")
                seen.add(key)
                points[key] = {"impl": key[0], "scenario": key[1], "concurrency": key[2],
                               "reps": int(r["reps"]), "measured": measured, "source": source,
                               **{k: round(float(r[k]), 3) for k in FIELDS}}
    rows = list(points.values())
    dates = sorted({r["measured"] for r in rows if r["measured"]})
    impls = list(dict.fromkeys(r["impl"] for r in rows))
    impls.sort(key=lambda i: (i not in H5I, H5I_ORDER.index(i) if i in H5I else i == "upstream"))
    scenarios = [s for s in app["scenarios"] if any(r["scenario"] == s for r in rows)]
    return {
        "id": app["id"], "title": app["title"], "upstream": app["upstream"], "about": app["about"],
        "seed": app["seed"], "source": f"{REPO}/{app['id']}",
        "measured": "–".join(dict.fromkeys([dates[0], dates[-1]])) if dates else None,
        "measurement_note": app.get("measurement_note", ""),
        "impls": [{"id": i, "stack": app.get("stacks", {}).get(i) or STACKS.get(i, ""), "h5i": i in H5I} for i in impls],
        "scenarios": [{"id": s, "requests": app["scenarios"][s]} for s in scenarios],
        "concurrency": sorted({r["concurrency"] for r in rows}),
        "rows": rows,
    }


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE.parent / "docs/performance/data.json"
    data = {"apps": [load(a) for a in APPS]}
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(data, indent=1) + "\n")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
