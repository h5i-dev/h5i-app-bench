//! Room permission bitspaces and effective permissions.
//!
//! Ported from synctv-core @ 38970e0:
//! - `src/models/permission.rs`: `RoomPermission`, `RoomPermissionSet::{has, has_all, has_any,
//!   all, default_*, guest_assignable}`, `Room{Member,Admin,Guest}PermissionBits::{includes_only_defined,
//!   to_permissions, from_permissions, bit_for}`, `Role::{permissions, override_bits_from_permissions}`.
//! - `src/models/room_member.rs`: `RoomMember::{effective_permissions, has_permission}`.
//! - `src/models/room_settings/mod.rs`: `RoomSettings::{admin,member,guest}_permissions`.
//! - `src/service/permission/calculator.rs`: `EffectivePermissionCalculator::{role_default,
//!   effective_for_member, has_permission}`.
//!
//! A permission set is the upstream `u64` in the admin bitspace. The bit constants are
//! written as literals (upstream: `1 << k`); the difftest compares every one of them with
//! upstream. Upstream's `to_permissions`/`from_permissions` are a sequence of
//! `if bits & FROM != 0 { out |= TO }`; here every step is the same test through `map_bit`,
//! and the results are or-ed together, which is the same value.

/// `RoomPermission`: the semantic room permission (no numeric representation upstream).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RoomPermission {
    SendChatMessages,
    ManageOwnMedia,
    BrowseLibrary,
    ViewMembers,
    ViewChatHistory,
    UseVoiceChat,
    UseP2pMedia,
    DeleteMedia,
    ReorderMedia,
    ClearMedia,
    ManageLiveStreams,
    ControlPlaybackState,
    NavigatePlayback,
    ReviewJoinRequests,
    RemoveMembers,
    ManageMemberPermissions,
    AddMembers,
    ManageRoomSettings,
    DeleteChatMessages,
    DeleteRoom,
    ViewPlaybackHistory,
}

/// `Role` (room role preset).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Role {
    Creator,
    Admin,
    Member,
    Guest,
}

// ---- RoomMemberPermissionBits ----
pub const M_SEND_CHAT_MESSAGES: u64 = 0x1;
pub const M_MANAGE_OWN_MEDIA: u64 = 0x2;
pub const M_BROWSE_LIBRARY: u64 = 0x4;
pub const M_VIEW_MEMBERS: u64 = 0x8;
pub const M_VIEW_CHAT_HISTORY: u64 = 0x10;
pub const M_USE_VOICE_CHAT: u64 = 0x20;
pub const M_USE_P2P_MEDIA: u64 = 0x40;
pub const M_ALL: u64 = 0x7f;

// ---- RoomAdminPermissionBits (also the effective-permission bitspace) ----
pub const A_SEND_CHAT_MESSAGES: u64 = 0x1;
pub const A_MANAGE_OWN_MEDIA: u64 = 0x2;
pub const A_BROWSE_LIBRARY: u64 = 0x4;
pub const A_VIEW_MEMBERS: u64 = 0x8;
pub const A_VIEW_CHAT_HISTORY: u64 = 0x10;
pub const A_USE_VOICE_CHAT: u64 = 0x20;
pub const A_DELETE_MEDIA: u64 = 0x40;
pub const A_REORDER_MEDIA: u64 = 0x80;
pub const A_CLEAR_MEDIA: u64 = 0x100;
pub const A_MANAGE_LIVE_STREAMS: u64 = 0x200;
pub const A_CONTROL_PLAYBACK_STATE: u64 = 0x400;
pub const A_NAVIGATE_PLAYBACK: u64 = 0x800;
pub const A_REVIEW_JOIN_REQUESTS: u64 = 0x1000;
pub const A_REMOVE_MEMBERS: u64 = 0x2000;
pub const A_MANAGE_MEMBER_PERMISSIONS: u64 = 0x4000;
pub const A_ADD_MEMBERS: u64 = 0x8000;
pub const A_MANAGE_ROOM_SETTINGS: u64 = 0x10000;
pub const A_DELETE_CHAT_MESSAGES: u64 = 0x20000;
pub const A_DELETE_ROOM: u64 = 0x40000;
pub const A_VIEW_PLAYBACK_HISTORY: u64 = 0x80000;
pub const A_USE_P2P_MEDIA: u64 = 0x100000;
pub const A_ALL: u64 = 0x1fffff;
/// `RoomAdminPermissionBits::DEFAULT = ALL & !DELETE_ROOM`.
pub const A_DEFAULT: u64 = 0x1bffff;

