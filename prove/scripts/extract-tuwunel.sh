#!/usr/bin/env bash
# Extract the tuwunel kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d -p "$root/results")
trap 'rm -rf "$tmp"' EXIT
(cd "$root/ports/tuwunel/kernel" && charon cargo --preset=aeneas \
  --start-from tuwunel_kernel::transition --dest-file "$tmp/tuwunel_kernel.llbc")
mkdir -p "$root/ports/tuwunel/proofs/generated"
aeneas -backend lean "$tmp/tuwunel_kernel.llbc" -dest "$root/ports/tuwunel/proofs/generated"
sed -i "s|Source: '$root/|Source: '|" "$root/ports/tuwunel/proofs/generated"/*.lean
if grep -q '^axiom' "$root/ports/tuwunel/proofs/generated"/*.lean; then
  echo "error: the extraction contains axioms" >&2
  exit 1
fi
