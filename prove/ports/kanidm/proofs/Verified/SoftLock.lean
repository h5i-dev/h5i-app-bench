import KanidmKernel
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel
open H5iAppLib

namespace kanidm_kernel.Verified.SoftLock

private theorem add_ok_val {ty} (a b out : UScalar ty) (h : a + b = ok out) :
    out.val = a.val + b.val := by
  have hh := UScalar.add_equiv a b
  rw [h] at hh
  exact hh.2.1

def later (a b : softlock.Time) : Prop :=
  a.secs > b.secs ∨ (a.secs = b.secs ∧ a.nanos > b.nanos)
instance (a b : softlock.Time) : Decidable (later a b) := inferInstanceAs (Decidable (_ ∨ _))
def equalTime (a b : softlock.Time) : Prop := a.secs = b.secs ∧ a.nanos = b.nanos
instance (a b : softlock.Time) : Decidable (equalTime a b) := inferInstanceAs (Decidable (_ ∧ _))

/-- Exact lexicographic Duration ordering, including subsecond precision. -/
theorem after_spec (a b : softlock.Time) :
    softlock.after a b = ok (decide (later a b)) := by
  unfold softlock.after later
  split <;> simp_all
  split <;> simp_all

theorem same_time_spec (a b : softlock.Time) :
    softlock.same_time a b = ok (decide (equalTime a b)) := by
  unfold softlock.same_time equalTime
  split <;> simp_all

/-- An independent pure transition: expiry caps the reset only on its first observation,
reset takes priority over unlock, and both deadlines use strict comparisons. -/
def timeStep (lock : softlock.SoftLock) (ct : softlock.Time) (expiry : Option softlock.Time) : softlock.SoftLock :=
  match lock.state with
  | .Init => lock
  | .Unlocked count reset => if later ct reset then {lock with state := .Init} else lock
  | .Locked count reset unlock =>
    let changed : Bool := match expiry with
      | none => false
      | some e => !decide (equalTime lock.last_expire_at e)
    let last := if changed = true then expiry.getD lock.last_expire_at else lock.last_expire_at
    let reset' := if changed = true ∧ later reset last then last else reset
    let state := if later ct reset' then softlock.State.Init
      else if later ct unlock then .Unlocked count reset' else .Locked count reset' unlock
    {lock with state := state, last_expire_at := last}

/-- Complete transition result, with no precondition on the state or timestamp. -/
theorem apply_time_step_spec (lock : softlock.SoftLock) (ct : softlock.Time) (expiry : Option softlock.Time) :
    softlock.apply_time_step lock ct expiry = ok (timeStep lock ct expiry) := by
  cases hs : lock.state with
  | Init => simp [softlock.apply_time_step, timeStep, hs]
  | Unlocked count reset =>
    simp [softlock.apply_time_step, timeStep, hs, after_spec]
    split <;> rfl
  | Locked count reset unlock =>
    cases expiry with
    | none =>
      simp [softlock.apply_time_step, timeStep, hs, after_spec]
      split <;> (first | rfl | (split <;> rfl))
    | some e =>
      by_cases he : equalTime lock.last_expire_at e <;>
        by_cases hr : later reset e <;>
        simp [softlock.apply_time_step, timeStep, hs, after_spec, same_time_spec, he, hr] <;>
        split <;> (first | rfl | (split <;> rfl))

/-- Exactly the Locked constructor blocks authentication. -/
theorem is_valid_spec (lock : softlock.SoftLock) :
    softlock.is_valid lock = ok (match lock.state with | .Locked .. => false | _ => true) := by
  cases hs : lock.state <;> simp [softlock.is_valid, hs]

