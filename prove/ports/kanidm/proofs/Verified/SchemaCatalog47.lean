import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_system_attr_domain : AttributeModel := ⟨41#u16,
281470681743382#u128,
[65#u8, 32#u8, 68#u8, 78#u8, 83#u8, 32#u8, 68#u8, 111#u8, 109#u8, 97#u8, 105#u8, 110#u8, 32#u8, 110#u8, 97#u8, 109#u8, 101#u8, 32#u8, 101#u8, 110#u8, 116#u8, 114#u8, 121#u8, 46#u8],
true,
false,
false,
false,
true,
true,
14#u16⟩

@[step] theorem system_attr_domain_complete : schema_catalog.system_attr_domain ⦃r => viewAttribute r = expected_system_attr_domain⦄ := by
  unfold schema_catalog.system_attr_domain
  h5i_steps
  all_goals simp_all [viewAttribute, expected_system_attr_domain, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
