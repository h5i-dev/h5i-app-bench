import Verified.RustfsStringLike
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsValids (any_loop)
open rustfs_kernel.Verified.RustfsCondData (all_loop)
namespace rustfs_kernel.Verified.RustfsLikeQuantifier

theorem step_ok (cands : Slice (alloc.vec.Vec U8)) (value : Slice U8)
    (q : condfuncs.Quantifier) (negate : Bool) (out : Option Bool)
    (h : condfuncs.like_step cands value q negate = ok out) :
    (out = none ↔ if (match q with | .ForAllValues => true | _ => false) then
      LikeValue q negate (cands.val.map (·.val)) value.val else
      ¬ LikeValue q negate (cands.val.map (·.val)) value.val) ∧
    (∀ b, out = some b → b = (match q with | .ForAllValues => false | _ => true)) := by
  obtain ⟨matched,hm,ho⟩ := RustfsStringLike.like_step_ok _ _ _ _ _ h
  subst out
  cases q <;> cases negate <;> cases matched <;>
    simp_all [LikeStep,StringMatchHolds,LikeValue]

theorem loop_ok (requests candidates : alloc.vec.Vec (alloc.vec.Vec U8))
    (q : condfuncs.Quantifier) (negate b : Bool)
    (h : condfuncs.str_eval_like_loop q negate requests candidates 0#usize = ok b) :
    b = true ↔ QuantifiedLike q negate (candidates.val.map (·.val))
      (requests.val.map (·.val)) := by
  cases q with
  | None =>
    have hh : b = true ↔ ∃ value ∈ requests.val,
        LikeValue .None negate (candidates.val.map (·.val)) value.val := by
      unfold condfuncs.str_eval_like_loop at h
      refine any_loop _ _ _ (fun i r _ hr => ?_) b h
      unfold condfuncs.str_eval_like_loop.body at hr
      h5i_invert hr
      · obtain ⟨hlt,he⟩ := vec_index_ok hv
        have hm := (step_ok _ _ _ _ _ ho).1.mp rfl
        simp only [RustfsForceDelete.deref_val] at hm
        refine ⟨hlt, by simpa [he] using hm, by have := add_ok_val hi2; scalar_tac⟩
      · obtain ⟨hlt,he⟩ := vec_index_ok hv
        have hm := (step_ok _ _ _ _ _ ho).1
        have hb := (step_ok _ _ _ _ _ ho).2 _ rfl
        refine .inl ⟨hlt, ?_, hb⟩
        simp only [RustfsForceDelete.deref_val] at hm
        by_contra hp
        have hn : some b_1 = none := hm.mpr (by simpa [he] using hp)
        contradiction
      · have hb : b_1 = false := by
          simpa [condfuncs.Quantifier.Insts.CoreCmpPartialEqQuantifier.eq,
            condfuncs.Quantifier.read_discriminant] using hb_1.symm
        exact .inr ⟨by scalar_tac,hb⟩
    simpa [QuantifiedLike,List.mem_map] using hh
  | ForAnyValue =>
    have hh : b = true ↔ ∃ value ∈ requests.val,
        LikeValue .ForAnyValue negate (candidates.val.map (·.val)) value.val := by
      unfold condfuncs.str_eval_like_loop at h
      refine any_loop _ _ _ (fun i r _ hr => ?_) b h
      unfold condfuncs.str_eval_like_loop.body at hr
      h5i_invert hr
      · obtain ⟨hlt,he⟩ := vec_index_ok hv
        have hm := (step_ok _ _ _ _ _ ho).1.mp rfl
        simp only [RustfsForceDelete.deref_val] at hm
        refine ⟨hlt, by simpa [he] using hm, by have := add_ok_val hi2; scalar_tac⟩
      · obtain ⟨hlt,he⟩ := vec_index_ok hv
        have hm := (step_ok _ _ _ _ _ ho).1
        have hb := (step_ok _ _ _ _ _ ho).2 _ rfl
        refine .inl ⟨hlt, ?_, hb⟩
        simp only [RustfsForceDelete.deref_val] at hm
        by_contra hp
        have hn : some b_1 = none := hm.mpr (by simpa [he] using hp)
        contradiction
      · have hb : b_1 = false := by
          simpa [condfuncs.Quantifier.Insts.CoreCmpPartialEqQuantifier.eq,
            condfuncs.Quantifier.read_discriminant] using hb_1.symm
        exact .inr ⟨by scalar_tac,hb⟩
    simpa [QuantifiedLike,List.mem_map] using hh
  | ForAllValues =>
    have hh : b = true ↔ ∀ value ∈ requests.val,
        LikeValue .ForAllValues negate (candidates.val.map (·.val)) value.val := by
      unfold condfuncs.str_eval_like_loop at h
      refine all_loop _ _ _ (fun i r _ hr => ?_) b h
      unfold condfuncs.str_eval_like_loop.body at hr
      h5i_invert hr
      · obtain ⟨hlt,he⟩ := vec_index_ok hv
        have hm := (step_ok _ _ _ _ _ ho).1.mp rfl
        simp only [RustfsForceDelete.deref_val] at hm
        refine ⟨hlt, by simpa [he] using hm, by have := add_ok_val hi2; scalar_tac⟩
      · obtain ⟨hlt,he⟩ := vec_index_ok hv
        have hm := (step_ok _ _ _ _ _ ho).1
        have hb := (step_ok _ _ _ _ _ ho).2 _ rfl
        refine .inl ⟨hlt, ?_, hb⟩
        simp only [RustfsForceDelete.deref_val] at hm
        intro hp
        exact (by simpa [he] using (hm.mpr (by simpa [he] using hp)))
      · have hb : b_1 = true := by
          simpa [condfuncs.Quantifier.Insts.CoreCmpPartialEqQuantifier.eq,
            condfuncs.Quantifier.read_discriminant] using hb_1.symm
        exact .inr ⟨by scalar_tac,hb⟩
    simpa [QuantifiedLike,List.mem_map] using hh
end rustfs_kernel.Verified.RustfsLikeQuantifier
