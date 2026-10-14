import SpecKernel
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.SpecKernel
open H5iAppLib hiding lit
namespace oxicloud_kernel.Verified.OxicloudDrivePolicy

@[step] theorem override_bool_spec (d : Bool) (o : Option Bool) :
    drivepolicy.override_bool d o ⦃ r => r = o.getD d ⦄ := by
  cases o <;> simp [drivepolicy.override_bool, Option.getD]

@[step] theorem override_cap_spec (d o : Option U32) :
    drivepolicy.override_cap d o ⦃ r => r = o.or d ⦄ := by
  cases o <;> simp [drivepolicy.override_cap, Option.or]

/-- Missing values inherit defaults, while explicit choices always take precedence. -/
@[step] theorem resolve_spec (d : drivepolicy.Policies) (o : drivepolicy.Overrides) :
    drivepolicy.resolve d o ⦃ r => PolicyResolved d o r ⦄ := by
  unfold drivepolicy.resolve
  step*
  simp_all [PolicyResolved]

/-- Link-specific and broad sharing restrictions both prevent minting. -/
theorem public_links_ok (p : drivepolicy.Policies) (r : core.result.Result Unit model.ErrorKind)
    (h : drivepolicy.refuse_public_links p = ok r) : GuardDecision (PublicLinksAllowed p) r := by
  cases hp : p.forbid_public_links <;> cases hs : p.forbid_sharing <;>
    simp_all [drivepolicy.refuse_public_links, GuardDecision, PublicLinksAllowed] <;>
    subst r <;> simp_all

theorem sharing_ok (p : drivepolicy.Policies) (r : core.result.Result Unit model.ErrorKind)
    (h : drivepolicy.refuse_sharing p = ok r) : GuardDecision (SharingAllowed p) r := by
  cases hs : p.forbid_sharing <;>
    simp_all [drivepolicy.refuse_sharing, GuardDecision, SharingAllowed] <;>
    subst r <;> simp_all

/-- Locking the owner roster constrains non-administrators. -/
theorem owner_changes_ok (p : drivepolicy.Policies) (admin : Bool)
    (r : core.result.Result Unit model.ErrorKind)
    (h : drivepolicy.refuse_owner_role_change p admin = ok r) :
    GuardDecision (OwnerChangesAllowed p admin) r := by
  cases hp : p.forbid_owner_role_change <;> cases admin <;>
    simp_all [drivepolicy.refuse_owner_role_change, GuardDecision, OwnerChangesAllowed] <;>
    subst r <;> simp_all

theorem cross_drive_move_ok (p : drivepolicy.Policies) (r : core.result.Result Unit model.ErrorKind)
    (h : drivepolicy.refuse_cross_drive_move p = ok r) :
    GuardDecision (CrossDriveMoveAllowed p) r := by
  cases hp : p.forbid_cross_drive_move <;>
    simp_all [drivepolicy.refuse_cross_drive_move, GuardDecision, CrossDriveMoveAllowed] <;>
    subst r <;> simp_all

/-- The external-sharing restriction distinguishes user principals from links and groups. -/
theorem external_sharing_ok (p : drivepolicy.Policies) (s : model.Subject) (external : Bool)
    (r : core.result.Result Unit model.ErrorKind)
    (h : drivepolicy.refuse_external_sharing p s external = ok r) :
    GuardDecision (ExternalSharingAllowed p s external) r := by
  cases hp : p.forbid_external_sharing <;> cases s <;> cases external <;>
    simp_all [drivepolicy.refuse_external_sharing, GuardDecision, ExternalSharingAllowed] <;>
    subst r <;> simp_all <;> aesop

end oxicloud_kernel.Verified.OxicloudDrivePolicy
