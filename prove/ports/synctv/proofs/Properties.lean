import Lemmas
import PathLemmas
/-!
# Security properties of synctv's room permissions, member policy and tokens

Each theorem is about the extracted kernel and the policy in `Spec.lean`.
-/
open Aeneas Aeneas.Std Result synctv_kernel synctv_kernel.Spec synctv_kernel.Lemmas synctv_kernel.PathLemmas H5iAppLib

namespace synctv_kernel.Properties

/-! ## Permission sets and effective permissions -/

/-- `RoomPermissionSet::has` tests exactly the permission's bit, and never fails. -/
theorem has_correct (s : U64) (p : perms.RoomPermission) :
    ∃ b, perms.has s p = ok b ∧ (b = true ↔ grants s.val p) :=
  has_spec s p

/-- `RoomMember::effective_permissions` is the allow/deny policy of `Spec.effective`
for every role, every override column value (including undefined bits) and every
role default, and never fails. -/
theorem effective_permissions_correct (m : perms.MemberPerms) (d : U64) :
    ∃ e, perms.effective_permissions m d = ok e ∧
      ∀ p, (grants e.val p ↔ effective m (grants d.val) p) :=
  effective_spec m d

/-- `EffectivePermissionCalculator::role_default` is `Spec.roleDefault`. -/
theorem role_default_correct (d : perms.Defaults) (r : perms.Role) (s : perms.SettingsPerms) :
    ∃ x, perms.role_default d r s = ok x ∧ ∀ p, (grants x.val p ↔ roleDefault d s r p) :=
  role_default_spec d r s

/-- `EffectivePermissionCalculator::has_permission` is `Spec.calcHas`. -/
theorem calculator_correct (d : perms.Defaults) (m : perms.MemberPerms) (s : perms.SettingsPerms)
    (p : perms.RoomPermission) :
    ∃ b, perms.calculator_has_permission d m s p = ok b ∧ (b = true ↔ calcHas d s m p) :=
  calculator_spec d m s p

/-- A guest never holds a permission outside the four guest-assignable ones
(view members, view chat history, voice chat, P2P media), whatever the server
defaults, the room's settings and the guest's own override columns contain. -/
theorem guest_confined (d : perms.Defaults) (m : perms.MemberPerms) (s : perms.SettingsPerms)
    (p : perms.RoomPermission) (hg : m.role = .Guest)
    (h : perms.calculator_has_permission d m s p = ok true) : guestAssignable p := by
  have := (calc_true h).2
  simp only [effective, hg, allowDeny] at this
  rcases this.1 with ⟨_, hga⟩ | hn
  · exact hga
  · exact names_guest_assignable hn

/-- The same for the effective permission set itself, for any role default. -/
theorem guest_effective_confined (m : perms.MemberPerms) (d e : U64) (p : perms.RoomPermission)
    (hg : m.role = .Guest) (he : perms.effective_permissions m d = ok e) (hp : grants e.val p) :
    guestAssignable p := by
  obtain ⟨e', he', hE⟩ := effective_spec m d
  rw [he, Result.ok.injEq] at he'
  subst he'
  have := (hE p).1 hp
  simp only [effective, hg, allowDeny] at this
  rcases this.1 with ⟨_, hga⟩ | hn
  · exact hga
  · exact names_guest_assignable hn

/-- A member's own override columns can only add or remove the seven
member-assignable permissions: for any other permission (deleting media, removing
members, room settings, deleting the room, ...) a member has it exactly when the
role default grants it. -/
theorem member_overrides_confined (m : perms.MemberPerms) (d : U64) (p : perms.RoomPermission)
    (hm : m.role = .Member) (hp : memberBit p = none) :
    ∃ e, perms.effective_permissions m d = ok e ∧ (grants e.val p ↔ grants d.val p) := by
  obtain ⟨e, he, hE⟩ := effective_spec m d
  refine ⟨e, he, ?_⟩
  rw [hE p]
  simp only [effective, hm, allowDeny]
  have h1 := names_none (bits := m.added_permissions.val) hp
  have h2 := names_none (bits := m.removed_permissions.val) hp
  tauto

