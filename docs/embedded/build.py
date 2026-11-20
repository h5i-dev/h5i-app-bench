#!/usr/bin/env python3.12
"""Build docs/embedded/projects/<slug>.json from the embedded ports.

For every gated theorem of a port (h5i-app.toml [check] theorems) this records
its docstring, statement and proof (proofs/*.lean), the extracted Lean
declarations its statement reaches (proofs/generated/*.lean, with their
transitive dependencies), the kernel Rust each declaration was extracted from
(the "Source:" line Aeneas writes), and the upstream Rust it ports
(upstream-map.toml in the port, read from the pinned upstream checkout).

Usage: python3.12 docs/embedded/build.py [--root /mnt/scratch/h5i-embed]
sources.json lists each port's directory and upstream checkout.
"""
import argparse
import json
import re
import subprocess
import sys
import tomllib
from pathlib import Path

HERE = Path(__file__).resolve().parent
DECL_START = re.compile(r"^(?:@\[[^\]]*\]\s*)*(?:private\s+|protected\s+|noncomputable\s+)*(theorem|lemma|def|abbrev|structure|inductive|instance|axiom|opaque|example)\b")
TOP = re.compile(r"^(?:/--|/-!|@\[|#|(?:theorem|lemma|def|abbrev|structure|inductive|instance|axiom|opaque|example|namespace|end|section|open|set_option|variable|private|protected|noncomputable|import|attribute|macro|syntax|local|scoped|mutual)\b)")
TOKEN = re.compile(r"[A-Za-z_][\w'.]*")
MAX_DEPS = 24


def split_decls(text):
    """Top-level declarations: (kind, name, doc, code)."""
    lines = text.split("\n")
    out, i, n = [], 0, len(lines)
    while i < n:
        doc = ""
        start = i
        if lines[i].startswith("/--"):
            j = i
            while j < n and "-/" not in lines[j]:
                j += 1
            doc = "\n".join(lines[i:j + 1])
            i = j + 1
            while i < n and lines[i].startswith("@[") and not DECL_START.match(lines[i]):
                i += 1
        elif i < n and lines[i].startswith("@[") and not DECL_START.match(lines[i]):
            while i < n and lines[i].startswith("@[") and not DECL_START.match(lines[i]):
                i += 1
        if i < n and (m := DECL_START.match(lines[i])):
            # the name follows the keyword
            rest = lines[i][m.end():].split()
            name = rest[0] if rest and m.group(1) != "example" else ""
            j = i + 1
            while j < n and not (lines[j] and TOP.match(lines[j])):
                j += 1
            code = "\n".join(lines[start:j]).rstrip()
            out.append((m.group(1), name, doc, code))
            i = j
        else:
            i = max(i, start) + 1
    return out


def clean_doc(doc):
    d = re.sub(r"^/--\s*|\s*-/$", "", doc.strip(), flags=re.S)
    return re.sub(r"\s+", " ", d).strip()


def statement_of(code):
    """Theorem text up to its top-level `:=` (or `:= by`)."""
    depth = 0
    for k, ch in enumerate(code):
        if ch in "([{⟨":
            depth += 1
        elif ch in ")]}⟩":
            depth -= 1
        elif ch == ":" and depth == 0 and code[k + 1:k + 2] == "=":
            return code[:k].rstrip()
    return code


def strip_doc(code):
    return re.sub(r"^/--.*?-/\s*", "", code, count=1, flags=re.S)


def read_lines(path, a, b):
    try:
        ls = Path(path).read_text().split("\n")
    except OSError:
        return None
    return "\n".join(ls[a - 1:b])


def gated(port):
    t = tomllib.loads((port / "h5i-app.toml").read_text())
    return [s.split(".")[-1] for s in t.get("check", {}).get("theorems", [])]


