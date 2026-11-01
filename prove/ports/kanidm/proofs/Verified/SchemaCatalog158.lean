import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl11_attr_key_provider_dl6 : AttributeModel := ⟨80#u16,
281470681743728#u128,
[45#u8],
false,
false,
false,
false,
true,
true,
6#u16⟩

@[step] theorem dl11_attr_key_provider_dl6_complete : schema_catalog.dl11_attr_key_provider_dl6 ⦃r => viewAttribute r = expected_dl11_attr_key_provider_dl6⦄ := by
  unfold schema_catalog.dl11_attr_key_provider_dl6
  h5i_steps
  all_goals simp_all [viewAttribute, expected_dl11_attr_key_provider_dl6, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
