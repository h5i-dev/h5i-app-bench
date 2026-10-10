import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Solution

h5i_derive_eq stmts.Effect stmts.Effect.Insts.CoreCmpPartialEqEffect.eq

theorem denies_pass_loop_spec (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (hd : ∀ st ∈ sts.val, st.effect = .Deny → stmts.statement_is_allowed st a e = ok true)
    (i : Usize) (hi : i.val ≤ sts.val.length) :
    policies.denies_pass_loop sts a e i ⦃ b => b = true ⦄ := by
  unfold policies.denies_pass_loop
  apply loop.spec_decr_nat
    (measure := fun (j : Usize) => sts.val.length - j.val)
    (inv := fun (j : Usize) => j.val ≤ sts.val.length)
    (post := fun (b : Bool) => b = true)
    (body := fun i1 => policies.denies_pass_loop.body sts a e i1)
    (x := i)
  · intro j hj
    unfold policies.denies_pass_loop.body
    dsimp only
    split
    · have : j.val < sts.val.length := by scalar_tac
      step
      step
      split
      · have heff : s.effect = stmts.Effect.Deny := by simpa [b_post] using ‹b = true›
        have hmem : s ∈ sts.val := by rw [s_post]; exact List.getElem_mem this
        have hall : stmts.statement_is_allowed s a e = ok true := hd s hmem heff
        rw [hall]
        step*
      · step*
    · simp
  · exact hi

theorem denies_pass_spec (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (hd : ∀ st ∈ sts.val, st.effect = .Deny → stmts.statement_is_allowed st a e = ok true) :
    policies.denies_pass sts a e ⦃ b => b = true ⦄ := by
  unfold policies.denies_pass
  exact denies_pass_loop_spec sts a e hd 0#usize (by simp)

theorem owner_allowed_unless_denied (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (ho : a.is_owner = true)
    (hd : ∀ st ∈ sts.val, st.effect = .Deny → stmts.statement_is_allowed st a e = ok true) :
    policies.policy_is_allowed sts a e = ok true := by
  have hpass : policies.denies_pass sts a e = ok true := by
    obtain ⟨y, hy, rfl⟩ := (WP.spec_equiv_exists _ _).1 (denies_pass_spec sts a e hd)
    exact hy
  unfold policies.policy_is_allowed
  rw [hpass]
  simp [bind_ok, ho]

end rustfs_kernel.Solution
