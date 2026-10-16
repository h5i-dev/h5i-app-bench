import SpecStringPolicies
import Verified.RustfsAwsDepthMeaning
import Verified.RustfsCommonSubstitution
import Verified.RustfsAsciiLower
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsPolicyValues
set_option maxHeartbeats 2000000
set_option linter.unusedSimpArgs false
def texts (xs : List (alloc.vec.Vec U8)) := xs.map (fun v => nats v.val)
theorem inner_ok (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (resolved initial : alloc.vec.Vec (alloc.vec.Vec U8)) (ignoreCase : Bool)
    (result : Bool × alloc.vec.Vec (alloc.vec.Vec U8))
    (h : condfuncs.policy_values_loop0_loop0 values ignoreCase initial resolved 0#usize=ok result) :
    result.1=ignoreCase ∧ texts result.2.val=texts initial.val ++
      (texts resolved.val).map (PolicyValueTransform (RequestValueLists values.val) ignoreCase) := by
  unfold condfuncs.policy_values_loop0_loop0 at h
  let F := fun v : alloc.vec.Vec U8 => PolicyValueTransform (RequestValueLists values.val) ignoreCase (nats v.val)
  refine loop_ok _ (fun s : Bool × alloc.vec.Vec (alloc.vec.Vec U8) × Usize =>
    s.1=ignoreCase ∧ s.2.2.val ≤ resolved.val.length ∧
    texts s.2.1.val=texts initial.val ++ (resolved.val.take s.2.2.val).map F)
    (fun r => r.1=ignoreCase ∧ texts r.2.val=texts initial.val ++ (texts resolved.val).map
      (PolicyValueTransform (RequestValueLists values.val) ignoreCase))
    (fun s => resolved.val.length-s.2.2.val) ?_ _ result ⟨rfl,by simp,by simp⟩ h
  rintro ⟨flag,buf,j⟩ r ⟨hflag,hj,ha⟩ hr
  dsimp only at hflag hj ha hr ⊢
  subst flag
  unfold condfuncs.policy_values_loop0_loop0.body at hr
  h5i_invert hr
  case isTrue.isTrue =>
    obtain ⟨hlt,he⟩ := vec_index_ok hv
    have hx := RustfsCommonSubstitution.first_ok _ _ _ hx
    simp only [RustfsForceDelete.deref_val] at hx
    have hpush := RustfsBytes.push_ok hout1
    have hn : j1.val=j.val+1 := by have := add_ok_val hj1; scalar_tac
    have htake : resolved.val.take j1.val=resolved.val.take j.val ++ [v] := by
      rw [hn,List.take_succ_eq_append_getElem hlt,he]
    dsimp only
    refine ⟨⟨by exact hc_1.symm,by omega,?_⟩,by omega⟩
    rw [hpush]
    simp only [texts,List.map_append,List.map_cons,List.map_nil] at ha ⊢
    rw [ha,htake,List.map_append]
    simp only [List.map_cons,List.map_nil,List.append_assoc]
    congr 1
    congr 1
    dsimp only [F,PolicyValueTransform]
    rw [RustfsCommonSubstitution.bytes_nats]
    simp only [hc_1,Bool.false_eq_true,↓reduceIte]
    have hl := RustfsAsciiLower.lower_ok _ _ hx1
    simpa only [RustfsForceDelete.deref_val,hx] using congrArg (fun xs : List Nat => [xs]) hl
  case isTrue.isFalse =>
    obtain ⟨hlt,he⟩ := vec_index_ok hv
    have hx := RustfsCommonSubstitution.first_ok _ _ _ hx
    simp only [RustfsForceDelete.deref_val] at hx
    have hpush := RustfsBytes.push_ok hout1
    have hn : j1.val=j.val+1 := by have := add_ok_val hj1; scalar_tac
    have htake : resolved.val.take j1.val=resolved.val.take j.val ++ [v] := by
      rw [hn,List.take_succ_eq_append_getElem hlt,he]
    dsimp only
    refine ⟨⟨by exact (Bool.eq_false_iff.mpr hc_1).symm,by omega,?_⟩,by omega⟩
    rw [hpush]
    simp only [texts,List.map_append,List.map_cons,List.map_nil] at ha ⊢
    rw [ha,htake,List.map_append]
    simp only [List.map_cons,List.map_nil,List.append_assoc]
    congr 1
    congr 1
    dsimp only [F,PolicyValueTransform]
    rw [RustfsCommonSubstitution.bytes_nats]
    simp only [hc_1,Bool.false_eq_true,↓reduceIte]
    rw [hx]
  case isFalse =>
    have hn : resolved.val.length ≤ j.val := by scalar_tac
    refine ⟨rfl,?_⟩
    simpa only [List.take_of_length_le hn,texts,List.map_map,Function.comp_def] using ha
theorem resolve_ok (policy : Slice (alloc.vec.Vec U8)) (i : Usize)
    (ctx : Option awsvars.VarContext) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : (match ctx with
      | none => do
        let v ← Slice.index_usize policy i
        let v1 ← alloc.vec.CloneVec.clone core.clone.CloneU8 v
        (alloc.vec.Vec.new (alloc.vec.Vec U8)).push v1
      | some c => do
        let v ← Slice.index_usize policy i
        awsvars.resolve_aws_variables c v.deref)=ok out) :
    ∃ v, policy.val[i.val]?=some v ∧
      texts out.val=ResolvedPolicy (ctx.map RustfsAwsValues.context) (nats v.val) := by
  cases ctx with
  | none =>
    simp only [u8vec_clone,bind_ok] at h
    h5i_invert h
    obtain ⟨hi,he⟩ := slice_index_ok hv1
    have hp := RustfsBytes.push_ok h
    change out.val=[v1] at hp
    refine ⟨v1,by simp [List.getElem?_eq_getElem hi,he],?_⟩
    simp [texts,hp,ResolvedPolicy]
  | some c =>
    h5i_invert h
    obtain ⟨hi,he⟩ := slice_index_ok hv
    refine ⟨v,by simp [List.getElem?_eq_getElem hi,he],?_⟩
    have hh := RustfsAwsResolution.depth_ok c v.deref 0#usize out h
    simpa only [texts,ResolvedPolicy,Option.map_some,RustfsForceDelete.deref_val,UScalar.ofNatCore_val_eq] using hh
theorem outer_ok (policy : Slice (alloc.vec.Vec U8))
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (ignoreCase : Bool)
    (initial out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : condfuncs.policy_values_loop0 policy values ctx ignoreCase initial 0#usize=ok out) :
    texts out.val=texts initial.val ++ PolicyCandidates (ctx.map RustfsAwsValues.context)
      (RequestValueLists values.val) ignoreCase (texts policy.val) := by
  unfold condfuncs.policy_values_loop0 at h
  let F := fun v : alloc.vec.Vec U8 => (ResolvedPolicy (ctx.map RustfsAwsValues.context) (nats v.val)).map
    (PolicyValueTransform (RequestValueLists values.val) ignoreCase)
  refine loop_ok _ (fun s : Bool × alloc.vec.Vec (alloc.vec.Vec U8) × Usize =>
    s.1=ignoreCase ∧ s.2.2.val ≤ policy.val.length ∧
    texts s.2.1.val=texts initial.val ++ (policy.val.take s.2.2.val).flatMap F)
    (fun r => texts r.val=texts initial.val ++ PolicyCandidates (ctx.map RustfsAwsValues.context)
      (RequestValueLists values.val) ignoreCase (texts policy.val))
    (fun s => policy.val.length-s.2.2.val) ?_ _ out ⟨rfl,by simp,by simp⟩ h
  rintro ⟨flag,buf,i⟩ r ⟨hflag,hi,ha⟩ hr
  dsimp only at hflag hi ha hr ⊢
  subst flag
  unfold condfuncs.policy_values_loop0.body at hr
  by_cases hb : i<policy.len
  · simp only [hb,↓reduceIte] at hr
    obtain ⟨resolved,hresolved,hr⟩ := bind_tc_eq_ok.mp hr
    obtain ⟨v,hv,hres⟩ := resolve_ok policy i ctx resolved hresolved
    obtain ⟨pair,hpair,hr⟩ := bind_tc_eq_ok.mp hr
    rcases pair with ⟨flag,buf'⟩
    have hh := inner_ok values resolved buf ignoreCase (flag,buf') hpair
    simp only [Prod.fst,Prod.snd] at hh
    obtain ⟨hflag,hbuf⟩ := hh
    subst flag
    change (do let next ← i+1#usize; ok (ControlFlow.cont (ignoreCase,buf',next)))=ok r at hr
    h5i_invert hr
    have hn : next.val=i.val+1 := by have := add_ok_val hnext; scalar_tac
    have hlt := List.getElem?_eq_some_iff.mp hv |>.1
    have hve : policy.val[i.val]=v := by simpa [List.getElem?_eq_getElem hlt] using hv
    have htake : policy.val.take next.val=policy.val.take i.val ++ [v] := by
      rw [hn,List.take_succ_eq_append_getElem hlt,hve]
    dsimp only
    refine ⟨⟨rfl,by omega,?_⟩,by omega⟩
    rw [hbuf,ha,hres,htake,List.flatMap_append,List.flatMap_cons,List.flatMap_nil,List.append_nil]
    simp only [List.append_assoc,F]
  · simp only [hb,↓reduceIte,Result.ok.injEq] at hr
    subst r
    have hn : policy.val.length ≤ i.val := by scalar_tac
    rw [List.take_of_length_le hn] at ha
    simpa only [PolicyCandidates,texts,List.flatMap_map,List.map_flatMap,Function.comp_def,F] using ha

theorem policy_values_ok (policy : Slice (alloc.vec.Vec U8))
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (ignoreCase : Bool)
    (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : condfuncs.policy_values policy values ctx ignoreCase=ok out) :
    texts out.val=PolicyCandidates (ctx.map RustfsAwsValues.context)
      (RequestValueLists values.val) ignoreCase (texts policy.val) := by
  have hh := outer_ok policy values ctx ignoreCase (alloc.vec.Vec.new _) out h
  simpa [texts] using hh
end rustfs_kernel.Verified.RustfsPolicyValues
