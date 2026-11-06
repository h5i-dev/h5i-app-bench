import Spec
import H5iAppLib
import Mathlib.Data.List.Pairwise
/-!
# Security / integrity properties of the SpoolEase inventory kernel

Classes (see STATUS.md): S = security/safety property, C = correspondence.
-/
open Aeneas Aeneas.Std Result spoolease_kernel spoolease_kernel.Spec
open H5iAppLib

namespace spoolease_kernel.Properties

/-! ## Loop-correctness specs (C): each `Vec`-building loop computes a plain
list transform. Registered as `@[step]` so the `transition` proofs discharge
them automatically. -/

@[step] theorem lookup_spec (slots : Slice Slot) (id : U32) :
    lookup slots id ⦃ r => r = slots.val.find? (fun s => decide (s.id = id)) ⦄ := by
  unfold lookup lookup_loop
  h5i_search_find slots.val (fun s => decide (s.id = id))

@[step] theorem replace_slot_spec (slots : Slice Slot) (id : U32) (ns : Slot) :
    replace_slot slots id ns ⦃ r => r.val = slots.val.map (replaceOne id ns) ⦄ := by
  unfold replace_slot replace_slot_loop
  apply WP.spec_mono (loop_fold slots.val (fun v : alloc.vec.Vec Slot => v.val)
    (fun acc x => acc ++ [replaceOne id ns x]) (fun v i => v.val.length ≤ i) _ ?step
    (alloc.vec.Vec.new Slot) 0#usize (by simp) (by simp))
  · intro r hr
    simpa only [UScalar.ofNatCore_val_eq, List.drop_zero, vec_new_val, foldl_map, List.nil_append] using hr
  · intro s i hi hI; unfold replace_slot_loop.body; h5i_step [replaceOne]

@[step] theorem remove_id_spec (slots : Slice Slot) (id : U32) :
    remove_id slots id ⦃ r => r.val = slots.val.filter (fun s => s.id != id) ⦄ := by
  unfold remove_id remove_id_loop
  apply WP.spec_mono (loop_fold slots.val (fun v : alloc.vec.Vec Slot => v.val)
    (fun acc x => if x.id != id then acc ++ [x] else acc) (fun v i => v.val.length ≤ i) _ ?step
    (alloc.vec.Vec.new Slot) 0#usize (by simp) (by simp))
  · intro r hr
    simpa only [UScalar.ofNatCore_val_eq, List.drop_zero, vec_new_val, foldl_filter, List.nil_append] using hr
  · intro s i hi hI; unfold remove_id_loop.body; h5i_step

@[step] theorem claim_tag_spec (slots : Slice Slot) (keeper tag : U32) :
    claim_tag slots keeper tag ⦃ r => r.val = slots.val.map (claimOne keeper tag) ⦄ := by
  unfold claim_tag claim_tag_loop
  apply WP.spec_mono (loop_fold slots.val (fun v : alloc.vec.Vec Slot => v.val)
    (fun acc x => acc ++ [claimOne keeper tag x]) (fun v i => v.val.length ≤ i) _ ?step
    (alloc.vec.Vec.new Slot) 0#usize (by simp) (by simp))
  · intro r hr
    simpa only [UScalar.ofNatCore_val_eq, List.drop_zero, vec_new_val, foldl_map, List.nil_append] using hr
  · intro s i hi hI; unfold claim_tag_loop.body; h5i_step [claimOne]

/-- The append loop copies every slot; the final push adds `slot`. Needs the
record count to stay below `usize::MAX` (it is bounded by the file size; see
`inv_count`). -/
@[step] theorem append_slot_spec (slots : Slice Slot) (slot : Slot)
    (hcap : slots.val.length < Usize.max) :
    append_slot slots slot ⦃ r => r.val = slots.val ++ [slot] ⦄ := by
  unfold append_slot
  have hloop : append_slot_loop slots (alloc.vec.Vec.new Slot) 0#usize ⦃ r => r.val = slots.val ⦄ := by
    unfold append_slot_loop
    apply WP.spec_mono (loop_fold slots.val (fun v : alloc.vec.Vec Slot => v.val)
      (fun acc x => acc ++ [x]) (fun v i => v.val.length ≤ i) _ ?step (alloc.vec.Vec.new Slot) 0#usize (by simp) (by simp))
    · intro r hr
      simpa only [UScalar.ofNatCore_val_eq, List.drop_zero, vec_new_val, foldl_snoc, List.nil_append] using hr
    · intro s i hi hI; unfold append_slot_loop.body; h5i_step
  step* <;> simp_all

/-! ## `place` properties (S): the allocator decision, independent of the
record index. Proven directly from the extracted equation with `h5i_invert`. -/

/-- (S) `place` never lets the file grow past the cap, and the record it
places lies wholly inside the (new) file. -/
theorem place_capacity (file_len : U32) (prev : Option Slot) (len : U32)
    (hlen : 1 ≤ len.val ∧ len.val ≤ 4096) (hfile : file_len.val ≤ 16777216)
    {slot off plan fl} (h : place file_len prev len = ok (.Ok (slot, off, plan, fl))) :
    fl.val ≤ 16777216 ∧ slotEnd slot ≤ fl.val := by
  obtain ⟨hlen1, hlen2⟩ := hlen
  unfold place at h
  cases prev <;> h5i_invert h <;> simp_all [slotEnd, max_file_val] <;> scalar_tac

/-- (S) An in-place overwrite (no new end-of-file) happens only when the new
record fits its old slot, and then it writes exactly that old slot's range
(never past it, and nothing voided). -/
theorem place_inplace_fits (file_len : U32) (p : Slot) (len : U32)
    (hlen : 1 ≤ len.val ∧ len.val ≤ 4096) (hfile : file_len.val ≤ 16777216)
    {slot off plan fl} (h : place file_len (some p) len = ok (.Ok (slot, off, plan, fl)))
    (hinplace : fl = file_len) :
    len.val ≤ p.length.val ∧ plan.data.off = p.offset ∧ plan.data.len = p.length ∧
      plan.void = NO_REGION := by
  obtain ⟨hlen1, hlen2⟩ := hlen
  unfold place at h
  h5i_invert h <;> simp_all [NO_REGION, max_file_val] <;> scalar_tac

/-- (S) Every byte `place` writes (its `void` and `data` regions) lies either
in fresh space at/after the old end of file or in the record's *own* previous
slot — never in another record's bytes. -/
theorem place_local (file_len : U32) (prev : Option Slot) (len : U32)
    (hlen : 1 ≤ len.val ∧ len.val ≤ 4096) (hfile : file_len.val ≤ 16777216)
    {slot off plan fl} (h : place file_len prev len = ok (.Ok (slot, off, plan, fl))) :
    ∀ q : Nat, (inSlot (Slot.mk 0#u32 0#u32 plan.data.off plan.data.len) q ∨
                inSlot (Slot.mk 0#u32 0#u32 plan.void.off plan.void.len) q) →
      (file_len.val ≤ q) ∨ (∃ w, prev = some w ∧ inSlot w q) := by
  obtain ⟨hlen1, hlen2⟩ := hlen
  intro q hq
  unfold place at h
  cases prev with
  | none =>
    h5i_invert h <;> simp_all [NO_REGION, inSlot, slotEnd]
    rcases hq with hd | hv
    · left; scalar_tac
    · exfalso; scalar_tac
  | some p =>
    h5i_invert h <;> simp_all [NO_REGION, inSlot, slotEnd]
    · -- in place: data == p's old range, void empty
      rcases hq with hd | hv
      · right; exact ⟨p, rfl, by simp only [inSlot, slotEnd]; scalar_tac⟩
      · exfalso; scalar_tac
    · -- append: void == p's old range, data fresh at file_len
      rcases hq with hd | hv
      · left; scalar_tac
      · right; exact ⟨p, rfl, by simp only [inSlot, slotEnd]; scalar_tac⟩

end spoolease_kernel.Properties
