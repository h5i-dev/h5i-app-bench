//! `domain/entities/user.rs`: the session and stored user-role hierarchy.
use crate::bytes::{equal, copy};

#[derive(Clone, Copy)]
pub enum UserRole {
    Owner,
    Admin,
    User,
    Anonymous,
}

/// `UserRole::as_str`, represented as wire bytes.
pub fn as_bytes(role: UserRole) -> Vec<u8> {
    match role {
        UserRole::Owner => copy(b"owner"),
        UserRole::Admin => copy(b"admin"),
        UserRole::User => copy(b"user"),
        UserRole::Anonymous => copy(b"anonymous"),
    }
}

/// `UserRole::from_stored`.
pub fn from_stored(raw: &[u8]) -> Option<UserRole> {
    if equal(raw, b"owner") {
        Some(UserRole::Owner)
    } else if equal(raw, b"admin") {
        Some(UserRole::Admin)
    } else if equal(raw, b"user") {
        Some(UserRole::User)
    } else {
        None
    }
}

/// `UserRole::from_session`.
pub fn from_session(raw: &[u8]) -> Option<UserRole> {
    if equal(raw, b"anonymous") {
        Some(UserRole::Anonymous)
    } else {
        from_stored(raw)
    }
}

/// `UserRole::rank`.
pub fn rank(role: UserRole) -> u8 {
    match role {
        UserRole::Anonymous => 0,
        UserRole::User => 1,
        UserRole::Admin => 2,
        UserRole::Owner => 3,
    }
}

/// `UserRole::at_least`.
pub fn at_least(role: UserRole, min: UserRole) -> bool {
    rank(role) >= rank(min)
}

/// `UserRole::outranks`.
pub fn outranks(role: UserRole, target: UserRole) -> bool {
    rank(role) > rank(target)
}

/// `UserRole::is_anonymous`.
pub fn is_anonymous(role: UserRole) -> bool {
    match role {
        UserRole::Anonymous => true,
        _ => false,
    }
}

/// `UserRole::str_at_least`.
pub fn str_at_least(raw: &[u8], min: UserRole) -> bool {
    match from_session(raw) {
        Some(role) => at_least(role, min),
        None => false,
    }
}

/// `UserRole::is_privileged`.
pub fn is_privileged(role: UserRole) -> bool {
    rank(role) > rank(UserRole::User)
}
