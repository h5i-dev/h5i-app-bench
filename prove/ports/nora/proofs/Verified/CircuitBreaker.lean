import NoraKernel
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel
open Aeneas.Std.WP H5iAppLib
namespace nora_kernel.Verified.CircuitBreaker
set_option maxHeartbeats 600000

/-- Every observable field, with counters and elapsed seconds as unbounded naturals. -/
structure View where
  phase : Nat
  failures : Nat
  failureAge : Option Nat
  inFlight : Bool
  probeAge : Option Nat
  generation : Nat
  deriving DecidableEq

def view (b : circuit_breaker.Breaker) : View :=
  ⟨match b.phase with | .Closed => 0 | .Open => 1 | .HalfOpen => 2,
   b.failures.val, b.failure_age.map (·.val), b.in_flight,
   b.probe_age.map (·.val), b.generation.val⟩
def fresh : View := ⟨0, 0, none, false, none, 0⟩
def stale (b : View) (token : Nat) : Bool := token != 0 && token != b.generation
def grant (b : View) : View :=
  { b with generation := b.generation + 1, inFlight := true, probeAge := some 0 }
def close (b : View) : View :=
  { b with phase := 0, failures := 0, inFlight := false, probeAge := none }
def checkModel (b : View) (enabled : Bool) (reset : Nat) : View × Option Nat :=
  if !enabled then (b, some 0) else
  if b.phase = 0 then (b, some 0) else
  if b.phase = 1 then
    if b.failureAge.getD U64.max ≥ reset then
      let b := grant { b with phase := 2 }
      (b, some b.generation)
    else (b, none)
  else
    let stalled := reset > 0 ∧ b.probeAge.all (· ≥ reset)
    if b.inFlight ∧ ¬stalled then (b, none)
    else let b := grant b; (b, some b.generation)
def successModel (b : View) (enabled : Bool) (token : Nat) : View :=
  if !enabled || stale b token then b else close b
def aliveModel (b : View) (enabled : Bool) (token : Nat) : View :=
  if !enabled || stale b token then b else if b.phase = 2 then close b else b
def failureModel (b : View) (enabled : Bool) (token threshold : Nat) : View :=
  if !enabled || stale b token then b else
  if b.phase = 0 then
    { b with
      failures := b.failures + 1
      failureAge := some 0
      phase := if b.failures + 1 ≥ threshold then 1 else 0 }
  else if b.phase = 2 then
    { b with phase := 1, failureAge := some 0, inFlight := false, probeAge := none }
  else { b with failureAge := some 0 }

@[step] theorem new_spec : circuit_breaker.new ⦃ r => view r = fresh ⦄ := by
  unfold circuit_breaker.new
  h5i_steps
  rfl

@[step] theorem stale_spec (b : circuit_breaker.Breaker) (token : U64) :
    circuit_breaker.is_stale b token ⦃ r => r = stale (view b) token.val ⦄ := by
  unfold circuit_breaker.is_stale
  h5i_steps
  all_goals simp_all [stale, view, UScalar.eq_equiv]
  all_goals apply Bool.eq_iff_iff.mpr
  all_goals simp_all [UScalar.eq_equiv]

@[step] theorem grant_spec (b : circuit_breaker.Breaker)
    (hgen : b.generation.val < U64.max) :
    circuit_breaker.grant_probe b ⦃ r =>
      view r.1 = grant (view b) ∧ r.2.val = b.generation.val + 1 ⦄ := by
  unfold circuit_breaker.grant_probe
  h5i_steps
  all_goals simp_all [view, grant]

theorem check_spec (b : circuit_breaker.Breaker) (enabled : Bool) (reset : U64)
    (hgen : b.generation.val < U64.max) :
    circuit_breaker.check b enabled reset ⦃ r =>
      (view r.1, r.2.map (·.val)) = checkModel (view b) enabled reset.val ⦄ := by
  unfold circuit_breaker.check
  cases hp : b.phase
  all_goals cases hf : b.failure_age
  all_goals cases ht : b.probe_age
  all_goals h5i_steps
  all_goals simp_all [checkModel, view, grant, U64.max, U64.rMax, U64.numBits]

theorem success_spec (b : circuit_breaker.Breaker) (enabled : Bool) (token : U64) :
    circuit_breaker.record_success b enabled token ⦃ r =>
      view r = successModel (view b) enabled token.val ⦄ := by
  unfold circuit_breaker.record_success
  h5i_steps
  all_goals simp_all [successModel, view, close]

theorem alive_spec (b : circuit_breaker.Breaker) (enabled : Bool) (token : U64) :
    circuit_breaker.record_alive b enabled token ⦃ r =>
      view r = aliveModel (view b) enabled token.val ⦄ := by
  unfold circuit_breaker.record_alive
  cases hp : b.phase
  all_goals h5i_steps
  all_goals simp_all [aliveModel, view, close]

theorem failure_spec (b : circuit_breaker.Breaker) (enabled : Bool) (token : U64)
    (threshold : U32) (hcount : b.failures.val < U32.max) :
    circuit_breaker.record_failure b enabled token threshold ⦃ r =>
      view r = failureModel (view b) enabled token.val threshold.val ⦄ := by
  unfold circuit_breaker.record_failure
  cases hp : b.phase
  all_goals h5i_steps
  all_goals simp_all [failureModel, view]

theorem threshold_spec (default : U32) (overrideValue : Option U32) :
    circuit_breaker.threshold default overrideValue ⦃ r =>
      r.val = (overrideValue.map (·.val)).getD default.val ⦄ := by
  unfold circuit_breaker.threshold
  cases overrideValue <;> h5i_steps <;> rfl

theorem reset_spec (default : U64) (overrideValue : Option U64) :
    circuit_breaker.reset_timeout default overrideValue ⦃ r =>
      r.val = (overrideValue.map (·.val)).getD default.val ⦄ := by
  unfold circuit_breaker.reset_timeout
  cases overrideValue <;> h5i_steps <;> rfl
end nora_kernel.Verified.CircuitBreaker
