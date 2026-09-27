#!/usr/bin/env bash
# Extract tutorial 1's kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/examples/tutorials/calculator/kernel" && charon cargo --preset=aeneas \
  --start-from calculator_kernel::transition --start-from calculator_kernel::apply \
  --start-from calculator_kernel::sql_writes $(bash "$root/scripts/schema-items.sh" calculator_kernel) \
  --include i5h_sql \
  --dest-file "$tmp/calculator_kernel.llbc")
aeneas -backend lean "$tmp/calculator_kernel.llbc" -dest "$root/examples/tutorials/calculator/proofs/generated"
