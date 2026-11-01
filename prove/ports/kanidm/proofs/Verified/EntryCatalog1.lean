import Verified.EntryCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.EntryCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl11_builtin_account_admin : AccountModel := ⟨0#u8,
false,
0#u128,
[97#u8, 100#u8, 109#u8, 105#u8, 110#u8],
0#u128,
[66#u8, 117#u8, 105#u8, 108#u8, 116#u8, 105#u8, 110#u8, 32#u8, 83#u8, 121#u8, 115#u8, 116#u8, 101#u8, 109#u8, 32#u8, 65#u8, 100#u8, 109#u8, 105#u8, 110#u8, 32#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 46#u8],
[83#u8, 121#u8, 115#u8, 116#u8, 101#u8, 109#u8, 32#u8, 65#u8, 100#u8, 109#u8, 105#u8, 110#u8, 105#u8, 115#u8, 116#u8, 114#u8, 97#u8, 116#u8, 111#u8, 114#u8]⟩

@[step] theorem dl11_builtin_account_admin_complete : entry_catalog.dl11_builtin_account_admin ⦃r => viewAccount r = expected_dl11_builtin_account_admin⦄ := by
  unfold entry_catalog.dl11_builtin_account_admin
  h5i_steps
  all_goals simp_all [viewAccount, expected_dl11_builtin_account_admin, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.EntryCatalog
