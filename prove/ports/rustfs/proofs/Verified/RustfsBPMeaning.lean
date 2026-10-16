import SpecBucketStatement
import Verified.RustfsResourceMeaning
import Verified.RustfsStatementActions
import Verified.RustfsPrincipal
import Verified.RustfsKmsActions
import Verified.RustfsFunctionsMeaning
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsBPMeaning
set_option maxHeartbeats 4000000
open RustfsForceDelete
lemma deny_effect (e : stmts.Effect) : decide (e=.Deny)=DenyEffect e := by cases e <;> rfl
lemma zero_not_pos (n : Nat) : n=0 ↔ ¬0<n := by omega
lemma prefix_lit : lit "s3:prefix" = [115,51,58,112,114,101,102,105,120] := by decide +kernel
lemma principal_meaning (p : stmts.Principal) (account : Slice U8) (b : Bool)
    (h : stmts.principal_is_match p account=ok b) :
    b=true ↔ PrincipalMatches (p.aws.val.map (fun x=>nats x.val))
      (p.service.val.map (fun x=>nats x.val)) (nats account.val) := by
  rw [RustfsPrincipal.principal_ok _ _ _ h]
  simp only [PrincipalMatches, ←List.map_append, List.mem_map, exists_exists_and_eq_and]
lemma resource_meaning (f : condfuncs.Functions) (a : acts.Action) (bucket object : Slice U8)
    (needle : Slice U8) (prefixOnly : Bool) (resource : alloc.vec.Vec U8)
    (hn : nats needle.val=lit "s3:prefix")
    (hp : condfuncs.references_key_name f needle=ok prefixOnly)
    (hr : stmts.build_resource a bucket object prefixOnly=ok resource) :
    nats resource.val=StatementResource f a bucket.val object.val := by
  classical
  have hp' := RustfsConditionKeys.functions_ok _ _ _ hp
  have hn' : needle.val=BytesOfNats (lit "s3:prefix") := by rw [←hn, RustfsCommonSubstitution.bytes_nats]
  rw [hn'] at hp'
  have hb : prefixOnly=decide (FunctionsReference f (BytesOfNats (lit "s3:prefix"))) := by
    cases prefixOnly <;> simp_all
  rw [RustfsStatementResources.build_ok _ _ _ _ _ hr,hb]
  rfl
theorem reaches_ok (st : stmts.BPStatement) (args : stmts.BucketPolicyArgs) (b : Bool)
    (h : stmts.bp_reaches_condition_eval st args=ok b) :
    b=true ↔ BucketStatementReaches st args := by
  unfold stmts.bp_reaches_condition_eval at h
  simp only [effect_eq_ok] at h
  h5i_invert h
  all_goals try have hk := RustfsKmsActions.all_ok _ _ (by assumption : stmts.all_kms st.actions.deref=ok _)
  all_goals try have hp := principal_meaning _ _ _ (by assumption : stmts.principal_is_match st.principal args.account.deref=ok _)
  all_goals try have ha := RustfsStatementActions.coverage_ok _ _ _ _ _ (by assumption : acts.statement_covers _ _ _ _=ok _)
  all_goals try have hn := lift_slice (by assumption : lift (Array.to_slice _) = ok _)
  all_goals try have hr := resource_meaning st.conditions args.action args.bucket.deref args.object.deref _ _ _ (by simpa only [prefix_lit,List.map_cons,List.map_nil,UScalar.ofNatCore_val_eq] using hn) (by assumption) (by assumption)
  all_goals try have hpos := RustfsResourceMeaning.set_ok _ _ _ _ _ (by assumption : rsrc.set_is_match st.resources.deref _ args.conditions none=ok _)
  all_goals try have hneg := RustfsResourceMeaning.set_ok _ _ _ _ _ (by assumption : rsrc.set_is_match st.not_resources.deref _ args.conditions none=ok _)
  all_goals simp only [deref_val,Option.map_none,gt_iff_lt,UScalar.lt_equiv,alloc.vec.Vec.len_val,UScalar.ofNatCore_val_eq] at *
  all_goals simp only [BucketStatementReaches,←deny_effect]
  all_goals try rw [←hr]
  all_goals simp_all only [decide_eq_true_eq,Bool.true_eq_false,Bool.false_eq_true,true_iff,false_iff,not_true_eq_false,not_false_eq_true]
  all_goals simp_all only [ne_eq,List.eq_nil_iff_length_eq_zero, zero_not_pos,not_not,implies_true,forall_const]
  all_goals tauto
theorem allowed_ok (st : stmts.BPStatement) (args : stmts.BucketPolicyArgs)
    (env : condfuncs.Env) (b : Bool)
    (h : stmts.bp_statement_is_allowed st args env=ok b) :
    b=true ↔ BucketStatementAllowed st args (env.ips.val.map (fun e=>(e.1.val,e.2))) := by
  unfold stmts.bp_statement_is_allowed at h
  obtain ⟨reach,hr,h⟩ := bind_tc_eq_ok.mp h
  have hr' := reaches_ok st args reach hr
  cases reach with
  | false =>
    simp only [Bool.false_eq_true,ite_false,bind_ok] at h
    change stmts.effect_is_allowed st.effect false=ok b at h
    cases he : st.effect <;> simp only [stmts.effect_is_allowed,he] at h
    all_goals have hb := Result.ok.inj h
    all_goals cases b <;> simp_all [BucketStatementAllowed,EffectAllows]
  | true =>
    simp only [ite_true] at h
    obtain ⟨pair,hpair,h⟩ := bind_tc_eq_ok.mp h
    obtain ⟨check,hf,hpair⟩ := bind_tc_eq_ok.mp hpair
    have heq := Result.ok.inj hpair
    subst pair
    have hf' := RustfsFunctionsMeaning.functions_ok _ _ _ _ _ hf
    change stmts.effect_is_allowed st.effect check=ok b at h
    cases he : st.effect <;> simp only [stmts.effect_is_allowed,he] at h
    all_goals have hb := Result.ok.inj h
    all_goals cases b <;> simp_all [BucketStatementAllowed,EffectAllows]
end rustfs_kernel.Verified.RustfsBPMeaning
