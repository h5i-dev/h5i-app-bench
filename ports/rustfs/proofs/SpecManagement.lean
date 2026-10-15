import SpecKernel

open Aeneas Aeneas.Std rustfs_kernel rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- Validation depends on action/resource fields, independently of metadata and conditions. -/
def MetadataStatementOK (st : manage.Statement) : Prop :=
  StatementOK { effect := st.effect, actions := st.actions, not_actions := st.not_actions, resources := st.resources, not_resources := st.not_resources, conditions := {for_any_value := alloc.vec.Vec.new _, for_all_values := alloc.vec.Vec.new _, for_normal := alloc.vec.Vec.new _} }
def MetadataBPStatementOK (st : manage.BPStatement) : Prop :=
  BPStatementOK { effect := st.effect, principal := st.principal, actions := st.actions, not_actions := st.not_actions, resources := st.resources, not_resources := st.not_resources, conditions := {for_any_value := alloc.vec.Vec.new _, for_all_values := alloc.vec.Vec.new _, for_normal := alloc.vec.Vec.new _} }
def MetadataPolicyOK (p : manage.Policy) : Prop :=
  (p.version.val = [] ∨ nats p.version.val = lit "2012-10-17") ∧
  ∀ st ∈ p.statements.val, MetadataStatementOK st
def MetadataBucketPolicyOK (p : manage.BucketPolicy) : Prop :=
  (p.version.val = [] ∨ nats p.version.val = lit "2012-10-17") ∧
  ∀ st ∈ p.statements.val, MetadataBPStatementOK st
end rustfs_kernel.Spec
