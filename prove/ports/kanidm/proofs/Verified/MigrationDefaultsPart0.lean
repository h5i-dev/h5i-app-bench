import Verified.MigrationDefaultsData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.MigrationDefaults
set_option maxRecDepth 16384
set_option maxHeartbeats 8000000
@[step] theorem table_part_0_spec : migration_defaults.table_part_0 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart0 ⦄ := by
  unfold migration_defaults.table_part_0
  h5i_steps
  all_goals simp_all [tablePart0, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_1_spec : migration_defaults.table_part_1 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart1 ⦄ := by
  unfold migration_defaults.table_part_1
  h5i_steps
  all_goals simp_all [tablePart1, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_2_spec : migration_defaults.table_part_2 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart2 ⦄ := by
  unfold migration_defaults.table_part_2
  h5i_steps
  all_goals simp_all [tablePart2, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

end kanidm_kernel.Verified.MigrationDefaults
