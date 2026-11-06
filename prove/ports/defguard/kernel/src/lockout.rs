//! `crates/defguard_core/src/auth/failed_login.rs` (the failed-login tracker)
//! and the part of `handlers/auth.rs` `authenticate` that consults it.
//!
//! Time is an input: `now` is `Local::now()` as nanoseconds since the epoch
//! (chrono's `signed_duration_since` is exact to the nanosecond).

/// `FAILED_LOGIN_WINDOW`: 60 s.
pub const WINDOW_NS: i64 = 60_000_000_000;
/// `FAILED_LOGIN_COUNT`.
pub const COUNT: u32 = 5;
/// `FAILED_LOGIN_TIMEOUT`: 5 min.
pub const TIMEOUT_NS: i64 = 300_000_000_000;

/// One entry of `FailedLoginMap`, with its key.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FailedLogin {
    pub key: Vec<u8>,
    pub attempt_count: u32,
    pub first_attempt: i64,
    pub last_attempt: i64,
}

/// `FailedLogin::should_prevent_login`.
pub fn should_prevent_login(f: &FailedLogin, now: i64) -> bool {
    f.attempt_count >= COUNT && now - f.last_attempt <= TIMEOUT_NS
}

/// `FailedLogin::should_reset_counter`.
pub fn should_reset_counter(f: &FailedLogin, now: i64) -> bool {
    (now - f.first_attempt > WINDOW_NS && f.attempt_count < COUNT) || now - f.last_attempt > TIMEOUT_NS
}

fn bytes_eq(a: &[u8], b: &[u8]) -> bool {
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

/// The entry `HashMap::get` finds for `key`.
pub fn find_entry(map: &Vec<FailedLogin>, key: &[u8]) -> Option<usize> {
    let mut i = 0;
    while i < map.len() {
        if bytes_eq(&map[i].key, key) {
            return Some(i);
        }
        i += 1;
    }
    None
}

/// `map` with entry `i` replaced by `f`.
fn set_entry(map: &Vec<FailedLogin>, i: usize, f: FailedLogin) -> Vec<FailedLogin> {
    let mut res = map.clone();
    if i < res.len() {
        res[i] = f;
    }
    res
}

/// `FailedLogin::increment`. The `+= 1` of a release build wraps.
fn incremented(f: &FailedLogin, now: i64) -> FailedLogin {
    FailedLogin {
        key: f.key.clone(),
        attempt_count: f.attempt_count.wrapping_add(1),
        first_attempt: f.first_attempt,
        last_attempt: now,
    }
}

/// `FailedLogin::default()` / `reset()`: one attempt, now.
fn fresh(key: &[u8], now: i64) -> FailedLogin {
    let mut k = Vec::new();
    let mut i = 0;
    while i < key.len() {
        k.push(key[i]);
        i += 1;
    }
    FailedLogin { key: k, attempt_count: 1, first_attempt: now, last_attempt: now }
}

/// `FailedLoginMap::log_failed_attempt`.
pub fn log_failed_attempt(map: &Vec<FailedLogin>, key: &[u8], now: i64) -> Vec<FailedLogin> {
    match find_entry(map, key) {
        None => {
            let mut res = map.clone();
            res.push(fresh(key, now));
            res
        }
        Some(i) => {
            if should_reset_counter(&map[i], now) {
                set_entry(map, i, fresh(key, now))
            } else {
                set_entry(map, i, incremented(&map[i], now))
            }
        }
    }
}

/// `FailedLoginMap::verify_username`: the new map, and whether the login is
/// refused. A refused attempt counts as a failure ("to prolong timeout").
pub fn verify_username(map: &Vec<FailedLogin>, key: &[u8], now: i64) -> (Vec<FailedLogin>, bool) {
    match find_entry(map, key) {
        None => (map.clone(), false),
        Some(i) => {
            if should_prevent_login(&map[i], now) {
                (set_entry(map, i, incremented(&map[i], now)), true)
            } else {
                (map.clone(), false)
            }
        }
    }
}

/// An account as `authenticate` looks it up.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Account {
    pub username: Vec<u8>,
    pub email: Vec<u8>,
}

/// PostgreSQL `LOWER` on ASCII (the difftest keeps emails ASCII).
fn lower(b: u8) -> u8 {
    if b >= b'A' && b <= b'Z' { b + 32 } else { b }
}

fn eq_lower(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut i = 0;
    while i < a.len() {
        if lower(a[i]) != lower(b[i]) {
            return false;
        }
        i += 1;
    }
    true
}

fn find_by_username(us: &Vec<Account>, name: &[u8]) -> Option<usize> {
    let mut i = 0;
    while i < us.len() {
        if bytes_eq(&us[i].username, name) {
            return Some(i);
        }
        i += 1;
    }
    None
}

fn find_by_email(us: &Vec<Account>, email: &[u8]) -> Option<usize> {
    let mut i = 0;
    while i < us.len() {
        if eq_lower(&us[i].email, email) {
            return Some(i);
        }
        i += 1;
    }
    None
}

/// `User::find_by_username_or_email`: `username = $1`, else
/// `LOWER(email) = LOWER($1)`.
pub fn find_by_username_or_email(us: &Vec<Account>, input: &[u8]) -> Option<usize> {
    match find_by_username(us, input) {
        Some(i) => Some(i),
        None => find_by_email(us, input),
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum LoginOutcome {
    /// `check_failed_logins` refused: "Too many login attempts".
    Blocked,
    /// The password verified for account `i`; the handler goes on to MFA.
    Verified(usize),
    /// Wrong password for a known account.
    WrongPassword,
    /// No account (and LDAP, off here, does not find one either).
    UnknownUser,
}

/// The lockout part of `handlers/auth.rs` `authenticate`, LDAP disabled:
/// check the tracker under the name the client typed, look the account up
/// by username or email, verify the password (`password_ok(i)` is
/// `verify_password` for account `i`, as a table), and log a failure under
/// the account's username, or under the typed name if there is no account.
pub fn authenticate(
    map: &Vec<FailedLogin>,
    us: &Vec<Account>,
    input: &[u8],
    password_ok: &Vec<bool>,
    now: i64,
) -> (Vec<FailedLogin>, LoginOutcome) {
    let (m1, blocked) = verify_username(map, input, now);
    if blocked {
        return (m1, LoginOutcome::Blocked);
    }
    match find_by_username_or_email(us, input) {
        None => (log_failed_attempt(&m1, input, now), LoginOutcome::UnknownUser),
        Some(i) => {
            if i < password_ok.len() && password_ok[i] {
                (m1, LoginOutcome::Verified(i))
            } else {
                (log_failed_attempt(&m1, &us[i].username, now), LoginOutcome::WrongPassword)
            }
        }
    }
}
