import Spec
import H5iAppLib
import Mathlib.Data.List.Pairwise
/-!
# Security / integrity properties of the SpoolEase inventory kernel

Classes (see STATUS.md): S = security/safety property, C = correspondence.
-/
open Aeneas Aeneas.Std Result spoolease_kernel spoolease_kernel.Spec
open H5iAppLib

set_option maxRecDepth 100000

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
places lies wholly inside the (new) file (given the previous slot, if any, was
itself in bounds — which the store invariant guarantees). -/
theorem place_capacity (file_len : U32) (prev : Option Slot) (len : U32)
    (hlen : 1 ≤ len.val ∧ len.val ≤ 4096) (hfile : file_len.val ≤ 16777216)
    (hprev : ∀ p, prev = some p → slotEnd p ≤ file_len.val)
    {slot off plan fl} (h : place file_len prev len = ok (.Ok (slot, off, plan, fl))) :
    fl.val ≤ 16777216 ∧ slotEnd slot ≤ fl.val := by
  obtain ⟨hlen1, hlen2⟩ := hlen
  have hmf : MAX_FILE.val = 16777216 := max_file_val
  unfold place at h
  cases prev with
  | none =>
    h5i_invert h <;> (try obtain ⟨rfl, rfl, rfl, rfl⟩ := h) <;>
      (simp only [slotEnd] at *; h5i_ok_facts; scalar_tac)
  | some p =>
    have hp := hprev p rfl
    h5i_invert h <;> (try obtain ⟨rfl, rfl, rfl, rfl⟩ := h) <;>
      (simp only [slotEnd] at *; h5i_ok_facts; scalar_tac)

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
  h5i_invert h <;> (try obtain ⟨rfl, rfl, rfl, rfl⟩ := h) <;>
    first
      | exact ⟨by scalar_tac, rfl, rfl, rfl⟩
      | (exfalso
         have hadd := add_ok_val (by assumption)
         rw [hinplace] at hadd
         omega)

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
    h5i_invert h <;> (try obtain ⟨rfl, rfl, rfl, rfl⟩ := h) <;>
      (left; rcases hq with hh | hh <;>
        (simp only [inSlot, slotEnd, no_region_off, no_region_len] at hh; scalar_tac))
  | some p =>
    h5i_invert h <;> (try obtain ⟨rfl, rfl, rfl, rfl⟩ := h) <;>
      (rcases hq with hh | hh <;>
        simp only [inSlot, slotEnd, no_region_off, no_region_len] at hh <;>
        first
          | (left; scalar_tac)
          | (right; exact ⟨p, rfl, by simp only [inSlot, slotEnd]; scalar_tac⟩))

/-! ## Panic freedom (C) -/

@[step] theorem place_total (file_len : U32) (prev : Option Slot) (len : U32)
    (hlen : len.val ≤ 4096) : place file_len prev len ⦃ _ => True ⦄ := by
  have hmf : MAX_FILE.val = 16777216 := max_file_val
  unfold place
  cases prev <;> step* <;> scalar_tac

@[step] theorem len_ok_spec (len : U32) :
    len_ok len ⦃ b => b = true → (1 ≤ len.val ∧ len.val ≤ 4096) ⦄ := by
  unfold len_ok
  have := max_rec_val
  split <;> step*

/-- (C) `transition` never panics / overflows, for any actor, store and
command (given the record count fits `usize`, which the file-size cap
guarantees physically). A panic on the device is a reset. -/
theorem transition_total (a : Device) (s : Store) (c : Command)
    (hcap : s.slots.val.length < Usize.max) : ∃ r, transition a s c = ok r := by
  have h : transition a s c ⦃ _ => True ⦄ := by
    unfold transition
    cases c <;> step* <;>
      (try obtain ⟨slot0, off, plan, fl⟩ := val) <;>
      step* <;>
      (first | scalar_tac | assumption | simp_all [alloc.vec.Vec.deref])
  obtain ⟨r, hr, -⟩ := (WP.spec_equiv_exists _ _).1 h
  exact ⟨r, hr⟩

/-! ## Fresh ids (S): `AddSpool` never reuses an existing spool id. -/

/-- `AddSpool` assigns `last_id + 1`. -/
theorem addspool_id (a : Device) (s : Store) (tag len : U32)
    (hcap : s.slots.val.length < Usize.max) (hmax : s.last_id.val < 4294967294)
    {ws id plan} (h : transition a s (.AddSpool tag len) = ok (.Ok (ws, Reply.Added id plan))) :
    id.val = s.last_id.val + 1 := by
  have hw : transition a s (.AddSpool tag len) ⦃ res =>
      ∀ ws id plan, res = .Ok (ws, Reply.Added id plan) → id.val = s.last_id.val + 1 ⦄ := by
    unfold transition
    step* <;> (try obtain ⟨slot0, off, plan0, fl⟩ := val) <;> step* <;>
      (first | scalar_tac | assumption | simp_all [alloc.vec.Vec.deref])
  exact post_of_ok hw h ws id plan rfl

/-- (S) The spool id `AddSpool` hands out is new: no record in the store
already uses it. Rules out the `fresh_id_reuse` mutant (reusing `last_id`
would let a new spool shadow an existing record's storage). Needs only that
existing ids are `≤ last_id` (part of `IdsOk`). -/
theorem fresh_id_is_new (a : Device) (s : Store) (tag len : U32)
    (hcap : s.slots.val.length < Usize.max) (hmax : s.last_id.val < 4294967294)
    (hids : ∀ sl ∈ s.slots.val, sl.id.val ≤ s.last_id.val)
    {ws id plan} (h : transition a s (.AddSpool tag len) = ok (.Ok (ws, Reply.Added id plan))) :
    ∀ sl ∈ s.slots.val, sl.id ≠ id := by
  have hid := addspool_id a s tag len hcap hmax h
  intro sl hsl heq
  have h2 := hids sl hsl
  have hv : sl.id.val = id.val := by rw [heq]
  omega

/-- (S) An unauthenticated caller (`admin = false`) can never mutate: every
write command is refused with `Forbidden`, before any state change. Rules out
dropping the `actor.admin` guard. -/
theorem unauth_refused (s : Store) (tag len id : U32) :
    transition ⟨false⟩ s (.AddSpool tag len) = ok (.Err .Forbidden) ∧
    transition ⟨false⟩ s (.EditSpool id tag len) = ok (.Err .Forbidden) ∧
    transition ⟨false⟩ s (.DeleteSpool id) = ok (.Err .Forbidden) := by
  refine ⟨?_, ?_, ?_⟩ <;> (unfold transition; simp)

end spoolease_kernel.Properties
