import Verified.Derived
import Spec
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

/-! Byte-string helpers of `bytes.rs`, read back as list operations. -/

namespace rustfs_kernel.Verified.RustfsBytes

/-- `p` occurs in `s` at index `k`. -/
def PrefAt (s p : List U8) (k : Nat) : Prop :=
  k + p.length ≤ s.length ∧ ∀ j < p.length, s[k + j]? = p[j]?

theorem push_ok {α} {v w : alloc.vec.Vec α} {x : α} (h : alloc.vec.Vec.push v x = ok w) :
    w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · simp only [Result.ok.injEq] at h; subst h; simp [alloc.vec.Vec.from_val]
  · simp at h

theorem starts_with_at_loop_ok (s p : Slice U8) (f : Usize) (hl : f.val + p.val.length ≤ s.val.length)
    (i : Usize) (r : Bool)
    (hi : ∀ j < i.val, s.val[f.val + j]? = p.val[j]?) (h : bytes.starts_with_at_loop s f p i = ok r) :
    (r = true ↔ ∀ j < p.val.length, s.val[f.val + j]? = p.val[j]?) := by
  unfold bytes.starts_with_at_loop at h
  refine loop_ok _ (fun i : Usize => ∀ j < i.val, s.val[f.val + j]? = p.val[j]?)
    (fun r => r = true ↔ ∀ j < p.val.length, s.val[f.val + j]? = p.val[j]?)
    (fun i : Usize => p.val.length - i.val) ?_ i r hi h
  intro x r hx hr
  unfold bytes.starts_with_at_loop.body at hr
  h5i_invert hr
  · have h0 := add_ok_val hi2
    obtain ⟨h1, h2⟩ := slice_index_ok hi3
    obtain ⟨h3, h4⟩ := slice_index_ok hi4
    simp only [Bool.false_eq_true, false_iff, not_forall]
    refine ⟨x.val, by scalar_tac, ?_⟩
    rw [← h0, List.getElem?_eq_getElem h1, List.getElem?_eq_getElem h3, h2, h4]
    simp only [Option.some.injEq]
    intro he; simp_all
  · have h0 := add_ok_val hi2
    obtain ⟨h1, h2⟩ := slice_index_ok hi3
    obtain ⟨h3, h4⟩ := slice_index_ok hi4
    have := add_ok_val hi5
    simp only
    refine ⟨fun j hj => ?_, by scalar_tac⟩
    by_cases hjx : j < x.val
    · exact hx j hjx
    · have : j = x.val := by scalar_tac
      subst this
      have : i3 = i4 := (u8_eq_iff _ _).2 (by simpa using hc_1)
      rw [← h0, List.getElem?_eq_getElem h1, List.getElem?_eq_getElem h3, h2, h4, this]
  · simp only [true_iff]
    intro j hj
    exact hx j (by scalar_tac)

theorem starts_with_at_ok (s p : Slice U8) (f : Usize) (r : Bool)
    (h : bytes.starts_with_at s f p = ok r) : (r = true ↔ PrefAt s.val p.val f.val) := by
  unfold bytes.starts_with_at at h
  unfold PrefAt
  h5i_invert h
  · simp only [Bool.false_eq_true, false_iff, not_and]
    intro h; scalar_tac
  · have := sub_ok_val hi2
    simp only [Bool.false_eq_true, false_iff, not_and]
    intro h; scalar_tac
  · have := sub_ok_val hi2
    have hl : f.val + p.val.length ≤ s.val.length := by scalar_tac
    rw [starts_with_at_loop_ok s p f hl _ r (by simp) h]
    simp [hl]

theorem starts_with_ok (s p : Slice U8) (r : Bool)
    (h : bytes.starts_with s p = ok r) : (r = true ↔ PrefAt s.val p.val 0) := by
  unfold bytes.starts_with at h
  exact starts_with_at_ok s p 0#usize r h

theorem not_prefAt_short {s p : List U8} {k : Nat} (h : s.length < k + p.length) : ¬ PrefAt s p k :=
  fun ⟨h1, _⟩ => by omega

