//! The decisions of `crates/wastebin_server/src/handlers/`: the paste and
//! rendered views (`html/paste.rs`, `html/rendered.rs`), raw and download
//! (`raw.rs`, `download.rs`), the QR page (`html/qr.rs`), deletion
//! (`delete/api.rs`, `delete/form.rs`) and the owner identity of inserts
//! (`insert/form.rs`, `insert/api.rs`, `html/paste.rs`'s `?owner=` handoff),
//! with the status codes of `errors.rs`.
//!
//! Each request is the path segment as bytes, the table, and what the
//! extractors produced: the verified `uid` cookie (`Uids`; `None` when the
//! cookie is missing or its HMAC does not verify) and the password (`None`
//! when not given). A signed owner token arrives as the uid it verified to.

use crate::ids::{decode, parse_key, to_i64};
use crate::store::{DbError, Entry, Row, contains_uid, delete_for, get, get_metadata};

/// The status codes the decisions produce (`impl From<Error> for StatusCode`).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Status {
    /// `400`: `Error::Id(_)`, `db::Error::NoPassword`.
    BadRequest,
    /// `403`: `db::Error::Delete`, decryption failure, a missing `uid` cookie.
    Forbidden,
    /// `404`: `db::Error::NotFound`.
    NotFound,
}

/// `impl From<Error> for StatusCode` on `Error::Database(_)`.
pub fn db_status(e: DbError) -> Status {
    match e {
        DbError::NotFound => Status::NotFound,
        DbError::Delete => Status::Forbidden,
        DbError::Crypto => Status::Forbidden,
        DbError::NoPassword => Status::BadRequest,
    }
}

/// `can_delete`: the verified cookie lists the paste's owner.
pub fn can_delete(uids: &Option<Vec<i64>>, owner: Option<i64>) -> bool {
    match uids {
        None => false,
        Some(us) => match owner {
            None => false,
            Some(o) => contains_uid(us, o),
        },
    }
}

/// What the paste view received besides the path.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ViewRequest {
    /// The verified uid of `?owner=<token>`, if the query carries a token
    /// that verifies.
    pub claim: Option<i64>,
    /// The form's `password`, `None` when absent or empty.
    pub password: Option<u64>,
    /// The form's `confirm_burn == "1"`.
    pub confirmed: bool,
    /// The verified `uid` cookie.
    pub uids: Option<Vec<i64>>,
    /// The cache holds this key's HTML for the view's mode.
    pub cached: bool,
}

/// A rendered paste page.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct PastePage {
    /// The content shown (from the cache when `cached`; the cache only holds
    /// what this function let it store for the same key).
    pub data: u64,
    pub title: Option<u64>,
    pub can_delete: bool,
    pub is_available: bool,
    /// `Cache-Control: no-store`.
    pub no_store: bool,
    /// The HTML is stored in the cache.
    pub cache_put: bool,
}

/// The responses of the paste view.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum View {
    /// The handoff: set the `uid` cookie to this list and redirect.
    Handoff(Vec<i64>),
    /// The burn interstitial, showing the title.
    BurnConfirmation(Option<u64>),
    /// The password form, `no-store`.
    PasswordInput,
    Paste(PastePage),
    Error(Status),
}

/// The handoff's new cookie: the old list (or none) with the claimed uid
/// appended unless already present.
pub fn handoff(uids: &Option<Vec<i64>>, claimed: i64) -> Vec<i64> {
    let mut out = Vec::new();
    match uids {
        None => {}
        Some(us) => {
            let mut i = 0;
            while i < us.len() {
                out.push(us[i]);
                i += 1;
            }
        }
    }
    if !contains_uid(&out, claimed) {
        out.push(claimed);
    }
    out
}

/// No password was given.
pub fn no_password(password: &Option<u64>) -> bool {
    match password {
        None => true,
        Some(_) => false,
    }
}

