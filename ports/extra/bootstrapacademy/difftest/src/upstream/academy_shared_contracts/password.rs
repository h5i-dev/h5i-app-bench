// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::future::Future;

use crate::upstream::academy_models::Sensitive;
use thiserror::Error;

pub trait PasswordService: Send + Sync + 'static {
    /// Securely hash a password.
    fn hash(
        &self,
        password: Sensitive<String>,
    ) -> impl Future<Output = anyhow::Result<String>> + Send;

    /// Verify that a password matches the given hash.
    fn verify(
        &self,
        password: Sensitive<String>,
        hash: String,
    ) -> impl Future<Output = Result<(), PasswordVerifyError>> + Send;
}

#[derive(Debug, Error)]
pub enum PasswordVerifyError {
    #[error("The password does not match the provided hash.")]
    InvalidPassword,
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}
