// Copied from artifact-keeper/artifact-keeper @ 7c42891 by extract_upstream.py. Do not edit.
//! Permission service for fine-grained access control.
//!
//! Resolves whether a user has a specific action on a target (repository,
//! group, or artifact) by checking both direct user permissions and
//! transitive group memberships in a single query. Results are cached
//! in-process with a 30-second TTL to avoid repeated database round-trips
//! on hot paths such as artifact downloads.

use sqlx::PgPool;
use std::collections::HashMap;
use std::sync::RwLock;
use std::time::{Duration, Instant};
use tracing::{debug, error, warn};
use uuid::Uuid;

use crate::error::{AppError, Result};

/// Target type for system-wide permission checks (e.g. creating repositories or groups).
pub const SYSTEM_TARGET_TYPE: &str = "system";

/// Sentinel UUID used as the `target_id` for system-wide permission checks.
/// Operations that are not scoped to a specific entity (repository, group, etc.)
/// use this nil UUID as a conventional placeholder.
pub const SYSTEM_SENTINEL_ID: Uuid = Uuid::nil();

/// Principal type for anonymous (unauthenticated) access rules (#1849).
///
/// Anonymous rules let an operator grant READ access to a repository (or its
/// owning project) to callers presenting no credential — the CI-runner
/// use case — optionally restricted by `allowed_cidrs`. They are evaluated
/// only by [`PermissionService::check_anonymous_repository_action`]; the
/// authenticated resolvers never match them (their principal disjuncts name
/// user/group/service-account rows), and write-time validation restricts
/// them to `read` actions on `repository`/`project` targets with the nil
/// principal id.
pub const ANONYMOUS_PRINCIPAL_TYPE: &str = "anonymous";

/// Optional conditions narrowing when a permission rule applies (#1849).
///
/// Today the only condition kind is `allowed_cidrs`: the rule applies only
/// to requests whose client IP (resolved under the trusted-proxy policy,
/// see `client_ip_context_middleware`) falls inside one of the listed CIDR
/// ranges; an unknown client IP matches nothing (fail closed). The struct
/// is deliberately open to future condition kinds (artifact, version, ...)
/// without a schema change, which is why it serializes as a JSONB object —
/// but unknown keys are rejected at write time so a typo cannot silently
/// widen a rule.
///
/// # Interaction with the role-assignment fallback
///
/// Applicability is per-rule, not per-principal: when a principal's
/// conditioned rule falls out of `applicable_rules` on an IP miss, the
/// decision falls to the legacy `role_assignments` fallback, exactly as if
/// the rule did not exist for that request. So inside the CIDR the rule is
/// authoritative, while outside it the principal keeps whatever its role
/// assignments grant unconditionally. That can mean MORE access outside the
/// CIDR for a principal holding both — the documented role model, not an
/// escalation: the fallback never grants beyond the role's unconditional
/// capabilities (recorded from review finding P3, #4266). An operator who
/// wants a principal restricted to the CIDR must grant it ONLY through the
/// conditioned rule, not additionally via a role.
#[derive(
    Debug, Clone, Default, PartialEq, Eq, serde::Serialize, serde::Deserialize, utoipa::ToSchema,
)]
#[serde(deny_unknown_fields)]
pub struct PermissionConditions {
    /// CIDR ranges (IPv4 or IPv6) the request's client IP must fall inside
    /// for the rule to apply. `None` (absent) means no IP restriction.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub allowed_cidrs: Option<Vec<String>>,
}

impl PermissionConditions {
    /// Validate the condition set for writing. Every CIDR must parse; a
    /// present-but-empty `allowed_cidrs` is rejected (it would make the rule
    /// match nothing, which is almost certainly an authoring mistake).
    pub fn validate(&self) -> Result<()> {
        if let Some(cidrs) = &self.allowed_cidrs {
            if cidrs.is_empty() {
                return Err(AppError::Validation(
                    "conditions.allowed_cidrs must name at least one CIDR range".to_string(),
                ));
            }
            for cidr in cidrs {
                crate::api::middleware::rate_limit::CidrRange::parse(cidr)
                    .map_err(|e| AppError::Validation(format!("conditions.allowed_cidrs: {e}")))?;
            }
        }
        Ok(())
    }

