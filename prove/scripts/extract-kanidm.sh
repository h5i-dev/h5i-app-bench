#!/usr/bin/env bash
# Extract the kanidm kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d -p "$root/results")
trap 'rm -rf "$tmp"' EXIT
(cd "$root/ports/kanidm/kernel" && charon cargo --preset=aeneas \
  --start-from kanidm_kernel::access --dest-file "$tmp/kanidm_kernel.llbc")
aeneas -backend lean "$tmp/kanidm_kernel.llbc" -dest "$root/ports/kanidm/proofs/generated"
sed -i "s|Source: '$root/|Source: '|" "$root/ports/kanidm/proofs/generated"/*.lean
if grep -q '^axiom' "$root/ports/kanidm/proofs/generated"/*.lean; then
  echo "error: the extraction contains axioms" >&2
  exit 1
fi
