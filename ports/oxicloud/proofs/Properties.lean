import Verified.OxicloudLiveAuth
import Verified.OxicloudAdmin
import Verified.OxicloudUserState
import Verified.OxicloudMagicLink
import Verified.OxicloudSubjectGroup
import Verified.OxicloudShare
import Verified.OxicloudValidation
import Verified.OxicloudSession
import Verified.OxicloudDrivePolicy
import Verified.OxicloudAuthWire
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


/-- Authorization subjects use their canonical database discriminator. -/
theorem auth_subject_wire (value : model.Subject) (out : alloc.vec.Vec U8)
    (h : authwire.subject_bytes value = ok out) : out.val = SpecKernel.SubjectWire value :=
  Verified.OxicloudAuthWire.subject_bytes_ok value out h

/-- Parsing cannot change the subject namespace or identifier. -/
theorem auth_subject_parse (raw : Slice U8) (id : U64) (o : Option model.Subject)
    (h : authwire.subject_parse raw id = ok o) (value : model.Subject) :
    (o = some value ↔ raw.val = SpecKernel.SubjectWire value ∧ id = SpecKernel.SubjectId value) :=
  Verified.OxicloudAuthWire.subject_parse_ok raw id o h value

/-- The projected subject identifier is preserved exactly. -/
theorem auth_subject_id (value : model.Subject) :
    authwire.subject_id value = ok (SpecKernel.SubjectId value) :=
  Verified.OxicloudAuthWire.subject_id_ok value

/-- Authorization resources use their canonical database discriminator. -/
theorem auth_resource_wire (value : model.Resource) (out : alloc.vec.Vec U8)
    (h : authwire.resource_bytes value = ok out) : out.val = SpecKernel.ResourceWire value :=
  Verified.OxicloudAuthWire.resource_bytes_ok value out h

/-- Parsing cannot change the resource namespace or identifier. -/
theorem auth_resource_parse (raw : Slice U8) (id : U64) (o : Option model.Resource)
    (h : authwire.resource_parse raw id = ok o) (value : model.Resource) :
    (o = some value ↔ raw.val = SpecKernel.ResourceWire value ∧ id = SpecKernel.ResourceId value) :=
  Verified.OxicloudAuthWire.resource_parse_ok raw id o h value

/-- The projected resource identifier is preserved exactly. -/
theorem auth_resource_id (value : model.Resource) :
    authwire.resource_id value = ok (SpecKernel.ResourceId value) :=
  Verified.OxicloudAuthWire.resource_id_ok value

/-- Authorization permissions use their canonical database discriminator. -/
theorem auth_permission_wire (value : model.Permission) (out : alloc.vec.Vec U8)
    (h : authwire.permission_bytes value = ok out) : out.val = SpecKernel.PermissionWire value :=
  Verified.OxicloudAuthWire.permission_bytes_ok value out h

/-- Parsing cannot change the permission namespace. -/
theorem auth_permission_parse (raw : Slice U8) (o : Option model.Permission)
    (h : authwire.permission_parse raw = ok o) (value : model.Permission) :
    (o = some value ↔ raw.val = SpecKernel.PermissionWire value) :=
  Verified.OxicloudAuthWire.permission_parse_ok raw o h value

/-- The query enumeration is complete and has the stable order. -/
theorem auth_permission_all (out : alloc.vec.Vec model.Permission)
    (h : authwire.permission_all = ok out) : out.val = SpecKernel.PermissionOrder :=
  Verified.OxicloudAuthWire.permission_all_ok out h

/-- Authorization roles use their canonical database discriminator. -/
theorem auth_role_wire (value : model.Role) (out : alloc.vec.Vec U8)
    (h : authwire.role_bytes value = ok out) : out.val = SpecKernel.GrantRoleWire value :=
  Verified.OxicloudAuthWire.role_bytes_ok value out h

