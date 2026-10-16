//! The repository queries the ported code runs (`academy_persistence/postgres`,
//! `queries/*.sql`), over the tables of `Db`, and `apply` for their writes.
use crate::{
    bytes_eq, lower, CoinRow, Consent, Db, HeartRow, RecoveryCode, RefreshTokenRow, Session, TotpDevice,
    User, UserComposite, Write,
};

/// `user_details.mfa_enabled`: an enabled TOTP device exists.
pub fn mfa_enabled(db: &Db, user_id: u64) -> bool {
    let mut i = 0;
    while i < db.totp_devices.len() {
        if db.totp_devices[i].user_id == user_id && db.totp_devices[i].enabled {
            return true;
        }
        i += 1;
    }
    false
}

fn composite(db: &Db, u: &User) -> UserComposite {
    UserComposite { user: u.clone(), mfa_enabled: mfa_enabled(db, u.id) }
}

/// `user.sql` `exists`.
pub fn user_exists(db: &Db, user_id: u64) -> bool {
    let mut i = 0;
    while i < db.users.len() {
        if db.users[i].id == user_id {
            return true;
        }
        i += 1;
    }
    false
}

/// `user.sql` `get_composite`.
pub fn get_composite(db: &Db, user_id: u64) -> Option<UserComposite> {
    let mut i = 0;
    while i < db.users.len() {
        if db.users[i].id == user_id {
            return Some(composite(db, &db.users[i]));
        }
        i += 1;
    }
    None
}

/// `user.sql` `get_composite_by_name`: `lower(name)=lower(:name)`.
pub fn get_composite_by_name(db: &Db, name: &[u8]) -> Option<UserComposite> {
    let key = lower(name);
    let mut i = 0;
    while i < db.users.len() {
        if bytes_eq(&lower(&db.users[i].name), &key) {
            return Some(composite(db, &db.users[i]));
        }
        i += 1;
    }
    None
}

fn email_matches(email: &Option<Vec<u8>>, key: &[u8]) -> bool {
    match email {
        Some(e) => bytes_eq(&lower(e), key),
        None => false,
    }
}

/// `user.sql` `get_composite_by_email`: `lower(email)=lower(:email)`.
pub fn get_composite_by_email(db: &Db, email: &[u8]) -> Option<UserComposite> {
    let key = lower(email);
    let mut i = 0;
    while i < db.users.len() {
        if email_matches(&db.users[i].email, &key) {
            return Some(composite(db, &db.users[i]));
        }
        i += 1;
    }
    None
}

/// `UserRepository::get_password_hash`.
pub fn get_password_hash(db: &Db, user_id: u64) -> Option<Vec<u8>> {
    let mut i = 0;
    while i < db.passwords.len() {
        if db.passwords[i].user_id == user_id {
            return Some(db.passwords[i].hash.clone());
        }
        i += 1;
    }
    None
}

/// `session.sql` `get`.
pub fn get_session(db: &Db, session_id: u64) -> Option<Session> {
    let mut i = 0;
    while i < db.sessions.len() {
        if db.sessions[i].id == session_id {
            return Some(db.sessions[i].clone());
        }
        i += 1;
    }
    None
}

/// `session.sql` `get_refresh_token_hash`.
pub fn get_refresh_token_hash(db: &Db, session_id: u64) -> Option<u64> {
    let mut i = 0;
    while i < db.refresh_tokens.len() {
        if db.refresh_tokens[i].session_id == session_id {
            return Some(db.refresh_tokens[i].hash);
        }
        i += 1;
    }
    None
}

/// `session.sql` `get_by_refresh_token_hash`: sessions joined with
/// `session_refresh_tokens`.
pub fn get_by_refresh_token_hash(db: &Db, hash: u64) -> Option<Session> {
    let mut i = 0;
    while i < db.refresh_tokens.len() {
        if db.refresh_tokens[i].hash == hash {
            return get_session(db, db.refresh_tokens[i].session_id);
        }
        i += 1;
    }
    None
}

/// `session.sql` `list_by_user`.
pub fn list_sessions_by_user(db: &Db, user_id: u64) -> Vec<Session> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < db.sessions.len() {
        if db.sessions[i].user_id == user_id {
            out.push(db.sessions[i].clone());
        }
        i += 1;
    }
    out
}

fn session_user(db: &Db, session_id: u64) -> Option<u64> {
    match get_session(db, session_id) {
        Some(s) => Some(s.user_id),
        None => None,
    }
}

/// `session.sql` `list_refresh_token_hashes_by_user`.
pub fn list_refresh_token_hashes_by_user(db: &Db, user_id: u64) -> Vec<u64> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < db.refresh_tokens.len() {
        match session_user(db, db.refresh_tokens[i].session_id) {
            Some(u) => {
                if u == user_id {
                    out.push(db.refresh_tokens[i].hash);
                }
            }
            None => {}
        }
        i += 1;
    }
    out
}

fn user_enabled(db: &Db, user_id: u64) -> bool {
    match get_composite(db, user_id) {
        Some(u) => u.user.enabled,
        None => false,
    }
}