    /// Serialize for persistence in the `conditions` JSONB column.
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::to_value(self).unwrap_or_else(|_| serde_json::json!({}))
    }
}

/// SQL predicate limiting a permission rule's applicability by the request's
/// client IP (#1849): a rule carrying `conditions.allowed_cidrs` applies
/// only when `ip_ref` (a bind like `$4` or an inet-castable SQL literal)
/// falls inside one of the listed CIDRs. A NULL `ip_ref` matches nothing
/// (fail closed). Rules without the key are unaffected.
///
/// `alias` is the `permissions` table alias in the enclosing query. The
/// generated text is interpolated unescaped, so both parameters MUST be
/// trusted fragments (bind placeholders, validated `IpAddr` literals) —
/// never request-derived text.
pub(crate) fn ip_condition_sql(alias: &str, ip_ref: &str) -> String {
    format!(
        "AND (\
             NOT ({alias}.conditions ? 'allowed_cidrs') \
             OR EXISTS ( \
                 SELECT 1 \
                 FROM jsonb_array_elements_text(\
                     {alias}.conditions->'allowed_cidrs'\
                 ) AS ak_ip_cidr(cidr) \
                 WHERE {ip_ref}::inet <<= ak_ip_cidr.cidr::inet \
             )\
         )"
    )
}

/// The current request's client IP as a SQL expression for the listing
/// fragments (#1849): a quoted `IpAddr` literal inside a request scope, or
/// `NULL` outside one (background jobs, detached tasks) — where the fail-
/// closed semantics of [`ip_condition_sql`] exclude every conditioned rule.
/// `IpAddr`'s `Display` contains only digits, dots and colons, so quoting it
/// is injection-safe.
pub(crate) fn request_ip_sql_ref() -> String {
    match crate::api::middleware::client_ip::current_client_ip() {
        Some(ip) => format!("'{ip}'"),
        None => "NULL".to_string(),
    }
}

/// How long cached permission entries remain valid before a fresh DB lookup.
const CACHE_TTL: Duration = Duration::from_secs(30);

/// Composite cache key: (user_id, target_type, target_id, client_ip).
///
/// The client IP is part of the key because `allowed_cidrs` conditions
/// (#1849) make the granted action set IP-dependent: caching a result
/// resolved under one source address and serving it to the same principal
/// arriving from another would leak the grant for the 30 s TTL.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct CacheKey {
    user_id: Uuid,
    target_type: String,
    target_id: Uuid,
    client_ip: Option<std::net::IpAddr>,
}

impl CacheKey {
    fn new(user_id: Uuid, target_type: &str, target_id: Uuid) -> Self {
        Self {
            user_id,
            target_type: target_type.to_string(),
            target_id,
            client_ip: crate::api::middleware::client_ip::current_client_ip(),
        }
    }
}

/// A cached set of granted actions together with its insertion timestamp.
#[derive(Debug, Clone)]
struct CacheEntry {
    actions: Vec<String>,
    inserted_at: Instant,
}

impl CacheEntry {
    fn is_expired(&self) -> bool {
        self.inserted_at.elapsed() > CACHE_TTL
    }
}

/// Composite key for the target rules existence cache: (target_type, target_id).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct RulesCacheKey {
    target_type: String,
    target_id: Uuid,
}

impl RulesCacheKey {
    fn new(target_type: &str, target_id: Uuid) -> Self {
        Self {
            target_type: target_type.to_string(),
            target_id,
        }
    }
}

/// A cached boolean result with an insertion timestamp.
#[derive(Debug, Clone)]
struct RulesCacheEntry {
    exists: bool,
    inserted_at: Instant,
}

impl RulesCacheEntry {
    fn is_expired(&self) -> bool {
        self.inserted_at.elapsed() > CACHE_TTL
    }
}

