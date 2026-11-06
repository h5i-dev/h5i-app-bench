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

/-- Two consecutive bytes `a b` occur in `l`. -/
def has2 {α} (l : List α) (a b : α) : Prop := ∃ i, l[i]? = some a ∧ l[i + 1]? = some b

def has3 {α} (l : List α) (a b c : α) : Prop := ∃ i, l[i]? = some a ∧ l[i + 1]? = some b ∧ l[i + 2]? = some c

@[step] theorem contains2_spec (s : Slice U8) (a b : U8) (hs : s.length + 8 < Usize.max) :
    pathcheck.contains2 s a b ⦃ r => (r = true ↔ has2 s.val a b) ⦄ := by
  unfold pathcheck.contains2 pathcheck.contains2_loop
  apply loop.spec_decr_nat (measure := fun (j : Usize) => s.length - j.val)
    (inv := fun j => j.val ≤ s.length ∧ ∀ k < j.val, ¬ (s.val[k]? = some a ∧ s.val[k + 1]? = some b))
  · rintro i ⟨hi, hk⟩
    unfold pathcheck.contains2_loop.body
    step*
    · simp only [true_iff]
      refine ⟨i.val, ?_, ?_⟩
      · rw [List.getElem?_eq_getElem (by scalar_tac)]; simp_all
      · rw [List.getElem?_eq_getElem (by scalar_tac)]; simp_all
    · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
      intro k hk'
      rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < i.val + 1 by scalar_tac) with h1 | h1
      · exact hk k h1
      · subst h1
        rw [List.getElem?_eq_getElem (show i.val + 1 < s.val.length by scalar_tac)]
        intro ⟨_, h2⟩
        simp only [Option.some.injEq] at h2
        apply ‹¬i4 = b›
        rw [i4_post, ← h2]
        simp_all
    · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
      intro k hk'
      rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < i.val + 1 by scalar_tac) with h1 | h1
      · exact hk k h1
      · subst h1
        rw [List.getElem?_eq_getElem (show i.val < s.val.length by scalar_tac)]
        intro ⟨h2, _⟩
        simp only [Option.some.injEq] at h2
        apply ‹¬i3 = a›
        rw [i3_post, ← h2]
    · simp only [Bool.false_eq_true, false_iff]
      rintro ⟨k, h1, h2⟩
      have hk2 : k + 1 < s.val.length := by
        by_contra hc; rw [List.getElem?_eq_none (by omega)] at h2; simp at h2
      exact hk k (by scalar_tac) ⟨h1, h2⟩
  · simp

theorem idx_some {s : Slice U8} {k : Nat} (h : k < s.val.length) : s.val[k]? = some s.val[k] :=
  List.getElem?_eq_getElem h

@[step] theorem contains3_spec (s : Slice U8) (a b c : U8) (hs : s.length + 8 < Usize.max) :
    pathcheck.contains3 s a b c ⦃ r => (r = true ↔ has3 s.val a b c) ⦄ := by
  unfold pathcheck.contains3 pathcheck.contains3_loop
  apply loop.spec_decr_nat (measure := fun (j : Usize) => s.length - j.val)
    (inv := fun j => j.val ≤ s.length ∧
      ∀ k < j.val, ¬ (s.val[k]? = some a ∧ s.val[k + 1]? = some b ∧ s.val[k + 2]? = some c))
  · rintro i ⟨hi, hk⟩
    unfold pathcheck.contains3_loop.body
    step*
    · simp only [true_iff]
      refine ⟨i.val, ?_, ?_, ?_⟩
      · rw [idx_some (by scalar_tac)]; simp_all
      · rw [idx_some (by scalar_tac)]; simp_all
      · rw [idx_some (by scalar_tac)]; simp_all
    all_goals first
      | (refine ⟨by scalar_tac, ?_, by scalar_tac⟩
         intro k hk'
         rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < i.val + 1 by scalar_tac) with h1 | h1
         · exact hk k h1
         · subst h1
           rw [idx_some (show i.val < s.val.length by scalar_tac),
             idx_some (show i.val + 1 < s.val.length by scalar_tac),
             idx_some (show i.val + 2 < s.val.length by scalar_tac)]
           simp only [Option.some.injEq]
           rintro ⟨h2, h3, h4⟩
           first
             | (apply ‹¬i3 = a›; rw [i3_post, ← h2])
             | (apply ‹¬i5 = b›; rw [i5_post, ← h3]; simp_all)
             | (apply ‹¬i6 = c›; rw [i6_post, ← h4]; simp_all))
      | (simp only [Bool.false_eq_true, false_iff]
         rintro ⟨k, h1, h2, h3⟩
         have hk2 : k + 2 < s.val.length := by
           by_contra hc; rw [List.getElem?_eq_none (by omega)] at h3; simp at h3
         exact hk k (by scalar_tac) ⟨h1, h2, h3⟩)
  · simp

