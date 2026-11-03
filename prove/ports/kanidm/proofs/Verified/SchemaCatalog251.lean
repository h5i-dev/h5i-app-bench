import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl15_class_oauth2_account : ClassModel := ⟨[111#u8, 97#u8, 117#u8, 116#u8, 104#u8, 50#u8, 95#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8],
281470681743881#u128,
[77#u8, 97#u8, 114#u8, 107#u8, 101#u8, 114#u8, 32#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 32#u8, 100#u8, 101#u8, 115#u8, 105#u8, 103#u8, 110#u8, 97#u8, 116#u8, 105#u8, 110#u8, 103#u8, 32#u8, 116#u8, 104#u8, 97#u8, 116#u8, 32#u8, 97#u8, 110#u8, 32#u8, 99#u8, 97#u8, 110#u8, 32#u8, 117#u8, 115#u8, 101#u8, 32#u8, 79#u8, 65#u8, 117#u8, 116#u8, 104#u8, 50#u8, 32#u8, 102#u8, 111#u8, 114#u8, 32#u8, 97#u8, 117#u8, 116#u8, 104#u8, 101#u8, 110#u8, 116#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 46#u8],
true,
[],
[],
[104#u16, 105#u16, 106#u16, 103#u16],
[],
[6#u8, 0#u8, 112#u8, 101#u8, 114#u8, 115#u8, 111#u8, 110#u8],
[],
[],
[]⟩

@[step] theorem dl15_class_oauth2_account_complete : schema_catalog.dl15_class_oauth2_account ⦃r => viewClass r = expected_dl15_class_oauth2_account⦄ := by
  unfold schema_catalog.dl15_class_oauth2_account
  h5i_steps
  all_goals simp_all [viewClass, expected_dl15_class_oauth2_account, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