/-- Parsing cannot change the role namespace. -/
theorem auth_role_parse (raw : Slice U8) (o : Option model.Role)
    (h : authwire.role_parse raw = ok o) (value : model.Role) :
    (o = some value ↔ raw.val = SpecKernel.GrantRoleWire value) :=
  Verified.OxicloudAuthWire.role_parse_ok raw o h value

/-- The query enumeration is complete and has the stable order. -/
theorem auth_role_all (out : alloc.vec.Vec model.Role)
    (h : authwire.role_all = ok out) : out.val = SpecKernel.RoleOrder :=
  Verified.OxicloudAuthWire.role_all_ok out h

/-- Group and link identities cannot be used as user-row identities. -/
theorem auth_user_identity (s : model.Subject) (id : U64) :
    authwire.subject_user_id s = ok (some id) ↔ s = .User id :=
  Verified.OxicloudAuthWire.user_identity s id

/-- Users and groups cannot be used as share-token identities. -/
theorem auth_token_identity (s : model.Subject) (id : U64) :
    authwire.subject_token_id s = ok (some id) ↔ s = .Token id :=
  Verified.OxicloudAuthWire.token_identity s id


/-- Explicit policy choices take precedence; missing choices inherit defaults. -/
theorem drive_policy_override_precedence (d : drivepolicy.Policies) (o : drivepolicy.Overrides)
    (r : drivepolicy.Policies) (h : drivepolicy.resolve d o = ok r) : SpecKernel.PolicyResolved d o r :=
  post_of_ok (Verified.OxicloudDrivePolicy.resolve_spec d o) h

/-- Both broad sharing restrictions and link-specific restrictions govern minting. -/
theorem drive_public_link_policy (p : drivepolicy.Policies)
    (r : core.result.Result Unit model.ErrorKind) (h : drivepolicy.refuse_public_links p = ok r) :
    SpecKernel.GuardDecision (SpecKernel.PublicLinksAllowed p) r :=
  Verified.OxicloudDrivePolicy.public_links_ok p r h

/-- The sharing policy controls per-resource sharing. -/
theorem drive_sharing_policy (p : drivepolicy.Policies)
    (r : core.result.Result Unit model.ErrorKind) (h : drivepolicy.refuse_sharing p = ok r) :
    SpecKernel.GuardDecision (SpecKernel.SharingAllowed p) r :=
  Verified.OxicloudDrivePolicy.sharing_ok p r h

/-- The owner-roster lock exempts administrators. -/
theorem drive_owner_roster_policy (p : drivepolicy.Policies) (admin : Bool)
    (r : core.result.Result Unit model.ErrorKind)
    (h : drivepolicy.refuse_owner_role_change p admin = ok r) :
    SpecKernel.GuardDecision (SpecKernel.OwnerChangesAllowed p admin) r :=
  Verified.OxicloudDrivePolicy.owner_changes_ok p admin r h

/-- The source drive controls the cross-drive move guard. -/
theorem drive_cross_move_policy (p : drivepolicy.Policies)
    (r : core.result.Result Unit model.ErrorKind) (h : drivepolicy.refuse_cross_drive_move p = ok r) :
    SpecKernel.GuardDecision (SpecKernel.CrossDriveMoveAllowed p) r :=
  Verified.OxicloudDrivePolicy.cross_drive_move_ok p r h

/-- The external-sharing guard preserves the distinction between users, groups, and tokens. -/
theorem drive_external_sharing_policy (p : drivepolicy.Policies) (s : model.Subject) (external : Bool)
    (r : core.result.Result Unit model.ErrorKind)
    (h : drivepolicy.refuse_external_sharing p s external = ok r) :
    SpecKernel.GuardDecision (SpecKernel.ExternalSharingAllowed p s external) r :=
  Verified.OxicloudDrivePolicy.external_sharing_ok p s external r h



/-- Session origins retain their canonical authentication-method discriminator. -/
theorem session_origin_wire (o : session.SessionOrigin) (out : alloc.vec.Vec U8)
    (h : session.origin_bytes o = ok out) : out.val = SpecKernel.OriginWire o :=
  Verified.OxicloudSession.origin_bytes_ok o out h

