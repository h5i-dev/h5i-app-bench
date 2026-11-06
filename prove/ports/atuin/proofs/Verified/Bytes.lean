import Spec
/-!
# Byte-string helpers: equality, `LOWER`, usernames, the `Authorization` header
-/
open Aeneas Aeneas.Std Result atuin_kernel atuin_kernel.Spec
open H5iAppLib hiding lit

namespace atuin_kernel.Verified

theorem getElem!_of_lt {a : List U8} {k : Nat} (h : k < a.length) : a[k]! = a[k] := by
  rw [List.getElem!_eq_getElem?_getD, List.getElem?_eq_getElem h]; rfl

theorem list_eq_of_getElem! {a b : List U8} (hl : a.length = b.length)
    (hk : ∀ k < a.length, a[k]! = b[k]!) : a = b := by
  apply List.ext_getElem hl
  intro n h1 h2
  have := hk n h1
  rw [getElem!_of_lt h1, getElem!_of_lt h2] at this
  exact this

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold bytes_eq; simp only []
  split
  · simp only [WP.spec_ok]
    have : a.val ≠ b.val := fun h => by simp_all
    simp [this]
  · unfold bytes_eq_loop
    apply loop.spec_decr_nat (measure := fun (j : Usize) => a.length - j.val)
      (inv := fun j => j.val ≤ a.length ∧ ∀ k < j.val, a.val[k]! = b.val[k]!)
    · rintro j ⟨hj, hk⟩
      unfold bytes_eq_loop.body; simp only []
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

@[step] theorem ascii_lower_spec (b : U8) : ascii_lower b ⦃ r => r.val = lowerN b.val ⦄ := by
  unfold ascii_lower lowerN
  step*
  all_goals (simp_all; try scalar_tac)

theorem lowerEq_iff (a b : List U8) :
    LowerEq a b ↔ a.length = b.length ∧ ∀ k < a.length, lowerN a[k]!.val = lowerN b[k]!.val := by
  unfold LowerEq
  constructor
  · intro h
    have hl : a.length = b.length := by simpa using congrArg List.length h
    refine ⟨hl, fun k hk => ?_⟩
    have := congrArg (fun l => l[k]?) h
    simp only [List.getElem?_map, List.getElem?_eq_getElem hk, List.getElem?_eq_getElem (show k < b.length by omega),
      Option.map_some, Option.some.injEq] at this
    rw [getElem!_of_lt hk, getElem!_of_lt (by omega)]
    exact this
  · rintro ⟨hl, hk⟩
    apply List.ext_getElem (by simpa using hl)
    intro n h1 h2
    have := hk n (by simpa using h1)
    simp only [List.getElem_map]
    rw [getElem!_of_lt (by simpa using h1), getElem!_of_lt (by simpa using h2)] at this
    exact this

@[step] theorem eq_lower_spec (a b : Slice U8) :
    eq_lower a b ⦃ r => r = decide (LowerEq a.val b.val) ⦄ := by
  unfold eq_lower; simp only []
  split
  · simp only [WP.spec_ok]
    have : ¬ LowerEq a.val b.val := fun h => by
      have := ((lowerEq_iff _ _).1 h).1; simp_all
    simp [this]
  · unfold eq_lower_loop
    apply loop.spec_decr_nat (measure := fun (j : Usize) => a.length - j.val)
      (inv := fun j => j.val ≤ a.length ∧ ∀ k < j.val, lowerN a.val[k]!.val = lowerN b.val[k]!.val)
    · rintro j ⟨hj, hk⟩
      unfold eq_lower_loop.body; simp only []
      step*
      · have : ¬ LowerEq a.val b.val := by
          intro h
          have h2 := ((lowerEq_iff _ _).1 h).2 j.val (by scalar_tac)
          rw [getElem!_of_lt (by scalar_tac), getElem!_of_lt (by scalar_tac)] at h2
          have : i3 = i5 := UScalar.eq_of_val_eq (by simp_all)
          simp_all
        simp [this]
      · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
        intro k hk'
        rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < j.val + 1 by scalar_tac) with h1 | h1
        · exact hk k h1
        · subst h1
          rw [getElem!_of_lt (by scalar_tac), getElem!_of_lt (by scalar_tac)]
          simp_all
      · have : LowerEq a.val b.val := (lowerEq_iff _ _).2 ⟨by scalar_tac, fun k hk' => hk k (by scalar_tac)⟩
        simp [this]
    · simp

@[step] theorem is_name_char_spec (c : U8) : is_name_char c ⦃ r => r = nameChar c ⦄ := by
  unfold is_name_char nameChar
  step*

