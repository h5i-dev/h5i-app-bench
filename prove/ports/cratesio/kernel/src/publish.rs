//! `src/controllers/krate/publish.rs` `publish`: who may publish a version,
//! up to the ownership check after the crate row is written; and
//! `crates/crates_io_trustpub/src/access_token.rs` `AccessToken::from_str`.
//!
//! Inputs are the crate row found by name before authentication (`existing`)
//! and the owners of the crate row the insert-or-update lands on
//! (`owners_at_write`: `None` when this publish created the crate, which
//! makes the user its owner). The two can differ when another publish
//! creates the crate in between; upstream's comment accepts that the endpoint
//! scope may then be `publish-new`.

use crate::auth::{AuthCheck, AuthError, Authentication, Request, User, check, parse_auth_header};
use crate::bytes::{eq, is_alnum, starts_with, sub};
use crate::rights::{Actor, Owner, RightsError, rank, rights};
use crate::scopes::EndpointScope;

/// The crate row `Crate::by_name` found.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Crate {
    pub id: i32,
    pub trustpub_only: bool,
}

/// A `trustpub_tokens` row; `raw` is the plaintext the stored SHA-256 was
/// computed from.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct TrustpubToken {
    pub raw: Vec<u8>,
    pub expires_at: i64,
    pub crate_ids: Vec<Option<i32>>,
}

/// Why a publish is refused.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum PublishError {
    /// `401` from parsing the `Authorization` header.
    Header(AuthError),
    /// `401`: a `cio_tp_` token that does not parse.
    TrustpubParse,
    /// `403`: Trusted Publishing cannot create crates.
    TrustpubNewCrate,
    /// `403`: no unexpired Trusted Publishing token with this secret.
    TrustpubInvalid,
    /// `403`: the token is not valid for this crate.
    TrustpubWrongCrate,
    /// `AuthCheck::check` refused.
    Auth(AuthError),
    /// `403`: the crate only accepts Trusted Publishing.
    TrustpubOnly,
    /// `Rights::get` failed.
    Rights(RightsError),
    /// `403`: the user is not an owner (nor a member of an owning team).
    NotOwner,
}

/// Who publishes.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Publisher {
    /// A Trusted Publishing token, for this crate id.
    TrustPub(i32),
    /// A user, authenticated by cookie or API token.
    User(i32),
}

/// `AccessToken::PREFIX`, `"cio_tp_"`.
pub const TP_PREFIX: [u8; 7] = [b'c', b'i', b'o', b'_', b't', b'p', b'_'];

/// `checksum`'s alphabet.
pub const CHECKSUM_ALPHABET: [u8; 62] = [
    b'A', b'B', b'C', b'D', b'E', b'F', b'G', b'H', b'I', b'J', b'K', b'L', b'M', b'N', b'O', b'P',
    b'Q', b'R', b'S', b'T', b'U', b'V', b'W', b'X', b'Y', b'Z', b'a', b'b', b'c', b'd', b'e', b'f',
    b'g', b'h', b'i', b'j', b'k', b'l', b'm', b'n', b'o', b'p', b'q', b'r', b's', b't', b'u', b'v',
    b'w', b'x', b'y', b'z', b'0', b'1', b'2', b'3', b'4', b'5', b'6', b'7', b'8', b'9',
];

/// `checksum`: the xor of the bytes, as a character of the alphabet.
pub fn checksum(raw: &[u8]) -> u8 {
    let mut acc: u8 = 0;
    let mut i = 0;
    while i < raw.len() {
        acc = acc ^ raw[i];
        i += 1;
    }
    CHECKSUM_ALPHABET[(acc as usize) % 62]
}

