import OxicloudKernel
import H5iAppLib
/-!
# OxiCloud access control: the spec

From OxiCloud's code and documentation at 8c0dd33. Lookups read the tables
the way the engine's queries do: the first row with the id.
-/
open Aeneas Aeneas.Std oxicloud_kernel

namespace oxicloud_kernel

deriving instance DecidableEq for model.Resource, model.Role

end oxicloud_kernel

namespace oxicloud_kernel.Spec

/-- A grant counts at `now`: no expiry, or one still ahead. -/
def live (g : model.Grant) (now : I64) : Bool :=
  match g.expires_at with
  | none => true
  | some t => decide (now.val < t.val)

abbrev Live (g : model.Grant) (now : I64) : Prop := live g now = true

/-- The drive a folder or file lives in; a drive is its own. -/
def driveOf (db : model.Db) : model.Resource → Option U64
  | .Folder x => (db.folders.val.find? (·.id = x)).map (·.drive_id)
  | .File x => (db.files.val.find? (·.id = x)).map (·.drive_id)
  | .Drive x => some x
  | _ => none

def driveRow (db : model.Db) (d : U64) : Option model.Drive := db.drives.val.find? (·.id = d)

/-- Two databases that differ at most in their grants. -/
def SameButGrants (a b : model.Db) : Prop :=
  a.users = b.users ∧ a.memberships = b.memberships ∧ a.drives = b.drives ∧ a.folders = b.folders ∧ a.files = b.files

/-- Owner grants on a drive, whatever their expiry. -/
def ownerCount (db : model.Db) (d : U64) : Nat :=
  (db.grants.val.filter (fun g => decide (g.resource = .Drive d ∧ g.role = .Owner))).length

def isStorage : model.Resource → Bool
  | .Folder _ | .File _ => true
  | _ => false

end oxicloud_kernel.Spec
