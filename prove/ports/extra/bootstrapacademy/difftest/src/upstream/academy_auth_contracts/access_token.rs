// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::future::Future;

use crate::upstream::academy_models::{
    auth::AccessToken,
    session::{SessionId, SessionRefreshTokenHash},
    user::User,
};

use super::Authentication;

pub trait AuthAccessTokenService: Send + Sync + 'static {
    /// Generate a new access token for the given user and session.
    fn issue(
        &self,
        user: &User,
        session_id: SessionId,
        refresh_token_hash: SessionRefreshTokenHash,
        mfa_verified: bool,
    ) -> anyhow::Result<AccessToken>;

    /// Verify the given access token and return its content if it is valid.
    fn verify(&self, access_token: &AccessToken) -> Option<Authentication>;

    /// Manually invalidate a previously issued access token before it expires.
    fn invalidate(
        &self,
        refresh_token_hash: SessionRefreshTokenHash,
    ) -> impl Future<Output = anyhow::Result<()>> + Send;

    /// Return whether an access token has been manually invalidated.
    fn is_invalidated(
        &self,
        refresh_token_hash: SessionRefreshTokenHash,
    ) -> impl Future<Output = anyhow::Result<bool>> + Send;
}
