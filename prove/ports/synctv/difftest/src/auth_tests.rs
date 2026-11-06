//! `auth` against synctv-core's `UserRole`/`UserStatus`, `JwtService` (real HS256 tokens
//! under a controlled clock), `GuestTokenValidator`, `JwtValidator::extract_bearer_token`
//! and the verbatim `validate_expiration`.
use crate::Rng;
use chrono::{DateTime, Utc};
use std::sync::atomic::{AtomicI64, Ordering};
use std::sync::Arc;
use synctv_core::models::{RoomId, UserId, UserRole as UR, UserStatus as US};
use synctv_core::service::{
    GuestTokenValidator, InMemoryTokenBlacklistStore, JwtService, JwtServiceOptions, JwtValidator,
};
use synctv_core::{Clock, Error, KeyBuilder};
use synctv_kernel::auth::{self as k, AuthError, BearerError, TokenType};

const UROLES: [(k::UserRole, UR); 3] =
    [(k::UserRole::Root, UR::Root), (k::UserRole::Admin, UR::Admin), (k::UserRole::User, UR::User)];

#[test]
fn global_roles_agree() {
    for (ka, ua) in UROLES {
        assert_eq!(k::is_admin_or_above(ka), ua.is_admin_or_above());
        for (kb, ub) in UROLES {
            assert_eq!(k::can_manage(ka, kb), ua.can_manage(&ub), "{ka:?} {kb:?}");
        }
    }
    for (ks, us) in [(k::UserStatus::Active, US::Active), (k::UserStatus::Banned, US::Banned)] {
        assert_eq!(k::status_is_active(ks), us.is_active());
        assert_eq!(k::status_is_banned(ks), us.is_banned());
        assert_eq!(k::status_can_login(ks), us.can_login());
        assert_eq!(k::status_can_login(ks), us.can_create_room());
        assert_eq!(k::status_can_login(ks), us.can_join_room());
    }
}

struct TestClock(AtomicI64);

impl Clock for TestClock {
    fn now(&self) -> DateTime<Utc> {
        DateTime::from_timestamp(self.0.load(Ordering::SeqCst), 0).expect("in range")
    }
}

fn kind(r: &synctv_core::Result<impl Sized>) -> Result<(), AuthError> {
    match r {
        Ok(_) => Ok(()),
        Err(Error::Authentication(_)) => Err(AuthError::Authentication),
        Err(Error::ServiceUnavailable(_)) => Err(AuthError::ServiceUnavailable),
        Err(Error::Authorization(_)) => Err(AuthError::Authorization),
        Err(e) => panic!("unexpected upstream error {e:?}"),
    }
}

/// Clock values chrono can represent (`DateTime::from_timestamp`).
const T_MIN: i64 = -8_000_000_000_000;
const T_MAX: i64 = 8_000_000_000_000;

#[test]
fn expiration_agrees() {
    let mut r = Rng(0x5157_0201);
    let clock = TestClock(AtomicI64::new(0));
    let leeways = [0u64, 1, 30, 60, 3600, i64::MAX as u64 - 1, i64::MAX as u64, i64::MAX as u64 + 1, u64::MAX];
    let mut n = 0;
    for _ in 0..200_000 {
        let now = T_MIN + (r.below((T_MAX - T_MIN) as u64) as i64);
        let leeway = if r.bool() { leeways[r.below(leeways.len() as u64) as usize] } else { r.next() >> r.below(64) };
        let exp = match r.below(4) {
            0 => r.next() as i64,
            1 => now.saturating_sub(leeway.min(i64::MAX as u64) as i64).saturating_add(r.below(7) as i64 - 3),
            2 => [i64::MIN, i64::MAX, i64::MAX - 1, 0][r.below(4) as usize],
            _ => now + r.below(1000) as i64 - 500,
        };
        clock.0.store(now, Ordering::SeqCst);
        let up = crate::service::jwt::validate(&clock, exp, leeway);
        assert_eq!(k::validate_expiration(now, exp, leeway), kind(&up), "now={now} exp={exp} leeway={leeway}");
        n += 1;
    }
    eprintln!("expiration_agrees: {n} cases");
}

const SECRET: &str = "Zq7#Lp2$Wm9@Rt4&Xv8*Ky3!Nb6^Hd1%Jf5_Gs0+Qc";

fn service(clock: Arc<TestClock>, access_h: u64, guest_h: u64, leeway: u64) -> Arc<JwtService> {
    Arc::new(
        JwtService::with_options(JwtServiceOptions {
            secret: SECRET.to_string(),
            access_token_duration_hours: access_h,
            refresh_token_duration_days: 1,
            guest_token_duration_hours: guest_h,
            clock_skew_leeway_secs: leeway,
            issuer: None,
            audience: None,
            clock,
        })
        .expect("jwt service"),
    )
}

