//! Live-account role reconciliation and the internal-account restriction.
use crate::{bytes, userrole::{self, UserRole}};
#[derive(Clone, Copy)]
pub struct UserFlags {
    pub role: UserRole,
    pub is_external: bool,
    pub active: bool,
    pub force_password_change: bool,
}
#[derive(Clone, Copy)]
pub enum FlagsLookup { Found(UserFlags), NotFound, Unavailable }
pub enum LiveRole { Active(Vec<u8>), Revoked }
pub enum InternalDenial { External, NoAccount }
/// The caller UUID is retained at the boundary for the shell audit event.
pub fn decide_internal_user(flags: FlagsLookup, _caller_id: u128) -> Result<(), InternalDenial> {
    match flags {
        FlagsLookup::Found(f) => if f.is_external { Err(InternalDenial::External) } else { Ok(()) },
        FlagsLookup::NotFound => Err(InternalDenial::NoAccount),
        FlagsLookup::Unavailable => Ok(()),
    }
}
pub fn anonymous_live_role(claim_role: &[u8]) -> Option<LiveRole> {
    match userrole::from_session(claim_role) {
        Some(role) => if userrole::is_anonymous(role) { Some(LiveRole::Active(userrole::as_bytes(role))) } else { None },
        None => None,
    }
}
pub fn decide_live_role(flags: FlagsLookup, _user_id: u128, claim_role: &[u8]) -> LiveRole {
    match flags {
        FlagsLookup::Found(f) => if f.active { LiveRole::Active(userrole::as_bytes(f.role)) } else { LiveRole::Revoked },
        FlagsLookup::NotFound => LiveRole::Revoked,
        FlagsLookup::Unavailable => LiveRole::Active(bytes::copy(claim_role)),
    }
}
