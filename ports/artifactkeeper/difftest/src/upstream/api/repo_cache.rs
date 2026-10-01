// Copied from artifact-keeper/artifact-keeper @ 7c42891 by extract_upstream.py. Do not edit.
/// How long a cached repository record is considered fresh.
/// Repository metadata (visibility, type, upstream URL) rarely changes, so
/// 60 seconds is a safe balance between performance and propagation speed.
pub const REPO_CACHE_TTL_SECS: u64 = 60;
/// Cached repository metadata populated by the repo-visibility middleware
/// and reused by format-handler resolvers to avoid a second DB round-trip.
///
/// The enforcement flags (`promotion_only`, `age_gate_*`, `curation_*`) ride
/// the same entry so a cache-built [`RepoInfo`](crate::api::handlers::proxy_helpers::RepoInfo)
/// is a faithful snapshot of the `repositories` row — a resolver that served
/// defaults instead would silently fail those gates open (#3778). Writes to
/// any of these columns fire the `ak_repository_changed_notify` trigger
/// (migration 239), which evicts the entry fleet-wide; the 60-second TTL is
/// the fallback bound.
#[derive(Clone, Debug)]
pub struct CachedRepo {
    pub id: Uuid,
    pub format: String,
    pub repo_type: String,
    pub upstream_url: Option<String>,
    pub storage_path: String,
    pub storage_backend: String,
    /// Baseline read audience. Carried instead of the deprecated `is_public`
    /// mirror so a cache hit and a cache miss reach the same decision, and so
    /// that narrowing a repository from `internal` to `private` is a real
    /// change to this field -- which is what the NOTIFY trigger keys off to
    /// evict this entry across instances (migration 245).
    pub visibility: crate::models::repository::RepositoryVisibility,
    /// The `index_upstream_url` config value (cargo-specific; `None` for
    /// other formats or when not configured).
    pub index_upstream_url: Option<String>,
    pub promotion_only: bool,
    pub age_gate_enabled: bool,
    pub age_gate_min_age_days: i32,
    /// Age-source mode wire value (migration 191).
    pub age_gate_mode: String,
    pub curation_enabled: bool,
    pub curation_default_action: String,
}
/// Thread-safe in-process cache for `CachedRepo` entries, keyed by repo key.
pub type RepoCache = Arc<RwLock<HashMap<String, (CachedRepo, Instant)>>>;
/// Thread-safe in-process *negative* cache for the repo-visibility middleware:
/// repo keys that resolved to no repository row, with the instant the lookup
/// ran. Same [`REPO_CACHE_TTL_SECS`] freshness window as [`RepoCache`].
///
/// Kept as a separate map rather than a tombstone variant inside `RepoCache`
/// because `RepoCache`'s value type is read by a dozen format-handler
/// resolvers; the misses are only ever consulted by the middleware.
///
/// #3750: without it, a repeated probe of an *existing* repository the caller
/// may not see answers from `RepoCache` (~40 µs) while a repeated probe of a
/// nonexistent key re-runs the `SELECT` every time (~350 µs) — a timing oracle
/// for repository existence on every native read surface.
pub type RepoMissCache = Arc<RwLock<HashMap<String, Instant>>>;
/// Hard cap on [`RepoMissCache`] entries after TTL eviction. Every probed key
/// an attacker invents would otherwise become a map entry, so the negative
/// cache — unlike the positive one, which is bounded by the number of
/// repositories that actually exist — is attacker-growable. Past the cap the
/// whole map is dropped: the next probe of each key pays one `SELECT` again,
/// which is exactly the pre-#3750 cost, so the failure mode of the bound is
/// the old behaviour rather than unbounded memory.
pub const REPO_MISS_CACHE_MAX_ENTRIES: usize = 10_000;
