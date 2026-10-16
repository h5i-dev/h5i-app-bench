#!/usr/bin/env bash
# Extract the Bootstrap Academy kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d -p "$root/results")
trap 'rm -rf "$tmp"' EXIT
(cd "$root/ports/extra/bootstrapacademy/kernel" && charon cargo --preset=aeneas \
  --start-from bootstrapacademy_kernel::transition --dest-file "$tmp/bootstrapacademy_kernel.llbc")
aeneas -backend lean "$tmp/bootstrapacademy_kernel.llbc" -dest "$root/ports/extra/bootstrapacademy/proofs/generated"
sed -i "s|Source: '$root/|Source: '|" "$root/ports/extra/bootstrapacademy/proofs/generated"/*.lean
if grep -q '^axiom' "$root/ports/extra/bootstrapacademy/proofs/generated"/*.lean; then
  echo "error: the extraction contains axioms" >&2
  exit 1
fi
