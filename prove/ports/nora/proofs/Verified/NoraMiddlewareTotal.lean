import Verified.NoraMiddlewareSupport
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit
namespace nora_kernel.Verified.NoraMiddlewareTotal
-- Post is a transparent predicate alias; expose it to tactic type checking.
set_option allowUnsafeReducibility true
attribute [local reducible] Aeneas.Std.WP.Post
set_option maxRecDepth 4096
open Lean Elab Tactic Meta in
elab "join_total_bind" : tactic => withMainContext do
  let target ← instantiateMVars (← getMainTarget)
  unless target.isAppOfArity ``Aeneas.Std.WP.spec 3 do throwError "not a specification"
  let m := target.getAppArgs[1]!.consumeMData
  unless m.isAppOfArity ``Bind.bind 6 || m.isAppOfArity ``Aeneas.Std.bind 4 do
    throwError "not a bind"
  evalTactic (← `(tactic| apply Aeneas.Std.WP.spec_bind (Pₘ := fun _ => True)))

theorem total_ite {α : Type} (p : Prop) [Decidable p] (a b : Result α)
    (Q : α → Prop) (ha : p → WP.spec a Q) (hb : ¬p → WP.spec b Q) :
    WP.spec (if p then a else b) Q := by
  by_cases h : p
  · simpa only [if_pos h] using ha h
  · simpa only [if_neg h] using hb h

open Lean Elab Tactic Meta in
elab "total_if" : tactic => withMainContext do
  let target ← instantiateMVars (← getMainTarget)
  unless target.isAppOfArity ``Aeneas.Std.WP.spec 3 do throwError "not a specification"
  unless target.getAppArgs[1]!.consumeMData.isAppOfArity ``ite 5 do
    throwError "not a conditional"
  evalTactic (← `(tactic| (apply total_ite; all_goals intro total_cond)))

open Lean Elab Tactic Meta in
elab "total_head" : tactic => withMainContext do
  let target ← instantiateMVars (← getMainTarget)
  unless target.isAppOfArity ``Aeneas.Std.WP.spec 3 do throwError "not a specification"
  let args := target.getAppArgs
  let computation := args[1]!.consumeMData
  let m ← if computation.getAppFn.isLambda then pure computation.headBeta
    else if computation.isLet then whnfCore computation else do
    unless computation.isAppOfArity ``Aeneas.Std.uncurry 5 do
      throwError "not a tuple continuation"
    unless computation.getAppArgs[4]!.isAppOfArity ``Prod.mk 4 do
      throwError "tuple not yet destructured"
    let some unfolded ← unfoldDefinition? computation (ignoreTransparency := true)
      | throwError "could not unfold tuple continuation"
    whnfCore unfolded
  if m == args[1]! then throwError "head unchanged: {m.getAppFn.constName?}, {m.getAppArgs.size} args; let={m.isLet}"
  let target' := mkAppN target.getAppFn (args.set! 1 m)
  let g ← (← getMainGoal).change target'
  replaceMainGoal [g]

open Lean Elab Tactic Meta in
elab "total_pair" : tactic => withMainContext do
  for d in ← getLCtx do
    if d.isImplementationDetail then continue
    if (← whnf d.type).isAppOfArity ``Prod 2 then
      evalTactic (← `(tactic| cases $(mkIdent d.userName):ident))
      return
  throwError "no pair"

macro "total_tree" : tactic => `(tactic| (
  repeat' (first
    | (solve | step)
    | join_total_bind
    | total_if
    | total_head
    | (intro total_value total_fact)
    | split
    | total_pair
    | (simp_all +failIfUnchanged [alloc.vec.Vec.deref])
    | (solve | scalar_tac))
  all_goals try (apply usize_lt_max; omega)))

set_option maxHeartbeats 12000000 in
theorem middleware_total (cfg : middleware.Config) (fs : Slice lockout.FailureEntry)
    (cr : oracle.Crypto) (jw : Option middleware.Jwt) (req : middleware.Request)
    (hf : ∀ e ∈ fs.val, e.failures.val < U32.max)
    (hpat : ∀ p b, cfg.oidc = some (p, b) → ∀ rule ∈ p.role_rules.val, rule.pattern.length < Usize.max) :
    ∃ y, middleware.auth_middleware cfg fs cr jw req = ok y := by
  apply ok_of (P := fun _ => True)
  unfold middleware.auth_middleware
  by_cases he : cfg.enabled = true
  · rw [if_pos he]
    total_tree
  · rw [if_neg he]
    total_tree

end nora_kernel.Verified.NoraMiddlewareTotal
