//! `perms` against synctv-core's `models::permission`, `models::room_member`,
//! `models::room_settings` and `service::permission::calculator`.
use crate::Rng;
use synctv_core::models::{
    RoomAdminPermissionBits as UA, RoomGuestPermissionBits as UG, RoomId, RoomMember,
    RoomMemberPermissionBits as UM, RoomPermission as UP, RoomPermissionSet, RoomRole, RoomSettings,
    UserId,
};
use synctv_core::service::{EffectivePermissionCalculator, RuntimePermissionDefaults};
use synctv_kernel::perms::{self as k, RoomPermission as KP};

pub const PERMS: [(KP, UP); 21] = [
    (KP::SendChatMessages, UP::SendChatMessages),
    (KP::ManageOwnMedia, UP::ManageOwnMedia),
    (KP::BrowseLibrary, UP::BrowseLibrary),
    (KP::ViewMembers, UP::ViewMembers),
    (KP::ViewChatHistory, UP::ViewChatHistory),
    (KP::UseVoiceChat, UP::UseVoiceChat),
    (KP::UseP2pMedia, UP::UseP2pMedia),
    (KP::DeleteMedia, UP::DeleteMedia),
    (KP::ReorderMedia, UP::ReorderMedia),
    (KP::ClearMedia, UP::ClearMedia),
    (KP::ManageLiveStreams, UP::ManageLiveStreams),
    (KP::ControlPlaybackState, UP::ControlPlaybackState),
    (KP::NavigatePlayback, UP::NavigatePlayback),
    (KP::ReviewJoinRequests, UP::ReviewJoinRequests),
    (KP::RemoveMembers, UP::RemoveMembers),
    (KP::ManageMemberPermissions, UP::ManageMemberPermissions),
    (KP::AddMembers, UP::AddMembers),
    (KP::ManageRoomSettings, UP::ManageRoomSettings),
    (KP::DeleteChatMessages, UP::DeleteChatMessages),
    (KP::DeleteRoom, UP::DeleteRoom),
    (KP::ViewPlaybackHistory, UP::ViewPlaybackHistory),
];

pub const ROLES: [(k::Role, RoomRole); 4] = [
    (k::Role::Creator, RoomRole::Creator),
    (k::Role::Admin, RoomRole::Admin),
    (k::Role::Member, RoomRole::Member),
    (k::Role::Guest, RoomRole::Guest),
];

const MASKS: [u64; 4] = [UM::ALL, UA::ALL, UG::ALL, UA::ALL | UG::ALL];

