import SpecResource
import Verified.RustfsPathFull
import Verified.RustfsPolicyValues
import Verified.RustfsWildcard
import Verified.RustfsValids
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsResourceMeaning
set_option maxHeartbeats 2000000
open RustfsForceDelete RustfsCommonSubstitution
lemma transform_ok (pattern : Slice U8)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (out : alloc.vec.Vec U8)
    (h : (if values.len>0#usize then rsrc.substitute_common pattern values
      else alloc.slice.Slice.to_vec core.clone.CloneU8 pattern)=ok out) :
    nats out.val=ResourcePattern (RequestValueLists values.val) (nats pattern.val) := by
  have hn : RequestValueLists values.val=[] ↔ values.val=[] := by simp [RequestValueLists]
  h5i_invert h
  · have he : values.val≠[] := by intro he; simp [he] at hc
    rw [RustfsCommonSubstitution.all_ok _ _ _ h]
    simp only [ResourcePattern,hn,he,↓reduceIte,bytes_nats]
  · have he : values.val=[] := List.eq_nil_iff_length_eq_zero.mpr (by scalar_tac)
    rw [RustfsCleanCanonical.to_vec_ok _ _ h]
    simp [ResourcePattern,he,RequestValueLists]
lemma eq_nats (a b : Slice U8) (r : Bool) (h : bytes.eq a b=ok r) :
    r=true ↔ nats a.val=nats b.val :=
  (bytes_eq_ok a b r h).trans ⟨congrArg nats,nats_inj⟩
