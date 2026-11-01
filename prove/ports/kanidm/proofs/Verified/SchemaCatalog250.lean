import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl15_attr_s256 : AttributeModel := ⟨146#u16,
281470681743897#u128,
[65#u8, 32#u8, 83#u8, 104#u8, 97#u8, 50#u8, 53#u8, 54#u8, 32#u8, 111#u8, 117#u8, 116#u8, 112#u8, 117#u8, 116#u8, 46#u8],
true,
false,
false,
false,
true,
false,
44#u16⟩

@[step] theorem dl15_attr_s256_complete : schema_catalog.dl15_attr_s256 ⦃r => viewAttribute r = expected_dl15_attr_s256⦄ := by
  unfold schema_catalog.dl15_attr_s256
  h5i_steps
  all_goals simp_all [viewAttribute, expected_dl15_attr_s256, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
