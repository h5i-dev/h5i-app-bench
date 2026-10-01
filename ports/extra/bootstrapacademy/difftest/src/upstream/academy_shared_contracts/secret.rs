// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use crate::upstream::academy_models::{Sensitive, VerificationCode, mfa::MfaRecoveryCode};

pub trait SecretService: Send + Sync + 'static {
    /// Generate a new random alphanumeric string of the given length.
    fn generate(&self, len: usize) -> Sensitive<String>;

    /// Generate `len` bytes of random data.
    fn generate_bytes(&self, len: usize) -> Sensitive<Vec<u8>>;

    /// Generate a new random verification code.
    fn generate_verification_code(&self) -> VerificationCode;

    /// Generate a new random mfa recovery code.
    fn generate_mfa_recovery_code(&self) -> MfaRecoveryCode;
}