@[step] theorem valid_username_spec (u : Slice U8) :
    valid_username u ⦃ r => r = decide (ValidUsername u.val) ⦄ := by
  unfold valid_username; simp only []
  split
  · simp only [WP.spec_ok]
    have : u.val.length = 0 := by scalar_tac
    simp [ValidUsername, List.length_eq_zero_iff.1 this]
  · unfold valid_username_loop
    apply WP.spec_mono (H5iAppLib.loop_search u.val (fun c => !nameChar c) id (fun _ _ => false) true _ ?step 0#usize (by simp))
    · intro r hr; simp only [id] at hr; rw [hr, H5iAppLib.searchFrom_const]
      have hne : u.val ≠ [] := by intro h; have : u.length = 0 := by simp [Slice.length, h]
                                  scalar_tac
      simp [ValidUsername, hne]
    case step =>
      intro j hj; unfold valid_username_loop.body; h5i_step

@[step] theorem header_is_ascii_spec (v : Slice U8) :
    header_is_ascii v ⦃ r => r = visibleAscii v.val ⦄ := by
  unfold header_is_ascii header_is_ascii_loop
  apply WP.spec_mono (H5iAppLib.loop_search v.val
    (fun (c : U8) => !(decide (c.val = 9) || (decide (32 ≤ c.val) && decide (c.val < 127)))) id
    (fun _ _ => false) true _ ?step 0#usize (by simp))
  · intro r hr; simp only [id] at hr; rw [hr, H5iAppLib.searchFrom_const]
    simp [visibleAscii]
    rw [Bool.eq_iff_iff]; simp only [decide_eq_true_eq, Bool.not_eq_true', List.all_eq_false]
    simp
    constructor <;> rintro ⟨x, hx, h⟩ <;> exact ⟨x, hx, by omega⟩
  case step =>
    intro j hj; unfold header_is_ascii_loop.body; h5i_step
    all_goals (refine ⟨by scalar_tac, ?_⟩; generalize (↑v : List U8)[↑j] = x at *; subst_vars; simp_all)

@[step] theorem first_space_spec (v : Slice U8) :
    first_space v ⦃ r => r.map (·.val) = v.val.findIdx? (fun c => decide (c.val = 32)) ⦄ := by
  unfold first_space first_space_loop
  apply WP.spec_mono (H5iAppLib.loop_search v.val (fun c => decide (c.val = 32)) (fun r => r.map (·.val))
    (fun i _ => some i) none _ ?step 0#usize (by simp))
  · intro r hr; rw [hr, H5iAppLib.searchFrom_findIdx]; simp
  case step =>
    intro j hj; unfold first_space_loop.body; h5i_step
    all_goals (refine ⟨by scalar_tac, ?_⟩; generalize (↑v : List U8)[↑j] = x at *; subst_vars; simp_all)

@[step] theorem copy_from_spec (v : Slice U8) (start : Usize) (h : start.val ≤ v.length) :
    copy_from v start ⦃ r => r.val = v.val.drop start.val ⦄ := by
  unfold copy_from copy_from_loop
  apply WP.spec_mono (H5iAppLib.loop_fold v.val (fun (o : alloc.vec.Vec U8) => o.val) (fun acc x => acc ++ [x])
    (fun o i => o.val.length ≤ i) _ ?step (alloc.vec.Vec.new U8) start h (by simp))
  · intro r hr; rw [hr, H5iAppLib.foldl_snoc]; simp
  case step =>
    intro o j hj hinv; unfold copy_from_loop.body; h5i_step

/-- The literal `Token` is at the start of `v`, with the first space right after it. -/
theorem token_prefix_iff (v : List U8) :
    (v.findIdx? (fun c => decide (c.val = 32)) = some 5 ∧ nats (v.take 5) = lit "Token") ↔
      nats (v.take 6) = lit "Token " := by
  have hl5 : lit "Token" = [84, 111, 107, 101, 110] := by decide
  have hl6 : lit "Token " = [84, 111, 107, 101, 110, 32] := by decide
  rw [hl5, hl6]
  match v with
  | a :: b :: c :: d :: e :: f :: rest =>
    simp only [List.take, nats, List.map, List.cons.injEq, and_true]
    constructor
    · rintro ⟨h1, ha, hb, hc, hd, he⟩
      simp [List.findIdx?_cons, ha, hb, hc, hd, he] at h1
      simp_all
    · rintro ⟨ha, hb, hc, hd, he, hf⟩
      simp [List.findIdx?_cons, ha, hb, hc, hd, he, hf]
  | [] => simp [nats]
  | [a] => simp [nats]
  | [a, b] => simp [nats]
  | [a, b, c] => simp [nats]
  | [a, b, c, d] => simp [nats]
  | [a, b, c, d, e] =>
    simp only [List.take, nats, List.map, List.cons.injEq, and_true]
    simp [List.findIdx?_cons]
    intro h1 ha hb hc hd
    simp [ha, hb, hc, hd] at h1

end atuin_kernel.Verified
