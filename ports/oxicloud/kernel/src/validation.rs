//! Login-boundary and storage-configuration validation.
use crate::bytes;

#[derive(Clone, Copy)]
pub enum EmailReason { Unverified, UnverifiedFlagOff, ClaimAbsentRequired }
pub struct EmailDecision { pub reject: bool, pub reason: Option<EmailReason> }

/// Upstream `classify_email_verification`.
pub fn classify_email_verification(claim: Option<bool>, must_verify: bool) -> EmailDecision {
    match claim {
        Some(true) => EmailDecision { reject: false, reason: None },
        Some(false) => if must_verify {
            EmailDecision { reject: true, reason: Some(EmailReason::Unverified) }
        } else {
            EmailDecision { reject: false, reason: Some(EmailReason::UnverifiedFlagOff) }
        },
        None => if must_verify {
            EmailDecision { reject: true, reason: Some(EmailReason::ClaimAbsentRequired) }
        } else {
            EmailDecision { reject: false, reason: None }
        },
    }
}

fn storage_byte(b: u8) -> bool {
    (b >= b'a' && b <= b'z') || (b >= b'0' && b <= b'9') || b == b'_' || b == b'-'
}
fn base64url_byte(b: u8) -> bool {
    storage_byte(b) || (b >= b'A' && b <= b'Z')
}
fn all_storage(raw: &[u8]) -> bool {
    let mut i = 0;
    while i < raw.len() {
        if !storage_byte(raw[i]) { return false; }
        i += 1;
    }
    true
}
fn all_base64url(raw: &[u8]) -> bool {
    let mut i = 0;
    while i < raw.len() {
        if !base64url_byte(raw[i]) { return false; }
        i += 1;
    }
    true
}

/// Upstream `is_valid_entry_name`.
pub fn is_valid_entry_name(raw: &[u8]) -> bool {
    if raw.len() < 1 || raw.len() > 32 { return false; }
    all_storage(raw)
}
#[derive(Clone, Copy)]
pub enum JktError { WrongLength, BadAlphabet }
/// Upstream `validate_dpop_jkt`.
pub fn validate_dpop_jkt(raw: &[u8]) -> Result<Vec<u8>, JktError> {
    if raw.len() != 43 { return Err(JktError::WrongLength); }
    if !all_base64url(raw) { return Err(JktError::BadAlphabet); }
    Ok(bytes::copy(raw))
}
