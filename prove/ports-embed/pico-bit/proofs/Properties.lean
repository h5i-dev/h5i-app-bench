import PicoBitKernel
import Spec
import H5iAppLib.Basic
/-!
# Properties of pico-bit's extracted kernel

Security (S) and correspondence (C) theorems about `PicoBitKernel.lean`.
See `STATUS.md` for the S/C/F classification and the mutants each S kills.
-/
open Aeneas Aeneas.Std Result pico_bit_kernel

namespace pico_bit_kernel.Properties

/-- `is_separator b` decides `Spec.IsSep b`. -/
theorem is_separator_eq (b : Std.U8) :
    is_separator b = ok (decide (Spec.IsSep b)) := by
  unfold is_separator Spec.IsSep SLASH BACKSLASH NUL
  split
  · rename_i h; simp [h]
  · split
    · rename_i h1 h2; simp [h2]
    · rename_i h1 h2; simp_all
      by_cases h : b = 0#u8 <;> simp [h]

/-- `is_separator` is total. -/
@[step]
theorem is_separator_total (b : Std.U8) : is_separator b ⦃ _ => True ⦄ := by
  rw [is_separator_eq]; simp

/-! ## valid_name_prefix -/

/-- The scanning loop: if it accepts (`true`) then no byte in `buf[i..len]` is a
separator. The invariant threads "every earlier byte is clean". -/
theorem valid_name_prefix_loop_sound (buf : Slice Std.U8) (len i : Std.Usize)
    (hlen : len.val ≤ buf.val.length) :
    valid_name_prefix_loop buf len i ⦃ r =>
      r = true → ∀ k (_ : k < buf.val.length), i.val ≤ k → k < len.val →
        ¬ Spec.IsSep buf.val[k] ⦄ := by
  unfold valid_name_prefix_loop
  apply loop.spec_decr_nat
    (measure := fun (j : Std.Usize) => len.val - j.val)
    (inv := fun (j : Std.Usize) =>
      j.val ≤ len.val ∧
      ∀ k (_ : k < buf.val.length), i.val ≤ k → k < j.val → ¬ Spec.IsSep buf.val[k])
    (post := fun r =>
      r = true → ∀ k (_ : k < buf.val.length), i.val ≤ k → k < len.val →
        ¬ Spec.IsSep buf.val[k])
  · intro j hj
    obtain ⟨hjle, hclean⟩ := hj
    unfold valid_name_prefix_loop.body
    step
    · -- j < len: read byte, test separator
      rename_i hjlt
      have hjb : j.val < buf.val.length := by omega
      step with Slice.index_usize_spec buf j (by scalar_tac)
      rw [is_separator_eq]
      split
      · -- separator found: returns `done false`; post trivial
        simp
      · -- clean byte: continue to j+1
        rename_i hbyte _
        refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
        intro k hk hik hklt
        by_cases hkj : k < j.val
        · exact hclean k hk hik hkj
        · have : k = j.val := by omega
          subst this
          simpa [Spec.IsSep] using hbyte
    · -- j ≥ len: loop ends with `done true`; inv gives cleanliness up to len
      rename_i hjge
      intro _ k hk hik hklt
      exact hclean k hk hik (by omega)
  · exact ⟨by scalar_tac, by intro k _ _ hk; omega⟩

/-- `valid_name_prefix` is total. -/
@[step]
theorem valid_name_prefix_total (buf : Slice Std.U8) (len : Std.Usize) :
    valid_name_prefix buf len ⦃ _ => True ⦄ := by
  unfold valid_name_prefix is_dot_name
  step*

end pico_bit_kernel.Properties