/// SQL that checks whether a principal of `principal_type` exists with `id = $1`,
/// or `None` when the principal type is not recognised.
///
/// Service accounts are stored in the `users` table with `is_service_account =
/// true`; human users have it `false`; groups live in the `groups` table. This
/// mapping is the single source of truth for the write-time type/id
/// correspondence check performed by [`PermissionService::validate_principal`].
fn principal_existence_query(principal_type: &str) -> Option<&'static str> {
    match principal_type {
        "user" => {
            Some("SELECT EXISTS(SELECT 1 FROM users WHERE id = $1 AND is_service_account = false)")
        }
        "service_account" => {
            Some("SELECT EXISTS(SELECT 1 FROM users WHERE id = $1 AND is_service_account = true)")
        }
        "group" => Some("SELECT EXISTS(SELECT 1 FROM groups WHERE id = $1)"),
        _ => None,
    }
}

/// Service that evaluates permission rules stored in the `permissions` table.
///
/// The service resolves both direct user grants and group-based grants in a
/// single SQL query, then caches the resulting action list per
/// (user, target_type, target_id) tuple for 30 seconds.
pub struct PermissionService {
    db: PgPool,
    cache: RwLock<HashMap<CacheKey, CacheEntry>>,
    rules_cache: RwLock<HashMap<RulesCacheKey, RulesCacheEntry>>,
}

impl PermissionService {
    pub fn new(db: PgPool) -> Self {
        Self {
            db,
            cache: RwLock::new(HashMap::new()),
            rules_cache: RwLock::new(HashMap::new()),
        }
    }

    /// Check whether `user_id` holds `action` on the given target.
    ///
    /// Admin users bypass all checks and always receive `true`. For
    /// non-admin users the service first checks the in-process cache,
    /// then falls back to a combined SQL query that resolves both direct
    /// user permissions and group-based permissions via `user_group_members`.
    pub async fn check_permission(
        &self,
        user_id: Uuid,
        target_type: &str,
        target_id: Uuid,
        action: &str,
        is_admin: bool,
    ) -> Result<bool> {
        if is_admin {
            return Ok(true);
        }

        let actions = self
            .resolve_actions(user_id, target_type, target_id)
            .await?;
        Ok(actions.iter().any(|a| a == action))
    }

    /// Check an action against repository ownership, fine-grained rules, and
    /// legacy role assignments in one decision.
    ///
    /// A role carrying `admin` is a durable owner capability and always wins.
    /// For every other principal, an applicable direct/group repository rule
    /// (or inherited project rule) is authoritative for that principal only.
    /// Users without an applicable rule retain their role-based capabilities.
    /// This principal-scoped transition prevents the first rule on a target
    /// from dropping every unrelated legacy principal to no access.
    pub async fn check_repository_action(
        &self,
        user_id: Uuid,
        repository_id: Uuid,
        action: &str,
        is_admin: bool,
    ) -> Result<bool> {
        if is_admin {
            return Ok(true);
        }
        // #1849: a rule carrying `conditions.allowed_cidrs` is applicable
        // only to requests whose client IP falls inside it. The IP is the
        // in-flight request's (`client_ip_context_middleware`); outside a
        // request scope (background jobs, detached tasks) it is None, which
        // matches nothing — conditioned grants fail closed there.
        let client_ip = crate::api::middleware::client_ip::current_client_ip();
        let query = format!(
            r#"
            WITH applicable_rules AS (
                SELECT p.actions
                FROM permissions p
                WHERE (
                    (p.principal_type IN ('user', 'service_account') AND p.principal_id = $1)
                    OR (
                        p.principal_type = 'group'
                        AND p.principal_id IN (
                            SELECT group_id
                            FROM user_group_members
                            WHERE user_id = $1
                        )
                    )
                )
                AND (
                    (p.target_type = 'repository' AND p.target_id = $2)
                    OR (
                        p.target_type = 'project'
                        AND p.target_id = (
                            SELECT project_id
                            FROM repositories
                            WHERE id = $2
                        )
                    )
                )
                {ip_condition}
            ),
            assigned_roles AS (
                SELECT r.permissions
                FROM role_assignments ra
                JOIN roles r ON r.id = ra.role_id
                WHERE ra.user_id = $1
                  AND (ra.repository_id = $2 OR ra.repository_id IS NULL)
            )
            SELECT
                EXISTS (
                    SELECT 1
                    FROM assigned_roles
                    WHERE 'admin' = ANY(permissions)
                )
                OR CASE
                    WHEN EXISTS (SELECT 1 FROM applicable_rules)
                    THEN EXISTS (
                        SELECT 1
                        FROM applicable_rules
                        WHERE $3 = ANY(actions) OR 'admin' = ANY(actions)
                    )
                    ELSE EXISTS (
                        SELECT 1
                        FROM assigned_roles
                        WHERE $3 = ANY(permissions) OR 'admin' = ANY(permissions)
                    )
                END
            "#,
            ip_condition = ip_condition_sql("p", "$4"),
        );
        let allowed: bool = sqlx::query_scalar(sqlx::AssertSqlSafe(&*query))
            .bind(user_id)
            .bind(repository_id)
            .bind(action)
            .bind(client_ip.map(|ip| ip.to_string()))
            .fetch_one(&self.db)
            .await
            .map_err(|e| AppError::Database(e.to_string()))?;

        Ok(allowed)
    }