def build(entry, root):
    port = root / entry["port"]
    wt_root = port.parents[2]  # <worktree>/prove/ports-embed/<slug>
    upstream = root / "upstream" / entry["upstream"]
    head = subprocess.run(["git", "-C", str(upstream), "rev-parse", "--short=7", "HEAD"],
                          capture_output=True, text=True).stdout.strip()
    proofs = port / "proofs"

    # extracted declarations
    gen = {}
    for f in sorted((proofs / "generated").glob("*.lean")):
        for kind, name, doc, code in split_decls(f.read_text()):
            m = re.search(r"\[([\w:]+)\]:?\s*\n\s*Source: '([^']+)', lines (\d+):\d+-(\d+):\d+", doc)
            if not name or not m:
                continue
            rust_path, src, a, b = m.group(1), m.group(2), int(m.group(3)), int(m.group(4))
            gen[name] = {"kind": kind, "rust_path": rust_path, "kernel_file": src.split("/kernel/", 1)[-1] if "/kernel/" in src else src,
                         "kernel_line": a, "kernel_code": read_lines(wt_root / src, a, b), "lean": strip_doc(code)}
    short = {}
    for name in gen:
        short.setdefault(name.split(".")[-1], name)

    def resolve(tok):
        if tok in gen:
            return tok
        parts = tok.split(".")
        for k in range(len(parts)):
            cand = ".".join(parts[k:])
            if cand in gen:
                return cand
        return short.get(parts[-1])

    # spec / property modules
    thms, specs = {}, {}
    for f in sorted(proofs.glob("*.lean")):
        if f.name == "lakefile.lean":
            continue
        for kind, name, doc, code in split_decls(f.read_text()):
            if kind in ("theorem", "lemma"):
                thms.setdefault(name, {"file": f.name, "doc": clean_doc(doc), "code": strip_doc(code)})
            elif kind in ("def", "abbrev", "structure", "inductive") and name:
                specs.setdefault(name, {"file": f.name, "code": code})

    # upstream mapping
    umap = {}
    mf = port / "upstream-map.toml"
    if mf.exists():
        for it in tomllib.loads(mf.read_text()).get("item", []):
            refs = []
            for r in it.get("upstream", []):
                fpath, _, rng = r.rpartition(":")
                a, _, b = rng.partition("-")
                a, b = int(a), int(b or a)
                refs.append({"file": fpath, "line": a, "code": read_lines(upstream / fpath, a, b) or "(not found at the pin)"})
            umap[it["kernel"]] = {"refs": refs, "note": it.get("note", "")}

    used = set()
    theorems = []
    for tname in gated(port):
        t = thms.get(tname)
        if not t:
            theorems.append({"name": tname, "missing": True})
            continue
        stmt = statement_of(t["code"])
        toks = set(TOKEN.findall(stmt))
        deps, seen = [], set()
        frontier = [d for d in (resolve(x) for x in toks) if d]
        while frontier and len(deps) < MAX_DEPS:
            d = frontier.pop(0)
            if d in seen:
                continue
            seen.add(d)
            deps.append(d)
            frontier += [x for x in (resolve(y) for y in set(TOKEN.findall(gen[d]["lean"]))) if x and x not in seen]
        spec = [s for s in sorted(toks) if s in specs and s not in gen][:8]
        used.update(deps)
        theorems.append({"name": tname, "file": t["file"], "doc": t["doc"], "statement": stmt,
                         "proof": t["code"], "deps": deps, "spec": spec})

    decls = {}
    for d in used:
        g = gen[d]
        key = g["rust_path"].split("::")[-1]
        u = umap.get(g["rust_path"]) or umap.get(key)
        decls[d] = {**g, "upstream": u["refs"] if u else [], "upstream_note": u["note"] if u else ""}
    spec_used = {s: specs[s] for t in theorems for s in t.get("spec", [])}
    return {"slug": entry["slug"], "name": entry["name"], "pin": entry["pin"], "upstream_head": head,
            "pin_ok": head.startswith(entry["pin"][:7]), "mapped": mf.exists(),
            "theorems": theorems, "decls": decls, "specs": spec_used}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default="/mnt/scratch/h5i-embed", type=Path)
    ap.add_argument("--check", action="store_true", help="report only; write nothing")
    ap.add_argument("--only", help="one slug")
    args = ap.parse_args()
    sources = json.loads((HERE / "sources.json").read_text())
    data = json.loads((HERE / "data.json").read_text())
    by_name = {p["name"]: p for p in data["projects"]}
    (HERE / "projects").mkdir(exist_ok=True)
    for e in sources:
        if args.only and e["slug"] != args.only:
            continue
        p = build(e, args.root)
        unmapped = sorted(k for k, v in p["decls"].items() if not v["upstream"] and not v["upstream_note"])
        if args.check:
            print(f"{e['slug']}: map={'yes' if p['mapped'] else 'no'}; unmapped: {', '.join(unmapped) or 'none'}")
            continue
        (HERE / "projects" / f"{e['slug']}.json").write_text(json.dumps(p, indent=1))
        s = by_name[e["name"]]
        s["slug"] = e["slug"]
        s["theorems"] = len([t for t in p["theorems"] if not t.get("missing")])
        s["theorem_list"] = [{"name": t["name"], "doc": t.get("doc", "")} for t in p["theorems"] if not t.get("missing")]
        missing = [t["name"] for t in p["theorems"] if t.get("missing")]
        print(f"{e['slug']:24} {s['theorems']:3} theorems, {len(p['decls']):3} decls, "
              f"map={'yes' if p['mapped'] else 'no '} pin={'ok' if p['pin_ok'] else 'MISMATCH ' + p['upstream_head']}"
              + (f" missing={missing}" if missing else ""), file=sys.stderr)
    if not args.check:
        (HERE / "data.json").write_text(json.dumps(data, indent=1))


if __name__ == "__main__":
    main()
