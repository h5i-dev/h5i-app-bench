import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Solution

theorem effect_eq_allow_iff (e : stmts.Effect) :
    stmts.Effect.Insts.CoreCmpPartialEqEffect.eq e .Allow = ok true ↔ e = .Allow := by
  unfold stmts.Effect.Insts.CoreCmpPartialEqEffect.eq
  cases e <;> simp [stmts.Effect.read_discriminant]

theorem bp_statement_is_allowed_eval (st : stmts.BPStatement) (a : stmts.BucketPolicyArgs)
    (e : condfuncs.Env) (he : st.effect = .Allow)
    (h : stmts.bp_statement_is_allowed st a e = ok true) :
    stmts.bp_reaches_condition_eval st a = ok true := by
  unfold stmts.bp_statement_is_allowed at h
  rw [bind_tc_eq_ok] at h
  rcases h with ⟨b, hb, h⟩
  cases b
  · simp [stmts.effect_is_allowed, he] at h
  · exact hb

theorem bp_reaches_condition_eval_principal (st : stmts.BPStatement) (a : stmts.BucketPolicyArgs)
    (h : stmts.bp_reaches_condition_eval st a = ok true) :
    stmts.principal_is_match st.principal a.account.deref = ok true := by
  unfold stmts.bp_reaches_condition_eval at h
  h5i_invert h
  all_goals (subst_vars; assumption)

theorem slice_index_mem {α : Type} (s : Slice α) (i : Usize) (x : α)
    (h : Slice.index_usize s i = ok x) : x ∈ s.val := by
  unfold Slice.index_usize at h
  split at h
  · cases fail_not_ok h
  · simp only [Result.ok.injEq] at h
    subst h
    exact List.mem_of_getElem? (by assumption)

theorem usize_add_one_val (i i2 : Usize) (h : i + 1#usize = ok i2) : i2.val = i.val + 1 := by
  have heq := UScalar.add_equiv i 1#usize
  rw [h] at heq
  simp only [Result.match.ok] at heq
  exact heq.2.1

@[reducible] def step_prop (sts : Slice stmts.BPStatement) (a : stmts.BucketPolicyArgs) (e : condfuncs.Env)
    (i : Usize) (r : ControlFlow Usize Bool) : Prop :=
  match r with
  | .done y => y = true → ∃ st ∈ sts.val, st.effect = .Allow ∧
      stmts.principal_is_match st.principal a.account.deref = ok true ∧
      stmts.bp_statement_is_allowed st a e = ok true
  | .cont i' => i'.val ≤ sts.val.length ∧ sts.val.length - i'.val < sts.val.length - i.val

theorem bp_some_allow_loop_step (sts : Slice stmts.BPStatement) (a : stmts.BucketPolicyArgs)
    (e : condfuncs.Env) (i : Usize) (r : ControlFlow Usize Bool) (_hi : i.val ≤ sts.val.length)
    (hr : policies.bp_some_allow_loop.body sts a e i = ok r) :
    step_prop sts a e i r := by
  unfold policies.bp_some_allow_loop.body at hr
  by_cases hlt : i < sts.len
  · have hlt_val : i.val < sts.val.length := by
      have := hlt
      scalar_tac
    simp only [hlt, ite_true] at hr
    rw [bind_tc_eq_ok] at hr
    obtain ⟨b, hb, hr⟩ := hr
    have hb_mem : b ∈ sts.val := slice_index_mem sts i b hb
    rw [bind_tc_eq_ok] at hr
    obtain ⟨b1, hb1, hr⟩ := hr
    cases b1
    · simp only [Bool.false_eq_true, ite_false] at hr
      rw [bind_tc_eq_ok] at hr
      obtain ⟨i2, hi2, hr⟩ := hr
      have hr_inj : r = .cont i2 := by simp only [Result.ok.injEq] at hr; exact hr.symm
      subst hr_inj
      have hi2_val : i2.val = i.val + 1 := usize_add_one_val i i2 hi2
      dsimp [step_prop]
      omega
    · have hb_allow : b.effect = .Allow := (effect_eq_allow_iff b.effect).mp hb1
      simp only [ite_true] at hr
      rw [bind_tc_eq_ok] at hr
      obtain ⟨b2, hb2, hr⟩ := hr
      cases b2
      · simp only [Bool.false_eq_true, ite_false] at hr
        rw [bind_tc_eq_ok] at hr
        obtain ⟨i2, hi2, hr⟩ := hr
        have hr_inj : r = .cont i2 := by simp only [Result.ok.injEq] at hr; exact hr.symm
        subst hr_inj
        have hi2_val : i2.val = i.val + 1 := usize_add_one_val i i2 hi2
        dsimp [step_prop]
        omega
      · simp only [ite_true] at hr
        have hr_inj : r = .done true := by simp only [Result.ok.injEq] at hr; exact hr.symm
        subst hr_inj
        dsimp [step_prop]
        intro _
        have hprinc : stmts.principal_is_match b.principal a.account.deref = ok true :=
          bp_reaches_condition_eval_principal b a (bp_statement_is_allowed_eval b a e hb_allow hb2)
        exact ⟨b, hb_mem, hb_allow, hprinc, hb2⟩
  · simp [hlt] at hr
    subst hr
    dsimp [step_prop]
    intro hy; contradiction

theorem bucket_allow_needs_principal (sts : Slice stmts.BPStatement) (a : stmts.BucketPolicyArgs)
    (e : condfuncs.Env) (h : policies.bucket_policy_is_allowed sts a e = ok true) (ho : a.is_owner = false) :
    ∃ st ∈ sts.val, st.effect = .Allow ∧ stmts.principal_is_match st.principal a.account.deref = ok true ∧
      stmts.bp_statement_is_allowed st a e = ok true := by
  unfold policies.bucket_policy_is_allowed at h
  rw [bind_tc_eq_ok] at h
  obtain ⟨b, _, h⟩ := h
  cases b
  · simp at h
  · simp only [ho] at h
    unfold policies.bp_some_allow at h
    unfold policies.bp_some_allow_loop at h
    have hq := loop_ok
      (body := fun i1 => policies.bp_some_allow_loop.body sts a e i1)
      (Inv := fun i => i.val ≤ sts.val.length)
      (Q := fun y => y = true → ∃ st ∈ sts.val, st.effect = .Allow ∧
        stmts.principal_is_match st.principal a.account.deref = ok true ∧
        stmts.bp_statement_is_allowed st a e = ok true)
      (μ := fun i => sts.val.length - i.val)
      (fun i r hi hr => by
        have hstep := bp_some_allow_loop_step sts a e i r hi hr
        cases r <;> exact hstep)
      0#usize true (Nat.zero_le _) h
    exact hq rfl

end rustfs_kernel.Solution
