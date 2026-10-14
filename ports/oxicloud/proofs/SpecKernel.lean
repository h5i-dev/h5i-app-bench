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

end oxicloud_kernel.SpecKernel