/// The page for an entry `Database::get` returned: an encrypted paste is
/// available again unless it burned, and is `no-store`; the HTML is cached
/// only for a paste that stays available and was read without a password,
/// on a cache miss.
pub fn page_of(e: Entry, req: &ViewRequest) -> PastePage {
    let (d, is_available, encrypted) = match e {
        Entry::Regular(d) => (d, true, false),
        Entry::Burned(d) => (d, false, false),
        Entry::Encrypted(d) => (d, !d.metadata.must_be_deleted, true),
    };
    PastePage {
        data: d.data,
        title: d.metadata.title,
        can_delete: can_delete(&req.uids, d.metadata.uid),
        is_available,
        no_store: encrypted,
        cache_put: !req.cached && is_available && no_password(&req.password),
    }
}

/// The paste view after the key is parsed: `get_metadata`, the burn
/// interstitial, `Database::get`.
pub fn view_id(rows: &Vec<Row>, id: i64, now: i64, req: &ViewRequest) -> (Vec<Row>, View) {
    let metadata = match get_metadata(rows, id) {
        Err(e) => return (rows.clone(), View::Error(db_status(e))),
        Ok(m) => m,
    };
    if metadata.must_be_deleted && !req.confirmed {
        return (rows.clone(), View::BurnConfirmation(metadata.title));
    }
    let (after, result) = get(rows, id, now, req.password);
    match result {
        Ok(e) => (after, View::Paste(page_of(e, req))),
        Err(DbError::NoPassword) => (after, View::PasswordInput),
        Err(e) => (after, View::Error(db_status(e))),
    }
}

/// `html::paste::get` (and `html::rendered::get`, which has no handoff):
/// the table afterwards and the response. A verified `?owner=` token is
/// handled first and touches no paste.
pub fn view(rows: &Vec<Row>, path: &[u8], now: i64, req: &ViewRequest) -> (Vec<Row>, View) {
    match req.claim {
        Some(c) => (rows.clone(), View::Handoff(handoff(&req.uids, c))),
        None => match parse_key(path) {
            Err(_) => (rows.clone(), View::Error(Status::BadRequest)),
            Ok(k) => view_id(rows, to_i64(k.id), now, req),
        },
    }
}

/// The responses of `raw::get` and `download::get`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Raw {
    /// The content and title (download's filename), and `no-store`.
    Content(u64, Option<u64>, bool),
    /// The password form, `no-store`.
    PasswordInput,
    Error(Status),
}

/// `raw::get` / `download::get` after the key is parsed.
pub fn raw_id(rows: &Vec<Row>, id: i64, now: i64, password: Option<u64>) -> (Vec<Row>, Raw) {
    let (after, result) = get(rows, id, now, password);
    match result {
        Ok(Entry::Regular(d)) => (after, Raw::Content(d.data, d.metadata.title, false)),
        Ok(Entry::Burned(d)) => (after, Raw::Content(d.data, d.metadata.title, false)),
        Ok(Entry::Encrypted(d)) => (after, Raw::Content(d.data, d.metadata.title, true)),
        Err(DbError::NoPassword) => (after, Raw::PasswordInput),
        Err(e) => (after, Raw::Error(db_status(e))),
    }
}

/// `raw::get` / `download::get`: no burn interstitial, no cache. `password`
/// is the `wastebin-password` header or the form's `password`, empty
/// strings included.
pub fn raw(rows: &Vec<Row>, path: &[u8], now: i64, password: Option<u64>) -> (Vec<Row>, Raw) {
    match parse_key(path) {
        Err(_) => (rows.clone(), Raw::Error(Status::BadRequest)),
        Ok(k) => raw_id(rows, to_i64(k.id), now, password),
    }
}

/// The QR page's metadata.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Qr {
    /// Title, raw expiry and `can_delete`.
    Page(Option<u64>, Option<i64>, bool),
    Error(Status),
}

