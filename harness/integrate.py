"""Emit a mechanical patch integrating checked proof candidates into a port.

The standard h5i-app gate must recheck the resulting project. A historical or
isolated certificate alone does not establish the canonical project's status.
This command does not change files; apply its patch after reviewing it.
"""
import argparse
import difflib
import hashlib
import json
import re

import bench


def shared_derivations(derivations):
    commands = list(dict.fromkeys(derivations))
    if "h5i_derive_all" in commands:
        commands = [c for c in commands if not c.startswith(("h5i_derive_eq ", "h5i_derive_clone "))]
    eq_types = {c.split()[1] for c in commands if c.startswith("h5i_derive_eq ")}
    return [c for c in commands if not (c.startswith("deriving instance DecidableEq for ")
            and c.split()[-1] in eq_types)]


def integrate_theorem(text, name, namespace):
    block = re.search(rf"^theorem {re.escape(name)}\b.*?(?=^theorem\b|^end\b|\Z)",
                      text, flags=re.M | re.S)
    if block is None:
        raise ValueError(f"{name}: canonical theorem missing")
    call = f"{namespace}.{name}"
    replacement, count = re.subn(r"(\s:=\s*by\s*\n)  sorry\b",
        lambda m: m[1] + f"  apply {call} <;> assumption", block[0], count=1)
    if count == 0 and call not in block[0]:
        raise ValueError(f"{name}: theorem is not an untouched placeholder; review manually")
    return text[:block.start()] + replacement + text[block.end():]


def replace_file(path, old, new):
    if old == new:
        return ""
    relative = path.relative_to(bench.ROOT)
    if not path.exists():
        return f"*** Add File: {relative}\n" + "".join("+" + l + "\n" for l in new.splitlines())
    diff = list(difflib.unified_diff(old.splitlines(keepends=True), new.splitlines(keepends=True)))
    hunks = "".join("@@\n" if line.startswith("@@") else line for line in diff[2:])
    return f"*** Update File: {relative}\n" + hunks


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--app", required=True,
                    choices=["nora", "artifactkeeper", "kanidm", "rustfs", "tuwunel", "oxicloud"])
    args = ap.parse_args()
    base = bench.ROOT / "ports" / args.app / "proofs"
    properties = base / "Properties.lean"
    old = properties.read_text()
    new = old
    imports = []
    changes = []
    modules = []
    derivations = []
    for tid, t in bench.tasks(extra=False).items():
        if t["src"] != f"bench:ports/{args.app}":
            continue
        certificate = bench.ROOT / "results/verification" / tid / "certificate.json"
        candidate = certificate.parent / "Solution.lean"
        if not certificate.exists() or not candidate.exists():
            continue
        saved = json.loads(certificate.read_text())
        code = candidate.read_text()
        if not saved.get("grade", {}).get("passed"):
            continue
        if saved.get("sha256") != hashlib.sha256(candidate.read_bytes()).hexdigest():
            raise SystemExit(f"{tid}: certificate does not match saved candidate")
        label = "".join(part.capitalize() for part in tid.split("-"))
        namespace = f"{t['ns']}.Verified.{label}"
        code = code.replace(f"{t['ns']}.Solution", namespace)
        commands = re.findall(r"^(?:h5i_derive_.*|deriving instance DecidableEq for .*)$", code, re.M)
        derivations.extend(commands)
        code = re.sub(r"^(?:h5i_derive_.*|deriving instance DecidableEq for .*)\n", "", code, flags=re.M)
        name = t["theorem"].rsplit(".", 1)[1]
        if not re.search(rf"^theorem {re.escape(name)}\b", code, re.M):
            raise SystemExit(f"{tid}: expected theorem missing")
        path = base / "Verified" / f"{label}.lean"
        previous = path.read_text() if path.exists() else ""
        modules.append((path, previous, code))
        imports.append(f"import Verified.{label}")
        try:
            new = integrate_theorem(new, name, namespace)
        except ValueError as error:
            raise SystemExit(f"{tid}: {error}") from error
    if derivations:
        # Derivation commands emit declarations in the extracted type's
        # namespace, even inside a proof namespace. Import them exactly once.
        commands = shared_derivations(derivations)
        ns = next(t["ns"] for t in bench.tasks(extra=False).values()
                  if t["src"] == f"bench:ports/{args.app}")
        derived = base / "Verified/Derived.lean"
        content = (f"import Spec\nimport H5iAppLib\nopen Aeneas Aeneas.Std Result {ns} {ns}.Spec\n"
                   "open H5iAppLib hiding lit\n\n" + "\n".join(commands) + "\n")
        changes.append(replace_file(derived, derived.read_text() if derived.exists() else "", content))
        modules = [(p, old_code, "import Verified.Derived\n" + code) for p, old_code, code in modules]
    changes.extend(replace_file(p, old_code, code) for p, old_code, code in modules)
    missing = [i for i in imports if i not in new.splitlines()]
    if missing:
        new = "\n".join(missing) + "\n" + new
    changes.append(replace_file(properties, old, new))
    lakefile = base / "lakefile.lean"
    lake_old = lakefile.read_text()
    if imports and "lean_lib Verified" not in lake_old:
        lake_new = lake_old.replace("@[default_target] lean_lib Proofs",
            "lean_lib Verified where\n  globs := #[.submodules `Verified]\n\n@[default_target] lean_lib Proofs")
        changes.append(replace_file(lakefile, lake_old, lake_new))
    print("*** Begin Patch\n" + "".join(changes) + "*** End Patch")


if __name__ == "__main__":
    main()
