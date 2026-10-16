import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Solution

h5i_derive_eq stmts.Effect stmts.Effect.Insts.CoreCmpPartialEqEffect.eq

lemma denies_pass_loop_body_spec
    (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (hd : ∀ st ∈ sts.val, st.effect = .Deny → stmts.statement_is_allowed st a e = ok true)
    (i : Usize) (hi : i.val ≤ sts.length) :
    policies.denies_pass_loop.body sts a e i ⦃ r =>
      match r with
      | .done y => y = true
      | .cont x' => x'.val ≤ sts.length ∧ sts.length - x'.val < sts.length - i.val ⦄ := by
  unfold policies.denies_pass_loop.body
  by_cases hlt : i < sts.len
  · rw [if_pos hlt]
    step*
    have hbound : i.val < sts.val.length := by scalar_tac
    have hmem : s ∈ sts.val := by rw [s_post]; exact List.getElem_mem hbound
    have heff : s.effect = stmts.Effect.Deny := by simpa [b_post] using ‹b = true›
    have hall := hd s hmem heff
    rw [hall]
    simp only [bind_ok, reduceIte]
    step*
  · rw [if_neg hlt]
    simp

lemma denies_pass_ok (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (hd : ∀ st ∈ sts.val, st.effect = .Deny → stmts.statement_is_allowed st a e = ok true) :
    policies.denies_pass sts a e = ok true := by
  have hloop : policies.denies_pass_loop sts a e 0#usize ⦃ r => r = true ⦄ := by
    unfold policies.denies_pass_loop
    apply loop.spec_decr_nat
      (measure := fun j => sts.length - j.val)
      (inv := fun j => j.val ≤ sts.length)
      (post := fun b => b = true)
      (body := fun i1 => policies.denies_pass_loop.body sts a e i1)
      (x := 0#usize)
    · intro j hj
      apply WP.spec_mono (denies_pass_loop_body_spec sts a e hd j hj)
      intro r hr
      cases r <;> exact hr
    · scalar_tac
  have heq : policies.denies_pass_loop sts a e 0#usize = ok true := eq_ok_of_spec hloop
  unfold policies.denies_pass
  exact heq

theorem deny_only_ignores_allows (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (ho : a.deny_only = true)
    (hd : ∀ st ∈ sts.val, st.effect = .Deny → stmts.statement_is_allowed st a e = ok true) :
    policies.policy_is_allowed sts a e = ok true := by
  unfold policies.policy_is_allowed
  rw [denies_pass_ok sts a e hd]
  simp [ho]

end rustfs_kernel.Solution
