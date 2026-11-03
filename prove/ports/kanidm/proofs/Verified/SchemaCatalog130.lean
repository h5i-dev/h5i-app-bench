import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl11_attr_oauth2_rs_token_key : AttributeModel := ⟨127#u16,
281470681743492#u128,
[65#u8, 110#u8, 32#u8, 111#u8, 97#u8, 117#u8, 116#u8, 104#u8, 50#u8, 32#u8, 114#u8, 101#u8, 115#u8, 111#u8, 117#u8, 114#u8, 99#u8, 101#u8, 32#u8, 115#u8, 101#u8, 114#u8, 118#u8, 101#u8, 114#u8, 115#u8, 32#u8, 117#u8, 110#u8, 105#u8, 113#u8, 117#u8, 101#u8, 32#u8, 116#u8, 111#u8, 107#u8, 101#u8, 110#u8, 32#u8, 115#u8, 105#u8, 103#u8, 110#u8, 105#u8, 110#u8, 103#u8, 32#u8, 107#u8, 101#u8, 121#u8],
false,
false,
false,
false,
true,
false,
9#u16⟩

@[step] theorem dl11_attr_oauth2_rs_token_key_complete : schema_catalog.dl11_attr_oauth2_rs_token_key ⦃r => viewAttribute r = expected_dl11_attr_oauth2_rs_token_key⦄ := by
  unfold schema_catalog.dl11_attr_oauth2_rs_token_key
  h5i_steps
  all_goals simp_all [viewAttribute, expected_dl11_attr_oauth2_rs_token_key, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
