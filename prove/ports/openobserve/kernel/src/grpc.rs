//! gRPC authentication: `api/grpc/src/handler/grpc/auth/mod.rs`
//! `check_auth_inner`, `check_internal_auth`, `auth_token`, `is_internal_token`,
//! `token_matches`, `attach_user_id`, with the caches it reads
//! (`is_root_user`, `get_cached_user_org`, `ORG_INGESTION_TOKENS`) as tables
//! keyed exactly as upstream keys them. Upstream's order is kept.
use crate::bytes::{bytes_eq, contains, starts_with};

/// The org header (`cfg.grpc.org_header_key`).
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum OrgHeader {
    Missing,
    /// Present, but `to_str()` fails.
    NotAscii,
    Value(Vec<u8>),
}

/// `http_auth_basic::Credentials::from_header(token)`, decoded by the shell.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Credentials {
    pub user_id: Vec<u8>,
    pub password: Vec<u8>,
}

/// An `ORG_USERS` row: its key `"{org}/{email}"`, role, and API token.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct OrgUserRow {
    pub key: Vec<u8>,
    pub is_root: bool,
    pub token: Vec<u8>,
}

/// A `USERS` row: its key (the lowercased email) and credentials.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct UserRow {
    pub key: Vec<u8>,
    pub email: Vec<u8>,
    pub password: Vec<u8>,
    pub salt: Vec<u8>,
}

/// The fields of `config::meta::user::User` the decision reads.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct User {
    pub email: Vec<u8>,
    pub token: Vec<u8>,
    pub password: Vec<u8>,
    pub salt: Vec<u8>,
}

/// One `try_get_hash(password, salt)` result (`None` for an empty salt).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct HashRow {
    pub password: Vec<u8>,
    pub salt: Vec<u8>,
    pub hash: Option<Vec<u8>>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct GrpcEnv {
    /// `get_internal_grpc_token()`.
    pub internal_token: Vec<u8>,
    /// The super-cluster token, when super-cluster mode is on.
    pub super_cluster_token: Option<Vec<u8>>,
    /// The keys of `ORG_INGESTION_TOKENS` (`"{org}/{token}"`).
    pub ingestion_keys: Vec<Vec<u8>>,
    pub org_users: Vec<OrgUserRow>,
    pub users: Vec<UserRow>,
    /// `ROOT_USER.get("root")`.
    pub root_user: Option<User>,
    /// The hash oracle: rows not listed hash to `None`.
    pub hashes: Vec<HashRow>,
}

/// Why a request is refused; the numbers are upstream's `[n]` tags.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Reject {
    /// `unauthenticated("No valid auth token[1]")`
    NoToken,
    /// `[2]`
    EmptyToken,
    /// `[3]`
    BadCredentials,
    /// `[4]`
    NoUser,
    /// `[5]`
    BadPassword,
    /// `[6]` (`check_internal_auth`)
    NotInternal,
    /// `invalid_argument`: no org header.
    MissingOrg,
    /// `invalid_argument`: org header not visible ASCII.
    OrgNotAscii,
    /// `invalid_argument`: the user id cannot be a metadata value.
    BadUserId,
}

/// What reaches the service: the internal identity, or a `user_id` header.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Accept {
    Internal,
    User(Vec<u8>),
}

pub const ORG_INGESTION_TOKEN_PREFIX: &[u8] = b"o2oi_";
pub const DEFAULT_ORG: &[u8] = b"default";

/// `auth_token(metadata)`: `token` is the `authorization` value when `to_str()` succeeds.
pub fn auth_token(token: &Option<Vec<u8>>) -> Result<Vec<u8>, Reject> {
    match token {
        None => Err(Reject::NoToken),
        Some(t) => {
            if t.len() == 0 {
                Err(Reject::EmptyToken)
            } else {
                Ok(t.clone())
            }
        }
    }
}

/// `token_matches(token, internal, super_cluster)`.
pub fn token_matches(token: &[u8], internal: &[u8], super_cluster: &Option<Vec<u8>>) -> bool {
    if bytes_eq(token, internal) {
        return true;
    }
    match super_cluster {
        None => false,
        Some(t) => bytes_eq(t, token),
    }
}

/// `check_internal_auth`.
pub fn check_internal_auth(env: &GrpcEnv, token: &Option<Vec<u8>>) -> Result<Accept, Reject> {
    let t = match auth_token(token) {
        Err(e) => return Err(e),
        Ok(t) => t,
    };
    if token_matches(&t, &env.internal_token, &env.super_cluster_token) {
        Ok(Accept::Internal)
    } else {
        Err(Reject::NotInternal)
    }
}

/// `a/b` as one key.
pub fn join_key(a: &[u8], b: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < a.len() {
        out.push(a[i]);
        i += 1;
    }
    out.push(b'/');
    let mut j = 0;
    while j < b.len() {
        out.push(b[j]);
        j += 1;
    }
    out
}