// ---- RoomGuestPermissionBits ----
pub const G_VIEW_MEMBERS: u64 = 0x1_0000_0000;
pub const G_VIEW_CHAT_HISTORY: u64 = 0x2_0000_0000;
pub const G_USE_VOICE_CHAT: u64 = 0x4_0000_0000;
pub const G_USE_P2P_MEDIA: u64 = 0x8_0000_0000;
pub const G_ALL: u64 = 0xf_0000_0000;
pub const G_DEFAULT: u64 = 0;

/// `bits & from != 0 ? to : 0`: one step of upstream's `to_permissions`/`from_permissions`.
pub fn map_bit(bits: u64, from: u64, to: u64) -> u64 {
    if bits & from != 0 { to } else { 0 }
}

/// `includes_only_defined(bits) = bits & !ALL == 0`, for each bitspace.
pub fn member_includes_only_defined(bits: u64) -> bool {
    bits & !M_ALL == 0
}

pub fn admin_includes_only_defined(bits: u64) -> bool {
    bits & !A_ALL == 0
}

pub fn guest_includes_only_defined(bits: u64) -> bool {
    bits & !G_ALL == 0
}

/// `RoomMemberPermissionBits::to_permissions`.
pub fn member_to_permissions(bits: u64) -> u64 {
    map_bit(bits, M_SEND_CHAT_MESSAGES, A_SEND_CHAT_MESSAGES)
        | map_bit(bits, M_MANAGE_OWN_MEDIA, A_MANAGE_OWN_MEDIA)
        | map_bit(bits, M_BROWSE_LIBRARY, A_BROWSE_LIBRARY)
        | map_bit(bits, M_VIEW_MEMBERS, A_VIEW_MEMBERS)
        | map_bit(bits, M_VIEW_CHAT_HISTORY, A_VIEW_CHAT_HISTORY)
        | map_bit(bits, M_USE_VOICE_CHAT, A_USE_VOICE_CHAT)
        | map_bit(bits, M_USE_P2P_MEDIA, A_USE_P2P_MEDIA)
}

/// `RoomMemberPermissionBits::from_permissions`.
pub fn member_from_permissions(p: u64) -> u64 {
    map_bit(p, A_SEND_CHAT_MESSAGES, M_SEND_CHAT_MESSAGES)
        | map_bit(p, A_MANAGE_OWN_MEDIA, M_MANAGE_OWN_MEDIA)
        | map_bit(p, A_BROWSE_LIBRARY, M_BROWSE_LIBRARY)
        | map_bit(p, A_VIEW_MEMBERS, M_VIEW_MEMBERS)
        | map_bit(p, A_VIEW_CHAT_HISTORY, M_VIEW_CHAT_HISTORY)
        | map_bit(p, A_USE_VOICE_CHAT, M_USE_VOICE_CHAT)
        | map_bit(p, A_USE_P2P_MEDIA, M_USE_P2P_MEDIA)
}

/// `RoomAdminPermissionBits::to_permissions` (every admin bit maps to itself).
pub fn admin_to_permissions(bits: u64) -> u64 {
    map_bit(bits, A_SEND_CHAT_MESSAGES, A_SEND_CHAT_MESSAGES)
        | map_bit(bits, A_MANAGE_OWN_MEDIA, A_MANAGE_OWN_MEDIA)
        | map_bit(bits, A_BROWSE_LIBRARY, A_BROWSE_LIBRARY)
        | map_bit(bits, A_VIEW_MEMBERS, A_VIEW_MEMBERS)
        | map_bit(bits, A_VIEW_CHAT_HISTORY, A_VIEW_CHAT_HISTORY)
        | map_bit(bits, A_USE_VOICE_CHAT, A_USE_VOICE_CHAT)
        | map_bit(bits, A_DELETE_MEDIA, A_DELETE_MEDIA)
        | map_bit(bits, A_REORDER_MEDIA, A_REORDER_MEDIA)
        | map_bit(bits, A_CLEAR_MEDIA, A_CLEAR_MEDIA)
        | map_bit(bits, A_MANAGE_LIVE_STREAMS, A_MANAGE_LIVE_STREAMS)
        | map_bit(bits, A_CONTROL_PLAYBACK_STATE, A_CONTROL_PLAYBACK_STATE)
        | map_bit(bits, A_NAVIGATE_PLAYBACK, A_NAVIGATE_PLAYBACK)
        | map_bit(bits, A_REVIEW_JOIN_REQUESTS, A_REVIEW_JOIN_REQUESTS)
        | map_bit(bits, A_REMOVE_MEMBERS, A_REMOVE_MEMBERS)
        | map_bit(bits, A_MANAGE_MEMBER_PERMISSIONS, A_MANAGE_MEMBER_PERMISSIONS)
        | map_bit(bits, A_ADD_MEMBERS, A_ADD_MEMBERS)
        | map_bit(bits, A_MANAGE_ROOM_SETTINGS, A_MANAGE_ROOM_SETTINGS)
        | map_bit(bits, A_DELETE_CHAT_MESSAGES, A_DELETE_CHAT_MESSAGES)
        | map_bit(bits, A_DELETE_ROOM, A_DELETE_ROOM)
        | map_bit(bits, A_VIEW_PLAYBACK_HISTORY, A_VIEW_PLAYBACK_HISTORY)
        | map_bit(bits, A_USE_P2P_MEDIA, A_USE_P2P_MEDIA)
}

