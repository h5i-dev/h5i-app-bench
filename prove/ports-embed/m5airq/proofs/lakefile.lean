import Lake
open Lake DSL

-- Pinned to the Aeneas commit that generated generated/M5airqKernel.lean,
-- and the h5i-app-core proofs library (H5iAppLib). Both resolve from the
-- shared Lean package cache via the .lake/packages symlink.
require aeneas from git
  "https://github.com/AeneasVerif/aeneas" @ "b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"

require h5i_app_lib from git
  "https://github.com/h5i-dev/h5i" @ "v0.5.0" / "crates/h5i-app-core/proofs"

package m5airq_proofs

-- Generated Lean: the extracted Rust (`h5i app extract`). Do not edit.
lean_lib Generated where
  srcDir := "generated"
  roots := #[`M5airqKernel]

-- Hand-written spec and proofs.
@[default_target] lean_lib Proofs where
  roots := #[`Properties, `ReadOnly]
