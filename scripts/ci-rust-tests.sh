#!/usr/bin/env bash
# Run the workspace tests against Postgres. Tests skip when the database URL
# is missing, so a skip here is a CI failure.
set -uo pipefail
: "${I5H_TEST_DATABASE_URL:?set I5H_TEST_DATABASE_URL}"
log=$(mktemp)
cargo test --workspace --locked 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
if grep -q "skipping" "$log"; then
  echo "error: some database tests skipped"
  exit 1
fi
exit "$status"
