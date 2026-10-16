import Lake
open Lake DSL

-- Pinned to the Aeneas commit that generated generated/LinkdingKernel.lean.
require aeneas from git
  "https://github.com/AeneasVerif/aeneas" @ "b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"

-- h5i's Lean library, from h5i main like the Rust crates (../kernel/Cargo.toml);
-- lake-manifest.json pins the commit Cargo.lock pins.
require h5i_app_lib from git
  "https://github.com/h5i-dev/h5i" @ "main" / "crates/h5i-app-core/proofs"

package linkding_proofs

-- Generated Lean: the extracted Rust (`h5i app extract`). Do not edit.
lean_lib Generated where
  srcDir := "generated"
  roots := #[`LinkdingKernel, `Schema]

-- Hand-written specification and proofs.
@[default_target] lean_lib Proofs where
  roots := #[`Spec, `Helpers, `Apply, `Storage, `ReadOnly, `Theorems, `Owner, `Plan]
