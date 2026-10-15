import Verified.RustfsSimpleWildcard
import Verified.RustfsValids
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsPrincipal
open rustfs_kernel.Verified.RustfsValids (any_loop)
open rustfs_kernel.Verified.RustfsForceDelete (deref_val)
theorem any_ok (patterns : Slice (alloc.vec.Vec U8)) (account : Slice U8) (b : Bool)
    (h : stmts.any_simple_match patterns account = ok b) :
    b=true ↔ ∃ p ∈ patterns.val, simpleGlobSpec (nats p.val) (nats account.val)=true := by
  unfold stmts.any_simple_match stmts.any_simple_match_loop at h
  refine any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold stmts.any_simple_match_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hv
    have hb := (by assumption : wildmatch.is_simple_match _ _ = ok _)
    rw [RustfsSimpleWildcard.wildcard_is_glob] at hb
    have hh := Result.ok.inj hb
    exact .inl ⟨hlt,by rw [he]; simpa only [deref_val,← hh] using hc_1,rfl⟩
  · obtain ⟨hlt,he⟩ := slice_index_ok hv
    have hb := (by assumption : wildmatch.is_simple_match _ _ = ok _)
    rw [RustfsSimpleWildcard.wildcard_is_glob] at hb
    have hh := Result.ok.inj hb
    refine ⟨hlt,?_,by have := add_ok_val hi2; scalar_tac⟩
    rw [he]; simpa only [deref_val,← hh] using hc_1
  · exact .inr ⟨by scalar_tac,rfl⟩
theorem principal_ok (p : stmts.Principal) (account : Slice U8) (b : Bool)
    (h : stmts.principal_is_match p account = ok b) :
    b=true ↔ (∃ pat ∈ p.aws.val ++ p.service.val,
      simpleGlobSpec (nats pat.val) (nats account.val)=true) := by
  unfold stmts.principal_is_match at h
  h5i_invert h
  all_goals have ha := any_ok _ _ _ (by assumption : stmts.any_simple_match p.aws.deref account = ok _)
  all_goals try have hs := any_ok _ _ _ h
  all_goals simp_all only [deref_val,List.mem_append,exists_prop,or_and_right,exists_or,true_iff,true_or,false_or]
end rustfs_kernel.Verified.RustfsPrincipal
