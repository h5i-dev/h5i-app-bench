import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_system_class_member_of : ClassModel := ⟨[109#u8, 101#u8, 109#u8, 98#u8, 101#u8, 114#u8, 111#u8, 102#u8],
281470681743408#u128,
[67#u8, 108#u8, 97#u8, 115#u8, 115#u8, 32#u8, 116#u8, 104#u8, 97#u8, 116#u8, 32#u8, 105#u8, 115#u8, 32#u8, 100#u8, 121#u8, 110#u8, 97#u8, 109#u8, 105#u8, 99#u8, 97#u8, 108#u8, 108#u8, 121#u8, 32#u8, 97#u8, 100#u8, 100#u8, 101#u8, 100#u8, 32#u8, 116#u8, 111#u8, 32#u8, 114#u8, 101#u8, 99#u8, 105#u8, 112#u8, 105#u8, 101#u8, 110#u8, 116#u8, 115#u8, 32#u8, 111#u8, 102#u8, 32#u8, 109#u8, 101#u8, 109#u8, 98#u8, 101#u8, 114#u8, 111#u8, 102#u8, 32#u8, 111#u8, 114#u8, 32#u8, 100#u8, 105#u8, 114#u8, 101#u8, 99#u8, 116#u8, 109#u8, 101#u8, 109#u8, 98#u8, 101#u8, 114#u8, 111#u8, 102#u8, 46#u8, 32#u8, 84#u8, 79#u8, 32#u8, 66#u8, 69#u8, 32#u8, 82#u8, 69#u8, 77#u8, 79#u8, 86#u8, 69#u8, 68#u8, 46#u8],
false,
[],
[],
[],
[],
[],
[],
[],
[]⟩

@[step] theorem system_class_member_of_complete : schema_catalog.system_class_member_of ⦃r => viewClass r = expected_system_class_member_of⦄ := by
  unfold schema_catalog.system_class_member_of
  h5i_steps
  all_goals simp_all [viewClass, expected_system_class_member_of, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
