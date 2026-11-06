import WindmillKernel
import H5iAppLib
/-!
# What windmill's scope and path checks should do

The file to review. Everything here is stated over lists of bytes (`List U8`) and
propositions, and nothing calls a kernel function. Byte constants: `/` = 47, `*` = 42,
`:` = 58, `,` = 44, `.` = 46, `u` = 117, `f` = 102, `g` = 103.
-/
open Aeneas Aeneas.Std

namespace windmill_kernel.Spec

abbrev Bytes := List U8

/-- `s.split(sep)` is `H5iAppLib.splitB sep s` (`List.splitOnP`): the pieces between
separators, always at least one. -/
abbrev segments (sep : U8) (s : Bytes) : List Bytes := H5iAppLib.splitB sep s

def slashB : U8 := 47#u8
def starB : U8 := 42#u8

/-- `x` lies in the subtree rooted at `p`: it is `p` or continues `p` with `/`. -/
def inSubtree (p x : Bytes) : Prop := x = p ∨ (p ++ [slashB]) <+: x

/-- The concrete paths a resource pattern names: an exact path names itself; a
pattern `p/*` names the subtree of `p`. -/
def names (pat x : Bytes) : Prop :=
  x = pat ∨ (∃ p, pat = p ++ [slashB, starB] ∧ inSubtree p x)

/-- A resource pattern (exact path or subtree) covers another when every path the
second names is named by the first. -/
def coversSem (c r : Bytes) : Prop := ∀ x, names r x → names c x

/-- All bytes are ASCII. -/
def ascii (s : Bytes) : Prop := ∀ b ∈ s, b.val < 128

/-! ## Path ownership -/

def uB : Bytes := [117#u8]
def fB : Bytes := [102#u8]
def dotdot : Bytes := [46#u8, 46#u8]

/-- `a` owns folder `n`: an admin, or an entry for `n` with the owner flag. -/
def ownsFolder (a : windmill_kernel.authz.Authed) (n : Bytes) : Prop :=
  a.is_admin = true ∨ ∃ f ∈ a.folders.val, f.name.val = n ∧ f.is_owner = true

/-- `a` may read folder `n` (any entry, read is enough). -/
def readsFolder (a : windmill_kernel.authz.Authed) (n : Bytes) : Prop :=
  ∃ f ∈ a.folders.val, f.name.val = n

/-- The owner policy for a path: admins; `u/<me>/...`; `f/<owned>/...`. -/
def ownerOfPath (a : windmill_kernel.authz.Authed) (path : Bytes) : Prop :=
  a.is_admin = true ∨
  ∃ segs, segments slashB path = segs ∧ 2 ≤ segs.length ∧
    ((segs[0]! = uB ∧ segs[1]! = a.username.val) ∨ (segs[0]! = fB ∧ ownsFolder a segs[1]!))

/-- A path that could escape a directory: absolute, a `..` segment, or a NUL byte. -/
def traversal (path : Bytes) : Prop :=
  path.head? = some slashB ∨ dotdot ∈ segments slashB path ∨ 0#u8 ∈ path

/-! ## Scope actions -/

def jobsB : Bytes := [106#u8, 111#u8, 98#u8, 115#u8]
def appsB : Bytes := [97#u8, 112#u8, 112#u8, 115#u8]
def readB : Bytes := [114#u8, 101#u8, 97#u8, 100#u8]
def writeB : Bytes := [119#u8, 114#u8, 105#u8, 116#u8, 101#u8]
def runB : Bytes := [114#u8, 117#u8, 110#u8]
def cancelB : Bytes := [99#u8, 97#u8, 110#u8, 99#u8, 101#u8, 108#u8]

/-- Which held action covers which required action in domain `d`: the same action,
`write` covers `read`, and only in `apps` does `write` cover `run`, only in `jobs`
does `write` cover `cancel`. -/
def actionCov (d a b : Bytes) : Prop :=
  a = b ∨ (a = writeB ∧ b = readB) ∨ (a = writeB ∧ b = runB ∧ d = appsB) ∨
    (a = writeB ∧ b = cancelB ∧ d = jobsB)

/-! ## `extra_perms` -/

/-- `extra_perms` names `a` with value `true`: an entry for `u/<username>` or for
`g/<group>` of one of `a`'s groups, whose value is the JSON boolean `true`. -/
def grantedByEntry (obj : List windmill_kernel.authz.PermEntry) (a : windmill_kernel.authz.Authed) : Prop :=
  ∃ e ∈ obj, e.is_bool = true ∧ e.value = true ∧
    (e.key.val = [117#u8, 47#u8] ++ a.username.val ∨ ∃ g ∈ a.groups.val, e.key.val = [103#u8, 47#u8] ++ g.val)

/-! ## Token scopes as strings -/

/-- `if_jobs:filter_tags:`: a tag filter, not a scope restriction. -/
def filterTagsB : Bytes :=
  [105#u8, 102#u8, 95#u8, 106#u8, 111#u8, 98#u8, 115#u8, 58#u8, 102#u8, 105#u8, 108#u8, 116#u8,
   101#u8, 114#u8, 95#u8, 116#u8, 97#u8, 103#u8, 115#u8, 58#u8]

/-- The domain and action fields of a `domain:action[:...]` scope string. -/
def domainOf (s : Bytes) : Bytes := (segments 58#u8 s)[0]!
def actionOf (s : Bytes) : Bytes := (segments 58#u8 s)[1]!

end windmill_kernel.Spec
