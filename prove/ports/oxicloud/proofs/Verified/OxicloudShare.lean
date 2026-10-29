import SpecKernel
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.SpecKernel
open H5iAppLib hiding lit
namespace oxicloud_kernel.Verified.OxicloudShare

/-- Restoration preserves every security observation without interpreting token or hash contents. -/
theorem restored_readback (snapshot r : share.Share)
    (h : share.from_raw snapshot.id snapshot.item_id snapshot.item_name snapshot.item_type snapshot.token snapshot.password_hash snapshot.expires_at snapshot.created_at snapshot.created_by snapshot.access_count = ok r) :
    share.id r = ok snapshot.id ∧
    share.item_id r = ok snapshot.item_id ∧
    share.item_name r = ok snapshot.item_name ∧
    share.item_type r = ok snapshot.item_type ∧
    share.token r = ok snapshot.token ∧
    share.password_hash r = ok snapshot.password_hash ∧
    share.expires_at r = ok snapshot.expires_at ∧
    share.created_at r = ok snapshot.created_at ∧
    share.created_by r = ok snapshot.created_by ∧
    share.access_count r = ok snapshot.access_count := by
  simp only [share.from_raw, Result.ok.injEq] at h
  subst r
  simp [share.id, share.item_id, share.item_name, share.item_type, share.token, share.password_hash, share.expires_at, share.created_at, share.created_by, share.access_count]

theorem password_change_ok (s r : share.Share) (hash : Option (alloc.vec.Vec U8))
    (h : share.with_password s hash = ok r) : SharePasswordChanged s hash r := by
  simp only [share.with_password, Result.ok.injEq] at h
  subst r
  simp [SharePasswordChanged]

theorem token_change_ok (s r : share.Share) (token : alloc.vec.Vec U8)
    (h : share.with_token s token = ok r) : ShareTokenChanged s token r := by
  simp only [share.with_token, Result.ok.injEq] at h
  subst r
  simp [ShareTokenChanged]

/-- Presence alone controls the password requirement, including an empty stored hash. -/
theorem password_required (s : share.Share) (r : Bool) (h : share.has_password s = ok r) :
    (r = true ↔ ∃ hash, s.password_hash = some hash) ∧ (r = false ↔ s.password_hash = none) := by
  cases hp : s.password_hash <;> simp_all [share.has_password]

theorem access_count_ok (s r : share.Share) (h : share.increment_access_count s = ok r) :
    ShareAccessCounted s r := by
  unfold share.increment_access_count at h
  h5i_invert h
  have ha := add_ok_val hi
  simp [ShareAccessCounted, ha]

end oxicloud_kernel.Verified.OxicloudShare
