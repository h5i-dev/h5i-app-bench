import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl11_attr_jws_es256_private_key : AttributeModel := ⟨74#u16,
281470681743632#u128,
[65#u8, 110#u8, 32#u8, 101#u8, 115#u8, 50#u8, 53#u8, 54#u8, 32#u8, 112#u8, 114#u8, 105#u8, 118#u8, 97#u8, 116#u8, 101#u8, 32#u8, 107#u8, 101#u8, 121#u8, 32#u8, 102#u8, 111#u8, 114#u8, 32#u8, 106#u8, 119#u8, 115#u8],
false,
true,
false,
false,
true,
true,
26#u16⟩

@[step] theorem dl11_attr_jws_es256_private_key_complete : schema_catalog.dl11_attr_jws_es256_private_key ⦃r => viewAttribute r = expected_dl11_attr_jws_es256_private_key⦄ := by
  unfold schema_catalog.dl11_attr_jws_es256_private_key
  h5i_steps
  all_goals simp_all [viewAttribute, expected_dl11_attr_jws_es256_private_key, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
