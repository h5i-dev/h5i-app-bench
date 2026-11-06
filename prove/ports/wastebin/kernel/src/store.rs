//! `crates/wastebin_core/src/db.rs`: the `entries` table, the statements
//! `Handler` runs on it, and the decisions `Database::get` makes around them.
//!
//! A row keeps what the decisions read. `data` and `title` stand for the
//! compressed content and the title; `secret` is `Some(k)` when the row has a
//! nonce (the paste is encrypted), `k` naming the password it was encrypted
//! with. Decryption with password `p` succeeds exactly when `p == k`: the
//! kernel assumes XChaCha20-Poly1305 under an argon2 key rejects every other
//! password (DEVIATIONS.md, "Trusted"). Time is whole seconds on one clock:
//! `expires < datetime('now')` is `e < now`.

/// An `entries` row.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Row {
    /// `id INTEGER PRIMARY KEY`: `Id::to_i64`.
    pub id: i64,
    /// `uid INTEGER`, the owner; `NULL` for pastes inserted without one.
    pub uid: Option<i64>,
    /// `burn_after_reading INTEGER`, nullable.
    pub burn: Option<bool>,
    /// `nonce BLOB`: `None` for plaintext, `Some(k)` for a paste encrypted
    /// with password `k`.
    pub secret: Option<u64>,
    /// `expires TEXT`, as seconds on the same clock as `now`.
    pub expires: Option<i64>,
    /// `data BLOB`.
    pub data: u64,
    /// `title TEXT`.
    pub title: Option<u64>,
}

/// `db::Error`, the variants the decisions produce.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum DbError {
    /// `Error::Delete`: "not allowed to delete".
    Delete,
    /// `Error::NotFound`.
    NotFound,
    /// `Error::NoPassword`.
    NoPassword,
    /// `Error::Crypto(_)`: decryption failed.
    Crypto,
}

/// `read::Metadata` (`get_metadata`). `expires` is the raw column; upstream
/// shows the remaining time (`expires - now`, if positive) and never decides
/// anything on it.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Metadata {
    pub uid: Option<i64>,
    pub title: Option<u64>,
    pub expires: Option<i64>,
    pub must_be_deleted: bool,
}

/// `read::Data`: the content and its metadata.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Data {
    pub data: u64,
    pub metadata: Metadata,
}

/// `read::Entry`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Entry {
    Regular(Data),
    Burned(Data),
    Encrypted(Data),
}

/// The first row with this id (`WHERE id=?1` on the primary key).
pub fn find_row(rows: &Vec<Row>, id: i64) -> Option<Row> {
    let mut i = 0;
    while i < rows.len() {
        if rows[i].id == id {
            return Some(rows[i]);
        }
        i += 1;
    }
    None
}

/// `expires < datetime('now')`, `NULL` read as `false` (`unwrap_or(false)`).
pub fn is_expired(r: &Row, now: i64) -> bool {
    match r.expires {
        None => false,
        Some(e) => e < now,
    }
}

/// `burn_after_reading`, `NULL` read as `false`.
pub fn must_be_deleted(r: &Row) -> bool {
    match r.burn {
        None => false,
        Some(b) => b,
    }
}

/// `Handler::get_metadata`'s row mapping.
pub fn metadata_of(r: &Row) -> Metadata {
    Metadata { uid: r.uid, title: r.title, expires: r.expires, must_be_deleted: must_be_deleted(r) }
}

/// `Handler::get_metadata`: no row is `NotFound`. Expiry is not checked.
pub fn get_metadata(rows: &Vec<Row>, id: i64) -> Result<Metadata, DbError> {
    match find_row(rows, id) {
        None => Err(DbError::NotFound),
        Some(r) => Ok(metadata_of(&r)),
    }
}

/// `Handler::delete`: `DELETE FROM entries WHERE id=?1`, and whether a row
/// was affected.
pub fn delete(rows: &Vec<Row>, id: i64) -> (Vec<Row>, bool) {
    let mut out = Vec::new();
    let mut hit = false;
    let mut i = 0;
    while i < rows.len() {
        let r = rows[i];
        if r.id == id {
            hit = true;
        } else {
            out.push(r);
        }
        i += 1;
    }
    (out, hit)
}

/// `read::DatabaseEntry::decrypt`: a nonce without a password is
/// `NoPassword`; a nonce with the wrong password is `Crypto`; no nonce
/// ignores any password.
pub fn decrypt(secret: Option<u64>, password: Option<u64>) -> Result<(), DbError> {
    match secret {
        None => Ok(()),
        Some(k) => match password {
            None => Err(DbError::NoPassword),
            Some(p) => {
                if p == k {
                    Ok(())
                } else {
                    Err(DbError::Crypto)
                }
            }
        },
    }
}

