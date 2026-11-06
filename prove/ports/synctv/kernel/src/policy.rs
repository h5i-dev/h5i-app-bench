//! Room member role and permission-override policy.
//!
//! Ported from synctv-core @ 38970e0:
//! - `src/service/room/member_role_policy.rs` (all seven validators).
//! - `src/service/room/member_kick.rs`: `validate_kick_cooldown_seconds`.
//! - `src/service/room/member_roles.rs`: the validation prefix of
//!   `RoomService::update_member_with_outbox` (everything before
//!   `execute_member_update_with_outbox`), with the two repository reads as inputs.
//!
//! Upstream errors carry messages; here only their kind is kept
//! (`Error::InvalidInput` / `Error::Authorization` / `Error::NotFound`).
use crate::perms::{
    admin_includes_only_defined, guest_includes_only_defined, member_includes_only_defined, Role,
};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum PolicyError {
    InvalidInput,
    Authorization,
    NotFound,
}

/// `validate_role_can_be_assigned`.
pub fn validate_role_can_be_assigned(role: Role) -> Result<(), PolicyError> {
    if role == Role::Creator {
        return Err(PolicyError::InvalidInput);
    }
    Ok(())
}

/// `validate_add_member_role(room, actor_id, role)`; `room_created_by` is `room.created_by`.
pub fn validate_add_member_role(
    room_created_by: i64,
    actor_id: i64,
    role: Role,
) -> Result<(), PolicyError> {
    validate_role_can_be_assigned(role)?;
    if role == Role::Admin && room_created_by != actor_id {
        return Err(PolicyError::Authorization);
    }
    Ok(())
}

/// `validate_admin_member_role_update(room, target_user_id)`.
pub fn validate_admin_member_role_update(
    room_created_by: i64,
    target_user_id: i64,
) -> Result<(), PolicyError> {
    if target_user_id == room_created_by {
        return Err(PolicyError::InvalidInput);
    }
    Ok(())
}

/// `validate_creator_member_role_update(room, actor_id, target_user_id)`.
pub fn validate_creator_member_role_update(
    room_created_by: i64,
    actor_id: i64,
    target_user_id: i64,
) -> Result<(), PolicyError> {
    if room_created_by != actor_id {
        return Err(PolicyError::Authorization);
    }
    validate_admin_member_role_update(room_created_by, target_user_id)
}

/// `validate_admin_override_bits`.
pub fn validate_admin_override_bits(
    admin_added_permissions: u64,
    admin_removed_permissions: u64,
) -> Result<(), PolicyError> {
    if !admin_includes_only_defined(admin_added_permissions)
        || !admin_includes_only_defined(admin_removed_permissions)
    {
        return Err(PolicyError::InvalidInput);
    }
    Ok(())
}

/// `validate_override_bits_for_role`.
pub fn validate_override_bits_for_role(
    role: Role,
    added_permissions: u64,
    removed_permissions: u64,
) -> Result<(), PolicyError> {
    let valid = match role {
        Role::Creator => {
            admin_includes_only_defined(added_permissions)
                && admin_includes_only_defined(removed_permissions)
        }
        Role::Admin => {
            admin_includes_only_defined(added_permissions)
                && admin_includes_only_defined(removed_permissions)
        }
        Role::Member => {
            member_includes_only_defined(added_permissions)
                && member_includes_only_defined(removed_permissions)
        }
        Role::Guest => {
            guest_includes_only_defined(added_permissions)
                && guest_includes_only_defined(removed_permissions)
        }
    };
    if valid { Ok(()) } else { Err(PolicyError::InvalidInput) }
}

/// `validate_member_permission_override_channel`.
pub fn validate_member_permission_override_channel(
    effective_is_admin: bool,
    added_permissions: u64,
    removed_permissions: u64,
    admin_added_permissions: u64,
    admin_removed_permissions: u64,
) -> Result<(), PolicyError> {
    if effective_is_admin && (added_permissions > 0 || removed_permissions > 0) {
        return Err(PolicyError::Authorization);
    }
    if !effective_is_admin && (admin_added_permissions > 0 || admin_removed_permissions > 0) {
        return Err(PolicyError::Authorization);
    }
    Ok(())
}

/// `MAX_KICK_COOLDOWN_SECONDS = 30 * 24 * 60 * 60`.
pub const MAX_KICK_COOLDOWN_SECONDS: i64 = 2592000;

/// `validate_kick_cooldown_seconds`.
pub fn validate_kick_cooldown_seconds(cooldown_seconds: i64) -> Result<(), PolicyError> {
    if cooldown_seconds <= 0 {
        return Err(PolicyError::InvalidInput);
    }
    if cooldown_seconds > MAX_KICK_COOLDOWN_SECONDS {
        return Err(PolicyError::InvalidInput);
    }
    Ok(())
}

/// `MemberPermissionPatch` plus the requested role of `UpdateMemberWithOutboxRequest`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct MemberUpdate {
    pub actor_id: i64,
    pub target_user_id: i64,
    /// `role: Option<RoomRole>`; `has_role = false` is `None`.
    pub has_role: bool,
    pub role: Role,
    pub apply_permission_update: bool,
    pub added_permissions: u64,
    pub removed_permissions: u64,
    pub admin_added_permissions: u64,
    pub admin_removed_permissions: u64,
}

/// What the validation prefix of `update_member_with_outbox` hands to
/// `execute_member_update_with_outbox`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct MemberUpdatePlan {
    pub effective_role: Role,
    pub effective_is_admin: bool,
    /// `actor_permission_check`: `Some(MANAGE_MEMBER_PERMISSIONS)` iff a permission update.
    pub needs_manage_member_permissions: bool,
}

/// `role.unwrap_or(current.role)`.
pub fn effective_role_of(has_role: bool, role: Role, current_role: Role) -> Role {
    if has_role { role } else { current_role }
}

/// The validation prefix of `RoomService::update_member_with_outbox`.
/// `current_role` is the target's row (`None` -> `NotFound`), `room_created_by` the room
/// (`None` -> `NotFound`; only read when a role is requested).
pub fn plan_member_update(
    u: &MemberUpdate,
    current_exists: bool,
    current_role: Role,
    room_exists: bool,
    room_created_by: i64,
) -> Result<MemberUpdatePlan, PolicyError> {
    validate_admin_override_bits(u.admin_added_permissions, u.admin_removed_permissions)?;
    if !current_exists {
        return Err(PolicyError::NotFound);
    }
    let effective_role = effective_role_of(u.has_role, u.role, current_role);
    let effective_is_admin = effective_role == Role::Admin;
    if u.apply_permission_update {
        validate_override_bits_for_role(effective_role, u.added_permissions, u.removed_permissions)?;
    }
    if u.has_role {
        validate_role_can_be_assigned(u.role)?;
        if !room_exists {
            return Err(PolicyError::NotFound);
        }
        validate_creator_member_role_update(room_created_by, u.actor_id, u.target_user_id)?;
    }
    if u.apply_permission_update {
        validate_member_permission_override_channel(
            effective_is_admin,
            u.added_permissions,
            u.removed_permissions,
            u.admin_added_permissions,
            u.admin_removed_permissions,
        )?;
    }
    Ok(MemberUpdatePlan {
        effective_role,
        effective_is_admin,
        needs_manage_member_permissions: u.apply_permission_update,
    })
}
