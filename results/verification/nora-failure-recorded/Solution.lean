import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

set_option maxRecDepth 4096
set_option maxHeartbeats 2000000

namespace nora_kernel.Solution

open Lean Elab Tactic Meta in
elab "destruct_products" : tactic => do
  let mut more := true
  while more do
    more ← withMainContext do
      for d in ← getLCtx do
        let t ← whnf d.type
        if t.isAppOfArity ``Prod 2 then
          let gs ← (← getMainGoal).cases d.fvarId
          replaceMainGoal (gs.toList.map (·.mvarId))
          return true
      return false

def NoFailures (ws : alloc.vec.Vec middleware.Write) : Prop :=
  ∀ e, middleware.Write.PutFailures e ∉ ws.val

def BadCredentials (o : middleware.Outcome) : Prop :=
  o = .Deny .InvalidOrExpiredToken ∨ o = .Deny .InvalidUsernameOrPassword

def Safe (r : alloc.vec.Vec middleware.Write × middleware.Outcome) : Prop :=
  ∀ e, middleware.Write.PutFailures e ∈ r.1.val → BadCredentials r.2

theorem push_val {α : Type} {v w : alloc.vec.Vec α} {x : α}
    (h : alloc.vec.Vec.push v x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · simpa using congrArg alloc.vec.Vec.val (result_ok_inj h).symm
  · simp at h

theorem noFailures_new : NoFailures (alloc.vec.Vec.new middleware.Write) := by
  simp [NoFailures]

theorem noFailures_token_push {v w : alloc.vec.Vec middleware.Write}
    (hv : NoFailures v) (tw : tokens.TokenWrite)
    (h : alloc.vec.Vec.push v (.Token tw) = ok w) : NoFailures w := by
  simp only [NoFailures, push_val h, List.mem_append, List.mem_singleton]
  intro e he
  rcases he with he | he
  · exact hv e he
  · cases he

theorem token_writes_noFailures (tw : alloc.vec.Vec tokens.TokenWrite)
    (ws : alloc.vec.Vec middleware.Write) (h : middleware.token_writes tw = ok ws) :
    NoFailures ws := by
  unfold middleware.token_writes middleware.token_writes_loop at h
  apply loop_idx_ok (idx := fun x => x.2) (n := tw.val.length)
    (Inv := fun x => NoFailures x.1) (Q := NoFailures) _ _ _ _ _ _ h
  · rintro ⟨out, i⟩ r hout hi hr
    unfold middleware.token_writes_loop.body at hr
    h5i_invert hr
    · simp only
      refine ⟨noFailures_token_push hout _ hout1, ?_, ?_⟩
      all_goals h5i_arith
    · exact hout
  · exact noFailures_new
  · simp

theorem record_success_noFailures (v w : alloc.vec.Vec middleware.Write)
    (ip : Option net.IpAddr) (hv : NoFailures v)
    (h : middleware.record_success v ip = ok w) : NoFailures w := by
  unfold middleware.record_success at h
  h5i_invert h
  · exact hv
  · simp only [NoFailures, push_val h, List.mem_append, List.mem_singleton]
    intro e he
    rcases he with he | he
    · exact hv e he
    · cases he

theorem token_identity_noFailures (v ws : alloc.vec.Vec middleware.Write)
    (ip : Option net.IpAddr) (m : middleware.HttpMethod) (admin : Bool)
    (u : alloc.vec.Vec U8) (role : Role) (o : middleware.Outcome)
    (hv : NoFailures v)
    (h : middleware.token_identity v ip m admin u role = ok (ws, o)) : NoFailures ws := by
  unfold middleware.token_identity at h
  h5i_invert h
  all_goals
    rcases h with ⟨rfl, rfl⟩
    exact record_success_noFailures _ _ _ hv hwrites1

theorem safe_of_noFailures {ws : alloc.vec.Vec middleware.Write} {o : middleware.Outcome}
    (h : NoFailures ws) : Safe (ws, o) := by
  intro e he
  exact False.elim (h e he)

/-- The postcondition of every computation that returns successfully. -/
def Partial {α : Type} (m : Result α) (P : α → Prop) : Prop :=
  ∀ r, m = ok r → P r

theorem partial_ok {α : Type} {x : α} {P : α → Prop} (hx : P x) : Partial (ok x) P := by
  intro r h
  cases result_ok_inj h
  exact hx

theorem partial_bind_any {α β : Type} (m : Result α) (k : α → Result β) (P : β → Prop)
    (hk : ∀ x, Partial (k x) P) : Partial (do let x ← m; k x) P := by
  intro r h
  obtain ⟨x, _, h⟩ := bind_tc_eq_ok.1 h
  exact hk x r h

theorem partial_if {α : Type} (c : Prop) [Decidable c] (a b : Result α) (P : α → Prop)
    (ha : Partial a P) (hb : Partial b P) : Partial (if c then a else b) P := by
  by_cases h : c
  · simpa only [if_pos h] using ha
  · simpa only [if_neg h] using hb

theorem partial_bind_token (tw : alloc.vec.Vec tokens.TokenWrite)
    (k : alloc.vec.Vec middleware.Write → Result (alloc.vec.Vec middleware.Write × middleware.Outcome))
    (hk : ∀ ws, NoFailures ws → Partial (k ws) Safe) :
    Partial (do let ws ← middleware.token_writes tw; k ws) Safe := by
  intro r h
  obtain ⟨ws, hw, h⟩ := bind_tc_eq_ok.1 h
  exact hk ws (token_writes_noFailures _ _ hw) r h

theorem partial_bind_success (v : alloc.vec.Vec middleware.Write) (ip : Option net.IpAddr)
    (k : alloc.vec.Vec middleware.Write → Result (alloc.vec.Vec middleware.Write × middleware.Outcome))
    (hv : NoFailures v) (hk : ∀ ws, NoFailures ws → Partial (k ws) Safe) :
    Partial (do let ws ← middleware.record_success v ip; k ws) Safe := by
  intro r h
  obtain ⟨ws, hw, h⟩ := bind_tc_eq_ok.1 h
  exact hk ws (record_success_noFailures _ _ _ hv hw) r h

theorem partial_token_identity (v : alloc.vec.Vec middleware.Write) (ip : Option net.IpAddr)
    (m : middleware.HttpMethod) (admin : Bool) (u : alloc.vec.Vec U8) (role : Role)
    (hv : NoFailures v) : Partial (middleware.token_identity v ip m admin u role) Safe := by
  rintro ⟨ws, o⟩ h
  exact safe_of_noFailures (token_identity_noFailures _ _ _ _ _ _ _ _ hv h)

open Lean Elab Tactic Meta in
elab "guard_bind" : tactic => withMainContext do
  let t ← instantiateMVars (← getMainTarget)
  unless t.isAppOfArity ``Partial 3 do throwError "not a partial specification"
  let m := t.getAppArgs[1]!.consumeMData
  unless m.isAppOfArity ``Bind.bind 6 || m.isAppOfArity ``Aeneas.Std.bind 4 do
    throwError "not a bind"

open Lean Elab Tactic Meta in
elab "guard_return" : tactic => withMainContext do
  let t ← instantiateMVars (← getMainTarget)
  unless t.isAppOfArity ``Partial 3 do throwError "not a partial specification"
  unless t.getAppArgs[1]!.getAppFn.isConstOf ``Aeneas.Std.Result.ok do
    throwError "not a return"

open Lean Elab Tactic Meta in
elab "guard_if" : tactic => withMainContext do
  let t ← instantiateMVars (← getMainTarget)
  unless t.isAppOfArity ``Partial 3 do throwError "not a partial specification"
  unless t.getAppArgs[1]!.isAppOfArity ``ite 5 do throwError "not an if"

open Lean Elab Tactic Meta in
elab "normalize_partial" : tactic => withMainContext do
  let t ← instantiateMVars (← getMainTarget)
  unless t.isAppOfArity ``Partial 3 do throwError "not a partial specification"
  let args := t.getAppArgs
  let m ← if args[1]!.getAppFn.isConstOf ``Aeneas.Std.uncurry then
      withTransparency .all <| unfoldDefinition args[1]!
    else whnfCore args[1]!
  if m == args[1]! then throwError "already normalized"
  let t' := mkAppN t.getAppFn #[args[0]!, m, args[2]!]
  replaceMainGoal [← (← getMainGoal).change t']

macro "safe_step" : tactic => `(tactic|
  first
    | (guard_return; apply partial_ok; first
        | (apply safe_of_noFailures; first | assumption | exact noFailures_new)
        | (intro e he; exact Or.inl rfl)
        | (intro e he; exact Or.inr rfl))
    | (apply partial_token_identity; first | assumption | exact noFailures_new)
    | (guard_bind; apply partial_bind_token; intro ws hn)
    | (guard_bind; apply partial_bind_success <;>
        first | assumption | exact noFailures_new | intro ws hn)
    | (guard_bind; apply partial_bind_any; intro x; destruct_products)
    | (guard_if; apply partial_if)
    | (fail_if_no_progress destruct_products)
    | normalize_partial
    | split
    | dsimp only)

macro "safe_steps" : tactic => `(tactic| repeat' safe_step)

theorem open_path_safe (cfg : middleware.Config) (cr : oracle.Crypto)
    (req : middleware.Request) : Partial (middleware.open_path cfg cr req) Safe := by
  unfold middleware.open_path
  safe_steps

theorem basic_safe (cfg : middleware.Config) (cr : oracle.Crypto)
    (fs : Slice lockout.FailureEntry) (req : middleware.Request) (auth : Slice U8)
    (ip : Option net.IpAddr) (admin : Bool) :
    Partial (middleware.basic cfg cr fs req auth ip admin) Safe := by
  unfold middleware.basic
  safe_steps

theorem bearer_safe (cfg : middleware.Config) (cr : oracle.Crypto)
    (fs : Slice lockout.FailureEntry) (jw : Option middleware.Jwt)
    (req : middleware.Request) (token : Slice U8) (ip : Option net.IpAddr) (admin : Bool) :
    Partial (middleware.bearer cfg cr fs jw req token ip admin) Safe := by
  unfold middleware.bearer
  safe_steps

theorem failure_recorded_only_for_bad_credentials (cfg : middleware.Config)
    (fs : Slice lockout.FailureEntry) (cr : oracle.Crypto) (jw : Option middleware.Jwt)
    (req : middleware.Request) (ws : alloc.vec.Vec middleware.Write) (o : middleware.Outcome)
    (e : lockout.FailureEntry)
    (h : middleware.auth_middleware cfg fs cr jw req = ok (ws, o)) (hw : .PutFailures e ∈ ws.val) :
    o = .Deny .InvalidOrExpiredToken ∨ o = .Deny .InvalidUsernameOrPassword := by
  have hs : Partial (middleware.auth_middleware cfg fs cr jw req) Safe := by
    unfold middleware.auth_middleware
    repeat' (first
      | exact open_path_safe _ _ _
      | exact basic_safe _ _ _ _ _ _ _
      | exact bearer_safe _ _ _ _ _ _ _ _
      | safe_step)
  exact hs (ws, o) h e hw

end nora_kernel.Solution
