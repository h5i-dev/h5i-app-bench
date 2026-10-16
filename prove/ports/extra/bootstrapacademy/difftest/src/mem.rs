//! In-memory Postgres, Valkey and shared services for the copied upstream
//! code. The repositories reproduce the SQL in
//! `academy_persistence/postgres/queries/*.sql` on the kernel's tables; they
//! do not call kernel code. Hashes are an injective stand-in for SHA-256.
use std::collections::BTreeMap;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::time::Duration;

use anyhow::anyhow;
use bootstrapacademy_kernel as k;
use chrono::{DateTime, Utc};
use serde::{Serialize, de::DeserializeOwned};

use crate::upstream::academy_cache_contracts::CacheService;
use crate::upstream::academy_core_finance_contracts::coin::{Decimal, FinanceCoinService};
use crate::upstream::academy_models::{
    coin::{Balance, Transaction, TransactionDescription},
    heart::Hearts,
    mfa::{MfaRecoveryCode, MfaRecoveryCodeHash, TotpCode, TotpDevice, TotpDeviceId, TotpDevicePatchRef, TotpSecret,
        TotpSecretBase32, TotpSetup},
    session::{DeviceName, Session, SessionId, SessionPatchRef, SessionRefreshTokenHash},
    user::{EmailAddress, User, UserComposite, UserDetails, UserId, UserName, UserPatchRef},
    withdrawal::{WithdrawalConsent, WithdrawalSubject},
    Sensitive, Sha256Hash, VerificationCode,
};
use crate::upstream::academy_persistence_contracts::{
    Database, Transaction as DbTransaction,
    coin::{CoinRepoAddCoinsError, CoinRepository},
    heart::HeartRepository,
    mfa::MfaRepository,
    session::SessionRepository,
    user::{UserRepoError, UserRepository},
    withdrawal::WithdrawalRepository,
};
use crate::upstream::academy_shared_contracts::{
    captcha::{CaptchaCheckError, CaptchaService},
    hash::HashService,
    id::IdService,
    jwt::{JwtService, VerifyJwtError},
    password::{PasswordService, PasswordVerifyError},
    secret::SecretService,
    time::TimeService,
    totp::{TotpCheckError, TotpService},
};
use crate::upstream::academy_utils::patch::PatchValue;
use crate::upstream::uuid::Uuid;

/// The committed database, the cache and the trusted inputs of one request.
pub struct World {
    pub db: Mutex<k::Db>,
    /// key -> (JSON value, expiry in seconds)
    pub cache: Mutex<BTreeMap<String, (String, Option<u64>)>>,
    pub fresh: AtomicU64,
    pub env: k::Env,
}
pub type W = Arc<World>;

pub fn dt(secs: u64) -> DateTime<Utc> {
    DateTime::from_timestamp(secs as i64, 0).unwrap()
}
pub fn secs(t: DateTime<Utc>) -> u64 {
    t.timestamp() as u64
}
pub fn uid(n: u64) -> Uuid {
    Uuid(n)
}
pub fn s(b: &[u8]) -> String {
    String::from_utf8(b.to_vec()).unwrap()
}

/// Injective stand-in for SHA-256 on short inputs.
pub fn fake_sha(data: &[u8]) -> [u8; 32] {
    assert!(data.len() < 32, "input too long for the stand-in hash");
    let mut h = [0u8; 32];
    h[0] = data.len() as u8;
    h[1..=data.len()].copy_from_slice(data);
    h
}
pub fn unsha(h: &[u8; 32]) -> Vec<u8> {
    h[1..=h[0] as usize].to_vec()
}
/// A kernel token or code `n` is the decimal string upstream hashes.
pub fn hash_of(n: u64) -> Sha256Hash {
    Sha256Hash(fake_sha(n.to_string().as_bytes()))
}
pub fn unhash(h: &Sha256Hash) -> u64 {
    s(&unsha(&h.0)).parse().unwrap()
}
pub fn secret_of(n: u64) -> TotpSecret {
    TotpSecret(n.to_le_bytes().to_vec())
}
pub fn unsecret(t: &TotpSecret) -> u64 {
    u64::from_le_bytes(t.0.as_slice().try_into().unwrap())
}

