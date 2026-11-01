import Verified.EntryCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.EntryCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl12_e_hmac_name_history_feature : EntryModel := ⟨[5#u8, 0#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 4#u8, 0#u8, 0#u8, 6#u8, 0#u8, 111#u8, 98#u8, 106#u8, 101#u8, 99#u8, 116#u8, 0#u8, 7#u8, 0#u8, 102#u8, 101#u8, 97#u8, 116#u8, 117#u8, 114#u8, 101#u8, 0#u8, 10#u8, 0#u8, 107#u8, 101#u8, 121#u8, 95#u8, 111#u8, 98#u8, 106#u8, 101#u8, 99#u8, 116#u8, 0#u8, 20#u8, 0#u8, 107#u8, 101#u8, 121#u8, 95#u8, 111#u8, 98#u8, 106#u8, 101#u8, 99#u8, 116#u8, 95#u8, 104#u8, 107#u8, 100#u8, 102#u8, 95#u8, 115#u8, 50#u8, 53#u8, 54#u8, 11#u8, 0#u8, 100#u8, 101#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8, 105#u8, 111#u8, 110#u8, 1#u8, 0#u8, 2#u8, 47#u8, 0#u8, 67#u8, 111#u8, 110#u8, 102#u8, 105#u8, 103#u8, 117#u8, 114#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 32#u8, 111#u8, 102#u8, 32#u8, 116#u8, 104#u8, 101#u8, 32#u8, 72#u8, 77#u8, 65#u8, 67#u8, 32#u8, 78#u8, 97#u8, 109#u8, 101#u8, 32#u8, 72#u8, 105#u8, 115#u8, 116#u8, 111#u8, 114#u8, 121#u8, 32#u8, 70#u8, 101#u8, 97#u8, 116#u8, 117#u8, 114#u8, 101#u8, 46#u8, 4#u8, 0#u8, 110#u8, 97#u8, 109#u8, 101#u8, 1#u8, 0#u8, 3#u8, 17#u8, 0#u8, 104#u8, 109#u8, 97#u8, 99#u8, 95#u8, 110#u8, 97#u8, 109#u8, 101#u8, 95#u8, 102#u8, 101#u8, 97#u8, 116#u8, 117#u8, 114#u8, 101#u8, 4#u8, 0#u8, 117#u8, 117#u8, 105#u8, 100#u8, 1#u8, 0#u8, 1#u8, 88#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8]⟩

@[step] theorem dl12_e_hmac_name_history_feature_complete : entry_catalog.dl12_e_hmac_name_history_feature ⦃r => viewEntry r = expected_dl12_e_hmac_name_history_feature⦄ := by
  unfold entry_catalog.dl12_e_hmac_name_history_feature
  h5i_steps
  all_goals simp_all [viewEntry, expected_dl12_e_hmac_name_history_feature, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.EntryCatalog