    /// Check an action for an ANONYMOUS (unauthenticated) caller against
    /// `principal_type = 'anonymous'` rules (#1849).
    ///
    /// This is the grant behind IP-restricted anonymous downloads: an
    /// operator grants the anonymous principal `read` on a repository (or
    /// its owning project), optionally narrowed by `allowed_cidrs`, and CI
    /// runners inside those ranges can pull without credentials while every
    /// other anonymous caller keeps the existence-hiding denial. There is no
    /// role-assignment fallback (an anonymous caller holds no roles) and no
    /// admin bypass. Write-time validation confines anonymous rules to
    /// `read` on `repository`/`project` targets, and every gate only ever
    /// asks this resolver about `read`.
    ///
    /// The client IP is the in-flight request's, exactly as in
    /// [`Self::check_repository_action`]: `None` outside a request scope
    /// fails closed (conditioned rules match nothing; an unconditioned
    /// anonymous rule still applies, since it names no CIDR).
    pub async fn check_anonymous_repository_action(
        &self,
        repository_id: Uuid,
        action: &str,
    ) -> Result<bool> {
        let client_ip = crate::api::middleware::client_ip::current_client_ip();
        let query = format!(
            r#"
            SELECT EXISTS (
                SELECT 1
                FROM permissions p
                WHERE p.principal_type = 'anonymous'
                  AND (
                      (p.target_type = 'repository' AND p.target_id = $1)
                      OR (
                          p.target_type = 'project'
                          AND p.target_id = (
                              SELECT project_id
                              FROM repositories
                              WHERE id = $1
                          )
                      )
                  )
                  AND ($2 = ANY(p.actions) OR 'admin' = ANY(p.actions))
                  {ip_condition}
            )
            "#,
            ip_condition = ip_condition_sql("p", "$3"),
        );
        sqlx::query_scalar(sqlx::AssertSqlSafe(&*query))
            .bind(repository_id)
            .bind(action)
            .bind(client_ip.map(|ip| ip.to_string()))
            .fetch_one(&self.db)
            .await
            .map_err(|e| AppError::Database(e.to_string()))
    }

