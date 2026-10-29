import Spec
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.AcpDefaults
structure Model where
  classes : List U16
  «name» : List U8
  uuid : U128
  description : List U8
  receiver : U8
  groups : List U128
  target : List U8
  search_attrs : List U16
  modify_present_attrs : List U16
  modify_removed_attrs : List U16
  modify_classes : List U16
  modify_present_classes : List U16
  modify_remove_classes : List U16
  create_classes : List U16
  create_attrs : List U16
  deriving DecidableEq
def view (r : acp_defaults.Profile) : Model :=
  ⟨r.classes.val, r.name.val, r.uuid, r.description.val, r.receiver, r.groups.val, r.target.val, r.search_attrs.val, r.modify_present_attrs.val, r.modify_removed_attrs.val, r.modify_classes.val, r.modify_present_classes.val, r.modify_remove_classes.val, r.create_classes.val, r.create_attrs.val⟩
end kanidm_kernel.Verified.AcpDefaults