theorem find_from_ok (s p : Slice U8) (f : Usize) (o : Option Usize)
    (h : bytes.find_from s f p = ok o) :
    (∀ j, o = some j → PrefAt s.val p.val j.val) ∧
    (o = none → ∀ k, f.val ≤ k → ¬ PrefAt s.val p.val k) := by
  unfold bytes.find_from bytes.find_from_loop at h
  refine loop_ok _ (fun i : Usize => ∀ k, f.val ≤ k → k < i.val → ¬ PrefAt s.val p.val k)
    (fun o => (∀ j, o = some j → PrefAt s.val p.val j.val) ∧
      (o = none → ∀ k, f.val ≤ k → ¬ PrefAt s.val p.val k))
    (fun i : Usize => s.val.length + 1 - i.val) ?_ f o (fun k h1 h2 => by omega) h
  intro x r hx hr
  unfold bytes.find_from_loop.body at hr
  h5i_invert hr
  · have := sub_ok_val hi3
    have hb := starts_with_at_ok s p x b hb
    refine ⟨fun j hj => ?_, by simp⟩
    cases Option.some.inj hj
    exact hb.1 hc_2
  · have := sub_ok_val hi3
    have hb := starts_with_at_ok s p x b hb
    have := add_ok_val hi5
    refine ⟨fun k h1 h2 => ?_, by scalar_tac⟩
    by_cases hk : k < x.val
    · exact hx k h1 hk
    · have : k = x.val := by scalar_tac
      subst this
      intro hp; simp_all
  · have := sub_ok_val hi3
    refine ⟨by simp, fun _ k h1 => ?_⟩
    by_cases hk : k < x.val
    · exact hx k h1 hk
    · exact not_prefAt_short (by scalar_tac)
  · refine ⟨by simp, fun _ k h1 => ?_⟩
    by_cases hk : k < x.val
    · exact hx k h1 hk
    · exact not_prefAt_short (by scalar_tac)

theorem contains_ok (s p : Slice U8) (r : Bool) (h : bytes.contains s p = ok r) :
    (r = true ↔ ∃ k, PrefAt s.val p.val k) := by
  unfold bytes.contains at h
  obtain ⟨o, ho, h⟩ := bind_eq_ok.1 h
  obtain ⟨h1, h2⟩ := find_from_ok s p 0#usize o ho
  cases o with
  | some j =>
    simp only [Result.ok.injEq] at h; subst h
    simp only [true_iff]
    exact ⟨_, h1 _ rfl⟩
  | none =>
    simp only [Result.ok.injEq] at h; subst h
    simp only [Bool.false_eq_true, false_iff, not_exists]
    intro k
    exact h2 rfl k (by simp)

theorem slice_ok (s : Slice U8) (a b : Usize) (v : alloc.vec.Vec U8)
    (h : bytes.slice s a b = ok v) : v.val = (s.val.take b.val).drop a.val := by
  unfold bytes.slice bytes.slice_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec U8 × Usize =>
      x.1.val = (s.val.take x.2.val).drop a.val ∧ a.val ≤ x.2.val ∧ (x.2.val ≤ b.val ∨ x.2.val = a.val))
    (fun v : alloc.vec.Vec U8 => v.val = (s.val.take b.val).drop a.val)
    (fun x => b.val + 1 - x.2.val) ?_ _ v ⟨by simp, le_refl _, Or.inr rfl⟩ h
  rintro ⟨out, i⟩ r ⟨hx1, hx2, hx3⟩ hr
  simp only at hx1 hx2 hx3
  unfold bytes.slice_loop.body at hr
  h5i_invert hr
  · obtain ⟨h1, h2⟩ := slice_index_ok hi1
    have hp := push_ok hout1
    have := add_ok_val hi2
    simp only
    refine ⟨⟨?_, by scalar_tac, Or.inl (by scalar_tac)⟩, by scalar_tac⟩
    rw [hp, hx1, show i2.val = i.val + 1 by scalar_tac, List.take_add_one, List.drop_append_of_le_length
      (by simp; omega), List.getElem?_eq_getElem h1, h2]
    rfl
  · simp only
    rw [hx1]
    rcases hx3 with h3 | h3
    · rw [show i.val = b.val by scalar_tac]
    · have : b.val ≤ a.val := by scalar_tac
      rw [h3, List.drop_eq_nil_of_le (by simp only [List.length_take]; omega)]
      exact (List.drop_eq_nil_of_le (by simp only [List.length_take]; omega)).symm

end rustfs_kernel.Verified.RustfsBytes
