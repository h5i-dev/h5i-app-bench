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

end oxicloud_kernel.SpecKernel
