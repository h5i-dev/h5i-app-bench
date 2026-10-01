//! Bootstrap Academy's sessions, MFA, coins and hearts
//! (Bootstrap-Academy/backend @ fbe5e60) in the Aeneas subset. Each function
//! follows the upstream function of the same name, in upstream's order; the
//! deviations are listed in ../DEVIATIONS.md.
//!
//! A request runs against a `Snapshot` of the database and the cache and
//! returns the writes it makes. Cache writes take effect at once; database
//! writes only when the transaction commits, as upstream. JWT verification,
//! argon2, TOTP, the captcha and the clock are trusted input (`Env`).

pub mod access;
pub mod valkey;
pub mod coin;
pub mod repo;
pub mod heart;
pub mod mfa;
pub mod sessions;
pub mod throttle;

/// The configuration the ported services read, in seconds.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Config {
    /// `AuthServiceConfig`.
    pub access_token_ttl: u64,
    pub refresh_token_ttl: u64,
    /// `SessionFeatureConfig`.
    pub login_fails_before_captcha: u64,
    /// `SessionLoginThrottleConfig`.
    pub fails_before_lock: u64,
    pub fail_window: u64,
    pub lock_initial: u64,
    pub lock_max: u64,
    pub fails_per_ip: u64,
    pub ip_window: u64,
    /// `HeartFeatureConfig`; `auto_refill_time` is seconds after midnight UTC.
    pub hearts_max: u64,
    pub hearts_refill_price: u64,
    pub auto_refill_time: u64,
}

/// `users`, with the columns the ported code reads.
#[derive(Debug, PartialEq, Eq)]
pub struct User {
    pub id: u64,
    pub name: Vec<u8>,
    pub email: Option<Vec<u8>>,
    pub email_verified: bool,
    pub last_login: Option<u64>,
    pub enabled: bool,
    pub admin: bool,
}

/// `user_passwords`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Password {
    pub user_id: u64,
    pub hash: Vec<u8>,
}

/// `sessions`.
#[derive(Debug, PartialEq, Eq)]
pub struct Session {
    pub id: u64,
    pub user_id: u64,
    pub device_name: Option<Vec<u8>>,
    pub created_at: u64,
    pub updated_at: u64,
    pub mfa_verified: bool,
}

/// `session_refresh_tokens`. Hashes are SHA-256, taken as injective: the
/// kernel stores the refresh token itself.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct RefreshTokenRow {
    pub session_id: u64,
    pub hash: u64,
}

/// `totp_devices` joined with `totp_device_secrets` (one row each).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct TotpDevice {
    pub id: u64,
    pub user_id: u64,
    pub enabled: bool,
    pub created_at: u64,
    pub secret: u64,
}

/// `mfa_recovery_codes`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct RecoveryCode {
    pub user_id: u64,
    pub hash: u64,
}

/// `coins`: both columns are `bigint check (>= 0)`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct CoinRow {
    pub user_id: u64,
    pub coins: i64,
    pub withheld_coins: i64,
}

/// `transactions`.
#[derive(Debug, PartialEq, Eq)]
pub struct Transaction {
    pub id: u64,
    pub user_id: u64,
    pub coins: i64,
    pub description: Option<Vec<u8>>,
    pub created_at: u64,
    pub include_in_credit_note: bool,
}

/// `hearts`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct HeartRow {
    pub user_id: u64,
    pub hearts: u64,
    pub last_refill: u64,
}

/// `withdrawal_consents`; the ported code only records the hearts subject.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Consent {
    pub id: u64,
    pub user_id: u64,
    pub text_version: Vec<u8>,
    pub consented_at: u64,
}

#[derive(Clone, Debug, PartialEq, Eq, Default)]
pub struct Db {
    pub users: Vec<User>,
    pub passwords: Vec<Password>,
    pub sessions: Vec<Session>,
    pub refresh_tokens: Vec<RefreshTokenRow>,
    pub totp_devices: Vec<TotpDevice>,
    pub recovery_codes: Vec<RecoveryCode>,
    pub coins: Vec<CoinRow>,
    pub transactions: Vec<Transaction>,
    pub hearts: Vec<HeartRow>,
    pub consents: Vec<Consent>,
}

