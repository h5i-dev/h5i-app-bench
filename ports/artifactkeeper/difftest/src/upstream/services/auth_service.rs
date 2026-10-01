//! Stub of `services/auth_service.rs`: `Claims` (the `impl Claims` block is
//! copied), and an `AuthService` whose credential checks read the kernel's
//! oracle tables, the trusted boundary both sides share.
use std::sync::Arc;

use artifactkeeper_kernel as k;
use uuid::Uuid;

use crate::error::{AppError, Result};
use crate::models::access_scope::AccessScope;
use crate::models::user::User;

/// `Claims`, without its serde attributes.
#[derive(Debug, Clone)]
pub struct Claims {
    pub sub: Uuid,
    pub username: String,
    pub email: String,
    pub is_admin: bool,
    pub allowed_repo_ids: Option<Vec<Uuid>>,
    pub iat: i64,
    pub iat_ms: Option<i64>,
    pub exp: i64,
    pub token_type: String,
    pub jti: Option<Uuid>,
    pub family_id: Option<Uuid>,
    pub scan_pull_repo: Option<String>,
    pub scopes: Option<Vec<String>>,
}

include!("auth_service_claims.rs");

#[derive(Debug)]
pub struct TokenPair {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: u64,
}

#[derive(Debug)]
pub struct ApiTokenValidation {
    pub user: User,
    pub scopes: Vec<String>,
    pub allowed_repo_ids: AccessScope,
    pub expires_at: Option<()>,
}

pub struct AuthService {
    db: sqlx::PgPool,
    oracle: Arc<k::trusted::Oracle>,
}

/// The message of the `ServiceUnavailable` the oracle's `AuthErr` maps to.
pub const OVERLOADED: &str = "Authentication service is overloaded";

pub fn uid(n: u64) -> Uuid {
    Uuid::from_u128(n as u128)
}

pub fn text(b: &[u8]) -> String {
    String::from_utf8(b.to_vec()).expect("oracle strings are UTF-8")
}

pub fn user(u: &k::User) -> User {
    User {
        id: uid(u.id),
        username: text(&u.username),
        email: text(&u.email),
        is_active: u.is_active,
        is_admin: u.is_admin,
        is_service_account: u.is_service_account,
        must_change_password: u.must_change_password,
    }
}

pub fn scope(s: &k::AccessScope) -> AccessScope {
    match s {
        k::AccessScope::Admin => AccessScope::Admin,
        k::AccessScope::Restricted(ids) => AccessScope::Restricted(ids.iter().map(|&i| uid(i)).collect()),
    }
}

fn error(e: k::trusted::AuthErr) -> AppError {
    match e {
        k::trusted::AuthErr::ServiceUnavailable => AppError::ServiceUnavailable(OVERLOADED.to_string()),
        k::trusted::AuthErr::PoolTimeout => AppError::Sqlx(sqlx::Error::PoolTimedOut),
        k::trusted::AuthErr::Other => AppError::Authentication("Invalid credentials".to_string()),
    }
}

impl AuthService {
    pub fn new(db: sqlx::PgPool, _config: Arc<crate::config::Config>) -> Self {
        AuthService { db, oracle: Arc::new(k::trusted::Oracle {
            jwt: vec![], api_tokens: vec![], passwords: vec![], base64: vec![], ip: vec![],
        }) }
    }

    pub fn with_oracle(db: sqlx::PgPool, oracle: Arc<k::trusted::Oracle>) -> Self {
        AuthService { db, oracle }
    }

    pub fn db(&self) -> &sqlx::PgPool {
        &self.db
    }

    pub async fn validate_access_token_async(&self, token: &str) -> Result<Claims> {
        match self.oracle.jwt.iter().find(|(t, _)| t == token.as_bytes()) {
            Some((_, c)) => Ok(Claims {
                sub: uid(c.sub),
                username: text(&c.username),
                email: text(&c.email),
                is_admin: c.is_admin,
                allowed_repo_ids: c.allowed_repo_ids.as_ref().map(|v| v.iter().map(|&i| uid(i)).collect()),
                iat: c.iat,
                iat_ms: c.iat_ms,
                exp: 0,
                token_type: "access".to_string(),
                jti: None,
                family_id: None,
                scan_pull_repo: None,
                scopes: c.scopes.as_ref().map(|v| v.iter().map(|s| text(s)).collect()),
            }),
            None => Err(AppError::Authentication("Invalid token".to_string())),
        }
    }

    pub async fn validate_api_token(&self, token: &str) -> Result<ApiTokenValidation> {
        match self.oracle.api_tokens.iter().find(|(t, _)| t == token.as_bytes()) {
            Some((_, Ok(v))) => Ok(ApiTokenValidation {
                user: user(&v.user),
                scopes: v.scopes.iter().map(|s| text(s)).collect(),
                allowed_repo_ids: scope(&v.allowed_repo_ids),
                expires_at: None,
            }),
            Some((_, Err(e))) => Err(error(*e)),
            None => Err(AppError::Authentication("Invalid API token".to_string())),
        }
    }

    pub async fn authenticate(&self, username: &str, password: &str) -> Result<(User, TokenPair)> {
        let hit = self.oracle.passwords.iter()
            .find(|(u, p, _)| u == username.as_bytes() && p == password.as_bytes());
        let pair = || TokenPair { access_token: String::new(), refresh_token: String::new(), expires_in: 0 };
        match hit {
            Some((_, _, Ok(u))) => Ok((user(u), pair())),
            Some((_, _, Err(e))) => Err(error(*e)),
            None => Err(AppError::Authentication("Invalid credentials".to_string())),
        }
    }
}
