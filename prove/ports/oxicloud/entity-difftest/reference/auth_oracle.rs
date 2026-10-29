struct EmailVerificationDecision {
    reject: bool,
    reason: Option<&'static str>,
}fn classify_email_verification(
    email_verified: Option<bool>,
    must_verify: bool,
) -> EmailVerificationDecision {
    match (email_verified, must_verify) {
        (Some(true), _) => EmailVerificationDecision {
            reject: false,
            reason: None,
        },
        (Some(false), true) => EmailVerificationDecision {
            reject: true,
            reason: Some("idp_asserts_unverified"),
        },
        (Some(false), false) => EmailVerificationDecision {
            reject: false,
            reason: Some("idp_asserts_unverified_flag_off"),
        },
        (None, true) => EmailVerificationDecision {
            reject: true,
            reason: Some("claim_absent_and_required"),
        },
        (None, false) => EmailVerificationDecision {
            reject: false,
            reason: None,
        },
    }
}fn validate_dpop_jkt(raw: &str) -> Result<String, &'static str> {
    if raw.len() != 43 {
        return Err("DPoP thumbprint must be 43 characters (base64url SHA-256)");
    }
    if !raw
        .bytes()
        .all(|b| b.is_ascii_alphanumeric() || b == b'-' || b == b'_')
    {
        return Err("DPoP thumbprint contains non-base64url characters");
    }
    Ok(raw.to_string())
}
pub fn email(claim: Option<bool>, required: bool)->(bool,Option<&'static str>) {let d=classify_email_verification(claim,required);(d.reject,d.reason)}
pub fn jkt(raw:&str)->Result<String,&'static str> {validate_dpop_jkt(raw)}
