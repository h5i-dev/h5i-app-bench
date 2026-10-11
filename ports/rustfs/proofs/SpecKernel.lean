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

/-- The actions the built-in `writeonly` policy names (`policy.rs` `DEFAULT_POLICIES`). -/
def writeonlyNames : List (List Nat) :=
  [lit "s3:PutObject", lit "sts:AssumeRole"]

/-- The actions the built-in `diagnostics` policy names (`policy.rs` `DEFAULT_POLICIES`). -/
def diagnosticsNames : List (List Nat) :=
  [lit "admin:Profiling", lit "admin:ServerTrace", lit "admin:ConsoleLog", lit "admin:ServerInfo", lit "admin:TopLocksInfo", lit "admin:OBDInfo", lit "admin:Prometheus", lit "admin:BandwidthMonitor", lit "sts:AssumeRole"]

/-- The actions the built-in `KMSKeyAdministrator` policy names (`policy.rs` `DEFAULT_POLICIES`). -/
def kmsAdministratorNames : List (List Nat) :=
  [lit "kms:DescribeKey", lit "kms:ListKeys", lit "kms:EnableKey", lit "kms:DisableKey", lit "kms:RotateKey", lit "kms:DeleteKey", lit "sts:AssumeRole"]

/-- The actions the built-in `KMSKeyUser` policy names (`policy.rs` `DEFAULT_POLICIES`). -/
def kmsUserNames : List (List Nat) :=
  [lit "kms:GenerateDataKey", lit "kms:Decrypt", lit "kms:DescribeKey", lit "sts:AssumeRole"]

/-- The actions the built-in `KMSAuditor` policy names (`policy.rs` `DEFAULT_POLICIES`). -/
def kmsAuditorNames : List (List Nat) :=
  [lit "kms:DescribeKey", lit "kms:ListKeys", lit "sts:AssumeRole"]

/-- The built-in policies that name their actions exactly (no wildcard), each
with the actions it names. `readwrite` and `consoleAdmin` grant `s3:*`,
`admin:*` and `kms:*` and are not listed. -/
def builtinOnly : List (List Nat × List (List Nat)) :=
  [(lit "readonly", readonlyNames), (lit "writeonly", writeonlyNames), (lit "diagnostics", diagnosticsNames), (lit "KMSKeyAdministrator", kmsAdministratorNames), (lit "KMSKeyUser", kmsUserNames), (lit "KMSAuditor", kmsAuditorNames)]

end rustfs_kernel.Spec
