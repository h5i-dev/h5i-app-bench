import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl13_class_assertion_nonce : ClassModel := ⟨[97#u8, 115#u8, 115#u8, 101#u8, 114#u8, 116#u8, 105#u8, 111#u8, 110#u8, 95#u8, 110#u8, 111#u8, 110#u8, 99#u8, 101#u8],
281470681743905#u128,
[84#u8, 104#u8, 101#u8, 32#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 32#u8, 114#u8, 101#u8, 112#u8, 114#u8, 101#u8, 115#u8, 101#u8, 110#u8, 116#u8, 105#u8, 110#u8, 103#u8, 32#u8, 116#u8, 104#u8, 101#u8, 32#u8, 110#u8, 111#u8, 110#u8, 99#u8, 101#u8, 32#u8, 116#u8, 105#u8, 101#u8, 100#u8, 32#u8, 116#u8, 111#u8, 32#u8, 97#u8, 110#u8, 32#u8, 97#u8, 115#u8, 115#u8, 101#u8, 114#u8, 116#u8, 105#u8, 111#u8, 110#u8, 32#u8, 101#u8, 118#u8, 101#u8, 110#u8, 116#u8, 32#u8, 115#u8, 111#u8, 32#u8, 116#u8, 104#u8, 97#u8, 116#u8, 32#u8, 105#u8, 116#u8, 32#u8, 105#u8, 115#u8, 32#u8, 111#u8, 110#u8, 108#u8, 121#u8, 32#u8, 97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 101#u8, 100#u8, 32#u8, 111#u8, 110#u8, 99#u8, 101#u8, 46#u8],
false,
[],
[],
[175#u16, 146#u16],
[],
[],
[],
[],
[]⟩

@[step] theorem dl13_class_assertion_nonce_complete : schema_catalog.dl13_class_assertion_nonce ⦃r => viewClass r = expected_dl13_class_assertion_nonce⦄ := by
  unfold schema_catalog.dl13_class_assertion_nonce
  h5i_steps
  all_goals simp_all [viewClass, expected_dl13_class_assertion_nonce, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
