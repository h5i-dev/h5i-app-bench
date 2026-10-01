"""Lines of upstream code the kernel ports: the service files copied into
src/upstream/*_impl and models_verbatim.rs, without blank lines, comments,
attributes, `use` statements and `mod` declarations. The copied contract
traits and error enums (src/upstream/*_contracts) are counted apart.

  python3 count_loc.py
"""
from pathlib import Path

UP = Path(__file__).parent / "src/upstream"


def code(text):
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
        if s and not s.startswith("//") and not s.startswith("#[") and not s.startswith("pub mod "):
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
    impl = count(sorted(UP.glob("*_impl/*.rs")) + [UP / "models_verbatim.rs"])
    print(f"{impl:5}  ported service code")
    contracts = count(sorted(UP.glob("*_contracts/*.rs")))
    print(f"{contracts:5}  contracts (traits and error types)")
