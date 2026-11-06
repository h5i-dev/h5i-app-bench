//! atuin's sync server (atuinsh/atuin @ df152cd, `crates/atuin-server`) as an
//! h5i-app kernel: authentication of the `Authorization: Token ...` header,
//! the account handlers (register, login, delete, change password), the record
//! store handlers (post, status, next, delete store), and the SQLite
//! backend's effect on the tables (`apply`).
//!
//! Written in the subset of Rust that Charon and Aeneas translate (no `?`, no
//! closures, no `String`; loops over indices). Each function names the
//! upstream code it follows; the differences are listed in ../DEVIATIONS.md.
//! Argon2 hashing and verification, random token generation, JSON and HTTP
//! parsing are outside: hashes and tokens are inputs, verification is the
//! `Crypto` table.

pub mod client_ip;

pub type Bytes = Vec<u8>;

/// `users` row (`db/models.rs` `User`). `password` is the stored PHC string.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct User {
    pub id: u64,
    pub username: Bytes,
    pub email: Bytes,
    pub password: Bytes,
}

/// `sessions` row (`db/models.rs` `Session`).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Session {
    pub id: u64,
    pub user_id: u64,
    pub token: Bytes,
}

/// `history` row: only the owner matters to the server since v0 sync was removed.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct HistoryRow {
    pub id: u64,
    pub user_id: u64,
}

/// `store` row: one `Record<EncryptedData>` of one user. `idx` and
/// `timestamp` are the client's `u64`s; the backend stores them as `i64`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StoreRow {
    pub user_id: u64,
    pub client_id: u128,
    pub host: u128,
    pub idx: u64,
    pub timestamp: u64,
    pub version: Bytes,
    pub tag: Bytes,
    pub data: Bytes,
    pub cek: Bytes,
}

/// The tables of one server database, rows in insertion (rowid) order, and
/// the AUTOINCREMENT counters.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Snapshot {
    pub users: Vec<User>,
    pub sessions: Vec<Session>,
    pub history: Vec<HistoryRow>,
    pub store: Vec<StoreRow>,
    pub next_user_id: u64,
    pub next_session_id: u64,
}

/// The settings the handlers read (`settings.rs`).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Config {
    pub open_registration: bool,
    /// `max_record_size.as_u64()`; 0 means no limit.
    pub max_record_size: u64,
}

/// A password that `HashedPassword::verify` accepts for a stored hash.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Verified {
    pub hash: Bytes,
    pub password: Bytes,
}

/// Argon2 verification as a table: `verify(hash, pw)` holds iff the pair is
/// listed. The theorems hold for every table; the difftest fills it from
/// the real `HashedPassword::verify`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Crypto {
    pub verified: Vec<Verified>,
}

/// A record as posted (`Record<EncryptedData>`).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct RecordIn {
    pub client_id: u128,
    pub host: u128,
    pub idx: u64,
    pub timestamp: u64,
    pub version: Bytes,
    pub tag: Bytes,
    pub data: Bytes,
    pub cek: Bytes,
}

/// The routes of `router.rs`. Hashes and tokens the handler would generate
/// (`HashedPassword::new`, `crypto_random_string`) are inputs.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Command {
    /// `GET /user/{username}`
    GetUser { username: Bytes },
    /// `POST /register`; `new_hash` is `HashedPassword::new(password)`, `token` the new session.
    Register { username: Bytes, email: Bytes, new_hash: Bytes, token: Bytes },
    /// `POST /login`
    Login { username: Bytes, password: Bytes },
    /// `GET /api/v0/me`
    Me,
    /// `DELETE /account`
    DeleteAccount { password: Bytes },
    /// `PATCH /account/password`; `new_hash` is `HashedPassword::new(new_password)`.
    ChangePassword { current_password: Bytes, new_hash: Bytes },
    /// `POST /api/v0/record`
    PostRecords { records: Vec<RecordIn> },
    /// `GET /api/v0/record`
    Status,
    /// `GET /api/v0/record/next`
    Next { host: u128, tag: Bytes, start: Option<u64>, count: u64 },
    /// `DELETE /api/v0/store`
    DeleteStore,
}

