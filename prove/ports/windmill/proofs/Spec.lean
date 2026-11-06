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

/-- `s.split(sep)`: the pieces between separators, always at least one. -/
def splitStep (sep : U8) (acc : List Bytes × Bytes) (c : U8) : List Bytes × Bytes :=
  if c = sep then (acc.1 ++ [acc.2], []) else (acc.1, acc.2 ++ [c])

def segments (sep : U8) (s : Bytes) : List Bytes :=
  let r := s.foldl (splitStep sep) ([], [])
  r.1 ++ [r.2]

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

end windmill_kernel.Spec