/// `login_throttle.rs` `FailedAttempts`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct FailedAttempts {
    pub count: u64,
    pub blocked_until: Option<u64>,
}

/// A cache key; upstream formats each as a prefix and a hex SHA-256.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CacheKey {
    /// `access_token_invalidated:{refresh token hash}`.
    Invalidated(u64),
    /// `failed_auth_attempts:{lowercased login}`.
    FailedAuth(Vec<u8>),
    /// `login_throttle_account:{lowercased login}`.
    ThrottleAccount(Vec<u8>),
    /// `login_throttle_ip:{client address}`.
    ThrottleIp(u64),
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CacheValue {
    Unit,
    Count(u64),
    Attempts(FailedAttempts),
}

/// A Valkey entry; it is gone once `now >= expires`.
#[derive(Debug, PartialEq, Eq)]
pub struct CacheEntry {
    pub key: CacheKey,
    pub value: CacheValue,
    pub expires: Option<u64>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Snapshot {
    pub config: Config,
    pub db: Db,
    pub cache: Vec<CacheEntry>,
}

/// `TotpService::check`'s verdict.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TotpCheck {
    Ok,
    InvalidCode,
    RecentlyUsed,
}

/// Trusted input: the clock, the client address, fresh ids and secrets, and
/// the verdicts of argon2, TOTP and reCAPTCHA.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Env {
    pub now: u64,
    pub client_ip: u64,
    /// `IdService::generate`, `SecretService` and `TotpService::generate_secret`
    /// hand out `fresh`, `fresh + 1`, ... in call order.
    pub fresh: u64,
    pub captcha_ok: bool,
    /// (password, hash) pairs that argon2 accepts.
    pub argon2_ok: Vec<(Vec<u8>, Vec<u8>)>,
    /// (code, secret, verdict); a pair not listed is `InvalidCode`.
    pub totp: Vec<(u64, u64, TotpCheck)>,
}

/// `auth::Authentication`, also the claims of a verified access token.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Authentication {
    pub user_id: u64,
    pub session_id: u64,
    pub refresh_token_hash: u64,
    pub admin: bool,
    pub email_verified: bool,
    pub mfa_verified: bool,
}

/// `user::UserIdOrSelf`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum UserIdOrSelf {
    UserId(u64),
    Slf,
}

/// `user::UserNameOrEmailAddress`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum NameOrEmail {
    Name(Vec<u8>),
    Email(Vec<u8>),
}

/// `mfa::MfaAuthentication`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct MfaAuthentication {
    pub totp_code: Option<u64>,
    pub recovery_code: Option<u64>,
}

/// `SessionCreateCommand`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SessionCreateCommand {
    pub name_or_email: NameOrEmail,
    pub password: Vec<u8>,
    pub mfa: MfaAuthentication,
    pub device_name: Option<Vec<u8>>,
}

/// `withdrawal::WithdrawalConsentDeclaration`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Declaration {
    pub given: bool,
    pub text_version: Option<Vec<u8>>,
}

/// One call of a feature service.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Command {
    GetCurrentSession,
    ListSessions { user_id: UserIdOrSelf },
    CreateSession { cmd: SessionCreateCommand },
    ProveRecipient { cmd: SessionCreateCommand },
    Impersonate { user_id: u64 },
    RefreshSession { refresh_token: u64 },
    DeleteSession { user_id: UserIdOrSelf, session_id: u64 },
    DeleteCurrentSession,
    DeleteSessionsByUser { user_id: UserIdOrSelf },
    MfaInitialize { user_id: UserIdOrSelf },
    MfaEnable { user_id: UserIdOrSelf, code: u64 },
    MfaDisable { user_id: UserIdOrSelf },
    GetBalance { user_id: UserIdOrSelf },
    AddCoins { user_id: UserIdOrSelf, coins: i64, description: Option<Vec<u8>>, include_in_credit_note: bool },
    GetHearts { user_id: UserIdOrSelf },
    RefillHearts { declaration: Declaration },
}

/// A request: the access token's verified claims (`None` when the JWT does
/// not verify or none was sent) and the command.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Request {
    pub token: Option<Authentication>,
    pub cmd: Command,
}

/// `user::UserComposite`, with the part the ported code reads.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct UserComposite {
    pub user: User,
    pub mfa_enabled: bool,
}

