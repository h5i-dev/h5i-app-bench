import Verified.Derived
import Spec
/-!
# Ownership rights (`Rights::get`)
-/
open Aeneas Aeneas.Std Result cratesio_kernel cratesio_kernel.Spec
open H5iAppLib hiding Covers
open Aeneas.Std.WP

namespace cratesio_kernel.Verified.Rights

/-- GitHub's answer for a team (the first one listed; none: not a member). -/
def answerOf (answers : List (I64 × rights.Membership)) (t : I64) : rights.Membership :=
  ((answers.find? (fun a => a.1 = t)).map (·.2)).getD .NotMember

@[step] theorem membership_of_spec (answers : Slice (I64 × rights.Membership)) (t : I64) :
    rights.membership_of answers t ⦃ m => answerOf answers.val t = m ⦄ := by
  unfold rights.membership_of rights.membership_of_loop
  apply WP.spec_mono (loop_search answers.val (fun a => decide (a.1 = t))
    (fun m : rights.Membership => m) (fun _ a => a.2) .NotMember _ ?_ 0#usize (by simp))
  · intro r hr
    rw [hr, searchFrom_findD]
    simp [answerOf]
  · intro j hj; unfold rights.membership_of_loop.body; h5i_step
    · left; refine ⟨by scalar_tac, ?_, ?_⟩ <;> rw [← i2_post]
    · refine ⟨by scalar_tac, ?_⟩
      rw [← i2_post]; intro h; apply ‹¬ _›; scalar_tac

/-- A team owner the user is an active member of, with GitHub credentials. -/
def ViaTeam (user : rights.Actor) (has_auth : Bool) (owners : List rights.Owner)
    (answers : List (I64 × rights.Membership)) : Prop :=
  ∃ t, rights.Owner.Team t ∈ owners ∧ answerOf answers t = .Active ∧ has_auth = true ∧ user.gh_login = true

theorem owner_step_facts (user : rights.Actor) (has_auth : Bool) (o : rights.Owner)
    (answers : Slice (I64 × rights.Membership)) (c : U8)
    (h : rights.owner_step user has_auth o answers = ok c) :
    (c.val = 2 → o = .User user.id) ∧
    (c.val = 1 → ∃ t, o = .Team t ∧ answerOf answers.val t = .Active ∧ has_auth = true ∧ user.gh_login = true) := by
  unfold rights.owner_step at h
  rcases o with id | t
  · simp only at h
    split at h <;> (have := Result.ok.inj h; subst this) <;> simp_all
  · simp only at h
    cases hga : has_auth <;> cases hgl : user.gh_login <;>
      simp only [hga, hgl, Bool.false_eq_true, if_false, if_true] at h
    · have := Result.ok.inj h; subst this; simp
    · have := Result.ok.inj h; subst this; simp
    · have := Result.ok.inj h; subst this; simp
    · rw [eq_of_spec' (membership_of_spec answers t)] at h
      try simp only [bind_tc_ok] at h
      rcases hm : answerOf answers.val t <;> rw [hm] at h <;> simp only [bind_ok] at h <;> (have := Result.ok.inj h; subst this) <;>
        simp_all
where
  eq_of_spec' {α} {m : Result α} {v : α} (h : m ⦃ x => v = x ⦄) : m = ok v := by
    obtain ⟨x, hx⟩ := ok_of h
    rw [hx, post_of_ok h hx]

end cratesio_kernel.Verified.Rights
