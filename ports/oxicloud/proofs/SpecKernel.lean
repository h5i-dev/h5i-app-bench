import Spec
open Aeneas Aeneas.Std oxicloud_kernel

namespace oxicloud_kernel.SpecKernel

/-- The session role policy: anonymous visitors, ordinary users, administrators,
and server owners in increasing privilege order. -/
def RoleLevel : userrole.UserRole → Nat
  | .Anonymous => 0
  | .User => 1
  | .Admin => 2
  | .Owner => 3

/-- Canonical spellings accepted at the session boundary. -/
def RoleWire : userrole.UserRole → List U8
  | .Owner => [111#u8, 119#u8, 110#u8, 101#u8, 114#u8]
  | .Admin => [97#u8, 100#u8, 109#u8, 105#u8, 110#u8]
  | .User => [117#u8, 115#u8, 101#u8, 114#u8]
  | .Anonymous => [97#u8, 110#u8, 111#u8, 110#u8, 121#u8, 109#u8, 111#u8, 117#u8, 115#u8]

/-- A stored user row has one of the three named account roles. -/
def StoredRole (raw : List U8) (r : userrole.UserRole) : Prop :=
  raw = RoleWire r ∧ r ≠ .Anonymous

/-- A session may additionally represent an anonymous visitor. -/
def SessionRole (raw : List U8) (r : userrole.UserRole) : Prop := raw = RoleWire r

/-- A wire role satisfies a requirement only if its canonical spelling is
recognized and its privilege is sufficient. -/
def MeetsRole (raw : List U8) (min : userrole.UserRole) : Prop :=
  ∃ r, SessionRole raw r ∧ RoleLevel min ≤ RoleLevel r



/-- Canonical database discriminator for subjects. -/
def SubjectWire : model.Subject → List U8
  | .User _ => [117#u8, 115#u8, 101#u8, 114#u8]
  | .Group _ => [103#u8, 114#u8, 111#u8, 117#u8, 112#u8]
  | .Token _ => [116#u8, 111#u8, 107#u8, 101#u8, 110#u8]

/-- Identity in a subject namespace. -/
def SubjectId : model.Subject → U64
  | .User id => id
  | .Group id => id
  | .Token id => id

/-- Canonical database discriminator for resources. -/
def ResourceWire : model.Resource → List U8
  | .Folder _ => [102#u8, 111#u8, 108#u8, 100#u8, 101#u8, 114#u8]
  | .File _ => [102#u8, 105#u8, 108#u8, 101#u8]
  | .Drive _ => [100#u8, 114#u8, 105#u8, 118#u8, 101#u8]
  | .Calendar _ => [99#u8, 97#u8, 108#u8, 101#u8, 110#u8, 100#u8, 97#u8, 114#u8]
  | .AddressBook _ => [97#u8, 100#u8, 100#u8, 114#u8, 101#u8, 115#u8, 115#u8, 95#u8, 98#u8, 111#u8, 111#u8, 107#u8]
  | .Playlist _ => [112#u8, 108#u8, 97#u8, 121#u8, 108#u8, 105#u8, 115#u8, 116#u8]

/-- Identity in a resource namespace. -/
def ResourceId : model.Resource → U64
  | .Folder id => id
  | .File id => id
  | .Drive id => id
  | .Calendar id => id
  | .AddressBook id => id
  | .Playlist id => id

/-- Canonical database discriminator for permissions. -/
def PermissionWire : model.Permission → List U8
  | .Read => [114#u8, 101#u8, 97#u8, 100#u8]
  | .Create => [99#u8, 114#u8, 101#u8, 97#u8, 116#u8, 101#u8]
  | .Share => [115#u8, 104#u8, 97#u8, 114#u8, 101#u8]
  | .Comment => [99#u8, 111#u8, 109#u8, 109#u8, 101#u8, 110#u8, 116#u8]
  | .Delete => [100#u8, 101#u8, 108#u8, 101#u8, 116#u8, 101#u8]
  | .Update => [117#u8, 112#u8, 100#u8, 97#u8, 116#u8, 101#u8]
  | .Manage => [109#u8, 97#u8, 110#u8, 97#u8, 103#u8, 101#u8]

/-- Complete stable enumeration used by permission queries. -/
def PermissionOrder : List model.Permission := [.Read, .Create, .Share, .Comment, .Delete, .Update, .Manage]

/-- Canonical database discriminator for roles. -/
def GrantRoleWire : model.Role → List U8
  | .Viewer => [118#u8, 105#u8, 101#u8, 119#u8, 101#u8, 114#u8]
  | .Commenter => [99#u8, 111#u8, 109#u8, 109#u8, 101#u8, 110#u8, 116#u8, 101#u8, 114#u8]
  | .Contributor => [99#u8, 111#u8, 110#u8, 116#u8, 114#u8, 105#u8, 98#u8, 117#u8, 116#u8, 111#u8, 114#u8]
  | .Editor => [101#u8, 100#u8, 105#u8, 116#u8, 111#u8, 114#u8]
  | .Owner => [111#u8, 119#u8, 110#u8, 101#u8, 114#u8]

/-- Complete stable enumeration used by permission queries. -/
def RoleOrder : List model.Role := [.Viewer, .Commenter, .Contributor, .Editor, .Owner]


/-- A drive's explicit choices override its kind's defaults, including explicit
false choices. An absent expiry cap override inherits the default cap. -/
def PolicyResolved (d : drivepolicy.Policies) (o : drivepolicy.Overrides)
    (r : drivepolicy.Policies) : Prop :=
  r.forbid_sharing = o.forbid_sharing.getD d.forbid_sharing ∧
  r.forbid_external_sharing = o.forbid_external_sharing.getD d.forbid_external_sharing ∧
  r.forbid_public_links = o.forbid_public_links.getD d.forbid_public_links ∧
  r.forbid_cross_drive_move = o.forbid_cross_drive_move.getD d.forbid_cross_drive_move ∧
  r.forbid_owner_role_change = o.forbid_owner_role_change.getD d.forbid_owner_role_change ∧
  r.include_in_photo_index = o.include_in_photo_index.getD d.include_in_photo_index ∧
  r.include_in_music_index = o.include_in_music_index.getD d.include_in_music_index ∧
  r.read_only = o.read_only.getD d.read_only ∧
  r.require_public_link_password = o.require_public_link_password.getD d.require_public_link_password ∧
  r.max_public_link_days = o.max_public_link_days.or d.max_public_link_days

/-- Both the broad sharing policy and the link-specific policy permit minting. -/
def PublicLinksAllowed (p : drivepolicy.Policies) : Prop :=
  p.forbid_sharing = false ∧ p.forbid_public_links = false

def SharingAllowed (p : drivepolicy.Policies) : Prop := p.forbid_sharing = false

/-- Administrators may manage a locked owner roster. -/
def OwnerChangesAllowed (p : drivepolicy.Policies) (admin : Bool) : Prop :=
  p.forbid_owner_role_change = false ∨ admin = true

def CrossDriveMoveAllowed (p : drivepolicy.Policies) : Prop :=
  p.forbid_cross_drive_move = false

/-- Only external user principals are constrained by the external-sharing knob. -/
def ExternalSharingAllowed (p : drivepolicy.Policies) (s : model.Subject) (external : Bool) : Prop :=
  p.forbid_external_sharing = false ∨ (∀ id, s ≠ .User id) ∨ external = false

/-- A policy guard succeeds exactly when allowed and otherwise returns the
canonical unsupported-operation refusal. -/
def GuardDecision (allowed : Prop) (r : core.result.Result Unit model.ErrorKind) : Prop :=
  (r = .Ok () ↔ allowed) ∧ (r = .Err .OperationNotSupported ↔ ¬allowed)



/-- Canonical session origins retain the authentication mechanism across restoration. -/
def OriginWire : session.SessionOrigin → List U8
  | .Password => [112#u8, 97#u8, 115#u8, 115#u8, 119#u8, 111#u8, 114#u8, 100#u8]
  | .Opaque => [111#u8, 112#u8, 97#u8, 113#u8, 117#u8, 101#u8]
  | .MagicLink => [109#u8, 97#u8, 103#u8, 105#u8, 99#u8, 95#u8, 108#u8, 105#u8, 110#u8, 107#u8]
  | .Oidc => [111#u8, 105#u8, 100#u8, 99#u8]
  | .Device => [100#u8, 101#u8, 118#u8, 105#u8, 99#u8, 101#u8]
  | .Unknown => [117#u8, 110#u8, 107#u8, 110#u8, 111#u8, 119#u8, 110#u8]

/-- Known authentication origins are recognized exactly, with Unknown as the fallback. -/
def OriginDecoded (raw : List U8) (o : session.SessionOrigin) : Prop :=
  ∀ known, known ≠ .Unknown → (o = known ↔ raw = OriginWire known)

/-- Revocation changes no identity, credential, binding, or lifetime information. -/
def SessionRevoked (before after : session.Session) : Prop :=
  after.revoked = true ∧ { after with revoked := before.revoked } = before

/-- Binding only applies to an unbound session and changes no other security state. -/
def SessionBound (before : session.Session) (key : alloc.vec.Vec U8) (after : session.Session) : Prop :=
  before.dpop_jkt = none ∧ after.dpop_jkt = some key ∧
  { after with dpop_jkt := before.dpop_jkt } = before

/-- OIDC logout metadata changes cannot alter the principal, DPoP binding, or revocation. -/
def SessionTokenAttached (before : session.Session) (token : alloc.vec.Vec U8)
    (after : session.Session) : Prop :=
  after.oidc_id_token = some token ∧ { after with oidc_id_token := before.oidc_id_token } = before

def SessionSidAttached (before : session.Session) (sid : alloc.vec.Vec U8)
    (after : session.Session) : Prop :=
  after.oidc_sid = some sid ∧ { after with oidc_sid := before.oidc_sid } = before



/-- Storage selectors use a bounded ASCII alphabet suitable for environment and URL names. -/
def StorageByte (b : U8) : Prop :=
  (97 ≤ b.val ∧ b.val ≤ 122) ∨ (48 ≤ b.val ∧ b.val ≤ 57) ∨ b.val = 95 ∨ b.val = 45

def Base64UrlByte (b : U8) : Prop := StorageByte b ∨ (65 ≤ b.val ∧ b.val ≤ 90)

def ValidStorageName (raw : List U8) : Prop :=
  1 ≤ raw.length ∧ raw.length ≤ 32 ∧ ∀ b ∈ raw, StorageByte b

/-- A login thumbprint has the unpadded base64url shape of a SHA-256 digest. -/
def ValidJkt (raw : List U8) : Prop := raw.length = 43 ∧ ∀ b ∈ raw, Base64UrlByte b

def JktDecision (raw : List U8)
    (r : core.result.Result (alloc.vec.Vec U8) validation.JktError) : Prop :=
  match r with
  | .Ok value => ValidJkt raw ∧ value.val = raw
  | .Err .WrongLength => raw.length ≠ 43
  | .Err .BadAlphabet => raw.length = 43 ∧ ¬ ∀ b ∈ raw, Base64UrlByte b

/-- Required verification admits only an explicit true claim; audit reasons distinguish
asserted false claims from absent claims and flag-disabled acceptance. -/
def VerifiedEmailDecision (claim : Option Bool) (required : Bool) (d : validation.EmailDecision) : Prop :=
  (d.reject = false ↔ (required = true → claim = some true)) ∧
  (d.reason = some .Unverified ↔ claim = some false ∧ required = true) ∧
  (d.reason = some .UnverifiedFlagOff ↔ claim = some false ∧ required = false) ∧
  (d.reason = some .ClaimAbsentRequired ↔ claim = none ∧ required = true) ∧
  (d.reason = none ↔ claim = some true ∨ (claim = none ∧ required = false))



/-- Password changes preserve the resource, creator, token, lifetime, and accounting state. -/
def SharePasswordChanged (before : share.Share) (hash : Option (alloc.vec.Vec U8))
    (after : share.Share) : Prop :=
  after.password_hash = hash ∧ { after with password_hash := before.password_hash } = before

/-- Rotating a share token cannot remove its password requirement or change its target or expiry. -/
def ShareTokenChanged (before : share.Share) (token : alloc.vec.Vec U8) (after : share.Share) : Prop :=
  after.token = token ∧ { after with token := before.token } = before

/-- Access accounting increases by one without wrapping or changing authorization state. -/
def ShareAccessCounted (before after : share.Share) : Prop :=
  after.access_count.val = before.access_count.val + 1 ∧
  { after with access_count := before.access_count } = before

/-- Subject names form a bounded ASCII namespace with an alphanumeric initial byte. -/
def GroupAlphanumeric (b : U8) : Prop :=
  (97 ≤ b.val ∧ b.val ≤ 122) ∨ (65 ≤ b.val ∧ b.val ≤ 90) ∨ (48 ≤ b.val ∧ b.val ≤ 57)
def GroupNameByte (b : U8) : Prop :=
  GroupAlphanumeric b ∨ b.val = 46 ∨ b.val = 45 ∨ b.val = 95
def GroupNameStart (raw : List U8) : Prop :=
  ∃ b, raw[0]? = some b ∧ GroupAlphanumeric b
def ValidGroupName (raw : List U8) : Prop :=
  1 ≤ raw.length ∧ raw.length ≤ 64 ∧ GroupNameStart raw ∧ ∀ b ∈ raw, GroupNameByte b
/-- Typed rejection reasons retain length, initial-byte, and alphabet precedence. -/
def GroupNameDecision (raw : List U8)
    (r : core.result.Result Unit subjectgroup.NameError) : Prop :=
  match r with
  | .Ok _ => ValidGroupName raw
  | .Err .Empty => raw.length = 0
  | .Err .TooLong => 1 ≤ raw.length ∧ 64 < raw.length
  | .Err .InvalidStart => 1 ≤ raw.length ∧ raw.length ≤ 64 ∧ ¬ GroupNameStart raw
  | .Err .InvalidCharacter => 1 ≤ raw.length ∧ raw.length ≤ 64 ∧
      GroupNameStart raw ∧ ¬ (∀ b ∈ raw, GroupNameByte b)


/-- Canonical magic-link resource discriminator. -/
def MagicResourceWire : magiclink.MagicLinkResourceKind → List U8
  | .File => [102#u8, 105#u8, 108#u8, 101#u8]
  | .Folder => [102#u8, 111#u8, 108#u8, 100#u8, 101#u8, 114#u8]

/-- Canonical magic-link status discriminator. -/
def MagicStatusWire : magiclink.MagicLinkStatus → List U8
  | .Pending => [112#u8, 101#u8, 110#u8, 100#u8, 105#u8, 110#u8, 103#u8]
  | .Used => [117#u8, 115#u8, 101#u8, 100#u8]
  | .Expired => [101#u8, 120#u8, 112#u8, 105#u8, 114#u8, 101#u8, 100#u8]

/-- UTC deadlines compare signed seconds, then subsecond precision. -/
def TimestampPast (now deadline : session.Timestamp) : Prop :=
  deadline.seconds.val < now.seconds.val ∨
    (now.seconds.val = deadline.seconds.val ∧ deadline.nanoseconds.val < now.nanoseconds.val)
def TimestampWithin (now deadline : session.Timestamp) : Prop :=
  now.seconds.val < deadline.seconds.val ∨
    (now.seconds.val = deadline.seconds.val ∧ now.nanoseconds.val ≤ deadline.nanoseconds.val)
/-- A magic link is usable only while Pending and at or before its deadline. -/
def MagicLinkRedeemable (s : magiclink.MagicLinkToken) (now : session.Timestamp) : Prop :=
  s.status = .Pending ∧ TimestampWithin now s.expires_at


def FederationWire : userstate.FederationKind → List U8
  | .MagicLink => [109#u8, 97#u8, 103#u8, 105#u8, 99#u8, 95#u8, 108#u8, 105#u8, 110#u8, 107#u8]
  | .Ocm => [111#u8, 99#u8, 109#u8]
  | .Oidc => [111#u8, 105#u8, 100#u8, 99#u8]

def AccountLoginCredential (s : userstate.User) : Prop :=
  (∃ hash, s.password_hash = some hash) ∨ (∃ subject, s.federation_subject = some subject)

def AccountPartsPreserved (s : userstate.User) (p : userstate.UserParts) : Prop :=
  p.id = s.id ∧
  p.username = s.username ∧
  p.email = s.email ∧
  p.password_hash = s.password_hash ∧
  p.role = s.role ∧
  p.storage_quota_bytes = s.storage_quota_bytes ∧
  p.storage_used_bytes = s.storage_used_bytes ∧
  p.created_at = s.created_at ∧
  p.updated_at = s.updated_at ∧
  p.last_login_at = s.last_login_at ∧
  p.active = s.active ∧
  p.federation_kind = s.federation_kind ∧
  p.federation_issuer = s.federation_issuer ∧
  p.federation_subject = s.federation_subject ∧
  p.image = s.image ∧
  p.is_external = s.is_external ∧
  p.given_name = s.given_name ∧
  p.family_name = s.family_name ∧
  p.email_verified_at = s.email_verified_at ∧
  p.preferred_locale = s.preferred_locale ∧
  p.notify_on_share = s.notify_on_share ∧
  p.ui_preferences = s.ui_preferences

def MinimalAccountRestored (s r : userstate.User) : Prop :=
  r.id = s.id ∧
  r.username = s.username ∧
  r.email = s.email ∧
  r.password_hash = s.password_hash ∧
  r.role = s.role ∧
  r.storage_quota_bytes = s.storage_quota_bytes ∧
  r.storage_used_bytes = s.storage_used_bytes ∧
  r.created_at = s.created_at ∧
  r.updated_at = s.updated_at ∧
  r.last_login_at = s.last_login_at ∧
  r.active = s.active ∧
  r.federation_kind = none ∧
  r.federation_issuer = none ∧
  r.federation_subject = none ∧
  r.image = none ∧
  r.is_external = false ∧
  r.given_name = none ∧
  r.family_name = none ∧
  r.email_verified_at = none ∧
  r.preferred_locale = none ∧
  r.notify_on_share = true ∧
  r.ui_preferences.val = [123#u8, 125#u8]

def AdminVisibilityWire : admin.AuthzDenialVisibility → List U8
  | .Visible => [118#u8,105#u8,115#u8,105#u8,98#u8,108#u8,101#u8]
  | .Hidden => [104#u8,105#u8,100#u8,100#u8,101#u8,110#u8]
def AdminDenialWire : admin.AdminDenial → List U8
  | .Inactive => [105#u8,110#u8,97#u8,99#u8,116#u8,105#u8,118#u8,101#u8]
  | .ExternalAccount => [101#u8,120#u8,116#u8,101#u8,114#u8,110#u8,97#u8,108#u8,95#u8,97#u8,99#u8,99#u8,111#u8,117#u8,110#u8,116#u8]
  | .NotAdmin => [110#u8,111#u8,116#u8,95#u8,97#u8,100#u8,109#u8,105#u8,110#u8]
  | .UnsupportedSubject => [117#u8,110#u8,115#u8,117#u8,112#u8,112#u8,111#u8,114#u8,116#u8,101#u8,100#u8,95#u8,115#u8,117#u8,98#u8,106#u8,101#u8,99#u8,116#u8]
/-- Deployment administration requires a live internal user of at least administrator rank. -/
def SystemAdminAllowed (subject : admin.Principal) (role : userrole.UserRole)
    (is_external active : Bool) : Prop :=
  (∃ id, subject = .User id) ∧ active = true ∧ is_external = false ∧ 2 ≤ RoleLevel role
/-- Denial reasons retain their precedence and cannot misattribute a missing condition. -/
def SystemAdminDenial (subject : admin.Principal) (role : userrole.UserRole)
    (is_external active : Bool) (reason : admin.AdminDenial) : Prop :=
  match reason with
  | .Inactive => (∃ id, subject = .User id) ∧ active = false
  | .ExternalAccount => (∃ id, subject = .User id) ∧ active = true ∧ is_external = true
  | .NotAdmin => (∃ id, subject = .User id) ∧ active = true ∧ is_external = false ∧ RoleLevel role < 2
  | .UnsupportedSubject => ∀ id, subject ≠ .User id


/-- The internal-account restriction allows an existing internal account or an unavailable lookup. -/
def InternalAccountAllowed (flags : liveauth.FlagsLookup) : Prop :=
  match flags with
  | .Found f => f.is_external = false
  | .NotFound => False
  | .Unavailable => True

/-- Each internal-account denial identifies the account condition that caused it. -/
def InternalAccountDenied (flags : liveauth.FlagsLookup) (reason : liveauth.InternalDenial) : Prop :=
  match flags, reason with
  | .Found f, .External => f.is_external = true
  | .NotFound, .NoAccount => True
  | _, _ => False

/-- A live account supplies its current role; absence or inactivity revokes the session.
    An unavailable lookup preserves the original claim bytes. -/
def LiveAccountRole (flags : liveauth.FlagsLookup) (claim : List U8) (out : liveauth.LiveRole) : Prop :=
  match flags, out with
  | .Found f, .Active role => f.active = true ∧ role.val = RoleWire f.role
  | .Found f, .Revoked => f.active = false
  | .NotFound, .Revoked => True
  | .Unavailable, .Active role => role.val = claim
  | _, _ => False

/-- Only the canonical anonymous session role can bypass the account lookup. -/
def AnonymousLiveRole (claim : List U8) (out : Option liveauth.LiveRole) : Prop :=
  (out = none ↔ claim ≠ RoleWire .Anonymous) ∧
  (∀ value, out = some value → ∃ role, value = .Active role ∧ role.val = RoleWire .Anonymous ∧ claim = RoleWire .Anonymous)


/-- Canonical order of independently configurable drive policies. -/
def PolicyKnobOrder : List policycompare.Knob :=
  [.ForbidSharing, .ForbidExternalSharing, .ForbidPublicLinks, .ForbidCrossDriveMove,
   .ForbidOwnerRoleChange, .IncludeInPhotoIndex, .IncludeInMusicIndex, .ReadOnly,
   .MaxPublicLinkDays, .RequirePublicLinkPassword]

def PolicyBit (p : drivepolicy.Policies) : policycompare.Knob → Bool
  | .ForbidSharing => p.forbid_sharing
  | .ForbidExternalSharing => p.forbid_external_sharing
  | .ForbidPublicLinks => p.forbid_public_links
  | .ForbidCrossDriveMove => p.forbid_cross_drive_move
  | .ForbidOwnerRoleChange => p.forbid_owner_role_change
  | .IncludeInPhotoIndex => p.include_in_photo_index
  | .IncludeInMusicIndex => p.include_in_music_index
  | .ReadOnly => p.read_only
  | .RequirePublicLinkPassword => p.require_public_link_password
  | _ => false

/-- Every configured upper bound is respected, with no bound weaker than any finite bound. -/
def PolicyCapRefines (own required : Option U32) : Prop :=
  ∀ bound, required = some bound → ∃ cap, own = some cap ∧ cap.val ≤ bound.val

/-- Refinement preserves prohibitions, reduces index exposure, and tightens link lifetimes. -/
def PolicyRefines (p q : drivepolicy.Policies) (knob : policycompare.Knob) : Prop :=
  match knob with
  | .MaxPublicLinkDays => PolicyCapRefines p.max_public_link_days q.max_public_link_days
  | .IncludeInPhotoIndex | .IncludeInMusicIndex => PolicyBit p knob = true → PolicyBit q knob = true
  | _ => PolicyBit q knob = true → PolicyBit p knob = true

def PolicyApplies (knob : policycompare.Knob) (kind : model.DriveKind) : Prop :=
  knob ≠ .ForbidOwnerRoleChange ∨ kind ≠ .Personal

def PolicyDefaultable (knob : policycompare.Knob) : Prop := knob ≠ .ReadOnly

/-- Drift consists only of applicable standing defaults that the current drive fails to refine. -/
def PolicyWeak (p d : drivepolicy.Policies) (kind : model.DriveKind) (knob : policycompare.Knob) : Prop :=
  PolicyApplies knob kind ∧ PolicyDefaultable knob ∧ ¬PolicyRefines p d knob

noncomputable def PolicyWeakerList (p d : drivepolicy.Policies) (kind : model.DriveKind) : List policycompare.Knob := by
  classical
  exact PolicyKnobOrder.filter (fun knob => decide (PolicyWeak p d kind knob))

/-- Policy values have exactly the boolean, bounded-integer, or null shape declared by their knob. -/
def PolicyValue (p : drivepolicy.Policies) (knob : policycompare.Knob) (out : policycompare.KnobValue) : Prop :=
  match knob with
  | .Other => out = .Null
  | .MaxPublicLinkDays =>
    match p.max_public_link_days with
    | none => out = .Null
    | some n => out = .Number n
  | _ => out = .Bool (PolicyBit p knob)

/-- Opt-in indices are false-stricter, link lifetime is smaller-stricter, and other flags are true-stricter. -/
def PolicyStrictness (knob : policycompare.Knob) (out : policycompare.Strictness) : Prop :=
  match knob with
  | .IncludeInPhotoIndex | .IncludeInMusicIndex => out = .FalseIsStricter
  | .MaxPublicLinkDays => out = .SmallerIsStricter
  | _ => out = .TrueIsStricter


/-- Exact policy-name spelling table; Other has no canonical spelling. -/
def PolicyKnobWire : policycompare.Knob → Option (List U8)
  | .ForbidSharing => some [102#u8, 111#u8, 114#u8, 98#u8, 105#u8, 100#u8, 95#u8, 115#u8, 104#u8, 97#u8, 114#u8, 105#u8, 110#u8, 103#u8]
  | .ForbidExternalSharing => some [102#u8, 111#u8, 114#u8, 98#u8, 105#u8, 100#u8, 95#u8, 101#u8, 120#u8, 116#u8, 101#u8, 114#u8, 110#u8, 97#u8, 108#u8, 95#u8, 115#u8, 104#u8, 97#u8, 114#u8, 105#u8, 110#u8, 103#u8]
  | .ForbidPublicLinks => some [102#u8, 111#u8, 114#u8, 98#u8, 105#u8, 100#u8, 95#u8, 112#u8, 117#u8, 98#u8, 108#u8, 105#u8, 99#u8, 95#u8, 108#u8, 105#u8, 110#u8, 107#u8, 115#u8]
  | .ForbidCrossDriveMove => some [102#u8, 111#u8, 114#u8, 98#u8, 105#u8, 100#u8, 95#u8, 99#u8, 114#u8, 111#u8, 115#u8, 115#u8, 95#u8, 100#u8, 114#u8, 105#u8, 118#u8, 101#u8, 95#u8, 109#u8, 111#u8, 118#u8, 101#u8]
  | .ForbidOwnerRoleChange => some [102#u8, 111#u8, 114#u8, 98#u8, 105#u8, 100#u8, 95#u8, 111#u8, 119#u8, 110#u8, 101#u8, 114#u8, 95#u8, 114#u8, 111#u8, 108#u8, 101#u8, 95#u8, 99#u8, 104#u8, 97#u8, 110#u8, 103#u8, 101#u8]
  | .IncludeInPhotoIndex => some [105#u8, 110#u8, 99#u8, 108#u8, 117#u8, 100#u8, 101#u8, 95#u8, 105#u8, 110#u8, 95#u8, 112#u8, 104#u8, 111#u8, 116#u8, 111#u8, 95#u8, 105#u8, 110#u8, 100#u8, 101#u8, 120#u8]
  | .IncludeInMusicIndex => some [105#u8, 110#u8, 99#u8, 108#u8, 117#u8, 100#u8, 101#u8, 95#u8, 105#u8, 110#u8, 95#u8, 109#u8, 117#u8, 115#u8, 105#u8, 99#u8, 95#u8, 105#u8, 110#u8, 100#u8, 101#u8, 120#u8]
  | .ReadOnly => some [114#u8, 101#u8, 97#u8, 100#u8, 95#u8, 111#u8, 110#u8, 108#u8, 121#u8]
  | .MaxPublicLinkDays => some [109#u8, 97#u8, 120#u8, 95#u8, 112#u8, 117#u8, 98#u8, 108#u8, 105#u8, 99#u8, 95#u8, 108#u8, 105#u8, 110#u8, 107#u8, 95#u8, 100#u8, 97#u8, 121#u8, 115#u8]
  | .RequirePublicLinkPassword => some [114#u8, 101#u8, 113#u8, 117#u8, 105#u8, 114#u8, 101#u8, 95#u8, 112#u8, 117#u8, 98#u8, 108#u8, 105#u8, 99#u8, 95#u8, 108#u8, 105#u8, 110#u8, 107#u8, 95#u8, 112#u8, 97#u8, 115#u8, 115#u8, 119#u8, 111#u8, 114#u8, 100#u8]
  | .Other => none

def PolicyKnobNames : List (List U8) :=
  [[102#u8, 111#u8, 114#u8, 98#u8, 105#u8, 100#u8, 95#u8, 115#u8, 104#u8, 97#u8, 114#u8, 105#u8, 110#u8, 103#u8],
   [102#u8, 111#u8, 114#u8, 98#u8, 105#u8, 100#u8, 95#u8, 101#u8, 120#u8, 116#u8, 101#u8, 114#u8, 110#u8, 97#u8, 108#u8, 95#u8, 115#u8, 104#u8, 97#u8, 114#u8, 105#u8, 110#u8, 103#u8],
   [102#u8, 111#u8, 114#u8, 98#u8, 105#u8, 100#u8, 95#u8, 112#u8, 117#u8, 98#u8, 108#u8, 105#u8, 99#u8, 95#u8, 108#u8, 105#u8, 110#u8, 107#u8, 115#u8],
   [102#u8, 111#u8, 114#u8, 98#u8, 105#u8, 100#u8, 95#u8, 99#u8, 114#u8, 111#u8, 115#u8, 115#u8, 95#u8, 100#u8, 114#u8, 105#u8, 118#u8, 101#u8, 95#u8, 109#u8, 111#u8, 118#u8, 101#u8],
   [102#u8, 111#u8, 114#u8, 98#u8, 105#u8, 100#u8, 95#u8, 111#u8, 119#u8, 110#u8, 101#u8, 114#u8, 95#u8, 114#u8, 111#u8, 108#u8, 101#u8, 95#u8, 99#u8, 104#u8, 97#u8, 110#u8, 103#u8, 101#u8],
   [105#u8, 110#u8, 99#u8, 108#u8, 117#u8, 100#u8, 101#u8, 95#u8, 105#u8, 110#u8, 95#u8, 112#u8, 104#u8, 111#u8, 116#u8, 111#u8, 95#u8, 105#u8, 110#u8, 100#u8, 101#u8, 120#u8],
   [105#u8, 110#u8, 99#u8, 108#u8, 117#u8, 100#u8, 101#u8, 95#u8, 105#u8, 110#u8, 95#u8, 109#u8, 117#u8, 115#u8, 105#u8, 99#u8, 95#u8, 105#u8, 110#u8, 100#u8, 101#u8, 120#u8],
   [114#u8, 101#u8, 97#u8, 100#u8, 95#u8, 111#u8, 110#u8, 108#u8, 121#u8],
   [109#u8, 97#u8, 120#u8, 95#u8, 112#u8, 117#u8, 98#u8, 108#u8, 105#u8, 99#u8, 95#u8, 108#u8, 105#u8, 110#u8, 107#u8, 95#u8, 100#u8, 97#u8, 121#u8, 115#u8],
   [114#u8, 101#u8, 113#u8, 117#u8, 105#u8, 114#u8, 101#u8, 95#u8, 112#u8, 117#u8, 98#u8, 108#u8, 105#u8, 99#u8, 95#u8, 108#u8, 105#u8, 110#u8, 107#u8, 95#u8, 112#u8, 97#u8, 115#u8, 115#u8, 119#u8, 111#u8, 114#u8, 100#u8]]

/-- Canonical names select their own knob; all other bytes select Other. -/
def PolicyKnobParsed (raw : List U8) (knob : policycompare.Knob) : Prop :=
  match knob with
  | .Other => raw ∉ PolicyKnobNames
  | _ => PolicyKnobWire knob = some raw

/-- Default settings must be recognized, standing policy, and applicable to the kind. -/
def DefaultKnobAllowed (knob : policycompare.Knob) (kind : model.DriveKind) : Prop :=
  knob ≠ .Other ∧ knob ≠ .ReadOnly ∧ PolicyApplies knob kind

def DefaultKnobRejection (knob : policycompare.Knob) (kind : model.DriveKind)
    (reason : policydefaults.KeyRejection) : Prop :=
  match reason with
  | .NotDefaultable => knob = .ReadOnly
  | .Unknown => knob = .Other
  | .NotApplicable => knob = .ForbidOwnerRoleChange ∧ kind = .Personal

def DefaultKeyAllowed (raw : List U8) (kind : model.DriveKind) : Prop :=
  ∃ knob, PolicyKnobParsed raw knob ∧ DefaultKnobAllowed knob kind

def DefaultKeyRejection (raw : List U8) (kind : model.DriveKind)
    (reason : policydefaults.KeyRejection) : Prop :=
  ∃ knob, PolicyKnobParsed raw knob ∧ DefaultKnobRejection knob kind reason

/-- A key failure identifies the first rejected key; success validates every key. -/
def DefaultsValidation (kind : model.DriveKind) (isObject : Bool)
    (keys : List (alloc.vec.Vec U8)) (r : policydefaults.Validation) : Prop :=
  match r with
  | .NotObject => isObject = false
  | .Valid => isObject = true ∧ ∀ raw ∈ keys, DefaultKeyAllowed raw.val kind
  | .Rejected index reason => isObject = true ∧
      (∃ raw, keys[index.val]? = some raw ∧ DefaultKeyRejection raw.val kind reason) ∧
      ∀ j < index.val, ∀ raw, keys[j]? = some raw → DefaultKeyAllowed raw.val kind

end oxicloud_kernel.SpecKernel
