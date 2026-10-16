//! The kernel against the copied upstream services, on random snapshots and
//! requests. Both start from the same database and cache; the test compares
//! the reply, the committed database and the cache afterwards.
use std::collections::BTreeMap;
use std::sync::atomic::AtomicU64;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use bootstrapacademy_kernel as k;
use chrono::NaiveTime;

use crate::mem::*;
use crate::upstream::academy_auth_impl::{
    AuthServiceConfig, AuthServiceImpl, access_token::AuthAccessTokenServiceImpl,
    refresh_token::AuthRefreshTokenServiceImpl,
};
use crate::upstream::academy_core_coin_contracts::{CoinAddCoinsError, CoinFeatureService, CoinGetBalanceError};
use crate::upstream::academy_core_coin_impl::{CoinFeatureServiceImpl, coin::CoinServiceImpl};
use crate::upstream::academy_core_heart_contracts::{HeartFeatureService, HeartGetError, HeartRefillError};
use crate::upstream::academy_core_heart_impl::{HeartFeatureConfig, HeartFeatureServiceImpl, heart::HeartServiceImpl};
use crate::upstream::academy_core_mfa_contracts::{MfaDisableError, MfaEnableError, MfaFeatureService, MfaInitializeError};
use crate::upstream::academy_core_mfa_impl::{
    MfaFeatureServiceImpl, authenticate::MfaAuthenticateServiceImpl, disable::MfaDisableServiceImpl,
    recovery::MfaRecoveryServiceImpl, totp_device::MfaTotpDeviceServiceImpl,
};
use crate::upstream::academy_core_session_contracts::{
    SessionCreateCommand, SessionCreateError, SessionDeleteByUserError, SessionDeleteCurrentError,
    SessionDeleteError, SessionFeatureService, SessionGetCurrentError, SessionImpersonateError,
    SessionListByUserError, SessionRefreshError,
};
use crate::upstream::academy_core_session_impl::{
    SessionFeatureConfig, SessionFeatureServiceImpl, failed_auth_count::SessionFailedAuthCountServiceImpl,
    login_throttle::{SessionLoginThrottleConfig, SessionLoginThrottleServiceImpl},
    session::SessionServiceImpl,
};
use crate::upstream::academy_core_withdrawal_impl::consent::WithdrawalConsentServiceImpl;
use crate::upstream::academy_models::{
    auth::{AccessToken, AuthError, AuthenticateError, AuthorizeError, Login, RefreshToken},
    mfa::{MfaAuthentication, MfaRecoveryCode, TotpCode},
    session::{DeviceName, Session},
    user::{EmailAddress, UserId, UserIdOrSelf, UserName, UserNameOrEmailAddress, UserPassword},
    withdrawal::{WithdrawalConsentDeclaration, WithdrawalTextVersion},
};

/// xorshift64*, so the test needs no dependencies.
pub(crate) struct Rng(pub(crate) u64);
impl Rng {
    pub(crate) fn next(&mut self) -> u64 {
        self.0 ^= self.0 >> 12;
        self.0 ^= self.0 << 25;
        self.0 ^= self.0 >> 27;
        self.0.wrapping_mul(0x2545F4914F6CDD1D)
    }
    pub(crate) fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
    pub(crate) fn chance(&mut self, pct: u64) -> bool {
        self.below(100) < pct
    }
    pub(crate) fn pick<'a, T>(&mut self, v: &'a [T]) -> &'a T {
        &v[self.below(v.len() as u64) as usize]
    }
}

const NAMES: &[&str] = &["ann", "bob", "cy", "dee"];
pub(crate) const FRESH: u64 = 1000;
pub(crate) const T0: u64 = 8_640_000;

fn b(s: &str) -> Vec<u8> {
    s.as_bytes().to_vec()
}

/// Random ASCII case.
fn spell(r: &mut Rng, s: &str) -> Vec<u8> {
    s.bytes().map(|c| if r.chance(30) { c.to_ascii_uppercase() } else { c }).collect()
}

pub(crate) fn config(r: &mut Rng) -> k::Config {
    k::Config {
        access_token_ttl: 1 + r.below(5),
        refresh_token_ttl: 1 + r.below(30),
        login_fails_before_captcha: r.below(5),
        fails_before_lock: r.below(5),
        fail_window: 1 + r.below(10),
        lock_initial: r.below(6),
        lock_max: r.below(40),
        fails_per_ip: r.below(7),
        ip_window: 1 + r.below(10),
        hearts_max: r.below(6),
        hearts_refill_price: r.below(6),
        auto_refill_time: *r.pick(&[0, 3600, 86399, 43200]),
    }
}

