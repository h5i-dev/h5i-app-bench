import SpecPath
import SpecStringPolicies
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
/-- Resource patterns visit every common key in table order when values are present. -/
def ResourcePattern (values : List (List U8 × List (List U8))) (pattern : List Nat) : List Nat :=
  if values=[] then pattern else nats (SubstituteCommon (BytesOfNats pattern) values)
/-- Both resource tags compare their stored pattern with the whole normalized name.
A normalized single dot is rejected. Literal equality is accepted before glob matching. -/
def ResourcePatternHolds (values : List (List U8 × List (List U8)))
    (pattern requested : List Nat) : Prop :=
  let cp := CleanPath requested
  let resolved := ResourcePattern values pattern
  cp≠[46] ∧ (cp=resolved ∨ globSpec resolved cp=true)
/-- Context expansion supplies alternatives before common-key substitution. -/
def ResourceHolds (ctx : Option AwsValueContext) (values : List (List U8 × List (List U8)))
    (pattern requested : List Nat) : Prop :=
  ∃ alternative ∈ ResolvedPolicy ctx pattern, ResourcePatternHolds values alternative requested
/-- A resource set matches exactly when one stored pattern matches. -/
def ResourceSetHolds (ctx : Option AwsValueContext) (values : List (List U8 × List (List U8)))
    (patterns : List (List Nat)) (requested : List Nat) : Prop :=
  ∃ pattern ∈ patterns, ResourceHolds ctx values pattern requested
/-- The S3 and KMS tags retain the same stored byte-pattern representation. -/
def ResourceText : rsrc.Resource → List Nat
  | .S3 text => nats text.val
  | .Kms text => nats text.val
end rustfs_kernel.Spec
