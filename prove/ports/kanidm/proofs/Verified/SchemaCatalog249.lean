import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl15_attr_oauth2_token_introspect_endpoint : AttributeModel := ⟨131#u16,
281470681743911#u128,
[84#u8, 104#u8, 101#u8, 32#u8, 114#u8, 102#u8, 99#u8, 55#u8, 54#u8, 54#u8, 50#u8, 32#u8, 116#u8, 111#u8, 107#u8, 101#u8, 110#u8, 32#u8, 105#u8, 110#u8, 116#u8, 114#u8, 111#u8, 115#u8, 112#u8, 101#u8, 99#u8, 116#u8, 32#u8, 117#u8, 114#u8, 108#u8, 32#u8, 111#u8, 102#u8, 32#u8, 116#u8, 104#u8, 101#u8, 32#u8, 79#u8, 65#u8, 117#u8, 116#u8, 104#u8, 50#u8, 32#u8, 112#u8, 114#u8, 111#u8, 118#u8, 105#u8, 100#u8, 101#u8, 114#u8],
false,
false,
false,
false,
true,
false,
18#u16⟩

@[step] theorem dl15_attr_oauth2_token_introspect_endpoint_complete : schema_catalog.dl15_attr_oauth2_token_introspect_endpoint ⦃r => viewAttribute r = expected_dl15_attr_oauth2_token_introspect_endpoint⦄ := by
  unfold schema_catalog.dl15_attr_oauth2_token_introspect_endpoint
  h5i_steps
  all_goals simp_all [viewAttribute, expected_dl15_attr_oauth2_token_introspect_endpoint, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
