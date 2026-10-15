//! Pure deployment-administrator authorization decisions.
use crate::{bytes, userrole::{self, UserRole}};
#[derive(Clone, Copy)]
pub enum Principal { User(u128), Group(u128), Token(u128) }
#[derive(Clone, Copy)]
pub enum AuthzDenialVisibility { Visible, Hidden }
#[derive(Clone, Copy)]
pub enum AdminDenial { Inactive, ExternalAccount, NotAdmin, UnsupportedSubject }
pub enum AdminDecision { Allowed, Denied(AdminDenial) }
pub fn visibility_bytes(v: AuthzDenialVisibility) -> Vec<u8> {
    match v { AuthzDenialVisibility::Visible => bytes::copy(b"visible"), AuthzDenialVisibility::Hidden => bytes::copy(b"hidden") }
}
pub fn denial_bytes(reason: AdminDenial) -> Vec<u8> {
    match reason {
        AdminDenial::Inactive => bytes::copy(b"inactive"),
        AdminDenial::ExternalAccount => bytes::copy(b"external_account"),
        AdminDenial::NotAdmin => bytes::copy(b"not_admin"),
        AdminDenial::UnsupportedSubject => bytes::copy(b"unsupported_subject"),
    }
}
pub fn system_admin_denial_reason(subject: Principal, role: UserRole, is_external: bool, active: bool) -> Option<AdminDenial> {
    match subject {
        Principal::User(_) => {
            if !active { return Some(AdminDenial::Inactive); }
            if is_external { return Some(AdminDenial::ExternalAccount); }
            if !userrole::at_least(role, UserRole::Admin) { return Some(AdminDenial::NotAdmin); }
            None
        },
        _ => Some(AdminDenial::UnsupportedSubject),
    }
}
pub fn require_system_admin(subject: Principal, role: UserRole, is_external: bool, active: bool) -> AdminDecision {
    match system_admin_denial_reason(subject, role, is_external, active) {
        None => AdminDecision::Allowed,
        Some(reason) => AdminDecision::Denied(reason),
    }
}
