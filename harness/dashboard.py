"""Write the data behind the benchmark dashboard (docs/benchmark/).

  python3 harness/dashboard.py <out dir> [--no-proofs]

<out dir>/index.json holds the applications, the models and every task's
result per model; <out dir>/tasks/<id>.json holds one task's code: the
statement, the spec it uses, the generated Lean, the kernel and upstream Rust
it comes from, the differential tests that touch it, and each model's
accepted proof. Code is matched through the `Source:` ranges Aeneas writes
above every generated declaration.
"""
import argparse, html, json, re, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPO = "https://github.com/h5i-dev/h5i-app-bench/blob/main"
SKIP_APPS = {"bootstrapacademy"}
MAX_DECLS = 10
# Runs before the framework moved into h5i as h5i-app used its old names. The
# raw runs keep what the model wrote; the dashboard shows the current names,
# under which those proofs were re-graded.
LEGACY_NAMES = [(re.compile(r"I5hLib"), "H5iAppLib"),
                (re.compile(r"(?<![A-Za-z0-9])i5h_(steps|step|for|eval|simp|invert|iter|derive_clone|derive_eq)\b"), r"h5i_\1"),
                (re.compile(r"(?<![A-Za-z0-9])i5h_(schema|sql|pgsql|pg|http|json|token)(?=\b|[A-Z])"), r"h5i_app_\1")]


def current_names(lean):
    for pat, new in LEGACY_NAMES:
        lean = pat.sub(new, lean)
    return lean


def tasks():
    out = []
    for meta in sorted((ROOT / "tasks").glob("*/meta.json")):
        m = json.loads(meta.read_text())
        kind, _, port = m["src"].partition(":")
        app = port.rsplit("/", 1)[-1]
        if kind == "bench" and app not in SKIP_APPS and (ROOT / port).is_dir():
            out.append(m | {"app": app, "port": ROOT / port})
    return out


# ---- Lean ---------------------------------------------------------------

DECL_KW = r"(?:noncomputable\s+)?(?:private\s+)?(?:def|abbrev|structure|inductive|theorem|lemma|instance|opaque|axiom|class)"


def generated_decls(path):
    """name -> {lean, rust_path, file, lines} for each Aeneas declaration."""
    text = path.read_text()
    starts = [m.start() for m in re.finditer(r"^/-- \[", text, re.M)]
    decls = {}
    for i, s in enumerate(starts):
        block = text[s:starts[i + 1] if i + 1 < len(starts) else len(text)]
        block = re.split(r"\n(?:end\b|namespace\b|section\b|/-[^-])", block)[0].rstrip()
        name = re.search(rf"^{DECL_KW}\s+([\w.']+)", block, re.M)
        if not name:
            continue
        src = re.search(r"Source: '([^']+)', lines (\d+):\d+-(\d+):\d+", block)
        rust = re.match(r"/-- \[([^\]]+)\]", block).group(1)
        decls[name.group(1)] = {"lean": block, "rust_path": rust,
                                "file": src and src.group(1), "lines": src and (int(src.group(2)), int(src.group(3))),
                                "kind": re.search(rf"^{DECL_KW}", block, re.M).group(0).split()[-1]}
    return decls


def spec_decls(path):
    """name -> text for the hand-written declarations of a spec file."""
    lines = path.read_text().splitlines()
    starts = [i for i, l in enumerate(lines) if re.match(rf"(/--|@\[|{DECL_KW}\s)", l)]
    decls, pending = {}, ""
    for n, i in enumerate(starts):
        end = starts[n + 1] if n + 1 < len(starts) else len(lines)
        block = re.split(r"\n(?:end\b|namespace\b|section\b|open\b)", "\n".join(lines[i:end]))[0].rstrip()
        m = re.search(rf"^{DECL_KW}\s+([\w.']+)", block, re.M)
        if m:
            decls.setdefault(m.group(1), pending + block)
            pending = ""
        else:
            # A doc comment or attribute: it belongs to the next declaration.
            pending += block + "\n"
    return decls