/// `html::qr::get` after the key is parsed: only `get_metadata`.
pub fn qr_id(rows: &Vec<Row>, id: i64, uids: &Option<Vec<i64>>) -> Qr {
    match get_metadata(rows, id) {
        Err(e) => Qr::Error(db_status(e)),
        Ok(m) => Qr::Page(m.title, m.expires, can_delete(uids, m.uid)),
    }
}

/// `html::qr::get` (the QR code itself is not modeled).
pub fn qr(rows: &Vec<Row>, path: &[u8], uids: &Option<Vec<i64>>) -> Qr {
    match parse_key(path) {
        Err(_) => Qr::Error(Status::BadRequest),
        Ok(k) => qr_id(rows, to_i64(k.id), uids),
    }
}

/// `delete::api::delete` and `delete::form::delete`: the `Uids` extractor
/// rejects a request without a verified cookie with `403` before the
/// handler runs; the path is an `Id` (no extension). `Ok` is `200` (API) or
/// the redirect to `/` (form).
pub fn delete_paste(rows: &Vec<Row>, path: &[u8], uids: &Option<Vec<i64>>) -> (Vec<Row>, Result<(), Status>) {
    let us = match uids {
        None => return (rows.clone(), Err(Status::Forbidden)),
        Some(us) => us,
    };
    let id = match decode(path) {
        Err(_) => return (rows.clone(), Err(Status::BadRequest)),
        Ok(id) => id,
    };
    match delete_for(rows, to_i64(id), us) {
        Err(e) => (rows.clone(), Err(db_status(e))),
        Ok(out) => (out, Ok(())),
    }
}

/// `insert::form::post`'s owner: the first uid of the verified cookie, or
/// `fresh` (`next_uid`) appended to the list. The cookie is set to the list.
pub fn form_owner(uids: &Option<Vec<i64>>, fresh: i64) -> (i64, Vec<i64>) {
    let mut list = Vec::new();
    match uids {
        None => {}
        Some(us) => {
            let mut i = 0;
            while i < us.len() {
                list.push(us[i]);
                i += 1;
            }
        }
    }
    if list.len() > 0 {
        let primary = list[0];
        (primary, list)
    } else {
        list.push(fresh);
        (fresh, list)
    }
}

/// `insert::api::post`'s owner: the uid of a verified `owner` token, else
/// `fresh` (`next_uid`). A raw uid is never taken from the request.
pub fn api_owner(token: Option<i64>, fresh: i64) -> i64 {
    match token {
        Some(u) => u,
        None => fresh,
    }
}

/// An insert's columns, after `From<Entry> for write::Entry` (empty password
/// and title already `None`) and `expires` turned into a time by SQLite.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct NewPaste {
    pub uid: i64,
    pub burn: Option<bool>,
    pub password: Option<u64>,
    pub expires: Option<i64>,
    pub data: u64,
    pub title: Option<u64>,
}

/// The id is taken.
pub fn id_taken(rows: &Vec<Row>, id: i64) -> bool {
    let mut i = 0;
    while i < rows.len() {
        if rows[i].id == id {
            return true;
        }
        i += 1;
    }
    false
}

/// `Handler::insert`: try the random ids in order; a primary-key conflict
/// retries while `counter < 10`, so at most eleven ids are tried. The row
/// is appended under the first free id.
pub fn insert(rows: &Vec<Row>, ids: &[i64], p: &NewPaste) -> Option<(i64, Vec<Row>)> {
    let mut counter: usize = 0;
    while counter < ids.len() {
        let id = ids[counter];
        if !id_taken(rows, id) {
            let mut out = rows.clone();
            out.push(Row {
                id,
                uid: Some(p.uid),
                burn: p.burn,
                secret: p.password,
                expires: p.expires,
                data: p.data,
                title: p.title,
            });
            return Some((id, out));
        }
        if counter >= 10 {
            return None;
        }
        counter += 1;
    }
    None
}