@[step] theorem contains1_spec (s : Slice U8) (a : U8) :
    pathcheck.contains1 s a ⦃ r => r = s.val.any (fun x => decide (x = a)) ⦄ := by
  unfold pathcheck.contains1 pathcheck.contains1_loop
  h5i_search_any s.val (fun x => decide (x = a))
  all_goals simp_all
  all_goals scalar_tac

theorem vals_get (p : Slice U8) {k : Nat} (h : k < p.val.length) : (vals p)[k]? = some p.val[k].val := by
  simp [vals, List.getElem?_map, idx_some h]

theorem vals_get_none (p : Slice U8) {k : Nat} (h : p.val.length ≤ k) : (vals p)[k]? = none := by
  simp [vals, List.getElem?_map, List.getElem?_eq_none h]

theorem pairAt_get (p : Slice U8) {j : Nat} (h : j + 1 < p.val.length) :
    pairAt (vals p) j = hexPair p.val[j].val p.val[j + 1].val := by
  simp [pairAt, vals_get p (show j < p.val.length by omega), vals_get p h]

theorem pairAt_none (p : Slice U8) {j : Nat} (h : p.val.length ≤ j + 1) : pairAt (vals p) j = none := by
  unfold pairAt
  rw [vals_get_none p h]
  split <;> simp_all

@[step] theorem encoded_at_spec (p : Slice U8) (i : Usize) (hi : i.val < p.length) (hs : p.length + 8 < Usize.max) :
    pathcheck.encoded_at p i ⦃ o => (o = none ↔ ¬ encAt (vals p) i.val) ⦄ := by
  unfold pathcheck.encoded_at
  step*
  all_goals
    simp only [encAt]
    simp (disch := scalar_tac) only [vals_get, pairAt_get, pairAt_none]
  all_goals try simp only [Nat.add_assoc, Nat.reduceAdd] at *
  all_goals simp_all
  all_goals (rw [← i1_post]; rfl)

@[step] theorem first_encoded_spec (p : Slice U8) (hs : p.length + 8 < Usize.max) :
    pathcheck.first_encoded p ⦃ o => (o = none ↔ ∀ i < p.length, ¬ encAt (vals p) i) ⦄ := by
  unfold pathcheck.first_encoded pathcheck.first_encoded_loop
  apply loop.spec_decr_nat (measure := fun (j : Usize) => p.length - j.val)
    (inv := fun j => j.val ≤ p.length ∧ ∀ k < j.val, ¬ encAt (vals p) k)
  · rintro i ⟨hi, hk⟩
    unfold pathcheck.first_encoded_loop.body
    simp only []
    split
    · rename_i hlt
      have hspec := encoded_at_spec p i (by scalar_tac) hs
      obtain ⟨o, ho, hiff⟩ := WP.spec_imp_exists hspec
      rw [ho]
      simp only [bind_ok]
      cases o with
      | none =>
        simp only []
        step*
        refine ⟨by scalar_tac, ?_, by scalar_tac⟩
        intro k hk'
        rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < i.val + 1 by scalar_tac) with h1 | h1
        · exact hk k h1
        · subst h1; exact hiff.1 rfl
      | some e =>
        simp only [WP.spec_ok, reduceCtorEq, false_iff, not_forall]
        exact ⟨i.val, by scalar_tac, by simpa using hiff⟩
    · simp only [WP.spec_ok, true_iff]
      intro k hk'
      exact hk k (by scalar_tac)
  · simp

