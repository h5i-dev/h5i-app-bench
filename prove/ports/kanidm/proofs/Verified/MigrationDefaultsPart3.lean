import Verified.MigrationDefaultsData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.MigrationDefaults
set_option maxRecDepth 16384
set_option maxHeartbeats 8000000
@[step] theorem table_part_9_spec : migration_defaults.table_part_9 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart9 ⦄ := by
  unfold migration_defaults.table_part_9
  h5i_steps
  all_goals simp_all [tablePart9, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_10_spec : migration_defaults.table_part_10 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart10 ⦄ := by
  unfold migration_defaults.table_part_10
  h5i_steps
  all_goals simp_all [tablePart10, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_11_spec : migration_defaults.table_part_11 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart11 ⦄ := by
  unfold migration_defaults.table_part_11
  h5i_steps
  all_goals simp_all [tablePart11, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

end kanidm_kernel.Verified.MigrationDefaults
