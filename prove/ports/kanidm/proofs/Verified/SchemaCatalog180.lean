import Verified.SchemaCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl11_class_domain_info_dl10 : ClassModel := ⟨[100#u8, 111#u8, 109#u8, 97#u8, 105#u8, 110#u8, 95#u8, 105#u8, 110#u8, 102#u8, 111#u8],
281470681743442#u128,
[76#u8, 111#u8, 99#u8, 97#u8, 108#u8, 32#u8, 100#u8, 111#u8, 109#u8, 97#u8, 105#u8, 110#u8, 32#u8, 105#u8, 110#u8, 102#u8, 111#u8, 114#u8, 109#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 32#u8, 97#u8, 110#u8, 100#u8, 32#u8, 99#u8, 111#u8, 110#u8, 102#u8, 105#u8, 103#u8, 117#u8, 114#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8],
false,
[48#u16, 46#u16, 85#u16, 82#u16, 70#u16, 136#u16, 44#u16, 43#u16, 45#u16],
[],
[100#u16, 50#u16, 47#u16, 176#u16],
[],
[],
[],
[],
[]⟩

@[step] theorem dl11_class_domain_info_dl10_complete : schema_catalog.dl11_class_domain_info_dl10 ⦃r => viewClass r = expected_dl11_class_domain_info_dl10⦄ := by
  unfold schema_catalog.dl11_class_domain_info_dl10
  h5i_steps
  all_goals simp_all [viewClass, expected_dl11_class_domain_info_dl10, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.SchemaCatalog
