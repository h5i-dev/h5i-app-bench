"""Export current project proofs and exact source pairs for the Specs drawer.

python3 harness/project_details.py ../docs/prove/data [--source-root prove/]
Shared app assets avoid duplicating the same source across hundreds of properties.
"""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

from dashboard import REPO, generated_decls, spec_decls
from project_reach import ROOT, executable_lines, fresh_extraction, fresh_gate, measure


def local_context(code, declarations):
    """Include local helper declarations referenced by a property wrapper."""
    found = {}
    pending = [code]
    while pending:
        tokens = set(re.findall(r"[\w']+", pending.pop()))
        for name, declaration in declarations.items():
            if name in tokens and declaration != code and name not in found:
                found[name] = declaration
                pending.append(declaration)
    return [{"name": name, "code": body} for name, body in found.items()]


def supporting_modules(code, modules, context=""):
    """Display referenced proof modules and their local import context."""
    pending = [m for m in modules if m.startswith("Verified.") and
               re.search(rf"(?<![\w.])(?:\w+_kernel\.)?{re.escape(m)}\.", code)]
    # Unqualified calls can come from an explicitly opened proof namespace.
    tokens = set(re.findall(r"[\w']+", code))
    pending.extend(m for m in re.findall(r"^open (?:\w+_kernel\.)?(Verified\.[\w.]+)", context, re.M)
                   if m in modules and tokens & set(spec_decls_text(modules[m]["code"])))
    found = set()
    while pending:
        name = pending.pop()
        if name in found:
            continue
        found.add(name)
        pending.extend(m for m in re.findall(r"^import ([\w.]+)", modules[name]["code"], re.M)
                       if m in modules and m not in found)
    return sorted(found)


def spec_decls_text(text):
    return re.findall(r"^(?:theorem|lemma|def|abbrev)\s+([\w']+)", text, re.M)


def write_details(index, out, root=ROOT):
    out = Path(out)
    assets, rows = {}, []
    for app, info in index["apps"].items():
        selected = info.get("project_properties")
        if not selected:
            continue
        gate, extraction = fresh_gate(app, root), fresh_extraction(app, root)
        if not gate or not extraction or gate["gated_theorems"] != selected["names"]:
            raise ValueError(f"{app}: current proof/extraction evidence is missing or stale")
        report = measure(app, selected["names"], root=root)
        if report["upstream_reached"] != info["current_source_matched_lines"]:
            raise ValueError(f"{app}: dashboard reach differs from current evidence")
        port = root / "ports" / app
        proofs = port / "proofs"
        statements = spec_decls(proofs / "Properties.lean")
        modules = {}
        for path in sorted(proofs.rglob("*.lean")):
            rel = path.relative_to(proofs)
            if ".lake" in rel.parts or rel.parts[0] == "generated" or path.name == "lakefile.lean":
                continue
            modules[".".join(rel.with_suffix("").parts)] = {
                "file": str(rel), "code": path.read_text(),
                "url": f"{REPO}/ports/{app}/proofs/{rel}"}
        generated = {}
        for path in sorted((proofs / "generated").glob("*.lean")):
            generated.update(generated_decls(path))
        declarations, upstream, properties, texts = {}, {}, {}, {}
        repository = root / "results/upstream" / f"{app}.git"
        revision = report["upstream_revision"]
        for prop in report["properties"]:
            name = prop["name"]
            short = name.rsplit(".", 1)[-1]
            statement = statements[short]
            helpers = local_context(statement, statements)
            items, reached = {}, {}
            for item in prop["items"]:
                path, first, last = item["file"], item["start"], item["end"]
                if path not in texts:
                    texts[path] = subprocess.check_output(
                        ["git", "-C", str(repository), "show", f"{revision}:{path}"], text=True)
                code = "\n".join(texts[path].splitlines()[first - 1:last])
                if hashlib.sha256(code.encode()).hexdigest() != item["sha256"]:
                    raise ValueError(f"{app}: upstream snippet changed")
                key = f"{path}:{first}-{last}"
                upstream[key] = {"file": path, "line": first, "code": code,
                                 "url": f"https://github.com/{info['repo']}/blob/{revision}/{path}#L{first}"}
                items.setdefault(item["declaration"], []).append(key)
                reached.setdefault(path, set()).update(
                    executable_lines(texts[path]) & set(range(first, last + 1)))
            for decl in prop["generated_dependencies"]:
                if decl in declarations:
                    continue
                d = generated[decl]
                source = d["file"]
                # Aeneas paths may include prove/, ports/, or be crate-relative.
                suffix = source.split(f"ports/{app}/kernel/", 1)[-1]
                path = port / "kernel" / suffix
                first, last = d["lines"]
                declarations[decl] = {
                    "name": decl, "lean": d["lean"], "rust_path": d["rust_path"],
                    "file": f"kernel/{suffix}", "line": first,
                    "code": "\n".join(path.read_text().splitlines()[first - 1:last]),
                    "url": f"{REPO}/ports/{app}/kernel/{suffix}#L{first}"}
            properties[name] = {"statement": statement, "dependencies": prop["generated_dependencies"],
                                "items": items, "helpers": helpers,
                                "modules": supporting_modules(statement + "\n" + "\n".join(h["code"] for h in helpers),
                                                              modules, modules["Properties"]["code"])}
            doc = re.search(r"/--\s*(.*?)\s*-/", statement, re.S)
            description = " ".join(doc.group(1).split()) if doc else short.replace("_", " ")
            rows.append({"id": name, "theorem": name, "app": app, "property": description,
                         "status": "accepted", "loc": sum(map(len, reached.values())),
                         "proof_loc": len(statement.splitlines()), "checked_at": gate["finished_at"]})
        assets[app] = {"properties": properties, "declarations": declarations, "upstream": upstream,
                       "modules": modules, "checked_at": gate["finished_at"], "log": gate["log"],
                       "revision": revision, "meaning": report["meaning"]}
    if len(rows) != index["stats"]["properties"]:
        raise ValueError("current property count differs from dashboard")
    (out / "projects").mkdir(parents=True, exist_ok=True)
    for app, asset in assets.items():
        (out / "projects" / f"{app}.json").write_text(json.dumps(asset, ensure_ascii=False))
    index["project_tasks"] = rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("out", type=Path)
    parser.add_argument("--source-root", type=Path, default=ROOT)
    args = parser.parse_args()
    path = args.out / "index.json"
    index = json.loads(path.read_text())
    write_details(index, args.out, args.source_root)
    path.write_text(json.dumps(index, ensure_ascii=False))
    print(f"Exported {len(index['project_tasks'])} current project properties")


if __name__ == "__main__":
    main()
