import Lake
open Lake DSL

require aeneas from git
  "https://github.com/AeneasVerif/aeneas" @ "b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"

require h5i_app_lib from git
  "https://github.com/h5i-dev/h5i" @ "v0.5.0" / "crates/h5i-app-core/proofs"

package oxicloud_proofs

-- Generated Lean: the extracted Rust (scripts/extract-oxicloud.sh). Do not edit.
lean_lib Generated where
  srcDir := "generated"
  roots := #[`OxicloudKernel]

lean_lib Verified where
  globs := #[.submodules `Verified]

@[default_target] lean_lib Proofs where
  roots := #[`Spec, `Properties]
