import Verified.Bytes
/-!
# `UserAuth`: the header, the session lookup, password verification
-/
open Aeneas Aeneas.Std Result atuin_kernel atuin_kernel.Spec
open H5iAppLib hiding lit

namespace atuin_kernel.Verified

theorem is_token_scheme_spec (v : Slice U8) (n : Usize) (h : n.val < v.length) :
    is_token_scheme v n ⦃ r => r = decide (n.val = 5 ∧ nats (v.val.take 5) = lit "Token") ⦄ := by
  have hl5 : lit "Token" = [84, 111, 107, 101, 110] := by decide
  rw [hl5]
  unfold is_token_scheme
  split
  · rename_i hn
    have hn' : n.val = 5 := by scalar_tac
    match hv : v.val with
    | a :: b :: c :: d :: e :: rest =>
      step*
      all_goals (simp_all [nats]; try scalar_tac)
    | [] => simp [hv] at h; try omega
    | [a] => simp [hv] at h; try omega
    | [a, b] => simp [hv] at h; try omega
    | [a, b, c] => simp [hv] at h; try omega
    | [a, b, c, d] => simp [hv] at h; try omega
  · simp only [WP.spec_ok]
    have : n.val ≠ 5 := by scalar_tac
    simp [this]

@[simp] theorem vec_deref_val {T : Type} (v : alloc.vec.Vec T) : (alloc.vec.Vec.deref v).val = v.val := by
  simp [alloc.vec.Vec.deref]

@[step] theorem parse_authorization_spec (h : Option (alloc.vec.Vec U8)) :
    parse_authorization h ⦃ r => match r with
      | .Ok t => presentedToken h = some t.val
      | .Err _ => presentedToken h = none ⦄ := by
  cases h with
  | none => simp [parse_authorization, presentedToken]
  | some v =>
    unfold parse_authorization
    simp only []
    apply WP.spec_bind (header_is_ascii_spec _); intro b hb
    simp only []
    split
    · apply WP.spec_bind (first_space_spec _); intro o ho
      simp only []
      split
      · simp only [WP.spec_ok, presentedToken]
        have : ¬ nats (v.val.take 6) = lit "Token " := by
          rw [← token_prefix_iff]; rintro ⟨h1, _⟩
          simp only [vec_deref_val] at ho
          rw [← ho] at h1; cases h1
        simp [this]
      · rename_i n
        have hn : n.val < v.length := by
          have := (List.findIdx?_eq_some_iff_findIdx_eq.1 ho.symm).1
          simp_all
        apply WP.spec_bind (is_token_scheme_spec (alloc.vec.Vec.deref v) n (by simpa using hn))
        intro b1 hb1
        simp only []
        split
        · have h5 : n.val = 5 ∧ nats (v.val.take 5) = lit "Token" := by simp_all
          have h6 : nats (v.val.take 6) = lit "Token " := (token_prefix_iff _).1 ⟨by simp_all, h5.2⟩
          have hn1 : n.val + 1 ≤ (alloc.vec.Vec.deref v).length := by simp_all; scalar_tac
          step*
          simp only [presentedToken]
          simp_all
        · simp only [WP.spec_ok, presentedToken]
          have : ¬ nats (v.val.take 6) = lit "Token " := by
            rw [← token_prefix_iff]; rintro ⟨h1, h2⟩
            simp at ho
            simp_all
          simp [this]
    · simp only [WP.spec_ok, presentedToken]
      simp_all

end atuin_kernel.Verified
