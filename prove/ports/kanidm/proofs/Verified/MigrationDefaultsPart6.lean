import Verified.MigrationDefaultsData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.MigrationDefaults
set_option maxRecDepth 16384
set_option maxHeartbeats 8000000
@[step] theorem table_part_18_spec : migration_defaults.table_part_18 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart18 ⦄ := by
  unfold migration_defaults.table_part_18
  h5i_steps
  all_goals simp_all [tablePart18, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_19_spec : migration_defaults.table_part_19 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart19 ⦄ := by
  unfold migration_defaults.table_part_19
  h5i_steps
  all_goals simp_all [tablePart19, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

@[step] theorem table_part_20_spec : migration_defaults.table_part_20 ⦃ r => r.val.map alloc.vec.Vec.val = tablePart20 ⦄ := by
  unfold migration_defaults.table_part_20
  h5i_steps
  all_goals simp_all [tablePart20, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

end kanidm_kernel.Verified.MigrationDefaults