def refs(text, names):
    """The names in `names` that `text` mentions: by full or trailing
    segments, or as a method call (`c.contains`) on a type the text names."""
    tokens = set(re.findall(r"[A-Za-z_][\w']*(?:\.[A-Za-z_][\w']*)*", text))
    tails = {".".join(t.split(".")[i:]) for t in tokens for i in range(t.count(".") + 1)}
    methods = {t.rsplit(".", 1)[1] for t in tokens if "." in t}
    found = []
    for n in names:
        parts = n.split(".")
        own = {".".join(parts[i:]) for i in range(len(parts))}
        if n in tails or any("." in t and t in tails for t in own):
            found.append(n)
        elif len(parts) > 2 and parts[-1] in methods and ".".join(parts[-3:-1]) in tails | {parts[-2]}:
            found.append(n)
    return found


def stems(text):
    return {w[:5] for w in re.split(r"[^a-z]+", text.lower()) if len(w) >= 4}


def closure(seed_text, decls, body, hint="", depth=3, cap=MAX_DECLS):
    """Declarations `seed_text` mentions, then the ones those mention, the
    callees whose names share the most words with `hint` first."""
    want = stems(hint)
    out, frontier = [], refs(seed_text, decls)
    for _ in range(depth):
        for n in frontier:
            if n not in out and len(out) < cap:
                out.append(n)
        nxt = []
        for n in frontier:
            nxt += [m for m in refs(body(n).split("\n", 3)[-1], decls) if m not in out and m not in nxt]
        frontier = sorted(nxt, key=lambda m: -len(stems(m.replace("_", " ").replace(".", " ")) & want))[:max(0, cap - len(out))]
    return out


def ported_loc():
    """Upstream lines each port covers, from the README's table."""
    out = {}
    for m in re.finditer(r"^\| \[[^\]]+\]\(ports/(\w+)\) \| [^|]+\| ([~\d,]+) \|", (ROOT / "README.md").read_text(), re.M):
        out[m.group(1)] = int(m.group(2).strip("~").replace(",", ""))
    return out


# ---- Rust ---------------------------------------------------------------

def rust_item_end(lines, i):
    """Index after the item that starts at line i, by brace depth."""
    depth, seen = 0, False
    for j in range(i, len(lines)):
        code = re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])\'|//.*', "", lines[j])
        depth += code.count("{") - code.count("}")
        seen = seen or "{" in code
        if seen and depth <= 0:
            return j + 1
        if not seen and code.rstrip().endswith(";"):
            return j + 1
    return len(lines)


def with_docs(lines, i):
    while i > 0 and lines[i - 1].strip().startswith(("///", "#[", "//!")):
        i -= 1
    return i


def rust_fn(path, name):
    """(first line, text) of each `fn name` in a Rust file."""
    lines = path.read_text().splitlines()
    out = []
    for i, l in enumerate(lines):
        if re.search(rf"\bfn\s+{re.escape(name)}\b\s*[<(]", l):
            s = with_docs(lines, i)
            out.append((s + 1, "\n".join(lines[s:rust_item_end(lines, i)])))
    return out


def rust_fns_using(path, name, cap=2):
    """Functions in a Rust file whose body mentions `name`."""
    lines = path.read_text().splitlines()
    out, i = [], 0
    while i < len(lines) and len(out) < cap:
        if re.match(r"\s*(?:pub(?:\([^)]*\))?\s+)?(?:async\s+)?fn\s+\w+", lines[i]):
            end = rust_item_end(lines, i)
            body = "\n".join(lines[i:end])
            if re.search(rf"\b{re.escape(name)}\b", body) and not re.match(rf"\s*(?:pub\s+)?fn\s+{re.escape(name)}\b", lines[i]):
                s = with_docs(lines, i)
                out.append((s + 1, "\n".join(lines[s:end])))
            i = end
        else:
            i += 1
    return out


