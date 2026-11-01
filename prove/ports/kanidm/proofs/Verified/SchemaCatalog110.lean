import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl11_attr_fernet_private_key_str : AttributeModel := ⟨62#u16,
281470681743509#u128,
[84#u8, 104#u8, 101#u8, 32#u8, 116#u8, 111#u8, 107#u8, 101#u8, 110#u8, 32#u8, 101#u8, 110#u8, 99#u8, 114#u8, 121#u8, 112#u8, 116#u8, 105#u8, 111#u8, 110#u8, 32#u8, 112#u8, 114#u8, 105#u8, 118#u8, 97#u8, 116#u8, 101#u8, 32#u8, 107#u8, 101#u8, 121#u8],
false,
false,
false,
false,
true,
false,
9#u16⟩

@[step] theorem dl11_attr_fernet_private_key_str_complete : schema_catalog.dl11_attr_fernet_private_key_str ⦃r => viewAttribute r = expected_dl11_attr_fernet_private_key_str⦄ := by
  unfold schema_catalog.dl11_attr_fernet_private_key_str
  h5i_steps
  all_goals simp_all [viewAttribute, expected_dl11_attr_fernet_private_key_str, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
