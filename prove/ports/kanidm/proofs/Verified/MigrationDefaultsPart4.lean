import Verified.MigrationDefaultsData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.MigrationDefaults
set_option maxRecDepth 16384
set_option maxHeartbeats 8000000
@[step] theorem table_part_12_spec : migration_defaults.table_part_12 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart12 ⦄ := by
  unfold migration_defaults.table_part_12
  h5i_steps
  all_goals simp_all [tablePart12, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_13_spec : migration_defaults.table_part_13 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart13 ⦄ := by
  unfold migration_defaults.table_part_13
  h5i_steps
  all_goals simp_all [tablePart13, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_14_spec : migration_defaults.table_part_14 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart14 ⦄ := by
  unfold migration_defaults.table_part_14
  h5i_steps
  all_goals simp_all [tablePart14, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

end kanidm_kernel.Verified.MigrationDefaults
