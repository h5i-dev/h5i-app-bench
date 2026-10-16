// Copied from getnora-io/nora @ f864a9a by extract_upstream.py. Do not edit.
// Copyright (c) 2026 The NORA Authors
// SPDX-License-Identifier: MIT

use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};
use thiserror::Error;
use uuid::Uuid;

use parking_lot::RwLock;
use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};

/// Default TTL for cached token verifications (avoids Argon2 per request).
/// Overridable per-store via [`TokenStore::with_cache_ttl`] (config
/// `auth.token_cache_ttl`) to bound the cross-replica revocation window.
const DEFAULT_CACHE_TTL: Duration = Duration::from_secs(300);

/// Cached verification result
#[derive(Clone)]
struct CachedToken {
    user: String,
    role: Role,
    expires_at: u64,
    cached_at: Instant,
}

const TOKEN_PREFIX: &str = "nra_";

/// Access role for API tokens
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
#[non_exhaustive]
pub enum Role {
    Read,
    Write,
    Admin,
}

impl std::fmt::Display for Role {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Role::Read => write!(f, "read"),
            Role::Write => write!(f, "write"),
            Role::Admin => write!(f, "admin"),
        }
    }
}

impl Role {
    pub fn can_write(&self) -> bool {
        matches!(self, Role::Write | Role::Admin)
    }

    pub fn can_admin(&self) -> bool {
        matches!(self, Role::Admin)
    }
}

/// API Token metadata stored on disk
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TokenInfo {
    pub token_hash: String,
    pub user: String,
    pub created_at: u64,
    pub expires_at: u64,
    pub last_used: Option<u64>,
    pub description: Option<String>,
    #[serde(default = "default_role")]
    pub role: Role,
}

fn default_role() -> Role {
    Role::Read
}

/// Token list entry for UI display (no hash exposed)
#[derive(Debug, Clone, Serialize)]
pub struct TokenListEntry {
    pub file_id: String,
    pub user: String,
    pub role: Role,
    pub created_at: u64,
    pub expires_at: u64,
    pub last_used: Option<u64>,
    pub description: Option<String>,
}

/// Token store for managing API tokens
#[derive(Clone)]
pub struct TokenStore {
    storage_path: PathBuf,
    /// In-memory cache: SHA256(token) -> verified result (avoids Argon2 per request)
    cache: Arc<RwLock<HashMap<String, CachedToken>>>,
    /// How long a cached verification is trusted before the slow path re-checks
    /// disk. Shorter = smaller cross-replica revocation window.
    cache_ttl: Duration,
    /// Pending last_used updates: file_id_prefix -> timestamp (flushed periodically)
    pending_last_used: Arc<RwLock<HashMap<String, u64>>>,
}

impl TokenStore {
    /// Create a new token store with the default verify-cache TTL.
    pub fn new(storage_path: &Path) -> Self {
        Self::with_cache_ttl(storage_path, DEFAULT_CACHE_TTL)
    }

