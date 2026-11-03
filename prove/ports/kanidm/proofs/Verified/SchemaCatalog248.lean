import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl15_attr_oauth2_account_unique_user_sub : AttributeModel := ⟨106#u16,
281470681743910#u128,
[84#u8, 104#u8, 101#u8, 32#u8, 117#u8, 110#u8, 105#u8, 113#u8, 117#u8, 101#u8, 32#u8, 117#u8, 115#u8, 101#u8, 114#u8, 32#u8, 115#u8, 117#u8, 98#u8, 106#u8, 101#u8, 99#u8, 116#u8, 32#u8, 111#u8, 102#u8, 32#u8, 116#u8, 104#u8, 105#u8, 115#u8, 32#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 32#u8, 97#u8, 115#u8, 32#u8, 107#u8, 110#u8, 111#u8, 119#u8, 110#u8, 32#u8, 98#u8, 121#u8, 32#u8, 116#u8, 104#u8, 101#u8, 32#u8, 114#u8, 101#u8, 109#u8, 111#u8, 116#u8, 101#u8, 32#u8, 79#u8, 65#u8, 117#u8, 116#u8, 104#u8, 50#u8, 32#u8, 112#u8, 114#u8, 111#u8, 118#u8, 105#u8, 100#u8, 101#u8, 114#u8, 46#u8],
false,
false,
false,
true,
true,
false,
0#u16⟩

@[step] theorem dl15_attr_oauth2_account_unique_user_sub_complete : schema_catalog.dl15_attr_oauth2_account_unique_user_sub ⦃r => viewAttribute r = expected_dl15_attr_oauth2_account_unique_user_sub⦄ := by
  unfold schema_catalog.dl15_attr_oauth2_account_unique_user_sub
  h5i_steps
  all_goals simp_all [viewAttribute, expected_dl15_attr_oauth2_account_unique_user_sub, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