/// The cache key upstream formats for a kernel key.
pub fn cache_key(key: &k::CacheKey) -> String {
    match key {
        k::CacheKey::Invalidated(h) => format!("access_token_invalidated:{}", hex::encode(hash_of(*h).0)),
        k::CacheKey::FailedAuth(v) => format!("failed_auth_attempts:{}", hex::encode(fake_sha(v))),
        k::CacheKey::ThrottleAccount(v) => format!("login_throttle_account:{}", hex::encode(fake_sha(v))),
        k::CacheKey::ThrottleIp(ip) => {
            let a = std::net::IpAddr::from(std::net::Ipv4Addr::from(*ip as u32));
            format!("login_throttle_ip:{}", hex::encode(fake_sha(a.to_string().as_bytes())))
        }
    }
}

/// `login_throttle.rs` `FailedAttempts`, which is private upstream.
#[derive(serde::Serialize, serde::Deserialize)]
struct FailedAttemptsJson {
    count: u64,
    #[serde(default)]
    blocked_until: Option<DateTime<Utc>>,
}

/// The JSON upstream stores for a kernel value.
pub fn cache_json(v: &k::CacheValue) -> String {
    match v {
        k::CacheValue::Unit => serde_json::to_string(&()).unwrap(),
        k::CacheValue::Count(n) => serde_json::to_string(n).unwrap(),
        k::CacheValue::Attempts(a) => serde_json::to_string(&FailedAttemptsJson {
            count: a.count,
            blocked_until: a.blocked_until.map(dt),
        })
        .unwrap(),
    }
}

// Database

pub struct MemDb(pub W);
pub struct MemTxn {
    pub db: k::Db,
    w: W,
}

impl Database for MemDb {
    type Transaction = MemTxn;
    async fn begin_transaction(&self) -> anyhow::Result<MemTxn> {
        Ok(MemTxn { db: self.0.db.lock().unwrap().clone(), w: self.0.clone() })
    }
}
impl DbTransaction for MemTxn {
    async fn commit(self) -> anyhow::Result<()> {
        *self.w.db.lock().unwrap() = self.db;
        Ok(())
    }
}

pub struct Repo;

fn user_of(db: &k::Db, u: &k::User) -> UserComposite {
    UserComposite {
        user: User {
            id: UserId(uid(u.id)),
            name: UserName(s(&u.name)),
            email: u.email.as_ref().map(|e| EmailAddress(s(e))),
            email_verified: u.email_verified,
            last_login: u.last_login.map(dt),
            enabled: u.enabled,
            admin: u.admin,
        },
        // user_details: `exists (... where td.user_id=u.id and td.enabled)`
        details: UserDetails { mfa_enabled: db.totp_devices.iter().any(|d| d.user_id == u.id && d.enabled) },
    }
}

pub fn session_of(x: &k::Session) -> Session {
    Session {
        id: SessionId(uid(x.id)),
        user_id: UserId(uid(x.user_id)),
        device_name: x.device_name.as_ref().map(|d| DeviceName(s(d))),
        created_at: dt(x.created_at),
        updated_at: dt(x.updated_at),
        mfa_verified: x.mfa_verified,
    }
}