/-- Known origins are accepted only with their exact spelling. -/
theorem session_origin_parse (raw : Slice U8) (o : session.SessionOrigin)
    (h : session.origin_from_wire raw = ok o) : SpecKernel.OriginDecoded raw.val o :=
  Verified.OxicloudSession.origin_parse_ok raw o h

/-- Restoring a session preserves all identity, binding, revocation, and lifetime observations. -/
theorem session_restoration_readback (snapshot r : session.Session)
    (h : session.from_raw snapshot.id snapshot.user_id snapshot.refresh_token snapshot.expires_at snapshot.ip_address snapshot.user_agent snapshot.created_at snapshot.revoked snapshot.family_id snapshot.oidc_id_token snapshot.oidc_sid snapshot.dpop_jkt snapshot.origin snapshot.last_seen_at = ok r) :
    session.id r = ok snapshot.id ∧
    session.user_id r = ok snapshot.user_id ∧
    session.refresh_token r = ok snapshot.refresh_token ∧
    session.expires_at r = ok snapshot.expires_at ∧
    session.ip_address r = ok snapshot.ip_address ∧
    session.user_agent r = ok snapshot.user_agent ∧
    session.created_at r = ok snapshot.created_at ∧
    session.is_revoked r = ok snapshot.revoked ∧
    session.family_id r = ok snapshot.family_id ∧
    session.oidc_id_token r = ok snapshot.oidc_id_token ∧
    session.oidc_sid r = ok snapshot.oidc_sid ∧
    session.dpop_jkt r = ok snapshot.dpop_jkt ∧
    session.origin r = ok snapshot.origin ∧
    session.last_seen_at r = ok snapshot.last_seen_at :=
  Verified.OxicloudSession.restored_readback snapshot r h

/-- Revocation preserves security metadata and remains revoked when repeated. -/
theorem session_revocation_frame (s r : session.Session) (h : session.revoke s = ok r) :
    SpecKernel.SessionRevoked s r ∧ session.revoke r = ok r :=
  Verified.OxicloudSession.revoke_ok s r h

/-- Binding requires an unbound session and preserves all other security fields. -/
theorem session_binding_frame (s r : session.Session) (key : alloc.vec.Vec U8)
    (h : session.with_dpop_jkt s key = ok r) : SpecKernel.SessionBound s key r :=
  Verified.OxicloudSession.bind_ok s r key h

/-- An existing key binding cannot be overwritten. -/
theorem session_binding_immutable (s : session.Session) (key : alloc.vec.Vec U8)
    (h : s.dpop_jkt ≠ none) : session.with_dpop_jkt s key = fail .panic :=
  Verified.OxicloudSession.no_rebind s key h

/-- Updating logout metadata preserves identity, revocation, lifetime, and key binding. -/
theorem session_oidc_token_frame (s r : session.Session) (token : alloc.vec.Vec U8)
    (h : session.with_oidc_id_token s token = ok r) : SpecKernel.SessionTokenAttached s token r :=
  Verified.OxicloudSession.token_attach_ok s r token h

/-- Updating OIDC session metadata preserves the other security fields. -/
theorem session_oidc_sid_frame (s r : session.Session) (sid : alloc.vec.Vec U8)
    (h : session.with_oidc_sid s sid = ok r) : SpecKernel.SessionSidAttached s sid r :=
  Verified.OxicloudSession.sid_attach_ok s r sid h



/-- Required email verification accepts only an explicit true claim and preserves audit distinctions. -/
theorem verified_email_policy (claim : Option Bool) (required : Bool) (d : validation.EmailDecision)
    (h : validation.classify_email_verification claim required = ok d) :
    SpecKernel.VerifiedEmailDecision claim required d :=
  Verified.OxicloudValidation.email_ok claim required d h

/-- Storage selectors enforce their bounded lowercase ASCII namespace. -/
theorem storage_selector_validation (raw : Slice U8) (r : Bool)
    (h : validation.is_valid_entry_name raw = ok r) :
    (r = true ↔ SpecKernel.ValidStorageName raw.val) :=
  Verified.OxicloudValidation.storage_name_ok raw r h

