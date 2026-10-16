// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::{fmt::Debug, time::Duration};

use serde::{Serialize, de::DeserializeOwned};
use thiserror::Error;

pub trait JwtService: Send + Sync + 'static {
    /// Sign a JWT with the given data and time to live.
    ///
    /// `data` must serialize to a map (JSON object), which may not contain the
    /// `exp` key.
    fn sign<T: Serialize + Debug + 'static>(
        &self,
        data: T,
        ttl: Duration,
    ) -> anyhow::Result<String>;

    /// Verify the signature of the given JWT, deserialize its payload and
    /// ensure the JWT has not expired yet.
    fn verify<T: DeserializeOwned + Debug + 'static>(
        &self,
        jwt: &str,
    ) -> Result<T, VerifyJwtError<T>>;

    /// Like [`JwtService::sign`], but signed with the secret that is configured
    /// for `key` instead of the default JWT secret.
    ///
    /// Keys without their own secret fall back to the default JWT secret.
    fn sign_with_key<T: Serialize + Debug + 'static>(
        &self,
        key: &str,
        data: T,
        ttl: Duration,
    ) -> anyhow::Result<String>;

    /// Like [`JwtService::verify`], but verified with the secret that is
    /// configured for `key` instead of the default JWT secret.
    ///
    /// Keys without their own secret fall back to the default JWT secret.
    fn verify_with_key<T: DeserializeOwned + Debug + 'static>(
        &self,
        key: &str,
        jwt: &str,
    ) -> Result<T, VerifyJwtError<T>>;
}

#[derive(Debug, Error)]
pub enum VerifyJwtError<T> {
    #[error("JWT has already expired (data: {0})")]
    Expired(T),
    #[error("Invalid JWT")]
    Invalid,
}
