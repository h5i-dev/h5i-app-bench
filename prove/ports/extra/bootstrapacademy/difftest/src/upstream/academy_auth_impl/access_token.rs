// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use crate::upstream::academy_auth_contracts::{Authentication, access_token::AuthAccessTokenService};
use crate::upstream::academy_cache_contracts::CacheService;
use crate::upstream::academy_di::Build;
use crate::upstream::academy_models::{
    auth::AccessToken,
    session::{SessionId, SessionRefreshTokenHash},
    user::{User, UserId},
};
use crate::upstream::academy_shared_contracts::jwt::JwtService;
use crate::upstream::academy_utils::trace_instrument;
use anyhow::Context;
use serde::{Deserialize, Serialize};

use super::AuthServiceConfig;

#[derive(Debug, Clone)]
pub struct AuthAccessTokenServiceImpl<Jwt, Cache> {
    pub jwt: Jwt,
    pub cache: Cache,
    pub config: AuthServiceConfig,
}

impl<Jwt, Cache> AuthAccessTokenService for AuthAccessTokenServiceImpl<Jwt, Cache>
where
    Jwt: JwtService,
    Cache: CacheService,
{
    fn issue(
        &self,
        user: &User,
        session_id: SessionId,
        refresh_token_hash: SessionRefreshTokenHash,
        mfa_verified: bool,
    ) -> anyhow::Result<AccessToken> {
        let auth = Authentication {
            user_id: user.id,
            session_id,
            refresh_token_hash,
            admin: user.admin,
            email_verified: user.email_verified,
            mfa_verified,
        };

        self.jwt
            .sign(Token::from(auth), self.config.access_token_ttl)
            .map(Into::into)
            .context("Failed to sign JWT")
    }

    fn verify(&self, access_token: &AccessToken) -> Option<Authentication> {
        self.jwt.verify(access_token).map(Token::into).ok()
    }

    async fn invalidate(&self, refresh_token_hash: SessionRefreshTokenHash) -> anyhow::Result<()> {
        self.cache
            .set(
                &access_token_invalidated_key(refresh_token_hash),
                &(),
                Some(self.config.access_token_ttl),
            )
            .await
            .with_context(|| {
                format!(
                    "Failed to invalidate access token by refresh token hash {refresh_token_hash}"
                )
            })
    }

    async fn is_invalidated(
        &self,
        refresh_token_hash: SessionRefreshTokenHash,
    ) -> anyhow::Result<bool> {
        self.cache
            .get::<()>(&access_token_invalidated_key(refresh_token_hash))
            .await
            .map(|x| x.is_some())
            .with_context(|| {
                format!(
                    "Failed to check whether the access token of refresh token hash \
                     {refresh_token_hash} has been invalidated"
                )
            })
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
struct Token {
    uid: UserId,
    sid: SessionId,
    rt: SessionRefreshTokenHash,
    data: TokenData,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
struct TokenData {
    admin: bool,
    email_verified: bool,
    /// Missing in tokens issued before administrators were required to
    /// authenticate with a second factor.
    #[serde(default)]
    mfa: bool,
}

impl From<Token> for Authentication {
    fn from(value: Token) -> Self {
        Self {
            user_id: value.uid,
            session_id: value.sid,
            refresh_token_hash: value.rt,
            admin: value.data.admin,
            email_verified: value.data.email_verified,
            mfa_verified: value.data.mfa,
        }
    }
}

impl From<Authentication> for Token {
    fn from(value: Authentication) -> Self {
        Self {
            uid: value.user_id,
            sid: value.session_id,
            rt: value.refresh_token_hash,
            data: TokenData {
                admin: value.admin,
                email_verified: value.email_verified,
                mfa: value.mfa_verified,
            },
        }
    }
}

fn access_token_invalidated_key(refresh_token_hash: SessionRefreshTokenHash) -> String {
    format!(
        "access_token_invalidated:{}",
        hex::encode(refresh_token_hash.0)
    )
}