impl UserRepository<MemTxn> for Repo {
    async fn exists(&self, txn: &mut MemTxn, user_id: UserId) -> anyhow::Result<bool> {
        Ok(txn.db.users.iter().any(|u| u.id == user_id.0.0))
    }
    async fn get_composite(&self, txn: &mut MemTxn, user_id: UserId) -> anyhow::Result<Option<UserComposite>> {
        Ok(txn.db.users.iter().find(|u| u.id == user_id.0.0).map(|u| user_of(&txn.db, u)))
    }
    async fn get_composite_by_name(&self, txn: &mut MemTxn, name: &UserName) -> anyhow::Result<Option<UserComposite>> {
        let key = name.0.to_lowercase();
        Ok(txn.db.users.iter().find(|u| s(&u.name).to_lowercase() == key).map(|u| user_of(&txn.db, u)))
    }
    async fn get_composite_by_email(&self, txn: &mut MemTxn, email: &EmailAddress) -> anyhow::Result<Option<UserComposite>> {
        let key = email.0.to_lowercase();
        Ok(txn
            .db
            .users
            .iter()
            .find(|u| u.email.as_ref().is_some_and(|e| s(e).to_lowercase() == key))
            .map(|u| user_of(&txn.db, u)))
    }
    async fn update<'a>(&self, txn: &mut MemTxn, user_id: UserId, patch: UserPatchRef<'a>) -> Result<bool, UserRepoError> {
        let mut n = 0;
        for u in txn.db.users.iter_mut().filter(|u| u.id == user_id.0.0) {
            // `last_login=coalesce(:last_login, last_login)`
            if let Some(Some(t)) = patch.last_login.update() {
                u.last_login = Some(secs(*t));
            }
            n += 1;
        }
        Ok(n != 0)
    }
    async fn get_password_hash(&self, txn: &mut MemTxn, user_id: UserId) -> anyhow::Result<Option<String>> {
        Ok(txn.db.passwords.iter().find(|p| p.user_id == user_id.0.0).map(|p| s(&p.hash)))
    }
}

impl SessionRepository<MemTxn> for Repo {
    async fn get(&self, txn: &mut MemTxn, session_id: SessionId) -> anyhow::Result<Option<Session>> {
        Ok(txn.db.sessions.iter().find(|x| x.id == session_id.0.0).map(session_of))
    }
    async fn get_by_refresh_token_hash(&self, txn: &mut MemTxn, h: SessionRefreshTokenHash) -> anyhow::Result<Option<Session>> {
        let h = unhash(&h);
        let rows: Vec<_> = txn
            .db
            .sessions
            .iter()
            .filter(|x| txn.db.refresh_tokens.iter().any(|r| r.session_id == x.id && r.hash == h))
            .collect();
        // `.opt()`: more than one row is an error.
        if rows.len() > 1 {
            return Err(anyhow!("query returned more than one row"));
        }
        Ok(rows.first().map(|x| session_of(x)))
    }
    async fn list_by_user(&self, txn: &mut MemTxn, user_id: UserId) -> anyhow::Result<Vec<Session>> {
        Ok(txn.db.sessions.iter().filter(|x| x.user_id == user_id.0.0).map(session_of).collect())
    }
    async fn create(&self, txn: &mut MemTxn, x: &Session) -> anyhow::Result<()> {
        if txn.db.sessions.iter().any(|y| y.id == x.id.0.0) {
            return Err(anyhow!("duplicate key"));
        }
        txn.db.sessions.push(k::Session {
            id: x.id.0.0,
            user_id: x.user_id.0.0,
            device_name: x.device_name.as_ref().map(|d| d.0.as_bytes().to_vec()),
            created_at: secs(x.created_at),
            updated_at: secs(x.updated_at),
            mfa_verified: x.mfa_verified,
        });
        Ok(())
    }
    async fn update<'a>(&self, txn: &mut MemTxn, session_id: SessionId, patch: SessionPatchRef<'a>) -> anyhow::Result<bool> {
        let Some(owner) = txn.db.sessions.iter().find(|x| x.id == session_id.0.0).map(|x| x.user_id) else {
            return Ok(false);
        };
        if !txn.db.users.iter().any(|u| u.id == owner && u.enabled) {
            return Ok(false);
        }
        let mut n = 0;
        for x in txn.db.sessions.iter_mut().filter(|x| x.id == session_id.0.0) {
            if let Some(d) = patch.device_name.update() {
                x.device_name = d.as_ref().map(|d| d.0.as_bytes().to_vec());
            }
            if let Some(t) = patch.updated_at.update() {
                x.updated_at = secs(**t);
            }
            n += 1;
        }
        Ok(n != 0)
    }
    async fn clear_mfa_verified_by_user(&self, txn: &mut MemTxn, user_id: UserId) -> anyhow::Result<()> {
        for x in txn.db.sessions.iter_mut().filter(|x| x.user_id == user_id.0.0) {
            x.mfa_verified = false;
        }
        Ok(())
    }
    async fn delete(&self, txn: &mut MemTxn, session_id: SessionId) -> anyhow::Result<bool> {
        let before = txn.db.sessions.len();
        txn.db.sessions.retain(|x| x.id != session_id.0.0);
        let sessions = txn.db.sessions.clone();
        txn.db.refresh_tokens.retain(|r| sessions.iter().any(|x| x.id == r.session_id));
        Ok(txn.db.sessions.len() != before)
    }
    async fn delete_by_user(&self, txn: &mut MemTxn, user_id: UserId) -> anyhow::Result<()> {
        txn.db.sessions.retain(|x| x.user_id != user_id.0.0);
        let sessions = txn.db.sessions.clone();
        txn.db.refresh_tokens.retain(|r| sessions.iter().any(|x| x.id == r.session_id));
        Ok(())
    }
    async fn list_refresh_token_hashes_by_user(&self, txn: &mut MemTxn, user_id: UserId) -> anyhow::Result<Vec<SessionRefreshTokenHash>> {
        Ok(txn
            .db
            .refresh_tokens
            .iter()
            .filter(|r| txn.db.sessions.iter().any(|x| x.id == r.session_id && x.user_id == user_id.0.0))
            .map(|r| hash_of(r.hash).into())
            .collect())
    }
    async fn get_refresh_token_hash(&self, txn: &mut MemTxn, session_id: SessionId) -> anyhow::Result<Option<SessionRefreshTokenHash>> {
        Ok(txn.db.refresh_tokens.iter().find(|r| r.session_id == session_id.0.0).map(|r| hash_of(r.hash).into()))
    }
    async fn save_refresh_token_hash(&self, txn: &mut MemTxn, session_id: SessionId, h: SessionRefreshTokenHash) -> anyhow::Result<()> {
        if !txn.db.sessions.iter().any(|x| x.id == session_id.0.0) {
            return Err(anyhow!("foreign key violation"));
        }
        let h = unhash(&h);
        match txn.db.refresh_tokens.iter_mut().find(|r| r.session_id == session_id.0.0) {
            Some(r) => r.hash = h,
            None => txn.db.refresh_tokens.push(k::RefreshTokenRow { session_id: session_id.0.0, hash: h }),
        }
        Ok(())
    }
}

