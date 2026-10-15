import Verified.OxicloudBytes
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.SpecKernel
open H5iAppLib hiding lit
open oxicloud_kernel.Verified.OxicloudBytes
namespace oxicloud_kernel.Verified.OxicloudUserState

theorem federation_bytes_ok (value : userstate.FederationKind) (out : alloc.vec.Vec U8)
    (h : userstate.federation_bytes value = ok out) : out.val = FederationWire value := by
  cases value <;> unfold userstate.federation_bytes at h <;> h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at hs
  all_goals subst s
  all_goals have hc := copy_ok _ _ h
  all_goals simpa [FederationWire, Array.to_slice, Array.make] using hc

theorem federation_parse_ok (raw : Slice U8) (o : Option userstate.FederationKind)
    (h : userstate.federation_parse raw = ok o) (value : userstate.FederationKind) :
    (o = some value ↔ raw.val = FederationWire value) := by
  unfold userstate.federation_parse at h
  h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at *
  all_goals subst_vars
  all_goals have he := equal_ok _ _ _ hb
  all_goals try have he1 := equal_ok _ _ _ hb1
  all_goals try have he2 := equal_ok _ _ _ hb2
  all_goals cases value <;> simp_all [FederationWire, Array.to_slice, Array.make]

theorem restored_readback (snapshot r : userstate.User)
    (h : userstate.from_data_full snapshot.id snapshot.username snapshot.email snapshot.password_hash snapshot.role snapshot.storage_quota_bytes snapshot.storage_used_bytes snapshot.created_at snapshot.updated_at snapshot.last_login_at snapshot.active snapshot.federation_kind snapshot.federation_issuer snapshot.federation_subject snapshot.image snapshot.is_external snapshot.given_name snapshot.family_name snapshot.email_verified_at snapshot.preferred_locale snapshot.notify_on_share snapshot.ui_preferences = ok r) :
    userstate.id r = ok snapshot.id ∧
    userstate.username r = ok snapshot.username ∧
    userstate.email r = ok snapshot.email ∧
    userstate.password_hash r = ok snapshot.password_hash ∧
    userstate.role r = ok snapshot.role ∧
    userstate.storage_quota_bytes r = ok snapshot.storage_quota_bytes ∧
    userstate.storage_used_bytes r = ok snapshot.storage_used_bytes ∧
    userstate.created_at r = ok snapshot.created_at ∧
    userstate.updated_at r = ok snapshot.updated_at ∧
    userstate.last_login_at r = ok snapshot.last_login_at ∧
    userstate.is_active r = ok snapshot.active ∧
    userstate.federation_kind r = ok snapshot.federation_kind ∧
    userstate.federation_issuer r = ok snapshot.federation_issuer ∧
    userstate.federation_subject r = ok snapshot.federation_subject ∧
    userstate.image r = ok snapshot.image ∧
    userstate.is_external r = ok snapshot.is_external ∧
    userstate.given_name r = ok snapshot.given_name ∧
    userstate.family_name r = ok snapshot.family_name ∧
    userstate.email_verified_at r = ok snapshot.email_verified_at ∧
    userstate.preferred_locale r = ok snapshot.preferred_locale ∧
    userstate.notify_on_share r = ok snapshot.notify_on_share ∧
    userstate.ui_preferences r = ok snapshot.ui_preferences := by
  simp only [userstate.from_data_full, Result.ok.injEq] at h
  subst r
  simp [userstate.id, userstate.username, userstate.email, userstate.password_hash, userstate.role, userstate.storage_quota_bytes, userstate.storage_used_bytes, userstate.created_at, userstate.updated_at, userstate.last_login_at, userstate.is_active, userstate.federation_kind, userstate.federation_issuer, userstate.federation_subject, userstate.image, userstate.is_external, userstate.given_name, userstate.family_name, userstate.email_verified_at, userstate.preferred_locale, userstate.notify_on_share, userstate.ui_preferences]

theorem minimal_restored (snapshot r : userstate.User)
    (h : userstate.from_data snapshot.id snapshot.username snapshot.email snapshot.password_hash snapshot.role snapshot.storage_quota_bytes snapshot.storage_used_bytes snapshot.created_at snapshot.updated_at snapshot.last_login_at snapshot.active = ok r) :
    MinimalAccountRestored snapshot r := by
  unfold userstate.from_data at h
  h5i_invert h
  simp only [lift, Result.ok.injEq] at hs
  subst s
  have hc := copy_ok _ _ hv
  simpa [MinimalAccountRestored, Array.to_slice, Array.make] using hc

theorem parts_preserved (s : userstate.User) (p : userstate.UserParts)
    (h : userstate.into_parts s = ok p) : AccountPartsPreserved s p := by
  simp only [userstate.into_parts, Result.ok.injEq] at h
  subst p
  simp [AccountPartsPreserved]

theorem password_presence (s : userstate.User) (r : Bool)
    (h : userstate.has_password s = ok r) : (r = true ↔ ∃ value, s.password_hash = some value) := by
  unfold userstate.has_password at h
  h5i_invert h <;> simp_all

theorem issuer_presence (s : userstate.User) (r : Bool)
    (h : userstate.is_oidc_user s = ok r) : (r = true ↔ ∃ value, s.federation_issuer = some value) := by
  unfold userstate.is_oidc_user at h
  h5i_invert h <;> simp_all

theorem email_verified (s : userstate.User) (r : Bool)
    (h : userstate.is_email_verified s = ok r) : (r = true ↔ ∃ value, s.email_verified_at = some value) := by
  unfold userstate.is_email_verified at h
  h5i_invert h <;> simp_all

theorem credential_presence (s : userstate.User) (r : Bool)
    (h : userstate.has_login_credential s = ok r) : (r = true ↔ AccountLoginCredential s) := by
  unfold userstate.has_login_credential at h
  h5i_invert h
  all_goals have hp := password_presence s _ hb
  all_goals simp_all [AccountLoginCredential]

end oxicloud_kernel.Verified.OxicloudUserState