    /// Return true when at least one permission rule exists for the given
    /// target, regardless of principal. This is used by middleware to decide
    /// whether fine-grained rules should be enforced at all (targets without
    /// any rules fall back to the default access model).
    pub async fn has_any_rules_for_target(
        &self,
        target_type: &str,
        target_id: Uuid,
    ) -> Result<bool> {
        let key = RulesCacheKey::new(target_type, target_id);

        // Fast path: return cached result if still fresh.
        let cached = match self.rules_cache.read() {
            Ok(cache) => cache.get(&key).and_then(|entry| {
                if entry.is_expired() {
                    None
                } else {
                    debug!(
                        target_type,
                        %target_id,
                        exists = entry.exists,
                        "rules cache hit"
                    );
                    Some(entry.exists)
                }
            }),
            Err(poisoned) => {
                error!("rules cache read lock poisoned, skipping cache");
                drop(poisoned.into_inner());
                None
            }
        };

        if let Some(exists) = cached {
            return Ok(exists);
        }

        debug!(target_type, %target_id, "rules cache miss, querying database");

        // Projects (#2472): a repository target also has rules when its owning
        // project carries a grant, so the fine-grained gate engages for
        // project-only repositories instead of falling back to the default
        // access model. The `$1 = 'repository'` guard keeps every other target
        // type (group/artifact/system) unaffected, and a NULL `project_id`
        // subquery result never matches (`target_id = NULL` is not true).
        let exists: bool = sqlx::query_scalar(
            r#"SELECT EXISTS(
                 SELECT 1 FROM permissions
                 WHERE (target_type = $1 AND target_id = $2)
                    OR ($1 = 'repository' AND target_type = 'project' AND target_id = (
                        SELECT project_id FROM repositories WHERE id = $2
                    ))
               )"#,
        )
        .bind(target_type)
        .bind(target_id)
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::Database(e.to_string()))?;

        // Populate cache.
        match self.rules_cache.write() {
            Ok(mut cache) => {
                cache.retain(|_, v| !v.is_expired());
                cache.insert(
                    key,
                    RulesCacheEntry {
                        exists,
                        inserted_at: Instant::now(),
                    },
                );
            }
            Err(poisoned) => {
                error!("rules cache write lock poisoned, recovering to update cache");
                let mut cache = poisoned.into_inner();
                cache.retain(|_, v| !v.is_expired());
                cache.insert(
                    key,
                    RulesCacheEntry {
                        exists,
                        inserted_at: Instant::now(),
                    },
                );
            }
        }

        if !exists {
            warn!(target_type, %target_id, "no permission rules found for target");
        }

        Ok(exists)
    }

    /// Clear both permission caches. Call this after any CRUD operation
    /// on the `permissions` table to ensure stale grants are not served.
    pub fn invalidate_cache(&self) {
        match self.cache.write() {
            Ok(mut cache) => cache.clear(),
            Err(poisoned) => {
                error!("permission cache lock poisoned during invalidation, clearing");
                poisoned.into_inner().clear();
            }
        }
        match self.rules_cache.write() {
            Ok(mut cache) => cache.clear(),
            Err(poisoned) => {
                error!("rules cache lock poisoned during invalidation, clearing");
                poisoned.into_inner().clear();
            }
        }
    }

    /// Validate that `principal_id` names an existing principal of the declared
    /// `principal_type` before a grant is written.
    ///
    /// #2503 (defense-in-depth): since #2433 widened grant matching to include
    /// `service_account`, a mistyped grant — e.g. `principal_type =
    /// 'service_account'` naming a real *user* id — becomes effective. Principal
    /// ids are globally-unique UUIDs drawn from distinct tables (`users` for both
    /// `user` and `service_account`, disambiguated by `is_service_account`;
    /// `groups` for `group`), so a type/id mismatch is always an authoring error.
    /// Reject it at write time with a 400 rather than persisting a grant that
    /// resolves against the wrong principal.
    pub async fn validate_principal(&self, principal_type: &str, principal_id: Uuid) -> Result<()> {
        // #1849: the anonymous principal names no table row — it stands for
        // every unauthenticated caller — so existence is trivially true. The
        // nil UUID is its only valid id, keeping
        // `(principal_type, principal_id, target_type, target_id)` unique and
        // giving hand-written SQL one unambiguous spelling.
        if principal_type == ANONYMOUS_PRINCIPAL_TYPE {
            if !principal_id.is_nil() {
                return Err(AppError::Validation(format!(
                    "principal_type '{ANONYMOUS_PRINCIPAL_TYPE}' requires the nil principal_id, \
                     got {principal_id}"
                )));
            }
            return Ok(());
        }
        let query = principal_existence_query(principal_type).ok_or_else(|| {
            AppError::Validation(format!(
                "Invalid principal_type '{principal_type}': expected one of user, \
                 service_account, group, {ANONYMOUS_PRINCIPAL_TYPE}"
            ))
        })?;
        let exists: bool = sqlx::query_scalar(sqlx::AssertSqlSafe(query))
            .bind(principal_id)
            .fetch_one(&self.db)
            .await
            .map_err(|e| AppError::Database(e.to_string()))?;
        if !exists {
            return Err(AppError::Validation(format!(
                "principal_id {principal_id} does not exist as a {principal_type}"
            )));
        }
        Ok(())
    }

    /// Resolve the full set of granted actions for a user on a specific target.
    ///
    /// Checks the cache first; on miss or expiry, queries the database and
    /// populates the cache before returning.
    async fn resolve_actions(
        &self,
        user_id: Uuid,
        target_type: &str,
        target_id: Uuid,
    ) -> Result<Vec<String>> {
        let key = CacheKey::new(user_id, target_type, target_id);

        // Fast path: return cached entry if still fresh.
        let cached = match self.cache.read() {
            Ok(cache) => cache.get(&key).and_then(|entry| {
                if entry.is_expired() {
                    None
                } else {
                    debug!(
                        %user_id,
                        target_type,
                        %target_id,
                        actions = ?entry.actions,
                        "permission cache hit"
                    );
                    Some(entry.actions.clone())
                }
            }),
            Err(poisoned) => {
                error!("permission cache read lock poisoned, skipping cache");
                drop(poisoned.into_inner());
                None
            }
        };

        if let Some(actions) = cached {
            return Ok(actions);
        }

        debug!(%user_id, target_type, %target_id, "permission cache miss, querying database");

        // Cache miss or expired -- query the database.
        let actions = self.query_actions(user_id, target_type, target_id).await?;

        if actions.is_empty() {
            warn!(
                %user_id,
                target_type,
                %target_id,
                "permission denied: rules exist but no actions granted"
            );
        }

        // Populate cache. Evict stale entries while we hold the write lock
        // to keep memory bounded over time.
        match self.cache.write() {
            Ok(mut cache) => {
                cache.retain(|_, v| !v.is_expired());
                cache.insert(
                    key,
                    CacheEntry {
                        actions: actions.clone(),
                        inserted_at: Instant::now(),
                    },
                );
            }
            Err(poisoned) => {
                error!("permission cache write lock poisoned, recovering to update cache");
                let mut cache = poisoned.into_inner();
                cache.retain(|_, v| !v.is_expired());
                cache.insert(
                    key,
                    CacheEntry {
                        actions: actions.clone(),
                        inserted_at: Instant::now(),
                    },
                );
            }
        }

        Ok(actions)
    }

    /// Execute the combined SQL query that resolves direct user permissions
    /// and group-based permissions via a UNION through `user_group_members`.
    async fn query_actions(
        &self,
        user_id: Uuid,
        target_type: &str,
        target_id: Uuid,
    ) -> Result<Vec<String>> {
        // Projects (#2472): when resolving actions on a repository target, a
        // grant on the repository's owning project is inherited. The
        // `$2 = 'repository'` guard confines inheritance to repository
        // targets; for a project-less repository the subquery yields NULL and
        // the project arm never matches, so behavior is unchanged.
        // #1849: `allowed_cidrs`-conditioned rules resolve to no actions
        // unless the in-flight request's client IP falls inside the range
        // (None outside a request scope fails closed), exactly as in
        // `check_repository_action`.
        let client_ip = crate::api::middleware::client_ip::current_client_ip();
        let query = format!(
            r#"
            SELECT DISTINCT unnest(actions) as action
            FROM permissions p
            WHERE (
                (p.principal_type IN ('user', 'service_account') AND p.principal_id = $1)
                OR
                (p.principal_type = 'group' AND p.principal_id IN (
                    SELECT group_id FROM user_group_members WHERE user_id = $1
                ))
            )
            AND (
                (p.target_type = $2 AND p.target_id = $3)
                OR ($2 = 'repository' AND p.target_type = 'project' AND p.target_id = (
                    SELECT project_id FROM repositories WHERE id = $3
                ))
            )
            {ip_condition}
            "#,
            ip_condition = ip_condition_sql("p", "$4"),
        );
        let rows: Vec<(String,)> = sqlx::query_as(sqlx::AssertSqlSafe(&*query))
            .bind(user_id)
            .bind(target_type)
            .bind(target_id)
            .bind(client_ip.map(|ip| ip.to_string()))
            .fetch_all(&self.db)
            .await
            .map_err(|e| AppError::Database(e.to_string()))?;

        Ok(rows.into_iter().map(|(action,)| action).collect())
    }
}
