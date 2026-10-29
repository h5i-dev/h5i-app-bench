// Verbatim pinned upstream can_commit method with projection-only stand-ins.
#![allow(dead_code)]
macro_rules! debug { ($($t:tt)*) => {} }
#[derive(Clone,Copy,Debug)]
pub enum CredentialType {Any,External,Mfa,Passkey,AttestedPasskey,AttestedResidentkey,Invalid}
#[derive(Debug,PartialEq,Eq)]
pub enum CredentialUpdateSessionStatusWarnings {MfaRequired,PasskeyRequired,AttestedPasskeyRequired,AttestedResidentKeyRequired,Unsatisfiable,WebauthnAttestationUnsatisfiable,NoValidCredentials}
pub struct Credential(pub bool); impl Credential {fn is_mfa(&self)->bool{self.0}}
pub struct CaList(pub bool); impl CaList {fn is_empty(&self)->bool{self.0}}
pub struct ResolvedAccountPolicy { pub policy:CredentialType,pub ca:Option<CaList> }
impl ResolvedAccountPolicy { fn credential_policy(&self)->CredentialType {self.policy} fn webauthn_attestation_ca_list(&self)->Option<&CaList>{self.ca.as_ref()} }
pub struct CredentialUpdateSession {pub resolved_account_policy:ResolvedAccountPolicy,pub primary:Option<Credential>,pub passkeys:Vec<()>,pub attested_passkeys:Vec<()>}
impl CredentialUpdateSession {
    pub fn can_commit(&self) -> (bool, Vec<CredentialUpdateSessionStatusWarnings>) {
        let mut warnings = Vec::with_capacity(0);
        let mut can_commit = true;

        let cred_type_min = self.resolved_account_policy.credential_policy();

        debug!(?cred_type_min);

        match cred_type_min {
            CredentialType::Any => {}
            CredentialType::External | CredentialType::Mfa => {
                if self
                    .primary
                    .as_ref()
                    .map(|cred| !cred.is_mfa())
                    // If it's none, then we can proceed because we satisfy mfa on other
                    // parts.
                    .unwrap_or(false)
                {
                    can_commit = false;
                    warnings.push(CredentialUpdateSessionStatusWarnings::MfaRequired);
                }
            }
            CredentialType::Passkey => {
                // NOTE: Technically this is unreachable, but we keep it for correctness.
                // Primary can't be set at all.
                if self.primary.is_some() {
                    can_commit = false;
                    warnings.push(CredentialUpdateSessionStatusWarnings::PasskeyRequired);
                }
            }
            CredentialType::AttestedPasskey => {
                // Also unreachable - during these sessions, there will be no values present here.
                if !self.passkeys.is_empty() || self.primary.is_some() {
                    can_commit = false;
                    warnings.push(CredentialUpdateSessionStatusWarnings::AttestedPasskeyRequired);
                }
            }
            CredentialType::AttestedResidentkey => {
                // Also unreachable - during these sessions, there will be no values present here.
                if !self.attested_passkeys.is_empty()
                    || !self.passkeys.is_empty()
                    || self.primary.is_some()
                {
                    can_commit = false;
                    warnings
                        .push(CredentialUpdateSessionStatusWarnings::AttestedResidentKeyRequired);
                }
            }
            CredentialType::Invalid => {
                // special case, must always deny all changes.
                can_commit = false;
                warnings.push(CredentialUpdateSessionStatusWarnings::Unsatisfiable)
            }
        }

        if let Some(att_ca_list) = self.resolved_account_policy.webauthn_attestation_ca_list() {
            if att_ca_list.is_empty() {
                warnings
                    .push(CredentialUpdateSessionStatusWarnings::WebauthnAttestationUnsatisfiable)
            }
        }

        // We only check this if we were able to proceed to a commit state. That way we don't warn needlessly.
        if can_commit
            && self.attested_passkeys.is_empty()
            && self.passkeys.is_empty()
            && self.primary.is_none()
        {
            // The user has no credentials to login to their account with, we can not proceed!
            can_commit = false;
            warnings.push(CredentialUpdateSessionStatusWarnings::NoValidCredentials)
        }

        (can_commit, warnings)
    }
}
