import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl11_class_application : ClassModel := ⟨[97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8],
281470681743745#u128,
[84#u8, 104#u8, 101#u8, 32#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 32#u8, 114#u8, 101#u8, 112#u8, 114#u8, 101#u8, 115#u8, 101#u8, 110#u8, 116#u8, 105#u8, 110#u8, 103#u8, 32#u8, 97#u8, 110#u8, 32#u8, 97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8],
false,
[19#u16],
[],
[90#u16],
[],
[15#u8, 0#u8, 115#u8, 101#u8, 114#u8, 118#u8, 105#u8, 99#u8, 101#u8, 95#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8],
[],
[],
[]⟩

@[step] theorem dl11_class_application_complete : schema_catalog.dl11_class_application ⦃r => viewClass r = expected_dl11_class_application⦄ := by
  unfold schema_catalog.dl11_class_application
  h5i_steps
  all_goals simp_all [viewClass, expected_dl11_class_application, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
