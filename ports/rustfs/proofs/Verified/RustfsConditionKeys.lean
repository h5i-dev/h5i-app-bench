import Verified.RustfsOperatorLookup
import SpecConditionKeys
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete (bytes_eq_ok deref_val)
open rustfs_kernel.Verified.RustfsValids (any_loop)
namespace rustfs_kernel.Verified.RustfsConditionKeys
set_option maxHeartbeats 2000000
theorem named_ok {T : Type} (funcs : Slice (condfuncs.Key × T)) (needle : Slice U8)
    (b : Bool) (h : condfuncs.keys_named funcs needle = ok b) :
    b=true ↔ ∃ entry ∈ funcs.val, entry.1.key_name.val=needle.val := by
  unfold condfuncs.keys_named condfuncs.keys_named_loop at h
  refine any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold condfuncs.keys_named_loop.body at hr
  h5i_invert hr
  · rcases x with ⟨key,payload⟩
    change (do
      let equal ← bytes.eq key.key_name.deref needle
      if equal then ok (ControlFlow.done true)
      else do
        let next ← i + 1#usize
        ok (ControlFlow.cont next)) = ok r at hr
    h5i_invert hr
    · obtain ⟨hlt,he⟩ := slice_index_ok hx
      have hm := bytes_eq_ok _ _ _ (by assumption : bytes.eq _ _ = ok _)
      simp only [deref_val] at hm
      exact .inl ⟨hlt,by rw [he]; exact hm.1 (by assumption),rfl⟩
    · obtain ⟨hlt,he⟩ := slice_index_ok hx
      have hm := bytes_eq_ok _ _ _ (by assumption : bytes.eq _ _ = ok _)
      simp only [deref_val] at hm
      refine ⟨hlt,?_,by have := add_ok_val (by assumption : i + 1#usize = ok _); scalar_tac⟩
      rw [he]; intro hh; exact (by assumption : _ ≠ true) (hm.2 hh)
  · exact .inr ⟨by scalar_tac,rfl⟩
theorem present_ok {T : Type} (funcs : Slice (condfuncs.Key × T))
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : condfuncs.keys_present funcs values = ok b) :
    b=true ↔ ∃ entry ∈ funcs.val, ∃ request ∈ values.val,
      request.1.val = LookupName entry.1 := by
  unfold condfuncs.keys_present condfuncs.keys_present_loop at h
  refine any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold condfuncs.keys_present_loop.body at hr
  h5i_invert hr
  · rcases x with ⟨key,payload⟩
    change (do
      let lookup ← condfuncs.key_lookup_name key
      let found ← condfuncs.get_value values lookup.deref
      match found with
      | none => do
        let next ← i + 1#usize
        ok (ControlFlow.cont next)
      | some _ => ok (ControlFlow.done true)) = ok r at hr
    h5i_invert hr
    all_goals obtain ⟨hlt,he⟩ := slice_index_ok hx
    all_goals have hn := RustfsConditionEval.lookup_name_ok _ _ (by assumption : condfuncs.key_lookup_name _ = ok _)
    all_goals have hp := RustfsConditionEval.get_value_present_ok _ _ _ (by assumption : condfuncs.get_value _ _ = ok _)
    all_goals simp only [deref_val,hn,Option.isSome_none,Option.isSome_some,Bool.false_eq_true,false_iff,true_iff] at hp
    · refine ⟨hlt,?_,by have := add_ok_val (by assumption : i + 1#usize = ok _); scalar_tac⟩
      rw [he]; exact hp
    · exact .inl ⟨hlt,by rw [he]; exact hp,rfl⟩
  · exact .inr ⟨by scalar_tac,rfl⟩

theorem has_key_ok (c : condfuncs.Cond)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : condfuncs.has_any_key_in c values = ok b) :
    b=true ↔ OperatorKeyPresent c (RequestValueLists values.val) := by
  unfold condfuncs.has_any_key_in at h
  cases c <;> rw [present_ok _ _ _ h]
  all_goals simp [OperatorKeyPresent,OperatorKeys,RequestValueLists,List.mem_map,deref_val]

theorem references_ok (c : condfuncs.Cond) (needle : Slice U8) (b : Bool)
    (h : condfuncs.cond_references c needle = ok b) :
    b=true ↔ OperatorReferences c needle.val := by
  unfold condfuncs.cond_references at h
  cases c <;> rw [named_ok _ _ _ h]
  all_goals simp [OperatorReferences,OperatorKeys,List.mem_map,deref_val]

theorem group_ok (cs : Slice condfuncs.Condition) (needle : Slice U8) (b : Bool)
    (h : condfuncs.any_references cs needle = ok b) :
    b=true ↔ ∃ c ∈ cs.val, OperatorReferences c.cond needle.val := by
  unfold condfuncs.any_references condfuncs.any_references_loop at h
  refine any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold condfuncs.any_references_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok (by assumption : cs.index_usize i = ok _)
    have hm := references_ok _ _ _ (by assumption : condfuncs.cond_references _ _ = ok _)
    exact .inl ⟨hlt,by rw [he]; exact hm.1 (by assumption),rfl⟩
  · obtain ⟨hlt,he⟩ := slice_index_ok (by assumption : cs.index_usize i = ok _)
    have hm := references_ok _ _ _ (by assumption : condfuncs.cond_references _ _ = ok _)
    refine ⟨hlt,?_,by have := add_ok_val (by assumption : i + 1#usize = ok _); scalar_tac⟩
    rw [he]; exact fun hh => (by assumption : _ ≠ true) (hm.2 hh)
  · exact .inr ⟨by scalar_tac,rfl⟩

theorem functions_ok (f : condfuncs.Functions) (needle : Slice U8) (b : Bool)
    (h : condfuncs.references_key_name f needle = ok b) :
    b=true ↔ FunctionsReference f needle.val := by
  unfold condfuncs.references_key_name at h
  h5i_invert h
  all_goals have ha := group_ok _ _ _ (by assumption : condfuncs.any_references f.for_any_value.deref needle = ok _)
  all_goals try have hb := group_ok _ _ _ (by assumption : condfuncs.any_references f.for_all_values.deref needle = ok _)
  all_goals try have hc := group_ok _ _ _ (by assumption : condfuncs.any_references f.for_normal.deref needle = ok _)
  all_goals simp_all [FunctionsReference,List.mem_append,or_and_right,exists_or,deref_val]
  all_goals grind
end rustfs_kernel.Verified.RustfsConditionKeys
