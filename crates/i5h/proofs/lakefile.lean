import Lake
open Lake DSL

-- Same Aeneas pin as the example proofs.
require aeneas from git
  "https://github.com/AeneasVerif/aeneas" @ "b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"

package i5h_lib

-- Reusable lemmas and tactics for Aeneas-extracted i5h kernels.
@[default_target] lean_lib I5hLib where
  roots := #[`I5hLib]
