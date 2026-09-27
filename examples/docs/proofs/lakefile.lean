import Lake
open Lake DSL

-- Pinned to the Aeneas commit that generated generated/DocsKernel.lean.
require aeneas from git
  "https://github.com/AeneasVerif/aeneas" @ "b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"

require i5h_lib from "../../../crates/i5h/proofs"

package docs_proofs

-- Generated Lean: the extracted Rust (scripts/extract.sh) and schema! output. Do not edit.
lean_lib Generated where
  srcDir := "generated"
  roots := #[`DocsKernel, `Schema]

-- Hand-written specs and proofs.
@[default_target] lean_lib Proofs where
  roots := #[`Columns, `Spec, `Lemmas, `Apply, `Transition, `Theorems, `Invariants, `Noninterference, `Frame, `Check, `Storage, `Load, `Scoped, `Scenarios]

-- Runs the extracted kernel for differential tests (scripts/difftest.sh).
lean_exe difftest where
  root := `DiffTest
