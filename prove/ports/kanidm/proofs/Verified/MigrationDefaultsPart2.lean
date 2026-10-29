import Verified.MigrationDefaultsData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.MigrationDefaults
set_option maxRecDepth 16384
set_option maxHeartbeats 8000000
@[step] theorem table_part_6_spec : migration_defaults.table_part_6 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart6 ⦄ := by
  unfold migration_defaults.table_part_6
  h5i_steps
  all_goals simp_all [tablePart6, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_7_spec : migration_defaults.table_part_7 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart7 ⦄ := by
  unfold migration_defaults.table_part_7
  h5i_steps
  all_goals simp_all [tablePart7, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_8_spec : migration_defaults.table_part_8 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart8 ⦄ := by
  unfold migration_defaults.table_part_8
  h5i_steps
  all_goals simp_all [tablePart8, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

end kanidm_kernel.Verified.MigrationDefaults
