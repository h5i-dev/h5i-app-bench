"""Map existing port inventories to deduplicated pinned upstream line spans.

These are ported-item spans, NOT a formal-verification numerator. Proof-to-item
mapping and review of modeled-away branches are separate acceptance steps.
"""
import argparse
import hashlib
import importlib.util
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

from source_inventory import ROOT, SOURCES


class NoWritePath:
    """Disable the extractor's direct Path writes as well as its write helper."""

    def __truediv__(self, other):
        return self

    @property
    def parent(self):
        return self

    def mkdir(self, *args, **kwargs):
        pass

    def write_text(self, *args, **kwargs):
        pass


def locate(source, fragment, base=0):
    fragment = fragment.rstrip("\n")
    if not fragment:
        raise ValueError("empty source fragment")
    start = source.find(fragment, base)
    if start < 0:
        raise ValueError("fragment is not verbatim upstream source")
    end = start + len(fragment)
    return source.count("\n", 0, start) + 1, source.count("\n", 0, end - 1) + 1


def load_inventory(app):
    directory = ROOT / "ports" / app / "difftest"
    # The historical inventory imports its adjacent extractor by a bare name.
    # Isolate that import so an earlier application's module cannot leak in.
    old = sys.modules.pop("extract_upstream", None)
    sys.path.insert(0, str(directory))
    try:
        filename = "extract_upstream.py" if app in ("artifactkeeper", "tuwunel") else "count_loc.py"
        spec = importlib.util.spec_from_file_location(f"{app}_loc_inventory", directory / filename)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    finally:
        sys.path.pop(0)
        sys.modules.pop("extract_upstream", None)
        if old is not None:
            sys.modules["extract_upstream"] = old


def inventory(app):
    module = load_inventory(app)
    revision, scope = SOURCES[app]
    repository = ROOT / "results/upstream" / f"{app}.git"
    revision = subprocess.check_output(["git", "-C", str(repository), "rev-parse", revision], text=True).strip()
    texts, spans = {}, []

    def source(path):
        if path not in texts:
            texts[path] = subprocess.check_output(
                ["git", "-C", str(repository), "show", f"{revision}:{path}"], text=True)
        return texts[path]

    def add(path, fragment, label, base=0):
        first, last = locate(source(path), fragment, base)
        spans.append({"path": path, "first_line": first, "last_line": last, "item": label})

    if app in ("artifactkeeper", "tuwunel"):
        # Replay selection only: source reads use immutable Git objects and
        # extractor writes are disabled. The original selector remains the
        # authority, avoiding a second manually maintained item list.
        module.show = lambda repo, relative: source(scope + "/" + relative)
        module.write = lambda *args, **kwargs: None
        module.UP = NoWritePath()
        module.OUT = NoWritePath()
        if app == "artifactkeeper":
            original_item, original_whole = module.item, module.upto_tests

            def record(fragment, label):
                matches = [path for path, text in texts.items() if fragment.rstrip("\n") in text]
                if len(matches) != 1:
                    raise ValueError(f"ambiguous source selection: {label}")
                add(matches[0], fragment, label)
                return fragment

            module.item = lambda text, header: record(original_item(text, header), header)
            module.upto_tests = lambda text: record(original_whole(text), "whole file before tests")
        else:
            original_cut, original_whole = module.cut, module.whole

            def cut(repo, path, ported, support=(), methods_of=None):
                text = source(scope + "/" + path)
                for header in ported:
                    add(scope + "/" + path, module.item(text, header), header)
                return original_cut(repo, path, ported, support, methods_of)

            def whole(repo, path, drop=()):
                if not path.startswith("core/utils/"):
                    text = source(scope + "/" + path)
                    end = text.find("\n#[cfg(test)]\nmod tests {")
                    add(scope + "/" + path, text if end < 0 else text[:end], "whole file before tests")
                return original_whole(repo, path, drop)

            module.cut, module.whole = cut, whole
        module.main(str(repository))
    elif app in ("nora", "rustfs", "oxicloud"):
        for relative, headers in module.PORTED.items():
            path = scope + "/" + relative
            text = source(path)
            if app in ("rustfs", "oxicloud"):
                test = text.find("#[cfg(test)]\nmod tests")
                text = text if test < 0 else text[:test]
            for header in headers:
                add(path, module.item(text, header), header)
        for relative, (first, last) in getattr(module, "FRAGMENTS", {}).items():
            path = scope + "/" + relative
            text = source(path)
            start = text.index(first)
            add(path, text[start:text.index(last, start) + len(last)], "ported claims fragment", start)
    else:
        for path in module.WHOLE:
            add(path, module.before_tests(source(path)), "whole file before tests")
        for path, headers in module.ITEMS.items():
            for header in headers:
                add(path, module.item(source(path), header), header)

        def functions(path, header, names):
            text = source(path)
            block = module.item(text, header).rstrip("\n")
            base = text.index(block)
            for name in names:
                fragment = module.item(block, rf"(?:pub(?:\([a-z]+\))? )?fn {name}\b")
                add(path, fragment, header + " :: " + name, base)

        for path, blocks in module.FNS.items():
            for header, names in blocks:
                functions(path, header, names)
        for file, ty, extra in module.VALUESETS:
            functions(module.LIB + "valueset/" + file, module.esc(f"impl ValueSetT for {ty} {{"),
                      ["contains", "substring", "startswith", "endswith", "lessthan"] + extra)

    lines = {}
    for span in spans:
        lines.setdefault(span["path"], set()).update(range(span["first_line"], span["last_line"] + 1))
    count = sum(bool(texts[path].splitlines()[line - 1].strip())
                for path, selected in lines.items() for line in selected)
    inputs = [ROOT / "ports" / app / "difftest" /
              ("extract_upstream.py" if app in ("artifactkeeper", "tuwunel") else "count_loc.py")]
    extractor = inputs[0].with_name("extract_upstream.py")
    if extractor.exists() and extractor not in inputs:
        inputs.append(extractor)
    return {"app": app, "upstream_revision": revision, "scope": scope,
            "mapping_status": "ported_item_inventory_not_formal_verification_coverage",
            "counting_convention": "nonblank_physical_lines_including_comments_and_attributes",
            "deduplicated_mapped_nonblank_lines": count,
            "mapped_physical_lines": sum(map(len, lines.values())),
            "spans": spans,
            "inventory_inputs": {str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest()
                                 for path in inputs},
            "verified_source_coverage_percent": None,
            "limitations": ["Item spans include branches and infrastructure modeled away by the kernel.",
                            "No proof-to-upstream-item mapping has yet been certified."] +
                           (["OxiCloud spans include unported email-invitation and message-bus branches and tracing calls; these must be excluded before computing a verified numerator."]
                            if app == "oxicloud" else [])}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", nargs="+", choices=list(SOURCES), default=list(SOURCES))
    args = parser.parse_args()
    rows = []
    for app in args.app:
        row = inventory(app)
        rows.append(row)
        print(f"{app}: {len(row['spans'])} spans, {row['deduplicated_mapped_nonblank_lines']} deduplicated nonblank lines",
              flush=True)
    output = ROOT / "results/source-coverage"
    output.mkdir(parents=True, exist_ok=True)
    (output / "ported-spans.json").write_text(json.dumps(
        {"timestamp": datetime.now(timezone.utc).isoformat(), "apps": rows}, indent=2) + "\n")


if __name__ == "__main__":
    main()
