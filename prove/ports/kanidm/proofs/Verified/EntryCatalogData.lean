import Spec
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.EntryCatalog
structure AccountModel where
  «account_type» : U8
  «has_entry_manager» : Bool
  «entry_manager» : U128
  «name» : List U8
  «uuid» : U128
  «description» : List U8
  «displayname» : List U8
  deriving DecidableEq
def viewAccount (r : entry_catalog.AccountRecord) : AccountModel :=
  ⟨r.«account_type», r.«has_entry_manager», r.«entry_manager», r.«name».val, r.«uuid», r.«description».val, r.«displayname».val⟩
structure EntryModel where
  «bytes» : List U8
  deriving DecidableEq
def viewEntry (r : entry_catalog.EntryRecord) : EntryModel :=
  ⟨r.«bytes».val⟩
end kanidm_kernel.Verified.EntryCatalog
