import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl12_attr_oauth2_client_id : AttributeModel := ⟨110#u16,
281470681743875#u128,
[84#u8, 104#u8, 101#u8, 32#u8, 79#u8, 65#u8, 117#u8, 116#u8, 104#u8, 50#u8, 32#u8, 67#u8, 108#u8, 105#u8, 101#u8, 110#u8, 116#u8, 32#u8, 73#u8, 68#u8],
false,
false,
false,
false,
true,
false,
0#u16⟩

@[step] theorem dl12_attr_oauth2_client_id_complete : schema_catalog.dl12_attr_oauth2_client_id ⦃r => viewAttribute r = expected_dl12_attr_oauth2_client_id⦄ := by
  unfold schema_catalog.dl12_attr_oauth2_client_id
  h5i_steps
  all_goals simp_all [viewAttribute, expected_dl12_attr_oauth2_client_id, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