/// A random database and cache around `now`: a few users, sessions and
/// devices, with ids from small ranges so requests hit them.
pub(crate) fn snapshot(r: &mut Rng, now: u64) -> k::Snapshot {
    let mut config = config(r);
    if r.chance(20) {
        // The clock at the refill time, or a second off it.
        config.auto_refill_time = (now % 86400 + *r.pick(&[86399, 0, 1])) % 86400;
    }
    let mut db = k::Db::default();
    let n = 1 + r.below(4);
    for id in 1..=n {
        let name = NAMES[(id - 1) as usize];
        db.users.push(k::User {
            id,
            name: spell(r, name),
            email: if r.chance(70) { Some(spell(r, &format!("{name}@x"))) } else { None },
            email_verified: r.chance(50),
            last_login: if r.chance(50) { Some(now - r.below(100)) } else { None },
            enabled: r.chance(80),
            admin: r.chance(40),
        });
        if r.chance(85) {
            db.passwords.push(k::Password { user_id: id, hash: b(&format!("h{id}")) });
        }
        if r.chance(50) {
            db.totp_devices.push(k::TotpDevice {
                id: 20 + id,
                user_id: id,
                enabled: r.chance(60),
                created_at: now - r.below(100),
                secret: 50 + id,
            });
        }
        if r.chance(40) {
            db.recovery_codes.push(k::RecoveryCode { user_id: id, hash: 70 + id });
        }
        if r.chance(60) {
            db.coins.push(k::CoinRow { user_id: id, coins: r.below(10) as i64, withheld_coins: r.below(3) as i64 });
        }
        if r.chance(60) {
            // Now and then exactly at a refill time.
            let last_refill = if r.chance(30) {
                (now - now % 86400 + config.auto_refill_time).saturating_sub(86400 * r.below(2))
            } else if r.chance(50) {
                now - r.below(600)
            } else {
                now - r.below(3 * 86400)
            };
            db.hearts.push(k::HeartRow { user_id: id, hearts: r.below(config.hearts_max + 1), last_refill });
        }
    }
    for i in 0..r.below(6) {
        let updated_at = now - r.below(40);
        db.sessions.push(k::Session {
            id: 10 + i,
            user_id: 1 + r.below(n),
            device_name: if r.chance(50) { Some(b("dev")) } else { None },
            created_at: updated_at - r.below(10),
            updated_at,
            mfa_verified: r.chance(50),
        });
        if r.chance(90) {
            db.refresh_tokens.push(k::RefreshTokenRow { session_id: 10 + i, hash: 100 + i });
        }
    }
    let mut cache = Vec::new();
    let exp = |r: &mut Rng| if r.chance(30) { None } else { Some(now - 5 + r.below(15)) };
    for i in 0..6 {
        if r.chance(20) {
            let e = exp(r);
            cache.push(k::CacheEntry { key: k::CacheKey::Invalidated(100 + i), value: k::CacheValue::Unit, expires: e });
        }
    }
    for name in NAMES {
        for v in [b(name), b(&format!("{name}@x"))] {
            if r.chance(30) {
                let e = if r.chance(70) { None } else { exp(r) };
                cache.push(k::CacheEntry { key: k::CacheKey::FailedAuth(v.clone()), value: k::CacheValue::Count(r.below(6)), expires: e });
            }
            if r.chance(35) {
                let a = attempts(r, now);
                let e = exp(r);
                cache.push(k::CacheEntry { key: k::CacheKey::ThrottleAccount(v), value: k::CacheValue::Attempts(a), expires: e });
            }
        }
    }
    for ip in 1..=2 {
        if r.chance(35) {
            let a = attempts(r, now);
            let e = exp(r);
            cache.push(k::CacheEntry { key: k::CacheKey::ThrottleIp(ip), value: k::CacheValue::Attempts(a), expires: e });
        }
    }
    k::Snapshot { config, db, cache }
}

fn attempts(r: &mut Rng, now: u64) -> k::FailedAttempts {
    k::FailedAttempts {
        count: r.below(7),
        blocked_until: if r.chance(50) { Some(now - 4 + r.below(10)) } else { None },
    }
}

