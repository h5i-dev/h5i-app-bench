#!/usr/bin/env bash
# Extract the i5h-pgsql compiler to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
# Starting from the public functions skips Debug impls, which only exist as
# axioms in Aeneas.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/crates/i5h-pgsql" && charon cargo --preset=aeneas \
  --start-from i5h_pgsql::compile --start-from i5h_pgsql::select \
  --start-from i5h_pgsql::create --start-from i5h_pgsql::render \
  --include i5h_sql \
  --dest-file "$tmp/i5h_pgsql.llbc")
aeneas -backend lean "$tmp/i5h_pgsql.llbc" -dest "$root/crates/i5h-pgsql/proofs/generated"
