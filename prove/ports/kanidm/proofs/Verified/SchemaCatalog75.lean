import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_system_class_builtin : ClassModel := ⟨[98#u8, 117#u8, 105#u8, 108#u8, 116#u8, 105#u8, 110#u8],
281470681743715#u128,
[65#u8, 32#u8, 109#u8, 97#u8, 114#u8, 107#u8, 101#u8, 114#u8, 32#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 32#u8, 100#u8, 101#u8, 110#u8, 111#u8, 116#u8, 105#u8, 110#u8, 103#u8, 32#u8, 98#u8, 117#u8, 105#u8, 108#u8, 116#u8, 105#u8, 110#u8, 32#u8, 101#u8, 110#u8, 116#u8, 114#u8, 105#u8, 101#u8, 115#u8],
false,
[],
[],
[],
[],
[],
[],
[],
[]⟩

@[step] theorem system_class_builtin_complete : schema_catalog.system_class_builtin ⦃r => viewClass r = expected_system_class_builtin⦄ := by
  unfold schema_catalog.system_class_builtin
  h5i_steps
  all_goals simp_all [viewClass, expected_system_class_builtin, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
