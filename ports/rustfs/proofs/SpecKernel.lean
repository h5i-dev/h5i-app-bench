import Spec
/-!
# rustfs policy engine: specs for the ported kernel beyond evaluation

Reference definitions for the kernel modules added by the full port of
`crates/policy/src/policy/` (built-in policies, validation, condition data, ...).
-/
open Aeneas Aeneas.Std rustfs_kernel

namespace rustfs_kernel.Spec

/-- The actions the built-in `readonly` policy names (`policy.rs` `DEFAULT_POLICIES`). -/
def readonlyNames : List (List Nat) :=
  [lit "s3:GetBucketLocation", lit "s3:GetObject", lit "s3:GetBucketQuota", lit "sts:AssumeRole"]

end rustfs_kernel.Spec
