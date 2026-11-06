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


theorem u8_or_eq_zero (x y : U8) : (x ||| y) = 0#u8 ↔ x = 0#u8 ∧ y = 0#u8 := by
  simp only [UScalar.eq_equiv_bv_eq, UScalar.bv_or]
  simp [BitVec.or_eq_zero_iff]

theorem u8_xor_eq_zero (x y : U8) : (x ^^^ y) = 0#u8 ↔ x = y := by
  simp only [UScalar.eq_equiv_bv_eq, UScalar.bv_xor]
  simp

/-- `constant_time_eq` is equality. -/
@[step] theorem constant_time_eq_spec (a b : Slice U8) :
    bytes.constant_time_eq a b ⦃ r => r = decide (nats a.val = nats b.val) ⦄ := by
  rw [show decide (nats a.val = nats b.val) = decide (a.val = b.val) from
    decide_eq_decide.2 nats_inj]
  unfold bytes.constant_time_eq; simp only []
  split
  · simp only [WP.spec_ok]
    have : a.val ≠ b.val := fun h => by simp_all
    simp [this]
  · rename_i hlen
    have hl : (a.val).length = (b.val).length := by scalar_tac
    unfold bytes.constant_time_eq_loop
    apply WP.spec_bind (Pₘ := fun d => (d = 0#u8 ↔ a.val = b.val))
    · apply loop.spec_decr_nat (measure := fun (x : U8 × Usize) => a.length - x.2.val)
        (inv := fun x => x.2.val ≤ a.length ∧ (x.1 = 0#u8 ↔ ∀ k < x.2.val, a.val[k]! = b.val[k]!))
      · rintro ⟨d, j⟩ ⟨hj, hk⟩
        simp only at hj hk
        unfold bytes.constant_time_eq_loop.body; simp only []
        step*
        · have hd1 : diff1 = d ||| (i2 ^^^ i3) := by
            rw [UScalar.eq_equiv_bv_eq]; simp [diff1_post1, i4_post1]
          refine ⟨by scalar_tac, ?_, by scalar_tac⟩
          rw [hd1, u8_or_eq_zero, u8_xor_eq_zero, hk]
          constructor
          · rintro ⟨h1, h2⟩ k hk'
            rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < j.val + 1 by scalar_tac) with h3 | h3
            · exact h1 k h3
            · subst h3
              rw [List.getElem!_eq_getElem?_getD, List.getElem!_eq_getElem?_getD,
                List.getElem?_eq_getElem (by scalar_tac), List.getElem?_eq_getElem (by scalar_tac)]
              simp_all
          · intro h
            refine ⟨fun k hk' => h k (by omega), ?_⟩
            have := h j.val (by scalar_tac)
            rw [List.getElem!_eq_getElem?_getD, List.getElem!_eq_getElem?_getD,
              List.getElem?_eq_getElem (by scalar_tac), List.getElem?_eq_getElem (by scalar_tac)] at this
            simp_all
        · rw [hk]
          constructor
          · intro h
            apply List.ext_getElem hl
            intro n h1 h2
            have := h n (by scalar_tac)
            rw [List.getElem!_eq_getElem?_getD, List.getElem!_eq_getElem?_getD,
              List.getElem?_eq_getElem h1, List.getElem?_eq_getElem h2] at this
            simpa using this
          · intro h k _; rw [h]
      · simp
    · intro d hd
      simp only [WP.spec_ok]
      by_cases h : a.val = b.val <;> simp_all


@[step] theorem starts_with_spec (s p : Slice U8) :
    bytes.starts_with s p ⦃ b => b = decide (nats p.val <+: nats s.val) ⦄ := by
  rw [show decide (nats p.val <+: nats s.val) = decide (p.val <+: s.val) from
    decide_eq_decide.2 (List.prefix_map_iff_of_injective (fun _ _ h => UScalar.eq_of_val_eq h))]
  unfold bytes.starts_with; simp only []
  split
  · simp only [WP.spec_ok]
    have : ¬ p.val <+: s.val := fun h => by have := h.length_le; scalar_tac
    simp [this]
  · unfold bytes.starts_with_loop
    apply loop.spec_decr_nat (measure := fun (j : Usize) => p.length - j.val)
      (inv := fun j => j.val ≤ p.length ∧ ∀ k < j.val, s.val[k]! = p.val[k]!)
    · rintro j ⟨hj, hk⟩
      unfold bytes.starts_with_loop.body; simp only []
      step*
      · have : ¬ p.val <+: s.val := fun h => by
          have := h.getElem (i := j.val) (by scalar_tac); simp_all; contradiction
        simp [this]
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
      · have hl : (p.val).length ≤ (s.val).length := by scalar_tac
        have : p.val <+: s.val := by
          rw [List.prefix_iff_eq_take]
          apply List.ext_getElem (by simp; omega)
          intro n h1 h2
          have := hk n (by scalar_tac)
          simp at this
          rw [List.getElem?_eq_getElem (by simp at h2; omega)] at this
          simp [List.getElem?_eq_getElem h1] at this
          simp [this]
        simp [this]
    · simp

theorem take_succ_eq {α} (l : List α) (j : Nat) (h : j < l.length) :
    l.take (j + 1) = l.take j ++ [l[j]] := by
  rw [List.take_add_one, List.getElem?_eq_getElem h]; simp

@[step] theorem suffix_spec (s : Slice U8) (f : Usize) :
    bytes.suffix s f ⦃ v => v.val = s.val.drop f.val ⦄ := by
  unfold bytes.suffix bytes.suffix_loop
  apply loop.spec_decr_nat (measure := fun (x : alloc.vec.Vec U8 × Usize) => s.length + 1 - x.2.val)
    (inv := fun x => f.val ≤ x.2.val ∧ (x.2.val ≤ s.length ∨ x.2.val = f.val) ∧
      x.1.val = (s.val.take x.2.val).drop f.val)
  · rintro ⟨out, j⟩ ⟨h1, h2, h3⟩
    simp only at h1 h2 h3
    have hl : out.val.length ≤ j.val := by rw [h3]; simp; try omega
    unfold bytes.suffix_loop.body; simp only []
    step*
    · have hj : j.val < s.val.length := by scalar_tac
      refine ⟨by scalar_tac, by scalar_tac, ?_, by scalar_tac⟩
      rw [out1_post, h3, i3_post, take_succ_eq _ _ hj, i2_post,
        List.drop_append_of_le_length (by simp; omega)]
    · rw [h3, List.take_of_length_le (by scalar_tac)]
  · simp

@[step] theorem prefix_spec (s : Slice U8) (t : Usize) :
    bytes.prefix s t ⦃ v => v.val = s.val.take t.val ⦄ := by
  unfold bytes.prefix bytes.prefix_loop
  apply loop.spec_decr_nat (measure := fun (x : alloc.vec.Vec U8 × Usize) => s.length - x.2.val)
    (inv := fun x => x.2.val ≤ s.length ∧ x.2.val ≤ t.val ∧ x.1.val = s.val.take x.2.val)
  · rintro ⟨out, j⟩ ⟨h1, h2, h3⟩
    simp only at h1 h2 h3
    have hl : out.val.length ≤ j.val := by rw [h3]; simp
    unfold bytes.prefix_loop.body; simp only []
    step*
    · have hj : j.val < s.val.length := by scalar_tac
      refine ⟨by scalar_tac, by scalar_tac, ?_, by scalar_tac⟩
      rw [out1_post, h3, i3_post, take_succ_eq _ _ hj, i2_post]
    · rw [h3, List.take_of_length_le (by scalar_tac), List.take_of_length_le (by scalar_tac)]
  · simp

@[step] theorem strip_prefix_spec (s p : Slice U8) :
    bytes.strip_prefix s p ⦃ o => o.map (fun v => v.val) =
      if nats p.val <+: nats s.val then some (s.val.drop p.val.length) else none ⦄ := by
  unfold bytes.strip_prefix
  step*
  · simp_all
  · simp_all

theorem splitAcc_drop (s : List U8) (j : Nat) (h : j < s.length) (cur : List Nat) :
    splitAcc cur (nats (s.drop j)) = if s[j].val = 47 then cur :: splitAcc [] (nats (s.drop (j+1)))
      else splitAcc (cur ++ [s[j].val]) (nats (s.drop (j+1))) := by
  rw [List.drop_eq_getElem_cons h]; simp only [nats, List.map_cons, splitAcc]

@[step] theorem split_slash_spec (s : Slice U8) (hs : s.length < Usize.max) :
    bytes.split_slash s ⦃ v => v.val.map (fun w => nats w.val) = splitSlash (nats s.val) ⦄ := by
  unfold bytes.split_slash bytes.split_slash_loop
  apply WP.spec_bind (Pₘ := fun (x : alloc.vec.Vec (alloc.vec.Vec U8) × alloc.vec.Vec U8) =>
    x.1.val.length ≤ s.length ∧
    x.1.val.map (fun w => nats w.val) ++ [nats x.2.val] = splitSlash (nats s.val))
  · apply loop.spec_decr_nat
      (measure := fun (x : alloc.vec.Vec (alloc.vec.Vec U8) × alloc.vec.Vec U8 × Usize) => s.length - x.2.2.val)
      (inv := fun x => x.2.2.val ≤ s.length ∧ x.1.val.length + x.2.1.val.length ≤ x.2.2.val ∧
        x.1.val.map (fun w => nats w.val) ++ splitAcc (nats x.2.1.val) (nats (s.val.drop x.2.2.val)) =
          splitSlash (nats s.val))
    · rintro ⟨out, cur, j⟩ ⟨h1, h2, h3⟩
      simp only at h1 h2 h3
      unfold bytes.split_slash_loop.body; simp only []
      have hn : out.val.length + cur.val.length < Usize.max := by scalar_tac
      split
      · rename_i hj
        have hj' : j.val < s.val.length := by scalar_tac
        have hsa := splitAcc_drop s.val j.val hj' (nats cur.val)
        step*
        by_cases hc : i2 = 47#u8
        · simp only [hc, if_true]
          step*
          refine ⟨by scalar_tac, by simp [x_post]; scalar_tac, ?_, by scalar_tac⟩
          rw [← h3, hsa, i3_post]
          have : (s.val[j.val]).val = 47 := by rw [← i2_post, hc]; rfl
          simp [this, x_post, nats]
        · simp only [hc, if_false]
          step*
          refine ⟨by scalar_tac, by simp [x_post]; scalar_tac, ?_, by scalar_tac⟩
          rw [← h3, hsa, i3_post]
          have : ¬ (s.val[j.val]).val = 47 := by
            intro h; apply hc; rw [i2_post]; apply UScalar.eq_of_val_eq; simpa using h
          simp [this, x_post, nats, i2_post]
      · simp only [WP.spec_ok]
        have : s.val.drop j.val = [] := List.drop_eq_nil_of_le (by scalar_tac)
        rw [this] at h3
        refine ⟨by scalar_tac, ?_⟩
        simpa [splitAcc, nats] using h3
    · simp [splitSlash, nats]
  · rintro ⟨out, cur⟩ ⟨h1, h2⟩
    simp only at h1 h2
    step*
    rw [v_post, ← h2]; simp

theorem takeWhile_len_stop {α} (l : List α) (p : α → Bool) (j : Nat)
    (hall : (l.take j).all p) (hj : j < l.length) (hn : p l[j] = false) :
    (l.takeWhile p).length = j := by
  induction l generalizing j with
  | nil => simp at hj
  | cons a t ih =>
    cases j with
    | zero => simp_all
    | succ k =>
      simp only [List.take_succ_cons, List.all_cons, Bool.and_eq_true] at hall
      simp only [List.takeWhile_cons, hall.1, if_true, List.length_cons]
      simp at hj
      rw [ih k hall.2 (by omega) (by simpa using hn)]

@[step] theorem find_byte_spec (s : Slice U8) (c : U8) :
    bytes.find_byte s c ⦃ i => i.val = (s.val.takeWhile (fun x => x ≠ c)).length ⦄ := by
  unfold bytes.find_byte bytes.find_byte_loop
  apply loop.spec_decr_nat (measure := fun (j : Usize) => s.length - j.val)
    (inv := fun j => j.val ≤ s.length ∧ (s.val.take j.val).all (fun x => x ≠ c))
  · rintro j ⟨hj, hk⟩
    unfold bytes.find_byte_loop.body; simp only []
    step*
    · rw [takeWhile_len_stop _ _ j.val hk (by scalar_tac) (by simp_all)]
    · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
      rw [i3_post, take_succ_eq _ _ (by scalar_tac)]
      simp only [List.all_append, Bool.and_eq_true, List.all_cons, List.all_nil, Bool.and_true]
      refine ⟨by simpa using hk, ?_⟩
      simp only [decide_eq_true_eq]
      intro h; apply ‹¬ _›; rw [i2_post, h]
    · have : s.val.take j.val = s.val := List.take_of_length_le (by scalar_tac)
      rw [this] at hk
      rw [List.takeWhile_eq_self_iff.2 (by simpa using hk)]
      simp
  · simp

theorem takeWhile_lt_iff {α} (l : List α) (c : α) [DecidableEq α] :
    (l.takeWhile (fun x => decide (x ≠ c))).length < l.length ↔ c ∈ l := by
  induction l with
  | nil => simp
  | cons a t ih =>
    by_cases h : a = c
    · subst h; simp
    · rw [List.takeWhile_cons, if_pos (by simpa using h)]
      simp only [List.length_cons, List.mem_cons]
      rw [Nat.add_lt_add_iff_right, ih]
      constructor
      · exact Or.inr
      · rintro (h' | h'); exact absurd h'.symm h; exact h'

@[step] theorem split_once_spec (s : Slice U8) (c : U8) :
    bytes.split_once s c ⦃ o => o.isSome = decide (c ∈ s.val) ⦄ := by
  unfold bytes.split_once
  step*
  · simp only [Option.isSome_some]
    rw [eq_comm, decide_eq_true_iff, ← takeWhile_lt_iff]; scalar_tac
  · simp only [Option.isSome_none]
    rw [eq_comm, decide_eq_false_iff_not, ← takeWhile_lt_iff]; scalar_tac

@[step] theorem contains_spec (list : Slice (alloc.vec.Vec U8)) (x : Slice U8) :
    bytes.contains list x ⦃ b => b = decide (nats x.val ∈ list.val.map (fun v => nats v.val)) ⦄ := by
  unfold bytes.contains bytes.contains_loop
  apply WP.spec_mono (loop_search list.val (fun v => decide (nats v.val = nats x.val)) id
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro b hb
    rw [id, searchFrom_const] at hb
    simp only [UScalar.ofNatCore_val_eq, List.drop_zero] at hb
    rw [hb]
    have : list.val.any (fun v => decide (nats v.val = nats x.val)) =
        decide (nats x.val ∈ list.val.map (fun v => nats v.val)) := by
      rw [Bool.eq_iff_iff, List.any_eq_true, decide_eq_true_iff, List.mem_map]
      simp only [decide_eq_true_eq]
    rw [this]; cases decide (nats x.val ∈ list.val.map (fun v => nats v.val)) <;> rfl
  · intro i hi
    unfold bytes.contains_loop.body; simp only []
    step*
    · left; exact ⟨by scalar_tac, by simp_all [alloc.vec.Vec.deref], rfl⟩
    · exact ⟨by scalar_tac, by simp_all [alloc.vec.Vec.deref], by scalar_tac⟩
    · right; exact ⟨by scalar_tac, rfl⟩


end openobserve_kernel.Verified
