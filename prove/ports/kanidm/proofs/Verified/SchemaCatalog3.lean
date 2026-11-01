import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_system_attr_created_at_cid : AttributeModel := ⟨32#u16,
281470681743748#u128,
[84#u8, 104#u8, 101#u8, 32#u8, 99#u8, 105#u8, 100#u8, 32#u8, 119#u8, 104#u8, 101#u8, 110#u8, 32#u8, 116#u8, 104#u8, 105#u8, 115#u8, 32#u8, 101#u8, 110#u8, 116#u8, 114#u8, 121#u8, 32#u8, 119#u8, 97#u8, 115#u8, 32#u8, 99#u8, 114#u8, 101#u8, 97#u8, 116#u8, 101#u8, 100#u8],
false,
false,
false,
false,
false,
false,
13#u16⟩

@[step] theorem system_attr_created_at_cid_complete : schema_catalog.system_attr_created_at_cid ⦃r => viewAttribute r = expected_system_attr_created_at_cid⦄ := by
  unfold schema_catalog.system_attr_created_at_cid
  h5i_steps
  all_goals simp_all [viewAttribute, expected_system_attr_created_at_cid, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
