// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::future::Future;

use crate::upstream::academy_models::{
    auth::{AccessToken, AuthError, AuthenticateError, AuthorizeError, RefreshToken},
    session::{SessionId, SessionRefreshTokenHash},
    user::{User, UserId, UserPassword},
};
use thiserror::Error;

pub mod access_token;
pub mod refresh_token;

pub trait AuthService<Txn: Send + Sync + 'static>: Send + Sync + 'static {
    /// Authenticates a user using an access token.
    fn authenticate(
        &self,
        token: &AccessToken,
    ) -> impl Future<Output = Result<Authentication, AuthenticateError>> + Send;

    /// Authenticates a user using their account password.
    fn authenticate_by_password(
        &self,
        txn: &mut Txn,
        user_id: UserId,
        password: UserPassword,
    ) -> impl Future<Output = Result<(), AuthenticateByPasswordError>> + Send;

    /// Authenticates a user using a refresh token.
    fn authenticate_by_refresh_token(
        &self,
        txn: &mut Txn,
        refresh_token: &RefreshToken,
    ) -> impl Future<Output = Result<SessionId, AuthenticateByRefreshTokenError>> + Send;

    /// Issues an access and refresh token for a given user and session.
    ///
    /// `mfa_verified` records whether the session was established with a
    /// verified second factor.
    fn issue_tokens(
        &self,
        user: &User,
        session_id: SessionId,
        mfa_verified: bool,
    ) -> anyhow::Result<Tokens>;

    /// Invalidates all previously issued access tokens of a user.
    fn invalidate_access_tokens(
        &self,
        txn: &mut Txn,
        user_id: UserId,
    ) -> impl Future<Output = anyhow::Result<()>> + Send;

    /// Return the refresh token hashes of all sessions of the given user.
    ///
    /// Together with [`AuthService::invalidate_access_tokens_of`] this is
    /// [`AuthService::invalidate_access_tokens`] split into its database half
    /// and its cache half. A caller that deletes those sessions inside a
    /// transaction has to read the hashes before they are gone but must only
    /// invalidate the access tokens once the transaction has been committed:
    /// the cache is not transactional, so an invalidation that ran first
    /// survives a rollback and logs the user out of every device for nothing.
    fn list_refresh_token_hashes(
        &self,
        txn: &mut Txn,
        user_id: UserId,
    ) -> impl Future<Output = anyhow::Result<Vec<SessionRefreshTokenHash>>> + Send;

    /// Invalidate the access tokens that were issued together with the given
    /// refresh tokens.
    fn invalidate_access_tokens_of(
        &self,
        refresh_token_hashes: Vec<SessionRefreshTokenHash>,
    ) -> impl Future<Output = anyhow::Result<()>> + Send;
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Tokens {
    pub access_token: AccessToken,
    pub refresh_token: RefreshToken,
    pub refresh_token_hash: SessionRefreshTokenHash,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Authentication {
    pub user_id: UserId,
    pub session_id: SessionId,
    pub refresh_token_hash: SessionRefreshTokenHash,
    pub admin: bool,
    pub email_verified: bool,
    /// Whether the session was established with a verified second factor.
    pub mfa_verified: bool,
}

#[derive(Debug, Error)]
pub enum AuthenticateByPasswordError {
    #[error("The user does not exist or the password is incorrect.")]
    InvalidCredentials,
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

#[derive(Debug, Error)]
pub enum AuthenticateByRefreshTokenError {
    #[error("The refresh token is invalid")]
    Invalid,
    #[error("The refresh token has expired")]
    Expired(SessionId),
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

impl Authentication {
    /// Return an error if the authenticated user is not an administrator or
    /// did not authenticate with a second factor.
    pub fn ensure_admin(&self) -> Result<(), AuthorizeError> {
        if !self.admin {
            return Err(AuthorizeError::Admin);
        }
        self.mfa_verified
            .then_some(())
            .ok_or(AuthorizeError::AdminMfa)
    }

    /// Return an error if the authenticated user has not verified their email
    /// address.
    pub fn ensure_email_verified(&self) -> Result<(), AuthorizeError> {
        self.email_verified
            .then_some(())
            .ok_or(AuthorizeError::EmailVerified)
    }

    /// Return an error if the authenticated user is neither the same as the one
    /// identified by the given `user_id` nor an administrator.
    pub fn ensure_self_or_admin(&self, user_id: UserId) -> Result<(), AuthorizeError> {
        if self.user_id == user_id {
            return Ok(());
        }
        self.ensure_admin()
    }
}

pub trait AuthResultExt<T> {
    fn map_auth_err(self) -> Result<T, AuthError>;
}

impl<T, E> AuthResultExt<T> for Result<T, E>
where
    E: Into<AuthError>,
{
    fn map_auth_err(self) -> Result<T, AuthError> {
        self.map_err(Into::into)
    }
}
