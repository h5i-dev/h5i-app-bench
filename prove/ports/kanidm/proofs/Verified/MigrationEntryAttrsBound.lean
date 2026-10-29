import Verified.MigrationBounds
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
open kanidm_kernel.Verified.RecoveredEffectivePermissionCheckTotal
namespace kanidm_kernel.Verified.MigrationEntryAttrsBound
set_option allowUnsafeReducibility true
attribute [local reducible] Aeneas.Std.WP.Post
set_option maxHeartbeats 2000000
set_option maxRecDepth 4096

/-- Share the migration bound with the protected-denial proofs. -/
theorem migration_attrs_bound (classes : Slice (alloc.vec.Vec U8)) :
    migration.migration_entry_attrs classes ⦃ r =>
      r.1.val.length ≤ 64 ∧ r.2.val.length ≤ 64 ⦄ := by
  unfold migration.migration_entry_attrs
  total_steps

end kanidm_kernel.Verified.MigrationEntryAttrsBound
