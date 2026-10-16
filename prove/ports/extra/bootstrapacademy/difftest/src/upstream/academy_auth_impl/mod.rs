// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::time::Duration;

use crate::upstream::academy_auth_contracts::{
    AuthService, AuthenticateByPasswordError, AuthenticateByRefreshTokenError, Authentication,
    Tokens, access_token::AuthAccessTokenService, refresh_token::AuthRefreshTokenService,
};
use crate::upstream::academy_di::Build;
use crate::upstream::academy_models::{
    auth::{AccessToken, AuthenticateError, RefreshToken},
    session::{SessionId, SessionRefreshTokenHash},
    user::{User, UserId, UserPassword},
};
use crate::upstream::academy_persistence_contracts::{Database, session::SessionRepository, user::UserRepository};
use crate::upstream::academy_shared_contracts::{
    password::{PasswordService, PasswordVerifyError},
    time::TimeService,
};
use crate::upstream::academy_utils::trace_instrument;
use anyhow::Context;
use crate::upstream::tracing::trace;

pub mod access_token;
pub mod refresh_token;


#[derive(Debug, Clone)]
pub struct AuthServiceImpl<
    Time,
    Password,
    UserRepo,
    SessionRepo,
    AuthAccessToken,
    AuthRefreshToken,
    Db,
> {
    pub db: Db,
    pub time: Time,
    pub password: Password,
    pub user_repo: UserRepo,
    pub session_repo: SessionRepo,
    pub auth_access_token: AuthAccessToken,
    pub auth_refresh_token: AuthRefreshToken,
    pub config: AuthServiceConfig,
}

#[derive(Debug, Clone, Copy)]
pub struct AuthServiceConfig {
    pub access_token_ttl: Duration,
    pub refresh_token_ttl: Duration,
    pub refresh_token_length: usize,
    pub internal_token_ttl: Duration,
}

impl<Txn, Time, Password, UserRepo, SessionRepo, AuthAccessToken, AuthRefreshToken, Db>
    AuthService<Txn>
    for AuthServiceImpl<
        Time,
        Password,
        UserRepo,
        SessionRepo,
        AuthAccessToken,
        AuthRefreshToken,
        Db,
    >
where
    Txn: Send + Sync + 'static,
    Db: Database<Transaction = Txn>,
    Time: TimeService,
    Password: PasswordService,
    UserRepo: UserRepository<Txn>,
    SessionRepo: SessionRepository<Txn>,
    AuthAccessToken: AuthAccessTokenService,
    AuthRefreshToken: AuthRefreshTokenService,
{
    async fn authenticate(&self, token: &AccessToken) -> Result<Authentication, AuthenticateError> {
        let auth = self
            .auth_access_token
            .verify(token)
            .ok_or(AuthenticateError::InvalidToken)?;

        if self
            .auth_access_token
            .is_invalidated(auth.refresh_token_hash)
            .await
            .context("Failed to check whether access token has been invalidated")?
        {
            trace!(?auth, "token invalidated");
            return Err(AuthenticateError::InvalidToken);
        }

        let mut txn = self.db.begin_transaction().await?;
        // Ordinary authority requires a current live session and an enabled
        // account. Redis invalidation is an early rejection optimization, never
        // the sole source of authority (cache expiry/flush cannot revive it).
        let user = self
            .user_repo
            .get_composite(&mut txn, auth.user_id)
            .await?
            .filter(|u| u.user.enabled)
            .ok_or(AuthenticateError::InvalidToken)?;
        let session = self
            .session_repo
            .get_by_refresh_token_hash(&mut txn, auth.refresh_token_hash)
            .await?
            .filter(|s| s.id == auth.session_id && s.user_id == auth.user_id)
            .ok_or(AuthenticateError::InvalidToken)?;
        let auth = Authentication {
            admin: user.user.admin,
            email_verified: user.user.email_verified,
            mfa_verified: session.mfa_verified,
            ..auth
        };
        Ok(auth)
    }

    async fn authenticate_by_password(
        &self,
        txn: &mut Txn,
        user_id: UserId,
        password: UserPassword,
    ) -> Result<(), AuthenticateByPasswordError> {
        let password_hash = self
            .user_repo
            .get_password_hash(txn, user_id)
            .await
            .context("Failed to get password hash from database")?
            .ok_or(AuthenticateByPasswordError::InvalidCredentials)
            .inspect_err(|_| trace!("no password set"))?;

        self.password
            .verify(password.into_inner().into(), password_hash)
            .await
            .map_err(|err| match err {
                PasswordVerifyError::InvalidPassword => {
                    trace!("wrong password");
                    AuthenticateByPasswordError::InvalidCredentials
                }
                PasswordVerifyError::Other(err) => {
                    err.context("Failed to verify password against hash").into()
                }
            })
    }

    async fn authenticate_by_refresh_token(
        &self,
        txn: &mut Txn,
        refresh_token: &RefreshToken,
    ) -> Result<SessionId, AuthenticateByRefreshTokenError> {
        let refresh_token_hash = self.auth_refresh_token.hash(refresh_token);

        let session = self
            .session_repo
            .get_by_refresh_token_hash(txn, refresh_token_hash)
            .await
            .context("Failed to get session from database")?
            .ok_or(AuthenticateByRefreshTokenError::Invalid)
            .inspect_err(|_| trace!("no session"))?;

        let now = self.time.now();
        if now >= session.updated_at + self.config.refresh_token_ttl {
            trace!("session expired");
            return Err(AuthenticateByRefreshTokenError::Expired(session.id));
        }

        Ok(session.id)
    }

    fn issue_tokens(
        &self,
        user: &User,
        session_id: SessionId,
        mfa_verified: bool,
    ) -> anyhow::Result<Tokens> {
        let refresh_token = self.auth_refresh_token.issue();
        let refresh_token_hash = self.auth_refresh_token.hash(&refresh_token);
        let access_token = self
            .auth_access_token
            .issue(user, session_id, refresh_token_hash, mfa_verified)
            .context("Failed to issue access token")?;

        Ok(Tokens {
            access_token,
            refresh_token,
            refresh_token_hash,
        })
    }

    async fn invalidate_access_tokens(&self, txn: &mut Txn, user_id: UserId) -> anyhow::Result<()> {
        let refresh_token_hashes = self.list_refresh_token_hashes(txn, user_id).await?;
        self.invalidate_access_tokens_of(refresh_token_hashes).await
    }

    async fn list_refresh_token_hashes(
        &self,
        txn: &mut Txn,
        user_id: UserId,
    ) -> anyhow::Result<Vec<SessionRefreshTokenHash>> {
        self.session_repo
            .list_refresh_token_hashes_by_user(txn, user_id)
            .await
            .context("Failed to get session refresh token hashes from database")
    }

    async fn invalidate_access_tokens_of(
        &self,
        refresh_token_hashes: Vec<SessionRefreshTokenHash>,
    ) -> anyhow::Result<()> {
        for refresh_token_hash in refresh_token_hashes {
            self.auth_access_token
                .invalidate(refresh_token_hash)
                .await
                .context("Failed to invalidate access token")?;
        }

        Ok(())
    }
}