/-- Room settings likewise only move member-assignable permissions in or out of
the member role default. -/
theorem member_default_confined (d : perms.Defaults) (s : perms.SettingsPerms) (p : perms.RoomPermission)
    (hp : memberBit p = none) :
    ∃ x, perms.role_default d .Member s = ok x ∧ (grants x.val p ↔ grants d.member.val p) := by
  obtain ⟨x, hx, hX⟩ := role_default_spec d .Member s
  refine ⟨x, hx, ?_⟩
  rw [hX p]
  simp only [roleDefault, allowDeny]
  have h1 := names_none (bits := s.member_added_permissions.val) hp
  have h2 := names_none (bits := s.member_removed_permissions.val) hp
  tauto

/-- An admin's permissions do not depend on the plain (member/guest) override
columns: each role reads only its own override channel. -/
theorem admin_ignores_plain_columns (m : perms.MemberPerms) (d a r : U64) (p : perms.RoomPermission)
    (hr : m.role = .Admin) :
    ∃ e e', perms.effective_permissions m d = ok e ∧
      perms.effective_permissions { m with added_permissions := a, removed_permissions := r } d = ok e' ∧
      (grants e.val p ↔ grants e'.val p) := by
  obtain ⟨e, he, hE⟩ := effective_spec m d
  obtain ⟨e', he', hE'⟩ := effective_spec { m with added_permissions := a, removed_permissions := r } d
  refine ⟨e, e', he, he', ?_⟩
  rw [hE p, hE' p]
  simp [effective, hr]

/-- A member's or guest's permissions do not depend on the admin override columns. -/
theorem non_admin_ignores_admin_columns (m : perms.MemberPerms) (d a r : U64) (p : perms.RoomPermission)
    (hr : m.role = .Member ∨ m.role = .Guest) :
    ∃ e e', perms.effective_permissions m d = ok e ∧
      perms.effective_permissions { m with admin_added_permissions := a, admin_removed_permissions := r } d = ok e' ∧
      (grants e.val p ↔ grants e'.val p) := by
  obtain ⟨e, he, hE⟩ := effective_spec m d
  obtain ⟨e', he', hE'⟩ := effective_spec { m with admin_added_permissions := a, admin_removed_permissions := r } d
  refine ⟨e, e', he, he', ?_⟩
  rw [hE p, hE' p]
  rcases hr with hr | hr <;> simp [effective, hr]

/-- Deny wins: a permission removed by the member's own override column (in the
bitspace of its role) is never held, whatever the defaults and settings grant. -/
theorem removed_never_held (d : perms.Defaults) (m : perms.MemberPerms) (s : perms.SettingsPerms)
    (p : perms.RoomPermission)
    (hrem : (m.role = .Admin ∧ names adminSpace m.admin_removed_permissions.val p) ∨
            (m.role = .Member ∧ names memberBit m.removed_permissions.val p) ∨
            (m.role = .Guest ∧ names guestBit m.removed_permissions.val p)) :
    perms.calculator_has_permission d m s p = ok false := by
  obtain ⟨b, hb, hiff⟩ := calculator_spec d m s p
  rw [hb]
  cases b
  · rfl
  · exfalso
    have := (hiff.1 rfl).2
    rcases hrem with ⟨hr, hn⟩ | ⟨hr, hn⟩ | ⟨hr, hn⟩ <;> simp only [effective, hr, allowDeny] at this <;>
      exact this.2 hn

/-- The room creator holds every permission. -/
theorem creator_holds_all (d : perms.Defaults) (m : perms.MemberPerms) (s : perms.SettingsPerms)
    (p : perms.RoomPermission) (hc : m.role = .Creator) :
    perms.calculator_has_permission d m s p = ok true := by
  obtain ⟨b, hb, hiff⟩ := calculator_spec d m s p
  rw [hb]
  cases b
  · exfalso
    have : calcHas d s m p := by simp [calcHas, effective, hc]
    exact absurd (hiff.2 this) (by simp)
  · rfl

/-- The compiled admin default withholds only `DeleteRoom`. -/
theorem default_admin_spec (p : perms.RoomPermission) :
    ∃ x, perms.default_admin = ok x ∧ (grants x.val p ↔ p ≠ .DeleteRoom) := by
  obtain ⟨x, hx, hX⟩ := admin_to_spec perms.A_DEFAULT
  refine ⟨x, by simp only [perms.default_admin, hx], ?_⟩
  unfold grants; rw [hX p]
  cases p <;> simp [names, adminSpace, adminBit, A_DEFAULT_val] <;> decide

/-- The compiled guest default grants nothing. -/
theorem default_guest_empty (p : perms.RoomPermission) :
    ∃ x, perms.default_guest = ok x ∧ ¬ grants x.val p := by
  obtain ⟨x, hx, hX⟩ := guest_to_spec perms.G_DEFAULT
  refine ⟨x, by simp only [perms.default_guest, hx], ?_⟩
  unfold grants; rw [hX p]
  simp [names, G_DEFAULT_val]

/-- The compiled member default grants exactly the member-assignable permissions. -/
theorem default_member_spec (p : perms.RoomPermission) :
    ∃ x, perms.default_member = ok x ∧ (grants x.val p ↔ memberAssignable p) := by
  obtain ⟨x, hx, hX⟩ := member_to_spec perms.M_ALL
  refine ⟨x, by simp only [perms.default_member, hx], ?_⟩
  unfold grants; rw [hX p]
  cases p <;> simp [names, memberBit, memberAssignable, M_ALL_val] <;> decide

/-- With the compiled server defaults, an admin can delete the room only if the room's
settings or the admin's own row explicitly add `DeleteRoom`. -/
theorem admin_delete_room_needs_explicit_grant (d : perms.Defaults) (m : perms.MemberPerms)
    (s : perms.SettingsPerms) (hd : perms.default_admin = ok d.admin) (ha : m.role = .Admin)
    (h : perms.calculator_has_permission d m s .DeleteRoom = ok true) :
    names adminSpace s.admin_added_permissions.val .DeleteRoom ∨
      names adminSpace m.admin_added_permissions.val .DeleteRoom := by
  have hc := (calc_true h).2
  obtain ⟨x, hx, hX⟩ := default_admin_spec .DeleteRoom
  rw [hd, Result.ok.injEq] at hx
  subst hx
  have hn : ¬ grants d.admin.val .DeleteRoom := fun g => (hX.1 g) rfl
  simp only [effective, ha, allowDeny, roleDefault] at hc
  tauto

/-- A plain member holds `DeleteRoom` only if the server-wide member default grants
it: neither room settings nor the member's row can add it. -/
theorem member_delete_room_only_from_server_default (d : perms.Defaults) (m : perms.MemberPerms)
    (s : perms.SettingsPerms) (hm : m.role = .Member)
    (h : perms.calculator_has_permission d m s .DeleteRoom = ok true) :
    grants d.member.val .DeleteRoom := by
  have hc := (calc_true h).2
  simp only [effective, hm, allowDeny, roleDefault] at hc
  have h1 := names_none (space := memberBit) (bits := m.added_permissions.val) (p := .DeleteRoom) rfl
  have h2 := names_none (space := memberBit) (bits := s.member_added_permissions.val) (p := .DeleteRoom) rfl
  tauto

/-- FINDING (info): the first test in `EffectivePermissionCalculator::has_permission`
(`member.has_permission(permission, RoomPermissionSet::all())`) never changes the
answer. Effective permissions over the real role default already imply it, so the
calculator returns exactly whether the effective permissions grant `p`. See
FINDINGS.md. -/
theorem calculator_precheck_redundant (d : perms.Defaults) (m : perms.MemberPerms) (s : perms.SettingsPerms)
    (p : perms.RoomPermission) :
    calcHas d s m p ↔ effective m (roleDefault d s m.role) p := by
  unfold calcHas
  refine ⟨fun h => h.2, fun h => ⟨?_, h⟩⟩
  unfold effective at h ⊢
  cases hr : m.role <;> simp only [hr, allowDeny] at h ⊢ <;> tauto

/-! ## Member role and override policy -/

/-- The creator role can never be conferred through role assignment. -/
theorem creator_role_never_assignable :
    policy.validate_role_can_be_assigned .Creator ≠ ok (.Ok ()) := by
  rw [Ne, role_assignable_iff]; simp

/-- Only the room creator may admit a member directly as admin, and nobody may admit
a creator. -/
theorem only_creator_admits_admins (c a : I64) (r : perms.Role)
    (h : policy.validate_add_member_role c a r = ok (.Ok ())) :
    r ≠ .Creator ∧ (r = .Admin → a = c) :=
  (add_member_role_iff c a r).1 h

/-- A member update that changes a role is only accepted from the room creator, never
targets the creator, and never confers the creator role. -/
theorem role_change_only_by_creator (u : policy.MemberUpdate) (ce : Bool) (cr : perms.Role) (re : Bool)
    (c : I64) (plan : policy.MemberUpdatePlan)
    (h : policy.plan_member_update u ce cr re c = ok (.Ok plan)) (hr : u.has_role = true) :
    roleUpdateAllowed c.val u.actor_id.val u.target_user_id.val u.role := by
  obtain ⟨-, -, -, -, h5, -⟩ := plan_sound u ce cr re c plan h
  obtain ⟨h1, h2, h3⟩ := h5 hr
  refine ⟨h1, by rw [h2], fun e => h3 (IScalar.eq_of_val_eq e)⟩

/-- Accepted permission overrides stay inside the bitspace of the member's (new)
role, and admin override columns inside the admin bitspace. -/
theorem overrides_stay_in_role_space (u : policy.MemberUpdate) (ce : Bool) (cr : perms.Role) (re : Bool)
    (c : I64) (plan : policy.MemberUpdatePlan)
    (h : policy.plan_member_update u ce cr re c = ok (.Ok plan)) :
    withinSpace 0 21 u.admin_added_permissions.val ∧ withinSpace 0 21 u.admin_removed_permissions.val ∧
    (u.apply_permission_update = true →
      let sp := roleSpace (if u.has_role then u.role else cr)
      withinSpace sp.1 sp.2 u.added_permissions.val ∧ withinSpace sp.1 sp.2 u.removed_permissions.val) := by
  obtain ⟨-, h2, h3, h4, -, h6⟩ := plan_sound u ce cr re c plan h
  refine ⟨h2, h3, fun ha => ?_⟩
  obtain ⟨-, h7, h8, -⟩ := h6 ha
  rw [h4] at h7 h8
  exact ⟨h7, h8⟩

/-- Admins are only changed through the admin override columns and everyone else
only through the plain columns; every permission update requires the actor to hold
`ManageMemberPermissions` (checked by the executor). -/
theorem override_channel_matches_role (u : policy.MemberUpdate) (ce : Bool) (cr : perms.Role) (re : Bool)
    (c : I64) (plan : policy.MemberUpdatePlan)
    (h : policy.plan_member_update u ce cr re c = ok (.Ok plan)) (ha : u.apply_permission_update = true) :
    plan.needs_manage_member_permissions = true ∧
    ((if u.has_role then u.role else cr) = .Admin → u.added_permissions.val = 0 ∧ u.removed_permissions.val = 0) ∧
    ((if u.has_role then u.role else cr) ≠ .Admin →
      u.admin_added_permissions.val = 0 ∧ u.admin_removed_permissions.val = 0) := by
  obtain ⟨-, -, -, h4, -, h6⟩ := plan_sound u ce cr re c plan h
  obtain ⟨h7, -, -, h9, h10⟩ := h6 ha
  rw [h4] at h9 h10
  exact ⟨h7, h9, h10⟩

/-- No update is planned for a target that is not a member. -/
theorem update_needs_existing_member (u : policy.MemberUpdate) (cr : perms.Role) (re : Bool) (c : I64)
    (plan : policy.MemberUpdatePlan) :
    policy.plan_member_update u false cr re c ≠ ok (.Ok plan) := by
  intro h
  have := (plan_sound u false cr re c plan h).1
  simp at this

/-- A kick cooldown is accepted only between one second and thirty days. -/
theorem kick_cooldown_bounded (c : I64) (h : policy.validate_kick_cooldown_seconds c = ok (.Ok ())) :
    0 < c.val ∧ c.val ≤ 30 * 24 * 60 * 60 :=
  (kick_cooldown_iff c).1 h

/-! ## Global roles -/

theorem can_manage_eq (a b : auth.UserRole) : ∃ x, auth.can_manage a b = ok x ∧ (x = true ↔ manages a b) := by
  cases a <;> cases b <;> simp [auth.can_manage, manages, userRank]

/-- Nobody but root manages root, admins never manage admins, and users manage
nobody: managing requires a strictly higher global role. -/
theorem manage_needs_higher_role (a b : auth.UserRole) (h : auth.can_manage a b = ok true) :
    a ≠ .User ∧ (b = .Root → a = .Root) ∧ (b = .Admin → a = .Root) := by
  cases a <;> cases b <;> simp_all [auth.can_manage]

/-- Whoever manages another role is admin or above. -/
theorem manager_is_admin_or_above (a b : auth.UserRole) (h : auth.can_manage a b = ok true) :
    auth.is_admin_or_above a = ok true := by
  cases a <;> cases b <;> simp_all [auth.can_manage, auth.is_admin_or_above]

/-- Banned accounts cannot log in, create or join rooms. -/
theorem banned_cannot_login : auth.status_can_login .Banned = ok false := by
  simp [auth.status_can_login, auth.status_is_active]

/-! ## Tokens -/

/-- `validate_expiration` is `Spec.notExpired`, and fails only with `Authentication`. -/
theorem expiration_correct (now exp : I64) (l : U64) : ∃ r, auth.validate_expiration now exp l = ok r ∧
    (r = .Ok () ↔ notExpired now.val exp.val l.val) ∧ (r = .Ok () ∨ r = .Err .Authentication) :=
  expiration_eq now exp l

/-- An accepted token is never used after its expiry plus the configured leeway. -/
theorem expired_token_rejected (now exp : I64) (l : U64)
    (h : auth.validate_expiration now exp l = ok (.Ok ())) : now.val ≤ exp.val + l.val := by
  obtain ⟨r, hr, hiff, -⟩ := expiration_eq now exp l
  rw [hr, Result.ok.injEq] at h
  have := hiff.1 h
  simp only [notExpired] at this
  omega

/-- With zero leeway, a token is rejected from the second after `exp`. -/
theorem zero_leeway_strict (now exp : I64) (h : auth.validate_expiration now exp 0#u64 = ok (.Ok ())) :
    now.val ≤ exp.val := by
  have := expired_token_rejected now exp 0#u64 h
  simpa using this

/-- A user token is only accepted as the type that was asked for (a refresh token is
never an access token) and only before its expiry. -/
theorem token_type_enforced (now exp : I64) (l : U64) (typ expected : auth.TokenType)
    (h : auth.accept_user_token now exp l typ expected = ok (.Ok ())) :
    typ = expected ∧ now.val ≤ exp.val + l.val := by
  obtain ⟨h1, h2⟩ := user_token_accepted now exp l typ expected h
  refine ⟨h1, ?_⟩
  simp only [notExpired] at h2
  omega

/-- Room-wide guest revocation works: once a room's guest version exceeds the
version in a guest token, that token is rejected (and so is an expired one). -/
theorem guest_revocation_effective (now exp : I64) (l : U64) (gv rv : I64)
    (h : auth.accept_guest_token now exp l gv rv = ok (.Ok ())) :
    rv.val ≤ gv.val ∧ now.val ≤ exp.val + l.val := by
  obtain ⟨r, hr, hiff, hor⟩ := expiration_eq now exp l
  unfold auth.accept_guest_token at h
  rcases hor with rfl | rfl
  · simp only [hr, bind_ok, core.result.Result.Insts.CoreOpsTry.branch] at h
    split_ifs at h with hlt
    · simp at h
    · have := hiff.1 rfl
      simp only [notExpired] at this
      constructor <;> scalar_tac
  · simp [hr, core.result.Result.Insts.CoreOpsTry.branch,
      core.result.Result.Insts.CoreOpsTry_traitFromResidualResult.from_residual] at h

/-- Guests get in only when guest mode is on server-wide (and the runtime settings
are available: fail closed), the room allows guests, and the room has no password. -/
theorem guest_access_requires (f : auth.GuestAccessFacts) (h : auth.check_guest_allowed f = ok (.Ok ())) :
    f.has_runtime_settings = true ∧ f.enable_guest = true ∧ f.allow_guest_join = true ∧
      f.password_enabled = false := by
  unfold auth.check_guest_allowed at h
  split_ifs at h <;> simp_all

/-- The security pipeline accepts a verified access token only for an existing,
non-deleted, non-banned user whose password version matches the token, with a second
factor when the account requires one, and a JTI that is known not to be revoked
(a blacklist outage fails closed). -/
theorem pipeline_accepts_only_valid (f : auth.PipelineFacts) (h : auth.pipeline_check f = ok (.Ok ())) :
    ¬ (f.cache_hit = true ∧ f.cached_rejects = true) ∧ f.user_found = true ∧
      f.claims_pv = f.password_version ∧ f.user_deleted = false ∧ f.banned = false ∧
      (f.two_factor_enabled = true → f.token_has_second_factor = true) ∧
      f.blacklist_unavailable = false ∧ f.blacklisted = false := by
  unfold auth.pipeline_check at h
  split_ifs at h <;> simp_all <;> exact IScalar.eq_of_val_eq (by assumption)

/-! ## Authorization header -/

/-- An accepted `Authorization` header starts with `Bearer ` (any case), and the token
is the non-empty range after it. -/
theorem bearer_token_after_scheme (v : Slice U8) (st en : Usize)
    (h : auth.extract_bearer_token v = ok (.Ok (st, en))) :
    7 < v.length ∧ (v.val.take 7).map lowerB = [98#u8, 101#u8, 97#u8, 114#u8, 101#u8, 114#u8, 32#u8] ∧
      7 ≤ st.val ∧ st.val < en.val ∧ en.val ≤ v.length := by
  unfold auth.extract_bearer_token at h
  h5i_invert h
  have hp := bearer_prefix_true v (by simpa [*] using hb)
  obtain ⟨rfl, rfl⟩ := h
  have h0 := post_of_ok (loop0_spec v 7#usize (by scalar_tac)) hstart
  have h1 := post_of_ok (loop1_spec v start v.len (by scalar_tac) (by scalar_tac)) hend1
  refine ⟨by scalar_tac, hp, by simpa using h0.1, ?_, by scalar_tac⟩
  have : start.val ≠ end1.val := fun e => hc_2 (UScalar.eq_of_val_eq e)
  scalar_tac

/-! ## Path traversal -/

/-- An accepted path contains no literal `..`, NUL, `%00` or `./.`. -/
theorem traversal_check_rejects_literal (p : Slice U8) (hs : p.length + 8 < Usize.max)
    (h : pathcheck.validate_path_for_traversal p = ok (.Ok ())) : ¬ literalTraversal (vals p) := by
  obtain ⟨h1, h2, h3, h4, -⟩ := validate_ok p hs h
  rw [has2_vals, has2_iff] at h1
  rw [has3_vals, has3_iff] at h3 h4
  rintro (e | e | e | e)
  · exact h1 e
  · apply h2
    obtain ⟨x, hx, hx0⟩ := List.mem_map.1 e
    have : x = 0#u8 := UScalar.eq_of_val_eq hx0
    exact this ▸ hx
  · exact h3 e
  · exact h4 e

/-- An accepted path contains no percent-encoded dot, single, double (`%25` then
`2e`) or triple encoded. -/
theorem traversal_check_rejects_encoded_dot (p : Slice U8) (hs : p.length + 8 < Usize.max)
    (h : pathcheck.validate_path_for_traversal p = ok (.Ok ())) : ∀ i, ¬ encAt (vals p) i := by
  intro i
  by_cases hi : i < p.length
  · exact (validate_ok p hs h).2.2.2.2 i hi
  · rintro ⟨h0, -⟩
    rw [vals_get_none p (by scalar_tac)] at h0
    simp at h0

/-- Decoding an accepted path once never produces `..`. -/
theorem decoded_path_has_no_dotdot (p : Slice U8) (hs : p.length + 8 < Usize.max)
    (h : pathcheck.validate_path_for_traversal p = ok (.Ok ())) : ¬ [46, 46] <:+: decodeOnce (vals p) := by
  have hl := traversal_check_rejects_literal p hs h
  have he := traversal_check_rejects_encoded_dot p hs h
  refine (decode_no_dd (vals p) (fun e => hl (Or.inl e)) (fun i hi => he i ⟨hi.1, Or.inl hi.2⟩)).1

/-- FINDING (S3): the double-encoding check only recognises `%25` followed by `2e`.
Percent-encoding the hex digits instead passes: `%2%65%2%65` is accepted, decodes
once to `%2e%2e` and twice to `..`. (`%25%32%65` works the same way.) -/
theorem double_decoding_reaches_dotdot (p : Slice U8)
    (hp : p.val = [37#u8, 50#u8, 37#u8, 54#u8, 53#u8, 37#u8, 50#u8, 37#u8, 54#u8, 53#u8])
    (hs : p.length + 8 < Usize.max) :
    pathcheck.validate_path_for_traversal p = ok (.Ok ()) ∧
      [46, 46] <:+: decodeOnce (decodeOnce (vals p)) := by
  have hv : vals p = [37, 50, 37, 54, 53, 37, 50, 37, 54, 53] := by simp [vals, hp]
  refine ⟨?_, by rw [hv]; decide⟩
  obtain ⟨b, hb, hbi⟩ := WP.spec_imp_exists (contains2_spec p 46#u8 46#u8 hs)
  obtain ⟨b1, hb1, hb1i⟩ := WP.spec_imp_exists (contains1_spec p 0#u8)
  obtain ⟨b2, hb2, hb2i⟩ := WP.spec_imp_exists (contains3_spec p 37#u8 48#u8 48#u8 hs)
  obtain ⟨b3, hb3, hb3i⟩ := WP.spec_imp_exists (contains3_spec p 46#u8 47#u8 46#u8 hs)
  obtain ⟨o, ho, hoi⟩ := WP.spec_imp_exists (first_encoded_spec p hs)
  have e0 : b = false := by
    cases b; rfl; exfalso; have := hbi.1 rfl; rw [has2_iff, hp] at this; revert this; decide
  have e1 : b1 = false := by rw [hb1i, hp]; decide
  have e2 : b2 = false := by
    cases b2; rfl; exfalso; have := hb2i.1 rfl; rw [has3_iff, hp] at this; revert this; decide
  have e3 : b3 = false := by
    cases b3; rfl; exfalso; have := hb3i.1 rfl; rw [has3_iff, hp] at this; revert this; decide
  have e4 : o = none := by
    apply hoi.2
    intro i hi
    have hl : p.length = 10 := by simp [Slice.length, hp]
    rw [hv]
    rw [hl] at hi
    revert i
    unfold encAt pairAt hexPair hexDigit
    decide
  unfold pathcheck.validate_path_for_traversal
  rw [hb, e0]; simp only [bind_ok, Bool.false_eq_true, if_false]
  rw [hb1, e1]; simp only [bind_ok, Bool.false_eq_true, if_false]
  rw [hb2, e2]; simp only [bind_ok, Bool.false_eq_true, if_false]
  rw [hb3, e3]; simp only [bind_ok, Bool.false_eq_true, if_false]
  rw [ho, e4]; simp

end synctv_kernel.Properties
