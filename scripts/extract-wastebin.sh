#!/usr/bin/env bash
# Extract the Wastebin kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/examples/wastebin/kernel" && charon cargo --preset=aeneas \
  --start-from wastebin_kernel::transition --start-from wastebin_kernel::transition_pre190 \
  $(bash "$root/scripts/schema-items.sh" wastebin_kernel) --include i5h_sql \
  --dest-file "$tmp/wastebin_kernel.llbc")
aeneas -backend lean "$tmp/wastebin_kernel.llbc" -dest "$root/examples/wastebin/proofs/generated"
