import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Solution

/-- Partial correctness, without requiring unrelated helpers to be total. -/
def Partial {α : Type} (m : Result α) (P : α → Prop) : Prop :=
  ∀ x, m = ok x → P x

theorem partial_bind {α β : Type} (m : Result α) (f : α → Result β)
    (P : β → Prop) (h : ∀ x, Partial (f x) P) : Partial (m >>= f) P := by
  intro y hy
  obtain ⟨x, _, hx⟩ := bind_tc_eq_ok.mp hy
  exact h x y hx

theorem partial_bind_facts {α β : Type} (m : Result α) (f : α → Result β)
    (Q : α → Prop) (P : β → Prop) (hm : Partial m Q)
    (h : ∀ x, Q x → Partial (f x) P) : Partial (m >>= f) P := by
  intro y hy
  obtain ⟨x, hx, hf⟩ := bind_tc_eq_ok.mp hy
  exact h x (hm x hx) y hf

theorem partial_ok {α : Type} (x : α) (P : α → Prop) (h : P x) :
    Partial (ok x) P := by
  intro y hy
  have := result_ok_inj hy
  subst y
  exact h

theorem partial_ite {α : Type} (c : Prop) [Decidable c]
    (a b : Result α) (P : α → Prop) (ha : Partial a P) (hb : Partial b P) :
    Partial (if c then a else b) P := by
  by_cases hc : c
  · simpa only [if_pos hc] using ha
  · simpa only [if_neg hc] using hb

open Lean Elab Tactic Meta in
elab "pc_if" : tactic => withMainContext do
  let t ← instantiateMVars (← getMainTarget)
  unless t.isAppOfArity ``Partial 3 do throwError "expected Partial"
  let m ← withTransparency .reducible <| whnf t.getAppArgs[1]!
  unless m.isAppOf ``ite do throwError "expected if"
  evalTactic (← `(tactic| apply partial_ite))

open Lean Elab Tactic Meta in
elab "pc_bind" : tactic => withMainContext do
  let t ← instantiateMVars (← getMainTarget)
  unless t.isAppOfArity ``Partial 3 do throwError "expected Partial"
  let m ← withTransparency .reducible <| whnf t.getAppArgs[1]!
  unless m.isAppOf ``Bind.bind || m.isAppOf ``Aeneas.Std.bind do
    throwError "expected bind"
  evalTactic (← `(tactic| apply partial_bind))
  let t ← instantiateMVars (← getMainTarget)
  if let .forallE _ ty _ _ := t then
    if ty.isAppOf ``Prod then
      evalTactic (← `(tactic| rintro ⟨_, _⟩))
    else evalTactic (← `(tactic| intro))
  else throwError "expected binder"

