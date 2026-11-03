import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl11_attr_ssh_publickey : AttributeModel := ⟨152#u16,
281470681743426#u128,
[83#u8, 83#u8, 72#u8, 32#u8, 112#u8, 117#u8, 98#u8, 108#u8, 105#u8, 99#u8, 32#u8, 107#u8, 101#u8, 121#u8, 115#u8, 32#u8, 111#u8, 102#u8, 32#u8, 116#u8, 104#u8, 101#u8, 32#u8, 111#u8, 98#u8, 106#u8, 101#u8, 99#u8, 116#u8],
true,
false,
false,
true,
true,
false,
10#u16⟩

@[step] theorem dl11_attr_ssh_publickey_complete : schema_catalog.dl11_attr_ssh_publickey ⦃r => viewAttribute r = expected_dl11_attr_ssh_publickey⦄ := by
  unfold schema_catalog.dl11_attr_ssh_publickey
  h5i_steps
  all_goals simp_all [viewAttribute, expected_dl11_attr_ssh_publickey, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
