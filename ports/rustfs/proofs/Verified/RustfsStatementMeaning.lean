import SpecIdentityStatement
import Verified.RustfsBPMeaning
import Verified.RustfsKmsMeaning
import Verified.RustfsStatementContext
import Verified.RustfsStatementSkips
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsStatementMeaning
set_option maxHeartbeats 12000000
set_option maxRecDepth 10000
set_option linter.unusedSimpArgs false
open RustfsForceDelete RustfsBPMeaning
theorem reaches_ok (st : stmts.Statement) (args : stmts.Args) (ctx : Option awsvars.VarContext)
    (b : Bool) (h : stmts.reaches_condition_eval st args ctx=ok b) :
    b=true ↔ StatementReaches (ctx.map RustfsAwsValues.context) st args := by
  unfold stmts.reaches_condition_eval at h
  simp only [effect_eq_ok,bind_tc_ok,bind_ok] at h
  have hh := bind_tc_eq_ok.mp h
  clear h
  obtain ⟨covered,hcovered,h⟩ := hh
  cases covered <;> try simp only [Bool.false_eq_true,ite_false,ite_true] at h
  all_goals try (have hh := bind_tc_eq_ok.mp h; clear h; obtain ⟨iskms,hiskms,h⟩ := hh; cases iskms <;> simp only [Bool.false_eq_true,ite_false,ite_true] at h)
  all_goals have hplen : (st.resources.len>0#usize) ↔ ¬st.resources.len=0#usize := by scalar_tac
  all_goals have hnlen : (st.not_resources.len>0#usize) ↔ ¬st.not_resources.len=0#usize := by scalar_tac
  all_goals by_cases hpr : st.resources.len=0#usize
  all_goals by_cases hnr : st.not_resources.len=0#usize
  all_goals try simp only [hplen,hnlen,hpr,hnr,not_true_eq_false,not_false_eq_true,ite_true,ite_false] at h
  all_goals h5i_invert h
  all_goals try have ha := RustfsStatementActions.coverage_ok _ _ _ _ _ (by assumption : acts.statement_covers _ _ _ _=ok _)
  all_goals try have hk := RustfsStatementSkips.family_ok _ _ _ (by assumption : stmts.has_family st.actions.deref .Kms=ok _)
  all_goals try have hadmin := RustfsStatementSkips.family_ok _ _ _ (by assumption : stmts.has_family st.actions.deref .Admin=ok _)
  all_goals try have hsts := RustfsStatementSkips.family_ok _ _ _ (by assumption : stmts.has_family st.actions.deref .Sts=ok _)
  all_goals try have hscope := RustfsKmsMeaning.scope_ok _ _ _ _ (by assumption : stmts.kms_key_scope_matches st args ctx=ok _)
  all_goals try have hs := RustfsStatementSkips.skip_ok _ _ _ (by assumption : stmts.skips_resource_match st args=ok _)
  all_goals try have hn := lift_slice (by assumption : lift (Array.to_slice _) = ok _)
  all_goals try have hr := resource_meaning st.conditions args.action args.bucket.deref args.object.deref _ _ _ (by simpa only [prefix_lit,List.map_cons,List.map_nil,UScalar.ofNatCore_val_eq] using hn) (by assumption) (by assumption)
  all_goals try have hpos := RustfsResourceMeaning.set_ok _ _ _ _ _ (by assumption : rsrc.set_is_match st.resources.deref _ args.conditions ctx=ok _)
  all_goals try have hneg := RustfsResourceMeaning.set_ok _ _ _ _ _ (by assumption : rsrc.set_is_match st.not_resources.deref _ args.conditions ctx=ok _)
  all_goals simp only [RustfsKmsMeaning.scalar_eq,deref_val,gt_iff_lt,UScalar.lt_equiv,alloc.vec.Vec.len_val,alloc.vec.Vec.length,UScalar.ofNatCore_val_eq] at *
  all_goals simp only [StatementReaches,←deny_effect]
  all_goals try rw [←hr]
  all_goals try simp only [decide_eq_true_eq,Bool.true_eq_false,Bool.false_eq_true,true_iff,false_iff,not_true_eq_false,not_false_eq_true] at *
  all_goals try simp only [ne_eq,List.eq_nil_iff_length_eq_zero,zero_not_pos,not_not,implies_true,forall_const] at *
  all_goals try rw [←ha]
  all_goals try rw [←hk]
  all_goals try rw [←hadmin]
  all_goals try rw [←hsts]
  all_goals try rw [←hs]
  all_goals try rw [←hscope]
  all_goals try rw [←hpos]
  all_goals try rw [←hneg]
  all_goals try cases b
  all_goals try simp_all only [Bool.true_eq_false,Bool.false_eq_true,true_iff,false_iff,not_true_eq_false,not_false_eq_true,Nat.lt_irrefl]
  all_goals tauto
theorem allowed_ok (st : stmts.Statement) (args : stmts.Args)
    (env : condfuncs.Env) (b : Bool)
    (h : stmts.statement_is_allowed st args env=ok b) :
    b=true ↔ StatementAllowed st args env := by
  unfold stmts.statement_is_allowed at h
  obtain ⟨vc,hvc,h⟩ := bind_tc_eq_ok.mp h
  have hc := RustfsStatementContext.resolver_ok args env vc hvc
  obtain ⟨reach,hr,h⟩ := bind_tc_eq_ok.mp h
  have hr' := reaches_ok st args (some vc) reach hr
  simp only [Option.map_some,hc] at hr'
  cases reach with
  | false =>
    simp only [Bool.false_eq_true,ite_false,bind_ok] at h
    change stmts.effect_is_allowed st.effect false=ok b at h
    cases he : st.effect <;> simp only [stmts.effect_is_allowed,he] at h
    all_goals have hb := Result.ok.inj h
    all_goals cases b <;> simp_all [StatementAllowed,EffectAllows]
  | true =>
    simp only [ite_true] at h
    obtain ⟨pair,hpair,h⟩ := bind_tc_eq_ok.mp h
    obtain ⟨check,hf,hpair⟩ := bind_tc_eq_ok.mp hpair
    have heq := Result.ok.inj hpair
    subst pair
    have hf' := RustfsFunctionsMeaning.functions_ok _ _ _ _ _ hf
    simp only [Option.map_some,hc] at hf'
    change stmts.effect_is_allowed st.effect check=ok b at h
    cases he : st.effect <;> simp only [stmts.effect_is_allowed,he] at h
    all_goals have hb := Result.ok.inj h
    all_goals cases b <;> simp_all [StatementAllowed,EffectAllows]
end rustfs_kernel.Verified.RustfsStatementMeaning
