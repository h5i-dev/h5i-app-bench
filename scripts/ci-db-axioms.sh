#!/usr/bin/env bash
# The SQL compiler's and each server app's database theorems use only Lean's
# standard axioms. Run after building those proof projects.
set -uo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
fail=0
check() { scripts/ci-axioms.sh "$@" > /dev/null || { scripts/ci-axioms.sh "$@" | grep error; fail=1; }; }
check crates/i5h-pgsql/proofs Sound -- i5h_pgsql.Comp.valid_spec i5h_pgsql.Comp.create_spec \
  i5h_pgsql.Comp.select_spec i5h_pgsql.Comp.compile_spec i5h_pgsql.render_spec \
  i5h_pgsql.Sound.write_sound "i5h_pgsql.Sound.select_sound'" "i5h_pgsql.Sound.create_sound'"
check examples/tutorials/calculator/proofs Storage -- calculator_kernel.Storage.pg_stored
for app in board:tutorials/board ledger:tutorials/ledger inbox:tutorials/inbox booking:tutorials/booking \
    wastebin:wastebin conduit:conduit cratesio:cratesio; do
  check "examples/${app#*:}/proofs" Storage -- "${app%%:*}_kernel.Storage.db_inv"
done
[ $fail -eq 0 ] && echo "database axioms: ok"
exit $fail
