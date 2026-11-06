//! `crates/wastebin_core/src/db.rs`: the `entries` table and the statements
//! `Handler` runs on it, and `Database::get`'s decisions around them.
//!
//! A row keeps what the decisions read. `data` and `title` stand for the
//! compressed content and the title; `secret` is `Some(k)` when the row has a
//! nonce (the paste is encrypted), `k` naming the password it was encrypted
//! with. Decryption with password `p` succeeds exactly when `p == k`: the
//! kernel assumes XChaCha20-Poly1305 under an argon2 key rejects every other
//! password (DEVIATIONS.md, "Trusted").

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

/// `can_delete` in `handlers/html/paste.rs` and `rendered.rs`: the `uid`
/// cookie (if it verified) lists the paste's owner.
pub fn can_delete(uids: &Option<Vec<i64>>, owner: Option<i64>) -> bool {
    match uids {
        None => false,
        Some(us) => match owner {
            None => false,
            Some(o) => contains_uid(us, o),
        },
    }
}
