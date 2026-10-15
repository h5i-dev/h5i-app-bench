import SpecCondData

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
/-- SID-independent equality of the semantic statement fields. -/
def MetadataStatementEquivalent (a b : manage.Statement) : Prop :=
  a.effect = b.effect ∧ (∀ x, x ∈ a.actions.val ↔ x ∈ b.actions.val) ∧
  (∀ x, x ∈ a.not_actions.val ↔ x ∈ b.not_actions.val) ∧
  (∀ x, x ∈ a.resources.val ↔ x ∈ b.resources.val) ∧
  (∀ x, x ∈ a.not_resources.val ↔ x ∈ b.not_resources.val) ∧
  ConditionGroupsMatch a.conditions b.conditions
/-- An entry explicitly names the existing-object-tag request key. -/
def InnerUsesExistingTag {T : Type} (f : conddata.InnerFunc T) : Prop :=
  ∃ e ∈ f.entries.val, nats e.key.key_name.val = lit "s3:ExistingObjectTag"
def ConditionUsesExistingTag (c : conddata.Condition) : Prop :=
  match c.data with
  | .Str f => InnerUsesExistingTag f
  | .Addr f => InnerUsesExistingTag f
  | .Boolean f => InnerUsesExistingTag f
  | .Num f => InnerUsesExistingTag f
  | .Date f => InnerUsesExistingTag f
  | .Binary f => InnerUsesExistingTag f
/-- A tag-reading condition survives later replacement by the same operator spelling. -/
def ActiveTagConditions (cs : List conddata.Condition) : Prop :=
  ∃ i, ∃ hi : i < cs.length, ConditionUsesExistingTag cs[i] ∧
    ∀ j, i < j → ∀ hj : j < cs.length, ConditionKeyName cs[i] ≠ ConditionKeyName cs[j]
def FunctionsUseExistingTag (f : conddata.Functions) : Prop :=
  ActiveTagConditions f.for_all_values.val ∨ ActiveTagConditions f.for_any_value.val ∨
    ActiveTagConditions f.for_normal.val
end rustfs_kernel.Spec