pub(crate) fn env(r: &mut Rng, s: &k::Snapshot, now: u64) -> k::Env {
    let mut argon2_ok = Vec::new();
    for id in 1..=4 {
        if r.chance(90) {
            argon2_ok.push((b(&format!("pw{id}")), b(&format!("h{id}"))));
        }
    }
    let mut totp = Vec::new();
    for code in 1..=4 {
        for secret in (51..=54).chain(FRESH..FRESH + 4) {
            if r.chance(30) {
                let v = *r.pick(&[k::TotpCheck::Ok, k::TotpCheck::Ok, k::TotpCheck::RecentlyUsed, k::TotpCheck::InvalidCode]);
                totp.push((code, secret, v));
            }
        }
    }
    let _ = s;
    k::Env { now, client_ip: 1 + r.below(2), fresh: FRESH, captcha_ok: r.chance(60), argon2_ok, totp }
}

fn user_id_or_self(r: &mut Rng) -> k::UserIdOrSelf {
    if r.chance(40) { k::UserIdOrSelf::Slf } else { k::UserIdOrSelf::UserId(1 + r.below(5)) }
}

fn create_cmd(r: &mut Rng) -> k::SessionCreateCommand {
    let id = 1 + r.below(5);
    let name = NAMES.get((id - 1) as usize).copied().unwrap_or("eve");
    let name_or_email = if r.chance(60) {
        k::NameOrEmail::Name(spell(r, name))
    } else {
        k::NameOrEmail::Email(spell(r, &format!("{name}@x")))
    };
    k::SessionCreateCommand {
        name_or_email,
        password: if r.chance(75) { b(&format!("pw{id}")) } else { b("nope") },
        mfa: k::MfaAuthentication {
            totp_code: if r.chance(70) { Some(1 + r.below(4)) } else { None },
            recovery_code: if r.chance(30) { Some(if r.chance(70) { 70 + id } else { 99 }) } else { None },
        },
        device_name: if r.chance(50) { Some(b("phone")) } else { None },
    }
}

pub(crate) fn request(r: &mut Rng, s: &k::Snapshot) -> k::Request {
    let token = if r.chance(85) && !s.db.sessions.is_empty() {
        let x = r.pick(&s.db.sessions).clone();
        let rt = s.db.refresh_tokens.iter().find(|t| t.session_id == x.id).map(|t| t.hash).unwrap_or(100 + r.below(6));
        let mut a = k::Authentication {
            user_id: x.user_id,
            session_id: x.id,
            refresh_token_hash: rt,
            admin: r.chance(50),
            email_verified: r.chance(50),
            mfa_verified: r.chance(50),
        };
        // A forged or stale token now and then.
        if r.chance(10) {
            a.user_id = 1 + r.below(4);
        }
        if r.chance(5) {
            a.session_id = 10 + r.below(6);
        }
        Some(a)
    } else if r.chance(50) {
        Some(k::Authentication {
            user_id: 1 + r.below(4),
            session_id: 10 + r.below(6),
            refresh_token_hash: 100 + r.below(6),
            admin: r.chance(50),
            email_verified: r.chance(50),
            mfa_verified: r.chance(50),
        })
    } else {
        None
    };
    let cmd = match r.below(16) {
        0 => k::Command::GetCurrentSession,
        1 => k::Command::ListSessions { user_id: user_id_or_self(r) },
        2 | 3 => k::Command::CreateSession { cmd: create_cmd(r) },
        4 => k::Command::ProveRecipient { cmd: create_cmd(r) },
        5 => k::Command::Impersonate { user_id: 1 + r.below(5) },
        6 => k::Command::RefreshSession { refresh_token: 100 + r.below(7) },
        7 => k::Command::DeleteSession { user_id: user_id_or_self(r), session_id: 10 + r.below(7) },
        8 => k::Command::DeleteCurrentSession,
        9 => k::Command::DeleteSessionsByUser { user_id: user_id_or_self(r) },
        10 => k::Command::MfaInitialize { user_id: user_id_or_self(r) },
        11 => k::Command::MfaEnable { user_id: user_id_or_self(r), code: 1 + r.below(4) },
        12 => k::Command::MfaDisable { user_id: user_id_or_self(r) },
        13 => k::Command::GetBalance { user_id: user_id_or_self(r) },
        14 => k::Command::AddCoins {
            user_id: user_id_or_self(r),
            coins: r.below(16) as i64 - 12,
            description: if r.chance(50) { Some(b("d")) } else { None },
            include_in_credit_note: r.chance(50),
        },
        _ => {
            if r.chance(50) {
                k::Command::GetHearts { user_id: user_id_or_self(r) }
            } else {
                k::Command::RefillHearts {
                    declaration: k::Declaration {
                        given: r.chance(85),
                        text_version: if r.chance(85) { Some(b(r.pick(&["2026-09", "2026-09", "2025-01"]))) } else { None },
                    },
                }
            }
        }
    };
    k::Request { token, cmd }
}

// The upstream side.

