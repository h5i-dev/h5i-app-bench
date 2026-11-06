import Verified.Derived
import Verified.Store
import Verified.Delete
/-!
# Extensions (`cache.rs`) and `Content-Disposition` (`download.rs`)
-/
open Aeneas Aeneas.Std Result wastebin_kernel wastebin_kernel.Spec
open H5iAppLib
open Aeneas.Std.WP

namespace wastebin_kernel.Verified.Ids

instance (b : Nat) : Decidable (ExtByte b) := by unfold ExtByte; infer_instance
instance (b : Nat) : Decidable (HeaderToken b) := by unfold HeaderToken; infer_instance
instance (b : Nat) : Decidable (UrlSafe b) := by unfold UrlSafe; infer_instance

@[step] theorem is_ascii_alphanumeric_spec (b : U8) :
    ext.is_ascii_alphanumeric b ⦃ r => r = decide ((48 ≤ b.val ∧ b.val ≤ 57) ∨ (65 ≤ b.val ∧ b.val ≤ 90) ∨
      (97 ≤ b.val ∧ b.val ≤ 122)) ⦄ := by
  unfold ext.is_ascii_alphanumeric
  split_ifs <;> simp only [WP.spec_ok] <;> rw [Bool.eq_iff_iff] <;> simp <;> scalar_tac

@[step] theorem extension_byte_spec (b : U8) : ext.extension_byte b ⦃ r => r = decide (ExtByte b.val) ⦄ := by
  unfold ext.extension_byte
  step*
  all_goals (rw [Bool.eq_iff_iff]; simp only [ExtByte, decide_eq_true_eq] at *; scalar_tac)

/-- `valid_extension`: at most 32 bytes, each an ASCII alphanumeric or one of
`.`, `_`, `-`. -/
@[step] theorem valid_extension_spec (e : Slice U8) :
    ext.valid_extension e ⦃ r => r = decide (e.val.length ≤ 32 ∧ ∀ b ∈ e.val, ExtByte b.val) ⦄ := by
  unfold ext.valid_extension ext.valid_extension_loop
  simp only [ext.MAX_EXTENSION_LEN]
  split
  · simp only [WP.spec_ok]; have : ¬ e.val.length ≤ 32 := by scalar_tac
    simp [this]
  · apply WP.spec_mono (loop_search e.val (fun b => !decide (ExtByte b.val)) (fun r : Bool => r)
      (fun _ _ => false) true _ ?_ 0#usize (by simp))
    · intro r hr
      have hl : e.val.length ≤ 32 := by scalar_tac
      rw [search_all _ _ _ hr, Bool.eq_iff_iff]
      simp [hl, List.all_eq_true]
    · intro j hj; unfold ext.valid_extension_loop.body; h5i_step

/-! ## `Content-Disposition` (byte classes) -/

@[step] theorem unreserved_spec (b : U8) : disposition.unreserved b ⦃ r => r = decide (
    (48 ≤ b.val ∧ b.val ≤ 57) ∨ (65 ≤ b.val ∧ b.val ≤ 90) ∨ (97 ≤ b.val ∧ b.val ≤ 122) ∨
      b.val = 46 ∨ b.val = 45 ∨ b.val = 95 ∨ b.val = 126 ∨ b.val = 43) ⦄ := by
  unfold disposition.unreserved
  step*
  all_goals (rw [Bool.eq_iff_iff]; simp only [decide_eq_true_eq] at *; scalar_tac)

theorem extByte_urlSafe {b : Nat} (h : ExtByte b) : UrlSafe b := by
  unfold ExtByte at h; unfold UrlSafe; omega

/-- Every extension a parsed key carries passed `valid_extension`. -/
theorem parse_key_ext (s : Slice U8) (k : ids.Key) (h : ids.parse_key s = ok (.Ok k))
    (t : alloc.vec.Vec U8) (ht : k.ext = some t) : t.val.length ≤ 32 ∧ ∀ b ∈ t.val, ExtByte b.val := by
  unfold ids.parse_key at h
  h5i_invert h
  · simp at ht
  · simp only [Option.some.injEq] at ht
    subst ht hc
    have := post_of_ok (valid_extension_spec tail.deref) hb
    simpa [Delete.deref_val] using this

end wastebin_kernel.Verified.Ids