/// ASCII lowercase (upstream's `str::to_lowercase`; they agree on ASCII).
pub fn ascii_lower(s: &[u8]) -> Vec<u8> {
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

fn find_org_user(rows: &[OrgUserRow], key: &[u8]) -> Option<OrgUserRow> {
    let mut i = 0;
    while i < rows.len() {
        if bytes_eq(&rows[i].key, key) {
            return Some(rows[i].clone());
        }
        i += 1;
    }
    None
}

fn find_user(rows: &[UserRow], key: &[u8]) -> Option<UserRow> {
    let mut i = 0;
    while i < rows.len() {
        if bytes_eq(&rows[i].key, key) {
            return Some(rows[i].clone());
        }
        i += 1;
    }
    None
}

/// `db::user::is_root_user(user_id)`: `ORG_USERS["default/{user_id}"]` has role Root.
pub fn is_root_user(env: &GrpcEnv, user_id: &[u8]) -> bool {
    match find_org_user(&env.org_users, &join_key(DEFAULT_ORG, user_id)) {
        None => false,
        Some(r) => r.is_root,
    }
}

/// `db::org_users::get_cached_user_org(org_id, user_email)`.
pub fn get_cached_user_org(env: &GrpcEnv, org: &[u8], email: &[u8]) -> Option<User> {
    let key = ascii_lower(email);
    match find_org_user(&env.org_users, &join_key(org, &key)) {
        None => None,
        Some(ou) => match find_user(&env.users, &key) {
            None => None,
            Some(u) => Some(User { email: u.email, token: ou.token, password: u.password, salt: u.salt }),
        },
    }
}

/// `try_get_hash(password, salt)`, from the oracle table.
pub fn try_get_hash(env: &GrpcEnv, password: &[u8], salt: &[u8]) -> Option<Vec<u8>> {
    let mut i = 0;
    while i < env.hashes.len() {
        if bytes_eq(&env.hashes[i].password, password) && bytes_eq(&env.hashes[i].salt, salt) {
            return match &env.hashes[i].hash {
                None => None,
                Some(h) => Some(h.clone()),
            };
        }
        i += 1;
    }
    None
}

/// `MetadataValue::try_from(user_id)`: no control bytes but tab (it accepts bytes >= 0x80).
pub fn valid_metadata(s: &[u8]) -> bool {
    let mut i = 0;
    while i < s.len() {
        let c = s[i];
        if !((c >= 32 && c != 127) || c == 9) {
            return false;
        }
        i += 1;
    }
    true
}

/// `attach_user_id(req, user_id)`.
pub fn attach_user_id(user_id: &[u8]) -> Result<Accept, Reject> {
    if valid_metadata(user_id) {
        Ok(Accept::User(user_id.to_vec()))
    } else {
        Err(Reject::BadUserId)
    }
}

/// `check_auth_inner(req, allow_org_ingestion_token)`. `creds` is
/// `Credentials::from_header(token)` (`None` on a parse error).
pub fn check_auth_inner(
    env: &GrpcEnv,
    token: &Option<Vec<u8>>,
    org_header: &OrgHeader,
    creds: &Option<Credentials>,
    allow_org_ingestion_token: bool,
) -> Result<Accept, Reject> {
    let t = match auth_token(token) {
        Err(e) => return Err(e),
        Ok(t) => t,
    };
    if token_matches(&t, &env.internal_token, &env.super_cluster_token) {
        return Ok(Accept::Internal);
    }
    let org = match org_header {
        OrgHeader::Missing => return Err(Reject::MissingOrg),
        OrgHeader::NotAscii => return Err(Reject::OrgNotAscii),
        OrgHeader::Value(o) => o,
    };
    let c = match creds {
        None => return Err(Reject::BadCredentials),
        Some(c) => c,
    };
    if c.password.len() == 0 {
        return Err(Reject::BadPassword);
    }
    if allow_org_ingestion_token && starts_with(&c.password, ORG_INGESTION_TOKEN_PREFIX) {
        if contains(&env.ingestion_keys, &join_key(org, &c.password)) {
            return attach_user_id(&c.user_id);
        }
        return Err(Reject::BadPassword);
    }
    let user = match lookup_user(env, org, &c.user_id) {
        None => return Err(Reject::NoUser),
        Some(u) => u,
    };
    if bytes_eq(&user.token, &c.password) {
        return attach_user_id(&c.user_id);
    }
    if password_matches(env, &user, c) {
        attach_user_id(&c.user_id)
    } else {
        Err(Reject::BadPassword)
    }
}

/// The user `check_auth_inner` compares against: `ROOT_USER["root"]` for a root
/// id, else the member record of the header org.
pub fn lookup_user(env: &GrpcEnv, org: &[u8], user_id: &[u8]) -> Option<User> {
    if is_root_user(env, user_id) {
        match &env.root_user {
            None => None,
            Some(u) => Some(u.clone()),
        }
    } else {
        get_cached_user_org(env, org, user_id)
    }
}

/// `user_id.eq(&user.email) && try_get_hash(password, salt).is_some_and(|h| h == user.password)`.
pub fn password_matches(env: &GrpcEnv, user: &User, c: &Credentials) -> bool {
    if !bytes_eq(&c.user_id, &user.email) {
        return false;
    }
    match try_get_hash(env, &c.password, &user.salt) {
        None => false,
        Some(h) => bytes_eq(&h, &user.password),
    }
}
