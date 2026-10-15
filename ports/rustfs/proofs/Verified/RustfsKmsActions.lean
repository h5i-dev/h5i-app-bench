import Verified.RustfsStatementSkips
import Verified.RustfsCondData
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsCondData (all_loop)
open rustfs_kernel.Verified.RustfsForceDelete (family_eq_ok)
namespace rustfs_kernel.Verified.RustfsKmsActions
theorem all_ok (actions : Slice acts.Action) (b : Bool)
    (h : stmts.all_kms actions = ok b) : b=true ↔ ∀ a ∈ actions.val, a.family=.Kms := by
  unfold stmts.all_kms stmts.all_kms_loop at h
  refine all_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold stmts.all_kms_loop.body core.cmp.PartialEq.ne.trait_default core.cmp.PartialEq.ne.default at hr
  simp only [family_eq_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok ha
    exact .inl ⟨hlt,by rw [he]; simpa using hc_1,rfl⟩
  · obtain ⟨hlt,he⟩ := slice_index_ok ha
    refine ⟨hlt,?_,by have := add_ok_val hi2; scalar_tac⟩
    rw [he]; simpa using hc_1
  · exact .inr ⟨by scalar_tac,rfl⟩
end rustfs_kernel.Verified.RustfsKmsActions
