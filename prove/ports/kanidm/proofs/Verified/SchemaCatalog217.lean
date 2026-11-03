import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl12_class_account_dl5 : ClassModel := ⟨[97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8],
281470681743430#u128,
[79#u8, 98#u8, 106#u8, 101#u8, 99#u8, 116#u8, 32#u8, 114#u8, 101#u8, 112#u8, 114#u8, 101#u8, 115#u8, 101#u8, 110#u8, 116#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 32#u8, 111#u8, 102#u8, 32#u8, 97#u8, 110#u8, 32#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8],
true,
[1#u16, 3#u16, 101#u16, 67#u16],
[],
[39#u16, 151#u16],
[],
[6#u8, 0#u8, 112#u8, 101#u8, 114#u8, 115#u8, 111#u8, 110#u8, 15#u8, 0#u8, 115#u8, 101#u8, 114#u8, 118#u8, 105#u8, 99#u8, 101#u8, 95#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 22#u8, 0#u8, 111#u8, 97#u8, 117#u8, 116#u8, 104#u8, 50#u8, 95#u8, 114#u8, 101#u8, 115#u8, 111#u8, 117#u8, 114#u8, 99#u8, 101#u8, 95#u8, 115#u8, 101#u8, 114#u8, 118#u8, 101#u8, 114#u8],
[],
[],
[]⟩

@[step] theorem dl12_class_account_dl5_complete : schema_catalog.dl12_class_account_dl5 ⦃r => viewClass r = expected_dl12_class_account_dl5⦄ := by
  unfold schema_catalog.dl12_class_account_dl5
  h5i_steps
  all_goals simp_all [viewClass, expected_dl12_class_account_dl5, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
