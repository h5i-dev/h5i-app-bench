#!/usr/bin/env bash
# Extract the Wastebin kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/examples/wastebin/kernel" && charon cargo --preset=aeneas \
  --start-from wastebin_kernel::transition --start-from wastebin_kernel::transition_pre190 \
  --start-from wastebin_kernel::apply \
  --dest-file "$tmp/wastebin_kernel.llbc")
aeneas -backend lean "$tmp/wastebin_kernel.llbc" -dest "$root/examples/wastebin/proofs/generated"