fn device_of(d: &k::TotpDevice) -> TotpDevice {
    TotpDevice {
        id: TotpDeviceId(uid(d.id)),
        user_id: UserId(uid(d.user_id)),
        enabled: d.enabled,
        created_at: dt(d.created_at),
    }
}

impl MfaRepository<MemTxn> for Repo {
    async fn list_totp_devices_by_user(&self, txn: &mut MemTxn, user_id: UserId) -> anyhow::Result<Vec<TotpDevice>> {
        Ok(txn.db.totp_devices.iter().filter(|d| d.user_id == user_id.0.0).map(device_of).collect())
    }
    async fn create_totp_device(&self, txn: &mut MemTxn, d: &TotpDevice, secret: &TotpSecret) -> anyhow::Result<()> {
        // `user_id uuid unique`
        if txn.db.totp_devices.iter().any(|x| x.id == d.id.0.0 || x.user_id == d.user_id.0.0) {
            return Err(anyhow!("duplicate key"));
        }
        txn.db.totp_devices.push(k::TotpDevice {
            id: d.id.0.0,
            user_id: d.user_id.0.0,
            enabled: d.enabled,
            created_at: secs(d.created_at),
            secret: unsecret(secret),
        });
        Ok(())
    }
    async fn update_totp_device<'a>(&self, txn: &mut MemTxn, id: TotpDeviceId, patch: TotpDevicePatchRef<'a>) -> anyhow::Result<bool> {
        let mut n = 0;
        for d in txn.db.totp_devices.iter_mut().filter(|d| d.id == id.0.0) {
            if let PatchValue::Update(e) = patch.enabled {
                d.enabled = *e;
            }
            n += 1;
        }
        Ok(n != 0)
    }
    async fn delete_totp_devices_by_user(&self, txn: &mut MemTxn, user_id: UserId) -> anyhow::Result<()> {
        txn.db.totp_devices.retain(|d| d.user_id != user_id.0.0);
        Ok(())
    }
    async fn list_enabled_totp_device_secrets_by_user(&self, txn: &mut MemTxn, user_id: UserId) -> anyhow::Result<Vec<TotpSecret>> {
        Ok(txn
            .db
            .totp_devices
            .iter()
            .filter(|d| d.user_id == user_id.0.0 && d.enabled)
            .map(|d| secret_of(d.secret))
            .collect())
    }
    async fn get_totp_device_secret(&self, txn: &mut MemTxn, id: TotpDeviceId) -> anyhow::Result<TotpSecret> {
        txn.db.totp_devices.iter().find(|d| d.id == id.0.0).map(|d| secret_of(d.secret)).ok_or(anyhow!("no rows"))
    }
    async fn save_totp_device_secret(&self, txn: &mut MemTxn, id: TotpDeviceId, secret: &TotpSecret) -> anyhow::Result<()> {
        let d = txn.db.totp_devices.iter_mut().find(|d| d.id == id.0.0).ok_or(anyhow!("foreign key violation"))?;
        d.secret = unsecret(secret);
        Ok(())
    }
    async fn get_mfa_recovery_code_hash(&self, txn: &mut MemTxn, user_id: UserId) -> anyhow::Result<Option<MfaRecoveryCodeHash>> {
        Ok(txn.db.recovery_codes.iter().find(|r| r.user_id == user_id.0.0).map(|r| hash_of(r.hash).into()))
    }
    async fn save_mfa_recovery_code_hash(&self, txn: &mut MemTxn, user_id: UserId, h: MfaRecoveryCodeHash) -> anyhow::Result<()> {
        let h = unhash(&h);
        match txn.db.recovery_codes.iter_mut().find(|r| r.user_id == user_id.0.0) {
            Some(r) => r.hash = h,
            None => txn.db.recovery_codes.push(k::RecoveryCode { user_id: user_id.0.0, hash: h }),
        }
        Ok(())
    }
    async fn delete_mfa_recovery_code_hash(&self, txn: &mut MemTxn, user_id: UserId) -> anyhow::Result<()> {
        txn.db.recovery_codes.retain(|r| r.user_id != user_id.0.0);
        Ok(())
    }
}