theorem new_spec (policy : softlock.Policy) :
    softlock.new policy = ok {state := .Init, policy := policy, last_expire_at := {secs := 0#u64, nanos := 0#u32}} := rfl

/-- The unrestricted credential policy never introduces a soft lock. -/
theorem unrestricted_failure (count : Usize) (ct : softlock.Time) :
    softlock.failure_next_state .Unrestricted count ct = ok .Init := rfl

/-- At 100 password failures, the next permitted attempt is the daily reset,
including the original failure counter. Arithmetic is checked by the extracted Rust. -/
theorem password_lockout (count : Usize) (ct : softlock.Time) (s : softlock.State)
    (hc : 100 ≤ count.val)
    (h : softlock.failure_next_state .Password count ct = ok s) :
    ∃ reset, s = .Locked count reset reset ∧ reset.nanos = 0#u32 := by
  unfold softlock.failure_next_state at h
  h5i_invert h <;> (first | scalar_tac | exact ⟨_, rfl, rfl⟩)

/-- TOTP exhausts its three attempts exactly at the window reset deadline. -/
theorem totp_lockout (step : U64) (count : Usize) (ct : softlock.Time) (s : softlock.State)
    (hc : 3 ≤ count.val)
    (h : softlock.failure_next_state (.Totp step) count ct = ok s) :
    ∃ reset, s = .Locked count reset reset ∧ reset.nanos = 0#u32 := by
  unfold softlock.failure_next_state at h
  h5i_invert h <;> (first | scalar_tac | exact ⟨_, rfl, rfl⟩)

/-- Webauthn's one-second throttle is also its reset, with subsecond precision preserved. -/
theorem webauthn_failure (count : Usize) (ct : softlock.Time) (s : softlock.State)
    (h : softlock.failure_next_state .Webauthn count ct = ok s) :
    ∃ reset, s = .Locked count reset reset ∧ reset.nanos = ct.nanos ∧
      reset.secs.val = ct.secs.val + 1 := by
  unfold softlock.failure_next_state softlock.plus_seconds at h
  h5i_invert h
  h5i_invert hnext
  refine ⟨_, rfl, rfl, ?_⟩
  have hv := add_ok_val _ _ _ hi
  simpa using hv

/-- Every restricted policy records the supplied count in a Locked state. -/
theorem failure_records_count (policy : softlock.Policy) (count : Usize) (ct : softlock.Time)
    (s : softlock.State) (h : softlock.failure_next_state policy count ct = ok s) :
    (policy = .Unrestricted ∧ s = .Init) ∨
      ∃ reset unlock, s = .Locked count reset unlock := by
  cases policy <;> unfold softlock.failure_next_state at h <;> h5i_invert h
  all_goals first | exact Or.inr ⟨_, _, rfl⟩ | exact Or.inl ⟨rfl, rfl⟩

/-- Recording an unsuccessful authentication increments the retained counter and
locks restricted credentials, while preserving the policy and tracked expiry. -/
theorem record_failure_spec (lock : softlock.SoftLock) (ct : softlock.Time)
    (out : softlock.SoftLock) (h : softlock.record_failure lock ct = ok out) :
    out.policy = lock.policy ∧ out.last_expire_at = lock.last_expire_at ∧
    ((lock.policy = .Unrestricted ∧ out.state = .Init) ∨
      ∃ count reset unlock, out.state = .Locked count reset unlock ∧
        count.val = (match lock.state with | .Init => 0 | .Locked n .. => n.val | .Unlocked n _ => n.val) + 1) := by
  unfold softlock.record_failure at h
  cases hs : lock.state <;> simp only [hs] at h <;> h5i_invert h
  all_goals
    dsimp
    simp only [eq_self_iff_true, true_and]
    have hshape := failure_records_count _ _ _ _ (by assumption)
    obtain hshape | ⟨r, u, hr⟩ := hshape
    · exact Or.inl hshape
    · refine Or.inr ⟨_, r, u, hr, ?_⟩
      first | rfl | (have hv := add_ok_val _ _ _ hi; simpa using hv)

end kanidm_kernel.Verified.SoftLock
