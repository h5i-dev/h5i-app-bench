//! `src/auth.rs`: `AuthHeader`, `authenticate` (session cookie, then API
//! token), `ensure_not_locked`, the session epoch, `AuthCheck::check` with
//! `endpoint_scope_matches` and `crate_scope_matches`;
//! `controllers/util.rs` `verify_origin`; and
//! `models/token.rs` `ApiToken::find_by_api_token`'s filter.
//!
//! Tables are lists. A token row keeps its plaintext `secret`: upstream
//! stores and compares SHA-256 hashes, and the kernel assumes the hash is
//! injective (DEVIATIONS.md). Time is one integer clock (`now`).

use crate::bytes::{eq, eq_ignore_ascii_case, starts_with, sub};
use crate::scopes::{EndpointScope, any_scope_matches, contains_scope};

/// The `users` columns the decisions read.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct User {
    pub id: i32,
    /// `account_lock_reason.is_some()`.
    pub lock_reason: bool,
    /// `account_lock_until`.
    pub lock_until: Option<i64>,
    pub session_epoch: i32,
}

/// An `api_tokens` row.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ApiToken {
    pub id: i32,
    pub user_id: i32,
    /// The plaintext the row's hash was computed from.
    pub secret: Vec<u8>,
    pub revoked: bool,
    pub expired_at: Option<i64>,
    /// `None` (legacy) or crate scope patterns.
    pub crate_scopes: Option<Vec<Vec<u8>>>,
    /// `None` (legacy) or endpoint scopes.
    pub endpoint_scopes: Option<Vec<EndpointScope>>,
}

/// The session cookie's `epoch` entry.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Epoch {
    /// No entry: epoch 0 (older cookies).
    Absent,
    /// An entry that does not parse as `i32`.
    Invalid,
    Value(i32),
}

/// What authentication reads from a request.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Request {
    /// The `Origin` header values.
    pub origins: Vec<u64>,
    /// The session's `user_id`, if present and an `i32`.
    pub session_uid: Option<i32>,
    pub session_epoch: Epoch,
    /// The `Authorization` header's bytes.
    pub authorization: Option<Vec<u8>>,
}

/// The failures, each with upstream's status: `Forbidden` (403) unless noted.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AuthError {
    /// `verify_origin`: an `Origin` outside `allowed_origins`.
    InvalidOrigin,
    /// `500`: the session's or token's user is not in the table.
    UserNotFound,
    /// `ensure_not_locked`.
    Locked,
    /// The session epoch does not parse.
    BadEpoch,
    /// The session epoch is not the user's current one.
    StaleSession,
    /// `401`: the header has bytes outside visible ASCII.
    HeaderNotAscii,
    /// `401`: a scheme other than `Bearer`.
    HeaderScheme,
    /// `InsecurelyGeneratedTokenRevoked`: no `cio` prefix.
    InsecureToken,
    /// No live token with this secret.
    TokenNotFound,
    /// Neither a session nor a header.
    NoAuth,
    /// `AuthCheck::check`: tokens not allowed here.
    TokenDisallowed,
    EndpointScopeMismatch,
    CrateScopeMismatch,
}

/// `Authentication`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Authentication {
    Cookie(User),
    Token(ApiToken, User),
}

/// `allowed_origins.contains(value)`.
pub fn contains_u64(xs: &[u64], x: u64) -> bool {
    let mut j = 0;
    while j < xs.len() {
        if xs[j] == x {
            return true;
        }
        j += 1;
    }
    false
}

