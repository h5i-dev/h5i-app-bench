#!/usr/bin/env bash
# Extract tutorial 5's kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/examples/tutorials/booking/kernel" && charon cargo --preset=aeneas \
  --start-from booking_kernel::transition --start-from booking_kernel::apply \
  --dest-file "$tmp/booking_kernel.llbc")
aeneas -backend lean "$tmp/booking_kernel.llbc" -dest "$root/examples/tutorials/booking/proofs/generated"