type AccessTok = AuthAccessTokenServiceImpl<Svc, MemCache>;
type RefreshTok = AuthRefreshTokenServiceImpl<Svc, Svc>;
type Auth = AuthServiceImpl<Svc, Svc, Repo, Repo, AccessTok, RefreshTok, MemDb>;
type SessionS = SessionServiceImpl<Svc, Svc, Auth, AccessTok, Repo, Repo>;
type MfaDisable = MfaDisableServiceImpl<Auth, Repo, Repo>;
type CoinS = CoinServiceImpl<Svc, Svc, Repo>;

struct Wiring {
    w: W,
    c: k::Config,
}

impl Wiring {
    fn auth_config(&self) -> AuthServiceConfig {
        AuthServiceConfig {
            access_token_ttl: Duration::from_secs(self.c.access_token_ttl),
            refresh_token_ttl: Duration::from_secs(self.c.refresh_token_ttl),
            refresh_token_length: 64,
            internal_token_ttl: Duration::from_secs(10),
        }
    }
    fn svc(&self) -> Svc {
        Svc(self.w.clone())
    }
    fn access(&self) -> AccessTok {
        AuthAccessTokenServiceImpl { jwt: self.svc(), cache: MemCache(self.w.clone()), config: self.auth_config() }
    }
    fn auth(&self) -> Auth {
        AuthServiceImpl {
            db: MemDb(self.w.clone()),
            time: self.svc(),
            password: self.svc(),
            user_repo: Repo,
            session_repo: Repo,
            auth_access_token: self.access(),
            auth_refresh_token: AuthRefreshTokenServiceImpl { secret: self.svc(), hash: self.svc(), config: self.auth_config() },
            config: self.auth_config(),
        }
    }
    fn session(&self) -> SessionS {
        SessionServiceImpl {
            id: self.svc(),
            time: self.svc(),
            auth: self.auth(),
            auth_access_token: self.access(),
            session_repo: Repo,
            user_repo: Repo,
        }
    }
    fn mfa_disable(&self) -> MfaDisable {
        MfaDisableServiceImpl { auth: self.auth(), mfa_repo: Repo, session_repo: Repo }
    }
    fn coin(&self) -> CoinS {
        CoinServiceImpl { id: self.svc(), time: self.svc(), coin_repo: Repo }
    }
    fn session_feature(&self) -> impl SessionFeatureService {
        SessionFeatureServiceImpl {
            db: MemDb(self.w.clone()),
            auth: self.auth(),
            captcha: self.svc(),
            session: self.session(),
            session_failed_auth_count: SessionFailedAuthCountServiceImpl { hash: self.svc(), cache: MemCache(self.w.clone()) },
            session_login_throttle: SessionLoginThrottleServiceImpl {
                time: self.svc(),
                hash: self.svc(),
                cache: MemCache(self.w.clone()),
                config: SessionLoginThrottleConfig {
                    fails_before_lock: self.c.fails_before_lock,
                    fail_window: Duration::from_secs(self.c.fail_window),
                    lock_initial: Duration::from_secs(self.c.lock_initial),
                    lock_max: Duration::from_secs(self.c.lock_max),
                    fails_per_ip: self.c.fails_per_ip,
                    ip_window: Duration::from_secs(self.c.ip_window),
                },
            },
            mfa_authenticate: MfaAuthenticateServiceImpl {
                hash: self.svc(),
                totp: self.svc(),
                mfa_disable: self.mfa_disable(),
                mfa_repo: Repo,
            },
            user_repo: Repo,
            session_repo: Repo,
            config: SessionFeatureConfig { login_fails_before_captcha: self.c.login_fails_before_captcha },
        }
    }
    fn mfa_feature(&self) -> impl MfaFeatureService {
        MfaFeatureServiceImpl {
            db: MemDb(self.w.clone()),
            auth: self.auth(),
            user_repo: Repo,
            mfa_repo: Repo,
            mfa_recovery: MfaRecoveryServiceImpl { secret: self.svc(), hash: self.svc(), mfa_repo: Repo },
            mfa_disable: self.mfa_disable(),
            mfa_totp_device: MfaTotpDeviceServiceImpl { id: self.svc(), time: self.svc(), totp: self.svc(), mfa_repo: Repo },
        }
    }
    fn coin_feature(&self) -> impl CoinFeatureService {
        CoinFeatureServiceImpl {
            db: MemDb(self.w.clone()),
            auth: self.auth(),
            user_repo: Repo,
            coin_repo: Repo,
            coin: self.coin(),
            finance_coin: self.svc(),
        }
    }
    fn heart_feature(&self) -> impl HeartFeatureService {
        HeartFeatureServiceImpl {
            db: MemDb(self.w.clone()),
            auth: self.auth(),
            user_repo: Repo,
            heart: HeartServiceImpl { time: self.svc(), heart_repo: Repo, config: self.heart_config() },
            coin: self.coin(),
            withdrawal_consent: WithdrawalConsentServiceImpl { id: self.svc(), time: self.svc(), withdrawal_repo: Repo },
            config: self.heart_config(),
        }
    }
    fn heart_config(&self) -> HeartFeatureConfig {
        let t = self.c.auto_refill_time as u32;
        HeartFeatureConfig {
            hearts_max: self.c.hearts_max,
            hearts_refill_price: self.c.hearts_refill_price,
            auto_refill_time: NaiveTime::from_hms_opt(t / 3600, t / 60 % 60, t % 60).unwrap(),
        }
    }
}

