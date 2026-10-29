import Verified.TuwunelTotalityRoutes
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
namespace tuwunel_kernel.Verified.TuwunelTransitionTotal
set_option maxHeartbeats 4000000
set_option maxRecDepth 4096
set_option linter.unusedSimpArgs false
set_option linter.unusedVariables false
set_option allowUnsafeReducibility true
attribute [local reducible] Aeneas.Std.WP.Post

open Lean Elab Tactic Meta in
elab "step_composed_bound" : tactic => withMainContext do
  let target ← instantiateMVars (← getMainTarget)
  unless target.isAppOfArity ``Aeneas.Std.WP.spec 3 do throwError "not a specification"
  let computation := target.getAppArgs[1]!.consumeMData
  let args := computation.getAppArgs
  let head := if computation.isAppOfArity ``Bind.bind 6 then args[4]!
    else if computation.isAppOfArity ``Aeneas.Std.bind 4 then args[2]!
    else computation
  unless head.getAppFn.isConstOf ``tuwunel_kernel.api_threads.truncate ||
      head.getAppFn.isConstOf ``tuwunel_kernel.api_room.reversed do
    throwError "not a bounded index operation"
  evalTactic (← `(tactic| step_route_bound))

-- Optional pagination tokens carry no array index invariant. Join their
-- branches before checking the continuation, to avoid duplicating route proofs.
open Lean Elab Tactic Meta in
elab "join_route_token" : tactic => withMainContext do
  let target ← instantiateMVars (← getMainTarget)
  unless target.isAppOfArity ``Aeneas.Std.WP.spec 3 do throwError "not a specification"
  let computation := target.getAppArgs[1]!.consumeMData
  let args := computation.getAppArgs
  let producer ← if computation.isAppOfArity ``Bind.bind 6 then pure args[4]!
    else if computation.isAppOfArity ``Aeneas.Std.bind 4 then pure args[2]!
    else throwError "not a bind"
  let mt ← inferType producer
  let rt := mt.getAppArgs.back!
  let scalar := if rt.isAppOfArity ``Option 1 then rt.getAppArgs[0]! else rt
  unless scalar.isConstOf ``Aeneas.Std.I64 ||
      (rt.isAppOfArity ``Option 1 && scalar.isConstOf ``Aeneas.Std.U64) do
    throwError "not a pagination scalar"
  evalTactic (← `(tactic| apply WP.spec_bind (Pₘ := fun _ => True)))

open Lean Elab Tactic Meta in
elab "route_head" : tactic => withMainContext do
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
elab "route_pure_head" : tactic => withMainContext do
  let target ← instantiateMVars (← getMainTarget)
  unless target.isAppOfArity ``Aeneas.Std.WP.spec 3 do throwError "not a specification"
  let computation := target.getAppArgs[1]!.consumeMData
  let args := computation.getAppArgs
  if computation.isAppOfArity ``Bind.bind 6 || computation.isAppOfArity ``Aeneas.Std.bind 4 then
    let producer := if computation.isAppOfArity ``Bind.bind 6 then args[4]! else args[2]!
    unless producer.getAppFn.isConstOf ``Aeneas.Std.Result.ok do throwError "not a pure bind"
    evalTactic (← `(tactic| first | rw [bind_tc_ok] | rw [bind_ok]))
  else
    unless computation.getAppFn.isConstOf ``Aeneas.Std.lift do throwError "not a lift"
    evalTactic (← `(tactic| simp only [core.num.I64.saturating_add, core.num.I64.saturating_sub, lift, WP.spec_ok]))

open Lean Elab Tactic Meta in
elab "clean_route_fact" : tactic => withMainContext do
  let target ← instantiateMVars (← getMainTarget)
  if target.isAppOfArity ``Aeneas.Std.WP.spec 3 then throwError "computation still pending"
  evalTactic (← `(tactic| (simp_all [Good, Indexed.valid, alloc.vec.Vec.deref]; try solve_by_elim (maxDepth := 4); try scalar_tac; try grind)))

macro "run_composed_routes" : tactic => `(tactic| (
  repeat' (first
    | join_route_token
    | step_composed_bound
    | step
    | route_pure_head
    | route_head
    | (intro route_value route_fact)
    | (simp only [WP.spec_ok, Bool.false_eq_true, Bool.true_eq_false, ↓reduceIte, ↓reduceDIte])
    | split
    | split_pair
    | (solve | clean_route_fact))
  all_goals try clean_route_fact))


end tuwunel_kernel.Verified.TuwunelTransitionTotal
