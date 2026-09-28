#!/usr/bin/env bash
# Run the tests of both workspaces (crates, examples) against Postgres. Tests
# skip when the database URL is missing, so a skip here is a CI failure.
set -uo pipefail
: "${I5H_TEST_DATABASE_URL:?set I5H_TEST_DATABASE_URL}"
log=$(mktemp)
root=$(cd "$(dirname "$0")/.." && pwd)
status=0
for ws in "$root" "$root/examples"; do
  (cd "$ws" && cargo test --workspace --locked 2>&1) | tee -a "$log"
  [ "${PIPESTATUS[0]}" -eq 0 ] || status=1
done
if grep -q "skipping" "$log"; then
  echo "error: some database tests skipped"
  exit 1
fi
exit "$status"