/// `RoomAdminPermissionBits::from_permissions` (the same table read the other way).
pub fn admin_from_permissions(p: u64) -> u64 {
    admin_to_permissions(p)
}

/// `RoomGuestPermissionBits::to_permissions`.
pub fn guest_to_permissions(bits: u64) -> u64 {
    map_bit(bits, G_VIEW_MEMBERS, A_VIEW_MEMBERS)
        | map_bit(bits, G_VIEW_CHAT_HISTORY, A_VIEW_CHAT_HISTORY)
        | map_bit(bits, G_USE_VOICE_CHAT, A_USE_VOICE_CHAT)
        | map_bit(bits, G_USE_P2P_MEDIA, A_USE_P2P_MEDIA)
}

/// `RoomGuestPermissionBits::from_permissions`.
pub fn guest_from_permissions(p: u64) -> u64 {
    map_bit(p, A_VIEW_MEMBERS, G_VIEW_MEMBERS)
        | map_bit(p, A_VIEW_CHAT_HISTORY, G_VIEW_CHAT_HISTORY)
        | map_bit(p, A_USE_VOICE_CHAT, G_USE_VOICE_CHAT)
        | map_bit(p, A_USE_P2P_MEDIA, G_USE_P2P_MEDIA)
}

/// `RoomAdminPermissionBits::bit_for`.
pub fn bit_for(p: RoomPermission) -> u64 {
    match p {
        RoomPermission::SendChatMessages => A_SEND_CHAT_MESSAGES,
        RoomPermission::ManageOwnMedia => A_MANAGE_OWN_MEDIA,
        RoomPermission::BrowseLibrary => A_BROWSE_LIBRARY,
        RoomPermission::ViewMembers => A_VIEW_MEMBERS,
        RoomPermission::ViewChatHistory => A_VIEW_CHAT_HISTORY,
        RoomPermission::UseVoiceChat => A_USE_VOICE_CHAT,
        RoomPermission::UseP2pMedia => A_USE_P2P_MEDIA,
        RoomPermission::DeleteMedia => A_DELETE_MEDIA,
        RoomPermission::ReorderMedia => A_REORDER_MEDIA,
        RoomPermission::ClearMedia => A_CLEAR_MEDIA,
        RoomPermission::ManageLiveStreams => A_MANAGE_LIVE_STREAMS,
        RoomPermission::ControlPlaybackState => A_CONTROL_PLAYBACK_STATE,
        RoomPermission::NavigatePlayback => A_NAVIGATE_PLAYBACK,
        RoomPermission::ReviewJoinRequests => A_REVIEW_JOIN_REQUESTS,
        RoomPermission::RemoveMembers => A_REMOVE_MEMBERS,
        RoomPermission::ManageMemberPermissions => A_MANAGE_MEMBER_PERMISSIONS,
        RoomPermission::AddMembers => A_ADD_MEMBERS,
        RoomPermission::ManageRoomSettings => A_MANAGE_ROOM_SETTINGS,
        RoomPermission::DeleteChatMessages => A_DELETE_CHAT_MESSAGES,
        RoomPermission::DeleteRoom => A_DELETE_ROOM,
        RoomPermission::ViewPlaybackHistory => A_VIEW_PLAYBACK_HISTORY,
    }
}

/// `RoomPermissionSet::has`.
pub fn has(set: u64, p: RoomPermission) -> bool {
    let bit = bit_for(p);
    bit != 0 && (set & bit) != 0
}

/// `RoomPermissionSet::has_all`.
pub fn has_all(set: u64, required: u64) -> bool {
    (set & required) == required
}

/// `RoomPermissionSet::has_any`.
pub fn has_any(set: u64, required: u64) -> bool {
    (set & required) != 0
}

/// `RoomPermissionSet::all()`.
pub fn all() -> u64 {
    A_ALL
}