/-- Login thumbprint validation preserves valid input and rejects malformed length or alphabet. -/
theorem login_thumbprint_validation (raw : Slice U8)
    (r : core.result.Result (alloc.vec.Vec U8) validation.JktError)
    (h : validation.validate_dpop_jkt raw = ok r) : SpecKernel.JktDecision raw.val r :=
  Verified.OxicloudValidation.jkt_ok raw r h



/-- Share restoration retains the complete target, creator, credential, lifetime, and accounting snapshot. -/
theorem share_restoration_readback (snapshot r : share.Share)
    (h : share.from_raw snapshot.id snapshot.item_id snapshot.item_name snapshot.item_type snapshot.token snapshot.password_hash snapshot.expires_at snapshot.created_at snapshot.created_by snapshot.access_count = ok r) :
    share.id r = ok snapshot.id ∧
    share.item_id r = ok snapshot.item_id ∧
    share.item_name r = ok snapshot.item_name ∧
    share.item_type r = ok snapshot.item_type ∧
    share.token r = ok snapshot.token ∧
    share.password_hash r = ok snapshot.password_hash ∧
    share.expires_at r = ok snapshot.expires_at ∧
    share.created_at r = ok snapshot.created_at ∧
    share.created_by r = ok snapshot.created_by ∧
    share.access_count r = ok snapshot.access_count :=
  Verified.OxicloudShare.restored_readback snapshot r h

/-- Changing password protection preserves the share token, target, creator, and expiry. -/
theorem share_password_frame (s r : share.Share) (hash : Option (alloc.vec.Vec U8))
    (h : share.with_password s hash = ok r) : SpecKernel.SharePasswordChanged s hash r :=
  Verified.OxicloudShare.password_change_ok s r hash h

/-- Token changes preserve the password requirement, target, creator, and expiry. -/
theorem share_token_frame (s r : share.Share) (token : alloc.vec.Vec U8)
    (h : share.with_token s token = ok r) : SpecKernel.ShareTokenChanged s token r :=
  Verified.OxicloudShare.token_change_ok s r token h

/-- A stored hash determines whether password verification is required. -/
theorem share_password_required (s : share.Share) (r : Bool) (h : share.has_password s = ok r) :
    (r = true ↔ ∃ hash, s.password_hash = some hash) ∧ (r = false ↔ s.password_hash = none) :=
  Verified.OxicloudShare.password_required s r h

/-- Successful access accounting cannot wrap or change authorization fields. -/
theorem share_access_accounting (s r : share.Share) (h : share.increment_access_count s = ok r) :
    SpecKernel.ShareAccessCounted s r :=
  Verified.OxicloudShare.access_count_ok s r h

/-- Every accepted group name belongs to the bounded ASCII principal namespace. -/
theorem subject_group_namespace (raw : Slice U8)
    (r : core.result.Result Unit subjectgroup.NameError)
    (h : subjectgroup.validate_name raw = ok r) :
    (r = .Ok () ↔ SpecKernel.ValidGroupName raw.val) :=
  Verified.OxicloudSubjectGroup.validation_exact raw r h

/-- Rejection reasons distinguish length, initial-byte, and subsequent alphabet constraints. -/
theorem subject_group_validation_reasons (raw : Slice U8)
    (r : core.result.Result Unit subjectgroup.NameError)
    (h : subjectgroup.validate_name raw = ok r) : SpecKernel.GroupNameDecision raw.val r :=
  Verified.OxicloudSubjectGroup.validation_ok raw r h

/-- Virtual groups are immutable regardless of their name, description, or timestamps. -/
theorem virtual_group_mutation_policy (group : subjectgroup.SubjectGroup) (r : Bool)
    (h : subjectgroup.is_immutable group = ok r) :
    (r = true ↔ group.is_virtual = true) :=
  Verified.OxicloudSubjectGroup.immutability_ok group r h

