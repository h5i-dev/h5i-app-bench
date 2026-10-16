#!/usr/bin/env bash
# Extract the nora kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d -p "$root/results")
trap 'rm -rf "$tmp"' EXIT
(cd "$root/ports/nora/kernel" && charon cargo --preset=aeneas \
  --start-from nora_kernel::transition --start-from nora_kernel::validation --start-from nora_kernel::middleware::auth_middleware --start-from nora_kernel::tokens::revoke_token --start-from nora_kernel::tokens::revoke_all_for_user --dest-file "$tmp/nora_kernel.llbc")
aeneas -backend lean "$tmp/nora_kernel.llbc" -dest "$root/ports/nora/proofs/generated"
sed -i "s|Source: '$root/|Source: '|" "$root/ports/nora/proofs/generated"/*.lean
