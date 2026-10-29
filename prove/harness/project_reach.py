"""Conservative canonical-property reach in immutable upstream source.

Mappings name exact generated declarations and exact upstream file/type/item
triples. Only the theorem TYPE seeds reach; proof bodies never seed it.
Reach is a property/dependency measure, not behavioral equivalence.
"""
import gzip
import hashlib
import json
import re
import subprocess
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def project_files(port):
    return sorted(p for p in [port / "h5i-app.toml", *port.glob("kernel/src/**/*.rs"),
                              port / "kernel/Cargo.toml", port / "kernel/Cargo.lock",
                              port / "kernel/build.rs", *port.glob("kernel/.cargo/*"),
                              *port.glob("proofs/**/*.lean"), port / "proofs/lean-toolchain",
                              port / "proofs/lake-manifest.json", port / "proofs/lakefile.lean"]
                  if ".lake" not in p.parts and p.is_file())


def fresh_record(app, actions, root=ROOT):
    """Latest outcome must succeed and hash the complete current input set."""
    latest = None
    for path in sorted((root / "results/project-checks").glob("*/summary.json")):
        for row in json.loads(path.read_text()):
            if row["app"] == app and any(c in row.get("command", []) for c in actions):
                latest = row
    if not latest or not latest.get("passed") or latest.get("inputs_unchanged") is False:
        return None
    port = root / "ports" / app
    expected = {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in project_files(port)}
    if latest.get("source_sha256") != expected:
        return None
    return latest


def fresh_extraction(app, root=ROOT):
    return fresh_record(app, ("extract",), root)


def fresh_gate(app, root=ROOT):
    """Latest full gate must cover all configured, unchanged statements."""
    latest = fresh_record(app, ("check", "prove"), root)
    if not latest:
        return None
    names = tomllib.loads((root / "ports" / app / "h5i-app.toml").read_text())["check"]["theorems"]
    if latest.get("gated_theorems") != names:
        return None
    return latest


def theorem_type(text, name):
    """Fail closed on missing/duplicate declarations, without reading proofs."""
    matches = list(re.finditer(rf"^theorem {re.escape(name.rsplit('.', 1)[-1])}\b(.*?)\s:=(?:\s|$)",
                               text, re.M | re.S))
    if len(matches) != 1:
        raise ValueError(f"expected one theorem declaration: {name}")
    return matches[0].group(1)


def dependencies(statement, gen):
    # The historical task selector uses heuristic suffix/method matching to
    # assemble context. Coverage must not inherit those guesses: two modules
    # can define the same method. Keep exact qualified tokens and only unique
    # abbreviated qualified names; never infer a receiver's type from spelling.
    aliases = {}
    for name in gen:
        parts = name.split(".")
        for i in range(len(parts) - 1):
            aliases.setdefault(".".join(parts[i:]), set()).add(name)

    def refs(text):
        found = set()
        for token in re.findall(r"[A-Za-z_][\w']*(?:\.[A-Za-z_][\w']*)*", text):
            if token in gen:
                found.add(token)
                continue
            if token.split(".")[0].endswith("_kernel"):
                token = token.split(".", 1)[-1]
                if token in gen:
                    found.add(token)
                    continue
            matches = aliases.get(token, set())
            if len(matches) == 1:
                found.update(matches)
        return found

    todo = list(refs(statement))
    seen = set()
    while todo:
        name = todo.pop()
        if name in seen or gen[name]["kind"] != "def":
            continue
        seen.add(name)
        # Strip the documentation (Rust paths can otherwise create false refs).
        body = gen[name]["lean"].split("-/", 1)[-1]
        todo.extend(refs(body))
    return seen


def executable_lines(text):
    """Physical code-line identities, excluding comments and attributes."""
    selected, block = set(), False
    for number, line in enumerate(text.splitlines(), 1):
        t = line.strip()
        if block or t.startswith("/*"):
            block = "*/" not in t
            continue
        if t and not t.startswith(("//", "#[", "#![")):
            selected.add(number)
    return selected


def measure(app, names, port=None, root=ROOT):
    from dashboard import generated_decls
    from source_inventory import SOURCES
    port = port or root / "ports" / app
    mapping_path = root / "harness/source-mappings" / f"{app}.json"
    if not mapping_path.exists():
        return None
    mapping = json.loads(mapping_path.read_text())
    repository = root / "results/upstream" / f"{app}.git"
    pin = SOURCES[app][0]
    revision = subprocess.check_output(["git", "-C", repository, "rev-parse", pin], text=True).strip()
    if mapping["upstream_revision"] != revision:
        raise ValueError(f"{app}: mapping revision mismatch")
    gen = {}
    for path in sorted((port / "proofs/generated").glob("*.lean")):
        gen.update(generated_decls(path))
    props = (port / "proofs/Properties.lean").read_text()
    texts, source_lines, properties = {}, {}, []
    for name in names:
        reached = dependencies(theorem_type(props, name), gen)
        items = []
        for decl in sorted(reached):
            for item in mapping["declarations"].get(decl, []):
                path, first, last = item["file"], item["start"], item["end"]
                if path not in texts:
                    texts[path] = subprocess.check_output(
                        ["git", "-C", repository, "show", f"{revision}:{path}"], text=True)
                fragment = "\n".join(texts[path].splitlines()[first - 1:last])
                if hashlib.sha256(fragment.encode()).hexdigest() != item["sha256"]:
                    raise ValueError(f"{app}: source item changed: {decl}")
                # Item and type are resolved when the mapping is authored;
                # immutable span hashes make later accidental drift fatal.
                source_lines.setdefault(path, set()).update(
                    executable_lines(texts[path]) & set(range(first, last + 1)))
                items.append({"declaration": decl, **item})
        properties.append({"name": name, "generated_dependencies": sorted(reached), "items": items})
    return {"upstream_revision": revision, "mapping_sha256": hashlib.sha256(mapping_path.read_bytes()).hexdigest(),
            "lines": {p: sorted(ns) for p, ns in sorted(source_lines.items())},
            "upstream_reached": sum(map(len, source_lines.values())), "properties": properties,
            "meaning": "Deduplicated pinned executable source reached by property types and extracted dependencies; not complete behavioral equivalence."}
