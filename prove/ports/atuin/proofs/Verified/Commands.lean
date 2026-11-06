import Verified.Tables
/-!
# One lemma per handler: what a successful run writes and why it succeeded
-/
open Aeneas Aeneas.Std Result atuin_kernel atuin_kernel.Spec
open H5iAppLib hiding lit

namespace atuin_kernel.Verified

theorem register_spec (cfg : Config) (s : Snapshot) (n e h t : alloc.vec.Vec U8) :
    register cfg s n e h t ⦃ r => ∀ ws rep, r = .Ok (ws, rep) →
      cfg.open_registration = true ∧ ValidUsername n.val ∧ Fresh s n.val e.val h.val t.val ∧
      ws.val = [.AddUser { id := s.next_user_id, username := n, email := e, password := h },
                .AddSession { id := s.next_session_id, user_id := s.next_user_id, token := t }] ∧
      rep = .Session t ⦄ := by
  unfold register
  step*
  all_goals (try simp_all)
  rename_i hopen _ _ _ _ _ hc _ _ ht _ _ _ _ _ _ _ _ _ _
  sorry

theorem login_spec (c : Crypto) (s : Snapshot) (n pw : alloc.vec.Vec U8) :
    login c s n pw ⦃ r => ∀ ws rep, r = .Ok (ws, rep) → ws.val = [] ∧
      ∃ u ∈ s.users.val, u.username.val = n.val ∧ Verify c u.password.val pw.val ∧
        ∃ x ∈ s.sessions.val, x.user_id = u.id ∧ rep = .Session x.token ⦄ := by
  unfold login
  step*
  all_goals sorry

end atuin_kernel.Verified
