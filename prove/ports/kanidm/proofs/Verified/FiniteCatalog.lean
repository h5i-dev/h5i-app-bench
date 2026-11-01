import KanidmKernel
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib kanidm_kernel
namespace kanidm_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def index_type_edc7b397_as_idx_str_model (v : finite_catalog.index_type_edc7b397.IndexType) : List U8 :=
  match v with
  | .Equality => [101#u8, 113#u8]
  | .Presence => [112#u8, 114#u8, 101#u8, 115#u8]
  | .SubString => [115#u8, 117#u8, 98#u8]
  | .Ordering => [111#u8, 114#u8, 100#u8]
theorem index_type_edc7b397_as_idx_str_complete (v : finite_catalog.index_type_edc7b397.IndexType) :
    finite_catalog.index_type_edc7b397.IndexType.as_idx_str v ⦃r => r.val = index_type_edc7b397_as_idx_str_model v⦄ := by
  cases v <;> simp only [index_type_edc7b397_as_idx_str_model]
  all_goals simp only [finite_catalog.index_type_edc7b397.IndexType.as_idx_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib kanidm_kernel
namespace kanidm_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def oauth_claim_map_join_edc7b397_to_str_model (v : finite_catalog.oauth_claim_map_join_edc7b397.OauthClaimMapJoin) : List U8 :=
  match v with
  | .CommaSeparatedValue => [44#u8]
  | .SpaceSeparatedValue => [32#u8]
  | .JsonArray => [59#u8]
theorem oauth_claim_map_join_edc7b397_to_str_complete (v : finite_catalog.oauth_claim_map_join_edc7b397.OauthClaimMapJoin) :
    finite_catalog.oauth_claim_map_join_edc7b397.OauthClaimMapJoin.to_str v ⦃r => r.val = oauth_claim_map_join_edc7b397_to_str_model v⦄ := by
  cases v <;> simp only [oauth_claim_map_join_edc7b397_to_str_model]
  all_goals simp only [finite_catalog.oauth_claim_map_join_edc7b397.OauthClaimMapJoin.to_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end kanidm_kernel.Verified.FiniteCatalog
