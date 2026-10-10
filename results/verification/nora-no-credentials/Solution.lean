import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Solution

set_option maxHeartbeats 0
set_option maxRecDepth 100000

open Lean Meta Elab Tactic in
elab "reduce_lhs_head " ident:ident : tactic => withMainContext do
  let id ← getFVarId ident
  let decl ← id.getDecl
  let args := decl.type.getAppArgs
  unless decl.type.isAppOfArity ``Eq 3 do throwError "expected equality"
  let lhs ← whnfHeadPred args[1]! (fun e => pure
    (!e.isAppOf ``ite && !e.isAppOf ``dite &&
     !e.isAppOf ``Bind.bind && !e.isAppOf ``Aeneas.Std.bind &&
     !e.isAppOf ``Aeneas.Std.Result.ok))
  let target := mkAppN decl.type.getAppFn #[args[0]!, lhs, args[2]!]
  let goal ← getMainGoal
  replaceMainGoal [← goal.replaceLocalDeclDefEq id target]

open Lean Meta Elab Tactic in
elab "split_lhs_head " ident:ident : tactic => withMainContext do
  let id ← getFVarId ident
  let decl ← id.getDecl
  let some (_, lhs, _) := decl.type.eq? | throwError "expected equality"
  unless lhs.isAppOf ``ite do throwError "expected head conditional"
  let cond := lhs.getAppArgs[1]!
  let hc := (← getLCtx).getUnusedName `head_cond
  let (yes, no) ← (← getMainGoal).byCases cond hc
  let hI := mkIdent ident.getId
  let cI := mkIdent hc
  setGoals [yes.mvarId]
  evalTactic (← `(tactic| rw [if_pos $cI:ident] at $hI:ident))
  let positive ← getGoals
  setGoals [no.mvarId]
  evalTactic (← `(tactic| rw [if_neg $cI:ident] at $hI:ident))
  setGoals (positive ++ (← getGoals))

open Lean Meta Elab Tactic in
elab "peel_lhs_bind " ident:ident : tactic => withMainContext do
  let id ← getFVarId ident
  let decl ← id.getDecl
  let some (_, lhs, _) := decl.type.eq? | throwError "expected equality"
  let lhs := lhs.consumeMData
  let thm ← if lhs.isAppOfArity ``Bind.bind 6 then pure ``H5iAppLib.bind_tc_eq_ok
    else if lhs.isAppOfArity ``Aeneas.Std.bind 4 then pure ``H5iAppLib.bind_eq_ok
    else throwError "expected head bind"
  let lctx ← getLCtx
  let x := mkIdent (lctx.getUnusedName `value)
  let hx := mkIdent (lctx.getUnusedName `hvalue)
  let hI := mkIdent ident.getId
  let thmI := mkIdent thm
  evalTactic (← `(tactic| obtain ⟨$x:ident, $hx:ident, $hI:ident⟩ := ($thmI).1 $hI))
  replaceMainGoal [← (← getMainGoal).clear id]

theorem no_credentials_no_write_role (cfg : middleware.Config) (fs : Slice lockout.FailureEntry)
    (cr : oracle.Crypto) (jw : Option middleware.Jwt) (req : middleware.Request)
    (ws : alloc.vec.Vec middleware.Write) (a : NamespaceAuthority) (u : alloc.vec.Vec U8) (r : Option Role)
    (he : cfg.enabled = true) (hn : req.auth_header = none)
    (h : middleware.auth_middleware cfg fs cr jw req = ok (ws, .Next a u r)) :
    r = none ∨ r = some .Read := by
  unfold middleware.auth_middleware at h
  rw [if_pos he] at h
  simp only [middleware.open_path, hn] at h
  try simp only [hn] at h
  h5i_invert h
  all_goals try cases_type* Prod
  rename_i anon web opened
  all_goals try reduce_lhs_head h
  cases opened
  all_goals simp only [Bool.false_eq_true, ↓reduceIte] at h
  all_goals try simp only [hn] at h
  iterate 100 (
    all_goals try split_lhs_head h
    all_goals try peel_lhs_bind h
    all_goals try cases_type* Prod
    all_goals try reduce_lhs_head h
    all_goals try simp only [hn] at h)
  all_goals try h5i_invert h
  all_goals try simp only [Prod.mk.injEq, middleware.Outcome.Next.injEq, reduceCtorEq] at h
  all_goals first | exact Or.inl rfl | exact Or.inr rfl | tauto

end nora_kernel.Solution
