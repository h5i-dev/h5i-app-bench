//! Turning an extracted credential into a principal: `api/middleware/auth.rs`
//! `try_resolve_auth_outcome`, `validate_api_token_with_scopes` and the
//! download-ticket path. `AuthService` itself is the oracle.
use crate::strs::*;
use crate::tables::{Db, Query};
use crate::http::{header_str, ExtractedToken, Request};
use crate::trusted::{AuthErr, Oracle};
use crate::paths::{extract_ticket_from_query, ticket_method_allowed, ticket_path_allowed};
use crate::token_scope::{from_claims, from_user};
use crate::{AuthExtension, Method};

/// `TokenAuthError`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TokenAuthError {
    Invalid,
    Overloaded,
}

/// `AuthOutcome`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum AuthOutcome {
    Resolved(AuthExtension),
    NoCredential,
    InvalidCredential,
    Overloaded,
}

/// A database write a request makes.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Write {
    /// `validate_download_ticket`'s `DELETE FROM download_tickets`.
    DeleteTicket(Vec<u8>),
    /// `admin_middleware`'s `PermissionDenied` audit entry for this user.
    AuditPermissionDenied { user_id: u64, path: Vec<u8>, method: Method },
    /// `create_permission`'s INSERT.
    InsertPermission(crate::tables::Permission),
}

/// `classify_token_validation_err`.
pub fn classify_token_validation_err(err: AuthErr) -> TokenAuthError {
    match err {
        AuthErr::ServiceUnavailable => TokenAuthError::Overloaded,
        AuthErr::PoolTimeout => TokenAuthError::Overloaded,
        AuthErr::Other => TokenAuthError::Invalid,
    }
}

/// `validate_api_token_with_scopes`.
pub fn validate_api_token_with_scopes(oracle: &Oracle, token: &[u8]) -> Result<AuthExtension, TokenAuthError> {
    let validation = match oracle.validate_api_token(token) {
        Ok(v) => v,
        Err(e) => return Err(classify_token_validation_err(e)),
    };
    Ok(AuthExtension {
        user_id: validation.user.id,
        username: validation.user.username,
        email: validation.user.email,
        is_admin: validation.user.is_admin,
        is_api_token: true,
        is_service_account: validation.user.is_service_account,
        scopes: Some(validation.scopes),
        allowed_repo_ids: validation.allowed_repo_ids,
        iat_ms: None,
    }
    .with_scope_gated_admin())
}

/// `decode_basic_credentials`.
pub fn decode_basic_credentials(oracle: &Oracle, encoded: &[u8]) -> Option<(Vec<u8>, Vec<u8>)> {
    let bytes = match oracle.base64_decode(encoded) {
        Some(b) => b,
        None => return None,
    };
    if !is_utf8(&bytes) {
        return None;
    }
    split_once(&bytes, b':')
}

/// `extract_bearer_credentials`.
pub fn extract_bearer_credentials(oracle: &Oracle, headers: &[(Vec<u8>, Vec<u8>)]) -> Option<(Vec<u8>, Vec<u8>)> {
    let v = match header_str(headers, b"authorization") {
        Some(v) => v,
        None => return None,
    };
    let token = match strip_prefix(&v, b"Bearer ") {
        Some(t) => t,
        None => match strip_prefix(&v, b"bearer ") {
            Some(t) => t,
            None => return None,
        },
    };
    decode_basic_credentials(oracle, &token)
}

fn resolve_bearer(oracle: &Oracle, token: &[u8]) -> AuthOutcome {
    if let Some(claims) = oracle.validate_access_token(token) {
        return AuthOutcome::Resolved(from_claims(&claims));
    }
    match validate_api_token_with_scopes(oracle, token) {
        Ok(ext) => return AuthOutcome::Resolved(ext),
        Err(TokenAuthError::Overloaded) => return AuthOutcome::Overloaded,
        Err(TokenAuthError::Invalid) => {}
    }
    if let Some((username, password)) = decode_basic_credentials(oracle, token) {
        match oracle.authenticate(&username, &password) {
            Ok(user) => return AuthOutcome::Resolved(from_user(&user)),
            Err(AuthErr::ServiceUnavailable) => return AuthOutcome::Overloaded,
            Err(_) => {}
        }
    }
    AuthOutcome::InvalidCredential
}

