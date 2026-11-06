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
    split
    · step*
      simp only [FoldStep]
      refine ⟨by scalar_tac, ?_, by scalar_tac, by simp_all; scalar_tac⟩
      simp_all [List.getElem_take]
    · simp only [WP.spec_ok, FoldStep, and_true]; scalar_tac

@[step] theorem is_star_spec (p : Slice U8) : scopes.is_star p ⦃ b => decide (p.val = [42#u8]) = b ⦄ := by
  unfold scopes.is_star
  split
  · step*
    rcases hp : p.val with _ | ⟨x, _ | ⟨y, rest⟩⟩
    · simp_all
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
    rw [List.getLast?_eq_getLast hne, Option.some.injEq] at hl
    conv_lhs => rw [← List.dropLast_append_getLast hne]
    rw [hl]

@[step] theorem ends_with_star_spec (p : Slice U8) :
    scopes.ends_with_star p ⦃ b => decide (∃ pre, p.val = pre ++ [42#u8]) = b ⦄ := by
  unfold scopes.ends_with_star
  split
  · step*
    have hne : p.val ≠ [] := by intro h; simp [h] at *; scalar_tac
    rw [Bool.eq_iff_iff, decide_eq_true_eq, ends_star_iff, List.getLast?_eq_getElem?]
    simp only [hne, ne_eq, not_false_eq_true, true_and]
    have hi : p.val.length - 1 < p.val.length := by scalar_tac
    rw [List.getElem?_eq_getElem hi]
    simp_all
  · have : ¬ ∃ pre, p.val = pre ++ [42#u8] := by
      rintro ⟨pre, h⟩; have := congrArg List.length h; simp at this; scalar_tac
    simp [this]

end cratesio_kernel.Verified.Scopes
