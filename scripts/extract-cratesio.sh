#!/usr/bin/env bash
# Extract the crates.io kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/examples/cratesio/kernel" && charon cargo --preset=aeneas \
  --start-from cratesio_kernel::transition --start-from cratesio_kernel::transition_pre14760 \
  $(bash "$root/scripts/schema-items.sh" cratesio_kernel) --include i5h_sql \
  --dest-file "$tmp/cratesio_kernel.llbc")
aeneas -backend lean "$tmp/cratesio_kernel.llbc" -dest "$root/examples/cratesio/proofs/generated"
