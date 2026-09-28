#!/usr/bin/env bash
# Extract tutorial 5's kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/examples/tutorials/booking/kernel" && charon cargo --preset=aeneas \
  --start-from booking_kernel::transition $(bash "$root/scripts/schema-items.sh" booking_kernel) \
  --include i5h_sql \
  --dest-file "$tmp/booking_kernel.llbc")
aeneas -backend lean "$tmp/booking_kernel.llbc" -dest "$root/examples/tutorials/booking/proofs/generated"
for f in "$root/examples/tutorials/booking/proofs/generated"/*.lean; do bash "$(dirname "$0")/normalize-sources.sh" "$f" "$root"; done
