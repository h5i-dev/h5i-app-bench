import Verified.RustfsManagementDecisions
import Verified.RustfsResourceSets
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsManagementQueries
open rustfs_kernel.Verified.RustfsForceDelete (deref_val)
open rustfs_kernel.Verified.RustfsValids (any_loop)
theorem index_member_ok (xs : Slice Usize) (x : Usize) (b : Bool)
    (h : manage.index_member xs x = ok b) : (b = true ↔ x ∈ xs.val) := by
  unfold manage.index_member manage.index_member_loop at h
  have hm : (b = true ↔ ∃ y ∈ xs.val, y = x) := by
    refine any_loop xs.val (fun y => y = x) _ (fun i r _ hr => ?_) b h
    unfold manage.index_member_loop.body at hr
    h5i_invert hr
    ·
      obtain ⟨hlt, he⟩ := slice_index_ok hi2
      exact .inl ⟨hlt, by rw [he]; exact hc_1, rfl⟩
    ·
      obtain ⟨hlt, he⟩ := slice_index_ok hi2
      refine ⟨hlt, ?_, by have := add_ok_val hi3; scalar_tac⟩
      rw [he]; exact hc_1
    · exact .inr ⟨by scalar_tac, rfl⟩
  simpa using hm

theorem empty_ok (p : manage.Policy) :
    manage.is_empty p = ok (decide (p.statements.val = [])) := by
  unfold manage.is_empty
  dsimp only
  apply congrArg Result.ok
  apply Bool.eq_iff_iff.mpr
  simp only [decide_eq_true_eq, ← List.length_eq_zero_iff]
  constructor
  · intro h; have := congrArg UScalar.val h; simpa using this
  · intro h; apply UScalar.eq_of_val_eq; simpa using h

theorem match_resource_ok (p : manage.Policy) (needle : Slice U8) (b : Bool)
    (h : manage.match_resource p needle = ok b) :
    (b = true ↔ ∃ st ∈ p.statements.val, ∃ r ∈ st.resources.val,
      resets.match_resource r needle = ok true) := by
  unfold manage.match_resource manage.match_resource_loop at h
  refine any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold manage.match_resource_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt, he⟩ := vec_index_ok hs
    have hm := rustfs_kernel.Verified.RustfsResourceSets.set_match_ok _ _ _ hb_1
    exact .inl ⟨hlt, by rw [he]; simpa [deref_val] using hm.1 hc_1, rfl⟩
  · obtain ⟨hlt, he⟩ := vec_index_ok hs
    have hm := rustfs_kernel.Verified.RustfsResourceSets.set_match_ok _ _ _ hb_1
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]; intro hh; apply hc_1; apply hm.2; simpa [deref_val] using hh
  · exact .inr ⟨by scalar_tac, rfl⟩
end rustfs_kernel.Verified.RustfsManagementQueries
