//! Session restoration, observations, revocation, and binding updates.
use oxicloud::domain::entities::session as upstream;
use oxicloud_kernel::session as port;
use chrono::{DateTime, Utc};
use uuid::Uuid;
use crate::tests::Rng;

fn origin(o: port::SessionOrigin) -> upstream::SessionOrigin {
    match o {
        port::SessionOrigin::Password => upstream::SessionOrigin::Password,
        port::SessionOrigin::Opaque => upstream::SessionOrigin::Opaque,
        port::SessionOrigin::MagicLink => upstream::SessionOrigin::MagicLink,
        port::SessionOrigin::Oidc => upstream::SessionOrigin::Oidc,
        port::SessionOrigin::Device => upstream::SessionOrigin::Device,
        port::SessionOrigin::Unknown => upstream::SessionOrigin::Unknown,
    }
}
fn time(t: port::Timestamp) -> DateTime<Utc> {
    DateTime::from_timestamp(t.seconds, t.nanoseconds).unwrap()
}
fn text(rng: &mut Rng) -> String {
    let alphabet = ['a', 'Z', '\0', 'é', '世', '🦀', '-', '_', ' '];
    (0..rng.below(24)).map(|_| rng.pick(&alphabet)).collect()
}
fn optional(rng: &mut Rng) -> Option<String> {
    if rng.below(2) == 0 { None } else { Some(text(rng)) }
}
fn check(p: &port::Session, u: &upstream::Session) {
    assert_eq!(Uuid::from_u128(port::id(p)), u.id());
    assert_eq!(Uuid::from_u128(port::user_id(p)), u.user_id());
    assert_eq!(port::refresh_token(p), u.refresh_token().as_bytes());
    assert_eq!(time(port::expires_at(p)), u.expires_at());
    assert_eq!(port::ip_address(p).as_deref(), u.ip_address().map(str::as_bytes));
    assert_eq!(port::user_agent(p).as_deref(), u.user_agent().map(str::as_bytes));
    assert_eq!(time(port::created_at(p)), u.created_at());
    assert_eq!(port::is_revoked(p), u.is_revoked());
    assert_eq!(Uuid::from_u128(port::family_id(p)), u.family_id());
    assert_eq!(port::oidc_id_token(p).as_deref(), u.oidc_id_token().map(str::as_bytes));
    assert_eq!(port::oidc_sid(p).as_deref(), u.oidc_sid().map(str::as_bytes));
    assert_eq!(port::dpop_jkt(p).as_deref(), u.dpop_jkt().map(str::as_bytes));
    assert_eq!(origin(port::origin(p)), u.origin());
    assert_eq!(time(port::last_seen_at(p)), u.last_seen_at());
}
#[test]
fn session_state_differential() {
    let mut rng = Rng(0xf139_b711_048f_e204);
    for _ in 0..10_000 {
        let origins = [port::SessionOrigin::Password, port::SessionOrigin::Opaque,
            port::SessionOrigin::MagicLink, port::SessionOrigin::Oidc,
            port::SessionOrigin::Device, port::SessionOrigin::Unknown];
        for o in origins {
            assert_eq!(port::origin_bytes(o), origin(o).as_str().as_bytes());
            assert_eq!(origin(port::origin_from_wire(origin(o).as_str().as_bytes())), origin(o));
        }
        let raw = text(&mut rng);
        assert_eq!(origin(port::origin_from_wire(raw.as_bytes())), upstream::SessionOrigin::from_wire(&raw));
        let id = (u128::from(rng.next()) << 64) | u128::from(rng.next());
        let user = (u128::from(rng.next()) << 64) | u128::from(rng.next());
        let family = (u128::from(rng.next()) << 64) | u128::from(rng.next());
        let token = text(&mut rng); let ip = optional(&mut rng); let ua = optional(&mut rng);
        let oidc = optional(&mut rng); let sid = optional(&mut rng); let jkt = optional(&mut rng);
        let revoked = rng.below(2) == 0; let o = rng.pick(&origins);
        let expires = port::Timestamp { seconds: (rng.below(4_000_000_000) as i64) - 2_000_000_000,
            nanoseconds: rng.below(1_000_000_000) as u32 };
        let created = port::Timestamp { seconds: -1, nanoseconds: 0 };
        let seen = port::Timestamp { seconds: 59, nanoseconds: 1_234_567_890 };
        let mut p = port::from_raw(id, user, token.as_bytes().to_vec(), expires,
            ip.as_ref().map(|s| s.as_bytes().to_vec()), ua.as_ref().map(|s| s.as_bytes().to_vec()),
            created, revoked, family, oidc.as_ref().map(|s| s.as_bytes().to_vec()),
            sid.as_ref().map(|s| s.as_bytes().to_vec()), jkt.as_ref().map(|s| s.as_bytes().to_vec()), o, seen);
        let mut u = upstream::Session::from_raw(Uuid::from_u128(id), Uuid::from_u128(user), token,
            time(expires), ip, ua, time(created), revoked, Uuid::from_u128(family), oidc, sid, jkt.clone(),
            origin(o), time(seen));
        check(&p, &u);
        port::revoke(&mut p); u.revoke(); check(&p, &u);
        port::revoke(&mut p); u.revoke(); check(&p, &u);
        let token = text(&mut rng);
        p = port::with_oidc_id_token(p, token.as_bytes().to_vec());
        u = u.with_oidc_id_token(token); check(&p, &u);
        let sid = text(&mut rng);
        p = port::with_oidc_sid(p, sid.as_bytes().to_vec()); u = u.with_oidc_sid(sid); check(&p, &u);
        if jkt.is_none() {
            let jkt = text(&mut rng);
            p = port::with_dpop_jkt(p, jkt.as_bytes().to_vec()); u = u.with_dpop_jkt(jkt); check(&p, &u);
        }
        // Both implementations reject replacing a bound key, including an empty binding.
        if port::dpop_jkt(&p).is_some() && rng.below(1000) == 0 {
            assert!(std::panic::catch_unwind(|| port::with_dpop_jkt(p, Vec::new())).is_err());
            assert!(std::panic::catch_unwind(|| u.with_dpop_jkt(String::new())).is_err());
        }
    }
}
