import SpecStatements
import SpecResource
import SpecFunctions
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
def DenyEffect : stmts.Effect → Bool
  | .Allow => false
  | .Deny => true
/-- A prefix-key reference selects bucket-only matching for listing actions. -/
noncomputable def StatementResource (f : condfuncs.Functions) (action : acts.Action)
    (bucket object : List U8) : List Nat := by
  classical
  exact nats (RequestResource action bucket object (decide (FunctionsReference f (BytesOfNats (lit "s3:prefix")))))
/-- Bucket policies reject a nonempty all-KMS action set, require a principal
and action match, and apply both resource sets. Empty resource sets impose no
resource restriction; this path does not use the identity-policy resource skips. -/
noncomputable def BucketStatementReaches (st : stmts.BPStatement) (args : stmts.BucketPolicyArgs) : Prop := by
  classical
  exact ¬ (st.actions.val≠[] ∧ ∀ a ∈ st.actions.val, a.family=.Kms) ∧
  PrincipalMatches (st.principal.aws.val.map (fun x=>nats x.val))
    (st.principal.service.val.map (fun x=>nats x.val)) (nats args.account.val) ∧
  StatementActionCoverage (DenyEffect st.effect) st.actions.val st.not_actions.val args.action ∧
  (st.resources.val=[] ∨ ResourceSetHolds none (RequestValueLists args.conditions.val)
    (st.resources.val.map ResourceText) (StatementResource st.conditions args.action args.bucket.val args.object.val)) ∧
  (st.not_resources.val=[] ∨ ¬ResourceSetHolds none (RequestValueLists args.conditions.val)
    (st.not_resources.val.map ResourceText) (StatementResource st.conditions args.action args.bucket.val args.object.val))
/-- Allow returns the conjunction; Deny returns its complement. -/
def EffectAllows (effect : stmts.Effect) (satisfied : Prop) : Prop :=
  match effect with | .Allow => satisfied | .Deny => ¬satisfied
noncomputable def BucketStatementAllowed (st : stmts.BPStatement) (args : stmts.BucketPolicyArgs)
    (ips : List (List U8 × Option condfuncs.IpAddr)) : Prop :=
  EffectAllows st.effect (BucketStatementReaches st args ∧
    FunctionsHold none (RequestValueLists args.conditions.val) ips st.conditions)
end rustfs_kernel.Spec
