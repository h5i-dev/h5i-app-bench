import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_system_class_access_control_delete : ClassModel := ⟨[97#u8, 99#u8, 99#u8, 101#u8, 115#u8, 115#u8, 95#u8, 99#u8, 111#u8, 110#u8, 116#u8, 114#u8, 111#u8, 108#u8, 95#u8, 100#u8, 101#u8, 108#u8, 101#u8, 116#u8, 101#u8],
281470681743414#u128,
[83#u8, 121#u8, 115#u8, 116#u8, 101#u8, 109#u8, 32#u8, 65#u8, 99#u8, 99#u8, 101#u8, 115#u8, 115#u8, 32#u8, 67#u8, 111#u8, 110#u8, 116#u8, 114#u8, 111#u8, 108#u8, 32#u8, 68#u8, 69#u8, 76#u8, 69#u8, 84#u8, 69#u8, 32#u8, 67#u8, 108#u8, 97#u8, 115#u8, 115#u8],
false,
[],
[],
[],
[],
[],
[],
[],
[]⟩

@[step] theorem system_class_access_control_delete_complete : schema_catalog.system_class_access_control_delete ⦃r => viewClass r = expected_system_class_access_control_delete⦄ := by
  unfold schema_catalog.system_class_access_control_delete
  h5i_steps
  all_goals simp_all [viewClass, expected_system_class_access_control_delete, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
