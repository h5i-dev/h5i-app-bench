import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Solution

theorem explicit_deny_wins (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (st : stmts.Statement) (hm : st ∈ sts.val) (hd : st.effect = .Deny)
    (hs : stmts.statement_is_allowed st a e = ok false) :
    policies.policy_is_allowed sts a e ≠ ok true := by
  intro h
  obtain ⟨k, hk, hkst⟩ := List.mem_iff_getElem.1 hm
  have hloop : policies.denies_pass_loop sts a e 0#usize = ok true := by
    unfold policies.policy_is_allowed at h
    obtain ⟨b, hb, hk2⟩ := bind_eq_ok.1 h
    cases b with
    | true => exact hb
    | false => simp at hk2
  unfold policies.denies_pass_loop at hloop
  have := loop_idx_ok (policies.denies_pass_loop.body sts a e) id sts.val.length
    (fun i => i.val ≤ k) (fun y => y = true → False) ?_ 0#usize true (by simp) (by simp) hloop
  · exact this rfl
  intro i r hi hn hr
  unfold policies.denies_pass_loop.body at hr
  simp only [id] at *
  h5i_invert hr
  · obtain ⟨_, hsi⟩ := slice_index_ok hs_1
    have h2 := add_ok_val hi2
    have hne : i.val ≠ k := by
      rintro rfl
      rw [hkst] at hsi; subst hsi
      rw [hs] at hb1; simp at hb1; subst hb1; simp at hc_2
    simp only; refine ⟨?_, ?_, ?_⟩ <;> simp at h2 <;> omega
  · simp
  · obtain ⟨_, hsi⟩ := slice_index_ok hs_1
    have h2 := add_ok_val hi2
    have hne : i.val ≠ k := by
      rintro rfl
      rw [hkst] at hsi; subst hsi
      rw [hd] at hb; simp [stmts.Effect.Insts.CoreCmpPartialEqEffect.eq] at hb
      subst hb; simp at hc_1
    simp only; refine ⟨?_, ?_, ?_⟩ <;> simp at h2 <;> omega
  · exfalso; apply hc; scalar_tac

end rustfs_kernel.Solution
