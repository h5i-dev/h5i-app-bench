import Verified.MigrationDefaultsData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.MigrationDefaults
set_option maxRecDepth 16384
set_option maxHeartbeats 8000000
@[step] theorem table_part_15_spec : migration_defaults.table_part_15 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart15 ⦄ := by
  unfold migration_defaults.table_part_15
  h5i_steps
  all_goals simp_all [tablePart15, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_16_spec : migration_defaults.table_part_16 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart16 ⦄ := by
  unfold migration_defaults.table_part_16
  h5i_steps
  all_goals simp_all [tablePart16, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_17_spec : migration_defaults.table_part_17 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart17 ⦄ := by
  unfold migration_defaults.table_part_17
  h5i_steps
  all_goals simp_all [tablePart17, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

end kanidm_kernel.Verified.MigrationDefaults
