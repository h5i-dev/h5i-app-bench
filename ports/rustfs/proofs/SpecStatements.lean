import SpecKernel
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
/-- Deny uses ordinary glob matching; Allow applies the explicit force-delete rule. -/
def EffectActionMatches (deny : Bool) (pattern requested : acts.Action) : Prop :=
  if deny then globSpec (nats pattern.name.val) (nats requested.name.val) = true
  else ActionGrantMatches pattern requested
/-- Version-read compatibility applies for both effects. -/
def EffectActionSetMatches (deny : Bool) (entries : List acts.Action) (requested : acts.Action) : Prop :=
  ∃ pattern ∈ entries, EffectActionMatches deny pattern requested ∨
    (pattern.family = .S3 ∧ nats pattern.name.val = lit "s3:GetObjectVersion" ∧
     requested.family = .S3 ∧ nats requested.name.val = lit "s3:GetObject")
/-- NotAction exclusion uses Deny matching. With an empty positive set,
Allow still requires an explicit force-delete grant. -/
def StatementActionCoverage (deny : Bool) (actions excluded : List acts.Action)
    (requested : acts.Action) : Prop :=
  ¬ EffectActionSetMatches true excluded requested ∧
    (if actions = [] then deny = true ∨ ¬ IsForceDelete requested
     else EffectActionSetMatches deny actions requested)
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- These three S3 listing actions can select the bucket-only resource. -/
def ListBucketAction (a : acts.Action) : Prop :=
  a.family = .S3 ∧ nats a.name.val ∈
    [lit "s3:ListBucket",lit "s3:ListBucketVersions",lit "s3:ListBucketMultipartUploads"]
/-- The request resource always separates bucket and object with one slash at
this boundary. Existing slashes in the object are retained. Bucket-only
listing and empty objects produce a trailing slash. -/
noncomputable def RequestResource (a : acts.Action) (bucket object : List U8)
    (bucketOnly : Bool) : List U8 := by
  classical
  exact if (ListBucketAction a ∧ bucketOnly=true) ∨ object=[] then bucket++[47#u8]
    else bucket ++ (if object.head?=some 47#u8 then [] else [47#u8]) ++ object
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- The twenty administrative table operations whose resources are checked. -/
def TableResourceNames : List (List Nat) :=
  [[97, 100, 109, 105, 110, 58, 71, 101, 116, 84, 97, 98, 108, 101, 66, 117, 99, 107, 101, 116],
   [97, 100, 109, 105, 110, 58, 83, 101, 116, 84, 97, 98, 108, 101, 66, 117, 99, 107, 101, 116],
   [97, 100, 109, 105, 110, 58, 71, 101, 116, 84, 97, 98, 108, 101, 78, 97, 109, 101, 115, 112, 97, 99, 101],
   [97, 100, 109, 105, 110, 58, 83, 101, 116, 84, 97, 98, 108, 101, 78, 97, 109, 101, 115, 112, 97, 99, 101],
   [97, 100, 109, 105, 110, 58, 85, 112, 100, 97, 116, 101, 84, 97, 98, 108, 101, 78, 97, 109, 101, 115, 112, 97, 99, 101, 80, 114, 111, 112, 101, 114, 116, 105, 101, 115],
   [97, 100, 109, 105, 110, 58, 68, 101, 108, 101, 116, 101, 84, 97, 98, 108, 101, 78, 97, 109, 101, 115, 112, 97, 99, 101],
   [97, 100, 109, 105, 110, 58, 71, 101, 116, 84, 97, 98, 108, 101],
   [97, 100, 109, 105, 110, 58, 83, 101, 116, 84, 97, 98, 108, 101],
   [97, 100, 109, 105, 110, 58, 67, 114, 101, 97, 116, 101, 84, 97, 98, 108, 101],
   [97, 100, 109, 105, 110, 58, 82, 101, 103, 105, 115, 116, 101, 114, 84, 97, 98, 108, 101],
   [97, 100, 109, 105, 110, 58, 67, 111, 109, 109, 105, 116, 84, 97, 98, 108, 101],
   [97, 100, 109, 105, 110, 58, 68, 101, 108, 101, 116, 101, 84, 97, 98, 108, 101],
   [97, 100, 109, 105, 110, 58, 71, 101, 116, 84, 97, 98, 108, 101, 76, 105, 102, 101, 99, 121, 99, 108, 101],
   [97, 100, 109, 105, 110, 58, 83, 101, 116, 84, 97, 98, 108, 101, 76, 105, 102, 101, 99, 121, 99, 108, 101],
   [97, 100, 109, 105, 110, 58, 71, 101, 116, 84, 97, 98, 108, 101, 67, 114, 101, 100, 101, 110, 116, 105, 97, 108, 115],
   [97, 100, 109, 105, 110, 58, 82, 117, 110, 84, 97, 98, 108, 101, 77, 97, 105, 110, 116, 101, 110, 97, 110, 99, 101],
   [97, 100, 109, 105, 110, 58, 71, 101, 116, 84, 97, 98, 108, 101, 77, 101, 116, 97, 100, 97, 116, 97, 76, 111, 99, 97, 116, 105, 111, 110],
   [97, 100, 109, 105, 110, 58, 83, 101, 116, 84, 97, 98, 108, 101, 77, 101, 116, 97, 100, 97, 116, 97, 76, 111, 99, 97, 116, 105, 111, 110],
   [97, 100, 109, 105, 110, 58, 71, 101, 116, 84, 97, 98, 108, 101, 77, 101, 116, 97, 100, 97, 116, 97],
   [97, 100, 109, 105, 110, 58, 83, 101, 116, 84, 97, 98, 108, 101, 77, 101, 116, 97, 100, 97, 116, 97]]
def TableResourceAction (a : acts.Action) : Prop :=
  a.family=.Admin ∧ nats a.name.val ∈ TableResourceNames
/-- STS actions bypass resource matching. Administrative action sets also
bypass it unless the request is one of the administrative table operations. -/
def SkipResourceMatch (actions : List acts.Action) (requested : acts.Action) : Prop :=
  (∃ a ∈ actions, a.family=.Sts) ∨
    ((∃ a ∈ actions, a.family=.Admin) ∧ ¬ TableResourceAction requested)
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- Principal wildcard matching. At the end of the input, a question mark
succeeds immediately, including when more pattern bytes follow it. -/
def simpleGlobSpec : List Nat → List Nat → Bool
  | [], n => n = []
  | 42 :: p, n => simpleGlobSpec p n || match n with
    | [] => false
    | _ :: n' => simpleGlobSpec (42 :: p) n'
  | 63 :: p, n => match n with
    | [] => true
    | _ :: n' => simpleGlobSpec p n'
  | c :: p, n => match n with
    | [] => false
    | x :: n' => c = x && simpleGlobSpec p n'
termination_by p n => p.length + n.length
end rustfs_kernel.Spec
namespace rustfs_kernel.Spec
/-- AWS and service principal patterns share the same account-name matcher. -/
def PrincipalMatches (aws service : List (List Nat)) (account : List Nat) : Prop :=
  ∃ pattern ∈ aws ++ service, simpleGlobSpec pattern account = true
/-- The resource variant is data; only KMS entries survive this filter. -/
def KmsTag : rsrc.Resource → Bool
  | .S3 _ => false
  | .Kms _ => true
def KmsResources (resources : List rsrc.Resource) : List rsrc.Resource :=
  resources.filter KmsTag
end rustfs_kernel.Spec
