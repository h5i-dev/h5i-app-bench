import Lake
open Lake DSL

-- Pinned to the Aeneas commit that generated generated/LinkdingKernel.lean.
require aeneas from git
  "https://github.com/AeneasVerif/aeneas" @ "b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"

-- h5i's Lean library uses the same revision as the Rust crates
-- (../kernel/Cargo.toml and Cargo.lock).
require h5i_app_lib from git
  "https://github.com/h5i-dev/h5i" @ "8e764ab849f71e771bc8d026491a3c104f8cb6a5" / "crates/h5i-app-core/proofs"

package linkding_proofs

-- Generated Lean: the extracted Rust (`h5i app extract`). Do not edit.
lean_lib Generated where
  srcDir := "generated"
  roots := #[`LinkdingKernel, `Schema]

-- Hand-written specification and proofs.
@[default_target] lean_lib Proofs where
  roots := #[`Spec, `Helpers, `Apply, `Storage, `ReadOnly, `Theorems, `Owner, `Plan, `Frame]