impl CoinRepository<MemTxn> for Repo {
    async fn get_balance(&self, txn: &mut MemTxn, user_id: UserId) -> anyhow::Result<Balance> {
        Ok(txn
            .db
            .coins
            .iter()
            .find(|r| r.user_id == user_id.0.0)
            .map(|r| Balance { coins: r.coins.try_into().unwrap(), withheld_coins: r.withheld_coins.try_into().unwrap() })
            .unwrap_or_default())
    }
    async fn add_coins(&self, txn: &mut MemTxn, user_id: UserId, coins: i64, withhold: bool) -> Result<Balance, CoinRepoAddCoinsError> {
        let (c, w) = if withhold { (0, coins) } else { (coins, 0) };
        let (nc, nw) = match txn.db.coins.iter().find(|r| r.user_id == user_id.0.0) {
            Some(r) => (
                r.coins.checked_add(c).ok_or(anyhow!("bigint out of range"))?,
                r.withheld_coins.checked_add(w).ok_or(anyhow!("bigint out of range"))?,
            ),
            None => (c, w),
        };
        if nc < 0 || nw < 0 {
            return Err(CoinRepoAddCoinsError::NotEnoughCoins);
        }
        match txn.db.coins.iter_mut().find(|r| r.user_id == user_id.0.0) {
            Some(r) => {
                r.coins = nc;
                r.withheld_coins = nw;
            }
            None => txn.db.coins.push(k::CoinRow { user_id: user_id.0.0, coins: nc, withheld_coins: nw }),
        }
        Ok(Balance { coins: nc as u64, withheld_coins: nw as u64 })
    }
    async fn create_transaction(&self, txn: &mut MemTxn, t: &Transaction) -> anyhow::Result<()> {
        txn.db.transactions.push(k::Transaction {
            id: t.id.0.0,
            user_id: t.user_id.0.0,
            coins: t.coins,
            description: t.description.as_ref().map(|d| d.0.as_bytes().to_vec()),
            created_at: secs(t.created_at),
            include_in_credit_note: t.include_in_credit_note,
        });
        Ok(())
    }
}

