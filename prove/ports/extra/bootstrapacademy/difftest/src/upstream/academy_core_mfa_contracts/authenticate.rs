// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::future::Future;

use crate::upstream::academy_models::{mfa::MfaAuthentication, user::UserId};
use thiserror::Error;

pub trait MfaAuthenticateService<Txn: Send + Sync + 'static>: Send + Sync + 'static {
    /// Authenticate the given user using a second factor.
    ///
    /// Disables MFA for the user if a correct recovery code is provided.
    fn authenticate(
        &self,
        txn: &mut Txn,
        user_id: UserId,
        cmd: MfaAuthentication,
    ) -> impl Future<Output = Result<MfaAuthenticateResult, MfaAuthenticateError>> + Send;
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MfaAuthenticateResult {
    /// MFA is disabled
    Disabled,
    /// MFA is enabled and authentication was successful
    Ok,
    /// Recovery code has been used and MFA has been disabled
    Reset,
}

#[derive(Debug, Error)]
pub enum MfaAuthenticateError {
    #[error("The user failed to authenticate.")]
    Failed,
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}