/// `PostgresSessionRepository::update`: false when the session is gone or its
/// owner is disabled.
pub fn session_update_applies(db: &Db, session_id: u64) -> bool {
    match session_user(db, session_id) {
        Some(u) => user_enabled(db, u),
        None => false,
    }
}

/// `mfa.sql` `list_totp_devices_by_user`.
pub fn list_totp_devices_by_user(db: &Db, user_id: u64) -> Vec<TotpDevice> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < db.totp_devices.len() {
        if db.totp_devices[i].user_id == user_id {
            out.push(db.totp_devices[i].clone());
        }
        i += 1;
    }
    out
}

/// `mfa.sql` `list_enabled_totp_device_secrets_by_user`.
pub fn list_enabled_totp_device_secrets_by_user(db: &Db, user_id: u64) -> Vec<u64> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < db.totp_devices.len() {
        if db.totp_devices[i].user_id == user_id && db.totp_devices[i].enabled {
            out.push(db.totp_devices[i].secret);
        }
        i += 1;
    }
    out
}

/// `mfa.sql` `get_totp_device_secret` (`.one()`: no row is an error).
pub fn get_totp_device_secret(db: &Db, id: u64) -> Option<u64> {
    let mut i = 0;
    while i < db.totp_devices.len() {
        if db.totp_devices[i].id == id {
            return Some(db.totp_devices[i].secret);
        }
        i += 1;
    }
    None
}

/// `mfa.sql` `get_recovery_code_hash`.
pub fn get_mfa_recovery_code_hash(db: &Db, user_id: u64) -> Option<u64> {
    let mut i = 0;
    while i < db.recovery_codes.len() {
        if db.recovery_codes[i].user_id == user_id {
            return Some(db.recovery_codes[i].hash);
        }
        i += 1;
    }
    None
}

/// `coin.sql` `get_balance`, as the row.
pub fn get_coins(db: &Db, user_id: u64) -> Option<CoinRow> {
    let mut i = 0;
    while i < db.coins.len() {
        if db.coins[i].user_id == user_id {
            return Some(db.coins[i].clone());
        }
        i += 1;
    }
    None
}

/// `heart.sql` `get`.
pub fn get_hearts(db: &Db, user_id: u64) -> Option<HeartRow> {
    let mut i = 0;
    while i < db.hearts.len() {
        if db.hearts[i].user_id == user_id {
            return Some(db.hearts[i].clone());
        }
        i += 1;
    }
    None
}

fn delete_session(db: &mut Db, session_id: u64) {
    let mut sessions = Vec::new();
    let mut i = 0;
    while i < db.sessions.len() {
        if db.sessions[i].id != session_id {
            sessions.push(db.sessions[i].clone());
        }
        i += 1;
    }
    db.sessions = sessions;
    // `on delete cascade`
    let mut rts = Vec::new();
    let mut j = 0;
    while j < db.refresh_tokens.len() {
        if db.refresh_tokens[j].session_id != session_id {
            rts.push(db.refresh_tokens[j].clone());
        }
        j += 1;
    }
    db.refresh_tokens = rts;
}

fn keep_refresh_token(db: &Db, rt: &RefreshTokenRow) -> bool {
    match get_session(db, rt.session_id) {
        Some(_) => true,
        None => false,
    }
}

fn delete_sessions_by_user(db: &mut Db, user_id: u64) {
    let mut sessions = Vec::new();
    let mut i = 0;
    while i < db.sessions.len() {
        if db.sessions[i].user_id != user_id {
            sessions.push(db.sessions[i].clone());
        }
        i += 1;
    }
    db.sessions = sessions;
    let mut rts = Vec::new();
    let mut j = 0;
    while j < db.refresh_tokens.len() {
        if keep_refresh_token(db, &db.refresh_tokens[j]) {
            rts.push(db.refresh_tokens[j].clone());
        }
        j += 1;
    }
    db.refresh_tokens = rts;
}

fn update_session_updated_at(db: &mut Db, session_id: u64, updated_at: u64) {
    let mut i = 0;
    while i < db.sessions.len() {
        if db.sessions[i].id == session_id {
            db.sessions[i].updated_at = updated_at;
        }
        i += 1;
    }
}

fn clear_mfa_verified(db: &mut Db, user_id: u64) {
    let mut i = 0;
    while i < db.sessions.len() {
        if db.sessions[i].user_id == user_id {
            db.sessions[i].mfa_verified = false;
        }
        i += 1;
    }
}

/// `save_refresh_token_hash`: `on conflict (session_id) do update`.
fn save_refresh_token_hash(db: &mut Db, session_id: u64, hash: u64) {
    let mut i = 0;
    while i < db.refresh_tokens.len() {
        if db.refresh_tokens[i].session_id == session_id {
            db.refresh_tokens[i].hash = hash;
            return;
        }
        i += 1;
    }
    db.refresh_tokens.push(RefreshTokenRow { session_id, hash });
}