/// `auth::Login`; the access token is given by its claims.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Login {
    pub user_composite: UserComposite,
    pub session: Session,
    pub access_token: Authentication,
    pub refresh_token: u64,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Default)]
pub struct Balance {
    pub coins: u64,
    pub withheld_coins: u64,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Hearts {
    pub hearts: u64,
    pub last_refill: u64,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Reply {
    Session(Session),
    Sessions(Vec<Session>),
    Login(Login),
    UserId(u64),
    Done,
    /// `TotpSetup`: the new secret.
    TotpSetup(u64),
    RecoveryCode(u64),
    Balance(Balance),
    Hearts(Hearts),
}

/// The error variants of the feature services, merged.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    /// `AuthenticateError::InvalidToken`.
    InvalidToken,
    /// `AuthorizeError`.
    Admin,
    AdminMfa,
    EmailVerified,
    NotFound,
    UserNotFound,
    InvalidCredentials,
    MfaFailed,
    UserDisabled,
    Recaptcha,
    /// Seconds to wait.
    TooManyFailedAttempts(u64),
    InvalidRefreshToken,
    AlreadyEnabled,
    NotInitialized,
    InvalidCode,
    NotEnabled,
    CreditNotAuthorized,
    NotEnoughCoins,
    WithdrawalConsentMissing,
    /// An `anyhow` error (500).
    Internal,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Write {
    /// Cache writes; not part of the transaction.
    CacheSet(CacheEntry),
    CacheRemove(CacheKey),
    /// Database writes.
    CreateSession(Session),
    UpdateSessionUpdatedAt { session_id: u64, updated_at: u64 },
    ClearMfaVerified { user_id: u64 },
    DeleteSession { session_id: u64 },
    DeleteSessionsByUser { user_id: u64 },
    SaveRefreshTokenHash { session_id: u64, hash: u64 },
    UpdateLastLogin { user_id: u64, last_login: u64 },
    CreateTotpDevice(TotpDevice),
    UpdateTotpDeviceEnabled { id: u64, enabled: bool },
    SaveTotpDeviceSecret { id: u64, secret: u64 },
    DeleteTotpDevicesByUser { user_id: u64 },
    SaveRecoveryCodeHash { user_id: u64, hash: u64 },
    DeleteRecoveryCodeHash { user_id: u64 },
    AddCoins { user_id: u64, coins: i64, withheld_coins: i64 },
    CreateTransaction(Transaction),
    SetHearts { user_id: u64, hearts: u64, last_refill: u64 },
    CreateConsent(Consent),
}

/// One request in flight: the transaction's view of the database, the live
/// cache, the writes so far and the next fresh value.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Ctx {
    pub db: Db,
    pub cache: Vec<CacheEntry>,
    /// Cache writes, and database writes of the committed transaction.
    pub done: Vec<Write>,
    /// Database writes of the open transaction.
    pub pending: Vec<Write>,
    pub fresh: u64,
}

/// `IdService::generate`, `SecretService::generate*`, `TotpService::generate_secret`.
pub fn generate(ctx: &mut Ctx) -> u64 {
    let v = ctx.fresh;
    ctx.fresh = ctx.fresh.wrapping_add(1);
    v
}

/// A database write inside the open transaction.
pub fn db_write(ctx: &mut Ctx, w: Write) {
    repo::apply(&mut ctx.db, &w);
    ctx.pending.push(w);
}

/// A cache write, visible at once and kept whatever the transaction does.
pub fn cache_write(ctx: &mut Ctx, w: Write) {
    valkey::apply(&mut ctx.cache, &w);
    ctx.done.push(w);
}

/// `txn.commit()`.
pub fn commit(ctx: &mut Ctx) {
    let mut i = 0;
    while i < ctx.pending.len() {
        ctx.done.push(ctx.pending[i].clone());
        i += 1;
    }
    ctx.pending = Vec::new();
}

fn run(s: &Snapshot, env: &Env, ctx: &mut Ctx, req: &Request) -> Result<Reply, Error> {
    let c = &s.config;
    let t = &req.token;
    match &req.cmd {
        Command::GetCurrentSession => sessions::get_current_session(ctx, env, t),
        Command::ListSessions { user_id } => sessions::list_by_user(ctx, env, t, *user_id),
        Command::CreateSession { cmd } => sessions::create_session(c, ctx, env, cmd),
        Command::ProveRecipient { cmd } => sessions::prove_recipient(c, ctx, env, cmd),
        Command::Impersonate { user_id } => sessions::impersonate(ctx, env, t, *user_id),
        Command::RefreshSession { refresh_token } => sessions::refresh_session(c, ctx, env, *refresh_token),
        Command::DeleteSession { user_id, session_id } => {
            sessions::delete_session(c, ctx, env, t, *user_id, *session_id)
        }
        Command::DeleteCurrentSession => sessions::delete_current_session(c, ctx, env, t),
        Command::DeleteSessionsByUser { user_id } => sessions::delete_by_user(c, ctx, env, t, *user_id),
        Command::MfaInitialize { user_id } => mfa::initialize(ctx, env, t, *user_id),
        Command::MfaEnable { user_id, code } => mfa::enable(ctx, env, t, *user_id, *code),
        Command::MfaDisable { user_id } => mfa::disable_mfa(c, ctx, env, t, *user_id),
        Command::GetBalance { user_id } => coin::get_balance(ctx, env, t, *user_id),
        Command::AddCoins { user_id, coins, description, include_in_credit_note } => {
            coin::add_coins(ctx, env, t, *user_id, *coins, description, *include_in_credit_note)
        }
        Command::GetHearts { user_id } => heart::get(c, ctx, env, t, *user_id),
        Command::RefillHearts { declaration } => heart::refill(c, ctx, env, t, declaration),
    }
}

/// Handle one request: the writes that take effect, and the reply. An open
/// transaction is rolled back when the request ends, as upstream's
/// `Transaction` does on drop.
pub fn transition(s: &Snapshot, env: &Env, req: &Request) -> (Vec<Write>, Result<Reply, Error>) {
    let mut ctx = Ctx {
        db: s.db.clone(),
        cache: s.cache.clone(),
        done: Vec::new(),
        pending: Vec::new(),
        fresh: env.fresh,
    };
    let r = run(s, env, &mut ctx, req);
    (ctx.done, r)
}

/// `Option::clone` by hand: Aeneas has no model of it.
pub fn clone_bytes_opt(o: &Option<Vec<u8>>) -> Option<Vec<u8>> {
    match o {
        Some(v) => Some(v.clone()),
        None => None,
    }
}

pub fn clone_u64_opt(o: &Option<u64>) -> Option<u64> {
    match o {
        Some(v) => Some(*v),
        None => None,
    }
}

impl Clone for User {
    fn clone(&self) -> User {
        User {
            id: self.id,
            name: self.name.clone(),
            email: clone_bytes_opt(&self.email),
            email_verified: self.email_verified,
            last_login: clone_u64_opt(&self.last_login),
            enabled: self.enabled,
            admin: self.admin,
        }
    }
}

impl Clone for Session {
    fn clone(&self) -> Session {
        Session {
            id: self.id,
            user_id: self.user_id,
            device_name: clone_bytes_opt(&self.device_name),
            created_at: self.created_at,
            updated_at: self.updated_at,
            mfa_verified: self.mfa_verified,
        }
    }
}

impl Clone for Transaction {
    fn clone(&self) -> Transaction {
        Transaction {
            id: self.id,
            user_id: self.user_id,
            coins: self.coins,
            description: clone_bytes_opt(&self.description),
            created_at: self.created_at,
            include_in_credit_note: self.include_in_credit_note,
        }
    }
}

impl Clone for CacheEntry {
    fn clone(&self) -> CacheEntry {
        CacheEntry { key: self.key.clone(), value: self.value.clone(), expires: clone_u64_opt(&self.expires) }
    }
}

pub fn bytes_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut i = 0;
    while i < a.len() {
        if a[i] != b[i] {
            return false;
        }
        i += 1;
    }
    true
}

/// ASCII `to_lowercase` / SQL `lower`.
pub fn lower(s: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < s.len() {
        let c = s[i];
        if c >= b'A' && c <= b'Z' {
            out.push(c + 32);
        } else {
            out.push(c);
        }
        i += 1;
    }
    out
}
