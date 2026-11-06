import Spec
/-!
# Lemmas about the extracted path-traversal check
-/
open Aeneas Aeneas.Std Result Aeneas.Std.WP synctv_kernel synctv_kernel.Spec H5iAppLib

set_option linter.unusedSimpArgs false

namespace synctv_kernel.PathLemmas

/-- The byte values of a slice. -/
abbrev vals (s : Slice U8) : List Nat := s.val.map (·.val)

@[step] theorem hex_val_spec (b : U8) :
    pathcheck.hex_val b ⦃ r => (r.val < 16 → hexDigit b.val = some r.val) ∧ (16 ≤ r.val → hexDigit b.val = none) ⦄ := by
  unfold pathcheck.hex_val
  step*
  all_goals (simp only [hexDigit]; split_ifs <;> simp_all <;> scalar_tac)

@[step] theorem hex_pair_is_spec (a b t : U8) :
    pathcheck.hex_pair_is a b t ⦃ r => (r = true ↔ hexPair a.val b.val = some t.val) ⦄ := by
  unfold pathcheck.hex_pair_is
  step*
  · have ha := h_post (by scalar_tac)
    have hb := l_post (by scalar_tac)
    simp only [hexPair, ha, hb, Option.some.injEq, decide_eq_true_eq]
    constructor
    · intro e; subst e; scalar_tac
    · intro e; apply UScalar.eq_of_val_eq; scalar_tac
  · have hb := l_post1 (by scalar_tac)
    simp [hexPair, hb]
  · have ha := h_post1 (by scalar_tac)
    simp [hexPair, ha]

end synctv_kernel.PathLemmas
