import Verified.RustfsPolicyValues
import Verified.RustfsStringEquals
import Verified.RustfsLikeQuantifier
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsStringEval
set_option maxHeartbeats 2000000
set_option linter.unusedSimpArgs false
open RustfsPolicyValues
theorem equality_ok (key : condfuncs.Key) (policy : Slice (alloc.vec.Vec U8))
    (q : condfuncs.Quantifier) (ignoreCase negate : Bool)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (b : Bool)
    (h : condfuncs.str_eval key policy q ignoreCase negate values ctx=ok b) :
    b=StringEqualityEval (ctx.map RustfsAwsValues.context) (RequestValueLists values.val)
      key (texts policy.val) q ignoreCase negate := by
  unfold condfuncs.str_eval at h
  obtain ⟨keyName,hname,h⟩ := bind_tc_eq_ok.mp h
  have hn := RustfsConditionEval.lookup_name_ok key keyName hname
  obtain ⟨found,hfound,h⟩ := bind_tc_eq_ok.mp h
  have hf := RustfsOperatorLookup.lookup_ok values _ found hfound
  simp only [RustfsForceDelete.deref_val,hn] at hf
  cases found with
  | none =>
    simp only [bind_ok] at h
    obtain ⟨candidates,hcandidates,h⟩ := bind_tc_eq_ok.mp h
    have hp := policy_values_ok policy values ctx ignoreCase candidates hcandidates
    have hh := RustfsStringEquals.loop_ok _ _ q ignoreCase negate b h
    change b=EqualityDecision q ignoreCase negate (texts candidates.val) [] at hh
    rw [hp] at hh
    unfold StringEqualityEval
    rw [←hf]
    exact hh
  | some requests =>
    simp only [bind_ok] at h
    obtain ⟨candidates,hcandidates,h⟩ := bind_tc_eq_ok.mp h
    have hp := policy_values_ok policy values ctx ignoreCase candidates hcandidates
    have hh := RustfsStringEquals.loop_ok _ _ q ignoreCase negate b h
    change b=EqualityDecision q ignoreCase negate (texts candidates.val) (texts requests.val) at hh
    rw [hp] at hh
    unfold StringEqualityEval
    rw [←hf]
    simpa only [texts,Option.map_some,Option.getD_some,List.map_map,Function.comp_def] using hh

theorem like_ok (key : condfuncs.Key) (policy : Slice (alloc.vec.Vec U8))
    (q : condfuncs.Quantifier) (negate : Bool)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (b : Bool)
    (h : condfuncs.str_eval_like key policy q negate values ctx=ok b) :
    b=true ↔ StringLikeEval (ctx.map RustfsAwsValues.context) (RequestValueLists values.val)
      key (texts policy.val) q negate := by
  unfold condfuncs.str_eval_like at h
  obtain ⟨keyName,hname,h⟩ := bind_tc_eq_ok.mp h
  have hn := RustfsConditionEval.lookup_name_ok key keyName hname
  obtain ⟨found,hfound,h⟩ := bind_tc_eq_ok.mp h
  have hf := RustfsOperatorLookup.lookup_ok values _ found hfound
  simp only [RustfsForceDelete.deref_val,hn] at hf
  cases found with
  | none =>
    unfold StringLikeEval
    rw [←hf]
    clear hf hfound
    cases q <;> simp_all [condfuncs.Quantifier.Insts.CoreCmpPartialEqQuantifier.eq,
      condfuncs.Quantifier.read_discriminant,QuantifiedLike,Result.ok.injEq]
  | some requests =>
    obtain ⟨candidates,hcandidates,h⟩ := bind_tc_eq_ok.mp h
    have hp := policy_values_ok policy values ctx false candidates hcandidates
    have hh := RustfsLikeQuantifier.loop_ok requests candidates q negate b h
    have hbytes : (texts candidates.val).map BytesOfNats=candidates.val.map (·.val) := by
      simp only [texts,List.map_map,Function.comp_def,RustfsCommonSubstitution.bytes_nats]
    simpa only [StringLikeEval,←hf,Option.map_some,Option.getD_some,←hp,hbytes] using hh
end rustfs_kernel.Verified.RustfsStringEval
