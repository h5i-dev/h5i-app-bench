import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl12_attr_send_after : AttributeModel := ⟨148#u16,
281470681743767#u128,
[84#u8, 104#u8, 101#u8, 32#u8, 100#u8, 97#u8, 116#u8, 101#u8, 116#u8, 105#u8, 109#u8, 101#u8, 32#u8, 97#u8, 102#u8, 116#u8, 101#u8, 114#u8, 32#u8, 119#u8, 104#u8, 105#u8, 99#u8, 104#u8, 32#u8, 116#u8, 104#u8, 105#u8, 115#u8, 32#u8, 109#u8, 101#u8, 115#u8, 115#u8, 97#u8, 103#u8, 101#u8, 32#u8, 105#u8, 115#u8, 32#u8, 97#u8, 108#u8, 108#u8, 111#u8, 119#u8, 101#u8, 100#u8, 32#u8, 116#u8, 111#u8, 32#u8, 98#u8, 101#u8, 32#u8, 114#u8, 101#u8, 108#u8, 101#u8, 97#u8, 115#u8, 101#u8, 100#u8, 32#u8, 116#u8, 111#u8, 32#u8, 116#u8, 104#u8, 101#u8, 32#u8, 100#u8, 101#u8, 115#u8, 116#u8, 105#u8, 110#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8],
false,
false,
false,
false,
true,
true,
16#u16⟩

@[step] theorem dl12_attr_send_after_complete : schema_catalog.dl12_attr_send_after ⦃r => viewAttribute r = expected_dl12_attr_send_after⦄ := by
  unfold schema_catalog.dl12_attr_send_after
  h5i_steps
  all_goals simp_all [viewAttribute, expected_dl12_attr_send_after, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
