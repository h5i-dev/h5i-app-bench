import Verified.OxicloudBytes
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.SpecKernel
open H5iAppLib hiding lit
open oxicloud_kernel.Verified.OxicloudBytes
namespace oxicloud_kernel.Verified.OxicloudUserRole

theorem role_wire_injective : Function.Injective RoleWire := by
  intro a b h
  cases a <;> cases b <;> simp_all [RoleWire]

theorem rank_ok (r : userrole.UserRole) (n : U8) (h : userrole.rank r = ok n) :
    n.val = RoleLevel r := by
  cases r <;> simp_all [userrole.rank, RoleLevel] <;> scalar_tac

theorem at_least_ok (r min : userrole.UserRole) (b : Bool)
    (h : userrole.at_least r min = ok b) :
    (b = true ↔ RoleLevel min ≤ RoleLevel r) := by
  cases r <;> cases min <;> simp_all [userrole.at_least, userrole.rank, RoleLevel]

theorem outranks_ok (r target : userrole.UserRole) (b : Bool)
    (h : userrole.outranks r target = ok b) :
    (b = true ↔ RoleLevel target < RoleLevel r) := by
  cases r <;> cases target <;> simp_all [userrole.outranks, userrole.rank, RoleLevel]

theorem anonymous_ok (r : userrole.UserRole) (b : Bool)
    (h : userrole.is_anonymous r = ok b) : (b = true ↔ r = .Anonymous) := by
  cases r <;> simp_all [userrole.is_anonymous]

/-- Only administrators and server owners have the privileged account flag. -/
theorem privileged_ok (r : userrole.UserRole) (b : Bool)
    (h : userrole.is_privileged r = ok b) : (b = true ↔ r = .Admin ∨ r = .Owner) := by
  cases r <;> simp_all [userrole.is_privileged, userrole.rank]

theorem as_bytes_ok (r : userrole.UserRole) (out : alloc.vec.Vec U8)
    (h : userrole.as_bytes r = ok out) : out.val = RoleWire r := by
  cases r <;> unfold userrole.as_bytes at h <;> h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at hs
  all_goals subst s
  all_goals have hc := copy_ok _ _ h
  all_goals simpa [RoleWire, Array.to_slice, Array.make] using hc

/-- Stored-role parsing recognizes only the three canonical account roles. -/
theorem stored_ok (raw : Slice U8) (o : Option userrole.UserRole)
    (h : userrole.from_stored raw = ok o) (r : userrole.UserRole) :
    (o = some r ↔ StoredRole raw.val r) := by
  unfold userrole.from_stored at h
  h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at *
  all_goals subst_vars
  all_goals have he := equal_ok _ _ _ hb
  all_goals try have he1 := equal_ok _ _ _ hb1
  all_goals try have he2 := equal_ok _ _ _ hb2
  all_goals cases r <;> simp_all [StoredRole, RoleWire, Array.to_slice, Array.make]

/-- Session parsing adds only the canonical anonymous spelling. -/
theorem session_ok (raw : Slice U8) (o : Option userrole.UserRole)
    (h : userrole.from_session raw = ok o) (r : userrole.UserRole) :
    (o = some r ↔ SessionRole raw.val r) := by
  unfold userrole.from_session at h
  h5i_invert h
  · simp only [lift, Result.ok.injEq] at hs
    subst s
    have he := equal_ok _ _ _ hb
    cases r <;> simp_all [SessionRole, RoleWire, Array.to_slice, Array.make]
  · simp only [lift, Result.ok.injEq] at hs
    subst s
    have he := equal_ok _ _ _ hb
    have ho := stored_ok raw o h r
    cases r <;> simp_all [SessionRole, StoredRole, RoleWire, Array.to_slice, Array.make]

/-- Unrecognized roles cannot satisfy even the anonymous requirement. -/
theorem str_at_least_ok (raw : Slice U8) (min : userrole.UserRole) (b : Bool)
    (h : userrole.str_at_least raw min = ok b) : (b = true ↔ MeetsRole raw.val min) := by
  unfold userrole.str_at_least at h
  h5i_invert h
  · have hs := session_ok raw none ho
    simp only [Bool.false_eq_true, false_iff]
    rintro ⟨r, hr, _⟩
    have := (hs r).2 hr
    simp at this
  · have hs := session_ok raw (some role) ho
    have hb := at_least_ok role min b h
    rw [hb]
    constructor
    · intro hr
      exact ⟨role, (hs role).1 rfl, hr⟩
    · rintro ⟨r, hr, hl⟩
      have he : role = r := Option.some.inj ((hs r).2 hr)
      simpa [he] using hl

end oxicloud_kernel.Verified.OxicloudUserRole
