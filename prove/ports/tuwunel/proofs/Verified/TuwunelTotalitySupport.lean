import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace tuwunel_kernel.Verified.TuwunelTransitionTotal
set_option allowUnsafeReducibility true
attribute [local reducible] Aeneas.Std.WP.Post
set_option maxHeartbeats 2000000
set_option linter.unusedSimpArgs false
set_option maxRecDepth 4096
set_option linter.unusedVariables false

class Indexed (α : Type) where
  valid : Nat → α → Prop
instance (priority := low) (α : Type) : Indexed α := ⟨fun _ _ => True⟩
instance : Indexed Usize := ⟨fun n i => i.val < n⟩
instance [Indexed α] [Indexed β] : Indexed (α × β) :=
  ⟨fun n p => Indexed.valid n p.1 ∧ Indexed.valid n p.2⟩
instance [Indexed α] : Indexed (alloc.vec.Vec α) :=
  ⟨fun n v => ∀ x ∈ v.val, Indexed.valid n x⟩
instance [Indexed α] : Indexed (Slice α) :=
  ⟨fun n v => ∀ x ∈ v.val, Indexed.valid n x⟩
instance [Indexed α] : Indexed (Option α) :=
  ⟨fun n o => ∀ x, o = some x → Indexed.valid n x⟩
instance [Indexed α] : Indexed (core.result.Result α ε) :=
  ⟨fun n r => ∀ x, r = .Ok x → Indexed.valid n x⟩
abbrev Good [Indexed α] (n : Nat) (x : α) := Indexed.valid n x

@[simp] theorem deref_val (v : alloc.vec.Vec α) :
    (alloc.vec.Vec.deref v).val = v.val := by simp [alloc.vec.Vec.deref]

open Lean Elab Tactic Meta in
elab "copy_good" : tactic => withMainContext do
  let decls ← getLCtx
  for d in decls do
    if d.isImplementationDetail then continue
    if d.type.isAppOfArity ``Good 4 then
      evalTactic (← `(tactic| (
        have h_good := $(mkIdent d.userName):ident
        dsimp only [Good, Indexed.valid] at h_good)))

macro "clean" : tactic => `(tactic| (
  copy_good
  try dsimp only [Good, Indexed.valid] at *
  all_goals (simp_all -failIfUnchanged [Good, Indexed.valid, List.mem_append, List.mem_singleton, api_context.LIMIT_MAX, api_context.LIMIT_DEFAULT, api_room.LIMIT_MAX, COUNT_MAX])
  all_goals try scalar_tac
  all_goals try grind))
open Lean Elab Tactic Meta in
elab "split_pair" : tactic => withMainContext do
  for d in ← getLCtx do
    if d.isImplementationDetail then continue
    if (← whnf d.type).isAppOfArity ``Prod 2 then
      evalTactic (← `(tactic| cases $(mkIdent d.userName):ident))
      return
  throwError "no pair"

open Lean Elab Tactic Meta in
elab "step_bounded" : tactic => withMainContext do
  let ds ← getLCtx
  for d in ds do
    if d.isImplementationDetail then continue
    if d.type.isConstOf ``Snapshot then
      evalTactic (← `(tactic| first
        | step with api_threads.truncate_total ($(mkIdent d.userName):ident).pdus.length
        | step with api_room.reversed_total ($(mkIdent d.userName):ident).pdus.length))
      return
  throwError "no snapshot"

macro "run" : tactic => `(tactic| (
  try simp only [core.num.I64.saturating_add, core.num.I64.saturating_sub, lift]
  repeat' (first | step_bounded | step | (dsimp only) | (simp only [bind_tc_ok, bind_ok, WP.spec_ok, Bool.false_eq_true, Bool.true_eq_false, ↓reduceIte, ↓reduceDIte]) | (simp only [bind_tc_ite, bind_ite]) | split | split_pair | (simp_all [Good, Indexed.valid, api_context.LIMIT_MAX, api_context.LIMIT_DEFAULT, api_room.LIMIT_MAX, COUNT_MAX]) | (solve | clean))
  all_goals clean))


end tuwunel_kernel.Verified.TuwunelTransitionTotal
