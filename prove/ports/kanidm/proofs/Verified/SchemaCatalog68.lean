import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_system_attr_uid : AttributeModel := ⟨169#u16,
281470681743696#u128,
[65#u8, 110#u8, 32#u8, 76#u8, 68#u8, 65#u8, 80#u8, 32#u8, 67#u8, 111#u8, 109#u8, 112#u8, 97#u8, 116#u8, 105#u8, 98#u8, 108#u8, 101#u8, 32#u8, 117#u8, 105#u8, 100#u8, 46#u8],
false,
false,
true,
false,
false,
false,
0#u16⟩

@[step] theorem system_attr_uid_complete : schema_catalog.system_attr_uid ⦃r => viewAttribute r = expected_system_attr_uid⦄ := by
  unfold schema_catalog.system_attr_uid
  h5i_steps
  all_goals simp_all [viewAttribute, expected_system_attr_uid, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