/-- Resource tokens use the exact canonical file and folder namespace. -/
theorem magic_resource_wire (value : magiclink.MagicLinkResourceKind) (out : alloc.vec.Vec U8)
    (h : magiclink.resource_bytes value = ok out) : out.val = SpecKernel.MagicResourceWire value :=
  Verified.OxicloudMagicLink.resource_bytes_ok value out h

/-- Unknown resource names cannot be interpreted as valid targets. -/
theorem magic_resource_parse (raw : Slice U8) (o : Option magiclink.MagicLinkResourceKind)
    (h : magiclink.resource_parse raw = ok o) (value : magiclink.MagicLinkResourceKind) :
    (o = some value ↔ raw.val = SpecKernel.MagicResourceWire value) :=
  Verified.OxicloudMagicLink.resource_parse_ok raw o h value

/-- Lifecycle states have distinct canonical wire names. -/
theorem magic_status_wire (value : magiclink.MagicLinkStatus) (out : alloc.vec.Vec U8)
    (h : magiclink.status_bytes value = ok out) : out.val = SpecKernel.MagicStatusWire value :=
  Verified.OxicloudMagicLink.status_bytes_ok value out h

/-- Only recognized lifecycle names can restore a token state. -/
theorem magic_status_parse (raw : Slice U8) (o : Option magiclink.MagicLinkStatus)
    (h : magiclink.status_parse raw = ok o) (value : magiclink.MagicLinkStatus) :
    (o = some value ↔ raw.val = SpecKernel.MagicStatusWire value) :=
  Verified.OxicloudMagicLink.status_parse_ok raw o h value

/-- Restoration preserves identity, target, browser challenge, and lifecycle evidence. -/
theorem magic_restoration_readback (snapshot r : magiclink.MagicLinkToken)
    (h : magiclink.from_raw snapshot.id snapshot.token snapshot.user_id snapshot.status snapshot.issued_at snapshot.expires_at snapshot.used_at snapshot.resource_kind snapshot.resource_id snapshot.request_challenge = ok r) :
    magiclink.id r = ok snapshot.id ∧
    magiclink.token r = ok snapshot.token ∧
    magiclink.user_id r = ok snapshot.user_id ∧
    magiclink.status r = ok snapshot.status ∧
    magiclink.issued_at r = ok snapshot.issued_at ∧
    magiclink.expires_at r = ok snapshot.expires_at ∧
    magiclink.used_at r = ok snapshot.used_at ∧
    magiclink.resource_kind r = ok snapshot.resource_kind ∧
    magiclink.resource_id r = ok snapshot.resource_id ∧
    magiclink.request_challenge r = ok snapshot.request_challenge :=
  Verified.OxicloudMagicLink.restored_readback snapshot r h

/-- A token expires strictly after its deadline, with nanosecond precision. -/
theorem magic_expiry_rule (s : magiclink.MagicLinkToken) (now : session.Timestamp) (r : Bool)
    (h : magiclink.is_expired s now = ok r) : (r = true ↔ SpecKernel.TimestampPast now s.expires_at) :=
  Verified.OxicloudMagicLink.expired_ok s now r h

/-- Redemption requires Pending status and a time at or before expiry. -/
theorem magic_redemption_rule (s : magiclink.MagicLinkToken) (now : session.Timestamp) (r : Bool)
    (h : magiclink.is_redeemable s now = ok r) : (r = true ↔ SpecKernel.MagicLinkRedeemable s now) :=
  Verified.OxicloudMagicLink.redeemable_ok s now r h

/-- Federation names are canonical and distinguish the three trust chains. -/
theorem account_federation_wire (value : userstate.FederationKind) (out : alloc.vec.Vec U8)
    (h : userstate.federation_bytes value = ok out) : out.val = SpecKernel.FederationWire value :=
  Verified.OxicloudUserState.federation_bytes_ok value out h

