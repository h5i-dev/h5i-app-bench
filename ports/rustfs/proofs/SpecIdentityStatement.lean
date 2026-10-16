import SpecBucketStatement
import SpecKmsStatement
import SpecStatementContext
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
/-- Identity statements first require action coverage. A positive KMS action
selects KMS key scoping. Other actions require a resource entry unless a
positive Admin or STS action is present. STS skips resource matching; Admin
skips it except for requests naming a table-scoped Admin operation. -/
noncomputable def StatementReaches (ctx : Option AwsValueContext) (st : stmts.Statement) (args : stmts.Args) : Prop :=
  StatementActionCoverage (DenyEffect st.effect) st.actions.val st.not_actions.val args.action ∧
  ((∃ a ∈ st.actions.val, a.family=.Kms) ∧ KmsScopeHolds ctx st args ∨
   (¬∃ a ∈ st.actions.val, a.family=.Kms) ∧
    (st.resources.val≠[] ∨ st.not_resources.val≠[] ∨
      (∃ a ∈ st.actions.val, a.family=.Admin) ∨ (∃ a ∈ st.actions.val, a.family=.Sts)) ∧
    (SkipResourceMatch st.actions.val args.action ∨
      ((st.resources.val=[] ∨ ResourceSetHolds ctx (RequestValueLists args.conditions.val)
        (st.resources.val.map ResourceText) (StatementResource st.conditions args.action args.bucket.val args.object.val)) ∧
       (st.not_resources.val=[] ∨ ¬ResourceSetHolds ctx (RequestValueLists args.conditions.val)
        (st.not_resources.val.map ResourceText) (StatementResource st.conditions args.action args.bucket.val args.object.val)))))
/-- Identity Allow returns matching and condition satisfaction; Deny returns
their complement. The resolver's data is fixed by the request and environment. -/
noncomputable def StatementAllowed (st : stmts.Statement) (args : stmts.Args) (env : condfuncs.Env) : Prop :=
  EffectAllows st.effect (StatementReaches (some (PolicyContext args env)) st args ∧
    FunctionsHold (some (PolicyContext args env)) (RequestValueLists args.conditions.val)
      (env.ips.val.map (fun e=>(e.1.val,e.2))) st.conditions)

end rustfs_kernel.Spec
