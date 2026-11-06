import Lemmas
/-!
# Security properties of synctv's room permissions, member policy and tokens

Each theorem is about the extracted kernel and the policy in `Spec.lean`.
-/
open Aeneas Aeneas.Std Result synctv_kernel synctv_kernel.Spec synctv_kernel.Lemmas H5iAppLib

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

end synctv_kernel.Properties
