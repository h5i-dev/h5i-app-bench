//! Token scopes: `services/token_service.rs` and the scope methods of
//! `api/middleware/auth.rs` `AuthExtension`.
use crate::strs::{any_eq, bytes_eq, split_once};
use crate::{AccessScope, AppError, AuthExtension, Claims, User};

/// `ALLOWED_SCOPES.contains(&scope)`.
pub fn is_allowed_scope(s: &[u8]) -> bool {
    bytes_eq(s, b"read:artifacts")
        || bytes_eq(s, b"write:artifacts")
        || bytes_eq(s, b"delete:artifacts")
        || bytes_eq(s, b"promote:artifacts")
        || bytes_eq(s, b"read:repositories")
        || bytes_eq(s, b"write:repositories")
        || bytes_eq(s, b"delete:repositories")
        || bytes_eq(s, b"read:users")
        || bytes_eq(s, b"write:users")
        || bytes_eq(s, b"trigger:sync")
        || bytes_eq(s, b"write:findings")
        || bytes_eq(s, b"admin")
        || bytes_eq(s, b"*")
}

/// `ADMIN_ONLY_SCOPES.contains(&scope)`.
pub fn is_admin_only_scope(s: &[u8]) -> bool {
    bytes_eq(s, b"admin")
        || bytes_eq(s, b"*")
        || bytes_eq(s, b"delete:artifacts")
        || bytes_eq(s, b"delete:repositories")
        || bytes_eq(s, b"promote:artifacts")
        || bytes_eq(s, b"trigger:sync")
        || bytes_eq(s, b"write:users")
        || bytes_eq(s, b"write:findings")
}

/// `validate_scopes_pure`: the error carries the first invalid scope.
pub fn validate_scopes_pure(scopes: &[Vec<u8>]) -> Result<(), Vec<u8>> {
    let mut i = 0;
    while i < scopes.len() {
        if !is_allowed_scope(&scopes[i]) {
            return Err(scopes[i].clone());
        }
        i += 1;
    }
    Ok(())
}

/// `enforce_admin_only_scopes`: the error carries the first admin-only scope.
pub fn enforce_admin_only_scopes(scopes: &[Vec<u8>], caller_is_admin: bool) -> Result<(), Vec<u8>> {
    if caller_is_admin {
        return Ok(());
    }
    let mut i = 0;
    while i < scopes.len() {
        if is_admin_only_scope(&scopes[i]) {
            return Err(scopes[i].clone());
        }
        i += 1;
    }
    Ok(())
}

/// `scopes_grant_access`.
pub fn scopes_grant_access(scopes: &[Vec<u8>], required_scope: &[u8]) -> bool {
    let has_admin_wildcard = any_eq(scopes, b"*") || any_eq(scopes, b"admin");
    if any_eq(scopes, required_scope) || has_admin_wildcard {
        return true;
    }
    match split_once(required_scope, b':') {
        Some((parent, _resource)) => parent.len() > 0 && any_eq(scopes, &parent),
        None => false,
    }
}

impl AuthExtension {
    pub fn has_scope(&self, scope: &[u8]) -> bool {
        match &self.scopes {
            None => true,
            Some(scopes) => scopes_grant_access(scopes, scope),
        }
    }

    pub fn access_scope(&self) -> AccessScope {
        self.allowed_repo_ids.clone()
    }

    pub fn can_access_repo(&self, repo_id: u64) -> bool {
        self.access_scope().grants(repo_id)
    }

    pub fn require_scope(&self, scope: &[u8]) -> Result<(), AppError> {
        if self.has_scope(scope) { Ok(()) } else { Err(AppError::Authorization) }
    }

    pub fn enforce_mint_ceiling(&self, requested: &[Vec<u8>]) -> Result<(), AppError> {
        if self.is_admin {
            return Ok(());
        }
        let mut i = 0;
        while i < requested.len() {
            if !self.has_scope(&requested[i]) {
                return Err(AppError::Authorization);
            }
            i += 1;
        }
        Ok(())
    }

    pub fn mint_repo_ceiling(&self, requests_restriction: bool) -> Result<Option<Vec<u64>>, AppError> {
        match &self.allowed_repo_ids {
            AccessScope::Admin => Ok(None),
            AccessScope::Restricted(ids) => {
                if requests_restriction {
                    Err(AppError::Authorization)
                } else if ids.len() == 0 {
                    Err(AppError::Authorization)
                } else {
                    Ok(Some(ids.clone()))
                }
            }
        }
    }

    pub fn with_scope_gated_admin(mut self) -> AuthExtension {
        self.is_admin = self.is_admin && self.has_scope(b"admin");
        self
    }

    pub fn require_admin(&self) -> Result<(), AppError> {
        if self.is_admin { Ok(()) } else { Err(AppError::Authorization) }
    }

    pub fn require_self_or_admin(&self, target_user_id: u64) -> Result<(), AppError> {
        if self.user_id == target_user_id || self.is_admin { Ok(()) } else { Err(AppError::Authorization) }
    }
}

/// `impl From<Claims> for AuthExtension`.
pub fn from_claims(claims: &Claims) -> AuthExtension {
    let iat_ms = Some(claims.effective_iat_ms());
    AuthExtension {
        user_id: claims.sub,
        username: claims.username.clone(),
        email: claims.email.clone(),
        is_admin: claims.is_admin,
        is_api_token: false,
        is_service_account: false,
        scopes: crate::clone_opt_scopes(&claims.scopes),
        allowed_repo_ids: AccessScope::from_option(&claims.allowed_repo_ids),
        iat_ms,
    }
    .with_scope_gated_admin()
}

/// `impl From<User> for AuthExtension`.
pub fn from_user(user: &User) -> AuthExtension {
    AuthExtension {
        user_id: user.id,
        username: user.username.clone(),
        email: user.email.clone(),
        is_admin: user.is_admin,
        is_api_token: false,
        is_service_account: user.is_service_account,
        scopes: None,
        allowed_repo_ids: AccessScope::Admin,
        iat_ms: None,
    }
}
