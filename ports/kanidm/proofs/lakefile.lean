import Lake
open Lake DSL

require aeneas from git
  "https://github.com/AeneasVerif/aeneas" @ "b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"

require h5i_app_lib from "../../../../h5i/crates/h5i-app-core/proofs"

package kanidm_proofs

-- Generated Lean: the extracted Rust (scripts/extract-kanidm.sh). Do not edit.
lean_lib Generated where
  srcDir := "generated"
  roots := #[`KanidmKernel]

@[default_target] lean_lib Proofs where
  roots := #[`Spec, `Properties]
