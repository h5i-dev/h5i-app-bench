//! Pure drive-policy rules from domain/entities/drive.rs.
use crate::model::{Subject, ErrorKind};

#[derive(Clone, Copy)]
pub struct Policies {
    pub forbid_sharing: bool,
    pub forbid_external_sharing: bool,
    pub forbid_public_links: bool,
    pub forbid_cross_drive_move: bool,
    pub forbid_owner_role_change: bool,
    pub include_in_photo_index: bool,
    pub include_in_music_index: bool,
    pub read_only: bool,
    pub require_public_link_password: bool,
    pub max_public_link_days: Option<u32>,
}

#[derive(Clone, Copy)]
pub struct Overrides {
    pub forbid_sharing: Option<bool>,
    pub forbid_external_sharing: Option<bool>,
    pub forbid_public_links: Option<bool>,
    pub forbid_cross_drive_move: Option<bool>,
    pub forbid_owner_role_change: Option<bool>,
    pub include_in_photo_index: Option<bool>,
    pub include_in_music_index: Option<bool>,
    pub read_only: Option<bool>,
    pub require_public_link_password: Option<bool>,
    pub max_public_link_days: Option<u32>,
}

fn override_bool(default: bool, value: Option<bool>) -> bool {
    match value { Some(v) => v, None => default }
}
fn override_cap(default: Option<u32>, value: Option<u32>) -> Option<u32> {
    match value { Some(v) => Some(v), None => default }
}
/// Upstream `DrivePolicies::resolve`.
pub fn resolve(default: &Policies, overrides: &Overrides) -> Policies {
    Policies {
        forbid_sharing: override_bool(default.forbid_sharing, overrides.forbid_sharing),
        forbid_external_sharing: override_bool(default.forbid_external_sharing, overrides.forbid_external_sharing),
        forbid_public_links: override_bool(default.forbid_public_links, overrides.forbid_public_links),
        forbid_cross_drive_move: override_bool(default.forbid_cross_drive_move, overrides.forbid_cross_drive_move),
        forbid_owner_role_change: override_bool(default.forbid_owner_role_change, overrides.forbid_owner_role_change),
        include_in_photo_index: override_bool(default.include_in_photo_index, overrides.include_in_photo_index),
        include_in_music_index: override_bool(default.include_in_music_index, overrides.include_in_music_index),
        read_only: override_bool(default.read_only, overrides.read_only),
        require_public_link_password: override_bool(default.require_public_link_password, overrides.require_public_link_password),
        max_public_link_days: override_cap(default.max_public_link_days, overrides.max_public_link_days),
    }
}

/// Upstream `DrivePolicies::refuse_public_links`, with audit in the shell.
pub fn refuse_public_links(p: &Policies) -> Result<(), ErrorKind> {
    if p.forbid_public_links { return Err(ErrorKind::OperationNotSupported); }
    if p.forbid_sharing { return Err(ErrorKind::OperationNotSupported); }
    Ok(())
}
/// Upstream `DrivePolicies::refuse_sharing`, with audit in the shell.
pub fn refuse_sharing(p: &Policies) -> Result<(), ErrorKind> {
    if !p.forbid_sharing { return Ok(()); }
    Err(ErrorKind::OperationNotSupported)
}
/// Upstream `DrivePolicies::refuse_owner_role_change`, with audit in the shell.
pub fn refuse_owner_role_change(p: &Policies, caller_is_admin: bool) -> Result<(), ErrorKind> {
    if !p.forbid_owner_role_change { return Ok(()); }
    if caller_is_admin { return Ok(()); }
    Err(ErrorKind::OperationNotSupported)
}
/// Upstream `DrivePolicies::refuse_cross_drive_move`, with audit in the shell.
pub fn refuse_cross_drive_move(p: &Policies) -> Result<(), ErrorKind> {
    if !p.forbid_cross_drive_move { return Ok(()); }
    Err(ErrorKind::OperationNotSupported)
}
/// Upstream `DrivePolicies::refuse_external_sharing`, with audit in the shell.
pub fn refuse_external_sharing(p: &Policies, subject: Subject, is_external: bool) -> Result<(), ErrorKind> {
    if !p.forbid_external_sharing { return Ok(()); }
    match subject { Subject::User(_) => (), _ => return Ok(()) }
    if !is_external { return Ok(()); }
    Err(ErrorKind::OperationNotSupported)
}
