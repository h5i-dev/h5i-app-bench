#!/usr/bin/env bash
# Extract the Atuin kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/examples/atuin/kernel" && charon cargo --preset=aeneas \
  --start-from atuin_kernel::transition --start-from atuin_kernel::transition_current \
  $(bash "$root/scripts/schema-items.sh" atuin_kernel) --include i5h_sql \
  --dest-file "$tmp/atuin_kernel.llbc")
aeneas -backend lean "$tmp/atuin_kernel.llbc" -dest "$root/examples/atuin/proofs/generated"
