import Verified.OxicloudUserRole
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.SpecKernel
open H5iAppLib hiding lit
open oxicloud_kernel.Verified.OxicloudBytes
namespace oxicloud_kernel.Verified.OxicloudLiveAuth

theorem internal_ok (flags : liveauth.FlagsLookup) (id : U128)
    (r : core.result.Result Unit liveauth.InternalDenial)
    (h : liveauth.decide_internal_user flags id = ok r) :
    (r = .Ok () ↔ InternalAccountAllowed flags) ∧
    (∀ reason, r = .Err reason → InternalAccountDenied flags reason) := by
  cases flags with
  | Found f =>
    rcases f with ⟨role, external, active, change⟩
    cases external <;> simp_all [liveauth.decide_internal_user, InternalAccountAllowed, InternalAccountDenied]
    all_goals subst_vars
    all_goals simp_all [InternalAccountDenied]
  | NotFound =>
    simp_all [liveauth.decide_internal_user, InternalAccountAllowed, InternalAccountDenied]
    subst_vars
    simp_all [InternalAccountDenied]
  | Unavailable =>
    simp_all [liveauth.decide_internal_user, InternalAccountAllowed, InternalAccountDenied]
    subst_vars
    simp

theorem live_role_ok (flags : liveauth.FlagsLookup) (id : U128) (claim : Slice U8)
    (r : liveauth.LiveRole) (h : liveauth.decide_live_role flags id claim = ok r) :
    LiveAccountRole flags claim.val r := by
  cases flags with
  | Found f =>
    rcases f with ⟨role, external, active, change⟩
    cases active <;> unfold liveauth.decide_live_role at h <;> h5i_invert h
    · simp [LiveAccountRole]
    · have hr := oxicloud_kernel.Verified.OxicloudUserRole.as_bytes_ok _ _ hv
      simpa [LiveAccountRole] using hr
  | NotFound =>
    unfold liveauth.decide_live_role at h
    h5i_invert h
    simp [LiveAccountRole]
  | Unavailable =>
    unfold liveauth.decide_live_role at h
    h5i_invert h
    exact copy_ok _ _ hv

theorem anonymous_ok (claim : Slice U8) (r : Option liveauth.LiveRole)
    (h : liveauth.anonymous_live_role claim = ok r) : AnonymousLiveRole claim.val r := by
  unfold liveauth.anonymous_live_role at h
  h5i_invert h
  all_goals have hs := oxicloud_kernel.Verified.OxicloudUserRole.session_ok claim _ ho
  · have hn := hs .Anonymous
    simp only [SessionRole, reduceCtorEq, false_iff] at hn
    simp [AnonymousLiveRole, hn]
  · have ha : role = .Anonymous :=
      (oxicloud_kernel.Verified.OxicloudUserRole.anonymous_ok role b hb).1 hc
    subst role
    have hp : claim.val = RoleWire .Anonymous := (hs .Anonymous).1 rfl
    have hw := oxicloud_kernel.Verified.OxicloudUserRole.as_bytes_ok _ _ hv
    constructor
    · simp [hp]
    · intro value he
      have he' : liveauth.LiveRole.Active v = value := Option.some.inj he
      subst value
      exact ⟨v, rfl, hw, hp⟩
  · have hn : claim.val ≠ RoleWire .Anonymous := by
      intro he
      have hr : role = .Anonymous := Option.some.inj ((hs .Anonymous).2 he)
      exact hc ((oxicloud_kernel.Verified.OxicloudUserRole.anonymous_ok role b hb).2 hr)
    simp [AnonymousLiveRole, hn]

end oxicloud_kernel.Verified.OxicloudLiveAuth
