import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl14_attr_key_internal_data_dl6 : AttributeModel := ⟨79#u16,
281470681743721#u128,
[73#u8, 110#u8, 116#u8, 101#u8, 114#u8, 110#u8, 97#u8, 108#u8, 32#u8, 75#u8, 101#u8, 121#u8, 32#u8, 68#u8, 97#u8, 116#u8, 97#u8],
true,
false,
false,
false,
true,
false,
38#u16⟩

@[step] theorem dl14_attr_key_internal_data_dl6_complete : schema_catalog.dl14_attr_key_internal_data_dl6 ⦃r => viewAttribute r = expected_dl14_attr_key_internal_data_dl6⦄ := by
  unfold schema_catalog.dl14_attr_key_internal_data_dl6
  h5i_steps
  all_goals simp_all [viewAttribute, expected_dl14_attr_key_internal_data_dl6, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
