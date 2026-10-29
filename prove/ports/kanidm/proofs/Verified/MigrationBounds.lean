import Verified.EffectivePermissionSupport
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
namespace kanidm_kernel.Verified.RecoveredEffectivePermissionCheckTotal
set_option maxHeartbeats 600000
set_option maxRecDepth 4096

@[step] theorem migration_add_domain_info_total
    (classes : Slice (alloc.vec.Vec U8))
    (attrs cls : alloc.vec.Vec (alloc.vec.Vec U8))
    (hcap : attrs.val.length + 4 ≤ Usize.max) :
    migration.add_domain_info classes attrs cls ⦃ r =>
      r.1.val.length ≤ attrs.val.length + 4 ∧ r.2.val.length ≤ cls.val.length + 0 ⦄ := by
  unfold migration.add_domain_info
  total_steps

@[step] theorem migration_add_group_total
    (classes : Slice (alloc.vec.Vec U8))
    (attrs cls : alloc.vec.Vec (alloc.vec.Vec U8))
    (hcap : attrs.val.length + 5 ≤ Usize.max) :
    migration.add_group classes attrs cls ⦃ r =>
      r.1.val.length ≤ attrs.val.length + 5 ∧ r.2.val.length ≤ cls.val.length + 3 ⦄ := by
  unfold migration.add_group
  total_steps

@[step] theorem migration_add_person_total
    (classes : Slice (alloc.vec.Vec U8))
    (attrs cls : alloc.vec.Vec (alloc.vec.Vec U8))
    (hcap : attrs.val.length + 8 ≤ Usize.max) :
    migration.add_person classes attrs cls ⦃ r =>
      r.1.val.length ≤ attrs.val.length + 8 ∧ r.2.val.length ≤ cls.val.length + 3 ⦄ := by
  unfold migration.add_person
  total_steps

@[step] theorem migration_add_service_account_total
    (classes : Slice (alloc.vec.Vec U8))
    (attrs cls : alloc.vec.Vec (alloc.vec.Vec U8))
    (hcap : attrs.val.length + 6 ≤ Usize.max) :
    migration.add_service_account classes attrs cls ⦃ r =>
      r.1.val.length ≤ attrs.val.length + 6 ∧ r.2.val.length ≤ cls.val.length + 2 ⦄ := by
  unfold migration.add_service_account
  total_steps

@[step] theorem migration_add_account_policy_total
    (classes : Slice (alloc.vec.Vec U8))
    (attrs cls : alloc.vec.Vec (alloc.vec.Vec U8))
    (hcap : attrs.val.length + 8 ≤ Usize.max) :
    migration.add_account_policy classes attrs cls ⦃ r =>
      r.1.val.length ≤ attrs.val.length + 8 ∧ r.2.val.length ≤ cls.val.length + 0 ⦄ := by
  unfold migration.add_account_policy
  total_steps

@[step] theorem migration_add_oauth2_resource_server_total
    (classes : Slice (alloc.vec.Vec U8))
    (attrs cls : alloc.vec.Vec (alloc.vec.Vec U8))
    (hcap : attrs.val.length + 12 ≤ Usize.max) :
    migration.add_oauth2_resource_server classes attrs cls ⦃ r =>
      r.1.val.length ≤ attrs.val.length + 12 ∧ r.2.val.length ≤ cls.val.length + 4 ⦄ := by
  unfold migration.add_oauth2_resource_server
  total_steps

end kanidm_kernel.Verified.RecoveredEffectivePermissionCheckTotal
