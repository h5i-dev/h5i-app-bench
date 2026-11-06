import Spec
/-!
# The failed-login tracker and the login gate
-/
open Aeneas Aeneas.Std Result defguard_kernel defguard_kernel.Spec
open H5iAppLib

namespace defguard_kernel.Verified

h5i_derive_all

theorem getElem!_of_lt {a : List U8} {k : Nat} (h : k < a.length) : a[k]! = a[k] := by
  rw [List.getElem!_eq_getElem?_getD, List.getElem?_eq_getElem h]; rfl

theorem list_eq_of_getElem! {a b : List U8} (hl : a.length = b.length)
    (hk : ∀ k < a.length, a[k]! = b[k]!) : a = b := by
  apply List.ext_getElem hl
  intro n h1 h2
  have := hk n h1
  rw [getElem!_of_lt h1, getElem!_of_lt h2] at this
  exact this

@[simp] theorem vec_deref_val {T : Type} (v : alloc.vec.Vec T) : (alloc.vec.Vec.deref v).val = v.val := by
  simp [alloc.vec.Vec.deref]

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    lockout.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold lockout.bytes_eq; simp only []
  split
  · simp only [WP.spec_ok]
    have : a.val ≠ b.val := fun h => by simp_all
    simp [this]
  · unfold lockout.bytes_eq_loop
    apply loop.spec_decr_nat (measure := fun (j : Usize) => a.length - j.val)
      (inv := fun j => j.val ≤ a.length ∧ ∀ k < j.val, a.val[k]! = b.val[k]!)
    · rintro j ⟨hj, hk⟩
      unfold lockout.bytes_eq_loop.body; simp only []
      step*
      · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
        intro k hk'
        rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < j.val + 1 by scalar_tac) with h1 | h1
        · exact hk k h1
        · subst h1
          rw [getElem!_of_lt (by scalar_tac), getElem!_of_lt (by scalar_tac)]
          apply UScalar.eq_of_val_eq
          simp_all
      · have : a.val = b.val := list_eq_of_getElem! (by scalar_tac) (fun k hk' => hk k (by scalar_tac))
        simp [this]
    · simp

@[step] theorem find_entry_spec (map : alloc.vec.Vec lockout.FailedLogin) (k : Slice U8) :
    lockout.find_entry map k ⦃ o => o.map (·.val) = map.val.findIdx? (fun f => decide (f.key.val = k.val)) ⦄ := by
  unfold lockout.find_entry lockout.find_entry_loop
  apply WP.spec_mono (H5iAppLib.loop_search map.val (fun f => decide (f.key.val = k.val)) (fun r => r.map (·.val))
    (fun i _ => some i) none _ ?step 0#usize (by simp))
  · intro r hr; rw [hr, H5iAppLib.searchFrom_findIdx]; simp
  case step =>
    intro j hj; unfold lockout.find_entry_loop.body; h5i_step

theorem isub_ok_val {ty} {x y z : IScalar ty} (h : x - y = ok z) : z.val = x.val - y.val := by
  have := IScalar.sub_equiv x y; rw [h] at this; simp at this; omega

theorem should_prevent_ok {f : lockout.FailedLogin} {now : I64} {b : Bool}
    (h : lockout.should_prevent_login f now = ok b) :
    b = decide (5 ≤ f.attempt_count.val ∧ now.val - f.last_attempt.val ≤ 300000000000) := by
  unfold lockout.should_prevent_login at h
  h5i_invert h
  all_goals (try have := isub_ok_val hi)
  all_goals (simp_all [lockout.COUNT, lockout.TIMEOUT_NS]; try omega)

theorem should_reset_ok {f : lockout.FailedLogin} {now : I64} {b : Bool}
    (h : lockout.should_reset_counter f now = ok b) :
    b = decide ((now.val - f.first_attempt.val > 60000000000 ∧ f.attempt_count.val < 5) ∨
      now.val - f.last_attempt.val > 300000000000) := by
  unfold lockout.should_reset_counter at h
  h5i_invert h
  all_goals (try have := isub_ok_val hi)
  all_goals (try have := isub_ok_val hi1)
  all_goals (simp_all [lockout.COUNT, lockout.TIMEOUT_NS, lockout.WINDOW_NS]; try omega)

/-! ## Lists -/

theorem find_set_first {α : Type} (p : α → Bool) (l : List α) (i : Nat) (f : α)
    (hi : l.findIdx? p = some i) (hf : p f = true) : (l.set i f).find? p = some f := by
  induction l generalizing i with
  | nil => simp at hi
  | cons x xs ih =>
    by_cases hx : p x
    · simp [List.findIdx?_cons, hx] at hi; subst hi; simp [hf]
    · simp [List.findIdx?_cons, hx] at hi
      obtain ⟨j, hj, rfl⟩ := hi
      simp [hx, ih j hj]

theorem find_set_other {α : Type} (p q : α → Bool) (l : List α) (i : Nat) (f : α)
    (hi : l.findIdx? p = some i) (hq : ∀ x, p x = true → q x = false) (hf : q f = false) :
    (l.set i f).find? q = l.find? q := by
  induction l generalizing i with
  | nil => simp at hi
  | cons x xs ih =>
    by_cases hx : p x
    · simp [List.findIdx?_cons, hx] at hi; subst hi; simp [hf, hq x hx]
    · simp [List.findIdx?_cons, hx] at hi
      obtain ⟨j, hj, rfl⟩ := hi
      by_cases hqx : q x <;> simp [hqx, ih j hj]

theorem find_of_findIdx {α : Type} (p : α → Bool) (l : List α) (i : Nat) (hi : l.findIdx? p = some i) :
    ∃ h : i < l.length, l.find? p = some l[i] := by
  obtain ⟨hl, hidx⟩ := List.findIdx?_eq_some_iff_findIdx_eq.1 hi
  refine ⟨hl, ?_⟩
  rw [List.find?_eq_getElem?_findIdx, hidx, List.getElem?_eq_getElem hl]

end defguard_kernel.Verified
