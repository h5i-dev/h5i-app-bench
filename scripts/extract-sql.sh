#!/usr/bin/env bash
# Extract the i5h-sql planner to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
# Starting from `plan` skips Debug impls, which only exist as axioms in Aeneas.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$root/crates/i5h-sql" && charon cargo --preset=aeneas \
  --start-from i5h_sql::plan \
  --dest-file "$tmp/i5h_sql.llbc")
aeneas -backend lean "$tmp/i5h_sql.llbc" -dest "$root/crates/i5h-sql/proofs/generated"