class Upstream:
    """The upstream functions of a port: copies under difftest/ (stubs and
    test seams excluded), or the pinned checkout a path dependency points at."""

    def __init__(self, port, repo, commit):
        self.port, self.repo, self.commit = port, repo, commit
        d = port / "difftest"
        self.copies = [f for root in (d / "upstream", d / "src/upstream") if root.is_dir()
                       for f in sorted(root.rglob("*.rs"))
                       if not {"stubs", "seams", "target"} & set(f.relative_to(root).parts)]
        self.checkout, self.found = None, {}
        for m in re.finditer(r'path\s*=\s*"([^"]+)"', (d / "Cargo.toml").read_text()):
            dep = (d / m.group(1)).resolve()
            if dep.is_dir() and not dep.is_relative_to(port.resolve()):
                top = subprocess.run(["git", "-C", dep, "rev-parse", "--show-toplevel"],
                                     capture_output=True, text=True).stdout.strip()
                if top:
                    self.checkout = (Path(top), str(dep.relative_to(top)))

    def find(self, fn):
        if fn not in self.found:
            self.found[fn] = self._find(fn)
        return self.found[fn]

    def _find(self, fn):
        for f in self.copies:
            for line, code in rust_fn(f, fn)[:1]:
                rel = f.relative_to(self.port)
                return {"fn": fn, "file": str(rel.relative_to("difftest")), "line": line,
                        "url": f"{REPO}/ports/{self.port.name}/{rel}#L{line}", "code": code}
        if self.checkout:
            top, sub = self.checkout
            hits = subprocess.run(["git", "-C", top, "grep", "-n", "-E", rf"\bfn\s+{fn}\b\s*[<(]", self.commit, "--", sub],
                                  capture_output=True, text=True).stdout.splitlines()
            for h in hits:
                _, path, _ = h.split(":", 2)
                text = subprocess.run(["git", "-C", top, "show", f"{self.commit}:{path}"],
                                      capture_output=True, text=True).stdout
                tmp = Path("/dev/shm") / f"h5iab-up-{fn}.rs"
                tmp.write_text(text)
                found = rust_fn(tmp, fn)[:1]
                tmp.unlink()
                for line, code in found:
                    return {"fn": fn, "file": path, "line": line,
                            "url": f"https://github.com/{self.repo}/blob/{self.commit}/{path}#L{line}", "code": code}
        return None


# Trait methods share names across unrelated types; never match them by name.
GENERIC = {"eq", "ne", "clone", "fmt", "default", "hash", "from", "into", "cmp", "partial_cmp",
           "to_string", "as_ref", "deref", "drop", "try_from", "from_str"}


def fn_name(decl):
    return re.split(r"::", decl["rust_path"])[-1].split("<")[0].strip("{} ")


def code_lines(text):
    """Lines without blanks, comments and attributes, as count_loc.py counts."""
    n, block = 0, False
    for line in text.splitlines():
        t = line.strip()
        if block or t.startswith("/*"):
            block = "*/" not in t
            continue
        if t and not t.startswith(("//", "#[")):
            n += 1
    return n


def dispatch_arms(decl, kernel_dir, gen):
    """constructor -> generated declarations called in that `match` arm, for a
    kernel function that dispatches on an enum (`Op::Messages { .. } => ...`)."""
    if not decl["file"]:
        return {}
    lines = (kernel_dir / decl["file"]).read_text().splitlines()
    text = "\n".join(lines[decl["lines"][0] - 1:decl["lines"][1]])
    heads = list(re.finditer(r"^\s*\w+::(\w+)\b[^\n]*?=>", text, re.M))
    by_fn = {}
    for n, d in gen.items():
        if d["kind"] == "def":
            by_fn.setdefault(fn_name(d), []).append(n)
    arms = {}
    for i, h in enumerate(heads):
        body = text[h.end():heads[i + 1].start() if i + 1 < len(heads) else len(text)]
        arms[h.group(1)] = [n for f in re.findall(r"(\w+)\s*\(", body) for n in by_fn.get(f, [])]
    return arms