/// A request: the `Authorization` header value as the server received it,
/// and the route with its decoded body or query.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Request {
    pub authorization: Option<Bytes>,
    pub command: Command,
}

/// A change to the tables (the SQL each `Database` method runs).
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Write {
    /// `ADD_USER`
    AddUser(User),
    /// `ADD_SESSION`
    AddSession(Session),
    /// `UPDATE_USER_PASSWORD`
    SetPassword { user_id: u64, hash: Bytes },
    /// `delete_user`: the user's sessions, history, store, then the user.
    DeleteUser(u64),
    /// One `ADD_RECORDS` insert, `ON CONFLICT DO NOTHING`.
    InsertRecord(StoreRow),
    /// `DELETE_STORE_BY_USER`
    DeleteStore(u64),
}

/// One `(host, tag, MAX(idx))` row of `STATUS`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StatusPoint {
    pub host: u128,
    pub tag: Bytes,
    pub idx: u64,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Reply {
    /// `UserResponse` / `MeResponse`: `{"username"}`.
    Username(Bytes),
    /// `RegisterResponse` / `LoginResponse`: `{"session", "auth": "cli"}`.
    Session(Bytes),
    /// `DeleteUserResponse` / `ChangePasswordResponse`: `{}`.
    Empty,
    /// `()`: 200 with an empty body.
    Unit,
    /// `RecordStatus`.
    Status(Vec<StatusPoint>),
    /// `Vec<Record<EncryptedData>>`.
    Records(Vec<StoreRow>),
}

/// Each refusal is one `ErrorResponse` reason with its status.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    /// 400 "missing authorization header"
    MissingAuthorization,
    /// 400 "invalid authorization header encoding"
    InvalidAuthorization,
    /// 403 "session not found"
    SessionNotFound,
    /// 404 "user not found"
    UserNotFound,
    /// 400 "this server is not open for registrations"
    RegistrationClosed,
    /// 400 "Only alphanumeric and hyphens (-) are allowed in usernames"
    InvalidUsername,
    /// 400 "failed to register user": `add_user_with_session` hit a constraint.
    RegisterFailed,
    /// 401 "password is not correct"
    WrongPassword,
    /// 500 "failed to change user password": the new hash is another user's.
    ChangePasswordFailed,
    /// 400 "could not add records; record too large"
    RecordTooLarge,
    /// An AUTOINCREMENT counter is exhausted (SQLite would fail the insert).
    Overflow,
}

pub type Outcome = Result<(Vec<Write>, Reply), Error>;

// ---------------------------------------------------------------- bytes

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

/// SQLite's `LOWER` without ICU: ASCII letters only.
pub fn ascii_lower(b: u8) -> u8 {
    if b >= b'A' && b <= b'Z' { b + 32 } else { b }
}

