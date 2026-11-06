import Verified.Tables
/-!
# One lemma per handler: what a successful run writes and why it succeeded
-/
open Aeneas Aeneas.Std Result atuin_kernel atuin_kernel.Spec
open H5iAppLib hiding lit

namespace atuin_kernel.Verified

theorem push_ok_val {α : Type} {v : alloc.vec.Vec α} {x : α} {w : alloc.vec.Vec α}
    (h : v.push x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  simp only [] at h
  split at h
  · have := H5iAppLib.Result.ok.inj h
    subst this; simp
  · simp at h

theorem verify_ok {c : Crypto} {a b : Slice U8} {r : Bool} (h : verify c a b = ok r) :
    r = decide (Verify c a.val b.val) := by
  have h' := post_of_ok (verify_spec c a b) h
  exact h'

theorem clone_ok {v w : alloc.vec.Vec U8} (h : alloc.vec.CloneVec.clone core.clone.CloneU8 v = ok w) : w = v := by
  rw [u8vec_clone] at h; exact (H5iAppLib.Result.ok.inj h).symm

theorem register_ok {cfg : Config} {s : Snapshot} {n e h t : alloc.vec.Vec U8} {ws rep}
    (hr : register cfg s n e h t = ok (.Ok (ws, rep))) :
      cfg.open_registration = true ∧ ValidUsername n.val ∧ Fresh s n.val e.val h.val t.val ∧
      ws.val = [.AddUser { id := s.next_user_id, username := n, email := e, password := h },
                .AddSession { id := s.next_session_id, user_id := s.next_user_id, token := t }] ∧
      rep = .Session t := by
  unfold register at hr
  h5i_invert hr
  obtain ⟨rfl, rfl⟩ := hr
  have h1 := post_of_ok (valid_username_spec _) hb
  have h2 := post_of_ok (user_conflict_spec _ _ _ _) hb1
  have h3 := post_of_ok (token_taken_spec _ _) hb2
  have e1 := clone_ok hv; have e2 := clone_ok hv1; have e3 := clone_ok hv2; have e4 := clone_ok hv3
  subst e1 e2 e3 e4
  have w1 := push_ok_val hws_1; have w2 := push_ok_val hws1
  refine ⟨hc, by simpa [hc_1] using h1, ⟨?_, ?_⟩, by simp [w1, w2], rfl⟩
  · intro x hx
    have h2' := h2.symm; simp [hc_2] at h2'
    exact h2' x hx
  · intro x hx
    have h3' := h3.symm; simp [hc_3] at h3'
    exact h3' x hx

theorem login_ok {c : Crypto} {s : Snapshot} {n pw : alloc.vec.Vec U8} {ws rep}
    (hr : login c s n pw = ok (.Ok (ws, rep))) : ws.val = [] ∧
      ∃ u ∈ s.users.val, u.username.val = n.val ∧ Verify c u.password.val pw.val ∧
        ∃ x ∈ s.sessions.val, x.user_id = u.id ∧ rep = .Session x.token := by
  unfold login at hr
  h5i_invert hr
  obtain ⟨rfl, rfl⟩ := hr
  have h1 := post_of_ok (find_user_by_name_spec _ _) ho
  have h2 := post_of_ok (find_session_by_user_spec _ _) ho1
  have h3 := verify_ok hb
  refine ⟨vec_new_val _, u, List.mem_of_find?_eq_some h1.symm, ?_, by simp_all, sess,
    List.mem_of_find?_eq_some h2.symm, ?_, rfl⟩
  · have := List.find?_some h1.symm; simpa using this
  · have := List.find?_some h2.symm; simpa using this

theorem get_user_ok {s : Snapshot} {n : alloc.vec.Vec U8} {ws rep}
    (hr : get_user s n = ok (.Ok (ws, rep))) : ws.val = [] ∧
      ∃ u ∈ s.users.val, u.username.val = n.val ∧ rep = .Username u.username := by
  unfold get_user at hr
  h5i_invert hr
  obtain ⟨rfl, rfl⟩ := hr
  have h1 := post_of_ok (find_user_by_name_spec _ _) ho
  refine ⟨vec_new_val _, u, List.mem_of_find?_eq_some h1.symm, ?_, rfl⟩
  have := List.find?_some h1.symm; simpa using this

theorem delete_account_ok {c : Crypto} {u : User} {pw : alloc.vec.Vec U8} {ws rep}
    (hr : delete_account c u pw = ok (.Ok (ws, rep))) :
      Verify c u.password.val pw.val ∧ ws.val = [.DeleteUser u.id] ∧ rep = .Empty := by
  unfold delete_account at hr
  h5i_invert hr
  obtain ⟨rfl, rfl⟩ := hr
  refine ⟨?_, by simpa using push_ok_val hws_1, rfl⟩
  have := verify_ok hb; simp_all

theorem change_password_ok {c : Crypto} {s : Snapshot} {u : User} {cur h : alloc.vec.Vec U8} {ws rep}
    (hr : change_password c s u cur h = ok (.Ok (ws, rep))) :
      Verify c u.password.val cur.val ∧ (∀ x ∈ s.users.val, x.id ≠ u.id → x.password.val ≠ h.val) ∧
      ws.val = [.SetPassword u.id h] ∧ rep = .Empty := by
  unfold change_password at hr
  h5i_invert hr
  obtain ⟨rfl, rfl⟩ := hr
  have h3 := verify_ok hb
  have h2 := post_of_ok (hash_taken_by_other_spec _ _ _) hb1
  have e1 := clone_ok hv; subst e1
  refine ⟨by simp_all, ?_, by simp [push_ok_val hws_1], rfl⟩
  intro x hx hne
  have h2' := h2.symm; simp [hc_1] at h2'
  exact h2' x hx (fun h => hne (UScalar.eq_of_val_eq h))

end atuin_kernel.Verified
