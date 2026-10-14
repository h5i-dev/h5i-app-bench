import Verified.OxicloudMigrationReadonly
import Verified.OxicloudDriveReadOnly
import Verified.OxicloudExpiredGrants
import Verified.OxicloudTokenGrant
import Verified.OxicloudShareNeedsOwner
import Verified.OxicloudCreateNeedsShare
import Verified.OxicloudSharingPolicies
import Verified.OxicloudPersonalDrive
import Verified.OxicloudKeepsOwner
import Verified.OxicloudRefusedWritesNothing
import Spec
import Verified.OxicloudUserRole
import Verified.OxicloudTotal
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit

namespace oxicloud_kernel.Properties

/-! ## The permission check (`PgAclEngine::check`) -/

/-- In storage-migration read-only mode only reads are allowed. -/
theorem migration_readonly_blocks_mutations (db : model.Db) (now : I64) (s : model.Subject)
    (p : model.Permission) (r : model.Resource) (hp : p ≠ .Read) :
    acl.check db true now s p r = ok false := by
  apply oxicloud_kernel.Verified.OxicloudMigrationReadonly.migration_readonly_blocks_mutations <;> assumption

/-- On a read-only drive, nothing inside it (nor the drive) can be changed. -/
theorem drive_read_only_blocks_mutations (db : model.Db) (ro : Bool) (now : I64) (s : model.Subject)
    (p : model.Permission) (r : model.Resource) (d : U64) (dr : model.Drive) (hp : p ≠ .Read)
    (hd : driveOf db r = some d) (hr : driveRow db d = some dr) (hro : dr.policies.read_only = true) :
    acl.check db ro now s p r ≠ ok true := by
  apply oxicloud_kernel.Verified.OxicloudDriveReadOnly.drive_read_only_blocks_mutations <;> assumption

