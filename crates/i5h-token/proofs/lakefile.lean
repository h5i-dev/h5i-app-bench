import Lake
open Lake DSL

-- Pinned to the Aeneas commit that generated generated/I5hToken.lean.
require aeneas from git
  "https://github.com/AeneasVerif/aeneas" @ "b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"

require i5h_lib from "../../i5h/proofs"

package token_proofs

-- Generated Lean: the extracted Rust (scripts/extract-token.sh). Do not edit.
lean_lib Generated where
  srcDir := "generated"
  roots := #[`I5hToken]

-- Hand-written specs and proofs.
@[default_target] lean_lib Proofs where
  roots := #[`TokenSpec, `TokenProofs, `TokenEncode]
