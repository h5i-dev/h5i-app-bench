import SpacedriveKernel
import H5iAppLib
/-!
# Spacedrive archive-extraction landing: the policy, over lists

From spacedriveapp/spacedrive @ 2c4da34, `core/src/ops/files/archive/directory.rs`
`ArchiveEntry::landing`. Byte strings are `List Nat`; the kernel's functions are
not called here.
-/
open Aeneas Aeneas.Std spacedrive_kernel

namespace spacedrive_kernel.Spec

/-- A byte string as numbers. -/
def nats (v : List Std.U8) : List Nat := v.map (·.val)

/-- `.` -/
def dot : List Nat := [46]
/-- `..` -/
def dotdot : List Nat := [46, 46]

/-- A path segment that cannot stay put, climb to the parent, or hide a NUL
a join could reinterpret: non-empty, not `.`, not `..`, no NUL byte. These are
exactly the four guards `components` applies before it keeps a segment. -/
def SafeSeg (s : List Nat) : Prop :=
  s ≠ [] ∧ s ≠ dot ∧ s ≠ dotdot ∧ 0 ∉ s

end spacedrive_kernel.Spec
