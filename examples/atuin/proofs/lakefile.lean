import Lake
open Lake DSL

-- Pinned to the Aeneas commit that generated generated/AtuinKernel.lean.
require aeneas from git
  "https://github.com/AeneasVerif/aeneas" @ "b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"

require i5h_lib from "../../../crates/i5h/proofs"

package atuin_proofs

-- Generated Lean: the extracted Rust (scripts/extract-atuin.sh). Do not edit.
lean_lib Generated where
  srcDir := "generated"
  roots := #[`AtuinKernel]

-- Hand-written specs and proofs.
@[default_target] lean_lib Proofs where
  roots := #[`Spec, `Lemmas, `Apply, `Theorems, `Invariants]