    /// Create a token store with an explicit verify-cache TTL. A shorter TTL
    /// bounds the window in which a token revoked on another replica is still
    /// served from this replica's cache.
    pub fn with_cache_ttl(storage_path: &Path, cache_ttl: Duration) -> Self {
        // Ensure directory exists with restricted permissions. The serve path
        // fail-fasts on this in main.rs (#816); this is best-effort for library /
        // standalone use, but surface a diagnostic rather than swallowing the error
        // so a non-writable path is never silently broken until the first write.
        if let Err(e) = fs::create_dir_all(storage_path) {
            tracing::warn!(
                path = %storage_path.display(),
                error = %e,
                "TokenStore: could not create storage directory — token writes will fail"
            );
        }
        #[cfg(unix)]
        {
            let _ = fs::set_permissions(storage_path, fs::Permissions::from_mode(0o700));
        }
        Self {
            storage_path: storage_path.to_path_buf(),
            cache: Arc::new(RwLock::new(HashMap::new())),
            cache_ttl,
            pending_last_used: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Generate a new API token for a user
    pub fn create_token(
        &self,
        user: &str,
        ttl_days: u64,
        description: Option<String>,
        role: Role,
    ) -> Result<String, TokenError> {
        // Generate random token
        let raw_token = format!(
            "{}{}",
            TOKEN_PREFIX,
            Uuid::new_v4().to_string().replace("-", "")
        );
        let token_hash = hash_token_argon2(&raw_token)?;
        // Use SHA256 of token as filename (deterministic, for lookup)
        let file_id = sha256_hex(&raw_token);

        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        let expires_at = now + (ttl_days * 24 * 60 * 60);

        let info = TokenInfo {
            token_hash,
            user: user.to_string(),
            created_at: now,
            expires_at,
            last_used: None,
            description,
            role,
        };

        // Save to file with restricted permissions
        let file_path = self.storage_path.join(format!("{}.json", &file_id[..16]));
        let json =
            serde_json::to_string_pretty(&info).map_err(|e| TokenError::Storage(e.to_string()))?;
        write_token_file(&file_path, &json).map_err(|e| TokenError::Storage(e.to_string()))?;

        Ok(raw_token)
    }

    /// Verify a token and return user info if valid.
    ///
    /// Uses an in-memory cache to avoid Argon2 verification on every request.
    /// The `last_used` timestamp is updated in batch via `flush_last_used()`.
    pub fn verify_token(&self, token: &str) -> Result<(String, Role), TokenError> {
        if !token.starts_with(TOKEN_PREFIX) {
            return Err(TokenError::InvalidFormat);
        }

        let cache_key = sha256_hex(token);

        // Fast path: check in-memory cache
        {
            let cache = self.cache.read();
            if let Some(cached) = cache.get(&cache_key) {
                if cached.cached_at.elapsed() < self.cache_ttl {
                    let now = SystemTime::now()
                        .duration_since(UNIX_EPOCH)
                        .unwrap_or_default()
                        .as_secs();
                    if now > cached.expires_at {
                        return Err(TokenError::Expired);
                    }
                    // Schedule deferred last_used update
                    self.pending_last_used
                        .write()
                        .insert(cache_key[..16].to_string(), now);
                    return Ok((cached.user.clone(), cached.role.clone()));
                }
            }
        }

        // Slow path: read from disk and verify Argon2
        let file_path = self.storage_path.join(format!("{}.json", &cache_key[..16]));

        let content = match fs::read_to_string(&file_path) {
            Ok(c) => c,
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
                return Err(TokenError::NotFound);
            }
            Err(e) => return Err(TokenError::Storage(e.to_string())),
        };

        let mut info: TokenInfo =
            serde_json::from_str(&content).map_err(|e| TokenError::Storage(e.to_string()))?;

        // Verify hash: try Argon2id first, fall back to legacy SHA256
        let hash_valid = if info.token_hash.starts_with("$argon2") {
            verify_token_argon2(token, &info.token_hash)
        } else {
            // Legacy SHA256 hash (no salt) — verify and migrate
            let legacy_hash = sha256_hex(token);
            if info.token_hash == legacy_hash {
                // Migrate to Argon2id
                if let Ok(new_hash) = hash_token_argon2(token) {
                    info.token_hash = new_hash;
                    if let Ok(json) = serde_json::to_string_pretty(&info) {
                        let _ = write_token_file(&file_path, &json);
                    }
                }
                true
            } else {
                false
            }
        };

        if !hash_valid {
            return Err(TokenError::NotFound);
        }

        // Check expiration
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        if now > info.expires_at {
            return Err(TokenError::Expired);
        }

        // Populate cache (key must match lookup at line 180: full 64-char SHA-256 hex)
        self.cache.write().insert(
            cache_key.clone(),
            CachedToken {
                user: info.user.clone(),
                role: info.role.clone(),
                expires_at: info.expires_at,
                cached_at: Instant::now(),
            },
        );

        // Schedule deferred last_used update
        self.pending_last_used
            .write()
            .insert(cache_key[..16].to_string(), now);

        Ok((info.user, info.role))
    }

    /// List all tokens for a user (returns TokenListEntry with file_id)
    pub fn list_tokens(&self, user: &str) -> Vec<TokenListEntry> {
        self.list_all_tokens()
            .into_iter()
            .filter(|t| t.user == user)
            .collect()
    }

    /// List all tokens across all users (for admin UI)
    pub fn list_all_tokens(&self) -> Vec<TokenListEntry> {
        let mut tokens = Vec::new();

        if let Ok(entries) = fs::read_dir(&self.storage_path) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.extension().and_then(|e| e.to_str()) != Some("json") {
                    continue;
                }
                let file_id = path
                    .file_stem()
                    .and_then(|s| s.to_str())
                    .unwrap_or("")
                    .to_string();
                if file_id.is_empty() {
                    continue;
                }
                if let Ok(content) = fs::read_to_string(&path) {
                    if let Ok(info) = serde_json::from_str::<TokenInfo>(&content) {
                        tokens.push(TokenListEntry {
                            file_id,
                            user: info.user,
                            role: info.role,
                            created_at: info.created_at,
                            expires_at: info.expires_at,
                            last_used: info.last_used,
                            description: info.description,
                        });
                    }
                }
            }
        }

