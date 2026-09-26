#!/usr/bin/env bash
# Fail on sorry/native_decide in hand-written proofs, and on any axiom beyond
# Lean's standard three in the main theorems. Run after `lake build`.
set -uo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
proofs="$root/examples/docs/proofs"
cd "$proofs"
fail=0

# DocsKernel.lean is generated; everything else is hand-written.
files=$(ls *.lean | grep -v -x -e DocsKernel.lean -e lakefile.lean)
if hits=$(grep -n -w -e sorry -e native_decide $files); then
  echo "error: sorry or native_decide in proofs:"
  echo "$hits"
  fail=1
fi

theorems="allows_eq transition_total apply_eq authorized reply_confined inv_preserved reachable_inv noninterference"
mkdir -p .lake/ci
{
  # Modules holding the main theorems.
  for m in Theorems Invariants Noninterference; do echo "import $m"; done
  for t in $theorems; do echo "#print axioms docs_kernel.Theorems.$t"; done
} > .lake/ci/Axioms.lean
out=$(lake env lean .lake/ci/Axioms.lean 2>&1)
status=$?
echo "$out"
if [ $status -ne 0 ]; then
  echo "error: axiom check did not compile"
  fail=1
fi
for t in $theorems; do
  line=$(grep -F "'docs_kernel.Theorems.$t'" <<<"$out" || true)
  if [ -z "$line" ]; then
    echo "error: no axiom report for $t"
    fail=1
    continue
  fi
  extra=$(grep -o '\[.*\]' <<<"$line" | tr -d '[] ' | tr ',' '\n' \
    | grep -v -x -e propext -e Classical.choice -e Quot.sound -e '' || true)
  if [ -n "$extra" ]; then
    echo "error: $t uses non-standard axioms: $(echo $extra)"
    fail=1
  fi
done

[ $fail -eq 0 ] && echo "lean gate: ok"
exit $fail
