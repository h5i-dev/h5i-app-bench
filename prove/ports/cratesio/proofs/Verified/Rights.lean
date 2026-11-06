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

/-- The result of the owner loop: full rights only through a user entry for
this user, publish rights only through an active team membership. -/
theorem rights_loop_ok (user : rights.Actor) (ha : Bool) (owners : Slice rights.Owner)
    (answers : Slice (I64 × rights.Membership)) (r : rights.Rights)
    (h : rights.rights_loop user ha owners answers = ok (.Ok r)) :
    (r = .Full → rights.Owner.User user.id ∈ owners.val) ∧
    (r = .Publish → ViaTeam user ha owners.val answers.val) := by
  unfold rights.rights_loop rights.rights_loop_loop at h
  refine loop_ok (fun x => rights.rights_loop_loop.body user ha owners answers x.1 x.2)
    (fun x => (x.1 = .Publish → ViaTeam user ha owners.val answers.val) ∧ x.1 ≠ .Full)
    (fun y => ∀ r, y = .Ok r → (r = .Full → rights.Owner.User user.id ∈ owners.val) ∧
      (r = .Publish → ViaTeam user ha owners.val answers.val))
    (fun x => owners.val.length - x.2.val) ?_ (.None, 0#usize) _ (by simp) h r rfl
  rintro ⟨best, i⟩ res ⟨hinv, hnf⟩ hb
  unfold rights.rights_loop_loop.body at hb
  h5i_invert hb
  · -- c = 2: full rights from this user's own entry
    intro r' hr'; cases hr'
    have hf := (owner_step_facts _ _ _ _ _ hc_1).1 (by simp_all)
    have hm := slice_index_ok_mem ho
    simp only [true_implies, reduceCtorEq, false_implies, and_true]
    rw [← hf]; exact hm
  all_goals first
    | (simp only; intro r' hr'; cases hr')
    | skip
  · -- continue, with publish rights if this entry is an active team
    h5i_ok_facts
    simp only
    by_cases h1 : c = 1#u8
    · simp only [h1, if_true] at hbest1
      have := Result.ok.inj hbest1; subst this
      have hf := (owner_step_facts _ _ _ _ _ hc_1).2 (by rw [h1]; rfl)
      obtain ⟨t, rfl, hact, hha, hgl⟩ := hf
      have hm := slice_index_ok_mem ho
      refine ⟨⟨fun _ => ⟨t, hm, hact, hha, hgl⟩, by simp⟩, by scalar_tac⟩
    · simp only [h1, if_false] at hbest1
      have := Result.ok.inj hbest1; subst this
      refine ⟨⟨hinv, hnf⟩, by scalar_tac⟩
  · -- the end: the best seen
    exact ⟨fun e => absurd e hnf, hinv⟩

/-- `Rights::get`: full rights only as a listed user owner; publish rights
only through an owning team the user is an active member of, with a GitHub
token that decrypts and a GitHub login. -/
theorem rights_ok (user : rights.Actor) (owners : Slice rights.Owner)
    (answers : Slice (I64 × rights.Membership)) (r : rights.Rights)
    (h : rights.rights user owners answers = ok (.Ok r)) :
    (r = .Full → rights.Owner.User user.id ∈ owners.val) ∧
    (r = .Publish → ∃ t, rights.Owner.Team t ∈ owners.val ∧ answerOf answers.val t = .Active ∧
      user.gh_token = some true ∧ user.gh_login = true) := by
  unfold rights.rights at h
  rcases hg : user.gh_token with _ | ok' <;> simp only [hg] at h
  · obtain ⟨h1, h2⟩ := rights_loop_ok _ _ _ _ _ h
    refine ⟨h1, fun hp => ?_⟩
    obtain ⟨t, -, -, hf, -⟩ := h2 hp; cases hf
  · cases ok' <;> simp only [Bool.false_eq_true, if_false, if_true] at h
    · simp at h
    · obtain ⟨h1, h2⟩ := rights_loop_ok _ _ _ _ _ h
      refine ⟨h1, fun hp => ?_⟩
      obtain ⟨t, hm, ha, -, hl⟩ := h2 hp
      exact ⟨t, hm, ha, rfl, hl⟩

end cratesio_kernel.Verified.Rights
