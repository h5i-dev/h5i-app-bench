import Verified.AcpDefaultsData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.AcpDefaults
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl12_service_account_entry_manager_v1 : Model := ⟨[15#u16, 3#u16, 2#u16, 4#u16],
[105#u8, 100#u8, 109#u8, 95#u8, 97#u8, 99#u8, 112#u8, 95#u8, 115#u8, 101#u8, 114#u8, 118#u8, 105#u8, 99#u8, 101#u8, 95#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 95#u8, 101#u8, 110#u8, 116#u8, 114#u8, 121#u8, 95#u8, 109#u8, 97#u8, 110#u8, 97#u8, 103#u8, 101#u8, 114#u8],
281474959933537#u128,
[66#u8, 117#u8, 105#u8, 108#u8, 116#u8, 105#u8, 110#u8, 32#u8, 73#u8, 68#u8, 77#u8, 32#u8, 67#u8, 111#u8, 110#u8, 116#u8, 114#u8, 111#u8, 108#u8, 32#u8, 102#u8, 111#u8, 114#u8, 32#u8, 97#u8, 108#u8, 108#u8, 111#u8, 119#u8, 105#u8, 110#u8, 103#u8, 32#u8, 101#u8, 110#u8, 116#u8, 114#u8, 121#u8, 32#u8, 109#u8, 97#u8, 110#u8, 97#u8, 103#u8, 101#u8, 114#u8, 115#u8, 32#u8, 116#u8, 111#u8, 32#u8, 109#u8, 111#u8, 100#u8, 105#u8, 102#u8, 121#u8, 32#u8, 115#u8, 101#u8, 114#u8, 118#u8, 105#u8, 99#u8, 101#u8, 32#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 115#u8],
2#u8,
[],
[1#u8, 3#u8, 0#u8, 0#u8, 5#u8, 0#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 7#u8, 0#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 0#u8, 5#u8, 0#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 15#u8, 0#u8, 115#u8, 101#u8, 114#u8, 118#u8, 105#u8, 99#u8, 101#u8, 95#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 3#u8, 2#u8, 2#u8, 0#u8, 0#u8, 5#u8, 0#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 8#u8, 0#u8, 114#u8, 101#u8, 99#u8, 121#u8, 99#u8, 108#u8, 101#u8, 100#u8, 0#u8, 5#u8, 0#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 9#u8, 0#u8, 116#u8, 111#u8, 109#u8, 98#u8, 115#u8, 116#u8, 111#u8, 110#u8, 101#u8],
[16#u16, 49#u16, 68#u16, 80#u16, 29#u16, 20#u16, 69#u16, 30#u16, 42#u16, 78#u16, 65#u16, 66#u16, 0#u16, 1#u16, 12#u16, 79#u16, 43#u16],
[20#u16, 69#u16, 66#u16, 0#u16, 1#u16, 12#u16],
[20#u16, 69#u16, 66#u16, 78#u16, 65#u16, 0#u16, 1#u16, 12#u16, 79#u16],
[],
[],
[],
[],
[]⟩

@[step] theorem dl12_service_account_entry_manager_v1_complete : acp_defaults.dl12_service_account_entry_manager_v1 ⦃r => view r = expected_dl12_service_account_entry_manager_v1⦄ := by
  unfold acp_defaults.dl12_service_account_entry_manager_v1
  h5i_steps
  all_goals simp_all [view, expected_dl12_service_account_entry_manager_v1, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.AcpDefaults
