import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl_1_12_class_account_signup_request : ClassModel := ⟨[97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 95#u8, 115#u8, 105#u8, 103#u8, 110#u8, 117#u8, 112#u8, 95#u8, 114#u8, 101#u8, 113#u8, 117#u8, 101#u8, 115#u8, 116#u8],
281470681743912#u128,
[65#u8, 32#u8, 112#u8, 101#u8, 110#u8, 100#u8, 105#u8, 110#u8, 103#u8, 32#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 32#u8, 115#u8, 105#u8, 103#u8, 110#u8, 117#u8, 112#u8, 32#u8, 114#u8, 101#u8, 113#u8, 117#u8, 101#u8, 115#u8, 116#u8, 32#u8, 116#u8, 104#u8, 97#u8, 116#u8, 32#u8, 105#u8, 115#u8, 32#u8, 112#u8, 101#u8, 110#u8, 100#u8, 105#u8, 110#u8, 103#u8, 32#u8, 114#u8, 101#u8, 118#u8, 105#u8, 101#u8, 119#u8, 32#u8, 97#u8, 110#u8, 100#u8, 47#u8, 111#u8, 114#u8, 32#u8, 118#u8, 101#u8, 114#u8, 105#u8, 102#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8],
false,
[],
[],
[100#u16, 39#u16, 92#u16, 35#u16],
[],
[],
[],
[],
[]⟩

@[step] theorem dl_1_12_class_account_signup_request_complete : schema_catalog.dl_1_12_class_account_signup_request ⦃r => viewClass r = expected_dl_1_12_class_account_signup_request⦄ := by
  unfold schema_catalog.dl_1_12_class_account_signup_request
  h5i_steps
  all_goals simp_all [viewClass, expected_dl_1_12_class_account_signup_request, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
