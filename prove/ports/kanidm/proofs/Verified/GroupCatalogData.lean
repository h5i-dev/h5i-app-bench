import Spec
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.GroupCatalog
structure GroupModel where
  «name» : List U8
  description : List U8
  uuid : U128
  members : List U128
  member_create_once : List U128
  has_entry_manager : Bool
  entry_manager : U128
  dyngroup : Bool
  filter : List U8
  extra_attributes : List U8
  deriving DecidableEq
def viewGroup (r : group_catalog.GroupRecord) : GroupModel :=
  ⟨r.name.val, r.description.val, r.uuid, r.members.val, r.member_create_once.val, r.has_entry_manager, r.entry_manager, r.dyngroup, r.filter.val, r.extra_attributes.val⟩
end kanidm_kernel.Verified.GroupCatalog