fn resolve_basic(oracle: &Oracle, encoded: &[u8], allow_basic_api_token: bool) -> AuthOutcome {
    let (username, password) = match decode_basic_credentials(oracle, encoded) {
        Some(c) => c,
        None => return AuthOutcome::InvalidCredential,
    };
    match oracle.authenticate(&username, &password) {
        Ok(user) => return AuthOutcome::Resolved(from_user(&user)),
        Err(AuthErr::ServiceUnavailable) => return AuthOutcome::Overloaded,
        Err(AuthErr::PoolTimeout) => return AuthOutcome::Overloaded,
        Err(AuthErr::Other) => {}
    }
    if let Some(claims) = oracle.validate_access_token(&password) {
        return AuthOutcome::Resolved(from_claims(&claims));
    }
    if !allow_basic_api_token {
        return AuthOutcome::InvalidCredential;
    }
    match validate_api_token_with_scopes(oracle, &password) {
        Ok(ext) => AuthOutcome::Resolved(ext),
        Err(TokenAuthError::Overloaded) => AuthOutcome::Overloaded,
        Err(TokenAuthError::Invalid) => AuthOutcome::InvalidCredential,
    }
}

/// `try_resolve_auth_outcome`.
pub fn try_resolve_auth_outcome(oracle: &Oracle, extracted: &ExtractedToken, allow_basic_api_token: bool) -> AuthOutcome {
    match extracted {
        ExtractedToken::Bearer(token) => resolve_bearer(oracle, token),
        ExtractedToken::ApiKey(token) => match validate_api_token_with_scopes(oracle, token) {
            Ok(ext) => AuthOutcome::Resolved(ext),
            Err(TokenAuthError::Overloaded) => AuthOutcome::Overloaded,
            Err(TokenAuthError::Invalid) => AuthOutcome::InvalidCredential,
        },
        ExtractedToken::Basic(encoded) => resolve_basic(oracle, encoded, allow_basic_api_token),
        ExtractedToken::None => AuthOutcome::NoCredential,
        ExtractedToken::Invalid => AuthOutcome::InvalidCredential,
    }
}

/// `AuthConfigService::validate_download_ticket`: deletes the live row and
/// returns its user and bound path.
pub fn validate_download_ticket(db: &Db, writes: &mut Vec<Write>, ticket: &[u8]) -> Option<(u64, Option<Vec<u8>>)> {
    if db.fails(Query::Ticket) {
        return None;
    }
    let mut i = 0;
    while i < db.tickets.len() {
        let t = &db.tickets[i];
        if bytes_eq(&t.ticket, ticket) && t.live {
            writes.push(Write::DeleteTicket(ticket.to_vec()));
            return Some((t.user_id, crate::paths::clone_path(&t.resource_path)));
        }
        i += 1;
    }
    None
}

/// `SELECT ... FROM users WHERE id = $1 AND is_active = true`.
pub fn active_user(db: &Db, user_id: u64) -> Option<crate::User> {
    let mut i = 0;
    while i < db.users.len() {
        if db.users[i].id == user_id && db.users[i].is_active {
            return Some(db.users[i].clone());
        }
        i += 1;
    }
    None
}

/// `try_resolve_ticket_auth`.
pub fn try_resolve_ticket_auth(db: &Db, writes: &mut Vec<Write>, ticket: &[u8], method: Method,
                               request_path: &[u8]) -> Option<AuthExtension> {
    if !ticket_method_allowed(method) {
        return None;
    }
    let (user_id, resource_path) = match validate_download_ticket(db, writes, ticket) {
        Some(r) => r,
        None => return None,
    };
    if !ticket_path_allowed(&resource_path, request_path) {
        return None;
    }
    if db.fails(Query::TicketUser) {
        return None;
    }
    let user = match active_user(db, user_id) {
        Some(u) => u,
        None => return None,
    };
    let mut ext = from_user(&user);
    ext.is_admin = false;
    ext.is_api_token = true;
    ext.scopes = Some(Vec::new());
    Some(ext)
}

/// `extract_ticket_request_parts` then `try_resolve_ticket_for_parts`.
pub fn try_ticket(db: &Db, writes: &mut Vec<Write>, req: &Request) -> Option<AuthExtension> {
    let ticket = match extract_ticket_from_query(&req.query) {
        Some(t) => t,
        None => return None,
    };
    try_resolve_ticket_auth(db, writes, &ticket, req.method, &req.path)
}

/// `principal_must_change_password`: a failed query or a missing or
/// inactive user reads as `false`.
pub fn principal_must_change_password(db: &Db, user_id: u64) -> bool {
    if db.fails(Query::MustChangePassword) {
        return false;
    }
    match active_user(db, user_id) {
        Some(u) => u.must_change_password,
        None => false,
    }
}