def target_loc(statement, gen, up, memo, kernel_dir):
    """The upstream code a property is about: the first functions with an
    upstream counterpart below the ones its statement names, and everything
    they call. A kernel-only dispatcher is followed only into the arms for the
    operations the statement names (all of them if it names none)."""
    def body_refs(n):
        if n not in memo:
            memo[n] = [m for m in refs(gen[n]["lean"].split("\n", 3)[-1], gen) if gen[m]["kind"] == "def"]
        return memo[n]

    def upstream(n):
        d = gen[n]
        fn = fn_name(d)
        return d["kind"] == "def" and d["file"] and fn.isidentifier() and fn not in GENERIC and up.find(fn)

    targets, seen, todo = [], set(), [n for n in refs(statement, gen) if gen[n]["kind"] == "def"]
    while todo:
        n = todo.pop(0)
        if n in seen:
            continue
        seen.add(n)
        if upstream(n):
            targets.append(n)
            continue
        callees = [m for m in body_refs(n) if m not in seen]
        # A dispatcher: a `match` whose every arm hands off to a function.
        arms = dispatch_arms(gen[n], kernel_dir, gen) if len(callees) > 1 else {}
        if len(arms) >= 2 and all(arms.values()):
            named = set(re.findall(r"\.([A-Z]\w*)", statement)) & set(arms)
            callees = [m for a, ms in arms.items() if not named or a in named for m in ms]
        todo += callees
    items, stack, done = {}, list(targets), set()
    while stack:
        n = stack.pop()
        if n in done:
            continue
        done.add(n)
        if u := upstream(n):
            items[(u["file"], u["line"])] = code_lines(u["code"])
        stack += [m for m in body_refs(n) if m not in done]
    return list(dict.fromkeys(fn_name(gen[n]) for n in targets)), sum(items.values())


# ---- Markdown (the subset DEVIATIONS.md uses) ----------------------------

def inline_md(s):
    s = html.escape(s, quote=False)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', s)
    return s


def markdown(text):
    out, para, lines, i = [], [], text.splitlines(), 0

    def flush():
        if para:
            out.append("<p>" + inline_md(" ".join(para)) + "</p>")
            para.clear()
    while i < len(lines):
        l = lines[i]
        if l.startswith("```"):
            flush()
            j = i + 1
            while j < len(lines) and not lines[j].startswith("```"):
                j += 1
            out.append("<pre><code>" + html.escape("\n".join(lines[i + 1:j])) + "</code></pre>")
            i = j + 1
            continue
        if m := re.match(r"(#{1,4})\s+(.*)", l):
            flush()
            lvl = min(len(m.group(1)) + 2, 6)
            out.append(f"<h{lvl}>{inline_md(m.group(2))}</h{lvl}>")
        elif l.startswith("|"):
            flush()
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                if not all(re.fullmatch(r":?-+:?", c) for c in cells):
                    rows.append(cells)
                i += 1
            head, *body = rows
            out.append("<table><thead><tr>" + "".join(f"<th>{inline_md(c)}</th>" for c in head) + "</tr></thead><tbody>"
                       + "".join("<tr>" + "".join(f"<td>{inline_md(c)}</td>" for c in r) + "</tr>" for r in body)
                       + "</tbody></table>")
            continue
        elif re.match(r"\s*[-*] ", l):
            flush()
            items = []
            while i < len(lines) and (re.match(r"\s*[-*] ", lines[i]) or (lines[i].startswith("  ") and items)):
                if re.match(r"\s*[-*] ", lines[i]):
                    items.append(re.sub(r"^\s*[-*] ", "", lines[i]))
                else:
                    items[-1] += " " + lines[i].strip()
                i += 1
            out.append("<ul>" + "".join(f"<li>{inline_md(x)}</li>" for x in items) + "</ul>")
            continue
        elif not l.strip():
            flush()
        else:
            para.append(l.strip())
        i += 1
    flush()
    return "\n".join(out)


