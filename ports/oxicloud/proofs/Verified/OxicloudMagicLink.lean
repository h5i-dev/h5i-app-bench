import Verified.OxicloudBytes
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.SpecKernel
open H5iAppLib hiding lit
open oxicloud_kernel.Verified.OxicloudBytes
namespace oxicloud_kernel.Verified.OxicloudMagicLink

theorem resource_bytes_ok (value : magiclink.MagicLinkResourceKind) (out : alloc.vec.Vec U8)
    (h : magiclink.resource_bytes value = ok out) : out.val = MagicResourceWire value := by
  cases value <;> unfold magiclink.resource_bytes at h <;> h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at hs
  all_goals subst s
  all_goals have hc := copy_ok _ _ h
  all_goals simpa [MagicResourceWire, Array.to_slice, Array.make] using hc

theorem resource_parse_ok (raw : Slice U8) (o : Option magiclink.MagicLinkResourceKind)
    (h : magiclink.resource_parse raw = ok o) (value : magiclink.MagicLinkResourceKind) :
    (o = some value ↔ raw.val = MagicResourceWire value) := by
  unfold magiclink.resource_parse at h
  h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at *
  all_goals subst_vars
  all_goals have he := equal_ok _ _ _ hb
  all_goals try have he1 := equal_ok _ _ _ hb1
  all_goals cases value <;> simp_all [MagicResourceWire, Array.to_slice, Array.make]

theorem status_bytes_ok (value : magiclink.MagicLinkStatus) (out : alloc.vec.Vec U8)
    (h : magiclink.status_bytes value = ok out) : out.val = MagicStatusWire value := by
  cases value <;> unfold magiclink.status_bytes at h <;> h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at hs
  all_goals subst s
  all_goals have hc := copy_ok _ _ h
  all_goals simpa [MagicStatusWire, Array.to_slice, Array.make] using hc

theorem status_parse_ok (raw : Slice U8) (o : Option magiclink.MagicLinkStatus)
    (h : magiclink.status_parse raw = ok o) (value : magiclink.MagicLinkStatus) :
    (o = some value ↔ raw.val = MagicStatusWire value) := by
  unfold magiclink.status_parse at h
  h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at *
  all_goals subst_vars
  all_goals have he := equal_ok _ _ _ hb
  all_goals try have he1 := equal_ok _ _ _ hb1
  all_goals try have he2 := equal_ok _ _ _ hb2
  all_goals cases value <;> simp_all [MagicStatusWire, Array.to_slice, Array.make]

theorem restored_readback (snapshot r : magiclink.MagicLinkToken)
    (h : magiclink.from_raw snapshot.id snapshot.token snapshot.user_id snapshot.status snapshot.issued_at snapshot.expires_at snapshot.used_at snapshot.resource_kind snapshot.resource_id snapshot.request_challenge = ok r) :
    magiclink.id r = ok snapshot.id ∧
    magiclink.token r = ok snapshot.token ∧
    magiclink.user_id r = ok snapshot.user_id ∧
    magiclink.status r = ok snapshot.status ∧
    magiclink.issued_at r = ok snapshot.issued_at ∧
    magiclink.expires_at r = ok snapshot.expires_at ∧
    magiclink.used_at r = ok snapshot.used_at ∧
    magiclink.resource_kind r = ok snapshot.resource_kind ∧
    magiclink.resource_id r = ok snapshot.resource_id ∧
    magiclink.request_challenge r = ok snapshot.request_challenge := by
  simp only [magiclink.from_raw, Result.ok.injEq] at h
  subst r
  simp [magiclink.id, magiclink.token, magiclink.user_id, magiclink.status, magiclink.issued_at, magiclink.expires_at, magiclink.used_at, magiclink.resource_kind, magiclink.resource_id, magiclink.request_challenge]

theorem expired_ok (s : magiclink.MagicLinkToken) (now : session.Timestamp) (r : Bool)
    (h : magiclink.is_expired s now = ok r) : (r = true ↔ TimestampPast now s.expires_at) := by
  unfold magiclink.is_expired at h
  h5i_invert h <;> simp_all [TimestampPast] <;> scalar_tac

theorem redeemable_ok (s : magiclink.MagicLinkToken) (now : session.Timestamp) (r : Bool)
    (h : magiclink.is_redeemable s now = ok r) : (r = true ↔ MagicLinkRedeemable s now) := by
  unfold magiclink.is_redeemable at h
  h5i_invert h
  · have he := expired_ok s now b hb
    cases b <;> simp_all [MagicLinkRedeemable, TimestampPast, TimestampWithin] <;> omega
  · simp [MagicLinkRedeemable, hc]
  · simp [MagicLinkRedeemable, hc]

end oxicloud_kernel.Verified.OxicloudMagicLink