/// Real tokens signed at `t0` and verified at `now` around the expiry boundary.
#[test]
fn user_and_guest_tokens_agree() {
    let mut r = Rng(0x5157_0202);
    let clock = Arc::new(TestClock(AtomicI64::new(0)));
    let mut n = 0;
    for i in 0..3_000 {
        let access_h = 1 + r.below(48);
        let guest_h = 1 + r.below(8);
        let leeway = [0u64, 1, 60, 3600, u64::MAX][r.below(5) as usize];
        let jwt = service(clock.clone(), access_h, guest_h, leeway);
        let t0 = 1_700_000_000 + (r.below(1 << 30) as i64);
        clock.0.store(t0, Ordering::SeqCst);
        let user = UserId::try_from(1 + r.below(1000) as i64).unwrap();
        let access = jwt.sign_access_token(&user, 0).unwrap();
        let refresh = jwt
            .sign_refresh_token_with_session(
                &user,
                0,
                None,
                "session-0123456789",
                &synctv_core::service::TokenCredentialBinding::Password { version: 0 },
            )
            .unwrap();
        let gv = r.below(5) as i64;
        let room = RoomId::try_from(1 + r.below(1000) as i64).unwrap();
        let guest = jwt.sign_guest_token_with_version(&room, gv).unwrap();
        let access_exp = t0 + access_h as i64 * 3600;
        let refresh_exp = t0 + 86_400;
        let guest_exp = t0 + guest_h as i64 * 3600;
        let validator = GuestTokenValidator::new(
            jwt.clone(),
            Arc::new(InMemoryTokenBlacklistStore::new(16, 60, 60)),
            KeyBuilder::new("difftest"),
        );
        for _ in 0..8 {
            let base = [access_exp, refresh_exp, guest_exp, t0][r.below(4) as usize];
            let lw = if leeway == u64::MAX { 0 } else { leeway as i64 };
            let now = base + lw + r.below(7) as i64 - 3 - if r.bool() { r.below(200_000) as i64 } else { 0 };
            clock.0.store(now, Ordering::SeqCst);
            for (token, typ, exp) in [
                (&access, TokenType::Access, access_exp),
                (&refresh, TokenType::Refresh, refresh_exp),
            ] {
                assert_eq!(
                    k::accept_user_token(now, exp, leeway, typ, TokenType::Access),
                    kind(&jwt.verify_access_token(token)),
                    "{i} access {typ:?} now={now} exp={exp} leeway={leeway}"
                );
                assert_eq!(
                    k::accept_user_token(now, exp, leeway, typ, TokenType::Refresh),
                    kind(&jwt.verify_refresh_token(token)),
                    "{i} refresh {typ:?} now={now} exp={exp} leeway={leeway}"
                );
            }
            // A guest token is not a user token: upstream's serde tag rejects it in
            // `decode`, the kernel by its type. Both are `Authentication`.
            assert_eq!(
                k::accept_user_token(now, guest_exp, leeway, TokenType::Guest, TokenType::Access),
                kind(&jwt.verify_access_token(&guest))
            );
            let room_version = r.below(7) as i64 - 1;
            assert_eq!(
                k::accept_guest_token(now, guest_exp, leeway, gv, room_version),
                kind(&validator.validate_with_version(&guest, room_version)),
                "{i} guest now={now} exp={guest_exp} gv={gv} room={room_version}"
            );
            n += 1;
        }
    }
    eprintln!("user_and_guest_tokens_agree: {n} rounds");
}

fn bearer_kind(r: &synctv_core::Result<String>) -> Result<String, BearerError> {
    match r {
        Ok(s) => Ok(s.clone()),
        Err(Error::Authentication(m)) if m.contains("cannot be empty") => Err(BearerError::Empty),
        Err(Error::Authentication(m)) if m.contains("must start with") => Err(BearerError::BadScheme),
        Err(e) => panic!("unexpected upstream error {e:?}"),
    }
}

/// Visible ASCII plus tab, which is what `HeaderValue::to_str` admits; also the other
/// ASCII whitespace `str::trim` removes.
fn random_header(r: &mut Rng) -> String {
    const PREFIXES: [&str; 8] = ["Bearer ", "bearer ", "BEARER ", "BeArEr ", "Bearer", "Basic ", "Bearer\t", ""];
    const ALPHABET: &[u8] = b"abcXYZ019.-_ \t\r\n\x0b\x0cBearer";
    let mut s = String::from(PREFIXES[r.below(PREFIXES.len() as u64) as usize]);
    let len = r.below(12);
    for _ in 0..len {
        let c = if r.below(4) == 0 { (0x20 + r.below(0x5f)) as u8 } else { ALPHABET[r.below(ALPHABET.len() as u64) as usize] };
        s.push(c as char);
    }
    s
}

#[test]
fn bearer_extraction_agrees() {
    let mut r = Rng(0x5157_0203);
    let mut n = 0;
    for _ in 0..300_000 {
        let h = random_header(&mut r);
        let kr = k::extract_bearer_token(h.as_bytes()).map(|(a, b)| h[a..b].to_string());
        assert_eq!(kr, bearer_kind(&JwtValidator::extract_bearer_token(&h)), "{h:?}");
        n += 1;
    }
    eprintln!("bearer_extraction_agrees: {n} headers");
}

/// FINDING (latent, not reachable through the current callers): `extract_bearer_token`
/// slices `auth_value[..7]` by bytes, which panics when byte 7 falls inside a multi-byte
/// UTF-8 character. Both callers pass `HeaderValue::to_str()` output (visible ASCII only).
#[test]
fn bearer_extraction_panics_on_non_ascii() {
    let r = std::panic::catch_unwind(|| JwtValidator::extract_bearer_token("Bearer\u{e9}x"));
    assert!(r.is_err(), "upstream no longer panics; update DEVIATIONS.md");
}