impl HeartRepository<MemTxn> for Repo {
    async fn get(&self, txn: &mut MemTxn, user_id: UserId) -> anyhow::Result<Option<Hearts>> {
        Ok(txn
            .db
            .hearts
            .iter()
            .find(|r| r.user_id == user_id.0.0)
            .map(|r| Hearts { hearts: r.hearts, last_refill: dt(r.last_refill) }))
    }
    async fn set(&self, txn: &mut MemTxn, user_id: UserId, h: Hearts) -> anyhow::Result<()> {
        let _: i64 = h.hearts.try_into()?;
        match txn.db.hearts.iter_mut().find(|r| r.user_id == user_id.0.0) {
            Some(r) => {
                r.hearts = h.hearts;
                r.last_refill = secs(h.last_refill);
            }
            None => txn.db.hearts.push(k::HeartRow { user_id: user_id.0.0, hearts: h.hearts, last_refill: secs(h.last_refill) }),
        }
        Ok(())
    }
}

impl WithdrawalRepository<MemTxn> for Repo {
    async fn create(&self, txn: &mut MemTxn, c: &WithdrawalConsent) -> anyhow::Result<()> {
        assert_eq!(c.subject, WithdrawalSubject::Hearts);
        assert!(c.reference.is_none());
        txn.db.consents.push(k::Consent {
            id: c.id.0.0,
            user_id: c.user_id.0.0,
            text_version: c.text_version.0.as_bytes().to_vec(),
            consented_at: secs(c.consented_at),
        });
        Ok(())
    }
}

// Valkey

pub struct MemCache(pub W);

impl MemCache {
    fn live(&self, key: &str) -> Option<String> {
        let now = self.0.env.now;
        match self.0.cache.lock().unwrap().get(key) {
            Some((v, exp)) if exp.is_none_or(|e| now < e) => Some(v.clone()),
            _ => None,
        }
    }
}

impl CacheService for MemCache {
    async fn get<T: DeserializeOwned + std::fmt::Debug + 'static>(&self, key: &str) -> anyhow::Result<Option<T>> {
        Ok(match self.live(key) {
            Some(v) => Some(serde_json::from_str(&v)?),
            None => None,
        })
    }
    async fn set<T: Serialize + std::fmt::Debug + Sync + 'static>(&self, key: &str, value: &T, ttl: Option<Duration>) -> anyhow::Result<()> {
        let exp = ttl.map(|t| {
            assert_eq!(t.subsec_nanos(), 0);
            self.0.env.now.saturating_add(t.as_secs())
        });
        self.0.cache.lock().unwrap().insert(key.into(), (serde_json::to_string(value)?, exp));
        Ok(())
    }
    async fn pop<T: DeserializeOwned + std::fmt::Debug + 'static>(&self, _: &str) -> anyhow::Result<Option<T>> {
        unimplemented!()
    }
    async fn remove(&self, key: &str) -> anyhow::Result<()> {
        self.0.cache.lock().unwrap().remove(key);
        Ok(())
    }
    async fn ping(&self) -> anyhow::Result<()> {
        Ok(())
    }
}

// Shared services, as trusted oracles.

pub struct Svc(pub W);

impl Svc {
    fn next(&self) -> u64 {
        self.0.fresh.fetch_add(1, Ordering::SeqCst)
    }
}

impl TimeService for Svc {
    fn now(&self) -> DateTime<Utc> {
        dt(self.0.env.now)
    }
}

impl IdService for Svc {
    fn generate<I: From<Uuid> + std::fmt::Debug + 'static>(&self) -> I {
        I::from(uid(self.next()))
    }
}

