#[path="../../difftest/credential_commit/reference.rs"]
mod reference;
use kanidm_kernel::credential_commit::{self,Policy,Warning};
#[test]
fn exhaustive_commit_decision() {
 let policies=[
(Policy::Any,reference::CredentialType::Any),
(Policy::External,reference::CredentialType::External),
(Policy::Mfa,reference::CredentialType::Mfa),
(Policy::Passkey,reference::CredentialType::Passkey),
(Policy::AttestedPasskey,reference::CredentialType::AttestedPasskey),
(Policy::AttestedResidentkey,reference::CredentialType::AttestedResidentkey),
(Policy::Invalid,reference::CredentialType::Invalid),
];
 let mut comparisons=0;
 for (policy,ref_policy) in policies { for primary in [None,Some(false),Some(true)] { for pass in [false,true] { for attested in [false,true] { for ca in [None,Some(false),Some(true)] {
  let r=reference::CredentialUpdateSession {
   resolved_account_policy:reference::ResolvedAccountPolicy {policy:ref_policy,ca:ca.map(reference::CaList)},
   primary:primary.map(reference::Credential), passkeys:if pass {vec![()]}else{vec![]}, attested_passkeys:if attested{vec![()]}else{vec![]}}.can_commit();
  let p=credential_commit::can_commit(policy,primary,pass,attested,ca);
  let mut warnings=Vec::new();
  if let Some(w)=p.policy_warning { warnings.push(match w {
Warning::MfaRequired=>reference::CredentialUpdateSessionStatusWarnings::MfaRequired,
Warning::PasskeyRequired=>reference::CredentialUpdateSessionStatusWarnings::PasskeyRequired,
Warning::AttestedPasskeyRequired=>reference::CredentialUpdateSessionStatusWarnings::AttestedPasskeyRequired,
Warning::AttestedResidentKeyRequired=>reference::CredentialUpdateSessionStatusWarnings::AttestedResidentKeyRequired,
Warning::Unsatisfiable=>reference::CredentialUpdateSessionStatusWarnings::Unsatisfiable,
 }); }
  if p.attestation_unsatisfiable {warnings.push(reference::CredentialUpdateSessionStatusWarnings::WebauthnAttestationUnsatisfiable);}
  if p.no_valid_credentials {warnings.push(reference::CredentialUpdateSessionStatusWarnings::NoValidCredentials);}
  assert_eq!((p.can_commit,warnings),r,"{policy:?} {primary:?} {pass} {attested} {ca:?}"); comparisons+=1;
 }}}}}
 println!("{comparisons} exhaustive credential-commit comparisons");
}
