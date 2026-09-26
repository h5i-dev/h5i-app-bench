#!/usr/bin/env bash
# Record engine traces in the Postgres tests and check them against the Lean
# protocol model (lean/Engine/Trace.lean). Needs I5H_TEST_DATABASE_URL.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
export PATH="$HOME/.elan/bin:$PATH"
(cd "$root/lean" && lake build tracecheck)
: "${I5H_TEST_DATABASE_URL:?set I5H_TEST_DATABASE_URL}"
cd "$root"
cargo test -p docs-server --test traces --test faults -- --nocapture 2>&1 | grep -E "tenants ok|FAIL|^test result"