fn auth_err(e: &AuthError) -> k::Error {
    match e {
        AuthError::Authenticate(AuthenticateError::InvalidToken) => k::Error::InvalidToken,
        AuthError::Authenticate(AuthenticateError::Other(_)) => k::Error::Internal,
        AuthError::Authorize(AuthorizeError::Admin) => k::Error::Admin,
        AuthError::Authorize(AuthorizeError::AdminMfa) => k::Error::AdminMfa,
        AuthError::Authorize(AuthorizeError::EmailVerified) => k::Error::EmailVerified,
    }
}

fn kuser_id(u: UserIdOrSelf) -> UserIdOrSelf {
    u
}
fn up_user_id(u: k::UserIdOrSelf) -> UserIdOrSelf {
    kuser_id(match u {
        k::UserIdOrSelf::UserId(n) => UserIdOrSelf::UserId(UserId(uid(n))),
        k::UserIdOrSelf::Slf => UserIdOrSelf::Slf,
    })
}

fn k_session(x: &Session) -> k::Session {
    k::Session {
        id: x.id.0.0,
        user_id: x.user_id.0.0,
        device_name: x.device_name.as_ref().map(|d| b(&d.0)),
        created_at: secs(x.created_at),
        updated_at: secs(x.updated_at),
        mfa_verified: x.mfa_verified,
    }
}

#[derive(serde::Deserialize)]
struct TokenJson {
    uid: u64,
    sid: u64,
    rt: [u8; 32],
    data: TokenDataJson,
}
#[derive(serde::Deserialize)]
struct TokenDataJson {
    admin: bool,
    email_verified: bool,
    mfa: bool,
}

fn token_json(a: &k::Authentication) -> String {
    serde_json::json!({
        "uid": a.user_id, "sid": a.session_id, "rt": hash_of(a.refresh_token_hash).0,
        "data": {"admin": a.admin, "email_verified": a.email_verified, "mfa": a.mfa_verified},
    })
    .to_string()
}

fn k_login(l: &Login) -> k::Login {
    let t: TokenJson = serde_json::from_str(&l.access_token.0).unwrap();
    let u = &l.user_composite.user;
    k::Login {
        user_composite: k::UserComposite {
            user: k::User {
                id: u.id.0.0,
                name: b(&u.name.0),
                email: u.email.as_ref().map(|e| b(&e.0)),
                email_verified: u.email_verified,
                last_login: u.last_login.map(secs),
                enabled: u.enabled,
                admin: u.admin,
            },
            mfa_enabled: l.user_composite.details.mfa_enabled,
        },
        session: k_session(&l.session),
        access_token: k::Authentication {
            user_id: t.uid,
            session_id: t.sid,
            refresh_token_hash: unhash(&crate::upstream::academy_models::Sha256Hash(t.rt)),
            admin: t.data.admin,
            email_verified: t.data.email_verified,
            mfa_verified: t.data.mfa,
        },
        refresh_token: l.refresh_token.0.parse().unwrap(),
    }
}

fn up_create(c: &k::SessionCreateCommand) -> SessionCreateCommand {
    SessionCreateCommand {
        name_or_email: match &c.name_or_email {
            k::NameOrEmail::Name(n) => UserNameOrEmailAddress::Name(UserName(s(n))),
            k::NameOrEmail::Email(e) => UserNameOrEmailAddress::Email(EmailAddress(s(e))),
        },
        password: UserPassword(s(&c.password)),
        mfa: MfaAuthentication {
            totp_code: c.mfa.totp_code.map(|n| TotpCode(n.to_string())),
            recovery_code: c.mfa.recovery_code.map(|n| MfaRecoveryCode(n.to_string())),
        },
        device_name: c.device_name.as_ref().map(|d| DeviceName(s(d))),
    }
}

