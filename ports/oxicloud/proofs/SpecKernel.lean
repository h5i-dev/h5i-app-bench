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

end oxicloud_kernel.SpecKernel