open Lean Elab Tactic Meta in
elab "pc_reduce" : tactic => withMainContext do
  let t ← instantiateMVars (← getMainTarget)
  evalTactic (← `(tactic| dsimp only [Aeneas.Std.uncurry]))
  let t' ← instantiateMVars (← getMainTarget)
  if t == t' then throwError "already reduced"

def GoodOutcome (o : middleware.Outcome) : Prop :=
  Passes o ∨ o = .Deny .ReadOnlyToken ∨ o = .Deny .ReadOnlyOidc ∨ o = .Deny .AdminRequired

def NoClear (ws : alloc.vec.Vec middleware.Write) : Prop :=
  ∀ ip, .ClearFailures ip ∉ ws.val

def Safe (p : alloc.vec.Vec middleware.Write × middleware.Outcome) : Prop :=
  ∀ ip, .ClearFailures ip ∈ p.1.val → GoodOutcome p.2

theorem safe_good (ws : alloc.vec.Vec middleware.Write) (o : middleware.Outcome)
    (h : GoodOutcome o) : Safe (ws, o) := by
  intro _ _
  exact h

theorem safe_no_clear (ws : alloc.vec.Vec middleware.Write) (o : middleware.Outcome)
    (h : NoClear ws) : Safe (ws, o) := by
  intro ip hw
  exact False.elim (h ip hw)

theorem no_clear_new : NoClear (alloc.vec.Vec.new middleware.Write) := by
  simp [NoClear]

theorem push_val {α : Type} (v : alloc.vec.Vec α) (x : α)
    (w : alloc.vec.Vec α) (h : alloc.vec.Vec.push v x = ok w) :
    w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  h5i_invert h
  simp

theorem no_clear_push (v : alloc.vec.Vec middleware.Write) (x : middleware.Write)
    (hv : NoClear v) (hx : ∀ ip, x ≠ .ClearFailures ip) :
    Partial (alloc.vec.Vec.push v x) NoClear := by
  intro w hw ip
  rw [push_val v x w hw]
  simpa using And.intro (hv ip) (Ne.symm (hx ip))

theorem token_writes_no_clear (ws : alloc.vec.Vec tokens.TokenWrite) :
    Partial (middleware.token_writes ws) NoClear := by
  intro out h
  unfold middleware.token_writes middleware.token_writes_loop at h
  refine loop_idx_ok _ (fun s => s.2) ws.val.length
    (fun s => NoClear s.1) NoClear ?_ _ out no_clear_new (by simp) h
  rintro ⟨v, i⟩ r hv hi hr
  unfold middleware.token_writes_loop.body at hr
  h5i_invert hr
  all_goals try exact hv
  all_goals
    have hp := no_clear_push v _ hv (by intro ip; simp) _ hout1
    h5i_arith

-- Preserve the write invariant through the two operations used on failed authentication.
open Lean Elab Tactic Meta in
elab "pc_effect" : tactic => withMainContext do
  let t ← instantiateMVars (← getMainTarget)
  unless t.isAppOfArity ``Partial 3 do throwError "expected Partial"
  let m ← withTransparency .reducible <| whnf t.getAppArgs[1]!
  unless m.isAppOf ``Bind.bind || m.isAppOf ``Aeneas.Std.bind do
    throwError "expected bind"
  let args := m.getAppArgs
  let call := args[args.size - 2]!
  if call.isAppOf ``middleware.token_writes then
    evalTactic (← `(tactic| (
      refine partial_bind_facts _ _ NoClear _ (token_writes_no_clear _) ?_
      intro writes hclean)))
  else if call.isAppOf ``alloc.vec.Vec.push then
    evalTactic (← `(tactic| (
      refine partial_bind_facts _ _ NoClear _ (no_clear_push _ _ ?_ ?_) ?_
      first | assumption | exact no_clear_new
      intro ip; simp
      intro writes hclean)))
  else throwError "no write invariant for this call"

theorem token_identity_safe (writes : alloc.vec.Vec middleware.Write)
    (client_ip : Option net.IpAddr) (method : middleware.HttpMethod)
    (is_admin : Bool) (user : alloc.vec.Vec U8) (role : Role) :
    Partial (middleware.token_identity writes client_ip method is_admin user role) Safe := by
  unfold middleware.token_identity
  repeat' (first
    | (apply partial_ok; apply safe_good; simp [GoodOutcome, Passes])
    | pc_reduce
    | pc_bind
    | split)

theorem open_path_safe (cfg : middleware.Config) (cr : oracle.Crypto)
    (req : middleware.Request) : Partial (middleware.open_path cfg cr req) Safe := by
  unfold middleware.open_path
  repeat' (first
    | (apply partial_ok; apply safe_good; simp [GoodOutcome, Passes])
    | pc_reduce
    | pc_bind
    | split)

macro "pc_safe" : tactic => `(tactic| (
  repeat' (first
    | (solve | apply token_identity_safe)
    | (solve | apply open_path_safe)
    | (solve | (apply partial_ok; apply safe_good; simp [GoodOutcome, Passes]))
    | (solve | (apply partial_ok; apply safe_no_clear; first | assumption | exact no_clear_new))
    | pc_reduce
    | pc_effect
    | pc_bind
    | split
    | cases_type Prod)))

theorem bearer_safe (cfg : middleware.Config) (cr : oracle.Crypto)
    (fs : Slice lockout.FailureEntry) (jw : Option middleware.Jwt)
    (req : middleware.Request) (token : Slice U8) (client_ip : Option net.IpAddr)
    (is_admin : Bool) :
    Partial (middleware.bearer cfg cr fs jw req token client_ip is_admin) Safe := by
  unfold middleware.bearer
  pc_safe

theorem basic_safe (cfg : middleware.Config) (cr : oracle.Crypto)
    (fs : Slice lockout.FailureEntry) (req : middleware.Request)
    (header : Slice U8) (client_ip : Option net.IpAddr) (is_admin : Bool) :
    Partial (middleware.basic cfg cr fs req header client_ip is_admin) Safe := by
  unfold middleware.basic
  pc_safe

set_option maxRecDepth 4096 in
set_option maxHeartbeats 0 in
theorem auth_middleware_safe (cfg : middleware.Config)
    (fs : Slice lockout.FailureEntry) (cr : oracle.Crypto) (jw : Option middleware.Jwt)
    (req : middleware.Request) :
    Partial (middleware.auth_middleware cfg fs cr jw req) Safe := by
  unfold middleware.auth_middleware
  repeat' (first
    | (solve | apply bearer_safe)
    | (solve | apply basic_safe)
    | (solve | apply open_path_safe)
    | (solve | (apply partial_ok; apply safe_good; simp [GoodOutcome, Passes]))
    | (solve | (apply partial_ok; apply safe_no_clear; exact no_clear_new))
    | pc_reduce
    | pc_bind
    | pc_if
    | split
    | cases_type Prod)

theorem failures_cleared_only_for_good_credentials (cfg : middleware.Config)
    (fs : Slice lockout.FailureEntry) (cr : oracle.Crypto) (jw : Option middleware.Jwt)
    (req : middleware.Request) (ws : alloc.vec.Vec middleware.Write) (o : middleware.Outcome)
    (ip : net.IpAddr)
    (h : middleware.auth_middleware cfg fs cr jw req = ok (ws, o)) (hw : .ClearFailures ip ∈ ws.val) :
    Passes o ∨ o = .Deny .ReadOnlyToken ∨ o = .Deny .ReadOnlyOidc ∨ o = .Deny .AdminRequired := by
  exact auth_middleware_safe cfg fs cr jw req (ws, o) h ip hw

end nora_kernel.Solution
