import Verified.AcpCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.AcpCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl12_service_account_entry_manager_v1 : Model := ⟨[19#u16, 3#u16, 2#u16, 4#u16],
[105#u8, 100#u8, 109#u8, 95#u8, 97#u8, 99#u8, 112#u8, 95#u8, 115#u8, 101#u8, 114#u8, 118#u8, 105#u8, 99#u8, 101#u8, 95#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 95#u8, 101#u8, 110#u8, 116#u8, 114#u8, 121#u8, 95#u8, 109#u8, 97#u8, 110#u8, 97#u8, 103#u8, 101#u8, 114#u8],
281474959933537#u128,
[66#u8, 117#u8, 105#u8, 108#u8, 116#u8, 105#u8, 110#u8, 32#u8, 73#u8, 68#u8, 77#u8, 32#u8, 67#u8, 111#u8, 110#u8, 116#u8, 114#u8, 111#u8, 108#u8, 32#u8, 102#u8, 111#u8, 114#u8, 32#u8, 97#u8, 108#u8, 108#u8, 111#u8, 119#u8, 105#u8, 110#u8, 103#u8, 32#u8, 101#u8, 110#u8, 116#u8, 114#u8, 121#u8, 32#u8, 109#u8, 97#u8, 110#u8, 97#u8, 103#u8, 101#u8, 114#u8, 115#u8, 32#u8, 116#u8, 111#u8, 32#u8, 109#u8, 111#u8, 100#u8, 105#u8, 102#u8, 121#u8, 32#u8, 115#u8, 101#u8, 114#u8, 118#u8, 105#u8, 99#u8, 101#u8, 32#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 115#u8],
2#u8,
[],
[1#u8, 3#u8, 0#u8, 0#u8, 5#u8, 0#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 7#u8, 0#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 0#u8, 5#u8, 0#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 15#u8, 0#u8, 115#u8, 101#u8, 114#u8, 118#u8, 105#u8, 99#u8, 101#u8, 95#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 3#u8, 2#u8, 2#u8, 0#u8, 0#u8, 5#u8, 0#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 8#u8, 0#u8, 114#u8, 101#u8, 99#u8, 121#u8, 99#u8, 108#u8, 101#u8, 100#u8, 0#u8, 5#u8, 0#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 9#u8, 0#u8, 116#u8, 111#u8, 109#u8, 98#u8, 115#u8, 116#u8, 111#u8, 110#u8, 101#u8],
[21#u16, 61#u16, 96#u16, 109#u16, 37#u16, 27#u16, 97#u16, 38#u16, 52#u16, 107#u16, 88#u16, 90#u16, 0#u16, 2#u16, 13#u16, 108#u16, 53#u16],
[27#u16, 97#u16, 90#u16, 0#u16, 2#u16, 13#u16],
[27#u16, 97#u16, 90#u16, 107#u16, 88#u16, 0#u16, 2#u16, 13#u16, 108#u16],
[],
[],
[],
[],
[]⟩

@[step] theorem dl12_service_account_entry_manager_v1_complete : acp_catalog.dl12_service_account_entry_manager_v1 ⦃r => view r = expected_dl12_service_account_entry_manager_v1⦄ := by
  unfold acp_catalog.dl12_service_account_entry_manager_v1
  h5i_steps
  all_goals simp_all [view, expected_dl12_service_account_entry_manager_v1, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.AcpCatalog
