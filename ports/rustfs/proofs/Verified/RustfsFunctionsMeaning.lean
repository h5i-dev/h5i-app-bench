import SpecFunctions
import Verified.RustfsStringFunction
import Verified.RustfsIpDecision
import Verified.RustfsNullBool
import Verified.RustfsNumeric
import Verified.RustfsConditionKeys
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsFunctionsMeaning
set_option maxHeartbeats 2000000
set_option linter.unusedSimpArgs false
theorem operator_ok (c : condfuncs.Cond) (q : condfuncs.Quantifier)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env) (b : Bool)
    (h : condfuncs.eval_cond c q values ctx env=ok b) :
    b=true ↔ OperatorHolds (ctx.map RustfsAwsValues.context) (RequestValueLists values.val)
      (env.ips.val.map (fun e => (e.1.val,e.2))) q c := by
  cases c with
  | Str op fs =>
    cases op <;> simp only [condfuncs.eval_cond,bind_ok] at h
    all_goals simpa only [OperatorHolds,StringFlags,RustfsPolicyValues.texts,RustfsForceDelete.deref_val] using
      RustfsStringFunction.function_ok _ _ _ _ _ _ _ _ h
  | Ip neg fs =>
    unfold condfuncs.eval_cond at h
    obtain ⟨r,hr,h⟩ := bind_tc_eq_ok.mp h
    have hh := RustfsIpDecision.conditions_ok fs.deref values env r hr
    cases neg <;> cases r <;> simp_all [OperatorHolds,Result.ok.injEq,RustfsForceDelete.deref_val]
  | Null fs =>
    simp only [condfuncs.eval_cond] at h
    simpa only [OperatorHolds,RustfsForceDelete.deref_val] using RustfsNullBool.null_conditions_ok fs.deref values b h
  | Bool fs =>
    simp only [condfuncs.eval_cond] at h
    simpa only [OperatorHolds,RustfsForceDelete.deref_val] using RustfsNullBool.bool_conditions_ok fs.deref values b h
  | Num op ie fs =>
    simp only [condfuncs.eval_cond] at h
    simpa only [OperatorHolds,RustfsForceDelete.deref_val] using RustfsNumeric.numeric_conditions_ok op ie fs.deref values b h
theorem condition_ok (c : condfuncs.Condition) (q : condfuncs.Quantifier)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env) (b : Bool)
    (h : condfuncs.condition_evaluate c q values ctx env=ok b) :
    b=true ↔ ConditionHolds (ctx.map RustfsAwsValues.context) (RequestValueLists values.val)
      (env.ips.val.map (fun e => (e.1.val,e.2))) q c := by
  unfold condfuncs.condition_evaluate at h
  by_cases hi : c.if_exists=true
  · simp only [hi,↓reduceIte] at h
    obtain ⟨present,hpresent,h⟩ := bind_tc_eq_ok.mp h
    have hp := RustfsConditionKeys.has_key_ok c.cond values present hpresent
    cases present with
    | false =>
      simp only [Bool.false_eq_true,↓reduceIte,Result.ok.injEq] at h
      have hn : ¬OperatorKeyPresent c.cond (RequestValueLists values.val) := by simpa using hp.symm
      simp [ConditionHolds,hi,hn,←h]
    | true =>
      simp only [↓reduceIte] at h
      have hp' : OperatorKeyPresent c.cond (RequestValueLists values.val) := hp.mp rfl
      simpa only [ConditionHolds,hi,hp',not_true_eq_false,and_false,false_or] using operator_ok _ _ _ _ _ _ h
  · simp only [hi,↓reduceIte] at h
    simpa only [ConditionHolds,hi,Bool.false_eq_true,false_and,false_or] using operator_ok _ _ _ _ _ _ h

theorem all_ok (cs : Slice condfuncs.Condition) (q : condfuncs.Quantifier)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env) (b : Bool)
    (h : condfuncs.all_hold cs q values ctx env=ok b) :
    b=true ↔ ∀ c ∈ cs.val, ConditionHolds (ctx.map RustfsAwsValues.context) (RequestValueLists values.val)
      (env.ips.val.map (fun e => (e.1.val,e.2))) q c := by
  unfold condfuncs.all_hold condfuncs.all_hold_loop at h
  refine RustfsCondData.all_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold condfuncs.all_hold_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok (by assumption : Slice.index_usize cs i=ok _)
    have hh := condition_ok _ _ _ _ _ _ (by assumption : condfuncs.condition_evaluate _ _ _ _ _=ok _)
    refine ⟨hlt,?_,by have := add_ok_val (by assumption : i+1#usize=ok _); scalar_tac⟩
    rw [he]; exact hh.mp (by assumption)
  · obtain ⟨hlt,he⟩ := slice_index_ok (by assumption : Slice.index_usize cs i=ok _)
    have hh := condition_ok _ _ _ _ _ _ (by assumption : condfuncs.condition_evaluate _ _ _ _ _=ok _)
    exact .inl ⟨hlt,by rw [he]; exact fun hp => (by assumption : _ ≠ true) (hh.mpr hp),rfl⟩
  · exact .inr ⟨by scalar_tac,rfl⟩

theorem functions_ok (f : condfuncs.Functions)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env) (b : Bool)
    (h : condfuncs.functions_evaluate f values ctx env=ok b) :
    b=true ↔ FunctionsHold (ctx.map RustfsAwsValues.context) (RequestValueLists values.val)
      (env.ips.val.map (fun e => (e.1.val,e.2))) f := by
  unfold condfuncs.functions_evaluate at h
  obtain ⟨any,ha,h⟩ := bind_tc_eq_ok.mp h
  have hAny := all_ok _ _ _ _ _ _ ha
  simp only [RustfsForceDelete.deref_val] at hAny
  cases any with
  | false =>
    simp only [Bool.false_eq_true,↓reduceIte,Result.ok.injEq] at h
    simp_all [FunctionsHold]
  | true =>
    simp only [↓reduceIte] at h
    obtain ⟨all,hall,h⟩ := bind_tc_eq_ok.mp h
    have hAll := all_ok _ _ _ _ _ _ hall
    simp only [RustfsForceDelete.deref_val] at hAll
    cases all with
    | false =>
      simp only [Bool.false_eq_true,↓reduceIte,Result.ok.injEq] at h
      simp_all [FunctionsHold]
    | true =>
      simp only [↓reduceIte] at h
      have hNormal := all_ok _ _ _ _ _ _ h
      simp only [RustfsForceDelete.deref_val] at hNormal
      simp_all [FunctionsHold]
end rustfs_kernel.Verified.RustfsFunctionsMeaning