/// `LOWER(a) = LOWER(b)`.
pub fn eq_lower(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut i = 0;
    while i < a.len() {
        if ascii_lower(a[i]) != ascii_lower(b[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `c.is_ascii_alphanumeric() || c == '-'`.
pub fn is_name_char(c: u8) -> bool {
    if c >= b'a' && c <= b'z' {
        true
    } else if c >= b'A' && c <= b'Z' {
        true
    } else if c >= b'0' && c <= b'9' {
        true
    } else {
        c == b'-'
    }
}

/// `models.rs` `NewUsername::from_str`: non-empty, every char an ASCII
/// letter, digit or `-`. On UTF-8 bytes this is the same test: every byte of
/// a non-ASCII char is >= 0x80.
pub fn valid_username(u: &[u8]) -> bool {
    if u.len() == 0 {
        return false;
    }
    let mut i = 0;
    while i < u.len() {
        if !is_name_char(u[i]) {
            return false;
        }
        i += 1;
    }
    true
}

// ---------------------------------------------------------------- auth

/// `HeaderValue::to_str` succeeds: every byte is visible ASCII or a tab.
pub fn header_is_ascii(v: &[u8]) -> bool {
    let mut i = 0;
    while i < v.len() {
        let c = v[i];
        if !(c == b'\t' || (c >= 32 && c < 127)) {
            return false;
        }
        i += 1;
    }
    true
}

/// The index of the first space, as `split_once(' ')`.
pub fn first_space(v: &[u8]) -> Option<usize> {
    let mut i = 0;
    while i < v.len() {
        if v[i] == b' ' {
            return Some(i);
        }
        i += 1;
    }
    None
}

fn copy_from(v: &[u8], start: usize) -> Bytes {
    let mut out = Vec::new();
    let mut i = start;
    while i < v.len() {
        out.push(v[i]);
        i += 1;
    }
    out
}

/// `typ == "Token"` for `typ = v[..n]`.
fn is_token_scheme(v: &[u8], n: usize) -> bool {
    n == 5 && v[0] == b'T' && v[1] == b'o' && v[2] == b'k' && v[3] == b'e' && v[4] == b'n'
}

/// The header checks of `router.rs` `UserAuth::from_request_parts`: the
/// session token the header presents.
pub fn parse_authorization(h: &Option<Bytes>) -> Result<Bytes, Error> {
    match h {
        None => Err(Error::MissingAuthorization),
        Some(v) => {
            if !header_is_ascii(v) {
                Err(Error::InvalidAuthorization)
            } else {
                match first_space(v) {
                    None => Err(Error::InvalidAuthorization),
                    Some(n) => {
                        if is_token_scheme(v, n) {
                            Ok(copy_from(v, n + 1))
                        } else {
                            Err(Error::InvalidAuthorization)
                        }
                    }
                }
            }
        }
    }
}

pub fn find_session_by_token(ss: &Vec<Session>, token: &[u8]) -> Option<Session> {
    let mut i = 0;
    while i < ss.len() {
        if bytes_eq(&ss[i].token, token) {
            return Some(ss[i].clone());
        }
        i += 1;
    }
    None
}

pub fn find_session_by_user(ss: &Vec<Session>, user_id: u64) -> Option<Session> {
    let mut i = 0;
    while i < ss.len() {
        if ss[i].user_id == user_id {
            return Some(ss[i].clone());
        }
        i += 1;
    }
    None
}

pub fn find_user_by_id(us: &Vec<User>, id: u64) -> Option<User> {
    let mut i = 0;
    while i < us.len() {
        if us[i].id == id {
            return Some(us[i].clone());
        }
        i += 1;
    }
    None
}

/// `GET_USER`: `WHERE username = $1` (BINARY collation).
pub fn find_user_by_name(us: &Vec<User>, name: &[u8]) -> Option<User> {
    let mut i = 0;
    while i < us.len() {
        if bytes_eq(&us[i].username, name) {
            return Some(us[i].clone());
        }
        i += 1;
    }
    None
}

/// `GET_SESSION_USER`: the user joined to the session holding `token`.
pub fn session_user(s: &Snapshot, token: &[u8]) -> Option<User> {
    match find_session_by_token(&s.sessions, token) {
        None => None,
        Some(sess) => find_user_by_id(&s.users, sess.user_id),
    }
}

/// `UserAuth::from_request_parts`.
pub fn authenticate(s: &Snapshot, h: &Option<Bytes>) -> Result<User, Error> {
    match parse_authorization(h) {
        Err(e) => Err(e),
        Ok(token) => match session_user(s, &token) {
            None => Err(Error::SessionNotFound),
            Some(u) => Ok(u),
        },
    }
}

/// `HashedPassword::verify`, by the table.
pub fn verify(c: &Crypto, hash: &[u8], password: &[u8]) -> bool {
    let mut i = 0;
    while i < c.verified.len() {
        if bytes_eq(&c.verified[i].hash, hash) && bytes_eq(&c.verified[i].password, password) {
            return true;
        }
        i += 1;
    }
    false
}

// ---------------------------------------------------------------- accounts

/// The `users` constraints `ADD_USER` can hit: `UNIQUE(username)`,
/// `UNIQUE(email)`, `UNIQUE(password)` and the `LOWER(...)` unique indexes.
pub fn user_conflict(us: &Vec<User>, username: &[u8], email: &[u8], hash: &[u8]) -> bool {
    let mut i = 0;
    while i < us.len() {
        if eq_lower(&us[i].username, username) || eq_lower(&us[i].email, email) || bytes_eq(&us[i].password, hash) {
            return true;
        }
        i += 1;
    }
    false
}

/// `sessions.token UNIQUE`.
pub fn token_taken(ss: &Vec<Session>, token: &[u8]) -> bool {
    let mut i = 0;
    while i < ss.len() {
        if bytes_eq(&ss[i].token, token) {
            return true;
        }
        i += 1;
    }
    false
}

/// `UNIQUE(password)` against every user but `id`.
pub fn hash_taken_by_other(us: &Vec<User>, id: u64, hash: &[u8]) -> bool {
    let mut i = 0;
    while i < us.len() {
        if us[i].id != id && bytes_eq(&us[i].password, hash) {
            return true;
        }
        i += 1;
    }
    false
}

/// `handlers/user.rs` `register`.
pub fn register(cfg: &Config, s: &Snapshot, username: &Bytes, email: &Bytes, new_hash: &Bytes, token: &Bytes) -> Outcome {
    if !cfg.open_registration {
        return Err(Error::RegistrationClosed);
    }
    if !valid_username(username) {
        return Err(Error::InvalidUsername);
    }
    if user_conflict(&s.users, username, email, new_hash) || token_taken(&s.sessions, token) {
        return Err(Error::RegisterFailed);
    }
    if s.next_user_id == u64::MAX || s.next_session_id == u64::MAX {
        return Err(Error::Overflow);
    }
    let user = User { id: s.next_user_id, username: username.clone(), email: email.clone(), password: new_hash.clone() };
    let session = Session { id: s.next_session_id, user_id: s.next_user_id, token: token.clone() };
    let mut ws = Vec::new();
    ws.push(Write::AddUser(user));
    ws.push(Write::AddSession(session));
    Ok((ws, Reply::Session(token.clone())))
}

/// `handlers/user.rs` `login`: the user, then their session, then the password.
pub fn login(c: &Crypto, s: &Snapshot, username: &Bytes, password: &Bytes) -> Outcome {
    match find_user_by_name(&s.users, username) {
        None => Err(Error::UserNotFound),
        Some(u) => match find_session_by_user(&s.sessions, u.id) {
            None => Err(Error::UserNotFound),
            Some(sess) => {
                if verify(c, &u.password, password) {
                    Ok((Vec::new(), Reply::Session(sess.token)))
                } else {
                    Err(Error::WrongPassword)
                }
            }
        },
    }
}

/// `handlers/user.rs` `get`.
pub fn get_user(s: &Snapshot, username: &Bytes) -> Outcome {
    match find_user_by_name(&s.users, username) {
        None => Err(Error::UserNotFound),
        Some(u) => Ok((Vec::new(), Reply::Username(u.username))),
    }
}

/// `handlers/user.rs` `delete`.
pub fn delete_account(c: &Crypto, u: &User, password: &Bytes) -> Outcome {
    if !verify(c, &u.password, password) {
        return Err(Error::WrongPassword);
    }
    let mut ws = Vec::new();
    ws.push(Write::DeleteUser(u.id));
    Ok((ws, Reply::Empty))
}

/// `handlers/user.rs` `change_password`.
pub fn change_password(c: &Crypto, s: &Snapshot, u: &User, current: &Bytes, new_hash: &Bytes) -> Outcome {
    if !verify(c, &u.password, current) {
        return Err(Error::WrongPassword);
    }
    if hash_taken_by_other(&s.users, u.id, new_hash) {
        return Err(Error::ChangePasswordFailed);
    }
    let mut ws = Vec::new();
    ws.push(Write::SetPassword { user_id: u.id, hash: new_hash.clone() });
    Ok((ws, Reply::Empty))
}

// ---------------------------------------------------------------- records

/// `handlers/v0/record.rs` `post`: `len <= max || max == 0` for every record.
pub fn records_fit(rs: &Vec<RecordIn>, max: u64) -> bool {
    let mut i = 0;
    while i < rs.len() {
        if !((rs[i].data.len() as u64) <= max || max == 0) {
            return false;
        }
        i += 1;
    }
    true
}

pub fn to_row(user_id: u64, r: &RecordIn) -> StoreRow {
    StoreRow {
        user_id,
        client_id: r.client_id,
        host: r.host,
        idx: r.idx,
        timestamp: r.timestamp,
        version: r.version.clone(),
        tag: r.tag.clone(),
        data: r.data.clone(),
        cek: r.cek.clone(),
    }
}

fn record_writes(user_id: u64, rs: &Vec<RecordIn>) -> Vec<Write> {
    let mut ws = Vec::new();
    let mut i = 0;
    while i < rs.len() {
        ws.push(Write::InsertRecord(to_row(user_id, &rs[i])));
        i += 1;
    }
    ws
}

/// `post`: reject the batch if one record is too large, else insert each.
pub fn post_records(cfg: &Config, u: &User, rs: &Vec<RecordIn>) -> Outcome {
    if !records_fit(rs, cfg.max_record_size) {
        return Err(Error::RecordTooLarge);
    }
    Ok((record_writes(u.id, rs), Reply::Unit))
}

/// The backend binds `idx` as `i64::conv(idx)`, which in a release build is
/// `idx as i64`; SQLite then orders by the signed value. Flipping the top
/// bit maps that signed order onto `u64`'s order.
pub fn signed_key(x: u64) -> u64 {
    x ^ 0x8000_0000_0000_0000
}

/// Whether `r` is in the series `NEXT_RECORDS` reads, at or after `start`.
pub fn in_series(r: &StoreRow, user_id: u64, host: u128, tag: &[u8], start: u64) -> bool {
    r.user_id == user_id && bytes_eq(&r.tag, tag) && r.host == host && signed_key(r.idx) >= signed_key(start)
}

/// `out` sorted by `signed_key(idx)`, with `r` put after every row whose key
/// is not greater.
pub fn insert_sorted(out: &Vec<StoreRow>, r: &StoreRow) -> Vec<StoreRow> {
    let mut res = Vec::new();
    let mut placed = false;
    let mut i = 0;
    while i < out.len() {
        if !placed && signed_key(r.idx) < signed_key(out[i].idx) {
            res.push(r.clone());
            placed = true;
        }
        res.push(out[i].clone());
        i += 1;
    }
    if !placed {
        res.push(r.clone());
    }
    res
}

/// The first `n` rows.
pub fn take(v: &Vec<StoreRow>, n: u64) -> Vec<StoreRow> {
    let mut res = Vec::new();
    let mut i = 0;
    while i < v.len() && (i as u64) < n {
        res.push(v[i].clone());
        i += 1;
    }
    res
}

/// `NEXT_RECORDS`: `WHERE user_id = $1 AND tag = $2 AND host = $3 AND idx >= $4
/// ORDER BY idx ASC LIMIT $5`, with `start` defaulting to 0. A `count` above
/// `i64::MAX` binds as a negative limit, which SQLite reads as no limit.
pub fn next_records(s: &Snapshot, user_id: u64, host: u128, tag: &Bytes, start: Option<u64>, count: u64) -> Vec<StoreRow> {
    let st = match start {
        None => 0,
        Some(x) => x,
    };
    let mut sorted = Vec::new();
    let mut i = 0;
    while i < s.store.len() {
        if in_series(&s.store[i], user_id, host, tag, st) {
            sorted = insert_sorted(&sorted, &s.store[i]);
        }
        i += 1;
    }
    if count > 0x7fff_ffff_ffff_ffff {
        sorted
    } else {
        take(&sorted, count)
    }
}

/// Fold one row into the `(host, tag)` maxima.
pub fn bump(ps: &Vec<StatusPoint>, r: &StoreRow) -> Vec<StatusPoint> {
    let mut res = Vec::new();
    let mut found = false;
    let mut i = 0;
    while i < ps.len() {
        if ps[i].host == r.host && bytes_eq(&ps[i].tag, &r.tag) {
            found = true;
            if signed_key(r.idx) > signed_key(ps[i].idx) {
                res.push(StatusPoint { host: r.host, tag: r.tag.clone(), idx: r.idx });
            } else {
                res.push(ps[i].clone());
            }
        } else {
            res.push(ps[i].clone());
        }
        i += 1;
    }
    if !found {
        res.push(StatusPoint { host: r.host, tag: r.tag.clone(), idx: r.idx });
    }
    res
}

/// `STATUS`: `SELECT host, tag, MAX(idx) FROM store WHERE user_id = $1 GROUP BY host, tag`.
pub fn status(s: &Snapshot, user_id: u64) -> Vec<StatusPoint> {
    let mut ps = Vec::new();
    let mut i = 0;
    while i < s.store.len() {
        if s.store[i].user_id == user_id {
            ps = bump(&ps, &s.store[i]);
        }
        i += 1;
    }
    ps
}

/// The handlers behind `UserAuth`, once it has found `u`.
pub fn authed(cfg: &Config, c: &Crypto, s: &Snapshot, u: &User, cmd: &Command) -> Outcome {
    match cmd {
        Command::Me => Ok((Vec::new(), Reply::Username(u.username.clone()))),
        Command::DeleteAccount { password } => delete_account(c, u, password),
        Command::ChangePassword { current_password, new_hash } => change_password(c, s, u, current_password, new_hash),
        Command::PostRecords { records } => post_records(cfg, u, records),
        Command::Status => Ok((Vec::new(), Reply::Status(status(s, u.id)))),
        Command::Next { host, tag, start, count } => Ok((Vec::new(), Reply::Records(next_records(s, u.id, *host, tag, *start, *count)))),
        Command::DeleteStore => {
            let mut ws = Vec::new();
            ws.push(Write::DeleteStore(u.id));
            Ok((ws, Reply::Unit))
        }
        // Unauthenticated routes never reach here.
        Command::GetUser { username: _ } => Err(Error::UserNotFound),
        Command::Register { username: _, email: _, new_hash: _, token: _ } => Err(Error::RegistrationClosed),
        Command::Login { username: _, password: _ } => Err(Error::UserNotFound),
    }
}

/// Whether the route takes `UserAuth`.
pub fn needs_auth(cmd: &Command) -> bool {
    match cmd {
        Command::GetUser { username: _ } => false,
        Command::Register { username: _, email: _, new_hash: _, token: _ } => false,
        Command::Login { username: _, password: _ } => false,
        _ => true,
    }
}

/// One request: the writes it commits and its reply, or the refusal (which
/// commits nothing).
pub fn transition(cfg: &Config, c: &Crypto, s: &Snapshot, req: &Request) -> Outcome {
    match &req.command {
        Command::GetUser { username } => get_user(s, username),
        Command::Register { username, email, new_hash, token } => register(cfg, s, username, email, new_hash, token),
        Command::Login { username, password } => login(c, s, username, password),
        _ => match authenticate(s, &req.authorization) {
            Err(e) => Err(e),
            Ok(u) => authed(cfg, c, s, &u, &req.command),
        },
    }
}

// ---------------------------------------------------------------- apply

fn without_user_sessions(v: &Vec<Session>, id: u64) -> Vec<Session> {
    let mut res = Vec::new();
    let mut i = 0;
    while i < v.len() {
        if v[i].user_id != id {
            res.push(v[i].clone());
        }
        i += 1;
    }
    res
}

fn without_user_history(v: &Vec<HistoryRow>, id: u64) -> Vec<HistoryRow> {
    let mut res = Vec::new();
    let mut i = 0;
    while i < v.len() {
        if v[i].user_id != id {
            res.push(v[i]);
        }
        i += 1;
    }
    res
}

pub fn without_user_store(v: &Vec<StoreRow>, id: u64) -> Vec<StoreRow> {
    let mut res = Vec::new();
    let mut i = 0;
    while i < v.len() {
        if v[i].user_id != id {
            res.push(v[i].clone());
        }
        i += 1;
    }
    res
}

fn without_user(v: &Vec<User>, id: u64) -> Vec<User> {
    let mut res = Vec::new();
    let mut i = 0;
    while i < v.len() {
        if v[i].id != id {
            res.push(v[i].clone());
        }
        i += 1;
    }
    res
}

fn with_password(v: &Vec<User>, id: u64, hash: &Bytes) -> Vec<User> {
    let mut res = Vec::new();
    let mut i = 0;
    while i < v.len() {
        if v[i].id == id {
            res.push(User { id: v[i].id, username: v[i].username.clone(), email: v[i].email.clone(), password: hash.clone() });
        } else {
            res.push(v[i].clone());
        }
        i += 1;
    }
    res
}

/// `record_uniq ON store(user_id, host, tag, idx)`.
pub fn store_conflict(v: &Vec<StoreRow>, r: &StoreRow) -> bool {
    let mut i = 0;
    while i < v.len() {
        if v[i].user_id == r.user_id && v[i].host == r.host && bytes_eq(&v[i].tag, &r.tag) && v[i].idx == r.idx {
            return true;
        }
        i += 1;
    }
    false
}

fn push_user(v: &Vec<User>, u: &User) -> Vec<User> {
    let mut res = v.clone();
    res.push(u.clone());
    res
}

fn push_session(v: &Vec<Session>, x: &Session) -> Vec<Session> {
    let mut res = v.clone();
    res.push(x.clone());
    res
}

fn push_row(v: &Vec<StoreRow>, r: &StoreRow) -> Vec<StoreRow> {
    let mut res = v.clone();
    res.push(r.clone());
    res
}

/// What one write does to the tables.
pub fn apply_write(s: &Snapshot, w: &Write) -> Snapshot {
    match w {
        Write::AddUser(u) => Snapshot {
            users: push_user(&s.users, u),
            sessions: s.sessions.clone(),
            history: s.history.clone(),
            store: s.store.clone(),
            next_user_id: if u.id >= s.next_user_id && u.id < u64::MAX { u.id + 1 } else { s.next_user_id },
            next_session_id: s.next_session_id,
        },
        Write::AddSession(x) => Snapshot {
            users: s.users.clone(),
            sessions: push_session(&s.sessions, x),
            history: s.history.clone(),
            store: s.store.clone(),
            next_user_id: s.next_user_id,
            next_session_id: if x.id >= s.next_session_id && x.id < u64::MAX { x.id + 1 } else { s.next_session_id },
        },
        Write::SetPassword { user_id, hash } => Snapshot {
            users: with_password(&s.users, *user_id, hash),
            sessions: s.sessions.clone(),
            history: s.history.clone(),
            store: s.store.clone(),
            next_user_id: s.next_user_id,
            next_session_id: s.next_session_id,
        },
        Write::DeleteUser(id) => Snapshot {
            users: without_user(&s.users, *id),
            sessions: without_user_sessions(&s.sessions, *id),
            history: without_user_history(&s.history, *id),
            store: without_user_store(&s.store, *id),
            next_user_id: s.next_user_id,
            next_session_id: s.next_session_id,
        },
        Write::InsertRecord(r) => Snapshot {
            users: s.users.clone(),
            sessions: s.sessions.clone(),
            history: s.history.clone(),
            store: if store_conflict(&s.store, r) { s.store.clone() } else { push_row(&s.store, r) },
            next_user_id: s.next_user_id,
            next_session_id: s.next_session_id,
        },
        Write::DeleteStore(id) => Snapshot {
            users: s.users.clone(),
            sessions: s.sessions.clone(),
            history: s.history.clone(),
            store: without_user_store(&s.store, *id),
            next_user_id: s.next_user_id,
            next_session_id: s.next_session_id,
        },
    }
}

/// Commit a write set, in order (one transaction).
pub fn apply(s: &Snapshot, ws: &Vec<Write>) -> Snapshot {
    let mut cur = s.clone();
    let mut i = 0;
    while i < ws.len() {
        cur = apply_write(&cur, &ws[i]);
        i += 1;
    }
    cur
}
