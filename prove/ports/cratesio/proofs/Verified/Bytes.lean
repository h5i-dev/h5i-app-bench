import Spec
/-!
# Byte-string helpers as list functions
-/
open Aeneas Aeneas.Std Result cratesio_kernel cratesio_kernel.Spec
open H5iAppLib
open Aeneas.Std.WP

namespace cratesio_kernel.Verified.Bytes
set_option maxHeartbeats 1000000

@[simp] theorem deref_val {α : Type} (v : alloc.vec.Vec α) : v.deref.val = v.val := by
  simp [alloc.vec.Vec.deref, alloc.vec.Vec.val]

theorem eq_loop_spec (a b : Slice U8) (i : Usize)
    (hlen : a.length = b.length) (hi : i.val ≤ a.length) :
    bytes.eq_loop a b i ⦃ r => r = decide (a.val.drop i.val = b.val.drop i.val) ⦄ := by
  induction h : a.length - i.val using Nat.strong_induction_on generalizing i with
  | h n ih =>
    rw [bytes.eq_loop, loop]
    unfold bytes.eq_loop.body
    dsimp only
    simp only [bind_ite]
    split
    · have ha : i.val < a.val.length := by scalar_tac
      have hb : i.val < b.val.length := by scalar_tac
      step*
      split
      · step*
        rw [List.drop_eq_getElem_cons ha, List.drop_eq_getElem_cons hb]
        simp only [List.cons.injEq, Bool.false_eq, decide_eq_false_iff_not]
        intro he; have := he.1; scalar_tac
      · step*
        apply WP.spec_mono (ih (a.length - x.val) (by scalar_tac) x (by scalar_tac) rfl)
        intro r hr
        rw [List.drop_eq_getElem_cons ha, List.drop_eq_getElem_cons hb]
        have he : a.val[i.val] = b.val[i.val] := by scalar_tac
        simpa only [List.cons.injEq, he, true_and, x_post] using hr
    · step*
      have ha : a.val.length ≤ i.val := by scalar_tac
      have hb : b.val.length ≤ i.val := by scalar_tac
      simp [List.drop_eq_nil_of_le ha, List.drop_eq_nil_of_le hb]

@[step] theorem eq_spec (a b : Slice U8) : bytes.eq a b ⦃ r => decide (a.val = b.val) = r ⦄ := by
  unfold bytes.eq
  dsimp only
  split
  · have hn : a.val ≠ b.val := by intro he; have := congrArg List.length he; scalar_tac
    simp [hn]
  · apply WP.spec_mono (eq_loop_spec a b 0#usize (by scalar_tac) (by simp))
    intro r hr; simp only [hr]; simp

end cratesio_kernel.Verified.Bytes