/-- Unrecognized federation names cannot select a trust chain. -/
theorem account_federation_parse (raw : Slice U8) (o : Option userstate.FederationKind)
    (h : userstate.federation_parse raw = ok o) (value : userstate.FederationKind) :
    (o = some value ↔ raw.val = SpecKernel.FederationWire value) :=
  Verified.OxicloudUserState.federation_parse_ok raw o h value

/-- Account hydration retains identity, role, credentials, verification, and profile state. -/
theorem account_restoration_readback (snapshot r : userstate.User)
    (h : userstate.from_data_full snapshot.id snapshot.username snapshot.email snapshot.password_hash snapshot.role snapshot.storage_quota_bytes snapshot.storage_used_bytes snapshot.created_at snapshot.updated_at snapshot.last_login_at snapshot.active snapshot.federation_kind snapshot.federation_issuer snapshot.federation_subject snapshot.image snapshot.is_external snapshot.given_name snapshot.family_name snapshot.email_verified_at snapshot.preferred_locale snapshot.notify_on_share snapshot.ui_preferences = ok r) :
    userstate.id r = ok snapshot.id ∧
    userstate.username r = ok snapshot.username ∧
    userstate.email r = ok snapshot.email ∧
    userstate.password_hash r = ok snapshot.password_hash ∧
    userstate.role r = ok snapshot.role ∧
    userstate.storage_quota_bytes r = ok snapshot.storage_quota_bytes ∧
    userstate.storage_used_bytes r = ok snapshot.storage_used_bytes ∧
    userstate.created_at r = ok snapshot.created_at ∧
    userstate.updated_at r = ok snapshot.updated_at ∧
    userstate.last_login_at r = ok snapshot.last_login_at ∧
    userstate.is_active r = ok snapshot.active ∧
    userstate.federation_kind r = ok snapshot.federation_kind ∧
    userstate.federation_issuer r = ok snapshot.federation_issuer ∧
    userstate.federation_subject r = ok snapshot.federation_subject ∧
    userstate.image r = ok snapshot.image ∧
    userstate.is_external r = ok snapshot.is_external ∧
    userstate.given_name r = ok snapshot.given_name ∧
    userstate.family_name r = ok snapshot.family_name ∧
    userstate.email_verified_at r = ok snapshot.email_verified_at ∧
    userstate.preferred_locale r = ok snapshot.preferred_locale ∧
    userstate.notify_on_share r = ok snapshot.notify_on_share ∧
    userstate.ui_preferences r = ok snapshot.ui_preferences :=
  Verified.OxicloudUserState.restored_readback snapshot r h

/-- Minimal hydration preserves supplied state and defaults to internal with no federation or email verification evidence. -/
theorem account_minimal_restoration (snapshot r : userstate.User)
    (h : userstate.from_data snapshot.id snapshot.username snapshot.email snapshot.password_hash snapshot.role snapshot.storage_quota_bytes snapshot.storage_used_bytes snapshot.created_at snapshot.updated_at snapshot.last_login_at snapshot.active = ok r) :
    SpecKernel.MinimalAccountRestored snapshot r :=
  Verified.OxicloudUserState.minimal_restored snapshot r h

/-- Owned decomposition cannot drop or change authorization and credential fields. -/
theorem account_decomposition_preserves_state (s : userstate.User) (p : userstate.UserParts)
    (h : userstate.into_parts s = ok p) : SpecKernel.AccountPartsPreserved s p :=
  Verified.OxicloudUserState.parts_preserved s p h

/-- A configured password is identified by presence, including a present empty value. -/
theorem account_password_presence (s : userstate.User) (r : Bool)
    (h : userstate.has_password s = ok r) : (r = true ↔ ∃ value, s.password_hash = some value) :=
  Verified.OxicloudUserState.password_presence s r h

/-- Issuer presence is independent of password and subject presence. -/
theorem account_issuer_presence (s : userstate.User) (r : Bool)
    (h : userstate.is_oidc_user s = ok r) : (r = true ↔ ∃ value, s.federation_issuer = some value) :=
  Verified.OxicloudUserState.issuer_presence s r h