        tokens.sort_by_key(|t| std::cmp::Reverse(t.created_at));
        tokens
    }

    /// Flush pending last_used timestamps to disk (async to avoid blocking runtime).
    /// Called periodically by background task (every 30s).
    pub async fn flush_last_used(&self) {
        let pending: HashMap<String, u64> = {
            let mut map = self.pending_last_used.write();
            std::mem::take(&mut *map)
        };

        if pending.is_empty() {
            return;
        }

        for (file_prefix, timestamp) in &pending {
            let file_path = self.storage_path.join(format!("{}.json", file_prefix));
            let content = match tokio::fs::read_to_string(&file_path).await {
                Ok(c) => c,
                Err(_) => continue,
            };
            let mut info: TokenInfo = match serde_json::from_str(&content) {
                Ok(i) => i,
                Err(_) => continue,
            };
            info.last_used = Some(*timestamp);
            // Atomic replace (write temp + rename), NOT an in-place `fs::write`:
            // this runs every 30s for every active token while `verify_token`
            // reads the same file on its cache-miss path. An in-place write
            // truncates first, so a concurrent read can observe a torn/empty
            // file — a VALID token then 401s ("Invalid username or password")
            // until a clean read repopulates the verify cache.
            if let Ok(json) = serde_json::to_string_pretty(&info) {
                let tmp = file_path.with_extension("json.tmp");
                if tokio::fs::write(&tmp, &json).await.is_ok() {
                    set_file_permissions_600(&tmp);
                    let _ = tokio::fs::rename(&tmp, &file_path).await;
                }
            }
        }

        tracing::debug!(count = pending.len(), "Flushed pending last_used updates");
    }

    /// Remove a token from the in-memory cache (called on revoke).
    /// Cache keys are full 64-char SHA-256 hex; revoke only knows the 16-char prefix,
    /// so we must scan for matching entries.
    fn invalidate_cache(&self, hash_prefix: &str) {
        self.cache
            .write()
            .retain(|k, _| !k.starts_with(hash_prefix));
    }

    /// Revoke a token by its hash prefix.
    ///
    /// `hash_prefix` must be exactly 16 lowercase hexadecimal characters (the
    /// first 16 chars of SHA-256(token)). Anything else is rejected to prevent
    /// path-traversal attacks via crafted prefixes like `../../etc/passwd`.
    pub fn revoke_token(&self, hash_prefix: &str) -> Result<(), TokenError> {
        // SECURITY: validate format before building filesystem path
        if !is_valid_hash_prefix(hash_prefix) {
            return Err(TokenError::NotFound);
        }
        let file_path = self.storage_path.join(format!("{}.json", hash_prefix));

        // TOCTOU fix: try remove directly
        match fs::remove_file(&file_path) {
            Ok(()) => {
                self.invalidate_cache(hash_prefix);
                Ok(())
            }
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => Err(TokenError::NotFound),
            Err(e) => Err(TokenError::Storage(e.to_string())),
        }
    }

    /// Revoke all tokens for a user
    pub fn revoke_all_for_user(&self, user: &str) -> usize {
        let mut count = 0;

        if let Ok(entries) = fs::read_dir(&self.storage_path) {
            for entry in entries.flatten() {
                if let Ok(content) = fs::read_to_string(entry.path()) {
                    if let Ok(info) = serde_json::from_str::<TokenInfo>(&content) {
                        if info.user == user && fs::remove_file(entry.path()).is_ok() {
                            count += 1;
                        }
                    }
                }
            }
        }

        // Evict cached entries for this user so revoked tokens fail immediately
        if count > 0 {
            self.cache.write().retain(|_, v| v.user != user);
        }

        count
    }
}