fn create_err(e: &SessionCreateError) -> k::Error {
    match e {
        SessionCreateError::InvalidCredentials => k::Error::InvalidCredentials,
        SessionCreateError::MfaFailed => k::Error::MfaFailed,
        SessionCreateError::UserDisabled => k::Error::UserDisabled,
        SessionCreateError::Recaptcha => k::Error::Recaptcha,
        SessionCreateError::TooManyFailedAttempts(d) => {
            assert_eq!(d.subsec_nanos(), 0);
            k::Error::TooManyFailedAttempts(d.as_secs())
        }
        SessionCreateError::Other(_) => k::Error::Internal,
    }
}

/// Upstream on one request: the committed database, the cache and the reply.
pub(crate) fn upstream(
    s: &k::Snapshot,
    env: &k::Env,
    req: &k::Request,
) -> (k::Db, BTreeMap<String, (String, Option<u64>)>, Result<k::Reply, k::Error>) {
    let cache = s.cache.iter().map(|e| (cache_key(&e.key), (cache_json(&e.value), e.expires))).collect();
    let w = Arc::new(World {
        db: Mutex::new(s.db.clone()),
        cache: Mutex::new(cache),
        fresh: AtomicU64::new(env.fresh),
        env: env.clone(),
    });
    let wiring = Wiring { w: w.clone(), c: s.config.clone() };
    let token = AccessToken(match &req.token {
        Some(a) => token_json(a),
        None => "not a jwt".into(),
    });
    let ip = std::net::IpAddr::from(std::net::Ipv4Addr::from(env.client_ip as u32));
    use k::Error as E;
    let reply = block_on(async {
        match &req.cmd {
            k::Command::GetCurrentSession => match wiring.session_feature().get_current_session(&token).await {
                Ok(x) => Ok(k::Reply::Session(k_session(&x))),
                Err(SessionGetCurrentError::Auth(e)) => Err(auth_err(&e)),
                Err(SessionGetCurrentError::Other(_)) => Err(E::Internal),
            },
            k::Command::ListSessions { user_id } => match wiring.session_feature().list_by_user(&token, up_user_id(*user_id)).await {
                Ok(x) => Ok(k::Reply::Sessions(x.iter().map(k_session).collect())),
                Err(SessionListByUserError::Auth(e)) => Err(auth_err(&e)),
                Err(SessionListByUserError::Other(_)) => Err(E::Internal),
            },
            k::Command::CreateSession { cmd } => match wiring.session_feature().create_session(ip, up_create(cmd), None).await {
                Ok(l) => Ok(k::Reply::Login(k_login(&l))),
                Err(e) => Err(create_err(&e)),
            },
            k::Command::ProveRecipient { cmd } => match wiring.session_feature().prove_recipient(ip, up_create(cmd), None).await {
                Ok(u) => Ok(k::Reply::UserId(u.0.0)),
                Err(e) => Err(create_err(&e)),
            },
            k::Command::Impersonate { user_id } => match wiring.session_feature().impersonate(&token, UserId(uid(*user_id))).await {
                Ok(l) => Ok(k::Reply::Login(k_login(&l))),
                Err(SessionImpersonateError::NotFound) => Err(E::NotFound),
                Err(SessionImpersonateError::Auth(e)) => Err(auth_err(&e)),
                Err(SessionImpersonateError::Other(_)) => Err(E::Internal),
            },
            k::Command::RefreshSession { refresh_token } => {
                match wiring.session_feature().refresh_session(&RefreshToken(refresh_token.to_string())).await {
                    Ok(l) => Ok(k::Reply::Login(k_login(&l))),
                    Err(SessionRefreshError::InvalidRefreshToken) => Err(E::InvalidRefreshToken),
                    Err(SessionRefreshError::Other(_)) => Err(E::Internal),
                }
            }
            k::Command::DeleteSession { user_id, session_id } => {
                let sid = crate::upstream::academy_models::session::SessionId(uid(*session_id));
                match wiring.session_feature().delete_session(&token, up_user_id(*user_id), sid).await {
                    Ok(()) => Ok(k::Reply::Done),
                    Err(SessionDeleteError::NotFound) => Err(E::NotFound),
                    Err(SessionDeleteError::Auth(e)) => Err(auth_err(&e)),
                    Err(SessionDeleteError::Other(_)) => Err(E::Internal),
                }
            }
            k::Command::DeleteCurrentSession => match wiring.session_feature().delete_current_session(&token).await {
                Ok(()) => Ok(k::Reply::Done),
                Err(SessionDeleteCurrentError::Auth(e)) => Err(auth_err(&e)),
                Err(SessionDeleteCurrentError::Other(_)) => Err(E::Internal),
            },
            k::Command::DeleteSessionsByUser { user_id } => match wiring.session_feature().delete_by_user(&token, up_user_id(*user_id)).await {
                Ok(()) => Ok(k::Reply::Done),
                Err(SessionDeleteByUserError::Auth(e)) => Err(auth_err(&e)),
                Err(SessionDeleteByUserError::Other(_)) => Err(E::Internal),
            },
            k::Command::MfaInitialize { user_id } => match wiring.mfa_feature().initialize(&token, up_user_id(*user_id)).await {
                Ok(setup) => Ok(k::Reply::TotpSetup(setup.secret.0.parse().unwrap())),
                Err(MfaInitializeError::AlreadyEnabled) => Err(E::AlreadyEnabled),
                Err(MfaInitializeError::NotFound) => Err(E::NotFound),
                Err(MfaInitializeError::Auth(e)) => Err(auth_err(&e)),
                Err(MfaInitializeError::Other(_)) => Err(E::Internal),
            },
            k::Command::MfaEnable { user_id, code } => {
                match wiring.mfa_feature().enable(&token, up_user_id(*user_id), TotpCode(code.to_string())).await {
                    Ok(c) => Ok(k::Reply::RecoveryCode(c.0.parse().unwrap())),
                    Err(MfaEnableError::AlreadyEnabled) => Err(E::AlreadyEnabled),
                    Err(MfaEnableError::NotInitialized) => Err(E::NotInitialized),
                    Err(MfaEnableError::InvalidCode) => Err(E::InvalidCode),
                    Err(MfaEnableError::NotFound) => Err(E::NotFound),
                    Err(MfaEnableError::Auth(e)) => Err(auth_err(&e)),
                    Err(MfaEnableError::Other(_)) => Err(E::Internal),
                }
            }
            k::Command::MfaDisable { user_id } => match wiring.mfa_feature().disable(&token, up_user_id(*user_id)).await {
                Ok(()) => Ok(k::Reply::Done),
                Err(MfaDisableError::NotEnabled) => Err(E::NotEnabled),
                Err(MfaDisableError::NotFound) => Err(E::NotFound),
                Err(MfaDisableError::Auth(e)) => Err(auth_err(&e)),
                Err(MfaDisableError::Other(_)) => Err(E::Internal),
            },
            k::Command::GetBalance { user_id } => match wiring.coin_feature().get_balance(&token, up_user_id(*user_id)).await {
                Ok(x) => Ok(k::Reply::Balance(k::Balance { coins: x.coins, withheld_coins: x.withheld_coins })),
                Err(CoinGetBalanceError::UserNotFound) => Err(E::UserNotFound),
                Err(CoinGetBalanceError::Auth(e)) => Err(auth_err(&e)),
                Err(CoinGetBalanceError::Other(_)) => Err(E::Internal),
            },
            k::Command::AddCoins { user_id, coins, description: d, include_in_credit_note } => {
                match wiring
                    .coin_feature()
                    .add_coins(&token, up_user_id(*user_id), *coins, description(d), *include_in_credit_note)
                    .await
                {
                    Ok(x) => Ok(k::Reply::Balance(k::Balance { coins: x.coins, withheld_coins: x.withheld_coins })),
                    Err(CoinAddCoinsError::CreditNotAuthorized) => Err(E::CreditNotAuthorized),
                    Err(CoinAddCoinsError::UserNotFound) => Err(E::UserNotFound),
                    Err(CoinAddCoinsError::NotEnoughCoins) => Err(E::NotEnoughCoins),
                    Err(CoinAddCoinsError::Auth(e)) => Err(auth_err(&e)),
                    Err(CoinAddCoinsError::Other(_)) => Err(E::Internal),
                }
            }
            k::Command::GetHearts { user_id } => match wiring.heart_feature().get(&token, up_user_id(*user_id)).await {
                Ok(h) => Ok(k::Reply::Hearts(k::Hearts { hearts: h.hearts, last_refill: secs(h.last_refill) })),
                Err(HeartGetError::UserNotFound) => Err(E::UserNotFound),
                Err(HeartGetError::Auth(e)) => Err(auth_err(&e)),
                Err(HeartGetError::Other(_)) => Err(E::Internal),
            },
            k::Command::RefillHearts { declaration } => {
                let d = WithdrawalConsentDeclaration {
                    given: declaration.given,
                    text_version: declaration.text_version.as_ref().map(|v| WithdrawalTextVersion(crate::mem::s(v))),
                };
                match wiring.heart_feature().refill(&token, d).await {
                    Ok(h) => Ok(k::Reply::Hearts(k::Hearts { hearts: h.hearts, last_refill: secs(h.last_refill) })),
                    Err(HeartRefillError::NotEnoughCoins) => Err(E::NotEnoughCoins),
                    Err(HeartRefillError::WithdrawalConsentMissing) => Err(E::WithdrawalConsentMissing),
                    Err(HeartRefillError::Auth(e)) => Err(auth_err(&e)),
                    Err(HeartRefillError::Other(_)) => Err(E::Internal),
                }
            }
        }
    });
    drop(wiring);
    let w = Arc::try_unwrap(w).ok().expect("services dropped");
    (w.db.into_inner().unwrap(), w.cache.into_inner().unwrap(), reply)
}

