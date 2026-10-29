import Verified.AcpDefaultsData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.AcpDefaults
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl13_application_entry_manager_dl8 : Model := ⟨[15#u16, 3#u16, 2#u16, 4#u16],
[105#u8, 100#u8, 109#u8, 95#u8, 97#u8, 99#u8, 112#u8, 95#u8, 97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 95#u8, 101#u8, 110#u8, 116#u8, 114#u8, 121#u8, 95#u8, 109#u8, 97#u8, 110#u8, 97#u8, 103#u8, 101#u8, 114#u8],
281474959933554#u128,
[66#u8, 117#u8, 105#u8, 108#u8, 116#u8, 105#u8, 110#u8, 32#u8, 73#u8, 68#u8, 77#u8, 32#u8, 67#u8, 111#u8, 110#u8, 116#u8, 114#u8, 111#u8, 108#u8, 32#u8, 102#u8, 111#u8, 114#u8, 32#u8, 97#u8, 108#u8, 108#u8, 111#u8, 119#u8, 105#u8, 110#u8, 103#u8, 32#u8, 69#u8, 110#u8, 116#u8, 114#u8, 121#u8, 77#u8, 97#u8, 110#u8, 97#u8, 103#u8, 101#u8, 114#u8, 32#u8, 116#u8, 111#u8, 32#u8, 114#u8, 101#u8, 97#u8, 100#u8, 32#u8, 97#u8, 110#u8, 100#u8, 32#u8, 109#u8, 111#u8, 100#u8, 105#u8, 102#u8, 121#u8, 32#u8, 97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 115#u8],
2#u8,
[],
[1#u8, 2#u8, 0#u8, 0#u8, 5#u8, 0#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 11#u8, 0#u8, 97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 3#u8, 2#u8, 2#u8, 0#u8, 0#u8, 5#u8, 0#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 8#u8, 0#u8, 114#u8, 101#u8, 99#u8, 121#u8, 99#u8, 108#u8, 101#u8, 100#u8, 0#u8, 5#u8, 0#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 9#u8, 0#u8, 116#u8, 111#u8, 109#u8, 98#u8, 115#u8, 116#u8, 111#u8, 110#u8, 101#u8],
[16#u16, 80#u16, 49#u16, 68#u16, 20#u16, 43#u16, 78#u16, 12#u16, 79#u16, 19#u16, 41#u16, 29#u16],
[49#u16, 19#u16, 20#u16, 43#u16, 78#u16, 12#u16, 41#u16],
[49#u16, 19#u16, 20#u16, 43#u16, 78#u16, 12#u16, 79#u16, 41#u16],
[],
[],
[],
[],
[]⟩

@[step] theorem dl13_application_entry_manager_dl8_complete : acp_defaults.dl13_application_entry_manager_dl8 ⦃r => view r = expected_dl13_application_entry_manager_dl8⦄ := by
  unfold acp_defaults.dl13_application_entry_manager_dl8
  h5i_steps
  all_goals simp_all [view, expected_dl13_application_entry_manager_dl8, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.AcpDefaults
