//! The middlewares, in upstream's order: `api/middleware/auth.rs`
//! `auth_middleware`, `optional_auth_middleware`, `admin_middleware`,
//! `repo_visibility_middleware`, and `api/middleware/guest_access.rs`
//! `guest_access_guard`. What the handler receives is `Outcome::Next`;
//! every early response is `Outcome::Respond`.
use crate::strs::*;
use crate::tables::{Db, Query};
use crate::http::*;
use crate::net::IpAddr;
use crate::trusted::{AuthErr, Oracle};
use crate::paths::*;
use crate::permission::{check_anonymous_repository_action, check_permission, check_repository_action,
                        has_any_rules_for_target};
use crate::resolve::*;
use crate::token_scope::{from_claims, from_user};
use crate::{AuthExtension, Visibility};

/// The 401 messages of `auth_middleware` and `admin_middleware`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Deny {
    InvalidOrExpiredToken,
    InvalidOrExpiredApiToken,
    InvalidBasic,
    InvalidCredentials,
    MissingHeader,
    InvalidHeaderFormat,
    InvalidTicket,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Response {
    /// `not_found_response`: 404 "Repository not found".
    NotFound,
    /// `challenge_unauthorized_response(challenge_basic)`.
    Unauthorized { challenge_basic: bool },
    /// `service_unavailable_response`: 503 with `Retry-After: 1`.
    ServiceUnavailable,
    /// 503 "permission service temporarily unavailable".
    PermissionServiceUnavailable,
    /// `auth_middleware`: 503 carrying `authenticate`'s message.
    AuthServiceUnavailable,
    /// `forbidden_repo_response`.
    ForbiddenRepo,
    /// `forbidden_permission_response`.
    ForbiddenPermission,
    /// `csrf_forbidden_response`.
    CsrfForbidden,
    /// `must_change_password_response`: 428.
    MustChangePassword,
    /// `(StatusCode::UNAUTHORIZED, message)`.
    Plain401(Deny),
    /// 403 "Admin access required".
    AdminRequired,
    /// `guest_access.rs` `unauthorized_response(for_browser)`.
    GuestUnauthorized { for_browser: bool },
    /// `oci_unauthorized_response(base_url)`.
    OciUnauthorized,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Outcome {
    /// The request reaches the next layer with this `AuthExtension`, and
    /// `DownloadTicketAuth` when `ticket`.
    Next { auth: Option<AuthExtension>, ticket: bool },
    Respond(Response),
}

fn respond(writes: Vec<Write>, r: Response) -> (Vec<Write>, Outcome) {
    (writes, Outcome::Respond(r))
}

/// `csrf_guard`.
pub fn csrf_guard(req: &Request) -> Option<Response> {
    if violates_csrf_contract(req.method, &req.headers) { Some(Response::CsrfForbidden) } else { None }
}

/// `auth_middleware`'s `header_result`; `Err(Ok(msg))` is a 401 message,
/// `Err(Err(r))` an early response.
fn header_result(oracle: &Oracle, extracted: &ExtractedToken) -> Result<AuthExtension, Result<Deny, Response>> {
    match extracted {
        ExtractedToken::Bearer(token) => {
            if let Some(claims) = oracle.validate_access_token(token) {
                return Ok(from_claims(&claims));
            }
            match validate_api_token_with_scopes(oracle, token) {
                Ok(ext) => Ok(ext),
                Err(TokenAuthError::Overloaded) => Err(Err(Response::ServiceUnavailable)),
                Err(TokenAuthError::Invalid) => Err(Ok(Deny::InvalidOrExpiredToken)),
            }
        }
        ExtractedToken::ApiKey(token) => match validate_api_token_with_scopes(oracle, token) {
            Ok(ext) => Ok(ext),
            Err(TokenAuthError::Overloaded) => Err(Err(Response::ServiceUnavailable)),
            Err(TokenAuthError::Invalid) => Err(Ok(Deny::InvalidOrExpiredApiToken)),
        },
        ExtractedToken::Basic(encoded) => match decode_basic_credentials(oracle, encoded) {
            None => Err(Ok(Deny::InvalidBasic)),
            Some((username, password)) => match oracle.authenticate(&username, &password) {
                Ok(user) => Ok(from_user(&user)),
                Err(AuthErr::ServiceUnavailable) => Err(Err(Response::AuthServiceUnavailable)),
                Err(AuthErr::PoolTimeout) => Err(Err(Response::ServiceUnavailable)),
                Err(AuthErr::Other) => match oracle.validate_access_token(&password) {
                    Some(claims) => Ok(from_claims(&claims)),
                    None => Err(Ok(Deny::InvalidCredentials)),
                },
            },
        },
        ExtractedToken::None => Err(Ok(Deny::MissingHeader)),
        ExtractedToken::Invalid => Err(Ok(Deny::InvalidHeaderFormat)),
    }
}

/// `auth_middleware`. The password-change gate reads `OriginalUri`, which
/// is the request path outside a nested router.
pub fn auth_middleware(db: &Db, oracle: &Oracle, req: &Request) -> (Vec<Write>, Outcome) {
    let mut writes = Vec::new();
    if let Some(refusal) = csrf_guard(req) {
        return respond(writes, refusal);
    }
    let extracted = extract_token(req);
    let had_header_credentials = !matches!(extracted, ExtractedToken::None);
    let header_error = match header_result(oracle, &extracted) {
        Ok(ext) => {
            if !path_exempt_from_password_change(&req.path) && principal_must_change_password(db, ext.user_id) {
                return respond(writes, Response::MustChangePassword);
            }
            return (writes, Outcome::Next { auth: Some(ext), ticket: false });
        }
        Err(Err(r)) => return respond(writes, r),
        Err(Ok(msg)) => msg,
    };
    let ticket_parts = extract_ticket_from_query(&req.query);
    if let Some(ticket) = &ticket_parts {
        if let Some(ext) = try_resolve_ticket_auth(db, &mut writes, ticket, req.method, &req.path) {
            return (writes, Outcome::Next { auth: Some(ext), ticket: true });
        }
    }
    let has_ticket = match &ticket_parts {
        Some(_) => true,
        None => false,
    };
    let message = if !had_header_credentials && has_ticket { Deny::InvalidTicket } else { header_error };
    respond(writes, Response::Plain401(message))
}

/// `optional_auth_middleware`.
pub fn optional_auth_middleware(db: &Db, oracle: &Oracle, req: &Request) -> (Vec<Write>, Outcome) {
    let mut writes = Vec::new();
    if let Some(refusal) = csrf_guard(req) {
        return respond(writes, refusal);
    }
    let extracted = extract_token(req);
    let outcome = try_resolve_auth_outcome(oracle, &extracted, false);
    if matches!(outcome, AuthOutcome::Overloaded) {
        return respond(writes, Response::ServiceUnavailable);
    }
    let credential_invalid = matches!(outcome, AuthOutcome::InvalidCredential);
    let mut auth_ext = match outcome {
        AuthOutcome::Resolved(ext) => Some(ext),
        _ => None,
    };
    let mut authed_via_ticket = false;
    if auth_ext.is_none() {
        if let Some(ext) = try_ticket(db, &mut writes, req) {
            auth_ext = Some(ext);
            authed_via_ticket = true;
        }
    }
    if credential_invalid && auth_ext.is_none() {
        return respond(writes, Response::Unauthorized { challenge_basic: !is_browser_request(&req.headers) });
    }
    (writes, Outcome::Next { auth: auth_ext, ticket: authed_via_ticket })
}

/// `admin_middleware`.
pub fn admin_middleware(db: &Db, oracle: &Oracle, req: &Request) -> (Vec<Write>, Outcome) {
    let mut writes = Vec::new();
    if let Some(refusal) = csrf_guard(req) {
        return respond(writes, refusal);
    }
    let extracted = extract_token(req);
    if let ExtractedToken::Basic(encoded) = &extracted {
        if decode_basic_credentials(oracle, encoded).is_none() {
            return respond(writes, Response::Plain401(Deny::InvalidBasic));
        }
    }
    let auth_ext = match try_resolve_auth_outcome(oracle, &extracted, false) {
        AuthOutcome::Resolved(ext) => ext,
        AuthOutcome::Overloaded => return respond(writes, Response::ServiceUnavailable),
        _ => {
            let msg = match extracted {
                ExtractedToken::Bearer(_) => Deny::InvalidOrExpiredToken,
                ExtractedToken::ApiKey(_) => Deny::InvalidOrExpiredApiToken,
                ExtractedToken::Basic(_) => Deny::InvalidCredentials,
                ExtractedToken::None => Deny::MissingHeader,
                ExtractedToken::Invalid => Deny::InvalidHeaderFormat,
            };
            return respond(writes, Response::Plain401(msg));
        }
    };
    if !auth_ext.is_admin {
        writes.push(Write::AuditPermissionDenied {
            user_id: auth_ext.user_id,
            path: req.path.clone(),
            method: req.method,
        });
        return respond(writes, Response::AdminRequired);
    }
    if !path_exempt_from_password_change(&req.path) && principal_must_change_password(db, auth_ext.user_id) {
        return respond(writes, Response::MustChangePassword);
    }
    (writes, Outcome::Next { auth: Some(auth_ext), ticket: false })
}

/// `guest_access.rs` `guest_access_guard`. A passing request reaches the
/// inner layers with no extension of its own.
pub fn guest_access_guard(guest_access_enabled: bool, oracle: &Oracle, req: &Request) -> Outcome {
    if guest_access_enabled {
        return Outcome::Next { auth: None, ticket: false };
    }
    if is_allowlisted(&req.path) {
        return Outcome::Next { auth: None, ticket: false };
    }
    let oci = is_oci_v2_path(&req.path);
    let extracted = extract_visibility_token(req);
    let outcome = try_resolve_auth_outcome(oracle, &extracted, true);
    let for_browser = is_browser_request(&req.headers);
    // `guard_short_circuit`.
    match outcome {
        AuthOutcome::Resolved(_) => Outcome::Next { auth: None, ticket: false },
        AuthOutcome::Overloaded => Outcome::Respond(Response::ServiceUnavailable),
        _ => {
            if oci {
                Outcome::Respond(Response::OciUnauthorized)
            } else {
                Outcome::Respond(Response::GuestUnauthorized { for_browser })
            }
        }
    }
}

/// The repository row `repo_visibility_middleware` resolves: `(id,
/// visibility)`, a visibility that does not decode failing closed to
/// private. A failed query reads as no row.
pub fn lookup_repo(db: &Db, repo_key: &[u8]) -> Option<(u64, Visibility)> {
    if db.fails(Query::RepoByKey) {
        return None;
    }
    let mut i = 0;
    while i < db.repositories.len() {
        let r = &db.repositories[i];
        if bytes_eq(&r.key, repo_key) {
            let v = match r.visibility {
                Some(v) => v,
                None => Visibility::Private,
            };
            return Some((r.id, v));
        }
        i += 1;
    }
    None
}

/// The role-assignment `EXISTS` of the rules-less private branch.
pub fn role_grant_exists(db: &Db, user_id: u64, repo_id: u64) -> Result<bool, ()> {
    if db.fails(Query::RoleGrant) {
        return Err(());
    }
    let mut i = 0;
    while i < db.role_assignments.len() {
        let ra = &db.role_assignments[i];
        let scoped = match ra.repository_id {
            Some(r) => r == repo_id,
            None => true,
        };
        if ra.user_id == user_id && scoped {
            return Ok(true);
        }
        i += 1;
    }
    Ok(false)
}

/// The no-repository branch.
fn no_repo(oracle: &Oracle, req: &Request) -> Response {
    let extracted = extract_visibility_token(req);
    let outcome = try_resolve_auth_outcome(oracle, &extracted, true);
    match outcome {
        AuthOutcome::Overloaded => Response::ServiceUnavailable,
        AuthOutcome::InvalidCredential => Response::Unauthorized { challenge_basic: true },
        AuthOutcome::NoCredential => Response::Unauthorized { challenge_basic: true },
        AuthOutcome::Resolved(_) => Response::NotFound,
    }
}

/// The permission arm for a non-admin caller: `None` lets the request
/// through.
fn permission_arm(db: &Db, client_ip: Option<IpAddr>, ext: &AuthExtension, repo_id: u64, visibility: Visibility,
                  req: &Request, is_write: bool, non_mutating_post: bool) -> Option<Response> {
    let action = if non_mutating_post { b"read".to_vec() } else { action_for_method(req.method) };
    if is_write && !non_mutating_post {
        return match check_repository_action(db, client_ip, ext.user_id, repo_id, &action, false) {
            Ok(true) => None,
            Ok(false) => Some(Response::ForbiddenPermission),
            Err(_) => Some(Response::ServiceUnavailable),
        };
    }
    let has_rules = match has_any_rules_for_target(db, b"repository", repo_id) {
        Ok(v) => v,
        Err(_) => return Some(Response::PermissionServiceUnavailable),
    };
    if has_rules {
        if !authenticated_read_satisfies_acl(visibility, &action) {
            let allowed = unwrap_false(check_permission(db, client_ip, ext.user_id, b"repository", repo_id, &action, false))
                || unwrap_false(check_permission(db, client_ip, ext.user_id, b"repository", repo_id, b"admin", false))
                || unwrap_false(check_repository_action(db, client_ip, ext.user_id, repo_id, &action, false));
            if !allowed {
                return Some(Response::NotFound);
            }
        }
        None
    } else if !visibility.allows_authenticated_read() {
        match role_grant_exists(db, ext.user_id, repo_id) {
            Ok(true) => None,
            Ok(false) => Some(Response::NotFound),
            Err(_) => Some(Response::ServiceUnavailable),
        }
    } else {
        None
    }
}

/// `.unwrap_or(false)`.
fn unwrap_false<E>(r: Result<bool, E>) -> bool {
    match r {
        Ok(b) => b,
        Err(_) => false,
    }
}

/// `repo_visibility_middleware`. `client_ip` is `current_client_ip()`, set
/// by the outer `client_ip_context_middleware`. The repository caches are
/// left out: the kernel answers as a cache miss.
pub fn repo_visibility_middleware(db: &Db, oracle: &Oracle, client_ip: Option<IpAddr>,
                                  req: &Request) -> (Vec<Write>, Outcome) {
    let mut writes = Vec::new();
    let repo_key = extract_repo_key(&req.path);
    if repo_key.len() == 0 {
        return respond(writes, Response::NotFound);
    }
    let (repo_id, visibility) = match lookup_repo(db, &repo_key) {
        Some(r) => r,
        None => return respond(writes, no_repo(oracle, req)),
    };
    let non_mutating_post = is_non_mutating_format_post(&req.path);
    let anonymous_readable_post = req.method == crate::Method::Post && is_anonymous_readable_format_post(&req.path);
    let is_write = is_write_method(req.method) && !anonymous_readable_post;

    let extracted = extract_visibility_token(req);
    let outcome = try_resolve_auth_outcome(oracle, &extracted, true);
    if matches!(outcome, AuthOutcome::Overloaded) {
        return respond(writes, Response::ServiceUnavailable);
    }
    let credential_invalid = matches!(outcome, AuthOutcome::InvalidCredential);
    let mut auth_ext = match outcome {
        AuthOutcome::Resolved(ext) => Some(ext),
        _ => None,
    };
    let mut authed_via_ticket = false;
    if auth_ext.is_none() {
        if let Some(ext) = try_ticket(db, &mut writes, req) {
            auth_ext = Some(ext);
            authed_via_ticket = true;
        }
    }
    if credential_invalid && auth_ext.is_none() {
        return respond(writes, Response::Unauthorized { challenge_basic: true });
    }
    let has_write_auth = auth_ext.is_some() && !authed_via_ticket;
    if is_write && !has_write_auth {
        return respond(writes, Response::Unauthorized { challenge_basic: true });
    }
    if !should_allow_repo_access(visibility, auth_ext.is_some()) {
        let anonymous_read_granted = auth_ext.is_none()
            && unwrap_false(check_anonymous_repository_action(db, client_ip, repo_id, b"read"));
        if !anonymous_read_granted {
            return respond(writes, Response::Unauthorized { challenge_basic: true });
        }
    }
    let scope_gate_action = if anonymous_readable_post { b"read".to_vec() } else { action_for_method(req.method) };
    if let Some(ext) = &auth_ext {
        if !public_read_satisfies_acl(visibility, &scope_gate_action) && !ext.can_access_repo(repo_id) {
            if !visibility.allows_anonymous_read() && (bytes_eq(&scope_gate_action, b"read") || non_mutating_post) {
                return respond(writes, Response::NotFound);
            }
            return respond(writes, Response::ForbiddenRepo);
        }
        if !ext.is_admin {
            if let Some(r) = permission_arm(db, client_ip, ext, repo_id, visibility, req, is_write, non_mutating_post) {
                return respond(writes, r);
            }
        }
    }
    (writes, Outcome::Next { auth: auth_ext, ticket: authed_via_ticket })
}
