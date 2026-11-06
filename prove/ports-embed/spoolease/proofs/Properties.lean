import Spec
import H5iAppLib.Basic
import H5iAppLib.Loops
import H5iAppLib.Runs
import Mathlib.Data.List.Pairwise
/-!
# Security / integrity properties of the SpoolEase inventory kernel

Classes (see STATUS.md): S = security/safety property, C = correspondence.
-/
open Aeneas Aeneas.Std Result spoolease_kernel spoolease_kernel.Spec
open H5iAppLib

namespace spoolease_kernel.Properties

attribute [local simp] max_file_val max_rec_val max_id_val

/-! ## Loop-correctness specs (C): each `Vec`-building loop computes a plain
list transform. Registered as `@[step]` so the `transition` proofs discharge
them automatically. -/

@[step] theorem lookup_spec (slots : Slice Slot) (id : U32) :
    lookup slots id ⦃ r => r = slots.val.find? (fun s => decide (s.id = id)) ⦄ := by
  unfold lookup lookup_loop
  h5i_search_find slots.val (fun s => decide (s.id = id))

@[step] theorem append_slot_spec (slots : Slice Slot) (slot : Slot) :
    append_slot slots slot ⦃ r => r.val = slots.val ++ [slot] ⦄ := by
  unfold append_slot
  have hloop : append_slot_loop slots (alloc.vec.Vec.new Slot) 0#usize ⦃ r => r.val = slots.val ⦄ := by
    unfold append_slot_loop
    apply WP.spec_mono (loop_fold slots.val (fun v : alloc.vec.Vec Slot => v.val)
      (fun acc x => acc ++ [x]) (fun _ _ => True) _ ?step (alloc.vec.Vec.new Slot) 0#usize (by simp) trivial)
    · intro r hr
      simpa only [UScalar.ofNatCore_val_eq, List.drop_zero, vec_new_val, foldl_snoc, List.nil_append] using hr
    · intro s i hi hI; unfold append_slot_loop.body; h5i_step
  step*

@[step] theorem replace_slot_spec (slots : Slice Slot) (id : U32) (ns : Slot) :
    replace_slot slots id ns ⦃ r => r.val = slots.val.map (replaceOne id ns) ⦄ := by
  unfold replace_slot replace_slot_loop
  apply WP.spec_mono (loop_fold slots.val (fun v : alloc.vec.Vec Slot => v.val)
    (fun acc x => acc ++ [replaceOne id ns x]) (fun _ _ => True) _ ?step
    (alloc.vec.Vec.new Slot) 0#usize (by simp) trivial)
  · intro r hr
    simpa only [UScalar.ofNatCore_val_eq, List.drop_zero, vec_new_val, foldl_map, List.nil_append] using hr
  · intro s i hi hI
    unfold replace_slot_loop.body
    step* <;> simp_all [FoldStep, replaceOne] <;> scalar_tac

@[step] theorem remove_id_spec (slots : Slice Slot) (id : U32) :
    remove_id slots id ⦃ r => r.val = slots.val.filter (fun s => s.id != id) ⦄ := by
  unfold remove_id remove_id_loop
  apply WP.spec_mono (loop_fold slots.val (fun v : alloc.vec.Vec Slot => v.val)
    (fun acc x => if x.id != id then acc ++ [x] else acc) (fun _ _ => True) _ ?step
    (alloc.vec.Vec.new Slot) 0#usize (by simp) trivial)
  · intro r hr
    simpa only [UScalar.ofNatCore_val_eq, List.drop_zero, vec_new_val, foldl_filter, List.nil_append] using hr
  · intro s i hi hI
    unfold remove_id_loop.body
    step* <;> simp_all [FoldStep] <;> scalar_tac

@[step] theorem claim_tag_spec (slots : Slice Slot) (keeper tag : U32) :
    claim_tag slots keeper tag ⦃ r => r.val = slots.val.map (claimOne keeper tag) ⦄ := by
  unfold claim_tag claim_tag_loop
  apply WP.spec_mono (loop_fold slots.val (fun v : alloc.vec.Vec Slot => v.val)
    (fun acc x => acc ++ [claimOne keeper tag x]) (fun _ _ => True) _ ?step
    (alloc.vec.Vec.new Slot) 0#usize (by simp) trivial)
  · intro r hr
    simpa only [UScalar.ofNatCore_val_eq, List.drop_zero, vec_new_val, foldl_map, List.nil_append] using hr
  · intro s i hi hI
    unfold claim_tag_loop.body
    step* <;> simp_all [FoldStep, claimOne] <;> scalar_tac

/-! ## `place`: the allocator decision, independent of the record index. -/

/-- Full structural spec of `place` under the preconditions that always hold
at the call sites (`len` range-checked, file within its cap). -/
theorem place_spec (file_len : U32) (prev : Option Slot) (len : U32)
    (hlen : 1 ≤ len.val ∧ len.val ≤ 4096) (hfile : file_len.val ≤ 16777216) :
    place file_len prev len ⦃ res => ∀ slot off plan fl, res = .Ok (slot, off, plan, fl) →
      fl.val ≤ 16777216 ∧ off = slot.offset ∧ slot.length = len ∧ slotEnd slot ≤ fl.val ∧
      (prev = none → slot.offset = file_len ∧ fl.val = file_len.val + len.val ∧
        plan.void = NO_REGION ∧ plan.data.off = file_len ∧ plan.data.len = len) ∧
      (∀ p, prev = some p → slot.id = p.id ∧ slot.tag = p.tag ∧
        ((slot.offset = p.offset ∧ fl = file_len ∧ len.val ≤ p.length.val ∧
            plan.void = NO_REGION ∧ plan.data.off = p.offset ∧ plan.data.len = p.length) ∨
         (slot.offset = file_len ∧ fl.val = file_len.val + len.val ∧ p.length.val < len.val ∧
            plan.void.off = p.offset ∧ plan.void.len = p.length ∧
            plan.data.off = file_len ∧ plan.data.len = len))) ⦄ := by
  obtain ⟨hlen1, hlen2⟩ := hlen
  unfold place
  cases prev with
  | none =>
    step* <;>
    · intro slot off plan fl heq
      simp only [NO_REGION, slotEnd] at *
      simp_all
      scalar_tac
  | some p =>
    split
    · -- in place
      intro slot off plan fl heq
      simp only [NO_REGION, slotEnd] at *
      simp_all
      scalar_tac
    · step* <;>
      · intro slot off plan fl heq
        simp only [NO_REGION, slotEnd] at *
        simp_all
        scalar_tac

/-- (S) `place` never lets the file grow past the cap, and the record it
places lies wholly inside the (new) file. -/
theorem place_capacity (file_len : U32) (prev : Option Slot) (len : U32)
    (hlen : 1 ≤ len.val ∧ len.val ≤ 4096) (hfile : file_len.val ≤ 16777216)
    {slot off plan fl} (h : place file_len prev len = ok (.Ok (slot, off, plan, fl))) :
    fl.val ≤ 16777216 ∧ slotEnd slot ≤ fl.val := by
  have hs := (WP.spec_equiv_exists _ _).1 (place_spec file_len prev len hlen hfile)
  obtain ⟨r, hr, hp⟩ := hs
  rw [h, Result.ok.injEq] at hr; subst hr
  obtain ⟨h1, _, _, h4, _⟩ := hp slot off plan fl rfl
  exact ⟨h1, h4⟩

/-- (S) Every byte `place` writes (its `void` and `data` regions) lies either
in the record's *own* previous slot or in fresh space at/after the old end of
file — never in another record's bytes. -/
theorem place_local (file_len : U32) (prev : Option Slot) (len : U32)
    (hlen : 1 ≤ len.val ∧ len.val ≤ 4096) (hfile : file_len.val ≤ 16777216)
    {slot off plan fl} (h : place file_len prev len = ok (.Ok (slot, off, plan, fl))) :
    ∀ p : Nat, (inSlot (Slot.mk 0#u32 0#u32 plan.data.off plan.data.len) p ∨
                inSlot (Slot.mk 0#u32 0#u32 plan.void.off plan.void.len) p) →
      (file_len.val ≤ p) ∨ (∃ q, prev = some q ∧ inSlot q p) := by
  have hs := (WP.spec_equiv_exists _ _).1 (place_spec file_len prev len hlen hfile)
  obtain ⟨r, hr, hp⟩ := hs
  rw [h, Result.ok.injEq] at hr; subst hr
  obtain ⟨_, _, _, _, hnone, hsome⟩ := hp slot off plan fl rfl
  intro q hq
  cases prev with
  | none =>
    obtain ⟨_, _, hv, hdo, hdl⟩ := hnone rfl
    left
    simp only [inSlot, slotEnd, NO_REGION, hv, hdo, hdl] at hq
    rcases hq with ⟨h1, h2⟩ | ⟨h1, h2⟩ <;> omega
  | some pp =>
    obtain ⟨_, _, hcase⟩ := hsome pp rfl
    rcases hcase with ⟨_, _, _, hv, hdo, hdl⟩ | ⟨_, _, _, hvo, hvl, hdo, hdl⟩
    · -- in place: data == pp's old range, void empty
      simp only [inSlot, slotEnd, NO_REGION, hv, hdo, hdl] at hq
      rcases hq with ⟨h1, h2⟩ | ⟨h1, h2⟩
      · right; exact ⟨pp, rfl, by simp only [inSlot, slotEnd]; omega⟩
      · exfalso; omega
    · -- void == pp's old range, data fresh at file_len
      simp only [inSlot, slotEnd, hvo, hvl, hdo, hdl] at hq
      rcases hq with ⟨h1, h2⟩ | ⟨h1, h2⟩
      · left; omega
      · right; exact ⟨pp, rfl, by simp only [inSlot, slotEnd]; omega⟩

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
  have hs := (WP.spec_equiv_exists _ _).1 (place_spec file_len (some p) len ⟨hlen1, hlen2⟩ hfile)
  obtain ⟨r, hr, hp⟩ := hs
  rw [h, Result.ok.injEq] at hr; subst hr
  obtain ⟨_, _, _, _, _, hsome⟩ := hp slot off plan fl rfl
  obtain ⟨_, _, hcase⟩ := hsome p rfl
  rcases hcase with ⟨_, _, hfit, hv, hdo, hdl⟩ | ⟨_, hflapp, _, _⟩
  · exact ⟨hfit, hdo, hdl, hv⟩
  · -- append: fl.val = file_len.val + len.val with len ≥ 1, so fl ≠ file_len.
    exfalso
    have heq : fl.val = file_len.val := by rw [hinplace]
    omega

end spoolease_kernel.Properties
