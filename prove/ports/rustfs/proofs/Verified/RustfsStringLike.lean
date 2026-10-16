import Verified.RustfsNotActionForceDelete
import SpecOperators
import Verified.RustfsWildcard
import Verified.RustfsCondData
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsValids (any_loop)
open rustfs_kernel.Verified.RustfsForceDelete (deref_val)
namespace rustfs_kernel.Verified.RustfsStringLike

theorem any_like_ok (cands : Slice (alloc.vec.Vec U8)) (value : Slice U8) (b : Bool)
    (h : condfuncs.any_like cands value = ok b) :
    b = true ↔ AnyStringLike (cands.val.map (·.val)) value.val := by
  unfold condfuncs.any_like condfuncs.any_like_loop at h
  have hh : b = true ↔ ∃ p ∈ cands.val, globSpec (nats p.val) (nats value.val) = true := by
    refine any_loop _ _ _ (fun i r _ hr => ?_) b h
    unfold condfuncs.any_like_loop.body at hr
    simp only [rustfs_kernel.Verified.RustfsNotActionForceDelete.wildcard_is_glob,
      bind_ok, deref_val] at hr
    h5i_invert hr
    · obtain ⟨hlt,he⟩ := slice_index_ok hv1
      exact .inl ⟨hlt, by simpa [he] using hc_1, rfl⟩
    · obtain ⟨hlt,he⟩ := slice_index_ok hv1
      exact ⟨hlt, by simpa [he] using hc_1, by have := add_ok_val hi2; scalar_tac⟩
    · exact .inr ⟨by scalar_tac,rfl⟩
  simpa [AnyStringLike, List.mem_map] using hh

theorem like_step_ok (cands : Slice (alloc.vec.Vec U8)) (value : Slice U8)
    (q : condfuncs.Quantifier) (negate : Bool) (out : Option Bool)
    (h : condfuncs.like_step cands value q negate = ok out) :
    ∃ matched, (matched = true ↔ AnyStringLike (cands.val.map (·.val)) value.val) ∧
      out = LikeStep q negate matched := by
  unfold condfuncs.like_step at h
  obtain ⟨matched,hm,h⟩ := bind_tc_eq_ok.1 h
  refine ⟨matched,any_like_ok _ _ _ hm,?_⟩
  cases q <;> cases negate <;> cases matched <;>
    simpa [LikeStep,StringMatchHolds] using h.symm
end rustfs_kernel.Verified.RustfsStringLike
