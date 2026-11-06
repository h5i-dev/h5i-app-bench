//! `crates/defguard_core/src/db/models/enrollment.rs` `Token` (enrollment
//! and desktop-activation tokens) and the session check of
//! `crates/defguard_proxy_manager/src/servers/enrollment.rs` `validate_session`.
//! Times are nanoseconds since the epoch (UTC); `now` is an input.

/// The fields of a `token` row the checks read.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Token {
    pub user_id: u64,
    pub expires_at: i64,
    pub used_at: Option<i64>,
    /// `token_type == Some(ENROLLMENT_TOKEN_TYPE)`.
    pub enrollment_type: bool,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TokenError {
    /// `TokenError::TokenExpired`
    TokenExpired,
    /// `TokenError::TokenUsed`
    TokenUsed,
    /// `permission_denied`: not an enrollment token
    WrongType,
    /// `unauthenticated("Session expired")`
    SessionExpired,
}

/// `Token::is_expired`: `expires_at < now`.
pub fn is_expired(t: &Token, now: i64) -> bool {
    t.expires_at < now
}

/// `TimeDelta::seconds(timeout as i64)` in nanoseconds; `timeout_ns` is that
/// value (the difftest keeps timeouts where neither conversion overflows).
/// `Token::is_session_valid`: started, and `now < used_at + timeout`.
pub fn is_session_valid(t: &Token, now: i64, timeout_ns: i64) -> bool {
    match t.used_at {
        None => false,
        Some(u) => now < u + timeout_ns,
    }
}

/// `t` unchanged (Aeneas has no `Option::clone`).
fn same(t: &Token) -> Token {
    let used_at = match t.used_at {
        None => None,
        Some(u) => Some(u),
    };
    Token { user_id: t.user_id, expires_at: t.expires_at, used_at, enrollment_type: t.enrollment_type }
}

/// `Token::start_session`: the token after the call (with `used_at` set on
/// first use) and the session deadline, or why it is refused.
pub fn start_session(t: &Token, now: i64, timeout_ns: i64) -> (Token, Result<i64, TokenError>) {
    if is_expired(t, now) {
        return (same(t), Err(TokenError::TokenExpired));
    }
    match t.used_at {
        Some(u) => {
            if is_session_valid(t, now, timeout_ns) {
                (same(t), Ok(u + timeout_ns))
            } else {
                (same(t), Err(TokenError::TokenUsed))
            }
        }
        None => (
            Token { user_id: t.user_id, expires_at: t.expires_at, used_at: Some(now), enrollment_type: t.enrollment_type },
            Ok(now + timeout_ns),
        ),
    }
}

/// `validate_session`: the token must be an enrollment token whose session
/// is still valid; it gives the user the request acts for.
pub fn validate_session(t: &Token, now: i64, timeout_ns: i64) -> Result<u64, TokenError> {
    if !t.enrollment_type {
        return Err(TokenError::WrongType);
    }
    if !is_session_valid(t, now, timeout_ns) {
        return Err(TokenError::SessionExpired);
    }
    Ok(t.user_id)
}
