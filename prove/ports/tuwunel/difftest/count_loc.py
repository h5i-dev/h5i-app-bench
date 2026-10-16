"""Lines of upstream code the kernel ports: the files extract_upstream.py
copies into upstream/ (the `// Copied from` ones), without blank lines,
comments, attributes, `use` statements and `mod` declarations, and without
the support items after the `// support` marker. The copied stream and
future combinators of tuwunel_core/src/utils are plumbing and counted apart.

  python3 count_loc.py
"""
from pathlib import Path

UP = Path(__file__).parent / "upstream"
MARK = "// Copied from matrix-construct/tuwunel"
SUPPORT = "// support: copied and run, not counted as ported"


def code(text):
    text = text.split(SUPPORT)[0]
    n, in_use, depth = 0, False, 0
    for line in text.splitlines():
        s = line.strip()
        if depth or s.startswith("/*"):
            depth = 0 if "*/" in s else 1
            continue
        if in_use:
            in_use = not s.endswith(";")
            continue
        if s.startswith("use ") or s.startswith("pub use "):
            in_use = not s.endswith(";")
            continue
        if s.startswith("#[") or s.startswith("#!["):
            in_use = not (s.endswith("]") or s.endswith("]\n"))
            continue
        if s.startswith(")]") or s.startswith("mod ") or s.startswith("pub mod "):
            continue
        if s and not s.startswith("//"):
            n += 1
    return n


def count(paths):
    total = 0
    for p in paths:
        n = code(p.read_text())
        print(f"{n:5}  {p.relative_to(UP)}")
        total += n
    return total


if __name__ == "__main__":
    copied = sorted(p for p in UP.rglob("*.rs") if p.read_text().startswith(MARK))
    plumbing = [p for p in copied if "/utils/stream/" in str(p) or "/utils/future/" in str(p)
                or "/utils/result/" in str(p) or p.name == "bool.rs"]
    ported = [p for p in copied if p not in plumbing]
    print(f"{count(ported):5}  ported upstream code")
    print(f"{count(plumbing):5}  plumbing (stream, future and result combinators)")
