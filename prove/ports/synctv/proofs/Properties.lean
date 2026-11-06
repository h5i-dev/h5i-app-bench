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

theorem calc_true {d m s p} (h : perms.calculator_has_permission d m s p = ok true) :
    calcHas d s m p := by
  obtain ⟨b, hb, hiff⟩ := calculator_spec d m s p
  rw [hb, Result.ok.injEq] at h
  exact hiff.1 h

theorem names_guest_assignable {bits : Nat} {p : perms.RoomPermission} (h : names guestBit bits p) :
    guestAssignable p := by
  obtain ⟨j, hj, _⟩ := h
  simp [guestAssignable, hj]

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

theorem names_none {space : perms.RoomPermission → Option Nat} {bits p} (h : space p = none) :
    ¬ names space bits p := by
  rintro ⟨j, hj, _⟩
  simp [h] at hj

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

end synctv_kernel.Properties
