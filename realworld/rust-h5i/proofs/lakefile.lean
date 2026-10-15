import Lake
open Lake DSL

require aeneas from git
  "https://github.com/AeneasVerif/aeneas" @ "b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"

require h5i_app_lib from git
  "https://github.com/h5i-dev/h5i" @ "v0.5.0" / "crates/h5i-app-core/proofs"

package conduit_proofs

-- Extracted kernel (`h5i app extract`). Do not edit.
lean_lib Generated where
  srcDir := "generated"
  roots := #[`ConduitKernel]

@[default_target] lean_lib Proofs where
  roots := #[`Theorems]
