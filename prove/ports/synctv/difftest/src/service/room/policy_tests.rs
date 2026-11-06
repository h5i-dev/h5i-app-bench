//! `policy` against the verbatim `member_role_policy.rs` and kick-cooldown validator.
//! Compiled inside `crate::service::room` so their `pub(in crate::service::room)`
//! visibility admits these calls.
use super::member_kick;
use super::member_role_policy as up;
use crate::Rng;
use synctv_core::models::{
    Room, RoomAdminPermissionBits as UA, RoomGuestPermissionBits as UG,
    RoomMemberPermissionBits as UM, RoomRole, UserId,
};
use synctv_core::Error;
use synctv_kernel::perms::Role as KR;
use synctv_kernel::policy::{self as k, PolicyError};

const ROLES: [(KR, RoomRole); 4] = [
    (KR::Creator, RoomRole::Creator),
    (KR::Admin, RoomRole::Admin),
    (KR::Member, RoomRole::Member),
    (KR::Guest, RoomRole::Guest),
];

fn kind(r: synctv_core::Result<()>) -> Result<(), PolicyError> {
    match r {
        Ok(()) => Ok(()),
        Err(Error::InvalidInput(_)) => Err(PolicyError::InvalidInput),
        Err(Error::Authorization(_)) => Err(PolicyError::Authorization),
        Err(Error::NotFound(_)) => Err(PolicyError::NotFound),
        Err(e) => panic!("unexpected upstream error {e:?}"),
    }
}

fn room(created_by: i64) -> Room {
    Room::new("r".to_string(), UserId::try_from(created_by).unwrap())
}

fn uid(i: i64) -> UserId {
    UserId::try_from(i).unwrap()
}

#[test]
fn role_validators_agree() {
    let mut n = 0;
    for (kr, ur) in ROLES {
        assert_eq!(k::validate_role_can_be_assigned(kr), kind(up::validate_role_can_be_assigned(ur)));
        for c in 1..=3i64 {
            let rm = room(c);
            assert_eq!(
                k::validate_admin_member_role_update(c, c + 1),
                kind(up::validate_admin_member_role_update(&rm, &uid(c + 1)))
            );
            for a in 1..=3i64 {
                assert_eq!(
                    k::validate_add_member_role(c, a, kr),
                    kind(up::validate_add_member_role(&rm, &uid(a), ur))
                );
                assert_eq!(
                    k::validate_admin_member_role_update(c, a),
                    kind(up::validate_admin_member_role_update(&rm, &uid(a)))
                );
                for t in 1..=3i64 {
                    assert_eq!(
                        k::validate_creator_member_role_update(c, a, t),
                        kind(up::validate_creator_member_role_update(&rm, &uid(a), &uid(t)))
                    );
                    n += 1;
                }
            }
        }
    }
    eprintln!("role_validators_agree: {n} cases");
}

#[test]
fn override_validators_agree() {
    let mut r = Rng(0x5157_0101);
    let masks = [UM::ALL, UA::ALL, UG::ALL, UA::ALL | UG::ALL];
    for _ in 0..200_000 {
        let a = r.bits(&masks);
        let b = r.bits(&masks);
        let c = r.bits(&masks);
        let d = r.bits(&masks);
        assert_eq!(k::validate_admin_override_bits(a, b), kind(up::validate_admin_override_bits(a, b)));
        for (kr, ur) in ROLES {
            assert_eq!(
                k::validate_override_bits_for_role(kr, a, b),
                kind(up::validate_override_bits_for_role(ur, a, b))
            );
        }
        for adm in [false, true] {
            let pick = |x: u64, z: bool| if z { 0 } else { x };
            let (a2, b2, c2, d2) = (pick(a, r.bool()), pick(b, r.bool()), pick(c, r.bool()), pick(d, r.bool()));
            assert_eq!(
                k::validate_member_permission_override_channel(adm, a2, b2, c2, d2),
                kind(up::validate_member_permission_override_channel(adm, a2, b2, c2, d2))
            );
        }
    }
}

#[test]
fn kick_cooldown_agrees() {
    assert_eq!(k::MAX_KICK_COOLDOWN_SECONDS, member_kick::MAX_KICK_COOLDOWN_SECONDS);
    let mut r = Rng(0x5157_0102);
    let m = k::MAX_KICK_COOLDOWN_SECONDS;
    let mut cases = vec![i64::MIN, i64::MIN + 1, -1, 0, 1, 2, m - 1, m, m + 1, i64::MAX - 1, i64::MAX];
    for _ in 0..100_000 {
        cases.push(r.next() as i64);
        cases.push((r.below(2 * m as u64 + 10) as i64) - 5);
    }
    for c in cases {
        assert_eq!(k::validate_kick_cooldown_seconds(c), kind(member_kick::validate(c)), "{c}");
    }
}
