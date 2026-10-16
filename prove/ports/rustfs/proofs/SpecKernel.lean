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

/-! ## Validation (`valids`): `policy/{statement,resource,principal}.rs` `is_valid` -/

/-- A KMS resource pattern `Resource::is_valid` accepts: `*`, `key/<id>` with
no further `/`, or `alias/<name>`; neither may contain a backslash. -/
def kmsResourceOK (p : List Nat) : Prop :=
  p = lit "*" ∨
  (lit "key/" <+: p ∧ 4 < p.length ∧ 47 ∉ p.drop 4 ∧ 92 ∉ p) ∨
  (lit "alias/" <+: p ∧ 6 < p.length ∧ 92 ∉ p)

/-- `Resource::is_valid`: an S3 pattern is nonempty and does not start with
`/`; a KMS pattern is `kmsResourceOK`. -/
def resourceOK : rsrc.Resource → Prop
  | .S3 p => p.val ≠ [] ∧ (nats p.val).head? ≠ some 47
  | .Kms p => kmsResourceOK (nats p.val)

def isKmsResource : rsrc.Resource → Prop
  | .S3 _ => False
  | .Kms _ => True

/-- The actions all belong to family `f` (entries of no family aside), and at
least one does. -/
def UniformFamily (l : List acts.Action) (f : acts.Family) : Prop :=
  f ≠ .None ∧ (∃ a ∈ l, a.family = f) ∧ ∀ a ∈ l, a.family = f ∨ a.family = .None

/-- A statement selects exactly one action list; positive actions have one
family, empty resource selections require Admin/Sts/Kms actions, and KMS
resources require positive KMS actions. Every selected resource is valid. -/
def StatementOK (st : stmts.Statement) : Prop :=
  (st.actions.val ≠ [] ↔ st.not_actions.val = []) ∧
  (st.not_actions.val = [] → ∃ f, UniformFamily st.actions.val f) ∧
  (st.resources.val = [] → st.not_resources.val = [] →
    ∃ f, (f = .Admin ∨ f = .Sts ∨ f = .Kms) ∧ UniformFamily st.actions.val f ∧ st.not_actions.val = []) ∧
  (st.resources.val = [] ∨ st.not_resources.val = []) ∧
  ((∃ r ∈ st.resources.val ++ st.not_resources.val, isKmsResource r) →
    UniformFamily st.actions.val .Kms ∧ st.not_actions.val = []) ∧
  (∀ r ∈ st.resources.val ++ st.not_resources.val, resourceOK r)

/-- What `BPStatement::is_valid` accepts. -/
def BPStatementOK (st : stmts.BPStatement) : Prop :=
  (st.principal.aws.val ≠ [] ∨ st.principal.service.val ≠ []) ∧
  (st.actions.val ≠ [] ↔ st.not_actions.val = []) ∧
  (∀ a ∈ st.actions.val ++ st.not_actions.val, a.family ≠ .Kms) ∧
  (∀ r ∈ st.resources.val ++ st.not_resources.val, ¬ isKmsResource r) ∧
  (st.resources.val ≠ [] ↔ st.not_resources.val = []) ∧
  (∀ r ∈ st.resources.val ++ st.not_resources.val, resourceOK r)

/-- Positive action matching combines wildcard names with the explicit-grant
requirement for the two force-delete actions. -/
def ActionGrantMatches (pattern requested : acts.Action) : Prop :=
  globSpec (nats pattern.name.val) (nats requested.name.val) = true ∧
  ¬ (pattern.family = .S3 ∧ nats pattern.name.val = lit "s3:*" ∧ IsForceDelete requested)

/-- A set grants an action through a matching entry or the version-read
compatibility rule. -/
def ActionSetGrantMatches (entries : List acts.Action) (requested : acts.Action) : Prop :=
  ∃ pattern ∈ entries, ActionGrantMatches pattern requested ∨
    (pattern.family = .S3 ∧ nats pattern.name.val = lit "s3:GetObjectVersion" ∧
     requested.family = .S3 ∧ nats requested.name.val = lit "s3:GetObject")

end rustfs_kernel.Spec
