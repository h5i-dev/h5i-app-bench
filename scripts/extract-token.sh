#!/usr/bin/env bash
# Extract i5h-token to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/crates/i5h-token" && charon cargo --preset=aeneas \
  --start-from i5h_token::parse --start-from i5h_token::encode_payload --start-from i5h_token::join \
  --dest-file "$tmp/i5h_token.llbc")
aeneas -backend lean "$tmp/i5h_token.llbc" -dest "$root/crates/i5h-token/proofs/generated"