/// `suffix.chars().all(char::is_ascii_alphanumeric)`.
pub fn all_alnum(s: &[u8]) -> bool {
    let mut i = 0;
    while i < s.len() {
        if !is_alnum(s[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `AccessToken::from_str`: the prefix, then 31 alphanumerics and their
/// checksum. Returns the raw part.
pub fn parse_access_token(s: &[u8]) -> Option<Vec<u8>> {
    if !starts_with(s, &TP_PREFIX) {
        return None;
    }
    let suffix = sub(s, 7, s.len());
    if suffix.len() != 32 {
        return None;
    }
    if !all_alnum(&suffix) {
        return None;
    }
    let raw = sub(&suffix, 0, 31);
    if checksum(&raw) != suffix[31] {
        return None;
    }
    Some(raw)
}

/// The `trustpub_tokens` query: an unexpired row with this raw token, its
/// crate ids.
pub fn find_tp_token(tokens: &Vec<TrustpubToken>, raw: &[u8], now: i64) -> Option<usize> {
    let mut i = 0;
    while i < tokens.len() {
        if tokens[i].expires_at > now && eq(&tokens[i].raw, raw) {
            return Some(i);
        }
        i += 1;
    }
    None
}

/// `o == Some(id)`.
pub fn is_id(o: Option<i32>, id: i32) -> bool {
    match o {
        Some(x) => x == id,
        None => false,
    }
}

/// `crate_ids.contains(&Some(id))`.
pub fn has_crate(ids: &[Option<i32>], id: i32) -> bool {
    let mut i = 0;
    while i < ids.len() {
        if is_id(ids[i], id) {
            return true;
        }
        i += 1;
    }
    false
}

/// The Trusted Publishing branch, for a header token with the `cio_tp_`
/// prefix.
pub fn trustpub_auth(existing: &Option<Crate>, tp_tokens: &Vec<TrustpubToken>, token: &[u8], now: i64) -> Result<Publisher, PublishError> {
    let raw = match parse_access_token(token) {
        None => return Err(PublishError::TrustpubParse),
        Some(r) => r,
    };
    let krate = match existing {
        None => return Err(PublishError::TrustpubNewCrate),
        Some(k) => k,
    };
    let ti = match find_tp_token(tp_tokens, &raw, now) {
        None => return Err(PublishError::TrustpubInvalid),
        Some(i) => i,
    };
    if !has_crate(&tp_tokens[ti].crate_ids, krate.id) {
        return Err(PublishError::TrustpubWrongCrate);
    }
    Ok(Publisher::TrustPub(krate.id))
}

/// The user of an authentication.
pub fn auth_user(a: &Authentication) -> User {
    match a {
        Authentication::Cookie(u) => *u,
        Authentication::Token(_, u) => *u,
    }
}

/// The `AuthCheck` `publish` uses for a user: `publish-update` for an
/// existing crate, `publish-new` otherwise, and the crate's name.
pub fn publish_check(existing: &Option<Crate>, name: &[u8]) -> AuthCheck {
    let scope = match existing {
        Some(_) => EndpointScope::PublishUpdate,
        None => EndpointScope::PublishNew,
    };
    AuthCheck {
        allow_token: true,
        endpoint_scope: Some(scope),
        crate_name: Some(sub(name, 0, name.len())),
        allow_any_crate_scope: false,
    }
}

/// The crate requires Trusted Publishing.
pub fn trustpub_only(existing: &Option<Crate>) -> bool {
    match existing {
        Some(k) => k.trustpub_only,
        None => false,
    }
}

/// The ownership check after the crate row is written: a crate this publish
/// created is the user's; otherwise `Rights::get` must give at least
/// `Publish`.
pub fn owner_ok(
    user_id: i32,
    owners_at_write: &Option<Vec<Owner>>,
    actor_gh: (Option<bool>, bool),
    answers: &[(i64, crate::rights::Membership)],
) -> Result<Publisher, PublishError> {
    match owners_at_write {
        None => Ok(Publisher::User(user_id)),
        Some(owners) => {
            let actor = Actor { id: user_id, gh_token: actor_gh.0, gh_login: actor_gh.1 };
            match rights(&actor, owners, answers) {
                Err(e) => Err(PublishError::Rights(e)),
                Ok(r) => {
                    if rank(r) < 1 {
                        Err(PublishError::NotOwner)
                    } else {
                        Ok(Publisher::User(user_id))
                    }
                }
            }
        }
    }
}

/// The publish of a user (cookie or API token).
#[allow(clippy::too_many_arguments)]
pub fn user_publish(
    name: &[u8],
    existing: &Option<Crate>,
    owners_at_write: &Option<Vec<Owner>>,
    allowed_origins: &[u64],
    users: &[User],
    tokens: &Vec<crate::auth::ApiToken>,
    req: &Request,
    now: i64,
    actor_gh: (Option<bool>, bool),
    answers: &[(i64, crate::rights::Membership)],
) -> Result<Publisher, PublishError> {
    let ac = publish_check(existing, name);
    let a = match check(&ac, allowed_origins, users, tokens, req, now) {
        Err(e) => return Err(PublishError::Auth(e)),
        Ok(a) => a,
    };
    if trustpub_only(existing) {
        return Err(PublishError::TrustpubOnly);
    }
    owner_ok(auth_user(&a).id, owners_at_write, actor_gh, answers)
}

/// The header token, if it is a Trusted Publishing token (`cio_tp_`).
pub fn is_tp(header_token: &Option<Vec<u8>>) -> bool {
    match header_token {
        None => false,
        Some(t) => starts_with(t, &TP_PREFIX),
    }
}

/// `publish`'s authorization, up to and including the ownership check.
#[allow(clippy::too_many_arguments)]
pub fn publish_auth(
    name: &[u8],
    existing: &Option<Crate>,
    owners_at_write: &Option<Vec<Owner>>,
    allowed_origins: &[u64],
    users: &[User],
    tokens: &Vec<crate::auth::ApiToken>,
    tp_tokens: &Vec<TrustpubToken>,
    req: &Request,
    now: i64,
    actor_gh: (Option<bool>, bool),
    answers: &[(i64, crate::rights::Membership)],
) -> Result<Publisher, PublishError> {
    match &req.authorization {
        None => user_publish(name, existing, owners_at_write, allowed_origins, users, tokens, req, now, actor_gh, answers),
        Some(h) => match parse_auth_header(h) {
            Err(e) => Err(PublishError::Header(e)),
            Ok(t) => {
                if starts_with(&t, &TP_PREFIX) {
                    trustpub_auth(existing, tp_tokens, &t, now)
                } else {
                    user_publish(name, existing, owners_at_write, allowed_origins, users, tokens, req, now, actor_gh, answers)
                }
            }
        },
    }
}
