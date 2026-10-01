//! `tokens.rs` `TokenStore::verify_token`. The token directory is a list of
//! files; the in-memory cache a list of entries. Times: `now` in seconds
//! since the epoch (`SystemTime`), `mono` in nanoseconds (`Instant`).
use crate::oracle::{bytes_eq, Crypto};
use crate::Role;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct TokenInfo {
    pub token_hash: Vec<u8>,
    pub user: Vec<u8>,
    pub expires_at: u64,
    pub role: Role,
}

/// `{prefix}.json`; `None` when reading or parsing it fails.
#[derive(Debug, PartialEq, Eq)]
pub struct TokenFile {
    pub prefix: Vec<u8>,
    pub info: Option<TokenInfo>,
}

// By hand: Aeneas has no `Option::clone`.
impl Clone for TokenFile {
    fn clone(&self) -> TokenFile {
        let info = match &self.info {
            Some(i) => Some(i.clone()),
            None => None,
        };
        TokenFile { prefix: self.prefix.clone(), info }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct CachedToken {
    pub key: Vec<u8>,
    pub user: Vec<u8>,
    pub role: Role,
    pub expires_at: u64,
    pub cached_at: u64,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct TokenStore {
    pub files: Vec<TokenFile>,
    pub cache: Vec<CachedToken>,
    pub cache_ttl: u64,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TokenError {
    InvalidFormat,
    NotFound,
    Expired,
    Storage,
}

/// What `verify_token` changes besides its answer.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum TokenWrite {
    /// `pending_last_used[prefix] = now`.
    LastUsed(Vec<u8>, u64),
    /// A legacy SHA-256 hash rewritten as Argon2 (the new hash is random).
    Migrate(Vec<u8>),
    CacheInsert(CachedToken),
}

pub const TOKEN_PREFIX: &[u8] = b"nra_";

fn starts_with(s: &[u8], p: &[u8]) -> bool {
    if s.len() < p.len() {
        return false;
    }
    let mut i = 0;
    while i < p.len() {
        if s[i] != p[i] {
            return false;
        }
        i += 1;
    }
    true
}

/// `cache_key[..16]`.
fn prefix16(key: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < 16 && i < key.len() {
        out.push(key[i]);
        i += 1;
    }
    out
}

fn find_cached(cache: &[CachedToken], key: &[u8]) -> Option<CachedToken> {
    let mut i = 0;
    while i < cache.len() {
        if bytes_eq(&cache[i].key, key) {
            return Some(cache[i].clone());
        }
        i += 1;
    }
    None
}

fn find_file(files: &[TokenFile], prefix: &[u8]) -> Option<usize> {
    let mut i = 0;
    while i < files.len() {
        if bytes_eq(&files[i].prefix, prefix) {
            return Some(i);
        }
        i += 1;
    }
    None
}

/// `verify_token`.
pub fn verify_token(store: &TokenStore, crypto: &Crypto, token: &[u8], now: u64, mono: u64)
    -> (Vec<TokenWrite>, Result<(Vec<u8>, Role), TokenError>) {
    let mut writes = Vec::new();
    if !starts_with(token, TOKEN_PREFIX) {
        return (writes, Err(TokenError::InvalidFormat));
    }
    let cache_key = crypto.sha256_hex(token);
    if let Some(cached) = find_cached(&store.cache, &cache_key) {
        if mono.saturating_sub(cached.cached_at) < store.cache_ttl {
            if now > cached.expires_at {
                return (writes, Err(TokenError::Expired));
            }
            writes.push(TokenWrite::LastUsed(prefix16(&cache_key), now));
            return (writes, Ok((cached.user, cached.role)));
        }
    }
    let file = match find_file(&store.files, &prefix16(&cache_key)) {
        Some(f) => f,
        None => return (writes, Err(TokenError::NotFound)),
    };
    let info = match &store.files[file].info {
        Some(i) => i.clone(),
        None => return (writes, Err(TokenError::Storage)),
    };
    let hash_valid = if starts_with(&info.token_hash, b"$argon2") {
        crypto.argon2_verify(token, &info.token_hash)
    } else {
        let legacy_hash = crypto.sha256_hex(token);
        if bytes_eq(&info.token_hash, &legacy_hash) {
            writes.push(TokenWrite::Migrate(prefix16(&cache_key)));
            true
        } else {
            false
        }
    };
    if !hash_valid {
        return (writes, Err(TokenError::NotFound));
    }
    if now > info.expires_at {
        return (writes, Err(TokenError::Expired));
    }
    writes.push(TokenWrite::CacheInsert(CachedToken {
        key: cache_key.clone(),
        user: info.user.clone(),
        role: info.role,
        expires_at: info.expires_at,
        cached_at: mono,
    }));
    writes.push(TokenWrite::LastUsed(prefix16(&cache_key), now));
    (writes, Ok((info.user, info.role)))
}

/// `is_valid_hash_prefix`: exactly 16 lowercase hex digits.
pub fn is_valid_hash_prefix(s: &[u8]) -> bool {
    if s.len() != 16 {
        return false;
    }
    let mut i = 0;
    while i < s.len() {
        let b = s[i];
        if !((b >= b'0' && b <= b'9') || (b >= b'a' && b <= b'f')) {
            return false;
        }
        i += 1;
    }
    true
}

/// The files other than `{prefix}.json`.
fn remove_file(files: &[TokenFile], prefix: &[u8]) -> Vec<TokenFile> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < files.len() {
        // Clone outside the branch: Aeneas cannot join the two contexts otherwise.
        let f = files[i].clone();
        if !bytes_eq(&f.prefix, prefix) {
            out.push(f);
        }
        i += 1;
    }
    out
}

/// `invalidate_cache`: drop entries whose key starts with the prefix.
fn invalidate_cache(cache: &[CachedToken], prefix: &[u8]) -> Vec<CachedToken> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < cache.len() {
        let c = cache[i].clone();
        if !starts_with(&c.key, prefix) {
            out.push(c);
        }
        i += 1;
    }
    out
}

fn has_file(files: &[TokenFile], prefix: &[u8]) -> bool {
    let mut i = 0;
    while i < files.len() {
        if bytes_eq(&files[i].prefix, prefix) {
            return true;
        }
        i += 1;
    }
    false
}

/// `revoke_token`: the store afterwards, and the answer.
pub fn revoke_token(store: &TokenStore, hash_prefix: &[u8]) -> (TokenStore, Result<(), TokenError>) {
    if !is_valid_hash_prefix(hash_prefix) {
        return (store.clone(), Err(TokenError::NotFound));
    }
    if !has_file(&store.files, hash_prefix) {
        return (store.clone(), Err(TokenError::NotFound));
    }
    let files = remove_file(&store.files, hash_prefix);
    let cache = invalidate_cache(&store.cache, hash_prefix);
    (TokenStore { files, cache, cache_ttl: store.cache_ttl }, Ok(()))
}

/// The directory loop of `revoke_all_for_user`: files of `user` that parse
/// are removed; returns the kept files and the count.
fn remove_user_files(files: &[TokenFile], user: &[u8]) -> (Vec<TokenFile>, usize) {
    let mut kept = Vec::new();
    let mut count = 0;
    let mut i = 0;
    while i < files.len() {
        let remove = match &files[i].info {
            Some(info) => bytes_eq(&info.user, user),
            None => false,
        };
        let f = files[i].clone();
        if remove {
            count += 1;
        } else {
            kept.push(f);
        }
        i += 1;
    }
    (kept, count)
}

/// `cache.retain(|_, v| v.user != user)`.
fn evict_user(cache: &[CachedToken], user: &[u8]) -> Vec<CachedToken> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < cache.len() {
        let c = cache[i].clone();
        if !bytes_eq(&c.user, user) {
            out.push(c);
        }
        i += 1;
    }
    out
}

/// `revoke_all_for_user`.
pub fn revoke_all_for_user(store: &TokenStore, user: &[u8]) -> (TokenStore, usize) {
    let (files, count) = remove_user_files(&store.files, user);
    let cache = if count > 0 { evict_user(&store.cache, user) } else { store.cache.clone() };
    (TokenStore { files, cache, cache_ttl: store.cache_ttl }, count)
}