# ---- Results ------------------------------------------------------------

# Model names that hide which version ran.
LABELS = {"deepseek-v4-pro": "deepseek-v4-pro (0423)"}


def results(task_ids):
    """Protocol-2 runs: one list of results per task, keyed by column."""
    by_task = {}
    for f in sorted((ROOT / "results/runs").glob("*/result.json")):
        r = json.loads(f.read_text())
        if r["task"] not in task_ids or r.get("protocol") != 2 or r.get("infra_error"):
            continue
        model = r["model"].rsplit("/", 1)[-1]
        model = LABELS.get(model, model)
        g = r.get("grade") or {}
        run = {"model": model, "agent": r.get("agent", "codex"), "passed": bool(g.get("passed")),
               "reason": None if g.get("passed") else (g.get("reason") or "")[:120],
               "minutes": round(r["wall_s"] / 60, 1), "cost": r.get("cost_usd"),
               "builds": r.get("lake_runs"), "failed_builds": r.get("lake_failures"),
               "proof_loc": g.get("proof_loc"), "resumed": bool(r.get("resumes")),
               "dir": f.parent}
        by_task.setdefault(r["task"], []).append(run)
    return by_task


def column(run):
    return f"{run['model']} · {run['agent']}"


# ---- Main ---------------------------------------------------------------

