#!/usr/bin/env bash
# Extract the oxicloud kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d -p "$root/results")
trap 'rm -rf "$tmp"' EXIT
(cd "$root/ports/oxicloud/kernel" && charon cargo --preset=aeneas \
  --start-from oxicloud_kernel::grantapi::transition \
  --dest-file "$tmp/oxicloud_kernel.llbc")
mkdir -p "$root/ports/oxicloud/proofs/generated"
aeneas -backend lean "$tmp/oxicloud_kernel.llbc" -dest "$root/ports/oxicloud/proofs/generated"
sed -i "s|Source: '$root/|Source: '|" "$root/ports/oxicloud/proofs/generated"/*.lean
if grep -q '^axiom' "$root/ports/oxicloud/proofs/generated"/*.lean; then
  grep -n '^axiom' "$root/ports/oxicloud/proofs/generated"/*.lean; exit 1
fi
