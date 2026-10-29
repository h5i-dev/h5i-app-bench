//! Complete credential-update commit policy decision from Kanidm f608c4f.
//! Presence, MFA and CA-list emptiness are projections of the caller's objects.
//! Warning slots preserve upstream warning order without a bounded allocation.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Policy { Any, External, Mfa, Passkey, AttestedPasskey, AttestedResidentkey, Invalid }
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Warning { MfaRequired, PasskeyRequired, AttestedPasskeyRequired, AttestedResidentKeyRequired, Unsatisfiable }
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Decision { pub can_commit: bool, pub policy_warning: Option<Warning>, pub attestation_unsatisfiable: bool, pub no_valid_credentials: bool }
pub fn can_commit(policy: Policy, primary: Option<bool>, passkeys: bool, attested_passkeys: bool, ca_empty: Option<bool>) -> Decision {
    let mut can_commit = true;
    let mut warning = None;
    match policy {
        Policy::Any => {},
        Policy::External | Policy::Mfa => {
            if match primary { Some(mfa) => !mfa, None => false } {
                can_commit=false; warning=Some(Warning::MfaRequired);
            }
        },
        Policy::Passkey => { if primary.is_some() { can_commit=false; warning=Some(Warning::PasskeyRequired); } },
        Policy::AttestedPasskey => { if passkeys || primary.is_some() { can_commit=false; warning=Some(Warning::AttestedPasskeyRequired); } },
        Policy::AttestedResidentkey => { if attested_passkeys || passkeys || primary.is_some() { can_commit=false; warning=Some(Warning::AttestedResidentKeyRequired); } },
        Policy::Invalid => { can_commit=false; warning=Some(Warning::Unsatisfiable); },
    }
    let attestation_unsatisfiable = ca_empty.unwrap_or(false);
    let mut no_valid_credentials = false;
    if can_commit && !attested_passkeys && !passkeys && primary.is_none() {
        can_commit=false; no_valid_credentials=true;
    }
    Decision {can_commit, policy_warning:warning, attestation_unsatisfiable, no_valid_credentials}
}
