import Verified.RustfsManagementTags
import Verified.RustfsBucketPrincipal
import Verified.RustfsManagementViews
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsRequestTags
open rustfs_kernel.Verified.RustfsManagementTags (functions_tag_ok)
open rustfs_kernel.Verified.RustfsManagementViews (statement_view_ok bp_view_ok)
open rustfs_kernel.Verified.RustfsForceDelete (effect_eq_ok deref_val)

theorem policy_loop_witness (p : manage.Policy) (args : stmts.Args) (vc : awsvars.VarContext)
    (b : Bool) (h : manage.policy_needs_existing_object_tag_for_args_loop p args vc 0#usize = ok b) :
    b = true → ∃ st ∈ p.statements.val, FunctionsUseExistingTag st.conditions ∧
      ∃ view, manage.statement_view st = ok view ∧ stmts.reaches_condition_eval view args (some vc) = ok true := by
  unfold manage.policy_needs_existing_object_tag_for_args_loop at h
  refine loop_ok _ (fun _ : Usize => True) (fun b => b = true → ∃ st ∈ p.statements.val,
      FunctionsUseExistingTag st.conditions ∧ ∃ view, manage.statement_view st = ok view ∧
      stmts.reaches_condition_eval view args (some vc) = ok true)
    (fun i => p.statements.val.length - i.val) ?_ _ b trivial h
  intro i r _ hr
  unfold manage.policy_needs_existing_object_tag_for_args_loop.body at hr
  h5i_invert hr
  · intro _
    obtain ⟨hlt,he⟩ := vec_index_ok hst
    exact ⟨st,by rw [←he]; exact List.getElem_mem hlt,
      (functions_tag_ok _ _ hb_1).1 hc_1,s,hs,by simpa only [hc_2] using hb1⟩
  · exact ⟨trivial,by have := add_ok_val hi2; scalar_tac⟩
  · exact ⟨trivial,by have := add_ok_val hi2; scalar_tac⟩
  · simp
theorem bucket_loop_witness (p : manage.BucketPolicy) (args : stmts.BucketPolicyArgs)
    (b : Bool) (h : manage.bucket_policy_needs_existing_object_tag_for_args_loop p args 0#usize = ok b) :
    b = true → ∃ st ∈ p.statements.val, FunctionsUseExistingTag st.conditions ∧
      ∃ view, manage.bp_statement_view st = ok view ∧ stmts.bp_reaches_condition_eval view args = ok true := by
  unfold manage.bucket_policy_needs_existing_object_tag_for_args_loop at h
  refine loop_ok _ (fun _ : Usize => True) (fun b => b = true → ∃ st ∈ p.statements.val,
      FunctionsUseExistingTag st.conditions ∧ ∃ view, manage.bp_statement_view st = ok view ∧
      stmts.bp_reaches_condition_eval view args = ok true)
    (fun i => p.statements.val.length - i.val) ?_ _ b trivial h
  intro i r _ hr
  unfold manage.bucket_policy_needs_existing_object_tag_for_args_loop.body at hr
  h5i_invert hr
  · intro _
    obtain ⟨hlt,he⟩ := vec_index_ok hst
    exact ⟨st,by rw [←he]; exact List.getElem_mem hlt,
      (functions_tag_ok _ _ hb_1).1 hc_1,b1,hb1,by simpa only [hc_2] using hb2⟩
  · exact ⟨trivial,by have := add_ok_val hi2; scalar_tac⟩
  · exact ⟨trivial,by have := add_ok_val hi2; scalar_tac⟩
  · simp
theorem policy_needs_sound (p : manage.Policy) (args : stmts.Args) (env : condfuncs.Env)
    (h : manage.policy_needs_existing_object_tag_for_args p args env = ok true) :
    ∃ st ∈ p.statements.val, FunctionsUseExistingTag st.conditions ∧
      (st.effect = .Allow → IsForceDelete args.action →
        ∃ x ∈ st.actions.val, acts.action_is_match_for_effect x args.action false = ok true) := by
  unfold manage.policy_needs_existing_object_tag_for_args at h
  h5i_invert h
  obtain ⟨st,hm,ht,view,hv,hr⟩ := policy_loop_witness _ _ _ _ h rfl
  refine ⟨st,hm,ht,?_⟩
  intro he hf
  have hv' := statement_view_ok _ _ hv
  unfold stmts.reaches_condition_eval at hr
  rw [effect_eq_ok,hv'.1,he] at hr
  obtain ⟨d,hd,hr⟩ := bind_tc_eq_ok.1 hr
  have hd' : d = false := (Result.ok.inj hd).symm
  subst d
  obtain ⟨c,hc,hr⟩ := bind_tc_eq_ok.1 hr
  cases c
  · simp at hr
  · have hw := rustfs_kernel.Verified.RustfsForceDelete.covers_ok _ _ _ hf hc
    simpa only [deref_val,hv'.2.1] using hw

theorem bucket_needs_sound (p : manage.BucketPolicy) (args : stmts.BucketPolicyArgs)
    (h : manage.bucket_policy_needs_existing_object_tag_for_args p args = ok true) :
    ∃ st ∈ p.statements.val, FunctionsUseExistingTag st.conditions ∧
      stmts.principal_is_match st.principal args.account.deref = ok true := by
  unfold manage.bucket_policy_needs_existing_object_tag_for_args at h
  h5i_invert h
  obtain ⟨st,hm,ht,view,hv,hr⟩ := bucket_loop_witness _ _ _ h rfl
  have hp := rustfs_kernel.Verified.RustfsBucketPrincipal.bp_reaches_condition_eval_principal _ _ hr
  have hv' := bp_view_ok _ _ hv
  exact ⟨st,hm,ht,by simpa only [hv'.2.1] using hp⟩
end rustfs_kernel.Verified.RustfsRequestTags
