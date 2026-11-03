import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl14_attr_key_action_import_jws_rs256_dl6 : AttributeModel := ⟨76#u16,
281470681743761#u128,
[77#u8, 97#u8, 114#u8, 107#u8, 101#u8, 114#u8, 32#u8, 97#u8, 116#u8, 116#u8, 114#u8, 105#u8, 98#u8, 117#u8, 116#u8, 101#u8, 32#u8, 116#u8, 104#u8, 97#u8, 116#u8, 32#u8, 100#u8, 101#u8, 110#u8, 111#u8, 116#u8, 101#u8, 115#u8, 32#u8, 97#u8, 32#u8, 106#u8, 119#u8, 115#u8, 32#u8, 114#u8, 115#u8, 50#u8, 53#u8, 54#u8, 32#u8, 107#u8, 101#u8, 121#u8, 32#u8, 116#u8, 111#u8, 32#u8, 98#u8, 101#u8, 32#u8, 105#u8, 109#u8, 112#u8, 111#u8, 114#u8, 116#u8, 101#u8, 100#u8, 46#u8],
true,
false,
true,
false,
true,
false,
21#u16⟩

@[step] theorem dl14_attr_key_action_import_jws_rs256_dl6_complete : schema_catalog.dl14_attr_key_action_import_jws_rs256_dl6 ⦃r => viewAttribute r = expected_dl14_attr_key_action_import_jws_rs256_dl6⦄ := by
  unfold schema_catalog.dl14_attr_key_action_import_jws_rs256_dl6
  h5i_steps
  all_goals simp_all [viewAttribute, expected_dl14_attr_key_action_import_jws_rs256_dl6, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
