import Verified.Ids
import Verified.Insert
/-!
# `Content-Disposition` (`make_content_disposition`)
-/
open Aeneas Aeneas.Std Result wastebin_kernel wastebin_kernel.Spec
open H5iAppLib
open Aeneas.Std.WP
open wastebin_kernel.Verified.Ids wastebin_kernel.Verified.Insert

namespace wastebin_kernel.Verified.Disposition

theorem arr_index_mem {α : Type} {n : Usize} {a : Array α n} {i : Usize} {x : α}
    (h : Array.index_usize a i = ok x) : x ∈ a.val := by
  unfold Array.index_usize at h
  split at h
  · simp at h
  · rename_i y hy
    have := Result.ok.inj h
    subst this
    rw [Array.getElem?_Usize_eq] at hy
    exact List.mem_of_getElem? hy

theorem hex_token : ∀ x ∈ disposition.HEX.val, HeaderToken x.val := by
  simp [disposition.HEX, Array.make, HeaderToken]



/-- The prefix loop copies `PREFIX`. -/
theorem prefix_loop_ok (v : alloc.vec.Vec U8) (h : disposition.content_disposition_loop0 (alloc.vec.Vec.new U8) 0#usize = ok v) :
    v.val = disposition.PREFIX.val := by
  unfold disposition.content_disposition_loop0 at h
  have hl : disposition.PREFIX.val.length = 29 := by simp [disposition.PREFIX, Array.make]
  refine loop_ok (fun x => disposition.content_disposition_loop0.body x.1 x.2)
    (fun x => x.1.val = disposition.PREFIX.val.take x.2.val ∧ x.2.val ≤ 29)
    (fun v => v.val = disposition.PREFIX.val) (fun x => 29 - x.2.val) ?_ _ v (by simp) h
  rintro ⟨a, i⟩ res ⟨ha, hi⟩ hb
  unfold disposition.content_disposition_loop0.body at hb
  simp only at ha hi hb ⊢
  h5i_invert hb
  · h5i_ok_facts
    refine ⟨⟨?_, by scalar_tac⟩, by scalar_tac⟩
    rw [push_val ‹_›, ha]
    have hx := ‹Array.index_usize disposition.PREFIX i = ok _›
    unfold Array.index_usize at hx
    split at hx
    · simp at hx
    · rename_i y hy
      have := Result.ok.inj hx; subst this
      rw [Array.getElem?_Usize_eq] at hy
      have hlt : i.val < disposition.PREFIX.val.length := by scalar_tac
      rw [show i2.val = i.val + 1 by scalar_tac, List.take_add_one, hy]
      simp
  · have : i.val = 29 := by scalar_tac
    simp only
    rw [ha, this]
    exact List.take_of_length_le (by omega)

/-- The header so far: the prefix, then header-token bytes only. -/
def Safe (l : List U8) : Prop :=
  l.take 29 = disposition.PREFIX.val ∧ 29 ≤ l.length ∧ ∀ b ∈ l.drop 29, HeaderToken b.val

theorem safe_push {l : List U8} {x : U8} (h : Safe l) (hx : HeaderToken x.val) : Safe (l ++ [x]) := by
  obtain ⟨h1, h2, h3⟩ := h
  refine ⟨?_, by simp; omega, fun b hb => ?_⟩
  · rw [List.take_append_of_le_length h2]; exact h1
  · rw [List.drop_append_of_le_length h2] at hb
    rcases List.mem_append.1 hb with hb | hb
    · exact h3 b hb
    · simp at hb; subst hb; exact hx

theorem filename_loop_ok (f : Slice U8) (v0 v : alloc.vec.Vec U8) (h0 : Safe v0.val)
    (h : disposition.content_disposition_loop1 f v0 0#usize = ok v) : Safe v.val := by
  unfold disposition.content_disposition_loop1 at h
  refine loop_ok (fun x => disposition.content_disposition_loop1.body f x.1 x.2)
    (fun x => Safe x.1.val) (fun v => Safe v.val) (fun x => f.val.length - x.2.val) ?_ _ v h0 h
  rintro ⟨a, j⟩ res ha hb
  unfold disposition.content_disposition_loop1.body at hb
  simp only at ha hb ⊢
  h5i_invert hb
  · h5i_ok_facts
    refine ⟨?_, by scalar_tac⟩
    simp only
    have hu := post_of_ok (unreserved_spec _) hb1
    by_cases hb1t : b1 = true
    · -- an unreserved byte, as itself
      simp only [hb1t, if_true] at hv1
      rw [push_val hv1]; apply safe_push ha
      rw [hb1t] at hu; have hu' := of_decide_eq_true hu.symm; unfold HeaderToken; omega
    · -- `%` and two hex digits
      simp only [hb1t, Bool.false_eq_true, if_false] at hv1
      h5i_invert hv1
      rw [push_val hv1, push_val hv3, push_val hv2]
      refine safe_push (safe_push (safe_push ha (by unfold HeaderToken; simp)) ?_) ?_
      · exact hex_token _ (arr_index_mem hi3)
      · exact hex_token _ (arr_index_mem hi6)
  · exact ha

theorem prefix_printable : ∀ b ∈ disposition.PREFIX.val, 32 ≤ b.val ∧ b.val < 127 := by
  simp [disposition.PREFIX, Array.make]

theorem content_disposition_safe (f : Slice U8) (v : alloc.vec.Vec U8)
    (h : disposition.content_disposition f = ok v) :
    v.val.take 29 = disposition.PREFIX.val ∧ (∀ b ∈ v.val.drop 29, HeaderToken b.val) ∧
      ∀ b ∈ v.val, 32 ≤ b.val ∧ b.val < 127 := by
  unfold disposition.content_disposition at h
  h5i_invert h
  have hp := prefix_loop_ok v_1 hv_1
  have hl : disposition.PREFIX.val.length = 29 := by simp [disposition.PREFIX, Array.make]
  have hs : Safe v.val := by
    refine filename_loop_ok f v_1 v ⟨?_, ?_, ?_⟩ h
    · rw [hp]; exact List.take_of_length_le (by omega)
    · rw [hp, hl]
    · intro b hb; rw [hp, List.drop_of_length_le (by omega)] at hb; simp at hb
  obtain ⟨h1, _, h3⟩ := hs
  refine ⟨h1, h3, fun b hb => ?_⟩
  rw [← List.take_append_drop 29 v.val] at hb
  rcases List.mem_append.1 hb with hb | hb
  · rw [h1] at hb; exact prefix_printable b hb
  · have := h3 b hb; unfold HeaderToken at this; omega

end wastebin_kernel.Verified.Disposition
