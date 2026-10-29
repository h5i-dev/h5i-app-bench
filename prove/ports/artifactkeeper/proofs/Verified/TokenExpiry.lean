import ArtifactkeeperKernel
import H5iAppLib

open Aeneas Aeneas.Std Result artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.TokenExpiry

/-- Configuration acceptance over mathematical integers. -/
def Valid (p : token_expiry.Policy) : Prop :=
  1 ≤ p.min_days.val ∧ p.min_days.val ≤ p.max_days.val ∧
  p.max_days.val ≤ 3650 ∧
  ∀ d ∈ p.default_days, p.min_days.val ≤ d.val ∧ d.val ≤ p.max_days.val

/-- Minting decisions, independent of the extracted implementation. Config
validation is deliberately separate: a configured default is used as stored. -/
def resolve (p : token_expiry.Policy) (requested : Option Std.I64) (service : Bool) :
    core.result.Result token_expiry.ResolvedExpiry token_expiry.PolicyError :=
  if p.require_expiration = false ∨ (service = true ∧ p.apply_to_service_accounts = false) then
    .Ok ⟨requested, false⟩
  else match requested with
    | none => match p.default_days with
      | none => .Err .Required
      | some d => .Ok ⟨some d, true⟩
    | some d => if p.min_days.val ≤ d.val ∧ d.val ≤ p.max_days.val then
        .Ok ⟨some d, true⟩ else .Err .RequestedRange

theorem default_valid :
    ∃ p, token_expiry.default_policy = ok p ∧ Valid p ∧
      p.require_expiration = false ∧ p.apply_to_service_accounts = false := by
  refine ⟨⟨false, 1#i64, 90#i64, some 90#i64, false⟩, rfl, ?_, rfl, rfl⟩
  simp [Valid, IScalar.ofInt_val_eq]

theorem validation_iff (p : token_expiry.Policy) :
    token_expiry.validate p = ok (.Ok ()) ↔ Valid p := by
  unfold token_expiry.validate Valid
  cases hd : p.default_days <;>
    simp only [hd, IScalar.lt_equiv, IScalar.ofInt_val_eq]
  all_goals split <;> simp_all
  all_goals split <;> simp_all
  all_goals split <;> simp_all
  all_goals split <;> simp_all
  all_goals split <;> simp_all
  all_goals omega

theorem resolution_spec (p : token_expiry.Policy) (requested : Option Std.I64) (service : Bool) :
    token_expiry.resolve_expiry p requested service = ok (resolve p requested service) := by
  unfold token_expiry.resolve_expiry resolve
  cases hreq : p.require_expiration <;> cases service <;>
    cases happly : p.apply_to_service_accounts <;>
    cases requested <;> cases hd : p.default_days <;>
    simp only [hreq, happly, hd, Bool.false_eq_true, Bool.true_eq_false,
      not_false_eq_true, and_false, and_true, or_true, or_false, false_or,
      true_or, ↓reduceIte, IScalar.lt_equiv]
  all_goals split <;> split <;> simp_all <;> omega

/-- Every explicitly requested lifetime accepted under enforcement is bounded. -/
theorem accepted_request_bounded (p : token_expiry.Policy) (d : Std.I64)
    (service : Bool) (r : token_expiry.ResolvedExpiry)
    (h : token_expiry.resolve_expiry p (some d) service = ok (.Ok r))
    (ha : r.policy_applied = true) :
    p.min_days.val ≤ d.val ∧ d.val ≤ p.max_days.val := by
  rw [resolution_spec] at h
  simp only [resolve] at h
  split at h
  · simp only [ok.injEq, core.result.Result.Ok.injEq] at h
    subst r
    contradiction
  · split at h
    · assumption
    · simp at h

end artifactkeeper_kernel.Verified.TokenExpiry