def app_info(port):
    dev = (port / "DEVIATIONS.md").read_text()
    m = re.search(r"Upstream: ([\w.-]+/[\w.-]+) @ (\w+)", dev)
    loc = re.search(r"covers\s+([\d,~]+)\s+lines", dev)
    return {"repo": m.group(1), "commit": m.group(2), "upstream_loc": loc and loc.group(1),
            "deviations": markdown(dev), "port": f"{REPO}/ports/{port.name}"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--no-proofs", action="store_true", help="leave the models' accepted proofs out")
    ap.add_argument("--skip-agent", action="append", default=[], help="leave this agent's runs out")
    a = ap.parse_args()
    out = Path(a.out)
    (out / "tasks").mkdir(parents=True, exist_ok=True)

    ts = tasks()
    runs = {k: [r for r in v if r["agent"] not in a.skip_agent] for k, v in results({t["id"] for t in ts}).items()}
    apps, cache, ups, memo = {}, {}, {}, {}
    index_tasks, columns = [], {}
    for t in ts:
        port, app = t["port"], t["app"]
        if app not in cache:
            gen = generated_decls(next((port / "proofs/generated").glob("*.lean")))
            spec = spec_decls(port / "proofs/Spec.lean")
            cache[app] = gen, spec
            apps[app] = app_info(port)
            ups[app] = Upstream(port, apps[app]["repo"], apps[app]["commit"])
        gen, spec = cache[app]
        ws = ROOT / "tasks" / t["id"] / "workspace"
        solution = (ws / "proofs/Solution.lean").read_text()
        statement = solution[solution.index("theorem"):solution.rindex("end ")].rstrip()

        hint = t["id"] + " " + t["property"] + " " + statement
        lean = closure(statement, gen, lambda n: gen[n]["lean"], hint)
        spec_names = closure(statement, spec, lambda n: spec[n], hint, depth=2)
        kernel, upstream, difftest, seen = [], [], [], set()
        for n in lean:
            d = gen[n]
            if d["kind"] != "def" or not d["file"]:
                continue
            fn = re.split(r"::", d["rust_path"])[-1].split("<")[0].strip("{} ")
            if fn in seen or not fn.isidentifier():
                continue
            seen.add(fn)
            path = port / "kernel" / d["file"]
            klines = path.read_text().splitlines()
            s = with_docs(klines, d["lines"][0] - 1)
            kernel.append({"fn": fn, "file": d["file"], "line": s + 1,
                           "url": f"{REPO}/ports/{app}/kernel/{d['file']}#L{s + 1}-L{d['lines'][1]}",
                           "code": "\n".join(klines[s:d["lines"][1]])})
            if up := ups[app].find(fn):
                upstream.append(up)
            if len(difftest) < 4:
                for tf in sorted((port / "difftest/src").glob("*.rs")):
                    for line, code in rust_fns_using(tf, fn, cap=1):
                        if len(difftest) < 4 and not any(x["code"] == code for x in difftest):
                            rel = tf.relative_to(port / "difftest")
                            difftest.append({"fn": fn, "file": str(rel), "line": line,
                                             "url": f"{REPO}/ports/{app}/difftest/{rel}#L{line}", "code": code})

        task_runs = runs.get(t["id"], [])
        target_fns, target = target_loc(statement, gen, ups[app], memo.setdefault(app, {}), port / "kernel")
        proofs = []
        for r in task_runs:
            columns.setdefault(column(r), {"model": r["model"], "agent": r["agent"]})
            if r["passed"] and not a.no_proofs:
                sol = current_names((r["dir"] / "workspace/proofs/Solution.lean").read_text())
                proofs.append({"column": column(r), "loc": r["proof_loc"], "minutes": r["minutes"], "code": sol})
        detail = {"id": t["id"], "app": app, "property": t["property"], "theorem": t["theorem"],
                  "statement": statement, "target": {"fns": target_fns, "loc": target},
                  "spec": [{"name": n, "code": spec[n]} for n in spec_names],
                  "lean": [{"name": n, "rust": gen[n]["rust_path"], "code": gen[n]["lean"]} for n in lean],
                  "kernel": kernel, "upstream": upstream, "difftest": difftest, "proofs": proofs,
                  "runs": [{k: v for k, v in r.items() if k != "dir"} for r in task_runs]}
        (out / "tasks" / f"{t['id']}.json").write_text(json.dumps(detail, ensure_ascii=False))
        index_tasks.append({"id": t["id"], "app": app, "property": t["property"],
                            "theorem": t["theorem"].rsplit(".", 1)[-1],
                            "rust_loc": t.get("rust_loc"), "lean_loc": t.get("generated_lean_loc"), "loc": target,
                            "results": {column(r): {"p": r["passed"], "m": r["minutes"], "c": r["cost"]}
                                        for r in task_runs}})

    for col, info in columns.items():
        rs = [r for rr in runs.values() for r in rr if column(r) == col]
        costs = [r["cost"] for r in rs if r["cost"] is not None]
        info.update({"runs": len(rs), "solved": sum(r["passed"] for r in rs),
                     "solved_loc": sum(t["loc"] for t in index_tasks if t["results"].get(col, {}).get("p")),
                     "solved_cost": round(sum(r["cost"] or 0 for r in rs if r["passed"]), 4),
                     "solved_minutes": round(sum(r["minutes"] for r in rs if r["passed"]) / max(1, sum(r["passed"] for r in rs)), 1)
                     if any(r["passed"] for r in rs) else None,
                     "minutes": round(sum(r["minutes"] for r in rs) / len(rs), 1),
                     "cost": round(sum(costs), 2) if costs else None})
    ported = ported_loc()
    for app, info in apps.items():
        info["ported_loc"] = ported.get(app)
    stats = {"repos": len(apps), "ported_loc": sum(ported.get(a, 0) for a in apps),
             "properties": len(index_tasks),
             "proved": sum(any(r["p"] for r in t["results"].values()) for t in index_tasks)}
    index = {"generated": time.strftime("%Y-%m-%d"), "stats": stats, "apps": apps, "columns": columns,
             "tasks": index_tasks, "proofs": not a.no_proofs, "time_limit_min": 40}
    (out / "index.json").write_text(json.dumps(index, ensure_ascii=False))
    print(f"{len(index_tasks)} tasks, {sum(len(v) for v in runs.values())} runs, {len(columns)} columns -> {out}",
          file=sys.stderr)


if __name__ == "__main__":
    main()
