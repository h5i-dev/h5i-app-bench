import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl11_attr_certificate_dl7 : AttributeModel := ⟨27#u16,
281470681743736#u128,
[65#u8, 110#u8, 32#u8, 120#u8, 53#u8, 48#u8, 57#u8, 32#u8, 67#u8, 101#u8, 114#u8, 116#u8, 105#u8, 102#u8, 105#u8, 99#u8, 97#u8, 116#u8, 101#u8],
false,
false,
false,
false,
true,
false,
40#u16⟩

@[step] theorem dl11_attr_certificate_dl7_complete : schema_catalog.dl11_attr_certificate_dl7 ⦃r => viewAttribute r = expected_dl11_attr_certificate_dl7⦄ := by
  unfold schema_catalog.dl11_attr_certificate_dl7
  h5i_steps
  all_goals simp_all [viewAttribute, expected_dl11_attr_certificate_dl7, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