fn update_last_login(db: &mut Db, user_id: u64, at: u64) {
    let mut i = 0;
    while i < db.users.len() {
        if db.users[i].id == user_id {
            db.users[i].last_login = Some(at);
        }
        i += 1;
    }
}

fn update_totp_device_enabled(db: &mut Db, id: u64, enabled: bool) {
    let mut i = 0;
    while i < db.totp_devices.len() {
        if db.totp_devices[i].id == id {
            db.totp_devices[i].enabled = enabled;
        }
        i += 1;
    }
}

fn save_totp_device_secret(db: &mut Db, id: u64, secret: u64) {
    let mut i = 0;
    while i < db.totp_devices.len() {
        if db.totp_devices[i].id == id {
            db.totp_devices[i].secret = secret;
        }
        i += 1;
    }
}

fn delete_totp_devices_by_user(db: &mut Db, user_id: u64) {
    let mut out = Vec::new();
    let mut i = 0;
    while i < db.totp_devices.len() {
        if db.totp_devices[i].user_id != user_id {
            out.push(db.totp_devices[i].clone());
        }
        i += 1;
    }
    db.totp_devices = out;
}

/// `set_recovery_code_hash`: `on conflict (user_id) do update`.
fn save_recovery_code_hash(db: &mut Db, user_id: u64, hash: u64) {
    let mut i = 0;
    while i < db.recovery_codes.len() {
        if db.recovery_codes[i].user_id == user_id {
            db.recovery_codes[i].hash = hash;
            return;
        }
        i += 1;
    }
    db.recovery_codes.push(RecoveryCode { user_id, hash });
}

fn delete_recovery_code_hash(db: &mut Db, user_id: u64) {
    let mut out = Vec::new();
    let mut i = 0;
    while i < db.recovery_codes.len() {
        if db.recovery_codes[i].user_id != user_id {
            out.push(db.recovery_codes[i].clone());
        }
        i += 1;
    }
    db.recovery_codes = out;
}

/// `coin.sql` `add_coins` (`merge`); the caller has checked the constraints.
fn add_coins(db: &mut Db, user_id: u64, coins: i64, withheld_coins: i64) {
    let mut i = 0;
    while i < db.coins.len() {
        if db.coins[i].user_id == user_id {
            db.coins[i].coins = db.coins[i].coins.wrapping_add(coins);
            db.coins[i].withheld_coins = db.coins[i].withheld_coins.wrapping_add(withheld_coins);
            return;
        }
        i += 1;
    }
    db.coins.push(CoinRow { user_id, coins, withheld_coins });
}

/// `heart.sql` `set`: `on conflict (user_id) do update`.
fn set_hearts(db: &mut Db, user_id: u64, hearts: u64, last_refill: u64) {
    let mut i = 0;
    while i < db.hearts.len() {
        if db.hearts[i].user_id == user_id {
            db.hearts[i].hearts = hearts;
            db.hearts[i].last_refill = last_refill;
            return;
        }
        i += 1;
    }
    db.hearts.push(HeartRow { user_id, hearts, last_refill });
}

fn create_consent(db: &mut Db, c: &Consent) {
    db.consents.push(c.clone());
}

/// The effect of a database write. Cache writes leave `db` alone.
pub fn apply(db: &mut Db, w: &Write) {
    match w {
        Write::CacheSet(_) | Write::CacheRemove(_) => {}
        Write::CreateSession(s) => db.sessions.push(s.clone()),
        Write::UpdateSessionUpdatedAt { session_id, updated_at } => {
            update_session_updated_at(db, *session_id, *updated_at)
        }
        Write::ClearMfaVerified { user_id } => clear_mfa_verified(db, *user_id),
        Write::DeleteSession { session_id } => delete_session(db, *session_id),
        Write::DeleteSessionsByUser { user_id } => delete_sessions_by_user(db, *user_id),
        Write::SaveRefreshTokenHash { session_id, hash } => save_refresh_token_hash(db, *session_id, *hash),
        Write::UpdateLastLogin { user_id, last_login } => update_last_login(db, *user_id, *last_login),
        Write::CreateTotpDevice(d) => db.totp_devices.push(d.clone()),
        Write::UpdateTotpDeviceEnabled { id, enabled } => update_totp_device_enabled(db, *id, *enabled),
        Write::SaveTotpDeviceSecret { id, secret } => save_totp_device_secret(db, *id, *secret),
        Write::DeleteTotpDevicesByUser { user_id } => delete_totp_devices_by_user(db, *user_id),
        Write::SaveRecoveryCodeHash { user_id, hash } => save_recovery_code_hash(db, *user_id, *hash),
        Write::DeleteRecoveryCodeHash { user_id } => delete_recovery_code_hash(db, *user_id),
        Write::AddCoins { user_id, coins, withheld_coins } => add_coins(db, *user_id, *coins, *withheld_coins),
        Write::CreateTransaction(t) => db.transactions.push(t.clone()),
        Write::SetHearts { user_id, hearts, last_refill } => set_hearts(db, *user_id, *hearts, *last_refill),
        Write::CreateConsent(c) => create_consent(db, c),
    }
}
