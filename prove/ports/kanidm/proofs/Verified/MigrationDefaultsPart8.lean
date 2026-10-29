import Verified.MigrationDefaultsData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.MigrationDefaults
set_option maxRecDepth 16384
set_option maxHeartbeats 8000000
@[step] theorem table_part_24_spec : migration_defaults.table_part_24 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart24 ⦄ := by
  unfold migration_defaults.table_part_24
  h5i_steps
  all_goals simp_all [tablePart24, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_25_spec : migration_defaults.table_part_25 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart25 ⦄ := by
  unfold migration_defaults.table_part_25
  h5i_steps
  all_goals simp_all [tablePart25, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_26_spec : migration_defaults.table_part_26 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart26 ⦄ := by
  unfold migration_defaults.table_part_26
  h5i_steps
  all_goals simp_all [tablePart26, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

end kanidm_kernel.Verified.MigrationDefaults