/// What `Database::get` holds after reading and decrypting a row, before it
/// burns it.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Fetch {
    /// No row: `NotFound`, nothing written.
    Missing,
    /// The row is expired: it is deleted and the result is `NotFound`.
    Expired,
    /// Decryption refused the password; nothing written.
    Refused(DbError),
    /// The content, whether the row was encrypted, and whether it burns.
    Ready(Data, bool, bool),
}

/// The read half of `Database::get`: `Handler::get` (which runs
/// `get_metadata` first), the expiry check, and `decrypt`.
pub fn fetch(rows: &Vec<Row>, id: i64, now: i64, password: Option<u64>) -> Fetch {
    match find_row(rows, id) {
        None => Fetch::Missing,
        Some(r) => {
            if is_expired(&r, now) {
                Fetch::Expired
            } else {
                match decrypt(r.secret, password) {
                    Err(e) => Fetch::Refused(e),
                    Ok(()) => {
                        let mbd = must_be_deleted(&r);
                        let data = Data { data: r.data, metadata: metadata_of(&r) };
                        let encrypted = match r.secret {
                            None => false,
                            Some(_) => true,
                        };
                        Fetch::Ready(data, encrypted, mbd)
                    }
                }
            }
        }
    }
}

/// The write half of `Database::get`, run on the table as it is when the
/// burn's `DELETE` executes (another reader may have burned the paste since
/// `fetch`): a burn whose `DELETE` affects no row is `NotFound`. Encrypted
/// takes precedence over burned.
pub fn finish(rows: &Vec<Row>, id: i64, data: Data, encrypted: bool, burn: bool) -> (Vec<Row>, Result<Entry, DbError>) {
    if burn {
        let (out, hit) = delete(rows, id);
        if !hit {
            return (out, Err(DbError::NotFound));
        }
        if encrypted { (out, Ok(Entry::Encrypted(data))) } else { (out, Ok(Entry::Burned(data))) }
    } else if encrypted {
        (rows.clone(), Ok(Entry::Encrypted(data)))
    } else {
        (rows.clone(), Ok(Entry::Regular(data)))
    }
}

/// `Database::get` with no other reader in between: the table afterwards and
/// the result.
pub fn get(rows: &Vec<Row>, id: i64, now: i64, password: Option<u64>) -> (Vec<Row>, Result<Entry, DbError>) {
    match fetch(rows, id, now, password) {
        Fetch::Missing => (rows.clone(), Err(DbError::NotFound)),
        Fetch::Expired => {
            let (out, _) = delete(rows, id);
            (out, Err(DbError::NotFound))
        }
        Fetch::Refused(e) => (rows.clone(), Err(e)),
        Fetch::Ready(data, encrypted, burn) => finish(rows, id, data, encrypted, burn),
    }
}

/// `x IN (uids)`.
pub fn contains_uid(uids: &[i64], x: i64) -> bool {
    let mut i = 0;
    while i < uids.len() {
        if uids[i] == x {
            return true;
        }
        i += 1;
    }
    false
}

/// `uid IN (uids)` on a nullable column: `NULL IN (..)` is not true.
pub fn owned_by(uid: Option<i64>, uids: &[i64]) -> bool {
    match uid {
        None => false,
        Some(u) => contains_uid(uids, u),
    }
}

/// `Handler::delete_for`: `DELETE FROM entries WHERE id=? AND uid IN (..)`,
/// refused when `uids` is empty or no row is affected.
pub fn delete_for(rows: &Vec<Row>, id: i64, uids: &[i64]) -> Result<Vec<Row>, DbError> {
    if uids.len() == 0 {
        return Err(DbError::Delete);
    }
    let mut out = Vec::new();
    let mut hit = false;
    let mut i = 0;
    while i < rows.len() {
        let r = rows[i];
        if r.id == id && owned_by(r.uid, uids) {
            hit = true;
        } else {
            out.push(r);
        }
        i += 1;
    }
    if hit { Ok(out) } else { Err(DbError::Delete) }
}

/// `Handler::purge`: `DELETE FROM entries WHERE expires < datetime('now')`
/// (only `wastebin-ctl purge` runs it).
pub fn purge(rows: &Vec<Row>, now: i64) -> Vec<Row> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < rows.len() {
        let r = rows[i];
        if !is_expired(&r, now) {
            out.push(r);
        }
        i += 1;
    }
    out
}
