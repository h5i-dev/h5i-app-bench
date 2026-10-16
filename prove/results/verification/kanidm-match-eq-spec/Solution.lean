import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit

namespace kanidm_kernel.Solution

@[step] theorem contains_uuid_spec (s : Slice U128) (u : U128) :
    bset.contains_uuid s u ⦃ b => b = decide (u ∈ s.val) ⦄ := by
  unfold bset.contains_uuid bset.contains_uuid_loop
  h5i_search_any s.val (fun x => decide (x = u))
  rename_i hsearch
  rw [← hsearch, Bool.eq_iff_iff]
  simp

@[step] theorem contains_u32_spec (s : Slice U32) (u : U32) :
    valueset.contains_u32 s u ⦃ b => b = decide (u ∈ s.val) ⦄ := by
  unfold valueset.contains_u32 valueset.contains_u32_loop
  h5i_search_any s.val (fun x => decide (x = u))
  rename_i hsearch
  rw [← hsearch, Bool.eq_iff_iff]
  simp

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    bset.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold bset.bytes_eq
  dsimp only
  split
  · simp only [WP.spec_ok]
    have hne : a.val ≠ b.val := by
      intro heq
      rename_i h
      simp [Slice.len, heq] at h
    simp [hne]
  · rename_i hlen
    have hl : a.val.length = b.val.length := by scalar_tac
    unfold bset.bytes_eq_loop
    apply WP.spec_mono (loop_search (a.val.zip b.val)
      (fun p => !decide (p.1 = p.2)) id (fun _ _ => false) true _ ?_ 0#usize (by simp))
    · intro r hr
      have h := search_all _ _ _ hr
      simp only [id_eq, Bool.not_not] at h
      exact h.trans (zip_all_eq a.val b.val hl)
    · intro i hi
      unfold bset.bytes_eq_loop.body
      h5i_step [List.length_zip, hl, List.getElem_zip]

@[step] theorem contains_bytes_spec (s : Slice (alloc.vec.Vec U8)) (x : alloc.vec.Vec U8) :
    bset.contains s (alloc.vec.Vec.deref x) ⦃ b => b = decide (x ∈ s.val) ⦄ := by
  unfold bset.contains bset.contains_loop
  apply WP.spec_mono (loop_search s.val (fun y => decide (y = x)) id
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    have h := search_any _ _ _ hr
    exact h.trans (by rw [Bool.eq_iff_iff]; simp)
  · intro i hi
    unfold bset.contains_loop.body
    h5i_step [alloc.vec.Vec.eq_iff, vec_deref_val]

instance valueContainsDecidable (vs : ValueSet) (v : PartialValue) : Decidable (ValueContains vs v) := by
  cases vs <;> cases v <;> unfold ValueContains <;> infer_instance

@[step] theorem vs_contains_spec (vs : ValueSet) (v : PartialValue) :
    valueset.vs_contains vs v ⦃ b => b = decide (ValueContains vs v) ⦄ := by
  cases vs <;> cases v <;> simp only [valueset.vs_contains, ValueContains]
  all_goals step* <;> simp_all [vec_deref_val]

theorem nats_eq_iff (a b : List U8) : nats a = nats b ↔ a = b := by
  exact List.map_inj_right (fun x y h => (u8_eq_iff x y).mpr h)

@[step] theorem get_ava_set_spec (e : Entry) (a : Slice U8) :
    entry_impl.get_ava_set e a ⦃ o => o = ava e (nats a.val) ⦄ := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  apply WP.spec_mono (loop_search e.attrs.val
    (fun x => decide (x.attr.val = a.val)) id (fun _ x => some x.vs) none _ ?_ 0#usize (by simp))
  · intro r hr
    have hp : (fun x : Ava => decide (x.attr.val = a.val)) =
        (fun x => nats x.attr.val == nats a.val) := by
      funext x
      rw [Bool.eq_iff_iff]
      simp [nats_eq_iff]
    rw [id_eq] at hr
    rw [hr, searchFrom_find]
    simp only [UScalar.ofNatCore_val_eq, List.drop_zero, ava, hp]
  · intro i hi
    unfold entry_impl.get_ava_set_loop.body
    h5i_step [vec_deref_val]

theorem match_eq_spec (e : Entry) (a : alloc.vec.Vec U8) (v : PartialValue) :
    entry_impl.entry_match_no_index_inner e (.Eq a v) = ok true ↔
      ∃ vs, ava e (nats a.val) = some vs ∧ ValueContains vs v := by
  simp only [entry_impl.entry_match_no_index_inner, entry_impl.attribute_equality]
  rw [eq_ok_of_spec (get_ava_set_spec e (alloc.vec.Vec.deref a))]
  simp only [vec_deref_val]
  cases hlookup : ava e (nats a.val) with
  | none => simp
  | some vs =>
    simp only [bind_ok]
    rw [eq_ok_of_spec (vs_contains_spec vs v)]
    simp

end kanidm_kernel.Solution