/// `verify_origin`: no `Origin` value outside `allowed_origins`.
pub fn origins_ok(origins: &[u64], allowed: &[u64]) -> bool {
    let mut i = 0;
    while i < origins.len() {
        if !contains_u64(allowed, origins[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `User::find`.
pub fn find_user(users: &[User], id: i32) -> Option<User> {
    let mut i = 0;
    while i < users.len() {
        if users[i].id == id {
            return Some(users[i]);
        }
        i += 1;
    }
    None
}

/// `ensure_not_locked`: a lock reason locks the account until
/// `account_lock_until`, or forever if there is none.
pub fn is_locked(u: &User, now: i64) -> bool {
    if !u.lock_reason {
        return false;
    }
    match u.lock_until {
        None => true,
        Some(until) => until > now,
    }
}

/// `HeaderValue::to_str`'s byte class: visible ASCII and tab.
pub fn visible(b: u8) -> bool {
    (b >= 32 && b < 127) || b == b'\t'
}

/// `u8::is_ascii_whitespace`.
pub fn ascii_ws(b: u8) -> bool {
    b == b' ' || b == b'\t' || b == b'\n' || b == 0x0c || b == b'\r'
}

/// `"Bearer"`.
pub const BEARER: [u8; 6] = [b'B', b'e', b'a', b'r', b'e', b'r'];

/// `AuthHeader::optional_from_request_parts` on a present header: visible
/// ASCII, `split_once(' ')` into scheme and token (no space: no scheme),
/// scheme `Bearer` in any case or none, the token `trim_ascii`'d.
pub fn parse_auth_header(h: &[u8]) -> Result<Vec<u8>, AuthError> {
    let mut i = 0;
    while i < h.len() {
        if !visible(h[i]) {
            return Err(AuthError::HeaderNotAscii);
        }
        i += 1;
    }
    let mut sp = h.len();
    let mut j = 0;
    while j < h.len() {
        if h[j] == b' ' {
            sp = j;
            break;
        }
        j += 1;
    }
    let (scheme, token) = if sp < h.len() {
        (sub(h, 0, sp), sub(h, sp + 1, h.len()))
    } else {
        (Vec::new(), sub(h, 0, h.len()))
    };
    if !(eq_ignore_ascii_case(&scheme, &BEARER) || scheme.len() == 0) {
        return Err(AuthError::HeaderScheme);
    }
    let mut lo = 0;
    while lo < token.len() && ascii_ws(token[lo]) {
        lo += 1;
    }
    let mut hi = token.len();
    while hi > lo && ascii_ws(token[hi - 1]) {
        hi -= 1;
    }
    Ok(sub(&token, lo, hi))
}

/// `TOKEN_PREFIX`.
pub const TOKEN_PREFIX: [u8; 3] = [b'c', b'i', b'o'];

/// `find_by_api_token`'s filter: not revoked, not expired, same secret.
pub fn token_live(t: &ApiToken, secret: &[u8], now: i64) -> bool {
    if t.revoked {
        return false;
    }
    let unexpired = match t.expired_at {
        None => true,
        Some(e) => e > now,
    };
    unexpired && eq(&t.secret, secret)
}

/// `ApiToken::find_by_api_token`: the first live token with this secret.
pub fn find_token(tokens: &Vec<ApiToken>, secret: &[u8], now: i64) -> Option<ApiToken> {
    let mut i = 0;
    while i < tokens.len() {
        if token_live(&tokens[i], secret, now) {
            return Some(tokens[i].clone());
        }
        i += 1;
    }
    None
}

/// `authenticate_via_cookie` for a session that names a user.
pub fn cookie_user(users: &[User], uid: i32, epoch: Epoch, now: i64) -> Result<User, AuthError> {
    let user = match find_user(users, uid) {
        None => return Err(AuthError::UserNotFound),
        Some(u) => u,
    };
    if is_locked(&user, now) {
        return Err(AuthError::Locked);
    }
    let e = match epoch {
        Epoch::Absent => 0,
        Epoch::Invalid => return Err(AuthError::BadEpoch),
        Epoch::Value(v) => v,
    };
    if e != user.session_epoch {
        return Err(AuthError::StaleSession);
    }
    Ok(user)
}

/// `authenticate_via_token` for a present header.
pub fn token_user(users: &[User], tokens: &Vec<ApiToken>, header: &[u8], now: i64) -> Result<Authentication, AuthError> {
    let secret = match parse_auth_header(header) {
        Err(e) => return Err(e),
        Ok(s) => s,
    };
    if !starts_with(&secret, &TOKEN_PREFIX) {
        return Err(AuthError::InsecureToken);
    }
    let token = match find_token(tokens, &secret, now) {
        None => return Err(AuthError::TokenNotFound),
        Some(t) => t,
    };
    let user = match find_user(users, token.user_id) {
        None => return Err(AuthError::UserNotFound),
        Some(u) => u,
    };
    if is_locked(&user, now) {
        return Err(AuthError::Locked);
    }
    Ok(Authentication::Token(token, user))
}

/// `authenticate`: the origin check, then the session cookie, then the API
/// token.
pub fn authenticate(
    allowed_origins: &[u64],
    users: &[User],
    tokens: &Vec<ApiToken>,
    req: &Request,
    now: i64,
) -> Result<Authentication, AuthError> {
    if !origins_ok(&req.origins, allowed_origins) {
        return Err(AuthError::InvalidOrigin);
    }
    match req.session_uid {
        Some(uid) => match cookie_user(users, uid, req.session_epoch, now) {
            Ok(u) => return Ok(Authentication::Cookie(u)),
            Err(e) => return Err(e),
        },
        None => {}
    }
    match &req.authorization {
        Some(h) => token_user(users, tokens, h, now),
        None => Err(AuthError::NoAuth),
    }
}

/// `AuthCheck`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct AuthCheck {
    pub allow_token: bool,
    pub endpoint_scope: Option<EndpointScope>,
    pub crate_name: Option<Vec<u8>>,
    pub allow_any_crate_scope: bool,
}

/// `AuthCheck::endpoint_scope_matches`.
pub fn endpoint_scope_matches(ac: &AuthCheck, token_scopes: &Option<Vec<EndpointScope>>) -> bool {
    match token_scopes {
        None => true,
        Some(ts) => match ac.endpoint_scope {
            None => false,
            Some(s) => contains_scope(ts, s),
        },
    }
}

/// `AuthCheck::crate_scope_matches`.
pub fn crate_scope_matches(ac: &AuthCheck, token_scopes: &Option<Vec<Vec<u8>>>) -> bool {
    match token_scopes {
        None => true,
        Some(ts) => {
            if ts.len() == 0 {
                true
            } else {
                match &ac.crate_name {
                    None => ac.allow_any_crate_scope,
                    Some(name) => any_scope_matches(ts, name),
                }
            }
        }
    }
}

/// `AuthCheck::check`.
pub fn check(
    ac: &AuthCheck,
    allowed_origins: &[u64],
    users: &[User],
    tokens: &Vec<ApiToken>,
    req: &Request,
    now: i64,
) -> Result<Authentication, AuthError> {
    let a = match authenticate(allowed_origins, users, tokens, req, now) {
        Err(e) => return Err(e),
        Ok(a) => a,
    };
    match &a {
        Authentication::Cookie(_) => {}
        Authentication::Token(t, _) => {
            if !ac.allow_token {
                return Err(AuthError::TokenDisallowed);
            }
            if !endpoint_scope_matches(ac, &t.endpoint_scopes) {
                return Err(AuthError::EndpointScopeMismatch);
            }
            if !crate_scope_matches(ac, &t.crate_scopes) {
                return Err(AuthError::CrateScopeMismatch);
            }
        }
    }
    Ok(a)
}
