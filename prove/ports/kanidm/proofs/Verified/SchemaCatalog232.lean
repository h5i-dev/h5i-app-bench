import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl13_class_oauth2_rs_dl9 : ClassModel := ⟨[111#u8, 97#u8, 117#u8, 116#u8, 104#u8, 50#u8, 95#u8, 114#u8, 101#u8, 115#u8, 111#u8, 117#u8, 114#u8, 99#u8, 101#u8, 95#u8, 115#u8, 101#u8, 114#u8, 118#u8, 101#u8, 114#u8],
281470681743493#u128,
[84#u8, 104#u8, 101#u8, 32#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 32#u8, 101#u8, 112#u8, 114#u8, 101#u8, 115#u8, 101#u8, 110#u8, 116#u8, 105#u8, 110#u8, 103#u8, 32#u8, 97#u8, 32#u8, 99#u8, 111#u8, 110#u8, 102#u8, 105#u8, 103#u8, 117#u8, 114#u8, 101#u8, 100#u8, 32#u8, 79#u8, 65#u8, 117#u8, 116#u8, 104#u8, 50#u8, 32#u8, 67#u8, 108#u8, 105#u8, 101#u8, 110#u8, 116#u8],
false,
[37#u16, 125#u16, 126#u16, 115#u16, 116#u16, 70#u16, 120#u16, 128#u16, 123#u16, 129#u16, 114#u16, 112#u16, 145#u16, 127#u16, 60#u16],
[],
[124#u16, 100#u16],
[],
[],
[],
[],
[]⟩

@[step] theorem dl13_class_oauth2_rs_dl9_complete : schema_catalog.dl13_class_oauth2_rs_dl9 ⦃r => viewClass r = expected_dl13_class_oauth2_rs_dl9⦄ := by
  unfold schema_catalog.dl13_class_oauth2_rs_dl9
  h5i_steps
  all_goals simp_all [viewClass, expected_dl13_class_oauth2_rs_dl9, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
