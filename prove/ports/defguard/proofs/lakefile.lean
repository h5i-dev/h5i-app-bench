import Lake
open Lake DSL

-- Pinned to the Aeneas commit `h5i app` extracts with (`h5i app doctor`).
require aeneas from git
  "https://github.com/AeneasVerif/aeneas" @ "b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"

-- h5i-app's lemmas and tactics for extracted kernels.
require h5i_app_lib from git
  "https://github.com/h5i-dev/h5i" @ "v0.5.3" / "crates/h5i-app-core/proofs"

package defguard_proofs

-- The extracted kernel (`h5i app extract`). Do not edit.
lean_lib Generated where
  srcDir := "generated"
  roots := #[`DefguardKernel]

-- Lemmas about the extracted helpers (one module per area).
lean_lib Verified where
  globs := #[.submodules `Verified]

-- The policy, stated without the kernel's helpers, and the theorems.
@[default_target] lean_lib Proofs where
  roots := #[`Spec, `Properties]
