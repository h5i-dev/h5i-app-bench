#!/usr/bin/env bash
# Extract the Conduit kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/examples/conduit/kernel" && charon cargo --preset=aeneas \
  --start-from conduit_kernel::transition --start-from conduit_kernel::transition_upstream \
  $(bash "$root/scripts/schema-items.sh" conduit_kernel) --include i5h_sql \
  --dest-file "$tmp/conduit_kernel.llbc")
aeneas -backend lean "$tmp/conduit_kernel.llbc" -dest "$root/examples/conduit/proofs/generated"
