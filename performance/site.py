"""Write the data behind the performance page (docs/performance/, served at
benchmark.h5i.dev/performance/) from each application's summary.csv.

  python3 performance/site.py [out.json]

The default output is docs/performance/data.json. Run it after a benchmark's
summarize.py has rewritten bench/results/summary.csv.
"""
import csv, json, subprocess, sys
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
H5I = {"rust-h5i", "rust-h5i-optimized", "rust-h5i-gpu"}

APPS = [
    {
        "id": "realworld",
        "title": "RealWorld (Conduit)",
        "stacks": {
            "rust-h5i": "Rust, axum, the h5i-app engine (h5i-app-pg) with Lean proofs",
            "rust-h5i-optimized": "Rust, axum, sqlx, h5i-app kernel with Lean proofs",
        },
        "upstream": "https://github.com/realworld-apps/realworld",
        "about": "The RealWorld blogging API: users, profiles, articles, comments, tags, follows and favorites. "
                 "Every implementation passes the same pinned Hurl suite.",
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
        "stacks": {
            "rust-h5i": "Rust, axum, the h5i-app engine (h5i-app-pg): kernel, read plans and writes with Lean proofs",
            "rust-h5i-optimized": "Rust, axum, sqlx, h5i-app kernel with Lean proofs",
            "rust-h5i-gpu": "Rust, axum, sqlx, plus a GPU-resident search index (Rust-CUDA) that the engine's read plan feeds",
        },
        "upstream": "https://github.com/sissbruecker/linkding",
        "about": "The linkding bookmark manager's REST API. The Hurl suite was checked against the pinned "
                 "1.47.0 image, which also runs in the benchmark as a reference.",
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
    rows = []
    with path.open() as f:
        for r in csv.DictReader(f):
            rows.append({"impl": r["impl"], "scenario": r["scenario"], "concurrency": int(r["concurrency"]),
                         "reps": int(r["reps"]), **{k: round(float(r[k]), 3) for k in FIELDS}})
    impls = list(dict.fromkeys(r["impl"] for r in rows))
    impls.sort(key=lambda i: (i not in H5I, i == "upstream"))
    scenarios = [s for s in app["scenarios"] if any(r["scenario"] == s for r in rows)]
    return {
        "id": app["id"], "title": app["title"], "upstream": app["upstream"], "about": app["about"],
        "seed": app["seed"], "source": f"{REPO}/{app['id']}", "measured": last_change(path),
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
