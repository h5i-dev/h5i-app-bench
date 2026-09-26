#!/usr/bin/env bash
# Extract i5h-json's writer to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/crates/i5h-json" && charon cargo --preset=aeneas \
  --start-from i5h_json::write \
  --dest-file "$tmp/i5h_json.llbc")
aeneas -backend lean "$tmp/i5h_json.llbc" -dest "$root/crates/i5h-json/proofs/generated"