/// `RoomPermissionSet::default_admin()`.
pub fn default_admin() -> u64 {
    admin_to_permissions(A_DEFAULT)
}

/// `RoomPermissionSet::default_member()`.
pub fn default_member() -> u64 {
    member_to_permissions(M_ALL)
}

/// `RoomPermissionSet::default_guest()`.
pub fn default_guest() -> u64 {
    guest_to_permissions(G_DEFAULT)
}

/// `RoomPermissionSet::guest_assignable()`.
pub fn guest_assignable() -> u64 {
    guest_to_permissions(G_ALL)
}

/// `Role::permissions`.
pub fn role_permissions(r: Role) -> u64 {
    match r {
        Role::Creator => all(),
        Role::Admin => default_admin(),
        Role::Member => default_member(),
        Role::Guest => default_guest(),
    }
}

/// `Role::override_bits_from_permissions`.
pub fn override_bits_from_permissions(r: Role, p: u64) -> u64 {
    match r {
        Role::Creator => admin_from_permissions(p),
        Role::Admin => admin_from_permissions(p),
        Role::Member => member_from_permissions(p),
        Role::Guest => guest_from_permissions(p),
    }
}

/// The permission columns of a `room_members` row.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct MemberPerms {
    pub role: Role,
    pub added_permissions: u64,
    pub removed_permissions: u64,
    pub admin_added_permissions: u64,
    pub admin_removed_permissions: u64,
}

/// `RoomMember::effective_permissions`.
pub fn effective_permissions(m: &MemberPerms, role_default: u64) -> u64 {
    match m.role {
        Role::Creator => all(),
        Role::Admin => {
            (role_default | admin_to_permissions(m.admin_added_permissions))
                & !admin_to_permissions(m.admin_removed_permissions)
        }
        Role::Member => {
            (role_default | member_to_permissions(m.added_permissions))
                & !member_to_permissions(m.removed_permissions)
        }
        Role::Guest => {
            ((role_default & guest_assignable()) | guest_to_permissions(m.added_permissions))
                & !guest_to_permissions(m.removed_permissions)
        }
    }
}

/// `RoomMember::has_permission`.
pub fn member_has_permission(m: &MemberPerms, p: RoomPermission, role_default: u64) -> bool {
    has(effective_permissions(m, role_default), p)
}

/// The permission override columns of `RoomSettings`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct SettingsPerms {
    pub admin_added_permissions: u64,
    pub admin_removed_permissions: u64,
    pub member_added_permissions: u64,
    pub member_removed_permissions: u64,
    pub guest_added_permissions: u64,
    pub guest_removed_permissions: u64,
}

/// `RoomSettings::admin_permissions`.
pub fn settings_admin_permissions(s: &SettingsPerms, global_default: u64) -> u64 {
    (global_default | admin_to_permissions(s.admin_added_permissions))
        & !admin_to_permissions(s.admin_removed_permissions)
}

/// `RoomSettings::member_permissions`.
pub fn settings_member_permissions(s: &SettingsPerms, global_default: u64) -> u64 {
    (global_default | member_to_permissions(s.member_added_permissions))
        & !member_to_permissions(s.member_removed_permissions)
}

/// `RoomSettings::guest_permissions`.
pub fn settings_guest_permissions(s: &SettingsPerms, global_default: u64) -> u64 {
    ((global_default & guest_assignable()) | guest_to_permissions(s.guest_added_permissions))
        & !guest_to_permissions(s.guest_removed_permissions)
}

/// `RuntimePermissionDefaults`: the global (server-wide) role defaults.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Defaults {
    pub admin: u64,
    pub member: u64,
    pub guest: u64,
}

/// `EffectivePermissionCalculator::role_default`.
pub fn role_default(d: &Defaults, r: Role, s: &SettingsPerms) -> u64 {
    match r {
        Role::Creator => all(),
        Role::Admin => settings_admin_permissions(s, d.admin),
        Role::Member => settings_member_permissions(s, d.member),
        Role::Guest => settings_guest_permissions(s, d.guest),
    }
}

/// `EffectivePermissionCalculator::effective_for_member`.
pub fn effective_for_member(d: &Defaults, m: &MemberPerms, s: &SettingsPerms) -> u64 {
    effective_permissions(m, role_default(d, m.role, s))
}

/// `EffectivePermissionCalculator::has_permission`.
pub fn calculator_has_permission(
    d: &Defaults,
    m: &MemberPerms,
    s: &SettingsPerms,
    p: RoomPermission,
) -> bool {
    if !member_has_permission(m, p, all()) {
        return false;
    }
    has(effective_for_member(d, m, s), p)
}
