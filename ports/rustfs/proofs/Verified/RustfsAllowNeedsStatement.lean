import Verified.Derived
import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsAllowNeedsStatement


theorem effect_eq_allow (eff : stmts.Effect) (b : Bool)
    (h : stmts.Effect.Insts.CoreCmpPartialEqEffect.eq eff .Allow = ok b) (hb : b = true) :
    eff = .Allow := by
  have hspec := post_of_ok (stmts.Effect.Insts.CoreCmpPartialEqEffect.eq.spec eff .Allow) h
  rw [hb] at hspec
  exact of_decide_eq_true hspec.symm

theorem mem_of_index_usize {α : Type} (sl : Slice α) (i : Usize) (x : α)
    (h : sl.index_usize i = ok x) : x ∈ sl.val := by
  unfold Slice.index_usize at h
  split at h
  · simp at h
  · simp only [ok.injEq] at h
    subst h
    rename_i heq
    exact List.mem_of_getElem? heq

theorem usize_add_one (x i2 : Usize) (h : x + 1#usize = ok i2) : i2.val = x.val + 1 := by
  have heq := UScalar.add_equiv x 1#usize
  rw [h] at heq
  exact heq.2.1

theorem some_allow_step_done (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (x : Usize) (y : Bool)
    (hr : policies.some_allow_loop.body sts a e x = ok (.done y)) :
    y = true → ∃ st ∈ sts.val, st.effect = .Allow ∧ stmts.statement_is_allowed st a e = ok true := by
  unfold policies.some_allow_loop.body at hr
  dsimp only at hr
  split at hr
  · rename_i h_lt
    obtain ⟨s, hs, hr⟩ := bind_tc_eq_ok.1 hr
    obtain ⟨b, hb, hr⟩ := bind_tc_eq_ok.1 hr
    split at hr
    · rename_i hb_true
      obtain ⟨b1, hb1, hr⟩ := bind_tc_eq_ok.1 hr
      split at hr
      · rename_i hb1_true
        simp only [ok.injEq, ControlFlow.done.injEq] at hr; subst hr
        intro _
        refine ⟨s, mem_of_index_usize sts x s hs, effect_eq_allow s.effect b hb hb_true, ?_⟩
        rw [hb1_true] at hb1
        exact hb1
      · obtain ⟨i2, _, hr⟩ := bind_tc_eq_ok.1 hr
        simp only [ok.injEq] at hr; cases hr
    · obtain ⟨i2, _, hr⟩ := bind_tc_eq_ok.1 hr
      simp only [ok.injEq] at hr; cases hr
  · simp only [ok.injEq, ControlFlow.done.injEq] at hr; subst hr
    intro h; contradiction

theorem some_allow_step_cont (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (x x' : Usize)
    (hr : policies.some_allow_loop.body sts a e x = ok (.cont x')) :
    x'.val ≤ sts.val.length ∧ sts.val.length - x'.val < sts.val.length - x.val := by
  unfold policies.some_allow_loop.body at hr
  dsimp only at hr
  split at hr
  · rename_i h_lt
    have : x.val < sts.val.length := by scalar_tac
    obtain ⟨s, hs, hr⟩ := bind_tc_eq_ok.1 hr
    obtain ⟨b, hb, hr⟩ := bind_tc_eq_ok.1 hr
    split at hr
    · rename_i hb_true
      obtain ⟨b1, hb1, hr⟩ := bind_tc_eq_ok.1 hr
      split at hr
      · rename_i hb1_true
        simp only [ok.injEq] at hr; cases hr
      · obtain ⟨i2, hi2, hr⟩ := bind_tc_eq_ok.1 hr
        simp only [ok.injEq, ControlFlow.cont.injEq] at hr; subst hr
        have hi2_val := usize_add_one x i2 hi2
        omega
    · obtain ⟨i2, hi2, hr⟩ := bind_tc_eq_ok.1 hr
      simp only [ok.injEq, ControlFlow.cont.injEq] at hr; subst hr
      have hi2_val := usize_add_one x i2 hi2
      omega
  · simp only [ok.injEq] at hr; cases hr

theorem allow_needs_allow_statement (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (h : policies.policy_is_allowed sts a e = ok true) (ho : a.is_owner = false) (hd : a.deny_only = false) :
    ∃ st ∈ sts.val, st.effect = .Allow ∧ stmts.statement_is_allowed st a e = ok true := by
  unfold policies.policy_is_allowed at h
  obtain ⟨b, _, h⟩ := bind_tc_eq_ok.1 h
  split at h
  · simp only [hd, ho, Bool.false_eq_true, ↓reduceIte] at h
    unfold policies.some_allow policies.some_allow_loop at h
    refine (loop_ok
      (fun i1 => policies.some_allow_loop.body sts a e i1)
      (fun i => i.val ≤ sts.val.length)
      (fun y => y = true → ∃ st ∈ sts.val, st.effect = .Allow ∧ stmts.statement_is_allowed st a e = ok true)
      (fun i => sts.val.length - i.val)
      ?_
      0#usize
      true
      (by simp)
      h) rfl
    intro x r _ hr
    cases r with
    | done y => exact some_allow_step_done sts a e x y hr
    | cont x' => exact some_allow_step_cont sts a e x x' hr
  · simp only [ok.injEq] at h; contradiction

end rustfs_kernel.Verified.RustfsAllowNeedsStatement
