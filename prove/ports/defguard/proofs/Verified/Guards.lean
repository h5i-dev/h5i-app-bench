import Verified.Lockout
/-!
# The API's authentication guards
-/
open Aeneas Aeneas.Std Result defguard_kernel defguard_kernel.Spec
open H5iAppLib

namespace defguard_kernel.Verified

theorem state_eq_ok {a b : auth.SessionState} {r : Bool}
    (h : auth.SessionState.Insts.CoreCmpPartialEqSessionState.eq a b = ok r) : r = decide (a = b) := by
  have h' := post_of_ok (auth.SessionState.Insts.CoreCmpPartialEqSessionState.eq.spec a b) h
  exact h'

theorem state_ne_ok {a b : auth.SessionState} {r : Bool}
    (h : core.cmp.PartialEq.ne.trait_default auth.SessionState.Insts.CoreCmpPartialEqSessionState a b = ok r) :
    r = !decide (a = b) := by
  unfold core.cmp.PartialEq.ne.trait_default at h
  obtain ⟨x, hx, h'⟩ := H5iAppLib.bind_tc_eq_ok.1 h
  have := state_eq_ok hx
  have e := (H5iAppLib.Result.ok.inj h').symm
  subst this; simpa using e

instance (u : auth.User) (names : List (alloc.vec.Vec U8)) : Decidable (IsAdmin u names) := by
  unfold IsAdmin; infer_instance

@[step] theorem contains_name_spec (names : alloc.vec.Vec (alloc.vec.Vec U8)) (n : Slice U8) :
    auth.contains_name names n ⦃ b => b = names.val.any (fun a => decide (a.val = n.val)) ⦄ := by
  unfold auth.contains_name auth.contains_name_loop
  h5i_search_any names.val (fun (a : alloc.vec.Vec U8) => decide (a.val = n.val))

@[step] theorem contains_any_group_spec (u : auth.User) (names : alloc.vec.Vec (alloc.vec.Vec U8)) :
    auth.contains_any_group u names ⦃ b => b = decide (IsAdmin u names.val) ⦄ := by
  unfold auth.contains_any_group auth.contains_any_group_loop
  apply WP.spec_mono (H5iAppLib.loop_search u.groups.val
    (fun (g : alloc.vec.Vec U8) => names.val.any (fun a => decide (a.val = g.val))) id
    (fun _ _ => true) false _ ?step 0#usize (by simp))
  · intro r hr; simp only [id] at hr; rw [hr, H5iAppLib.searchFrom_const]
    simp [IsAdmin]
  case step =>
    intro j hj; unfold auth.contains_any_group_loop.body; h5i_step

theorem find_user_ok {us : alloc.vec.Vec auth.User} {id : U64} {o : Option auth.User}
    (h : auth.find_user us id = ok o) : o = us.val.find? (fun u => decide (u.id = id)) := by
  have hs : auth.find_user us id ⦃ o => o = us.val.find? (fun u => decide (u.id = id)) ⦄ := by
    unfold auth.find_user auth.find_user_loop
    h5i_search_find us.val (fun (u : auth.User) => decide (u.id = id))
  have h' := post_of_ok hs h
  exact h'

/-- What a successful `SessionExtractor` stands on. -/
theorem extract_session_ok {lic : Bool} {cred : auth.Credential} {now : I64} {s : auth.Session}
    (h : auth.extract_session lic cred now = ok (.Ok s)) : Presents lic cred now.val s := by
  unfold auth.extract_session at h
  h5i_invert h
  · exact ⟨hc, rfl, rfl⟩
  · have e1 : b = decide (s_1.expires < now) := by
      unfold auth.expired at hb; exact (H5iAppLib.Result.ok.inj hb).symm
    rw [auth.Session.Insts.CoreCloneClone.clone.ok_eq] at hs1
    have e2 := (H5iAppLib.Result.ok.inj hs1); subst e2
    refine ⟨rfl, ?_⟩
    simp_all

/-- What a successful `SessionInfo` guarantees. -/
theorem session_info_ok {lic : Bool} {cred : auth.Credential} {us : alloc.vec.Vec auth.User}
    {ag : alloc.vec.Vec (alloc.vec.Vec U8)} {now : I64} {info : auth.Info}
    (h : auth.session_info lic cred us ag now = ok (.Ok info)) :
    Presents lic cred now.val info.session ∧ info.user ∈ us.val ∧ info.user.id = info.session.user_id ∧
    (info.is_admin = true ↔ IsAdmin info.user ag.val) ∧
    (info.user.mfa_enabled = true →
      info.session.state = .MultiFactorVerified ∨ info.session.state = .ApiTokenVerified) ∧
    (info.session.state = .ApiTokenVerified → IsAdmin info.user ag.val) := by
  unfold auth.session_info at h
  h5i_invert h
  all_goals (
    have hp := extract_session_ok hr
    have hu := find_user_ok ho
    have hmem := List.mem_of_find?_eq_some hu.symm
    have hid := List.find?_some hu.symm
    (try have e1 := state_ne_ok hb)
    (try have e5 := state_eq_ok hb)
    (try have e2 := state_ne_ok hb1)
    (try have e3 := state_eq_ok hb1)
    (try have e4 := state_eq_ok hb2)
    have ea := post_of_ok (contains_any_group_spec _ _) his_admin
    simp only [decide_eq_true_eq] at hid
    refine ⟨hp, hmem, hid, ?_, ?_, ?_⟩ <;> simp_all)

/-- `AdminRole`: an active member of an admin group, on top of `SessionInfo`. -/
theorem admin_role_ok {lic : Bool} {cred : auth.Credential} {us : alloc.vec.Vec auth.User}
    {ag : alloc.vec.Vec (alloc.vec.Vec U8)} {now : I64} {info : auth.Info}
    (h : auth.admin_role lic cred us ag now = ok (.Ok info)) :
    auth.session_info lic cred us ag now = ok (.Ok info) ∧ info.user.is_active = true ∧ IsAdmin info.user ag.val := by
  unfold auth.admin_role at h
  obtain ⟨r, hr, h2⟩ := H5iAppLib.bind_tc_eq_ok.1 h
  cases r with
  | Err e => simp at h2
  | Ok i =>
    simp only [] at h2
    split at h2
    · rename_i hact
      obtain ⟨b, hb, h3⟩ := H5iAppLib.bind_tc_eq_ok.1 h2
      have ea := post_of_ok (contains_any_group_spec _ _) hb
      split at h3
      · have := H5iAppLib.Result.ok.inj h3; simp only [core.result.Result.Ok.injEq] at this; subst this
        exact ⟨hr, hact, by simp_all⟩
      · simp at h3
    · simp at h2

theorem find_user_by_name_ok {us : alloc.vec.Vec auth.User} {n : Slice U8} {o : Option auth.User}
    (h : auth.find_user_by_name us n = ok o) : o = us.val.find? (fun u => decide (u.username.val = n.val)) := by
  have hs : auth.find_user_by_name us n ⦃ o => o = us.val.find? (fun u => decide (u.username.val = n.val)) ⦄ := by
    unfold auth.find_user_by_name auth.find_user_by_name_loop
    h5i_search_find us.val (fun (u : auth.User) => decide (u.username.val = n.val))
  have h' := post_of_ok hs h
  exact h'

/-- `user_for_admin_or_self`: the user named, and only the caller's own
account unless the caller is an admin. -/
theorem user_for_admin_or_self_ok {info : auth.Info} {us : alloc.vec.Vec auth.User} {n : Slice U8} {u : auth.User}
    (h : auth.user_for_admin_or_self info us n = ok (.Ok u)) :
    u ∈ us.val ∧ u.username.val = n.val ∧ (n.val = info.user.username.val ∨ info.is_admin = true) := by
  unfold auth.user_for_admin_or_self at h
  h5i_invert h
  all_goals (
    have hb' := post_of_ok (bytes_eq_spec _ _) hb
    have hf := find_user_by_name_ok ho
    have hmem := List.mem_of_find?_eq_some hf.symm
    have hn := List.find?_some hf.symm
    simp only [decide_eq_true_eq] at hn
    refine ⟨hmem, hn, ?_⟩
    simp_all)

/-- `device_for_admin_or_self`: the device asked for, and only the caller's
own unless the caller is an admin. -/
theorem device_for_admin_or_self_ok {info : auth.Info} {ds : alloc.vec.Vec auth.Device} {id : U64} {d : auth.Device}
    (h : auth.device_for_admin_or_self info ds id = ok (.Ok d)) :
    d ∈ ds.val ∧ d.id = id ∧ (d.user_id = info.user.id ∨ info.is_admin = true) := by
  unfold auth.device_for_admin_or_self auth.device_for_admin_or_self_loop at h
  refine H5iAppLib.loop_idx_ok _ (fun i => i) ds.val.length (fun _ => True)
    (fun r => ∀ d, r = .Ok d → d ∈ ds.val ∧ d.id = id ∧ (d.user_id = info.user.id ∨ info.is_admin = true))
    ?_ 0#usize _ trivial (by simp) h d rfl
  intro i r _ hi hb
  unfold auth.device_for_admin_or_self_loop.body at hb
  h5i_invert hb
  all_goals (simp only [])
  all_goals (try (refine ⟨trivial, ?_, ?_⟩ <;> (have := H5iAppLib.add_ok_val hi2; scalar_tac)))
  all_goals (try (intro d' hd'; simp at hd'; done))
  all_goals (
    intro d' hd'
    simp only [core.result.Result.Ok.injEq] at hd'
    subst hd'
    rw [auth.Device.Insts.CoreCloneClone.clone.ok_eq] at hd1
    have e := (H5iAppLib.Result.ok.inj hd1); subst e
    have hl : i.val < ds.val.length := by scalar_tac
    rw [vec_index_eq _ _ hl] at hd_1
    have e := (H5iAppLib.Result.ok.inj hd_1); subst e
    exact ⟨List.getElem_mem _, hc_1, by simp_all⟩)

end defguard_kernel.Verified
