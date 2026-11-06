import PicoBitKernel
import Spec
import H5iAppLib.Basic
/-!
# Properties of pico-bit's extracted kernel

Security (S) and correspondence (C) theorems about `PicoBitKernel.lean`.
See `STATUS.md` for the S/C/F classification and the mutants each S kills.
-/
open Aeneas Aeneas.Std Result pico_bit_kernel
open PicoBit

namespace pico_bit_kernel.Properties

/-! ## is_separator -/

/-- `is_separator b` decides `Spec.IsSep b`. -/
theorem is_separator_eq (b : Std.U8) :
    is_separator b = ok (decide (Spec.IsSep b)) := by
  unfold is_separator Spec.IsSep SLASH BACKSLASH NUL
  split
  · rename_i h; simp [h]
  · split
    · rename_i h1 h2; simp [h2]
    · rename_i h1 h2
      by_cases h : b = 0#u8 <;> simp_all

@[step]
theorem is_separator_spec (b : Std.U8) :
    is_separator b ⦃ r => r = decide (Spec.IsSep b) ⦄ := by
  rw [is_separator_eq]; simp

/-! ## valid_name_prefix scanning loop -/

/-- The scanning loop: if it accepts (`true`) then no byte in `buf[i..len]` is a
separator. The invariant threads "every earlier byte is clean". -/
theorem valid_name_prefix_loop_sound (buf : Slice Std.U8) (len i : Std.Usize)
    (hlen : len.val ≤ buf.val.length) (hile : i.val ≤ len.val) :
    valid_name_prefix_loop buf len i ⦃ r =>
      r = true → ∀ k, i.val ≤ k → k < len.val → ¬ Spec.IsSep buf.val[k]! ⦄ := by
  unfold valid_name_prefix_loop
  apply loop.spec_decr_nat
    (measure := fun (j : Std.Usize) => len.val - j.val)
    (inv := fun (j : Std.Usize) =>
      j.val ≤ len.val ∧
      ∀ k, i.val ≤ k → k < j.val → ¬ Spec.IsSep buf.val[k]!)
    (post := fun r =>
      r = true → ∀ k, i.val ≤ k → k < len.val → ¬ Spec.IsSep buf.val[k]!)
  · intro j hj
    obtain ⟨hjle, hclean⟩ := hj
    unfold valid_name_prefix_loop.body
    step*
    -- only the "clean byte → cont (j+1)" obligation remains
    refine ⟨by scalar_tac, ?_, by scalar_tac⟩
    intro k hik hklt
    by_cases hkj : k < j.val
    · exact hclean k hik hkj
    · have hkeq : k = j.val := by omega
      subst hkeq
      have hjb : j.val < buf.val.length := by scalar_tac
      rw [getElem!_pos buf.val j.val hjb, ← i1_post]
      have hbfalse : b = false := by rcases b <;> simp_all
      rw [hbfalse] at b_post
      simpa using b_post.symm
  · exact ⟨hile, by intro k _ hk; omega⟩

/-! ## is_dot_name -/

/-- `is_dot_name` is total when `len ≤ buf.len`, and a `false` result means the
first `len` bytes are neither `.` nor `..`. -/
theorem is_dot_name_spec (buf : Slice Std.U8) (len : Std.Usize)
    (hlen : len.val ≤ buf.val.length) :
    is_dot_name buf len ⦃ r =>
      (r = false →
        ¬ (len.val = 1 ∧ buf.val[0]! = 46#u8) ∧
        ¬ (len.val = 2 ∧ buf.val[0]! = 46#u8 ∧ buf.val[1]! = 46#u8)) ⦄ := by
  sorry

end pico_bit_kernel.Properties
