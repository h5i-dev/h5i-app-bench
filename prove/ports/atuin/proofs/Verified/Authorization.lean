import Verified.Commands
/-!
# Every write of a successful request is allowed by the policy
-/
open Aeneas Aeneas.Std Result atuin_kernel atuin_kernel.Spec
open H5iAppLib hiding lit

namespace atuin_kernel.Verified

theorem authenticate_ok {s : Snapshot} {h : Option (alloc.vec.Vec U8)} {u : User}
    (hr : authenticate s h = ok (.Ok u)) : Authenticated s h u :=
  post_of_ok (authenticate_spec s h) hr u rfl

/-- A successful request either registers, or is authenticated and makes
the writes of its handler, or writes nothing. -/
theorem transition_writes {cfg : Config} {c : Crypto} {s : Snapshot} {req : Request} {ws rep}
    (h : transition cfg c s req = ok (.Ok (ws, rep))) :
    (∃ n e hh t, req.command = .Register n e hh t ∧ cfg.open_registration = true ∧ ValidUsername n.val ∧
        Fresh s n.val e.val hh.val t.val ∧
        ws.val = [.AddUser { id := s.next_user_id, username := n, email := e, password := hh },
                  .AddSession { id := s.next_session_id, user_id := s.next_user_id, token := t }] ∧
        rep = .Session t) ∨
    (∃ u, Authenticated s req.authorization u ∧ AuthedWrites cfg c s u req.command ws.val) ∨
    ws.val = [] := by
  unfold transition at h
  split at h
  · exact Or.inr (Or.inr (get_user_ok h).1)
  · rename_i n e hh t heq
    obtain ⟨h1, h2, h3, h4, h5⟩ := register_ok h
    exact Or.inl ⟨n, e, hh, t, heq, h1, h2, h3, h4, h5⟩
  · exact Or.inr (Or.inr (login_ok h).1)
  all_goals
    h5i_invert h
    exact Or.inr (Or.inl ⟨_, authenticate_ok hr, authed_ok h⟩)

theorem authorized (cfg : Config) (c : Crypto) (s : Snapshot) (req : Request) (ws : alloc.vec.Vec Write)
    (rep : Reply) (h : transition cfg c s req = ok (.Ok (ws, rep))) :
    ∀ w ∈ ws.val, allowed cfg c s req w := by
  intro w hw
  rcases transition_writes h with ⟨n, e, hh, t, hc, h1, h2, h3, h4, _⟩ | ⟨u, hu, hw'⟩ | h0
  · rw [h4] at hw
    simp only [List.mem_cons, List.not_mem_nil, or_false] at hw
    rcases hw with rfl | rfl
    · exact ⟨n, e, hh, t, hc, h1, h2, h3, rfl⟩
    · exact ⟨n, e, hh, t, hc, h1, h2, h3, rfl⟩
  · cases hcmd : req.command with
    | DeleteAccount pw =>
      rw [hcmd] at hw'; obtain ⟨hv, hws⟩ := hw'
      rw [hws] at hw; simp only [List.mem_cons, List.not_mem_nil, or_false] at hw; subst hw
      exact ⟨u, hu, rfl, pw, hcmd, hv⟩
    | ChangePassword cur hh =>
      rw [hcmd] at hw'; obtain ⟨hv, hother, hws⟩ := hw'
      rw [hws] at hw; simp only [List.mem_cons, List.not_mem_nil, or_false] at hw; subst hw
      exact ⟨u, hu, rfl, cur, hcmd, hv, hother⟩
    | PostRecords rs =>
      rw [hcmd] at hw'; obtain ⟨hfit, hws⟩ := hw'
      rw [hws, List.mem_map] at hw; obtain ⟨r, hr, rfl⟩ := hw
      exact ⟨u, hu, rs, hcmd, hfit, r, hr, rfl⟩
    | DeleteStore =>
      rw [hcmd] at hw'
      rw [hw'] at hw; simp only [List.mem_cons, List.not_mem_nil, or_false] at hw; subst hw
      exact ⟨u, hu, rfl, hcmd⟩
    | GetUser _ | Register _ _ _ _ | Login _ _ | Me | Status | Next _ _ _ _ =>
      rw [hcmd] at hw'; simp [AuthedWrites] at hw'; simp [hw'] at hw
  · simp [h0] at hw

end atuin_kernel.Verified
