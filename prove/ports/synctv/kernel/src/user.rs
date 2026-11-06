//! Account-level gates on a `User` row.
//!
//! Ported from `synctv-core/src/models/user.rs` @ 38970e0: `User::{is_deleted, is_root,
//! is_admin, is_admin_or_above, can_login, can_create_room, can_join_room,
//! can_unbind_provider}` (lines 356-414). `deleted_at.is_some()` is the flag `deleted`.
use crate::auth::{is_admin_or_above, status_is_active, UserRole, UserStatus};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum SignupMethod {
    Unknown,
    Email,
    Password,
    OAuth2,
    AdminCreated,
    WebAuthn,
}

/// The fields of `User` these gates read.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct UserFacts {
    pub role: UserRole,
    pub status: UserStatus,
    pub is_banned: bool,
    pub deleted: bool,
    pub signup_method: SignupMethod,
}

/// `User::is_root`.
pub fn user_is_root(u: &UserFacts) -> bool {
    match u.role {
        UserRole::Root => true,
        UserRole::Admin => false,
        UserRole::User => false,
    }
}

/// `User::is_admin`.
pub fn user_is_admin(u: &UserFacts) -> bool {
    match u.role {
        UserRole::Root => false,
        UserRole::Admin => true,
        UserRole::User => false,
    }
}

/// `User::is_admin_or_above`.
pub fn user_is_admin_or_above(u: &UserFacts) -> bool {
    is_admin_or_above(u.role)
}

/// `User::can_login`.
pub fn user_can_login(u: &UserFacts) -> bool {
    !u.deleted && !u.is_banned && status_is_active(u.status)
}

/// `User::can_create_room(allow_user)`.
pub fn user_can_create_room(u: &UserFacts, allow_user: bool) -> bool {
    if u.deleted || u.is_banned || !status_is_active(u.status) {
        return false;
    }
    match u.role {
        UserRole::Root => true,
        UserRole::Admin => true,
        UserRole::User => allow_user,
    }
}

/// `User::can_join_room`.
pub fn user_can_join_room(u: &UserFacts) -> bool {
    !u.deleted && !u.is_banned && status_is_active(u.status)
}

/// `User::can_unbind_provider(has_oauth2_count, _)`.
pub fn user_can_unbind_provider(u: &UserFacts, has_oauth2_count: usize) -> bool {
    match u.signup_method {
        SignupMethod::OAuth2 => has_oauth2_count > 1,
        SignupMethod::Unknown => true,
        SignupMethod::Email => true,
        SignupMethod::Password => true,
        SignupMethod::AdminCreated => true,
        SignupMethod::WebAuthn => true,
    }
}
