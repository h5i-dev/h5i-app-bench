import KanidmKernel
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel
namespace kanidm_kernel.Verified.CredentialCommit

/-- The policy-specific warning; missing credentials is checked afterwards. -/
def policyWarning (policy : credential_commit.Policy) (primary : Option Bool)
    (passkeys attested : Bool) : Option credential_commit.Warning :=
  match policy with
  | .Any => none
  | .External | .Mfa => if primary = some false then some .MfaRequired else none
  | .Passkey => if primary.isSome then some .PasskeyRequired else none
  | .AttestedPasskey => if passkeys || primary.isSome then some .AttestedPasskeyRequired else none
  | .AttestedResidentkey => if attested || passkeys || primary.isSome then some .AttestedResidentKeyRequired else none
  | .Invalid => some .Unsatisfiable

def decision (policy : credential_commit.Policy) (primary : Option Bool)
    (passkeys attested : Bool) (caEmpty : Option Bool) : credential_commit.Decision :=
  let warning := policyWarning policy primary passkeys attested
  let missing := !attested && !passkeys && primary.isNone
  {can_commit := warning.isNone && !missing,
   policy_warning := warning,
   attestation_unsatisfiable := caEmpty.getD false,
   no_valid_credentials := warning.isNone && missing}

/-- Complete result, including warning order via the three distinct warning slots. -/
theorem can_commit_spec (policy : credential_commit.Policy) (primary : Option Bool)
    (passkeys attested : Bool) (caEmpty : Option Bool) :
    credential_commit.can_commit policy primary passkeys attested caEmpty =
      ok (decision policy primary passkeys attested caEmpty) := by
  cases policy <;> cases primary with
  | none => cases passkeys <;> cases attested <;> cases caEmpty <;>
      simp [credential_commit.can_commit, decision, policyWarning, core.option.Option.unwrap_or, lift] <;> rfl
  | some mfa => cases mfa <;> cases passkeys <;> cases attested <;> cases caEmpty <;>
      simp [credential_commit.can_commit, decision, policyWarning, core.option.Option.unwrap_or, lift] <;> rfl

/-- An invalid credential policy never allows a credential update to commit. -/
theorem invalid_denied (primary : Option Bool) (passkeys attested : Bool) (caEmpty : Option Bool) :
    ∃ d, credential_commit.can_commit .Invalid primary passkeys attested caEmpty = ok d ∧
      d.can_commit = false ∧ d.policy_warning = some .Unsatisfiable := by
  refine ⟨decision .Invalid primary passkeys attested caEmpty, can_commit_spec .., ?_, ?_⟩ <;>
    simp [decision, policyWarning]
end kanidm_kernel.Verified.CredentialCommit
