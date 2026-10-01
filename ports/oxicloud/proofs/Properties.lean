import Spec
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec H5iAppLib

namespace oxicloud_kernel.Properties

/-! ## The permission check (`PgAclEngine::check`) -/

/-- In storage-migration read-only mode only reads are allowed. -/
theorem migration_readonly_blocks_mutations (db : model.Db) (now : I64) (s : model.Subject)
    (p : model.Permission) (r : model.Resource) (hp : p ≠ .Read) :
    acl.check db true now s p r = ok false := by
  sorry

/-- On a read-only drive, nothing inside it (nor the drive) can be changed. -/
theorem drive_read_only_blocks_mutations (db : model.Db) (ro : Bool) (now : I64) (s : model.Subject)
    (p : model.Permission) (r : model.Resource) (d : U64) (dr : model.Drive) (hp : p ≠ .Read)
    (hd : driveOf db r = some d) (hr : driveRow db d = some dr) (hro : dr.policies.read_only = true) :
    acl.check db ro now s p r ≠ ok true := by
  sorry

/-- Expired grants play no part in a decision. -/
theorem expired_grants_ignored (db db' : model.Db) (ro : Bool) (now : I64) (s : model.Subject)
    (p : model.Permission) (r : model.Resource) (hs : SameButGrants db db')
    (hg : db'.grants.val = db.grants.val.filter (fun g => live g now)) :
    acl.check db' ro now s p r = acl.check db ro now s p r := by
  sorry

/-- Taking grants away never allows more. -/
theorem fewer_grants_allow_no_more (db db' : model.Db) (ro : Bool) (now : I64) (s : model.Subject)
    (p : model.Permission) (r : model.Resource) (hs : SameButGrants db db')
    (hg : ∀ g ∈ db'.grants.val, g ∈ db.grants.val) (h : acl.check db' ro now s p r = ok true) :
    acl.check db ro now s p r = ok true := by
  sorry

/-- A link token is allowed only through a live grant to that token. -/
theorem token_needs_its_own_grant (db : model.Db) (ro : Bool) (now : I64) (t : U64)
    (p : model.Permission) (r : model.Resource) (h : acl.check db ro now (.Token t) p r = ok true) :
    ∃ g ∈ db.grants.val, g.subject = .Token t ∧ Live g now := by
  sorry

/-- Share is granted only through a live Owner grant. -/
theorem share_needs_owner (db : model.Db) (ro : Bool) (now : I64) (s : model.Subject) (r : model.Resource)
    (h : acl.check db ro now s .Share r = ok true) :
    ∃ g ∈ db.grants.val, g.role = .Owner ∧ Live g now := by
  sorry

/-- The check always answers: group expansion and folder lookups terminate. -/
theorem check_total (db : model.Db) (ro : Bool) (now : I64) (s : model.Subject) (p : model.Permission)
    (r : model.Resource) : ∃ b, acl.check db ro now s p r = ok b := by
  sorry

/-! ## The grant endpoints -/

/-- Creating a grant needs Share on the resource. -/
theorem create_needs_share (db db' : model.Db) (env : grantapi.Env) (caller : U64) (r : model.Resource)
    (s : model.Subject) (role : model.Role) (e : Option I64) (rep : grantapi.Reply)
    (h : grantapi.transition db env caller (.CreateGrant r s role e) = ok (db', .Ok rep)) :
    acl.check db env.migration_readonly env.now (.User caller) .Share r = ok true := by
  sorry

/-- A grant created on a folder or file obeys its drive's sharing policies:
no sharing where it is forbidden, and no link token where public links are. -/
theorem create_respects_sharing_policies (db db' : model.Db) (env : grantapi.Env) (caller : U64)
    (r : model.Resource) (s : model.Subject) (role : model.Role) (e : Option I64) (rep : grantapi.Reply)
    (d : U64) (dr : model.Drive) (hst : isStorage r = true) (hd : driveOf db r = some d)
    (hr : driveRow db d = some dr)
    (h : grantapi.transition db env caller (.CreateGrant r s role e) = ok (db', .Ok rep)) :
    dr.policies.forbid_sharing = false ∧ (∀ t, s = .Token t → dr.policies.forbid_public_links = false) := by
  sorry

/-- A personal drive's membership cannot be changed by creating or setting
a role: the request fails and changes nothing. -/
theorem personal_drive_members_fixed (db db' : model.Db) (env : grantapi.Env) (caller d : U64)
    (s : model.Subject) (role : model.Role) (e : Option I64) (req : grantapi.Request)
    (dr : model.Drive) (hr : driveRow db d = some dr) (hk : dr.kind = .Personal)
    (hq : req = .CreateGrant (.Drive d) s role e ∨ req = .SetRole (.Drive d) s role e)
    (out : core.result.Result grantapi.Reply model.ErrorKind)
    (h : grantapi.transition db env caller req = ok (db', out)) :
    db' = db ∧ ∃ err, out = .Err err := by
  sorry

/-- Creating or setting a role never leaves a drive that had an owner
without one. -/
theorem drive_keeps_an_owner (db db' : model.Db) (env : grantapi.Env) (caller d : U64) (s : model.Subject)
    (role : model.Role) (e : Option I64) (req : grantapi.Request) (rep : grantapi.Reply)
    (hq : req = .CreateGrant (.Drive d) s role e ∨ req = .SetRole (.Drive d) s role e)
    (ho : 0 < ownerCount db d) (h : grantapi.transition db env caller req = ok (db', .Ok rep)) :
    0 < ownerCount db' d := by
  sorry

/-- A refused create or role change writes nothing. -/
theorem refused_create_or_set_writes_nothing (db db' : model.Db) (env : grantapi.Env) (caller : U64)
    (r : model.Resource) (s : model.Subject) (role : model.Role) (e : Option I64) (req : grantapi.Request)
    (err : model.ErrorKind) (hq : req = .CreateGrant r s role e ∨ req = .SetRole r s role e)
    (h : grantapi.transition db env caller req = ok (db', .Err err)) :
    db' = db := by
  sorry

end oxicloud_kernel.Properties
