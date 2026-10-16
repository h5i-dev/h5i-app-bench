import SpecClaims
import Verified.RustfsForceDelete
import Verified.RustfsValids
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete (lift_slice bytes_eq_ok)

namespace rustfs_kernel.Verified.RustfsClaimTags
set_option maxHeartbeats 1000000

theorem tag_key_ok (key : Slice U8) (b : Bool)
    (h : claims.is_existing_object_tag_condition_key key = ok b) :
    (b = true ↔ ExistingTagKey (nats key.val)) := by
  unfold claims.is_existing_object_tag_condition_key at h
  h5i_invert h
  all_goals
    have he := bytes_eq_ok _ _ _ hb_1
    have hn : (key.val = s.val) ↔ nats key.val = nats s.val :=
      ⟨congrArg nats, rustfs_kernel.Verified.RustfsForceDelete.nats_inj⟩
    have hsl : nats s.val = lit "ExistingObjectTag" := by
      rw [lift_slice hs]; decide +kernel
    rw [hn, hsl] at he
  · simp_all [ExistingTagKey]
  all_goals
    have he1 := bytes_eq_ok _ _ _ hb1
    have hn1 : (key.val = s1.val) ↔ nats key.val = nats s1.val :=
      ⟨congrArg nats, rustfs_kernel.Verified.RustfsForceDelete.nats_inj⟩
    have hsl1 : nats s1.val = lit "s3:ExistingObjectTag" := by
      rw [lift_slice hs1]; decide +kernel
    rw [hn1, hsl1] at he1
  · simp_all [ExistingTagKey]
  all_goals
    have hsl2 : nats s2.val = lit "ExistingObjectTag/" := by
      rw [lift_slice hs2]; decide +kernel
    have he2 := rustfs_kernel.Verified.RustfsValids.starts_lit hsl2 hb2
  · simp_all [ExistingTagKey]
  · have hsl3 : nats s3.val = lit "s3:ExistingObjectTag/" := by
      rw [lift_slice hs3]; decide +kernel
    have he3 := rustfs_kernel.Verified.RustfsValids.starts_lit hsl3 h
    simp_all [ExistingTagKey]
end rustfs_kernel.Verified.RustfsClaimTags