/-- What an accepted path satisfies, in kernel terms. -/
theorem validate_ok (p : Slice U8) (hs : p.length + 8 < Usize.max)
    (h : pathcheck.validate_path_for_traversal p = ok (.Ok ())) :
    ¬ has2 p.val 46#u8 46#u8 ∧ 0#u8 ∉ p.val ∧ ¬ has3 p.val 37#u8 48#u8 48#u8 ∧
      ¬ has3 p.val 46#u8 47#u8 46#u8 ∧ ∀ i < p.length, ¬ encAt (vals p) i := by
  unfold pathcheck.validate_path_for_traversal at h
  h5i_invert h
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · intro h2; exact hc ((post_of_ok (contains2_spec p _ _ hs) hb).2 h2)
  · intro h0
    have := post_of_ok (contains1_spec p 0#u8) hb1
    simp_all
  · intro h3; exact hc_2 ((post_of_ok (contains3_spec p _ _ _ hs) hb2).2 h3)
  · intro h3; exact hc_3 ((post_of_ok (contains3_spec p _ _ _ hs) hb3).2 h3)
  · exact (post_of_ok (first_encoded_spec p hs) ho).1 rfl

theorem decode_cons_of (c : Nat) (rest : List Nat) (h : ∀ a b r, c = 37 → rest = a :: b :: r → False) :
    decodeOnce (c :: rest) = c :: decodeOnce rest := by
  rcases rest with _ | ⟨a, _ | ⟨b, r⟩⟩
  · by_cases hc : c = 37 <;> simp [decodeOnce, hc]
  · by_cases hc : c = 37
    · subst hc; simp [decodeOnce]
    · simp [decodeOnce, hc]
  · by_cases hc : c = 37
    · exact absurd (h a b r hc rfl) id
    · rw [decodeOnce.eq_def]; simp [hc]

theorem dd_cons (x : Nat) (t : List Nat) : [46, 46] <:+: x :: t ↔ (x = 46 ∧ t.head? = some 46) ∨ [46, 46] <:+: t := by
  rw [List.infix_cons_iff]
  constructor
  · rintro (h | h)
    · left
      obtain ⟨u, hu⟩ := h
      cases t with
      | nil => simp at hu
      | cons y ys => simp at hu; simp [hu.1, hu.2.1]
    · exact Or.inr h
  · rintro (⟨rfl, ht⟩ | h)
    · left
      cases t with
      | nil => simp at ht
      | cons y ys => simp at ht; subst ht; exact ⟨ys, rfl⟩
    · exact Or.inr h

theorem decode_no_dd (l : List Nat) (hdd : ¬ [46, 46] <:+: l)
    (henc : ∀ i, ¬ (l[i]? = some 37 ∧ pairAt l (i + 1) = some 46)) :
    ¬ [46, 46] <:+: decodeOnce l ∧ ((decodeOnce l).head? = some 46 → l.head? = some 46) := by
  induction l using decodeOnce.induct with
  | case1 a b rest v hv ih =>
    have hv46 : v ≠ 46 := by
      intro e; subst e; exact henc 0 ⟨rfl, by simp [pairAt, hv]⟩
    have ih' := ih (fun h => hdd ((h.trans (List.suffix_cons _ _).isInfix).trans
      ((List.suffix_cons _ _).isInfix.trans (List.suffix_cons _ _).isInfix)))
      (fun i hi => henc (i + 3) (by simpa [pairAt] using hi))
    simp only [decodeOnce, hv]
    refine ⟨?_, by simp [hv46]⟩
    rw [dd_cons]
    rintro (⟨h1, _⟩ | h2)
    · exact hv46 h1
    · exact ih'.1 h2
  | case2 a b rest hnone ih =>
    have ih' := ih (fun h => hdd (h.trans (List.suffix_cons _ _).isInfix))
      (fun i hi => henc (i + 1) (by simpa [pairAt] using hi))
    simp only [decodeOnce, hnone]
    refine ⟨?_, by simp⟩
    rw [dd_cons]
    rintro (⟨h1, _⟩ | h2)
    · simp at h1
    · exact ih'.1 h2
  | case3 c rest hnot ih =>
    have ih' := ih (fun h => hdd (h.trans (List.suffix_cons _ _).isInfix))
      (fun i hi => henc (i + 1) (by simpa [pairAt] using hi))
    rw [decode_cons_of c rest hnot]
    refine ⟨?_, by simp⟩
    rw [dd_cons]
    rintro (⟨h1, h2⟩ | h2)
    · subst h1
      have := ih'.2 h2
      apply hdd
      rw [dd_cons]; exact Or.inl ⟨rfl, this⟩
    · exact ih'.1 h2
  | case4 => simp [decodeOnce]


