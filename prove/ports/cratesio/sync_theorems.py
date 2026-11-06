#!/usr/bin/env python3
"""Rewrite `[check] theorems` in h5i-app.toml from the theorems in proofs/Properties.lean."""
import re, pathlib
root = pathlib.Path(__file__).parent
names = re.findall(r"^theorem\s+(\S+)", (root / "proofs/Properties.lean").read_text(), re.M)
toml = (root / "h5i-app.toml").read_text()
body = "".join(f'  "cratesio_kernel.Properties.{n}",\n' for n in names)
toml = re.sub(r"theorems = \[.*?\]", "theorems = [\n" + body + "]", toml, flags=re.S)
(root / "h5i-app.toml").write_text(toml)
print(len(names), "theorems")