/// The snapshot after the kernel's writes.
pub(crate) fn after(s: &k::Snapshot, writes: &[k::Write]) -> (k::Db, Vec<k::CacheEntry>) {
    let mut db = s.db.clone();
    let mut cache = s.cache.clone();
    for w in writes {
        k::repo::apply(&mut db, w);
        k::valkey::apply(&mut cache, w);
    }
    (db, cache)
}

fn outcome(req: &k::Request, r: &Result<k::Reply, k::Error>) -> String {
    let cmd = format!("{:?}", req.cmd);
    let cmd = cmd.split([' ', '{']).next().unwrap().to_string();
    let res = match r {
        Ok(x) => format!("Ok {}", format!("{x:?}").split(['(', ' ']).next().unwrap()),
        Err(k::Error::TooManyFailedAttempts(_)) => "TooManyFailedAttempts".into(),
        Err(e) => format!("{e:?}"),
    };
    format!("{cmd} -> {res}")
}

#[test]
fn transition_agrees() {
    let mut r = Rng(0x9E3779B97F4A7C15);
    let mut outcomes = BTreeMap::new();
    for _ in 0..400_000 {
        let now = T0 + r.below(200_000);
        let s = snapshot(&mut r, now);
        let env = env(&mut r, &s, now);
        let req = request(&mut r, &s);
        let (writes, got) = k::transition(&s, &env, &req);
        let (db, cache, want) = upstream(&s, &env, &req);
        assert_eq!(got, want, "reply\n{s:?}\n{env:?}\n{req:?}");
        let (kdb, kcache) = after(&s, &writes);
        assert_eq!(kdb, db, "database\n{s:?}\n{env:?}\n{req:?}\n{writes:?}");
        let kcache: BTreeMap<_, _> = kcache.iter().map(|e| (cache_key(&e.key), (cache_json(&e.value), e.expires))).collect();
        assert_eq!(kcache, cache, "cache\n{s:?}\n{env:?}\n{req:?}\n{writes:?}");
        *outcomes.entry(outcome(&req, &want)).or_insert(0usize) += 1;
    }
    for (k, v) in &outcomes {
        println!("{v:8} {k}");
    }
    // Every command reaches success and its main errors.
    for must in [
        "GetCurrentSession -> Ok", "ListSessions -> Ok", "ListSessions -> AdminMfa", "ListSessions -> Admin",
        "CreateSession -> Ok", "CreateSession -> InvalidCredentials", "CreateSession -> MfaFailed",
        "CreateSession -> UserDisabled", "CreateSession -> Recaptcha", "CreateSession -> TooManyFailedAttempts",
        "ProveRecipient -> Ok", "Impersonate -> Ok", "Impersonate -> NotFound", "RefreshSession -> Ok",
        "RefreshSession -> InvalidRefreshToken", "DeleteSession -> Ok", "DeleteSession -> NotFound",
        "DeleteCurrentSession -> Ok", "DeleteSessionsByUser -> Ok", "MfaInitialize -> Ok",
        "MfaInitialize -> AlreadyEnabled", "MfaEnable -> Ok", "MfaEnable -> InvalidCode", "MfaEnable -> NotInitialized",
        "MfaDisable -> Ok", "MfaDisable -> NotEnabled", "GetBalance -> Ok", "GetBalance -> UserNotFound",
        "AddCoins -> Ok", "AddCoins -> CreditNotAuthorized", "AddCoins -> NotEnoughCoins", "GetHearts -> Ok",
        "RefillHearts -> Ok", "RefillHearts -> NotEnoughCoins", "RefillHearts -> WithdrawalConsentMissing",
        "GetCurrentSession -> InvalidToken",
    ] {
        assert!(outcomes.keys().any(|k| k.starts_with(must)), "never saw {must}");
    }
}
