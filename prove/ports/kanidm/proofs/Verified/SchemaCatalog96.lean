import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl11_attr_primary_credential : AttributeModel := ⟨138#u16,
281470681743427#u128,
[80#u8, 114#u8, 105#u8, 109#u8, 97#u8, 114#u8, 121#u8, 32#u8, 99#u8, 114#u8, 101#u8, 100#u8, 101#u8, 110#u8, 116#u8, 105#u8, 97#u8, 108#u8, 32#u8, 109#u8, 97#u8, 116#u8, 101#u8, 114#u8, 105#u8, 97#u8, 108#u8, 32#u8, 111#u8, 102#u8, 32#u8, 116#u8, 104#u8, 101#u8, 32#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 32#u8, 102#u8, 111#u8, 114#u8, 32#u8, 97#u8, 117#u8, 116#u8, 104#u8, 101#u8, 110#u8, 116#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 32#u8, 105#u8, 110#u8, 116#u8, 101#u8, 114#u8, 97#u8, 99#u8, 116#u8, 105#u8, 118#u8, 101#u8, 108#u8, 121#u8],
false,
false,
false,
true,
true,
true,
8#u16⟩

@[step] theorem dl11_attr_primary_credential_complete : schema_catalog.dl11_attr_primary_credential ⦃r => viewAttribute r = expected_dl11_attr_primary_credential⦄ := by
  unfold schema_catalog.dl11_attr_primary_credential
  h5i_steps
  all_goals simp_all [viewAttribute, expected_dl11_attr_primary_credential, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
