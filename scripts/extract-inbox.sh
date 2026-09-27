#!/usr/bin/env bash
# Extract tutorial 4's kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/examples/tutorials/inbox/kernel" && charon cargo --preset=aeneas \
  --start-from inbox_kernel::transition --start-from inbox_kernel::apply \
  --dest-file "$tmp/inbox_kernel.llbc")
aeneas -backend lean "$tmp/inbox_kernel.llbc" -dest "$root/examples/tutorials/inbox/proofs/generated"
