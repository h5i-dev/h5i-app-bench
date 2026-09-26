import KellnrKernel
/-!
# Kellnr registry authorization: the spec

Written from Kellnr's documented rules, over plain lists. Nothing here uses
the kernel's helpers, so the theorems are not circular.
-/
open Aeneas Aeneas.Std

namespace kellnr_kernel

deriving instance DecidableEq for Login

end kellnr_kernel

namespace kellnr_kernel.Spec

structure St where
  users : List User
  crates : List Krate
  versions : List Version
  owners : List Pair
  crateUsers : List Pair
  crateGroups : List Pair
  groupMembers : List Pair
  allowOwnerless : Bool
  newCratesRestricted : Bool

def Snapshot.toSt (s : Snapshot) : St :=
  ⟨s.users.val, s.crates.val, s.versions.val, s.owners.val, s.crate_users.val,
    s.crate_groups.val, s.group_members.val, s.settings.allow_ownerless_crates,
    s.settings.new_crates_restricted⟩

/-! ## Facts read from the database -/

def userOf (s : St) (u : Nat) : Option User := s.users.find? (·.id.val = u)

def isAdmin (s : St) (u : Nat) : Bool := (userOf s u).any (·.is_admin)

/-- The user's read-only flag as stored, whatever the login path. -/
def isReadOnly (s : St) (u : Nat) : Bool := (userOf s u).any (·.is_read_only)

def hasPair (l : List Pair) (a b : Nat) : Bool := l.any (fun x => x.a.val = a ∧ x.b.val = b)

def isOwner (s : St) (k u : Nat) : Bool := hasPair s.owners k u

def isCrateUser (s : St) (k u : Nat) : Bool := hasPair s.crateUsers k u

/-- `u` is in a group granted on crate `k`. -/
def inGrantedGroup (s : St) (k u : Nat) : Bool :=
  s.crateGroups.any (fun g => g.a.val = k ∧ hasPair s.groupMembers g.b.val u)

def crateExists (s : St) (k : Nat) : Bool := s.crates.any (·.id.val = k)

def restricted (s : St) (k : Nat) : Bool := (s.crates.find? (·.id.val = k)).any (·.restricted)

def ownerCount (s : St) (k : Nat) : Nat := (s.owners.filter (·.a.val = k)).length

/-! ## Policy -/

/-- Read-only users may not change anything, unless they are admins. -/
def mayModify (s : St) (u : Nat) : Bool := isAdmin s u || !isReadOnly s u

/-- Who may make a single write, judged on the state before the command.
ACL and yank changes need an admin or an owner of the crate; publishing a new
crate makes the publisher its first owner. -/
def writeAllowed (s : St) (u : Nat) : Write → Prop
  | .AddOwner x => isAdmin s u ∨ isOwner s x.a.val u ∨ (¬crateExists s x.a.val ∧ x.b.val = u)
  | .DelOwner x => isAdmin s u ∨ isOwner s x.a.val u
  | .AddCrateUser x | .DelCrateUser x => isAdmin s u ∨ isOwner s x.a.val u
  | .AddCrateGroup x | .DelCrateGroup x => isAdmin s u ∨ isOwner s x.a.val u
  | .SetYanked v => isAdmin s u ∨ isOwner s v.krate.val u
  | .AddVersion v => isAdmin s u ∨ isOwner s v.krate.val u ∨ ¬crateExists s v.krate.val
  | .AddCrate k => ¬crateExists s k.id.val

/-- A restricted crate is served only to a token of an admin, owner, crate
user or member of a granted group. -/
def downloadAllowed (s : St) (p : Principal) (k : Nat) : Prop :=
  restricted s k → p.login = .Token ∧
    (isAdmin s p.user.val ∨ isOwner s k p.user.val ∨ isCrateUser s k p.user.val ∨
      inGrantedGroup s k p.user.val)

end kellnr_kernel.Spec
