import Verified.EntryCatalogData
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.EntryCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def expected_dl11_e_key_provider_internal_dl6 : EntryModel := ⟨[5#u8, 0#u8, 99#u8, 108#u8, 97#u8, 115#u8, 115#u8, 3#u8, 0#u8, 0#u8, 6#u8, 0#u8, 111#u8, 98#u8, 106#u8, 101#u8, 99#u8, 116#u8, 0#u8, 12#u8, 0#u8, 107#u8, 101#u8, 121#u8, 95#u8, 112#u8, 114#u8, 111#u8, 118#u8, 105#u8, 100#u8, 101#u8, 114#u8, 0#u8, 21#u8, 0#u8, 107#u8, 101#u8, 121#u8, 95#u8, 112#u8, 114#u8, 111#u8, 118#u8, 105#u8, 100#u8, 101#u8, 114#u8, 95#u8, 105#u8, 110#u8, 116#u8, 101#u8, 114#u8, 110#u8, 97#u8, 108#u8, 11#u8, 0#u8, 100#u8, 101#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8, 105#u8, 111#u8, 110#u8, 1#u8, 0#u8, 2#u8, 57#u8, 0#u8, 84#u8, 104#u8, 101#u8, 32#u8, 100#u8, 101#u8, 102#u8, 97#u8, 117#u8, 108#u8, 116#u8, 32#u8, 100#u8, 97#u8, 116#u8, 97#u8, 98#u8, 97#u8, 115#u8, 101#u8, 32#u8, 105#u8, 110#u8, 116#u8, 101#u8, 114#u8, 110#u8, 97#u8, 108#u8, 32#u8, 99#u8, 114#u8, 121#u8, 112#u8, 116#u8, 111#u8, 103#u8, 114#u8, 97#u8, 112#u8, 104#u8, 105#u8, 99#u8, 32#u8, 107#u8, 101#u8, 121#u8, 32#u8, 112#u8, 114#u8, 111#u8, 118#u8, 105#u8, 100#u8, 101#u8, 114#u8, 46#u8, 4#u8, 0#u8, 110#u8, 97#u8, 109#u8, 101#u8, 1#u8, 0#u8, 3#u8, 21#u8, 0#u8, 107#u8, 101#u8, 121#u8, 95#u8, 112#u8, 114#u8, 111#u8, 118#u8, 105#u8, 100#u8, 101#u8, 114#u8, 95#u8, 105#u8, 110#u8, 116#u8, 101#u8, 114#u8, 110#u8, 97#u8, 108#u8, 4#u8, 0#u8, 117#u8, 117#u8, 105#u8, 100#u8, 1#u8, 0#u8, 1#u8, 112#u8, 0#u8, 0#u8, 255#u8, 255#u8, 255#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8, 0#u8]⟩

@[step] theorem dl11_e_key_provider_internal_dl6_complete : entry_catalog.dl11_e_key_provider_internal_dl6 ⦃r => viewEntry r = expected_dl11_e_key_provider_internal_dl6⦄ := by
  unfold entry_catalog.dl11_e_key_provider_internal_dl6
  h5i_steps
  all_goals simp_all [viewEntry, expected_dl11_e_key_provider_internal_dl6, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.EntryCatalog
