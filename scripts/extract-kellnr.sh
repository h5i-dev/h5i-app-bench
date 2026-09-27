#!/usr/bin/env bash
# Extract the Kellnr kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/examples/kellnr/kernel" && charon cargo --preset=aeneas \
  --start-from kellnr_kernel::transition --start-from kellnr_kernel::transition_pre1243 \
  --start-from kellnr_kernel::apply \
  --dest-file "$tmp/kellnr_kernel.llbc")
aeneas -backend lean "$tmp/kellnr_kernel.llbc" -dest "$root/examples/kellnr/proofs/generated"
