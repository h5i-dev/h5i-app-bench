import SpecStatements
import SpecResource
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
/-- Backup and restore with an explicit resource set select the Deny effect.
Other KMS requests accept empty filtered sets or an empty object; otherwise
only KMS-tagged patterns are tested against key/ followed by the object. -/
noncomputable def KmsScopeHolds (ctx : Option AwsValueContext) (st : stmts.Statement) (args : stmts.Args) : Prop := by
  classical
  exact if args.action.family=.Kms ∧ nats args.action.name.val ∈ [lit "kms:Backup",lit "kms:Restore"] ∧
      (st.resources.val≠[] ∨ st.not_resources.val≠[]) then st.effect=.Deny
  else (KmsResources st.resources.val=[] ∧ KmsResources st.not_resources.val=[]) ∨ args.object.val=[] ∨
    ((KmsResources st.resources.val=[] ∨ ResourceSetHolds ctx (RequestValueLists args.conditions.val)
      ((KmsResources st.resources.val).map ResourceText) (lit "key/" ++ nats args.object.val)) ∧
      ¬ResourceSetHolds ctx (RequestValueLists args.conditions.val)
        ((KmsResources st.not_resources.val).map ResourceText) (lit "key/" ++ nats args.object.val))
end rustfs_kernel.Spec
