import Verified.MigrationBounds
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
namespace kanidm_kernel.Verified.RecoveredEffectivePermissionCheckTotal
-- Post is a transparent predicate alias; expose it to tactic type checking.
set_option allowUnsafeReducibility true
attribute [local reducible] Aeneas.Std.WP.Post
set_option maxHeartbeats 2000000
set_option maxRecDepth 4096
@[step] theorem migration_migration_entry_attrs_total
  (classes : Slice (alloc.vec.Vec Std.U8))  :
  migration.migration_entry_attrs classes ⦃ r => r.1.val.length ≤ 73 ∧ r.2.val.length ≤ 73 ⦄ := by
  unfold migration.migration_entry_attrs
  total_steps

@[step] theorem modify_acc_modify_migration_attrs_total
  (ident : Identity) (entry : Entry)  :
  modify_acc.modify_migration_attrs ident entry ⦃ r => ModBound 73 r ⦄ := by
  unfold modify_acc.modify_migration_attrs
  bounded_steps

open Lean Elab Tactic Meta in
elab "join_protected_if" : tactic => withMainContext do
  let target ← instantiateMVars (← getMainTarget)
  let args := target.getAppArgs
  unless target.isAppOfArity ``Aeneas.Std.WP.spec 3 do
    throwError "expected a WP"
  let computation := args[1]!.consumeMData
  let ba := computation.getAppArgs
  let m ←
    if computation.isAppOfArity ``Bind.bind 6 then pure ba[4]!
    else if computation.isAppOfArity ``Aeneas.Std.bind 4 then pure ba[2]!
    else throwError "expected a bind"
  let m := m.consumeMData
  unless m.isAppOfArity ``ite 5 do throwError "expected a conditional"
  let mt ← inferType m
  let rt := mt.getAppArgs.back!
  let pair := rt.isAppOfArity ``Prod 2
  let vt := if pair then rt.getAppArgs[0]! else rt
  unless vt.isAppOfArity ``alloc.vec.Vec 1 do throwError "expected vector or vector pair"
  if pair then
    unless ← isDefEq vt rt.getAppArgs[1]! do throwError "expected homogeneous pair"
  let elem := vt.getAppArgs[0]!
  let counter ← IO.mkRef (0 : Nat)
  let baseline ← IO.mkRef (#[] : Array Expr)
  m.forEach fun e => do
    let e := e.consumeMData
    if e.isAppOfArity ``bset.insert 2 || e.isAppOfArity ``migration.ins 2 then
      counter.modify (· + 1)
    if e.isFVar then
      let bases ← baseline.get
      if !bases.contains e then
        let et ← inferType e
        if ← isDefEq et vt then baseline.modify (·.push e)
  let count ← counter.get
  let bases ← baseline.get
  let mut bound := mkNatLit count
  for base in bases do
    let value ← mkAppM ``alloc.vec.Vec.val #[base]
    let len ← mkAppM ``List.length #[value]
    bound ← mkAppM ``Nat.add #[len, bound]
  let bsyntax ← Term.exprToSyntax bound
  let esyntax ← Term.exprToSyntax elem
  if pair then
    evalTactic (← `(tactic|
      apply WP.spec_bind (Pₘ := fun (r : alloc.vec.Vec $esyntax × alloc.vec.Vec $esyntax) =>
        r.1.val.length ≤ $bsyntax ∧ r.2.val.length ≤ $bsyntax)))
  else
    evalTactic (← `(tactic|
      apply WP.spec_bind (Pₘ := fun (r : alloc.vec.Vec $esyntax) => r.val.length ≤ $bsyntax)))
  let gs ← getGoals
  unless gs.length == 2 do throwError "expected two bind obligations"
  setGoals [gs.head!]
  evalTactic (← `(tactic| as_aux_lemma => total_steps))
  unless (← getGoals).isEmpty do throwError "conditional bound did not close"
  setGoals gs.tail!
  evalTactic (← `(tactic| intro joined joined_bound))

macro "protected_steps" : tactic => `(tactic| (
  have hmax := H5iAppLib.usize_max_ge
  repeat' (first
    | join_protected_if
    | step
    | split
    | (simp_all))
  all_goals (try simp_all)
  all_goals (try scalar_tac)))

set_option maxHeartbeats 8000000 in
@[step] theorem modify_acc_modify_protected_entry_attrs_total
  (classes : Slice (alloc.vec.Vec Std.U8))  :
  modify_acc.modify_protected_entry_attrs classes ⦃ r => ModBound 40 r ⦄ := by
  unfold modify_acc.modify_protected_entry_attrs
  protected_steps

@[step] theorem modify_acc_modify_protected_attrs_total
  (ident : Identity) (entry : Entry)  :
  modify_acc.modify_protected_attrs ident entry ⦃ r => ModBound 40 r ⦄ := by
  unfold modify_acc.modify_protected_attrs
  bounded_steps


end kanidm_kernel.Verified.RecoveredEffectivePermissionCheckTotal