#[test]
fn constants_match() {
    let member = [
        (k::M_SEND_CHAT_MESSAGES, UM::SEND_CHAT_MESSAGES),
        (k::M_MANAGE_OWN_MEDIA, UM::MANAGE_OWN_MEDIA),
        (k::M_BROWSE_LIBRARY, UM::BROWSE_LIBRARY),
        (k::M_VIEW_MEMBERS, UM::VIEW_MEMBERS),
        (k::M_VIEW_CHAT_HISTORY, UM::VIEW_CHAT_HISTORY),
        (k::M_USE_VOICE_CHAT, UM::USE_VOICE_CHAT),
        (k::M_USE_P2P_MEDIA, UM::USE_P2P_MEDIA),
        (k::M_ALL, UM::ALL),
    ];
    let admin = [
        (k::A_SEND_CHAT_MESSAGES, UA::SEND_CHAT_MESSAGES),
        (k::A_MANAGE_OWN_MEDIA, UA::MANAGE_OWN_MEDIA),
        (k::A_BROWSE_LIBRARY, UA::BROWSE_LIBRARY),
        (k::A_VIEW_MEMBERS, UA::VIEW_MEMBERS),
        (k::A_VIEW_CHAT_HISTORY, UA::VIEW_CHAT_HISTORY),
        (k::A_USE_VOICE_CHAT, UA::USE_VOICE_CHAT),
        (k::A_DELETE_MEDIA, UA::DELETE_MEDIA),
        (k::A_REORDER_MEDIA, UA::REORDER_MEDIA),
        (k::A_CLEAR_MEDIA, UA::CLEAR_MEDIA),
        (k::A_MANAGE_LIVE_STREAMS, UA::MANAGE_LIVE_STREAMS),
        (k::A_CONTROL_PLAYBACK_STATE, UA::CONTROL_PLAYBACK_STATE),
        (k::A_NAVIGATE_PLAYBACK, UA::NAVIGATE_PLAYBACK),
        (k::A_REVIEW_JOIN_REQUESTS, UA::REVIEW_JOIN_REQUESTS),
        (k::A_REMOVE_MEMBERS, UA::REMOVE_MEMBERS),
        (k::A_MANAGE_MEMBER_PERMISSIONS, UA::MANAGE_MEMBER_PERMISSIONS),
        (k::A_ADD_MEMBERS, UA::ADD_MEMBERS),
        (k::A_MANAGE_ROOM_SETTINGS, UA::MANAGE_ROOM_SETTINGS),
        (k::A_DELETE_CHAT_MESSAGES, UA::DELETE_CHAT_MESSAGES),
        (k::A_DELETE_ROOM, UA::DELETE_ROOM),
        (k::A_VIEW_PLAYBACK_HISTORY, UA::VIEW_PLAYBACK_HISTORY),
        (k::A_USE_P2P_MEDIA, UA::USE_P2P_MEDIA),
        (k::A_ALL, UA::ALL),
        (k::A_DEFAULT, UA::DEFAULT),
    ];
    let guest = [
        (k::G_VIEW_MEMBERS, UG::VIEW_MEMBERS),
        (k::G_VIEW_CHAT_HISTORY, UG::VIEW_CHAT_HISTORY),
        (k::G_USE_VOICE_CHAT, UG::USE_VOICE_CHAT),
        (k::G_USE_P2P_MEDIA, UG::USE_P2P_MEDIA),
        (k::G_ALL, UG::ALL),
        (k::G_DEFAULT, UG::DEFAULT),
    ];
    for (a, b) in member.iter().chain(admin.iter()).chain(guest.iter()) {
        assert_eq!(a, b);
    }
    assert_eq!(k::all(), RoomPermissionSet::all().0);
    assert_eq!(k::default_admin(), RoomPermissionSet::default_admin().0);
    assert_eq!(k::default_member(), RoomPermissionSet::default_member().0);
    assert_eq!(k::default_guest(), RoomPermissionSet::default_guest().0);
    assert_eq!(k::guest_assignable(), RoomPermissionSet::guest_assignable().0);
    for (kp, up) in PERMS {
        assert_eq!(k::bit_for(kp), UA::bit_for(up), "{kp:?}");
    }
    for (kr, ur) in ROLES {
        assert_eq!(k::role_permissions(kr), ur.permissions().0, "{kr:?}");
    }
}

fn check_maps(b: u64) {
    assert_eq!(k::member_to_permissions(b), UM::to_permissions(b), "member to {b:#x}");
    assert_eq!(k::member_from_permissions(b), UM::from_permissions(b), "member from {b:#x}");
    assert_eq!(k::admin_to_permissions(b), UA::to_permissions(b), "admin to {b:#x}");
    assert_eq!(k::admin_from_permissions(b), UA::from_permissions(b), "admin from {b:#x}");
    assert_eq!(k::guest_to_permissions(b), UG::to_permissions(b), "guest to {b:#x}");
    assert_eq!(k::guest_from_permissions(b), UG::from_permissions(b), "guest from {b:#x}");
    assert_eq!(k::member_includes_only_defined(b), UM::includes_only_defined(b));
    assert_eq!(k::admin_includes_only_defined(b), UA::includes_only_defined(b));
    assert_eq!(k::guest_includes_only_defined(b), UG::includes_only_defined(b));
    for (kr, ur) in ROLES {
        assert_eq!(k::override_bits_from_permissions(kr, b), ur.override_bits_from_permissions(b));
    }
}

/// Every subset of the admin bitspace (2^21), each also with a random bit above it;
/// every subset of the guest bitspace; and 200k mixed-shape random values.
#[test]
fn bitspace_maps_agree() {
    let mut r = Rng(0x5157_0001);
    let mut n = 0u64;
    for s in 0..=UA::ALL {
        check_maps(s);
        check_maps(s | (1u64 << (21 + r.below(43))));
        n += 2;
    }
    for g in 0..16u64 {
        for low in [0, UA::ALL, r.next() & UA::ALL] {
            check_maps((g << 32) | low);
            n += 1;
        }
    }
    for _ in 0..200_000 {
        check_maps(r.bits(&MASKS));
        n += 1;
    }
    eprintln!("bitspace_maps_agree: {n} values");
}

