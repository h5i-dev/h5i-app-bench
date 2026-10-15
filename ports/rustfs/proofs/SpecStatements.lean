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
