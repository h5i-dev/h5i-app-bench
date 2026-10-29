//! The pinned upstream user-role implementation and the byte-oriented port.
use oxicloud::domain::entities::user::UserRole as Upstream;
use oxicloud_kernel::userrole::{self as port, UserRole as Kernel};
use crate::tests::Rng;

fn upstream(role: Kernel) -> Upstream {
    match role {
        Kernel::Owner => Upstream::Owner,
        Kernel::Admin => Upstream::Admin,
        Kernel::User => Upstream::User,
        Kernel::Anonymous => Upstream::Anonymous,
    }
}

fn wire(role: Option<Kernel>) -> Option<Vec<u8>> {
    role.map(port::as_bytes)
}

fn check_raw(raw: &str) {
    assert_eq!(wire(port::from_stored(raw.as_bytes())),
        Upstream::from_stored(raw).map(|r| r.as_str().as_bytes().to_vec()), "stored: {raw:?}");
    assert_eq!(wire(port::from_session(raw.as_bytes())),
        Upstream::from_session(raw).map(|r| r.as_str().as_bytes().to_vec()), "session: {raw:?}");
    for min in [Kernel::Owner, Kernel::Admin, Kernel::User, Kernel::Anonymous] {
        assert_eq!(port::str_at_least(raw.as_bytes(), min),
            Upstream::str_at_least(raw, upstream(min)), "requirement: {raw:?}");
    }
}

#[test]
fn user_role_differential() {
    let roles = [Kernel::Owner, Kernel::Admin, Kernel::User, Kernel::Anonymous];
    for role in roles {
        let original = upstream(role);
        assert_eq!(port::as_bytes(role), original.as_str().as_bytes());
        assert_eq!(port::rank(role), original.rank());
        assert_eq!(port::is_anonymous(role), original.is_anonymous());
        assert_eq!(port::is_privileged(role), original.is_privileged());
        for min in roles {
            assert_eq!(port::at_least(role, min), original.at_least(upstream(min)));
            assert_eq!(port::outranks(role, min), original.outranks(upstream(min)));
        }
    }
    for raw in ["", "owner", "admin", "user", "anonymous", "Owner", "ADMIN", " user",
        "user ", "user\0", "anonymous\n", "管理员", "usér", "🔐"] {
        check_raw(raw);
    }
    let mut rng = Rng(0x93a5_e0d1_81c7_264b);
    for _ in 0..10_000 {
        let len = rng.below(24);
        let mut raw = String::new();
        for _ in 0..len {
            let codepoint = rng.below(0x11_0000) as u32;
            if let Some(c) = char::from_u32(codepoint) { raw.push(c); }
        }
        check_raw(&raw);
        let mut spelling = upstream(rng.pick(&roles)).as_str().as_bytes().to_vec();
        let index = rng.below(spelling.len() as u64) as usize;
        spelling[index] = rng.below(128) as u8;
        check_raw(std::str::from_utf8(&spelling).unwrap());
    }
}
