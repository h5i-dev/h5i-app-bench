#!/usr/bin/env bash
# Extract the rustfs kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d -p "$root/results")
trap 'rm -rf "$tmp"' EXIT
(cd "$root/ports/rustfs/kernel" && charon cargo --preset=aeneas \
  --start-from rustfs_kernel::policies --start-from rustfs_kernel::pathclean::clean \
  --dest-file "$tmp/rustfs_kernel.llbc")
mkdir -p "$root/ports/rustfs/proofs/generated"
aeneas -backend lean "$tmp/rustfs_kernel.llbc" -dest "$root/ports/rustfs/proofs/generated"
sed -i "s|Source: '$root/|Source: '|" "$root/ports/rustfs/proofs/generated"/*.lean
if grep -q '^axiom' "$root/ports/rustfs/proofs/generated"/*.lean; then
  grep -n '^axiom' "$root/ports/rustfs/proofs/generated"/*.lean; exit 1
fi
