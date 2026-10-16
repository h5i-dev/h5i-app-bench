//! artifact-keeper's repository access decisions
//! (artifact-keeper/artifact-keeper @ 7c42891, `backend/src/`) in the Aeneas
//! subset. Each function follows the upstream function of the same name;
//! ../DEVIATIONS.md lists the differences. Credential verification (JWT,
//! API-token and password checks), base64 and IP-address parsing are the
//! trusted input, as oracle tables in `trusted.rs`. The database is a
//! snapshot of the tables the queries read (`tables.rs`).

// Module names avoid the names of local variables: Aeneas emits both as
// Lean identifiers in one namespace.
pub mod handlers;
pub mod http;
pub mod middleware;
pub mod net;
pub mod paths;
pub mod permission;
pub mod resolve;
pub mod strs;
pub mod tables;
pub mod token_scope;
pub mod trusted;

/// `http::Method`; `Other` is any extension method.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Method {
    Get,
    Head,
    Post,
    Put,
    Delete,
    Patch,
    Options,
    Other,
}

/// `models/repository.rs` `RepositoryVisibility`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Visibility {
    Public,
    Internal,
    Private,
}

impl Visibility {
    pub fn allows_anonymous_read(&self) -> bool {
        matches!(self, Visibility::Public)
    }

    pub fn allows_authenticated_read(&self) -> bool {
        matches!(self, Visibility::Public | Visibility::Internal)
    }
}

/// `error.rs` `AppError`, the variants these paths produce; messages dropped.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AppError {
    Authentication,
    Authorization,
    Validation,
    Database,
    Conflict,
}

/// `models/user.rs` `User`, the fields authorization reads.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct User {
    pub id: u64,
    pub username: Vec<u8>,
    pub email: Vec<u8>,
    pub is_active: bool,
    pub is_admin: bool,
    pub is_service_account: bool,
    pub must_change_password: bool,
}

/// `services/auth_service.rs` `Claims`, verified; the fields read here.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Claims {
    pub sub: u64,
    pub username: Vec<u8>,
    pub email: Vec<u8>,
    pub is_admin: bool,
    pub allowed_repo_ids: Option<Vec<u64>>,
    pub iat: i64,
    pub iat_ms: Option<i64>,
    pub scopes: Option<Vec<Vec<u8>>>,
}

/// `Option::clone` on the kernel's optional fields; Aeneas has no model of
/// it, so the derived `Clone` impls stay out of the extracted code.
pub fn clone_opt_ids(v: &Option<Vec<u64>>) -> Option<Vec<u64>> {
    match v {
        Some(x) => Some(x.clone()),
        None => None,
    }
}

pub fn clone_opt_i64(v: &Option<i64>) -> Option<i64> {
    match v {
        Some(x) => Some(*x),
        None => None,
    }
}

pub fn clone_opt_scopes(s: &Option<Vec<Vec<u8>>>) -> Option<Vec<Vec<u8>>> {
    match s {
        Some(v) => Some(v.clone()),
        None => None,
    }
}

impl Claims {
    pub fn duplicate(&self) -> Claims {
        Claims {
            sub: self.sub,
            username: self.username.clone(),
            email: self.email.clone(),
            is_admin: self.is_admin,
            allowed_repo_ids: clone_opt_ids(&self.allowed_repo_ids),
            iat: self.iat,
            iat_ms: clone_opt_i64(&self.iat_ms),
            scopes: clone_opt_scopes(&self.scopes),
        }
    }

    /// `self.iat_ms.unwrap_or_else(|| self.iat.saturating_mul(1000))`.
    pub fn effective_iat_ms(&self) -> i64 {
        match self.iat_ms {
            Some(ms) => ms,
            None => {
                if self.iat > i64::MAX / 1000 {
                    i64::MAX
                } else if self.iat < i64::MIN / 1000 {
                    i64::MIN
                } else {
                    self.iat * 1000
                }
            }
        }
    }
}

/// `models/access_scope.rs` `AccessScope`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum AccessScope {
    Admin,
    Restricted(Vec<u64>),
}

impl AccessScope {
    pub fn grants(&self, repo_id: u64) -> bool {
        match self {
            AccessScope::Admin => true,
            AccessScope::Restricted(ids) => strs::contains_id(ids, repo_id),
        }
    }

    /// `From<Option<Vec<Uuid>>>`.
    pub fn from_option(value: &Option<Vec<u64>>) -> AccessScope {
        match value {
            None => AccessScope::Admin,
            Some(ids) => AccessScope::Restricted(ids.clone()),
        }
    }
}

/// `api/middleware/auth.rs` `AuthExtension`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct AuthExtension {
    pub user_id: u64,
    pub username: Vec<u8>,
    pub email: Vec<u8>,
    pub is_admin: bool,
    pub is_api_token: bool,
    pub is_service_account: bool,
    pub scopes: Option<Vec<Vec<u8>>>,
    pub allowed_repo_ids: AccessScope,
    pub iat_ms: Option<i64>,
}

impl AuthExtension {
    pub fn duplicate(&self) -> AuthExtension {
        AuthExtension {
            user_id: self.user_id,
            username: self.username.clone(),
            email: self.email.clone(),
            is_admin: self.is_admin,
            is_api_token: self.is_api_token,
            is_service_account: self.is_service_account,
            scopes: clone_opt_scopes(&self.scopes),
            allowed_repo_ids: self.allowed_repo_ids.clone(),
            iat_ms: clone_opt_i64(&self.iat_ms),
        }
    }
}
