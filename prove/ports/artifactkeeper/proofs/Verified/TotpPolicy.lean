import ArtifactkeeperKernel
import H5iAppLib

open Aeneas Aeneas.Std Result artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.TotpPolicy
open totp_policy

/-- Policy scope over a subject, independent of existing enrollment. -/
def covered (p : TotpPolicy) (s : TotpSubject) : Bool :=
  let isLocal := match s.auth_provider with | .Local => true | _ => false
  let role := match p with | .Disabled => false | .RequiredForAdmins => s.is_admin | .RequiredForAll => true
  !s.is_service_account && isLocal && role

def login (p : TotpPolicy) (s : TotpSubject) : TotpLoginRequirement :=
  if s.totp_enabled then .ChallengeExisting
  else if covered p s then .EnrollmentRequired else .NotRequired

/-- Strictness is the number of subject classes required to enroll. -/
def rank : TotpPolicy → Nat
  | .Disabled => 0 | .RequiredForAdmins => 1 | .RequiredForAll => 2

def activation (current requested : TotpPolicy) (pinned enrolled : Bool) :
    core.result.Result Unit PolicyActivationRefusal :=
  if pinned then .Err .PinnedByEnvironment
  else if rank current < rank requested ∧ enrolled = false then .Err .ActorNotEnrolled
  else .Ok ()

theorem login_spec (p : TotpPolicy) (s : TotpSubject) :
    totp_login_requirement p s = ok (login p s) := by
  rcases s with ⟨provider, admin, service, enabled⟩
  cases p <;> cases provider <;> cases admin <;> cases service <;> cases enabled <;>
    simp [totp_login_requirement, login, covered,
      core.cmp.PartialEq.ne.trait_default, core.cmp.PartialEq.ne.default,
      AuthProvider.Insts.CoreCmpPartialEqAuthProvider,
      AuthProvider.Insts.CoreCmpPartialEqAuthProvider.eq, AuthProvider.read_discriminant] <;> scalar_tac

theorem disabling_spec (p : TotpPolicy) (s : TotpSubject) :
    policy_requires_totp p s = ok (covered p s) := by
  simp only [policy_requires_totp, login_spec, bind_ok, login]
  rcases s with ⟨provider, admin, service, enabled⟩
  cases p <;> cases provider <;> cases admin <;> cases service <;> cases enabled <;>
    simp [covered]

theorem activation_spec (current requested : TotpPolicy) (pinned enrolled : Bool) :
    check_policy_activation current requested pinned enrolled =
      ok (activation current requested pinned enrolled) := by
  cases current <;> cases requested <;> cases pinned <;> cases enrolled <;>
    simp [check_policy_activation, activation, is_tightening, strictness, rank]

theorem enforcing_spec (p : TotpPolicy) :
    is_enforcing p = ok (decide (0 < rank p)) := by
  cases p <;> simp [is_enforcing, rank]

/-- Policy relaxation is always available unless pinned externally. -/
theorem relaxation_allowed (current requested : TotpPolicy) (enrolled : Bool)
    (h : rank requested ≤ rank current) :
    check_policy_activation current requested false enrolled = ok (.Ok ()) := by
  rw [activation_spec]
  simp [activation, Nat.not_lt.mpr h]

/-- Existing TOTP enrollment takes precedence over every exemption. -/
theorem enrolled_challenged (p : TotpPolicy) (s : TotpSubject)
    (h : s.totp_enabled = true) :
    totp_login_requirement p s = ok .ChallengeExisting := by
  rw [login_spec]
  simp [login, h]

end artifactkeeper_kernel.Verified.TotpPolicy
