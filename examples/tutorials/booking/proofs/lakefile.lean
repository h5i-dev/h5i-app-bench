import Lake
open Lake DSL

-- Pinned to the Aeneas commit that generated generated/BookingKernel.lean.
require aeneas from git
  "https://github.com/AeneasVerif/aeneas" @ "b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"

require i5h_lib from "../../../../crates/i5h/proofs"

package booking_proofs

-- Generated Lean: the extracted Rust (scripts/extract-booking.sh). Do not edit.
lean_lib Generated where
  srcDir := "generated"
  roots := #[`BookingKernel]

-- Hand-written specification and proofs.
@[default_target] lean_lib Proofs where
  roots := #[`Spec, `Commands, `Theorems, `Apply, `Scenarios, `Clock]
