// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::future::Future;

use crate::upstream::academy_models::mfa::{TotpCode, TotpSecret, TotpSetup};
use thiserror::Error;

pub trait TotpService: Send + Sync + 'static {
    /// Generate a new random totp secret.
    fn generate_secret(&self) -> (TotpSecret, TotpSetup);

    /// Check the given totp code.
    fn check(
        &self,
        code: &TotpCode,
        secret: TotpSecret,
    ) -> impl Future<Output = Result<(), TotpCheckError>> + Send;
}

#[derive(Debug, Error)]
pub enum TotpCheckError {
    #[error("The code is incorrect.")]
    InvalidCode,
    #[error("The code has already been used recently.")]
    RecentlyUsed,
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}