theorem pattern_ok (pattern resource : Slice U8)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8))) (b : Bool)
    (h : rsrc.pattern_matches pattern resource values=ok b) :
    b=true ↔ ResourcePatternHolds (RequestValueLists values.val) (nats pattern.val) (nats resource.val) := by
  unfold rsrc.pattern_matches at h
  obtain ⟨resolved,hres,h⟩ := bind_tc_eq_ok.mp h
  have hr := transform_ok pattern values resolved hres
  h5i_invert h
  all_goals
    have hcp' := RustfsPathFull.clean_meaning resource cp hcp
    have hs := lift_slice hs1
    simp only [List.map_cons,List.map_nil,UScalar.ofNatCore_val_eq] at hs
    have hd := eq_nats _ _ _ hdot
    simp only [deref_val,hs,hcp'] at hd
    unfold ResourcePatternHolds
  · have hh := hd.mp hc
    simp only [hh,ne_eq,not_true_eq_false,false_and,Bool.false_eq_true]
  · have hd' : CleanPath (nats resource.val)≠[46] := fun he => hc (hd.mpr he)
    have he := eq_nats _ _ _ hb_1
    simp only [deref_val,hcp',hr] at he
    have he' := he.mp hc_1
    exact ⟨fun _ => ⟨hd',Or.inl he'⟩,fun _ => rfl⟩
  · have hd' : CleanPath (nats resource.val)≠[46] := fun he => hc (hd.mpr he)
    have he := eq_nats _ _ _ hb_1
    simp only [deref_val,hcp',hr] at he
    have he' : CleanPath (nats resource.val)≠ResourcePattern (RequestValueLists values.val) (nats pattern.val) :=
      fun hh => hc_1 (he.mpr hh)
    rw [RustfsWildcard.wildcard_is_glob] at h
    have hb := Result.ok.inj h
    simp only [deref_val,hcp',hr] at hb
    rw [←hb]
    constructor
    · intro hh; exact ⟨hd',Or.inr hh⟩
    · rintro ⟨_,hh | hh⟩
      · exact False.elim (he' hh)
      · exact hh
theorem alternatives_ok (patterns : alloc.vec.Vec (alloc.vec.Vec U8)) (resource : Slice U8)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8))) (b : Bool)
    (h : rsrc.resource_is_match_loop resource values patterns 0#usize=ok b) :
    b=true ↔ ∃ pattern ∈ patterns.val,
      ResourcePatternHolds (RequestValueLists values.val) (nats pattern.val) (nats resource.val) := by
  unfold rsrc.resource_is_match_loop at h
  refine RustfsValids.any_loop patterns.val
    (fun pattern => ResourcePatternHolds (RequestValueLists values.val) (nats pattern.val) (nats resource.val))
    _ (fun i r _ hr => ?_) b h
  unfold rsrc.resource_is_match_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := vec_index_ok hv
    have hm := pattern_ok _ _ _ _ (by assumption)
    simp only [deref_val] at hm
    exact Or.inl ⟨hlt,by rw [he]; exact hm.mp hc_1,rfl⟩
  · obtain ⟨hlt,he⟩ := vec_index_ok hv
    have hm := pattern_ok _ _ _ _ (by assumption)
    simp only [deref_val] at hm
    refine ⟨hlt,?_,by have := add_ok_val hi2; scalar_tac⟩
    rw [he]
    exact fun hh => hc_1 (hm.mpr hh)
  · exact Or.inr ⟨by scalar_tac,rfl⟩
theorem resource_ok (r : rsrc.Resource) (resource : Slice U8)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (b : Bool)
    (h : rsrc.resource_is_match r resource values ctx=ok b) :
    b=true ↔ ResourceHolds (ctx.map RustfsAwsValues.context) (RequestValueLists values.val)
      (ResourceText r) (nats resource.val) := by
  cases r with
  | S3 text | Kms text =>
    unfold rsrc.resource_is_match at h
    simp only [u8vec_clone,bind_ok] at h
    obtain ⟨patterns,hpatterns,h⟩ := bind_tc_eq_ok.mp h
    have hm := alternatives_ok patterns resource values b h
    have hp : patterns.val.map (fun v => nats v.val)=
        ResolvedPolicy (ctx.map RustfsAwsValues.context) (nats text.val) := by
      cases ctx with
      | none =>
        have hp := RustfsBytes.push_ok hpatterns
        change patterns.val=[text] at hp
        simp only [hp,List.map_cons,List.map_nil,Option.map_none,ResolvedPolicy]
      | some c =>
        change awsvars.resolve_aws_variables c text.deref=ok patterns at hpatterns
        unfold awsvars.resolve_aws_variables at hpatterns
        have hp := RustfsAwsResolution.depth_ok c text.deref 0#usize patterns hpatterns
        simpa only [ResolvedPolicy,Option.map_some,deref_val,UScalar.ofNatCore_val_eq] using hp
    simp only [ResourceHolds,ResourceText]
    rw [←hp]
    simpa only [List.mem_map,exists_exists_and_eq_and] using hm
theorem set_ok (set : Slice rsrc.Resource) (resource : Slice U8)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (b : Bool)
    (h : rsrc.set_is_match set resource values ctx=ok b) :
    b=true ↔ ResourceSetHolds (ctx.map RustfsAwsValues.context) (RequestValueLists values.val)
      (set.val.map ResourceText) (nats resource.val) := by
  unfold rsrc.set_is_match rsrc.set_is_match_loop at h
  have hm : b=true ↔ ∃ r ∈ set.val, ResourceHolds (ctx.map RustfsAwsValues.context)
      (RequestValueLists values.val) (ResourceText r) (nats resource.val) := by
    refine RustfsValids.any_loop set.val
      (fun r => ResourceHolds (ctx.map RustfsAwsValues.context) (RequestValueLists values.val)
        (ResourceText r) (nats resource.val)) _ (fun i res _ hr => ?_) b h
    unfold rsrc.set_is_match_loop.body at hr
    h5i_invert hr
    · obtain ⟨hlt,he⟩ := slice_index_ok hr_1
      have hm := resource_ok _ _ _ _ _ (by assumption)
      exact Or.inl ⟨hlt,by rw [he]; exact hm.mp hc_1,rfl⟩
    · obtain ⟨hlt,he⟩ := slice_index_ok hr_1
      have hm := resource_ok _ _ _ _ _ (by assumption)
      refine ⟨hlt,?_,by have := add_ok_val hi2; scalar_tac⟩
      rw [he]
      exact fun hh => hc_1 (hm.mpr hh)
    · exact Or.inr ⟨by scalar_tac,rfl⟩
  simpa only [ResourceSetHolds,List.mem_map,exists_exists_and_eq_and] using hm
end rustfs_kernel.Verified.RustfsResourceMeaning
