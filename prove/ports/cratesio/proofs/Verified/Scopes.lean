import Verified.Bytes
/-!
# Endpoint and crate scopes (`models/token/scopes.rs`)
-/
open Aeneas Aeneas.Std Result cratesio_kernel cratesio_kernel.Spec
open H5iAppLib
open Aeneas.Std.WP
open cratesio_kernel.Verified.Bytes

namespace cratesio_kernel.Verified.Scopes
set_option maxHeartbeats 1000000

theorem starts_with_loop_spec (s p : Slice U8) (i : Usize)
    (hlen : p.length ≤ s.length) (hi : i.val ≤ p.length) :
    bytes.starts_with_loop s p i ⦃ r => r = decide ((s.val.take p.length).drop i.val = p.val.drop i.val) ⦄ := by
  induction h : p.length - i.val using Nat.strong_induction_on generalizing i with
  | h n ih =>
    rw [bytes.starts_with_loop, loop]
    unfold bytes.starts_with_loop.body
    dsimp only
    simp only [bind_ite]
    have hl : (s.val.take p.length).length = p.val.length := by simp; scalar_tac
    split
    · have hs : i.val < (s.val.take p.length).length := by scalar_tac
      have hp : i.val < p.val.length := by scalar_tac
      step*
      split
      · step*
        rw [List.drop_eq_getElem_cons hs, List.drop_eq_getElem_cons hp]
        simp only [List.cons.injEq, Bool.false_eq, decide_eq_false_iff_not, List.getElem_take]
        intro he; have := he.1; scalar_tac
      · step*
        apply WP.spec_mono (ih (p.length - x.val) (by scalar_tac) x (by scalar_tac) rfl)
        intro r hr
        rw [List.drop_eq_getElem_cons hs, List.drop_eq_getElem_cons hp]
        have he : (s.val.take p.length)[i.val] = p.val[i.val] := by simp only [List.getElem_take]; scalar_tac
        simpa only [List.cons.injEq, he, true_and, x_post] using hr
    · step*
      have ha : (s.val.take p.length).length ≤ i.val := by scalar_tac
      have hb : p.val.length ≤ i.val := by scalar_tac
      simp [List.drop_eq_nil_of_le ha, List.drop_eq_nil_of_le hb]

