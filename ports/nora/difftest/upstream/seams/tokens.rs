
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