impl HashService for Svc {
    fn sha256<T: AsRef<[u8]> + std::fmt::Debug + 'static>(&self, data: &T) -> Sha256Hash {
        Sha256Hash(fake_sha(data.as_ref()))
    }
}

impl SecretService for Svc {
    fn generate(&self, _len: usize) -> Sensitive<String> {
        Sensitive(self.next().to_string())
    }
    fn generate_bytes(&self, _len: usize) -> Sensitive<Vec<u8>> {
        unimplemented!()
    }
    fn generate_verification_code(&self) -> VerificationCode {
        unimplemented!()
    }
    fn generate_mfa_recovery_code(&self) -> MfaRecoveryCode {
        MfaRecoveryCode(self.next().to_string())
    }
}

impl TotpService for Svc {
    fn generate_secret(&self) -> (TotpSecret, TotpSetup) {
        let n = self.next();
        (secret_of(n), TotpSetup { secret: TotpSecretBase32(n.to_string()) })
    }
    async fn check(&self, code: &TotpCode, secret: TotpSecret) -> Result<(), TotpCheckError> {
        let (code, secret) = (code.0.parse::<u64>().unwrap(), unsecret(&secret));
        match self.0.env.totp.iter().find(|t| t.0 == code && t.1 == secret).map(|t| t.2) {
            Some(k::TotpCheck::Ok) => Ok(()),
            Some(k::TotpCheck::RecentlyUsed) => Err(TotpCheckError::RecentlyUsed),
            _ => Err(TotpCheckError::InvalidCode),
        }
    }
}

impl CaptchaService for Svc {
    fn get_recaptcha_sitekey<'a>(&'a self) -> Option<&'a str> {
        None
    }
    async fn check<'a>(&self, _response: Option<&'a str>) -> Result<(), CaptchaCheckError> {
        if self.0.env.captcha_ok { Ok(()) } else { Err(CaptchaCheckError::Failed) }
    }
}

impl PasswordService for Svc {
    async fn hash(&self, _: Sensitive<String>) -> anyhow::Result<String> {
        unimplemented!()
    }
    async fn verify(&self, password: Sensitive<String>, hash: String) -> Result<(), PasswordVerifyError> {
        let ok = self.0.env.argon2_ok.iter().any(|(p, h)| *p == password.0.as_bytes() && *h == hash.as_bytes());
        if ok { Ok(()) } else { Err(PasswordVerifyError::InvalidPassword) }
    }
}

/// The JWT is the JSON of its claims; signature and expiry are trusted.
impl JwtService for Svc {
    fn sign<T: Serialize + std::fmt::Debug + 'static>(&self, data: T, _ttl: Duration) -> anyhow::Result<String> {
        Ok(serde_json::to_string(&data)?)
    }
    fn verify<T: DeserializeOwned + std::fmt::Debug + 'static>(&self, jwt: &str) -> Result<T, VerifyJwtError<T>> {
        serde_json::from_str(jwt).map_err(|_| VerifyJwtError::Invalid)
    }
    fn sign_with_key<T: Serialize + std::fmt::Debug + 'static>(&self, _: &str, _: T, _: Duration) -> anyhow::Result<String> {
        unimplemented!()
    }
    fn verify_with_key<T: DeserializeOwned + std::fmt::Debug + 'static>(&self, _: &str, _: &str) -> Result<T, VerifyJwtError<T>> {
        unimplemented!()
    }
}

impl FinanceCoinService for Svc {
    fn vat_percent(&self) -> Decimal {
        19
    }
    fn coins_per_euro(&self) -> u64 {
        100
    }
}

/// Runs a future that never waits: everything here is in memory.
pub fn block_on<F: std::future::Future>(f: F) -> F::Output {
    let mut f = std::pin::pin!(f);
    let mut cx = std::task::Context::from_waker(std::task::Waker::noop());
    match f.as_mut().poll(&mut cx) {
        std::task::Poll::Ready(x) => x,
        std::task::Poll::Pending => panic!("in-memory future pending"),
    }
}

pub fn description(d: &Option<Vec<u8>>) -> Option<TransactionDescription> {
    d.as_ref().map(|d| TransactionDescription(s(d)))
}
