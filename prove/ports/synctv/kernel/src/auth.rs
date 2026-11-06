//! Global roles, account status, and token acceptance decisions.
//!
//! Ported from synctv-core @ 38970e0:
//! - `src/models/user.rs`: `UserRole::{can_manage, is_admin_or_above}`,
//!   `UserStatus::{is_active, is_banned, can_login, can_create_room, can_join_room}`.
//! - `src/service/auth/jwt.rs`: `validate_expiration` (the clock read is the input `now`),
//!   and the token-type gate of `verify_access_token` / `verify_refresh_token`.
//! - `src/service/auth/guest_validator.rs`: the room guest-version gate of
//!   `validate_with_version`.
//! - `src/service/auth/validator.rs`: `JwtValidator::extract_bearer_token`, on bytes.
//! - `src/service/room/guest_access.rs`: the decision of `check_guest_allowed`, with the
//!   runtime-setting and repository reads as inputs.
//! - `src/service/auth/security_pipeline.rs`: the decision of `SecurityPipeline::check`,
//!   with the cache / repository / blacklist reads as inputs.

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum UserRole {
    Root,
    Admin,
    User,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum UserStatus {
    Active,
    Banned,
}

/// `UserRole::can_manage`: `matches!((self, other), (Root, _) | (Admin, User))`.
pub fn can_manage(actor: UserRole, other: UserRole) -> bool {
    match actor {
        UserRole::Root => true,
        UserRole::Admin => match other {
            UserRole::User => true,
            UserRole::Root => false,
            UserRole::Admin => false,
        },
        UserRole::User => false,
    }
}

/// `UserRole::is_admin_or_above`.
pub fn is_admin_or_above(r: UserRole) -> bool {
    match r {
        UserRole::Root => true,
        UserRole::Admin => true,
        UserRole::User => false,
    }
}

/// `UserStatus::is_active`.
pub fn status_is_active(s: UserStatus) -> bool {
    match s {
        UserStatus::Active => true,
        UserStatus::Banned => false,
    }
}

/// `UserStatus::is_banned`.
pub fn status_is_banned(s: UserStatus) -> bool {
    match s {
        UserStatus::Active => false,
        UserStatus::Banned => true,
    }
}

/// `UserStatus::can_login` (= `can_create_room` = `can_join_room` = `is_active`).
pub fn status_can_login(s: UserStatus) -> bool {
    status_is_active(s)
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AuthError {
    /// `Error::Authentication`.
    Authentication,
    /// `Error::ServiceUnavailable`.
    ServiceUnavailable,
    /// `Error::Authorization`.
    Authorization,
    /// Any other upstream error, propagated unchanged by `?`.
    Other,
}

/// `i64::try_from(leeway_secs).unwrap_or(i64::MAX)`.
pub fn leeway_to_i64(leeway_secs: u64) -> i64 {
    if leeway_secs <= 9223372036854775807 { leeway_secs as i64 } else { 9223372036854775807 }
}

/// `exp.saturating_add(leeway)` for `leeway >= 0`.
pub fn saturating_add_nonneg(exp: i64, leeway: i64) -> i64 {
    if exp > 9223372036854775807 - leeway { 9223372036854775807 } else { exp + leeway }
}

/// `validate_expiration(clock, exp, leeway_secs, ctx)`; `now = clock.now().timestamp()`.
pub fn validate_expiration(now: i64, exp: i64, leeway_secs: u64) -> Result<(), AuthError> {
    let leeway = leeway_to_i64(leeway_secs);
    let expires_with_leeway = saturating_add_nonneg(exp, leeway);
    if now > expires_with_leeway {
        return Err(AuthError::Authentication);
    }
    Ok(())
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TokenType {
    Access,
    Refresh,
    Guest,
}

/// The part of `verify_access_token` / `verify_refresh_token` after signature,
/// issuer and audience checks (`decode`, trusted): the expiration check of
/// `verify_token`, then the type check. `expected` is `Access` or `Refresh`.
pub fn accept_user_token(
    now: i64,
    exp: i64,
    leeway_secs: u64,
    typ: TokenType,
    expected: TokenType,
) -> Result<(), AuthError> {
    validate_expiration(now, exp, leeway_secs)?;
    if typ != expected {
        return Err(AuthError::Authentication);
    }
    Ok(())
}

/// `GuestTokenValidator::validate_with_version` after `verify_guest_token` decoded the
/// claims: the expiration check, then `claims.gv < current_room_guest_version` rejects.
pub fn accept_guest_token(
    now: i64,
    exp: i64,
    leeway_secs: u64,
    gv: i64,
    current_room_guest_version: i64,
) -> Result<(), AuthError> {
    validate_expiration(now, exp, leeway_secs)?;
    if gv < current_room_guest_version {
        return Err(AuthError::Authentication);
    }
    Ok(())
}

/// Inputs of `RoomService::check_guest_allowed`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct GuestAccessFacts {
    /// `runtime_settings_store.is_some()`.
    pub has_runtime_settings: bool,
    /// `registry.user.enable_guest.get()?` (`Ok` value; read errors propagate).
    pub enable_guest: bool,
    /// `room_settings.allow_guest_join.0`.
    pub allow_guest_join: bool,
    /// `password_state.is_some_and(|state| state.enabled)`.
    pub password_enabled: bool,
}

/// The decision of `RoomService::check_guest_allowed`.
pub fn check_guest_allowed(f: &GuestAccessFacts) -> Result<(), AuthError> {
    if !f.has_runtime_settings {
        return Err(AuthError::Authorization);
    }
    if !f.enable_guest {
        return Err(AuthError::Authorization);
    }
    if !f.allow_guest_join {
        return Err(AuthError::Authorization);
    }
    if f.password_enabled {
        return Err(AuthError::Authorization);
    }
    Ok(())
}

/// ASCII whitespace as `char::is_whitespace` sees it (`\t \n \x0b \x0c \r` and space).
pub fn is_ascii_ws(b: u8) -> bool {
    b == 32 || (b >= 9 && b <= 13)
}

/// ASCII lower-casing of one byte.
pub fn ascii_lower(b: u8) -> u8 {
    if b >= 65 && b <= 90 { b + 32 } else { b }
}

/// `auth_value[..7].eq_ignore_ascii_case("Bearer ")`, for `auth_value.len() > 7`.
pub fn bearer_prefix(v: &[u8]) -> bool {
    ascii_lower(v[0]) == 98
        && ascii_lower(v[1]) == 101
        && ascii_lower(v[2]) == 97
        && ascii_lower(v[3]) == 114
        && ascii_lower(v[4]) == 101
        && ascii_lower(v[5]) == 114
        && v[6] == 32
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum BearerError {
    /// "Authorization header must start with 'Bearer '".
    BadScheme,
    /// "Authorization bearer token cannot be empty".
    Empty,
}

/// `JwtValidator::extract_bearer_token`, on the bytes of an ASCII header value
/// (both callers obtain it from `HeaderValue::to_str`, which only accepts visible
/// ASCII). Returns the `[start, end)` byte range of the trimmed token.
pub fn extract_bearer_token(v: &[u8]) -> Result<(usize, usize), BearerError> {
    if v.len() <= 7 || !bearer_prefix(v) {
        return Err(BearerError::BadScheme);
    }
    let mut start = 7;
    while start < v.len() && is_ascii_ws(v[start]) {
        start += 1;
    }
    let mut end = v.len();
    while end > start && is_ascii_ws(v[end - 1]) {
        end -= 1;
    }
    if start == end {
        return Err(BearerError::Empty);
    }
    Ok((start, end))
}

/// What `SecurityPipeline::check` reads, in order.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct PipelineFacts {
    /// A user cache is configured and `cache.get` returned `Ok(Some(cached))`.
    pub cache_hit: bool,
    /// `cached.is_banned() || cached.status() == Banned || cached.is_deleted()`.
    pub cached_rejects: bool,
    /// `user_service.get_user` found the user (`NotFound` -> `Authentication`).
    pub user_found: bool,
    /// `user.is_deleted()`.
    pub user_deleted: bool,
    /// `claims.pv` and the stored password credential version.
    pub claims_pv: i32,
    pub password_version: i32,
    /// `user_service.is_user_banned`.
    pub banned: bool,
    /// `user_service.is_two_factor_enabled`.
    pub two_factor_enabled: bool,
    /// `claims.satisfies_two_factor_requirement()` (`amr` present).
    pub token_has_second_factor: bool,
    /// The JTI blacklist read failed (-> `ServiceUnavailable`).
    pub blacklist_unavailable: bool,
    /// The JTI is blacklisted.
    pub blacklisted: bool,
}

/// The decision of `SecurityPipeline::check` (repository errors other than
/// `NotFound` and blacklist storage errors are modelled by the flags above).
pub fn pipeline_check(f: &PipelineFacts) -> Result<(), AuthError> {
    if f.cache_hit && f.cached_rejects {
        return Err(AuthError::Authentication);
    }
    if !f.user_found {
        return Err(AuthError::Authentication);
    }
    if f.claims_pv != f.password_version {
        return Err(AuthError::Authentication);
    }
    if f.user_deleted || f.banned {
        return Err(AuthError::Authentication);
    }
    if f.two_factor_enabled && !f.token_has_second_factor {
        return Err(AuthError::Authentication);
    }
    if f.blacklist_unavailable {
        return Err(AuthError::ServiceUnavailable);
    }
    if f.blacklisted {
        return Err(AuthError::Authentication);
    }
    Ok(())
}
