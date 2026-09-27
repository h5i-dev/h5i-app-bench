#!/usr/bin/env bash
# Extract tutorial 3's kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/examples/tutorials/ledger/kernel" && charon cargo --preset=aeneas \
  --start-from ledger_kernel::transition --start-from ledger_kernel::apply \
  --dest-file "$tmp/ledger_kernel.llbc")
aeneas -backend lean "$tmp/ledger_kernel.llbc" -dest "$root/examples/tutorials/ledger/proofs/generated"
