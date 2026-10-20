"""Join matching cross-language batches; never convert them to HTTP throughput."""
import csv
import json
from pathlib import Path
import statistics
import sys

IMPLS = {"rust1": "Rust · 1 thread", "rust16": "Rust · 16 threads",
         "go": "Go · 1 thread", "javascript": "Node.js · 1 thread",
         "resident": "GPU · resident", "upload_each": "GPU · upload each"}


def load(path):
    rows = {}
    with path.open() as f:
        for r in csv.DictReader(f):
            key = tuple(int(r[k]) for k in ["carts", "lines", "repeat"])
            if key in rows:
                raise ValueError(f"Duplicate point: {path} {key}")
            rows[key] = r
    expected = {(n, line, rep) for n in [1,16,256,4096,65536,262144,1048576]
                for line in [1,8,32] for rep in range(3)}
    if set(rows) != expected:
        raise ValueError(f"Incomplete measurement grid: {path}")
    return rows


def summarize(path):
    rust = load(path)
    go = load(path.with_name("go.csv"))
    js = load(path.with_name("javascript.csv"))
    points = []
    for n, count in sorted({k[:2] for k in rust}, key=lambda k: (k[1], k[0])):
        repetitions = {i: [] for i in IMPLS}
        for rep in range(3):
            key = (n,count,rep)
            r,g,j = rust[key],go[key],js[key]
            if len({int(x["checksum"]) for x in [r,g,j]}) != 1:
                raise ValueError(f"Cross-language total checksum mismatch: {key}")
            if len({int(x["iterations"]) for x in [r,g,j]}) != 1:
                raise ValueError(f"Iteration mismatch: {key}")
            for impl, raw in {"rust1": r["cpu1_ms"], "rust16": r["cpu16_ms"],
                              "go": g["ms"], "javascript": j["ms"],
                              "resident": r["resident_ms"], "upload_each": r["upload_each_ms"]}.items():
                value = float(raw)
                if not 0 < value < float("inf"):
                    raise ValueError(f"Invalid timing: {key} {impl}")
                repetitions[impl].append(value)
        points.append({"carts": n, "lines": count, "reps": 3,
                       "ms": {i: statistics.median(v) for i,v in repetitions.items()},
                       "range_ms": {i: [min(v),max(v)] for i,v in repetitions.items()}})
    result = {"measured": path.parent.name[:10], "implementations": IMPLS, "points": points}
    path.with_name("summary.json").write_text(json.dumps(result, indent=2)+"\n")
    lines = ["# django-cart snapshot pricing", "",
             "Median milliseconds per complete batch; GPU includes full result download.", "",
             "| Carts | Lines/cart | Rust 1 | Rust 16 | Go 1 | Node.js 1 | GPU resident | GPU upload each | Best CPU / resident |",
             "| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |"]
    for p in points:
        v=p["ms"]
        best=min(v[i] for i in ["rust1","rust16","go","javascript"])
        lines.append(f'| {p["carts"]} | {p["lines"]} | '+" | ".join(f"{v[i]:.6f}" for i in IMPLS)
                     + f' | {best/v["resident"]:.2f}× |')
    lines += ["", "Three repetition means, eight warmup passes, 100 iterations below 4,096 carts and 10 otherwise.",
              "All languages use matching fixed-width snapshots and verify each repetition's last vector.",
              "Go and Node.js are single-thread baselines. Rust 16 uses persistent Rayon workers.",
              "The ratio uses the fastest of these four CPU measurements at each shape.",
              "Shared host; fixed implementation order; not HTTP, ORM or checkout timings.", ""]
    path.with_name("summary.md").write_text("\n".join(lines))
    return result


if __name__ == "__main__":
    summarize(Path(sys.argv[1]))
