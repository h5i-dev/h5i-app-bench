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
def has2 (l : List U8) (a b : U8) : Prop := ∃ i, l[i]? = some a ∧ l[i + 1]? = some b

def has3 (l : List U8) (a b c : U8) : Prop := ∃ i, l[i]? = some a ∧ l[i + 1]? = some b ∧ l[i + 2]? = some c

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

/-- The byte `%xy` at positions `j, j+1` encodes, if both are hex digits. -/
def pairAt (l : List Nat) (j : Nat) : Option Nat :=
  match l[j]?, l[j + 1]? with
  | some x, some y => hexPair x y
  | _, _ => none

/-- Position `i` starts an encoded dot: `%2e`, `%25` + `2e`, or `%25` + `25` + `2e`
(each hex pair in either case). -/
def encAt (l : List Nat) (i : Nat) : Prop :=
  l[i]? = some 37 ∧ (pairAt l (i + 1) = some 46 ∨ (pairAt l (i + 1) = some 37 ∧
    (pairAt l (i + 3) = some 46 ∨ (pairAt l (i + 3) = some 37 ∧ pairAt l (i + 5) = some 46))))

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

end synctv_kernel.PathLemmas
