import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_system_class_attribute_type : ClassModel := ⟨[97#u8, 116#u8, 116#u8, 114#u8, 105#u8, 98#u8, 117#u8, 116#u8, 101#u8, 116#u8, 121#u8, 112#u8, 101#u8],
281470681743398#u128,
[68#u8, 101#u8, 102#u8, 105#u8, 110#u8, 105#u8, 116#u8, 105#u8, 111#u8, 110#u8, 32#u8, 111#u8, 102#u8, 32#u8, 97#u8, 32#u8, 115#u8, 99#u8, 104#u8, 101#u8, 109#u8, 97#u8, 32#u8, 97#u8, 116#u8, 116#u8, 114#u8, 105#u8, 98#u8, 117#u8, 116#u8, 101#u8],
false,
[144#u16, 137#u16, 155#u16, 72#u16, 73#u16],
[],
[29#u16, 21#u16, 98#u16, 171#u16, 163#u16, 37#u16],
[],
[],
[],
[9#u8, 0#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 116#u8, 121#u8, 112#u8, 101#u8],
[]⟩

@[step] theorem system_class_attribute_type_complete : schema_catalog.system_class_attribute_type ⦃r => viewClass r = expected_system_class_attribute_type⦄ := by
  unfold schema_catalog.system_class_attribute_type
  h5i_steps
  all_goals simp_all [viewClass, expected_system_class_attribute_type, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
