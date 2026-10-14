//! Differential checks against the pinned upstream's public and private pure validators.
use oxicloud_kernel::validation as port;
use crate::tests::Rng;
mod upstream_auth { include!(concat!(env!("OUT_DIR"), "/auth_oracle.rs")); }
fn reason(value: Option<port::EmailReason>) -> Option<&'static str> {
    value.map(|r| match r {
        port::EmailReason::Unverified => "idp_asserts_unverified",
        port::EmailReason::UnverifiedFlagOff => "idp_asserts_unverified_flag_off",
        port::EmailReason::ClaimAbsentRequired => "claim_absent_and_required",
    })
}
fn check(raw: &str) {
    assert_eq!(port::is_valid_entry_name(raw.as_bytes()), oxicloud::common::config::is_valid_entry_name(raw));
    let result = port::validate_dpop_jkt(raw.as_bytes()).map(|v| String::from_utf8(v).unwrap()).map_err(|e| match e {
        port::JktError::WrongLength => "DPoP thumbprint must be 43 characters (base64url SHA-256)",
        port::JktError::BadAlphabet => "DPoP thumbprint contains non-base64url characters",
    });
    assert_eq!(result, upstream_auth::jkt(raw));
}
#[test]
fn login_and_storage_validation_differential() {
    for claim in [None, Some(false), Some(true)] {
        for required in [false, true] {
            let d = port::classify_email_verification(claim, required);
            assert_eq!((d.reject, reason(d.reason)), upstream_auth::email(claim, required));
        }
    }
    for len in [0, 1, 31, 32, 33, 42, 43, 44, 128] {
        for byte in 0..=127 {
            let raw = String::from_utf8(vec![byte; len]).unwrap();
            check(&raw);
        }
    }
    let mut rng = Rng(0x0427_2adf_910a_23bd);
    for _ in 0..10_000 {
        let mut raw = String::new();
        for _ in 0..rng.below(80) {
            if let Some(c) = char::from_u32(rng.below(0x11_0000) as u32) { raw.push(c); }
        }
        check(&raw);
        let alphabet = b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-";
        let mut raw = (0..43).map(|_| rng.pick(alphabet) as char).collect::<String>();
        check(&raw);
        let position = rng.below(43) as usize;
        raw.replace_range(position..position+1, &char::from(rng.below(128) as u8).to_string());
        check(&raw);
    }
}