/-- Expired grants play no part in a decision. -/
theorem expired_grants_ignored (db db' : model.Db) (ro : Bool) (now : I64) (s : model.Subject)
    (p : model.Permission) (r : model.Resource) (hs : SameButGrants db db')
    (hg : db'.grants.val = db.grants.val.filter (fun g => live g now)) :
    acl.check db' ro now s p r = acl.check db ro now s p r := by
  apply oxicloud_kernel.Verified.OxicloudExpiredGrants.expired_grants_ignored <;> assumption

/-- A link token is allowed only through a live grant to that token. -/
theorem token_needs_its_own_grant (db : model.Db) (ro : Bool) (now : I64) (t : U64)
    (p : model.Permission) (r : model.Resource) (h : acl.check db ro now (.Token t) p r = ok true) :
    ∃ g ∈ db.grants.val, g.subject = .Token t ∧ Live g now := by
  apply oxicloud_kernel.Verified.OxicloudTokenGrant.token_needs_its_own_grant <;> assumption

/-- Share is granted only through a live Owner grant. -/
theorem share_needs_owner (db : model.Db) (ro : Bool) (now : I64) (s : model.Subject) (r : model.Resource)
    (h : acl.check db ro now s .Share r = ok true) :
    ∃ g ∈ db.grants.val, g.role = .Owner ∧ Live g now := by
  apply oxicloud_kernel.Verified.OxicloudShareNeedsOwner.share_needs_owner <;> assumption

/-- The check always answers: group expansion and folder lookups terminate,
when the membership rows leave room for two more IDs. The expansion holds the
user, the internal group and every group it reaches; with `Usize.max - 1`
groups that is more IDs than a `Vec` holds, a table no database can store. -/
theorem check_total (db : model.Db) (ro : Bool) (now : I64) (s : model.Subject) (p : model.Permission)
    (r : model.Resource) (hm : db.memberships.length + 2 ≤ Usize.max) : ∃ b, acl.check db ro now s p r = ok b := by
  exact oxicloud_kernel.Verified.OxicloudTotal.check_total db ro now s p r hm

/-! ## The grant endpoints -/

/-- Creating a grant needs Share on the resource. -/
theorem create_needs_share (db db' : model.Db) (env : grantapi.Env) (caller : U64) (r : model.Resource)
    (s : model.Subject) (role : model.Role) (e : Option I64) (rep : grantapi.Reply)
    (h : grantapi.transition db env caller (.CreateGrant r s role e) = ok (db', .Ok rep)) :
    acl.check db env.migration_readonly env.now (.User caller) .Share r = ok true := by
  apply oxicloud_kernel.Verified.OxicloudCreateNeedsShare.create_needs_share <;> assumption

/-- A grant created on a folder or file obeys its drive's sharing policies:
no sharing where it is forbidden, and no link token where public links are. -/
theorem create_respects_sharing_policies (db db' : model.Db) (env : grantapi.Env) (caller : U64)
    (r : model.Resource) (s : model.Subject) (role : model.Role) (e : Option I64) (rep : grantapi.Reply)
    (d : U64) (dr : model.Drive) (hst : isStorage r = true) (hd : driveOf db r = some d)
    (hr : driveRow db d = some dr)
    (h : grantapi.transition db env caller (.CreateGrant r s role e) = ok (db', .Ok rep)) :
    dr.policies.forbid_sharing = false ∧ (∀ t, s = .Token t → dr.policies.forbid_public_links = false) := by
  apply oxicloud_kernel.Verified.OxicloudSharingPolicies.create_respects_sharing_policies <;> assumption

/-- A personal drive's membership cannot be changed by creating or setting
a role: the request fails and changes nothing. -/
theorem personal_drive_members_fixed (db db' : model.Db) (env : grantapi.Env) (caller d : U64)
    (s : model.Subject) (role : model.Role) (e : Option I64) (req : grantapi.Request)
    (dr : model.Drive) (hr : driveRow db d = some dr) (hk : dr.kind = .Personal)
    (hq : req = .CreateGrant (.Drive d) s role e ∨ req = .SetRole (.Drive d) s role e)
    (out : core.result.Result grantapi.Reply model.ErrorKind)
    (h : grantapi.transition db env caller req = ok (db', out)) :
    db' = db ∧ ∃ err, out = .Err err := by
  apply oxicloud_kernel.Verified.OxicloudPersonalDrive.personal_drive_members_fixed <;> assumption

/-- Creating or setting a role never leaves a drive that had an owner
without one, in a database whose grants are unique per subject and resource
as the table's key makes them. -/
theorem drive_keeps_an_owner (db db' : model.Db) (env : grantapi.Env) (caller d : U64) (s : model.Subject)
    (role : model.Role) (e : Option I64) (req : grantapi.Request) (rep : grantapi.Reply)
    (hq : req = .CreateGrant (.Drive d) s role e ∨ req = .SetRole (.Drive d) s role e)
    (hu : GrantsUnique db)
    (ho : 0 < ownerCount db d) (h : grantapi.transition db env caller req = ok (db', .Ok rep)) :
    0 < ownerCount db' d := by
  apply oxicloud_kernel.Verified.OxicloudKeepsOwner.drive_keeps_an_owner <;> assumption

/-- A refused create or role change writes nothing. -/
theorem refused_create_or_set_writes_nothing (db db' : model.Db) (env : grantapi.Env) (caller : U64)
    (r : model.Resource) (s : model.Subject) (role : model.Role) (e : Option I64) (req : grantapi.Request)
    (err : model.ErrorKind) (hq : req = .CreateGrant r s role e ∨ req = .SetRole r s role e)
    (h : grantapi.transition db env caller req = ok (db', .Err err)) :
    db' = db := by
  apply oxicloud_kernel.Verified.OxicloudRefusedWritesNothing.refused_create_or_set_writes_nothing <;> assumption

/-- Wire output uses the canonical spelling of the account role. -/
theorem role_wire_canonical (r : userrole.UserRole) (out : alloc.vec.Vec U8)
    (h : userrole.as_bytes r = ok out) : out.val = SpecKernel.RoleWire r :=
  Verified.OxicloudUserRole.as_bytes_ok r out h

/-- Stored accounts recognize precisely owner, admin, and user. -/
theorem stored_roles_canonical (raw : Slice U8) (o : Option userrole.UserRole)
    (h : userrole.from_stored raw = ok o) (r : userrole.UserRole) :
    (o = some r ↔ SpecKernel.StoredRole raw.val r) :=
  Verified.OxicloudUserRole.stored_ok raw o h r

/-- Sessions recognize precisely the four canonical role spellings. -/
theorem session_roles_canonical (raw : Slice U8) (o : Option userrole.UserRole)
    (h : userrole.from_session raw = ok o) (r : userrole.UserRole) :
    (o = some r ↔ SpecKernel.SessionRole raw.val r) :=
  Verified.OxicloudUserRole.session_ok raw o h r

/-- A role meets a minimum exactly when its policy level is sufficient. -/
theorem role_requirement_order (r min : userrole.UserRole) (b : Bool)
    (h : userrole.at_least r min = ok b) :
    (b = true ↔ SpecKernel.RoleLevel min ≤ SpecKernel.RoleLevel r) :=
  Verified.OxicloudUserRole.at_least_ok r min b h

/-- Strict privilege comparisons exclude peers and lower roles. -/
theorem role_strict_order (r target : userrole.UserRole) (b : Bool)
    (h : userrole.outranks r target = ok b) :
    (b = true ↔ SpecKernel.RoleLevel target < SpecKernel.RoleLevel r) :=
  Verified.OxicloudUserRole.outranks_ok r target b h

/-- Only the anonymous role has the anonymous flag. -/
theorem anonymous_role_exact (r : userrole.UserRole) (b : Bool)
    (h : userrole.is_anonymous r = ok b) : (b = true ↔ r = .Anonymous) :=
  Verified.OxicloudUserRole.anonymous_ok r b h

/-- The privileged flag selects administrators and owners. -/
theorem privileged_roles_exact (r : userrole.UserRole) (b : Bool)
    (h : userrole.is_privileged r = ok b) : (b = true ↔ r = .Admin ∨ r = .Owner) :=
  Verified.OxicloudUserRole.privileged_ok r b h

/-- Wire roles meet requirements only through a recognized spelling and sufficient privilege. -/
theorem session_role_requirement (raw : Slice U8) (min : userrole.UserRole) (b : Bool)
    (h : userrole.str_at_least raw min = ok b) : (b = true ↔ SpecKernel.MeetsRole raw.val min) :=
  Verified.OxicloudUserRole.str_at_least_ok raw min b h

end oxicloud_kernel.Properties
