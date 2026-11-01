import Verified.GroupCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.GroupCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl14_builtin_group_people_self_name_write_dl7 : GroupModel := ⟨[105#u8, 100#u8, 109#u8, 95#u8, 112#u8, 101#u8, 111#u8, 112#u8, 108#u8, 101#u8, 95#u8, 115#u8, 101#u8, 108#u8, 102#u8, 95#u8, 110#u8, 97#u8, 109#u8, 101#u8, 95#u8, 119#u8, 114#u8, 105#u8, 116#u8, 101#u8],
[66#u8, 117#u8, 105#u8, 108#u8, 116#u8, 105#u8, 110#u8, 32#u8, 73#u8, 68#u8, 77#u8, 32#u8, 71#u8, 114#u8, 111#u8, 117#u8, 112#u8, 32#u8, 100#u8, 101#u8, 110#u8, 111#u8, 116#u8, 105#u8, 110#u8, 103#u8, 32#u8, 117#u8, 115#u8, 101#u8, 114#u8, 115#u8, 32#u8, 116#u8, 104#u8, 97#u8, 116#u8, 32#u8, 99#u8, 97#u8, 110#u8, 32#u8, 119#u8, 114#u8, 105#u8, 116#u8, 101#u8, 32#u8, 116#u8, 111#u8, 32#u8, 116#u8, 104#u8, 101#u8, 105#u8, 114#u8, 32#u8, 111#u8, 119#u8, 110#u8, 32#u8, 110#u8, 97#u8, 109#u8, 101#u8, 32#u8, 97#u8, 116#u8, 116#u8, 114#u8, 105#u8, 98#u8, 117#u8, 116#u8, 101#u8, 115#u8, 46#u8],
72#u128,
[],
[53#u128],
true,
1#u128,
false,
[],
[]⟩

@[step] theorem dl14_builtin_group_people_self_name_write_dl7_complete : group_catalog.dl14_builtin_group_people_self_name_write_dl7 ⦃r => viewGroup r = expected_dl14_builtin_group_people_self_name_write_dl7⦄ := by
  unfold group_catalog.dl14_builtin_group_people_self_name_write_dl7
  h5i_steps
  all_goals simp_all [viewGroup, expected_dl14_builtin_group_people_self_name_write_dl7, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.GroupCatalog