@[step] theorem starts_with_spec (s p : Slice U8) :
    bytes.starts_with s p ⦃ r => decide (p.val <+: s.val) = r ⦄ := by
  unfold bytes.starts_with
  dsimp only
  split
  · have hn : ¬ p.val <+: s.val := by intro he; have := he.length_le; scalar_tac
    simp [hn]
  · apply WP.spec_mono (starts_with_loop_spec s p 0#usize (by scalar_tac) (by simp))
    intro r hr
    rw [hr, Bool.eq_iff_iff]
    simp only [decide_eq_true_eq, show ((0#usize : Usize) : Nat) = 0 from rfl, List.drop_zero, Slice.length,
      List.prefix_iff_eq_take]
    exact ⟨fun h => h.symm, fun h => h.symm⟩

@[step] theorem sub_spec (s : Slice U8) (f t : Usize) (hf : f.val ≤ t.val) (ht : t.val ≤ s.length) :
    bytes.sub s f t ⦃ v => v.val = (s.val.take t.val).drop f.val ⦄ := by
  unfold bytes.sub bytes.sub_loop
  have hl : (s.val.take t.val).length = t.val := by simp; scalar_tac
  apply WP.spec_mono (loop_fold (s.val.take t.val) (fun (a : alloc.vec.Vec U8) => a.val) (fun acc x => acc ++ [x])
    (fun a i => a.val.length + f.val = i) _ ?_ (alloc.vec.Vec.new U8) f (by scalar_tac) (by simp [vec_new_val]))
  · intro r hr; rw [hr, foldl_snoc]; simp [vec_new_val]
  · intro a i hi hinv
    unfold bytes.sub_loop.body
    dsimp only
    split
    · step*
      simp only [FoldStep]
      refine ⟨by scalar_tac, ?_, by scalar_tac, by simp_all; scalar_tac⟩
      simp_all [List.getElem_take]
    · simp only [WP.spec_ok, FoldStep, and_true]; scalar_tac

@[step] theorem is_star_spec (p : Slice U8) : scopes.is_star p ⦃ b => decide (p.val = [42#u8]) = b ⦄ := by
  unfold scopes.is_star
  dsimp only
  split
  · step*
    rcases hp : p.val with _ | ⟨x, _ | ⟨y, rest⟩⟩
    · have : p.val.length = 1 := by scalar_tac
      simp [hp] at this
    · simp_all
    · have : p.val.length = 1 := by scalar_tac
      simp [hp] at this
  · have : p.val ≠ [42#u8] := by intro h; have := congrArg List.length h; simp at this; scalar_tac
    simp [this]

theorem ends_star_iff (l : List U8) : (∃ pre, l = pre ++ [42#u8]) ↔ (l ≠ [] ∧ l.getLast? = some 42#u8) := by
  constructor
  · rintro ⟨pre, rfl⟩; simp
  · rintro ⟨hne, hl⟩
    refine ⟨l.dropLast, ?_⟩
    rw [List.getLast?_eq_some_getLast hne, Option.some.injEq] at hl
    conv_lhs => rw [← List.dropLast_append_getLast hne]
    rw [hl]

@[step] theorem ends_with_star_spec (p : Slice U8) :
    scopes.ends_with_star p ⦃ b => decide (p.val.getLast? = some 42#u8) = b ⦄ := by
  unfold scopes.ends_with_star
  dsimp only
  split
  · step*
    rw [List.getLast?_eq_getElem?]
    have hi : p.val.length - 1 < p.val.length := by scalar_tac
    rw [List.getElem?_eq_getElem hi]
    simp_all
  · have : p.val = [] := by
      have : p.val.length = 0 := by scalar_tac
      exact List.eq_nil_of_length_eq_zero this
    simp [this]

/-- `CrateScope::matches` as a Boolean over lists. -/
def coversB (p n : List U8) : Bool :=
  if p.getLast? = some 42#u8 then decide (p.dropLast <+: n) else decide (p = n)

theorem coversB_iff (p n : List U8) : coversB p n = true ↔ Spec.Covers p n := by
  unfold coversB Spec.Covers
  split
  · rename_i h
    have hne : p ≠ [] := by intro h'; simp [h'] at h
    have hp : p = p.dropLast ++ [42#u8] := by
      conv_lhs => rw [← List.dropLast_append_getLast hne]
      rw [List.getLast?_eq_some_getLast hne, Option.some.injEq] at h
      rw [h]
    simp only [decide_eq_true_eq]
    constructor
    · intro hpre; exact .inl ⟨_, hp, hpre⟩
    · rintro (⟨pre, hpre, hpn⟩ | rfl)
      · rw [hpre, List.dropLast_concat]; exact hpn
      · rw [hp, List.dropLast_concat]; exact List.prefix_append _ _
  · rename_i h
    simp only [decide_eq_true_eq]
    constructor
    · intro e; exact .inr e
    · rintro (⟨pre, hpre, -⟩ | e)
      · exact absurd (by rw [hpre]; simp) h
      · exact e

instance (p n : List U8) : Decidable (Spec.Covers p n) := decidable_of_iff _ (coversB_iff p n)

theorem eq_of_spec' {α} {m : Result α} {v : α} (h : m ⦃ x => v = x ⦄) : m = ok v := by
  obtain ⟨x, hx⟩ := ok_of h
  rw [hx, post_of_ok h hx]

@[step] theorem scope_matches_spec (p n : Slice U8) :
    scopes.scope_matches p n ⦃ b => coversB p.val n.val = b ⦄ := by
  unfold scopes.scope_matches
  rw [eq_of_spec' (is_star_spec p)]
  by_cases hs : p.val = [42#u8]
  · simp [hs, coversB]
  · simp only [hs, decide_false, Bool.false_eq_true, if_false, bind_tc_ok]
    rw [eq_of_spec' (ends_with_star_spec p)]
    by_cases he : p.val.getLast? = some 42#u8
    · have hne : p.val ≠ [] := by intro h; simp [h] at he
      have hl : 1 ≤ p.val.length := by
        rcases hp : p.val with _ | ⟨x, xs⟩
        · exact absurd hp hne
        · simp
      simp only [he, decide_true, if_true, bind_tc_ok]
      step*
      simp only [coversB, he, if_true]
      rw [← b_post, deref_val, prefix_post, List.drop_zero, List.dropLast_eq_take]
      have : i1.val = p.val.length - 1 := by simp [i1_post, Slice.len]
      rw [this]
    · simp only [he, decide_false, Bool.false_eq_true, if_false]
      step*
      simp_all [coversB, eq_comm]

end cratesio_kernel.Verified.Scopes