theorem has2_iff {α} (l : List α) (a b : α) : has2 l a b ↔ [a, b] <:+: l := by
  unfold has2
  induction l with
  | nil => simp
  | cons x xs ih =>
    rw [List.infix_cons_iff]
    constructor
    · rintro ⟨i, h1, h2⟩
      cases i with
      | zero =>
        left; simp at h1; subst h1
        cases xs with
        | nil => simp at h2
        | cons y ys => simp at h2; subst h2; exact ⟨ys, rfl⟩
      | succ k => right; exact ih.1 ⟨k, by simpa using h1, by simpa using h2⟩
    · rintro (⟨u, hu⟩ | h)
      · refine ⟨0, ?_, ?_⟩ <;> (rw [← hu]; simp)
      · obtain ⟨k, h1, h2⟩ := ih.2 h
        exact ⟨k + 1, by simpa using h1, by simpa using h2⟩

theorem has3_iff {α} (l : List α) (a b c : α) : has3 l a b c ↔ [a, b, c] <:+: l := by
  unfold has3
  induction l with
  | nil => simp
  | cons x xs ih =>
    rw [List.infix_cons_iff]
    constructor
    · rintro ⟨i, h1, h2, h3⟩
      cases i with
      | zero =>
        left; simp at h1; subst h1
        match xs, h2, h3 with
        | y :: z :: zs, h2, h3 => simp at h2 h3; subst h2 h3; exact ⟨zs, rfl⟩
      | succ k => right; exact ih.1 ⟨k, by simpa using h1, by simpa using h2, by simpa using h3⟩
    · rintro (⟨u, hu⟩ | h)
      · refine ⟨0, ?_, ?_, ?_⟩ <;> (rw [← hu]; simp)
      · obtain ⟨k, h1, h2, h3⟩ := ih.2 h
        exact ⟨k + 1, by simpa using h1, by simpa using h2, by simpa using h3⟩

theorem u8_get_iff (l : List U8) (i : Nat) (n : U8) :
    (l.map (·.val))[i]? = some n.val ↔ l[i]? = some n := by
  rw [List.getElem?_map]
  cases h : l[i]? with
  | none => simp
  | some x =>
    simp only [Option.map_some, Option.some.injEq]
    exact ⟨fun e => congrArg some (UScalar.eq_of_val_eq e) |>.trans rfl |> fun _ => by
      rw [UScalar.eq_of_val_eq e], fun e => by cases e; rfl⟩

theorem has2_vals (p : Slice U8) (a b : U8) : has2 p.val a b ↔ has2 (vals p) a.val b.val := by
  unfold has2; simp only [vals, u8_get_iff]

theorem has3_vals (p : Slice U8) (a b c : U8) : has3 p.val a b c ↔ has3 (vals p) a.val b.val c.val := by
  unfold has3; simp only [vals, u8_get_iff]

end synctv_kernel.PathLemmas
