import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_system_class_object : ClassModel := ⟨[111#u8, 98#u8, 106#u8, 101#u8, 99#u8, 116#u8],
281470681743400#u128,
[65#u8, 32#u8, 115#u8, 121#u8, 115#u8, 116#u8, 101#u8, 109#u8, 32#u8, 99#u8, 114#u8, 101#u8, 97#u8, 116#u8, 101#u8, 100#u8, 32#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 32#u8, 116#u8, 104#u8, 97#u8, 116#u8, 32#u8, 97#u8, 108#u8, 108#u8, 32#u8, 111#u8, 98#u8, 106#u8, 101#u8, 99#u8, 116#u8, 115#u8, 32#u8, 109#u8, 117#u8, 115#u8, 116#u8, 32#u8, 99#u8, 111#u8, 110#u8, 116#u8, 97#u8, 105#u8, 110#u8],
false,
[37#u16, 58#u16, 96#u16, 38#u16],
[],
[29#u16, 175#u16, 81#u16, 32#u16],
[],
[],
[],
[],
[]⟩

@[step] theorem system_class_object_complete : schema_catalog.system_class_object ⦃r => viewClass r = expected_system_class_object⦄ := by
  unfold schema_catalog.system_class_object
  h5i_steps
  all_goals simp_all [viewClass, expected_system_class_object, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
