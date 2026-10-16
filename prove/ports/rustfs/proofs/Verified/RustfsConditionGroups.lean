import Verified.RustfsCompleteConditionEquality
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsValids (any_loop)
open rustfs_kernel.Verified.RustfsCondData
open rustfs_kernel.Verified.RustfsCompleteConditionEquality
open rustfs_kernel.Verified.RustfsForceDelete (deref_val)

namespace rustfs_kernel.Verified.RustfsConditionGroups
 theorem contains_ok (xs : Slice conddata.Condition) (c : conddata.Condition) (b : Bool)
    (h : conddata.contains_condition xs c = ok b) :
    (b = true ↔ ∃ d ∈ xs.val, SameCondition d c) := by
  unfold conddata.contains_condition conddata.contains_condition_loop at h
  refine any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold conddata.contains_condition_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt, he⟩ := slice_index_ok (by assumption : Slice.index_usize _ _ = ok _)
    have hk := condition_eq_ok _ _ _ (by assumption : conddata.condition_eq _ _ = ok _)
    exact .inl ⟨hlt, by rw [he]; exact hk.1 (by assumption), rfl⟩
  · obtain ⟨hlt, he⟩ := slice_index_ok (by assumption : Slice.index_usize _ _ = ok _)
    have hk := condition_eq_ok _ _ _ (by assumption : conddata.condition_eq _ _ = ok _)
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]; intro hh; exact (by assumption : _ ≠ true) (hk.2 hh)
  · exact .inr ⟨by scalar_tac, rfl⟩

theorem covers_ok (l r : Slice conddata.Condition) (b : Bool)
    (h : conddata.list_covers l r = ok b) :
    (b = true ↔ ConditionGroupCovered l.val r.val) := by
  unfold conddata.list_covers conddata.list_covers_loop at h
  refine all_loop _ _ _ (fun i res _ hr => ?_) b h
  unfold conddata.list_covers_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt, he⟩ := slice_index_ok (by assumption : Slice.index_usize _ _ = ok _)
    have hk := contains_ok _ _ _ (by assumption : conddata.contains_condition _ _ = ok _)
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]; exact hk.1 (by assumption)
  · obtain ⟨hlt, he⟩ := slice_index_ok (by assumption : Slice.index_usize _ _ = ok _)
    have hk := contains_ok _ _ _ (by assumption : conddata.contains_condition _ _ = ok _)
    refine .inl ⟨hlt, ?_, rfl⟩
    rw [he]; intro hh; exact (by assumption : _ ≠ true) (hk.2 hh)
  · exact .inr ⟨by scalar_tac, rfl⟩

theorem functions_eq_ok (a b : conddata.Functions) (r : Bool)
    (h : conddata.functions_eq a b = ok r) : (r = true ↔ ConditionGroupsMatch a b) := by
  unfold conddata.functions_eq at h
  h5i_invert h
  all_goals try have ha := covers_ok _ _ _ (by assumption : conddata.list_covers (alloc.vec.Vec.deref a.for_any_value) _ = ok _)
  all_goals try have hb := covers_ok _ _ _ (by assumption : conddata.list_covers (alloc.vec.Vec.deref a.for_all_values) _ = ok _)
  all_goals try have hc := covers_ok _ _ _ (by assumption : conddata.list_covers (alloc.vec.Vec.deref a.for_normal) _ = ok _)
  all_goals simp_all [ConditionGroupsMatch, deref_val]
end rustfs_kernel.Verified.RustfsConditionGroups
