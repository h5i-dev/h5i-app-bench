import Verified.MigrationDefaultsData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.MigrationDefaults
set_option maxRecDepth 16384
set_option maxHeartbeats 8000000
@[step] theorem table_part_21_spec : migration_defaults.table_part_21 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart21 ⦄ := by
  unfold migration_defaults.table_part_21
  h5i_steps
  all_goals simp_all [tablePart21, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_22_spec : migration_defaults.table_part_22 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart22 ⦄ := by
  unfold migration_defaults.table_part_22
  h5i_steps
  all_goals simp_all [tablePart22, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_23_spec : migration_defaults.table_part_23 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart23 ⦄ := by
  unfold migration_defaults.table_part_23
  h5i_steps
  all_goals simp_all [tablePart23, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

end kanidm_kernel.Verified.MigrationDefaults
