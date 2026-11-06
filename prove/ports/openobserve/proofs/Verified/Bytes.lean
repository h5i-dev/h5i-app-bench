import Spec
import H5iAppLib
/-! Specs for the byte-string helpers in `kernel/src/bytes.rs`. -/
open Aeneas Aeneas.Std Result openobserve_kernel openobserve_kernel.Spec
open H5iAppLib hiding lit

namespace openobserve_kernel.Verified

theorem nats_inj {a b : List U8} : nats a = nats b ↔ a = b :=
  (List.map_injective_iff.2 (fun _ _ h => UScalar.eq_of_val_eq h)).eq_iff

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    bytes.bytes_eq a b ⦃ r => r = decide (nats a.val = nats b.val) ⦄ := by
  rw [show decide (nats a.val = nats b.val) = decide (a.val = b.val) from
    decide_eq_decide.2 nats_inj]
  unfold bytes.bytes_eq; simp only []
  split
  · simp only [WP.spec_ok]
    have : a.val ≠ b.val := fun h => by simp_all
    simp [this]
  · unfold bytes.bytes_eq_loop
    apply loop.spec_decr_nat (measure := fun (j : Usize) => a.length - j.val)
      (inv := fun j => j.val ≤ a.length ∧ ∀ k < j.val, a.val[k]! = b.val[k]!)
    · rintro j ⟨hj, hk⟩
      unfold bytes.bytes_eq_loop.body; simp only []
      step*
      · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
        intro k hk'
        rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < j.val + 1 by scalar_tac) with h1 | h1
        · exact hk k h1
        · subst h1
          rw [List.getElem!_eq_getElem?_getD, List.getElem!_eq_getElem?_getD,
            List.getElem?_eq_getElem (by scalar_tac), List.getElem?_eq_getElem (by scalar_tac)]
          simp only [Option.getD_some]
          apply UScalar.eq_of_val_eq
          simp_all
      · have hl : (a.val).length = (b.val).length := by scalar_tac
        have : a.val = b.val := by
          apply List.ext_getElem hl
          intro n h1 h2
          have := hk n (by scalar_tac)
          simp at this
          rw [List.getElem?_eq_getElem (by omega)] at this
          simpa [List.getElem?_eq_getElem h2] using this
        simp [this]
    · simp

end openobserve_kernel.Verified
