//! `user` against `synctv_core::models::User`.
use synctv_core::models::{SignupMethod as USM, User, UserRole as UR, UserStatus as US};
use synctv_kernel::auth::{UserRole as KR, UserStatus as KS};
use synctv_kernel::user::{self as k, SignupMethod as KSM};

#[test]
fn user_gates_agree() {
    let roles = [(KR::Root, UR::Root), (KR::Admin, UR::Admin), (KR::User, UR::User)];
    let statuses = [(KS::Active, US::Active), (KS::Banned, US::Banned)];
    let methods = [
        (KSM::Unknown, USM::Unknown),
        (KSM::Email, USM::Email),
        (KSM::Password, USM::Password),
        (KSM::OAuth2, USM::OAuth2),
        (KSM::AdminCreated, USM::AdminCreated),
        (KSM::WebAuthn, USM::WebAuthn),
    ];
    let mut n = 0;
    for (kr, ur) in roles {
        for (ks, us) in statuses {
            for banned in [false, true] {
                for deleted in [false, true] {
                    for (km, um) in methods {
                        let mut u = User::new("u".to_string(), um);
                        u.role = ur;
                        u.status = us;
                        u.is_banned = banned;
                        u.deleted_at = deleted.then(chrono::Utc::now);
                        let f = k::UserFacts { role: kr, status: ks, is_banned: banned, deleted, signup_method: km };
                        assert_eq!(k::user_is_root(&f), u.is_root());
                        assert_eq!(k::user_is_admin(&f), u.is_admin());
                        assert_eq!(k::user_is_admin_or_above(&f), u.is_admin_or_above());
                        assert_eq!(k::user_can_login(&f), u.can_login(), "{f:?}");
                        assert_eq!(k::user_can_join_room(&f), u.can_join_room());
                        for allow in [false, true] {
                            assert_eq!(k::user_can_create_room(&f, allow), u.can_create_room(allow), "{f:?} {allow}");
                        }
                        for c in 0..4usize {
                            for e in [false, true] {
                                assert_eq!(k::user_can_unbind_provider(&f, c), u.can_unbind_provider(c, e));
                            }
                        }
                        n += 1;
                    }
                }
            }
        }
    }
    eprintln!("user_gates_agree: {n} users (exhaustive)");
}
