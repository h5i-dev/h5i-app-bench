"""Per-item port ledger: which upstream items a kernel ports, and how much.

  python3 harness/port_ledger.py seed <app>     # write ports/<app>/LEDGER.toml
  python3 harness/port_ledger.py report [app..] # ported lines over the target

The candidates are the upstream items of the pinned scope, with the
kernel_ceiling.py classification (results/source-coverage/
kernel-ceiling-items.jsonl.gz). The ledger gives each one a status:

- ported:  the kernel function(s) or type(s) in `kernel` port it;
- outside: it stays in the shell, with a `reason` (policy decoding and
           serialization, HTTP clients, caches, the clock);
- todo:    kernel-eligible and not ported yet.

The target is every item that is not `outside`. `seed` proposes statuses
from the kernel's doc comments, which name the upstream item they port;
the ledger is then maintained by hand as items are ported.
"""
import argparse, gzip, json, re, sys, tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ITEMS = ROOT / "results/source-coverage/kernel-ceiling-items.jsonl.gz"
# Decoding and encoding of policy documents stay in the shell.
PARSING = {"serialize", "deserialize", "from_deserializer", "serialize_map", "expecting", "fmt", "from_str",
           "try_from", "from", "to_key", "from_encoded_values"}
GENERIC = {"new", "default", "eq", "is_match", "is_allowed", "clone", "hash"}


def items(app):
    return [i for i in map(json.loads, gzip.open(ITEMS, "rt")) if i["app"] == app]


def key(i):
    return f"{i['file']}:{i['start']} {(i['self_ty'] + '::') if i['self_ty'] else ''}{i['name']}"


def seed(app):
    kernel = "\n".join(p.read_text() for p in sorted((ROOT / "ports" / app / "kernel/src").glob("*.rs")))
    docs = {}
    for m in re.finditer(r"((?:^\s*///.*\n)+)\s*(?:pub(?:\([^)]*\))?\s+)?(?:fn|struct|enum)\s+(\w+)", kernel, re.M):
        for tick in re.findall(r"`([^`]+)`", m.group(1)):
            for w in re.findall(r"[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*", tick):
                docs.setdefault(w, set()).add(m.group(2))
                docs.setdefault(w.split("::")[-1], set()).add(m.group(2))
    # Kernel items with the upstream item's own name, and module docs (`//!`)
    # that name the upstream item the whole module ports.
    for m in re.finditer(r"^\s*(?:pub(?:\([^)]*\))?\s+)?(?:fn|struct|enum)\s+(\w+)", kernel, re.M):
        docs.setdefault(m.group(1), set()).add(m.group(1))
    for f in sorted((ROOT / "ports" / app / "kernel/src").glob("*.rs")):
        head = "".join(l for l in f.read_text().splitlines(True) if l.startswith("//!"))
        for tick in re.findall(r"`([^`]+)`", head):
            for w in re.findall(r"[A-Za-z_]\w*", tick):
                docs.setdefault(w, set()).add(f"{f.stem}::*")
    out = ["# Port ledger for ports/%s (see harness/port_ledger.py)." % app,
           "# status: ported (kernel = [...]), outside (reason = ...), todo.", ""]
    for i in items(app):
        full = (i["self_ty"] + "::" if i["self_ty"] else "") + i["name"]
        shell = i["reasons"] and not (i["reasons"][0] == "async")
        if i["name"] in PARSING or i["name"].startswith("visit_"):
            status, extra = "outside", 'reason = "policy decoding or serialization"'
        elif shell:
            status, extra = "outside", f'reason = "{i["reasons"][0]}"'
        elif (k := docs.get(full) or (docs.get(i["name"]) if i["name"] not in GENERIC else None)):
            status, extra = "ported", "kernel = [" + ", ".join(f'"{x}"' for x in sorted(k)) + "]"
        else:
            status, extra = "todo", ""
        out += ["[[item]]", f'upstream = "{key(i)}"', f"lines = {i['loc']}", f'status = "{status}"']
        if extra:
            out.append(extra)
        out.append("")
    path = ROOT / "ports" / app / "LEDGER.toml"
    path.write_text("\n".join(out))
    print(f"wrote {path.relative_to(ROOT)}")


def report(app):
    ledger = tomllib.loads((ROOT / "ports" / app / "LEDGER.toml").read_text())["item"]
    target = [x for x in ledger if x["status"] != "outside"]
    ported = sum(x["lines"] for x in target if x["status"] == "ported")
    total = sum(x["lines"] for x in target)
    return {"app": app, "target_lines": total, "ported_lines": ported,
            "todo_lines": total - ported, "outside_lines": sum(x["lines"] for x in ledger if x["status"] == "outside"),
            "items": len(target), "ported_items": sum(x["status"] == "ported" for x in target)}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("seed"); s.add_argument("app")
    r = sub.add_parser("report"); r.add_argument("apps", nargs="*")
    a = ap.parse_args()
    if a.cmd == "seed":
        seed(a.app)
    else:
        apps = a.apps or [p.parent.name for p in sorted((ROOT / "ports").glob("*/LEDGER.toml"))]
        rows = [report(x) for x in apps]
        for r in rows:
            print(f"{r['app']}: ported {r['ported_lines']:,} of {r['target_lines']:,} target lines "
                  f"({r['ported_lines'] / max(1, r['target_lines']):.0%}); {r['outside_lines']:,} outside")
        out = ROOT / "results/source-coverage/port-ledger.json"
        out.write_text(json.dumps({"apps": rows}, indent=1) + "\n")


if __name__ == "__main__":
    main()
