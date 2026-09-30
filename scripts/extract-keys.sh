#!/usr/bin/env bash
# Extract the API-keys kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/examples/keys/kernel" && charon cargo --preset=aeneas \
  --start-from keys_kernel::transition --start-from keys_kernel::transition_pre --start-from keys_kernel::apply \
  --dest-file "$tmp/keys_kernel.llbc")
aeneas -backend lean "$tmp/keys_kernel.llbc" -dest "$root/examples/keys/proofs/generated"
for f in "$root/examples/keys/proofs/generated"/*.lean; do bash "$(dirname "$0")/normalize-sources.sh" "$f" "$root"; done