/// Validate a hash prefix: must be exactly 16 lowercase hex characters (`[0-9a-f]`).
///
/// Token files are named `{sha256(token)[..16]}.json` (always lowercase via
/// `hex::encode`). We restrict to lowercase only to prevent case-mismatch
/// issues on case-sensitive filesystems.
fn is_valid_hash_prefix(s: &str) -> bool {
    s.len() == 16 && s.bytes().all(|b| matches!(b, b'0'..=b'9' | b'a'..=b'f'))
}

/// Hash a token using Argon2id with random salt
fn hash_token_argon2(token: &str) -> Result<String, TokenError> {
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    argon2
        .hash_password(token.as_bytes(), &salt)
        .map(|h| h.to_string())
        .map_err(|e| TokenError::Storage(format!("hash error: {e}")))
}

/// Verify a token against an Argon2id hash
fn verify_token_argon2(token: &str, hash: &str) -> bool {
    match PasswordHash::new(hash) {
        Ok(parsed) => Argon2::default()
            .verify_password(token.as_bytes(), &parsed)
            .is_ok(),
        Err(_) => false,
    }
}

/// SHA256 hex digest (used for file naming and legacy hash verification)
fn sha256_hex(input: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(input.as_bytes());
    hex::encode(hasher.finalize())
}

/// Set file permissions to 600 (owner read/write only)
fn set_file_permissions_600(path: &Path) {
    #[cfg(unix)]
    {
        let _ = fs::set_permissions(path, fs::Permissions::from_mode(0o600));
    }
}

/// Write a token file atomically: temp file in the same directory, permissions
/// fixed, then rename over the target. `verify_token` reads these files on its
/// cache-miss path while background rewrites happen, and a plain `fs::write`
/// truncates in place — a concurrent reader can observe a torn/empty file and
/// fail a valid token. Listings skip the temp name (extension is `tmp`, not
/// `json`), and `is_valid_hash_prefix` keeps it out of revoke paths.
fn write_token_file(path: &Path, json: &str) -> std::io::Result<()> {
    let tmp = path.with_extension("json.tmp");
    fs::write(&tmp, json)?;
    set_file_permissions_600(&tmp);
    fs::rename(&tmp, path)
}

#[derive(Debug, Error)]
pub enum TokenError {
    #[error("Invalid token format")]
    InvalidFormat,

    #[error("Token not found")]
    NotFound,

    #[error("Token expired")]
    Expired,

    #[error("Storage error: {0}")]
    Storage(String),
}


// Test seam appended by extract_upstream.py: seed and read the private state.
impl TokenStore {
    pub fn seed_cache(&self, key: &str, user: &str, role: Role, expires_at: u64, cached_at: Instant) {
        self.cache.write().insert(key.to_string(), CachedToken { user: user.to_string(), role, expires_at, cached_at });
    }
    pub fn cache_entries(&self) -> Vec<(String, String, Role, u64)> {
        let mut v: Vec<_> = self.cache.read().iter()
            .map(|(k, c)| (k.clone(), c.user.clone(), c.role.clone(), c.expires_at)).collect();
        v.sort_by(|a, b| a.0.cmp(&b.0));
        v
    }
    pub fn pending_entries(&self) -> Vec<(String, u64)> {
        let mut v: Vec<_> = self.pending_last_used.read().iter().map(|(k, t)| (k.clone(), *t)).collect();
        v.sort();
        v
    }
}
pub fn seam_sha256_hex(s: &str) -> String {
    sha256_hex(s)
}
pub fn seam_hash_argon2(s: &str) -> String {
    hash_token_argon2(s).expect("argon2")
}
