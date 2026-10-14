import Verified.OxicloudBytes
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.SpecKernel
open H5iAppLib hiding lit
open oxicloud_kernel.Verified.OxicloudBytes
namespace oxicloud_kernel.Verified.OxicloudSession

theorem origin_bytes_ok (o : session.SessionOrigin) (out : alloc.vec.Vec U8)
    (h : session.origin_bytes o = ok out) : out.val = OriginWire o := by
  cases o <;> unfold session.origin_bytes at h <;> h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at hs
  all_goals subst s
  all_goals have hc := copy_ok _ _ h
  all_goals simpa [OriginWire, Array.to_slice, Array.make] using hc

theorem origin_parse_ok (raw : Slice U8) (o : session.SessionOrigin)
    (h : session.origin_from_wire raw = ok o) : OriginDecoded raw.val o := by
  unfold session.origin_from_wire at h
  h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at *
  all_goals subst_vars
  all_goals have he := equal_ok _ _ _ hb
  all_goals try have he1 := equal_ok _ _ _ hb1
  all_goals try have he2 := equal_ok _ _ _ hb2
  all_goals try have he3 := equal_ok _ _ _ hb3
  all_goals try have he4 := equal_ok _ _ _ hb4
  all_goals intro known hk
  all_goals cases known <;> simp_all [OriginWire, Array.to_slice, Array.make]

/-- Lossless restoration preserves the complete security snapshot through its public views. -/
theorem restored_readback (snapshot r : session.Session)
    (h : session.from_raw snapshot.id snapshot.user_id snapshot.refresh_token snapshot.expires_at snapshot.ip_address snapshot.user_agent snapshot.created_at snapshot.revoked snapshot.family_id snapshot.oidc_id_token snapshot.oidc_sid snapshot.dpop_jkt snapshot.origin snapshot.last_seen_at = ok r) :
    session.id r = ok snapshot.id ∧
    session.user_id r = ok snapshot.user_id ∧
    session.refresh_token r = ok snapshot.refresh_token ∧
    session.expires_at r = ok snapshot.expires_at ∧
    session.ip_address r = ok snapshot.ip_address ∧
    session.user_agent r = ok snapshot.user_agent ∧
    session.created_at r = ok snapshot.created_at ∧
    session.is_revoked r = ok snapshot.revoked ∧
    session.family_id r = ok snapshot.family_id ∧
    session.oidc_id_token r = ok snapshot.oidc_id_token ∧
    session.oidc_sid r = ok snapshot.oidc_sid ∧
    session.dpop_jkt r = ok snapshot.dpop_jkt ∧
    session.origin r = ok snapshot.origin ∧
    session.last_seen_at r = ok snapshot.last_seen_at := by
  simp only [session.from_raw, Result.ok.injEq] at h
  subst r
  simp [session.id, session.user_id, session.refresh_token, session.expires_at, session.ip_address, session.user_agent, session.created_at, session.is_revoked, session.family_id, session.oidc_id_token, session.oidc_sid, session.dpop_jkt, session.origin, session.last_seen_at]

/-- Revocation is idempotent, and preserves every credential and authorization namespace. -/
theorem revoke_ok (s r : session.Session) (h : session.revoke s = ok r) :
    SessionRevoked s r ∧ session.revoke r = ok r := by
  simp only [session.revoke, Result.ok.injEq] at h
  subst r
  simp [SessionRevoked, session.revoke]

theorem bind_ok (s r : session.Session) (key : alloc.vec.Vec U8)
    (h : session.with_dpop_jkt s key = ok r) : SessionBound s key r := by
  cases hk : s.dpop_jkt <;> simp_all [session.with_dpop_jkt]
  subst r
  simp [SessionBound, hk]
  cases s
  simp_all

/-- A bound session cannot be rebound, including when the original key is empty. -/
theorem no_rebind (s : session.Session) (key : alloc.vec.Vec U8) (h : s.dpop_jkt ≠ none) :
    session.with_dpop_jkt s key = fail .panic := by
  cases hk : s.dpop_jkt <;> simp_all [session.with_dpop_jkt]

theorem token_attach_ok (s r : session.Session) (token : alloc.vec.Vec U8)
    (h : session.with_oidc_id_token s token = ok r) : SessionTokenAttached s token r := by
  simp only [session.with_oidc_id_token, Result.ok.injEq] at h
  subst r
  simp [SessionTokenAttached]

theorem sid_attach_ok (s r : session.Session) (sid : alloc.vec.Vec U8)
    (h : session.with_oidc_sid s sid = ok r) : SessionSidAttached s sid r := by
  simp only [session.with_oidc_sid, Result.ok.injEq] at h
  subst r
  simp [SessionSidAttached]

end oxicloud_kernel.Verified.OxicloudSession
