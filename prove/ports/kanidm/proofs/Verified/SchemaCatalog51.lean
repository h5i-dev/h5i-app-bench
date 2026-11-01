import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_system_attr_sync_parent_uuid : AttributeModel := ⟨160#u16,
281470681743650#u128,
[84#u8, 104#u8, 101#u8, 32#u8, 85#u8, 85#u8, 73#u8, 68#u8, 32#u8, 111#u8, 102#u8, 32#u8, 116#u8, 104#u8, 101#u8, 32#u8, 112#u8, 97#u8, 114#u8, 101#u8, 110#u8, 116#u8, 32#u8, 115#u8, 121#u8, 110#u8, 99#u8, 32#u8, 97#u8, 103#u8, 114#u8, 101#u8, 101#u8, 109#u8, 101#u8, 110#u8, 116#u8, 32#u8, 116#u8, 104#u8, 97#u8, 116#u8, 32#u8, 99#u8, 114#u8, 101#u8, 97#u8, 116#u8, 101#u8, 100#u8, 32#u8, 116#u8, 104#u8, 105#u8, 115#u8, 32#u8, 101#u8, 110#u8, 116#u8, 114#u8, 121#u8, 46#u8],
false,
false,
false,
false,
true,
true,
6#u16⟩

@[step] theorem system_attr_sync_parent_uuid_complete : schema_catalog.system_attr_sync_parent_uuid ⦃r => viewAttribute r = expected_system_attr_sync_parent_uuid⦄ := by
  unfold schema_catalog.system_attr_sync_parent_uuid
  h5i_steps
  all_goals simp_all [viewAttribute, expected_system_attr_sync_parent_uuid, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
