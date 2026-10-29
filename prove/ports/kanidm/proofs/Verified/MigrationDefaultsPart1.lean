import Verified.MigrationDefaultsData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.MigrationDefaults
set_option maxRecDepth 16384
set_option maxHeartbeats 8000000
@[step] theorem table_part_3_spec : migration_defaults.table_part_3 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart3 ⦄ := by
  unfold migration_defaults.table_part_3
  h5i_steps
  all_goals simp_all [tablePart3, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_4_spec : migration_defaults.table_part_4 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart4 ⦄ := by
  unfold migration_defaults.table_part_4
  h5i_steps
  all_goals simp_all [tablePart4, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_5_spec : migration_defaults.table_part_5 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart5 ⦄ := by
  unfold migration_defaults.table_part_5
  h5i_steps
  all_goals simp_all [tablePart5, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

end kanidm_kernel.Verified.MigrationDefaults