/-- Email verification requires a stored verification timestamp. -/
theorem account_email_verified (s : userstate.User) (r : Bool)
    (h : userstate.is_email_verified s = ok r) : (r = true ↔ ∃ value, s.email_verified_at = some value) :=
  Verified.OxicloudUserState.email_verified s r h

/-- The non-magic-link credential signal requires a password hash or a federation subject. -/
theorem account_login_credential (s : userstate.User) (r : Bool)
    (h : userstate.has_login_credential s = ok r) : (r = true ↔ SpecKernel.AccountLoginCredential s) :=
  Verified.OxicloudUserState.credential_presence s r h

/-- Authorization denial visibility labels remain stable. -/
theorem admin_visibility_wire (value : admin.AuthzDenialVisibility) (out : alloc.vec.Vec U8)
    (h : admin.visibility_bytes value = ok out) : out.val = SpecKernel.AdminVisibilityWire value :=
  Verified.OxicloudAdmin.visibility_bytes_ok value out h

/-- Administrator denial labels retain their exact audit spelling. -/
theorem admin_denial_wire (value : admin.AdminDenial) (out : alloc.vec.Vec U8)
    (h : admin.denial_bytes value = ok out) : out.val = SpecKernel.AdminDenialWire value :=
  Verified.OxicloudAdmin.denial_bytes_ok value out h

/-- Administrator denials identify the failed precondition in the prescribed order. -/
theorem admin_denial_conditions (subject : admin.Principal) (role : userrole.UserRole)
    (is_external active : Bool) (r : Option admin.AdminDenial)
    (h : admin.system_admin_denial_reason subject role is_external active = ok r) :
    (r = none ↔ SpecKernel.SystemAdminAllowed subject role is_external active) ∧
    (∀ reason, r = some reason → SpecKernel.SystemAdminDenial subject role is_external active reason) :=
  Verified.OxicloudAdmin.reason_decision_ok subject role is_external active r h

/-- Only live internal users of administrator or owner rank can administer the deployment. -/
theorem system_administrator_policy (subject : admin.Principal) (role : userrole.UserRole)
    (is_external active : Bool) (r : admin.AdminDecision)
    (h : admin.require_system_admin subject role is_external active = ok r) :
    (r = .Allowed ↔ SpecKernel.SystemAdminAllowed subject role is_external active) ∧
    (∀ reason, r = .Denied reason → SpecKernel.SystemAdminDenial subject role is_external active reason) :=
  Verified.OxicloudAdmin.required_admin_ok subject role is_external active r h


/-- The internal-account restriction classifies external and absent accounts. -/
theorem internal_account_policy (flags : liveauth.FlagsLookup) (id : U128)
    (r : core.result.Result Unit liveauth.InternalDenial)
    (h : liveauth.decide_internal_user flags id = ok r) :
    (r = .Ok () ↔ SpecKernel.InternalAccountAllowed flags) ∧
    (∀ reason, r = .Err reason → SpecKernel.InternalAccountDenied flags reason) := by
  exact oxicloud_kernel.Verified.OxicloudLiveAuth.internal_ok flags id r h

/-- Current active accounts supply the current role; inactive and missing accounts revoke. -/
theorem live_account_role_policy (flags : liveauth.FlagsLookup) (id : U128) (claim : Slice U8)
    (r : liveauth.LiveRole) (h : liveauth.decide_live_role flags id claim = ok r) :
    SpecKernel.LiveAccountRole flags claim.val r := by
  exact oxicloud_kernel.Verified.OxicloudLiveAuth.live_role_ok flags id claim r h

/-- Only the canonical anonymous session claim can bypass the account lookup. -/
theorem anonymous_role_lookup_bypass (claim : Slice U8) (r : Option liveauth.LiveRole)
    (h : liveauth.anonymous_live_role claim = ok r) : SpecKernel.AnonymousLiveRole claim.val r := by
  exact oxicloud_kernel.Verified.OxicloudLiveAuth.anonymous_ok claim r h

end oxicloud_kernel.Properties
