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
@[step]
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
@[step]
theorem is_dot_name_spec (buf : Slice Std.U8) (len : Std.Usize)
    (hlen : len.val ≤ buf.val.length) :
    is_dot_name buf len ⦃ r =>
      r = false →
        ¬ (len.val = 1 ∧ buf.val[0]! = 46#u8) ∧
        ¬ (len.val = 2 ∧ buf.val[0]! = 46#u8 ∧ buf.val[1]! = 46#u8) ⦄ := by
  unfold is_dot_name
  step* <;>
    intro hr <;>
    refine ⟨?_, ?_⟩ <;>
    intro hcon <;>
    (try obtain ⟨he, hb⟩ := hcon) <;>
    (try obtain ⟨he, hb0, hb1⟩ := hcon) <;>
    first
      | (exfalso; scalar_tac)
      | (try have e0 := getElem!_pos buf.val 0 (show 0 < buf.val.length by scalar_tac)
         try have e1 := getElem!_pos buf.val 1 (show 1 < buf.val.length by scalar_tac)
         simp_all [DOT])
      | simp_all [DOT]

/-! ## valid_name: the filename-acceptance gate -/

/-- If `valid_name_prefix buf len` accepts, the first `len` bytes of `buf`
satisfy the confinement policy `Spec.SafeNameAt`. This is the core soundness
lemma; totality follows because it is a WP over the whole function. -/
@[step]
theorem valid_name_prefix_facts (buf : Slice Std.U8) (len : Std.Usize) :
    valid_name_prefix buf len ⦃ r => r = true → Spec.SafeNameAt buf.val len.val ⦄ := by
  unfold valid_name_prefix
  simp only [NAME_MAX]
  step*
  have hbf : b = false := by rcases b <;> simp_all
  exact ⟨by scalar_tac, by scalar_tac, by scalar_tac,
    (b_post hbf).1, (b_post hbf).2, fun k hk => r_post r_post1 k (Nat.zero_le k) hk⟩

/-- `valid_name` is total (never panics), for any slice. (C) -/
theorem valid_name_total (nm : Slice Std.U8) :
    ∃ r, valid_name nm = ok r := by
  unfold valid_name
  obtain ⟨r, hr, -⟩ := (WP.spec_equiv_exists _ _).1 (valid_name_prefix_facts nm (Slice.len nm))
  exact ⟨r, hr⟩

/-- **Security (S): no path traversal.** Every filename the gate accepts is a
non-empty, ≤64-byte component that is neither `.` nor `..` and contains no path
separator or NUL. Appending it after `/armory/` therefore names a direct child
of the armory directory: the device can never be steered to a file outside
`/armory`. Falsified by `drop_slash_check` (a `/`/`\` could pass) and
`drop_dotdot_check` (`..` could pass). -/
theorem valid_name_no_traversal (nm : Slice Std.U8) (h : valid_name nm = ok true) :
    Spec.SafeNameAt nm.val nm.val.length := by
  unfold valid_name at h
  obtain ⟨r, hr, hpost⟩ := (WP.spec_equiv_exists _ _).1 (valid_name_prefix_facts nm (Slice.len nm))
  rw [hr] at h
  simp only [Result.ok.injEq] at h
  subst h
  simpa [Slice.len_val] using hpost rfl

/-! ## percent_decode and decode_filename -/

/-- `hex_digit` is total. -/
@[step]
theorem hex_digit_total (b : Std.U8) : hex_digit b ⦃ _ => True ⦄ := by
  unfold hex_digit
  step* <;> simp

/-- The decode loop is total: index lookahead is always guarded. -/
@[step]
theorem percent_decode_loop_total (raw out : Slice Std.U8) (i n : Std.Usize) :
    percent_decode_loop raw out i n ⦃ _ => True ⦄ := by
  unfold percent_decode_loop
  apply loop.spec_decr_nat
    (measure := fun (s : (Slice Std.U8) × Std.Usize × Std.Usize) => raw.val.length - s.2.1.val)
    (inv := fun _ => True)
    (post := fun _ => True)
  · intro x _
    obtain ⟨out1, i1, n1⟩ := x
    unfold percent_decode_loop.body
    step* <;> first | trivial | scalar_tac
  · trivial

/-- `percent_decode` is total. -/
@[step]
theorem percent_decode_wp (raw out : Slice Std.U8) :
    percent_decode raw out ⦃ _ => True ⦄ := by
  unfold percent_decode RAW_MAX NAME_MAX; step*

/-- `percent_decode` is total (never panics), for any input and buffer. (C) -/
theorem percent_decode_total (raw out : Slice Std.U8) :
    ∃ r, percent_decode raw out = ok r := by
  obtain ⟨r, hr, -⟩ := (WP.spec_equiv_exists _ _).1 (percent_decode_wp raw out)
  exact ⟨r, hr⟩

/-- `decode_filename` returns a confined decoded name whenever it accepts. -/
theorem decode_filename_wp (raw out : Slice Std.U8) :
    decode_filename raw out ⦃ r =>
      ∀ n out', r = (some n, out') → Spec.SafeNameAt out'.val n.val ⦄ := by
  unfold decode_filename
  step*

/-- `decode_filename` is total (never panics). (C) -/
theorem decode_filename_total (raw out : Slice Std.U8) :
    ∃ r, decode_filename raw out = ok r := by
  obtain ⟨r, hr, -⟩ := (WP.spec_equiv_exists _ _).1 (decode_filename_wp raw out)
  exact ⟨r, hr⟩

/-- **Security (S): decode-then-validate confinement.** Even after
percent-decoding, any filename `decode_filename` accepts satisfies the
confinement policy on the decoded bytes. This is what makes `%2e%2e` (`..`) and
`%2f` (`/`) harmless: they are decoded first and then rejected. Falsified by
`validate_before_decode` (validating the raw, still-encoded bytes would accept a
decoded `..`). -/
theorem decode_filename_confined (raw out out' : Slice Std.U8) (n : Std.Usize)
    (h : decode_filename raw out = ok (some n, out')) :
    Spec.SafeNameAt out'.val n.val := by
  obtain ⟨r, hr, hpost⟩ := (WP.spec_equiv_exists _ _).1 (decode_filename_wp raw out)
  rw [hr] at h
  simp only [Result.ok.injEq] at h
  exact hpost n out' h

/-! ## classify -/

/-- `starts_with` prefix loop: if it accepts, `bytes` and `prefix` agree on
every index in `[i, prefix.len)`. -/
@[step]
theorem starts_with_loop_sound (bytes «prefix» : Slice Std.U8) (i : Std.Usize)
    (hb : «prefix».val.length ≤ bytes.val.length) (hile : i.val ≤ «prefix».val.length) :
    starts_with_loop bytes «prefix» i ⦃ r =>
      r = true → ∀ k, i.val ≤ k → k < «prefix».val.length →
        bytes.val[k]! = «prefix».val[k]! ⦄ := by
  unfold starts_with_loop
  apply loop.spec_decr_nat
    (measure := fun (j : Std.Usize) => «prefix».val.length - j.val)
    (inv := fun (j : Std.Usize) =>
      j.val ≤ «prefix».val.length ∧
      ∀ k, i.val ≤ k → k < j.val → bytes.val[k]! = «prefix».val[k]!)
    (post := fun r =>
      r = true → ∀ k, i.val ≤ k → k < «prefix».val.length →
        bytes.val[k]! = «prefix».val[k]!)
  · intro j hj
    obtain ⟨hjle, hagree⟩ := hj
    unfold starts_with_loop.body
    step*
    refine ⟨by scalar_tac, ?_, by scalar_tac⟩
    intro k hik hklt
    by_cases hkj : k < j.val
    · exact hagree k hik hkj
    · have hkeq : k = j.val := by omega
      subst hkeq
      have hjbb : j.val < bytes.val.length := by scalar_tac
      have hjbp : j.val < «prefix».val.length := by scalar_tac
      rw [getElem!_pos bytes.val j.val hjbb, getElem!_pos «prefix».val j.val hjbp]
      scalar_tac
  · exact ⟨hile, by intro k _ hk; omega⟩

/-- `starts_with` is total, and when it accepts, `bytes` matches `prefix` on
every index of `prefix`. -/
@[step]
theorem starts_with_spec (bytes «prefix» : Slice Std.U8) :
    starts_with bytes «prefix» ⦃ r =>
      r = true → ∀ k, k < «prefix».val.length → bytes.val[k]! = «prefix».val[k]! ⦄ := by
  unfold starts_with
  step*

/-- `classify` is total (never panics), for any input. (C) -/
theorem classify_total (bytes : Slice Std.U8) :
    ∃ r, classify bytes = ok r := by
  have h : classify bytes ⦃ _ => True ⦄ := by unfold classify; step*
  obtain ⟨r, hr, -⟩ := (WP.spec_equiv_exists _ _).1 h
  exact ⟨r, hr⟩

end pico_bit_kernel.Properties
