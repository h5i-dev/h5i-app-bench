import Lake
open Lake DSL

require aeneas from git
  "https://github.com/AeneasVerif/aeneas" @ "b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"

require h5i_app_lib from "../../../../h5i/crates/h5i-app-core/proofs"

package nora_proofs

-- Generated Lean: the extracted Rust (scripts/extract-nora.sh). Do not edit.
lean_lib Generated where
  srcDir := "generated"
  roots := #[`NoraKernel]

@[default_target] lean_lib Proofs where
  roots := #[`Spec, `Properties]