#[test]
fn has_agrees() {
    let mut r = Rng(0x5157_0002);
    for _ in 0..100_000 {
        let s = r.bits(&MASKS);
        let q = r.bits(&MASKS);
        let set = RoomPermissionSet(s);
        for (kp, up) in PERMS {
            assert_eq!(k::has(s, kp), set.has(up), "{s:#x} {kp:?}");
        }
        assert_eq!(k::has_all(s, q), set.has_all(RoomPermissionSet(q)));
        assert_eq!(k::has_any(s, q), set.has_any(RoomPermissionSet(q)));
    }
}

fn upstream_member(m: &k::MemberPerms, ur: RoomRole) -> RoomMember {
    let mut u = RoomMember::new(RoomId::try_from(7i64).unwrap(), UserId::try_from(9i64).unwrap(), ur);
    u.added_permissions = m.added_permissions;
    u.removed_permissions = m.removed_permissions;
    u.admin_added_permissions = m.admin_added_permissions;
    u.admin_removed_permissions = m.admin_removed_permissions;
    u
}

fn random_member(r: &mut Rng) -> (k::MemberPerms, RoomRole) {
    let (kr, ur) = ROLES[r.below(4) as usize];
    let m = k::MemberPerms {
        role: kr,
        added_permissions: r.bits(&MASKS),
        removed_permissions: r.bits(&MASKS),
        admin_added_permissions: r.bits(&MASKS),
        admin_removed_permissions: r.bits(&MASKS),
    };
    (m, ur)
}

fn random_settings(r: &mut Rng) -> (k::SettingsPerms, RoomSettings) {
    let s = k::SettingsPerms {
        admin_added_permissions: r.bits(&MASKS),
        admin_removed_permissions: r.bits(&MASKS),
        member_added_permissions: r.bits(&MASKS),
        member_removed_permissions: r.bits(&MASKS),
        guest_added_permissions: r.bits(&MASKS),
        guest_removed_permissions: r.bits(&MASKS),
    };
    let mut u = RoomSettings::default();
    u.admin_added_permissions.0 = s.admin_added_permissions;
    u.admin_removed_permissions.0 = s.admin_removed_permissions;
    u.member_added_permissions.0 = s.member_added_permissions;
    u.member_removed_permissions.0 = s.member_removed_permissions;
    u.guest_added_permissions.0 = s.guest_added_permissions;
    u.guest_removed_permissions.0 = s.guest_removed_permissions;
    (s, u)
}

#[test]
fn effective_permissions_agree() {
    let mut r = Rng(0x5157_0003);
    for _ in 0..200_000 {
        let (m, ur) = random_member(&mut r);
        let d = r.bits(&MASKS);
        let um = upstream_member(&m, ur);
        let ue = um.effective_permissions(RoomPermissionSet(d));
        assert_eq!(k::effective_permissions(&m, d), ue.0, "{m:?} {d:#x}");
        for (kp, up) in PERMS {
            assert_eq!(k::member_has_permission(&m, kp, d), um.has_permission(up, RoomPermissionSet(d)));
        }
    }
}

#[test]
fn calculator_agrees() {
    let mut r = Rng(0x5157_0004);
    for i in 0..100_000 {
        let d = if i % 5 == 0 {
            k::Defaults { admin: k::default_admin(), member: k::default_member(), guest: k::default_guest() }
        } else {
            k::Defaults { admin: r.bits(&MASKS), member: r.bits(&MASKS), guest: r.bits(&MASKS) }
        };
        let calc = EffectivePermissionCalculator::new(RuntimePermissionDefaults {
            admin: RoomPermissionSet(d.admin),
            member: RoomPermissionSet(d.member),
            guest: RoomPermissionSet(d.guest),
        });
        let (s, us) = random_settings(&mut r);
        assert_eq!(k::settings_admin_permissions(&s, d.admin), us.admin_permissions(RoomPermissionSet(d.admin)).0);
        assert_eq!(k::settings_member_permissions(&s, d.member), us.member_permissions(RoomPermissionSet(d.member)).0);
        assert_eq!(k::settings_guest_permissions(&s, d.guest), us.guest_permissions(RoomPermissionSet(d.guest)).0);
        for (kr, ur) in ROLES {
            assert_eq!(k::role_default(&d, kr, &s), calc.role_default(&ur, &us).0);
        }
        let (m, ur) = random_member(&mut r);
        let um = upstream_member(&m, ur);
        assert_eq!(k::effective_for_member(&d, &m, &s), calc.effective_for_member(&um, &us).0);
        for (kp, up) in PERMS {
            assert_eq!(
                k::calculator_has_permission(&d, &m, &s, kp),
                calc.has_permission(&um, &us, up),
                "{m:?} {s:?} {d:?} {kp:?}"
            );
        }
    }
}
