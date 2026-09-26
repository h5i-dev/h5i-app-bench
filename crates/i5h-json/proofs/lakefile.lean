import Lake
open Lake DSL

-- Pinned to the Aeneas commit that generated generated/I5hJson.lean.
require aeneas from git
  "https://github.com/AeneasVerif/aeneas" @ "b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"

package json_proofs

-- Generated Lean: the extracted Rust (scripts/extract-json.sh). Do not edit.
lean_lib Generated where
  srcDir := "generated"
  roots := #[`I5hJson]

-- Hand-written specs and proofs.
@[default_target] lean_lib Proofs where
  roots := #[`JsonSpec, `JsonProofs]
