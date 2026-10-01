// Copied from artifact-keeper/artifact-keeper @ 7c42891 by extract_upstream.py. Do not edit.
//! Authentication middleware.
//!
//! Extracts and validates JWT tokens or API tokens from requests.
//!
//! Supported authentication methods:
//! - `Authorization: Bearer <jwt_token>` - JWT access tokens
//! - `Authorization: Bearer <api_token>` - API tokens via Bearer scheme
//! - `Authorization: ApiKey <api_token>` - API tokens via ApiKey scheme
//! - `X-API-Key: <api_token>` - API tokens via custom header
//! - `X-NuGet-ApiKey: <api_token>` - API tokens on the NuGet push route only

use std::borrow::Cow;
use std::sync::Arc;
use std::time::Instant;

use axum::{
    extract::{OriginalUri, Request, State},
    http::{
        header::{AUTHORIZATION, COOKIE},
        HeaderMap, HeaderName, Method, StatusCode,
    },
    middleware::Next,
    response::{IntoResponse, Response},
};
use base64::Engine;
use uuid::Uuid;

use crate::api::{
    CachedRepo, RepoCache, RepoMissCache, REPO_CACHE_TTL_SECS, REPO_MISS_CACHE_MAX_ENTRIES,
};
use crate::error::AppError;
use crate::models::access_scope::AccessScope;
use crate::models::repository::RepositoryVisibility;
use crate::models::user::User;
use crate::services::auth_service::{AuthService, Claims};
use crate::services::permission_service::PermissionService;

/// Custom header name for API key
static X_API_KEY: HeaderName = HeaderName::from_static("x-api-key");

/// Header the NuGet client sends the push credential in.
///
/// `dotnet nuget push --api-key <key>` puts the credential here rather than in
/// `Authorization` when the configured source carries no credentials. Only the
/// NuGet push route honours it (see [`extract_nuget_push_api_key`]).
static X_NUGET_API_KEY: HeaderName = HeaderName::from_static("x-nuget-apikey");

/// Custom header the web UI attaches to every API request as the CSRF
/// defense-in-depth signal (#3065).
///
/// The *value* is irrelevant — only that the header is present. A cross-site
/// HTML form (the classic cookie-riding CSRF vector) cannot set any custom
/// request header at all, and a cross-origin `fetch()`/XHR that tries to set
/// one is forced into a CORS preflight that this server does not approve. So
/// presence alone proves the request was issued by same-origin script.
static X_REQUESTED_WITH: HeaderName = HeaderName::from_static("x-requested-with");

/// Name of the httpOnly cookie that carries a web-UI session's access token.
const SESSION_COOKIE_NAME: &str = "ak_access_token=";

/// Extension that holds authenticated user information
///
/// `Default` derives a deny-by-default principal (anonymous, non-admin,
/// `allowed_repo_ids = AccessScope::default()` = `Restricted(vec![])`, and no
/// `iat_ms`). It exists so the ~130 test fixtures and the two non-JWT
/// production literals can spell only the fields they care about via
/// `..Default::default()`; the JWT source of truth (`impl From<Claims>`) always
/// sets every field explicitly. The default MUST fail CLOSED — see
/// `AccessScope::default`.
#[derive(Debug, Clone, Default)]
pub struct AuthExtension {
    pub user_id: Uuid,
    pub username: String,
    pub email: String,
    pub is_admin: bool,
    /// Indicates if authentication was via API token (vs JWT)
    pub is_api_token: bool,
    /// Whether this principal is a service account (machine identity)
    pub is_service_account: bool,
    /// Token scopes if authenticated via API token
    pub scopes: Option<Vec<String>>,
    /// Repository-scope authorization decision for this principal.
    pub allowed_repo_ids: AccessScope,
    /// Calling token's **millisecond** issued-at (`Claims::effective_iat_ms`).
    ///
    /// `Some` only on the JWT path (Bearer, cookie, or a JWT presented as a
    /// Basic-auth password). `None` for API-key, X-API-Key, Basic
    /// username/password, ticket, and service-account auth (there is no JWT
    /// `iat`). Used by credential-change handlers (TOTP enable/disable) to
    /// exempt the calling session's own token from the invalidation it just
    /// triggered (#1370). Folded onto `AuthExtension` (from the former separate
    /// `TokenIat` extension) so the single `From<Claims>` source stamps it
    /// uniformly alongside the live re-derived `is_admin` (#1166, #1394).
    pub iat_ms: Option<i64>,
}

/// Marker request extension inserted alongside [`AuthExtension`] when the
/// caller authenticated via a single-use download ticket (`?ticket=`).
///
/// This is a separate extension rather than a field on `AuthExtension` so
/// the existing 80+ test fixtures and call sites that build `AuthExtension`
/// literals do not need to be updated. Middleware that needs to refuse
/// ticket-authenticated requests (writes, admin) checks for the presence
/// of this extension instead.
#[derive(Debug, Clone, Copy)]
pub struct DownloadTicketAuth;

impl AuthExtension {
    /// Calling token's **millisecond** issued-at, or `None` for non-JWT
    /// principals. See [`AuthExtension::iat_ms`]. Handlers performing a
    /// credential-change invalidation (TOTP enable/disable) use this to exempt
    /// the calling session's own token from the invalidation it just triggered
    /// (#1370).
    pub fn caller_iat_ms(&self) -> Option<i64> {
        self.iat_ms
    }

    /// Check whether this auth context has a required scope.
    ///
    /// The action-scope ceiling is carried by `scopes`, NOT by `is_api_token`
    /// (#2430): `None` = action-unrestricted (interactive login / federated CI
    /// / scan token) and always passes; `Some(list)` = the exact allowlist the
    /// presenting credential was minted with. Keying on `scopes` rather than
    /// `is_api_token` is what stops a JWT exchanged from a read-only API token
    /// from being laundered up to write/delete — the exchanged JWT carries
    /// `is_api_token = false` but inherits the token's `Some(scopes)` ceiling.
    /// The download-ticket path (`Some(vec![])`) therefore still denies.
    pub fn has_scope(&self, scope: &str) -> bool {
        match &self.scopes {
            None => true,
            // Delegate the wildcard-aware scope decision to the single
            // canonical helper (`*` / `admin` short-circuit) instead of
            // re-inlining a brittle string match here. Keeping the wildcard
            // policy in one place is what the #1316 grep gate enforces.
            Some(scopes) => crate::services::token_service::scopes_grant_access(scopes, scope),
        }
    }

    /// Repo-scope authorization decision for this principal, as an explicit
    /// [`AccessScope`].
    ///
    /// Returns the principal's repository scope: [`AccessScope::Admin`] grants
    /// all repositories, [`AccessScope::Restricted`] is a deny-by-default
    /// allowlist. This is the single accessor callers use to reason about
    /// repo-scope decisions (#1617, Phase 4).
    pub fn access_scope(&self) -> AccessScope {
        self.allowed_repo_ids.clone()
    }

    /// TOKEN SCOPE only: is `repo_id` within the set this credential was minted
    /// for? Returns true if unrestricted ([`AccessScope::Admin`]) or if the repo
    /// is in the allowed set.
    ///
    /// # This does NOT answer "may this caller see this repository"
    ///
    /// `AccessScope::Admin` grants unconditionally, and that is the scope of
    /// every browser JWT session, every unscoped API token and every global
    /// admin. So for the most common caller this returns `true` for EVERY
    /// repository in the instance, and using it as a visibility gate means any
    /// authenticated user reads the resource. That mistake has now produced four
    /// separate cross-tenant leaks: #3081, #3163, and the two in #3174.
    ///
    /// The visibility predicate is
    ///
    /// ```text
    /// is_public OR (in_scope AND (is_admin OR grants))
    /// ```
    ///
    /// where `in_scope` is this function and `grants` is
    /// `RepositoryService::user_can_access_repo` (a similar NAME, an entirely
    /// different question: role assignments, not token scope). Do not open-code
    /// it — use one of:
    ///
    /// * [`repositories::require_visible`] — a loaded `Repository`;
    /// * [`repositories::require_repo_id_visible`] — a bare `repository_id`;
    /// * [`repositories::member_read_visibility`] — a DB-side aggregate;
    /// * [`repositories::member_grant_visibility`] + `member_passes_token_scope`
    ///   — row-wise listing;
    /// * `RepositoryService::filter_visible_repo_ids` — a set of ids.
    ///
    /// Calling this directly is correct only where it is one CONJUNCT of a
    /// larger check that supplies the entitlement half separately (as
    /// `require_visible` and `repo_visibility_middleware` do), or where token
    /// scope genuinely is the question being asked (a mutation whose
    /// entitlement is established by a following permission check).
    ///
    /// [`repositories::require_visible`]: crate::api::handlers::repositories::require_visible
    /// [`repositories::require_repo_id_visible`]: crate::api::handlers::repositories::require_repo_id_visible
    /// [`repositories::member_read_visibility`]: crate::api::handlers::repositories::member_read_visibility
    /// [`repositories::member_grant_visibility`]: crate::api::handlers::repositories::member_grant_visibility
    pub fn can_access_repo(&self, repo_id: Uuid) -> bool {
        self.access_scope().grants(repo_id)
    }

    /// Return an authorization error if scope check fails.
    pub fn require_scope(&self, scope: &str) -> crate::error::Result<()> {
        if self.has_scope(scope) {
            Ok(())
        } else {
            Err(AppError::Authorization(format!(
                "Token does not have required scope: {}",
                scope
            )))
        }
    }

    /// Delegation ceiling for token minting (#2996): a non-admin caller may
    /// not mint a token carrying a scope its own presenting credential does
    /// not hold. `scopes: None` (interactive/UI/CI login) is
    /// action-unrestricted, so this is a no-op for those principals and never
    /// affects the console mint flow; it only constrains a scoped API token
    /// (or a JWT exchanged from one, #2430) attempting to mint a token that
    /// exceeds its own authority — e.g. a `read:artifacts` token minting
    /// `write:artifacts`.
    ///
    /// The per-scope decision is delegated to `has_scope` →
    /// `scopes_grant_access`, so the wildcard (`*`/`admin`) and bare-parent
    /// coverage semantics stay in the one canonical helper (#1316).
    pub fn enforce_mint_ceiling(&self, requested: &[String]) -> crate::error::Result<()> {
        if self.is_admin {
            return Ok(());
        }
        for s in requested {
            if !self.has_scope(s) {
                return Err(AppError::Authorization(format!(
                    "Cannot mint a token with scope '{s}': it exceeds the scopes of the \
                     presenting credential",
                )));
            }
        }
        Ok(())
    }

    /// Repository ceiling for token minting (#4225), the repository-scope
    /// counterpart of [`enforce_mint_ceiling`](Self::enforce_mint_ceiling).
    ///
    /// Returns the repositories a token minted by this credential must be
    /// restricted to, or `None` when the credential has no repository
    /// restriction (interactive sessions and unrestricted tokens), in which
    /// case the request's own restriction, if any, applies unchanged.
    ///
    /// A repository-restricted credential (a token restricted by
    /// `repo_selector` or `repository_ids`, or a JWT exchanged from one) passes
    /// its restriction on: the new token is stamped with the credential's
    /// resolved repositories. It may not name its own restriction
    /// (`requests_restriction`), because a selector is resolved at
    /// authentication time and cannot be proven no wider than the credential's
    /// here; that is a 403 rather than a silent override. A credential whose
    /// restriction currently matches no repository cannot mint at all, since
    /// an empty restriction would be stored as none. Admins are not exempt: an
    /// admin token restricted to some repositories is still restricted.
    pub fn mint_repo_ceiling(
        &self,
        requests_restriction: bool,
    ) -> crate::error::Result<Option<Vec<Uuid>>> {
        match &self.allowed_repo_ids {
            AccessScope::Admin => Ok(None),
            AccessScope::Restricted(_) if requests_restriction => Err(AppError::Authorization(
                "A repository-restricted credential cannot set a repository restriction on \
                 the token it mints; the new token inherits the credential's own"
                    .to_string(),
            )),
            AccessScope::Restricted(ids) if ids.is_empty() => Err(AppError::Authorization(
                "The presenting credential is restricted to repositories that match nothing, \
                 so it cannot mint a token"
                    .to_string(),
            )),
            AccessScope::Restricted(ids) => Ok(Some(ids.clone())),
        }
    }

    /// Fold the effective-admin decision at construction time so every
    /// downstream `is_admin` read (both `require_admin` and the ~34 raw
    /// `if !auth.is_admin` handler checks) inherits scope awareness from a
    /// single place.
    ///
    /// A principal is an *effective* admin only when it is BOTH owned by an
    /// admin user AND presenting a credential whose scope ceiling grants the
    /// `admin` scope. `has_scope` treats `None` (interactive login / basic
    /// auth) as unrestricted, so this is a no-op for those principals and
    /// preserves their admin. For a scope-restricted credential (an API token
    /// or a JWT exchanged from one), `Some(list)` only grants `admin` when the
    /// list carries `admin` or `*` — both of which live on `ADMIN_ONLY_SCOPES`
    /// and cannot be minted by a non-admin. This closes GHSA-vvc3: an
    /// admin-owned but narrow-scoped token (e.g. `read:artifacts`) no longer
    /// inherits unconditional admin.
    fn with_scope_gated_admin(mut self) -> Self {
        self.is_admin = self.is_admin && self.has_scope("admin");
        self
    }

    /// Return a 403 Forbidden error if the caller is not an admin.
    pub fn require_admin(&self) -> crate::error::Result<()> {
        if self.is_admin {
            Ok(())
        } else {
            Err(AppError::Authorization("Admin access required".to_string()))
        }
    }

    /// Self-or-admin gate: allow the call when the caller is acting on their
    /// own resource (`self.user_id == target_user_id`) **or** the caller is an
    /// admin. Otherwise return a 403 Forbidden carrying `deny_msg`.
    ///
    /// This is the single evaluation point for the recurring self-service
    /// authorization pattern (`if auth.user_id != id && !auth.is_admin { 403 }`).
    /// The deny message is supplied by the call site so each endpoint keeps its
    /// existing, user-facing 403 body verbatim (e.g. "Cannot view other users'
    /// tokens"). Deny-by-default: any caller who is neither self nor admin is
    /// rejected.
    pub fn require_self_or_admin(
        &self,
        target_user_id: Uuid,
        deny_msg: &str,
    ) -> crate::error::Result<()> {
        if self.user_id == target_user_id || self.is_admin {
            Ok(())
        } else {
            Err(AppError::Authorization(deny_msg.to_string()))
        }
    }
}

impl From<Claims> for AuthExtension {
    fn from(claims: Claims) -> Self {
        // Single source of truth for the calling JWT's issued-at. Folded here
        // (from the former separate `TokenIat` extension) so every JWT
        // principal carries `iat_ms` uniformly (#1394). Computed before the
        // partial move of `claims.allowed_repo_ids` below.
        let iat_ms = Some(claims.effective_iat_ms());
        Self {
            user_id: claims.sub,
            username: claims.username,
            email: claims.email,
            is_admin: claims.is_admin,
            is_api_token: false,
            is_service_account: false,
            // Propagate the action-scope ceiling minted onto the JWT (#2430).
            // `None` for interactive/CI logins (full); `Some(list)` for JWTs
            // exchanged from an API token — enforced by `has_scope`.
            scopes: claims.scopes,
            allowed_repo_ids: AccessScope::from(claims.allowed_repo_ids),
            iat_ms,
        }
        // No-op for interactive/CI JWTs (`scopes = None`); demotes an
        // exchanged JWT that inherited a narrow token ceiling (GHSA-vvc3).
        .with_scope_gated_admin()
    }
}

impl From<User> for AuthExtension {
    fn from(user: User) -> Self {
        Self {
            user_id: user.id,
            username: user.username,
            email: user.email,
            is_admin: user.is_admin,
            is_api_token: false,
            is_service_account: user.is_service_account,
            scopes: None,
            allowed_repo_ids: AccessScope::Admin,
            // Basic username/password auth carries no JWT `iat`.
            iat_ms: None,
        }
    }
}

/// Require that the request is authenticated, returning a 401 with a
/// `WWW-Authenticate: Basic` challenge if not.
///
/// Format handlers call this instead of implementing their own auth.
#[allow(clippy::result_large_err)]
pub fn require_auth_basic(
    auth: Option<AuthExtension>,
    realm: &str,
) -> std::result::Result<AuthExtension, Response> {
    auth.ok_or_else(|| {
        Response::builder()
            .status(StatusCode::UNAUTHORIZED)
            .header("WWW-Authenticate", format!("Basic realm=\"{}\"", realm))
            .body(axum::body::Body::from("Authentication required"))
            .unwrap()
    })
}

/// Like [`require_auth_basic`] but additionally enforces the given API-token
/// scope. JWT and password-authenticated sessions (anything without
/// `is_api_token = true`) pass through unchanged because they are not scope
/// restricted. API tokens must carry the requested scope or `*`/`admin`,
/// otherwise this returns a 403 with body
/// `Token does not have required scope: <scope>`.
///
/// Format handlers should call this instead of `require_auth_basic` for any
/// write/delete path (publish, upload, delete) so a read-scoped service
/// account token cannot push or destroy artifacts. See GHSA-vvc3-h39c-mrq5.
#[allow(clippy::result_large_err)]
pub fn require_auth_basic_scope(
    auth: Option<AuthExtension>,
    realm: &str,
    scope: &str,
) -> std::result::Result<AuthExtension, Response> {
    let ext = require_auth_basic(auth, realm)?;
    if !ext.has_scope(scope) {
        return Err(Response::builder()
            .status(StatusCode::FORBIDDEN)
            .body(axum::body::Body::from(format!(
                "Token does not have required scope: {}",
                scope
            )))
            .unwrap());
    }
    Ok(ext)
}

/// Enforce a scope check on an already-resolved auth context, returning a
/// 403 `Response` if the scope is missing. Use for write/delete paths that
/// authenticate via [`require_auth_with_bearer_fallback`] or other helpers
/// returning `Response` errors. See GHSA-vvc3-h39c-mrq5.
#[allow(clippy::result_large_err)]
pub fn require_scope_response(
    auth: Option<&AuthExtension>,
    scope: &str,
) -> std::result::Result<(), Response> {
    if let Some(ext) = auth {
        if !ext.has_scope(scope) {
            return Err(Response::builder()
                .status(StatusCode::FORBIDDEN)
                .body(axum::body::Body::from(format!(
                    "Token does not have required scope: {}",
                    scope
                )))
                .unwrap());
        }
    }
    Ok(())
}

/// Extract credentials from a Bearer token that contains base64-encoded user:pass.
///
/// Some package managers (npm, cargo, goproxy) send Bearer tokens that are
/// base64-encoded `username:password` rather than JWTs or API keys.
pub fn extract_bearer_credentials(headers: &HeaderMap) -> Option<(String, String)> {
    headers
        .get(AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer ").or(v.strip_prefix("bearer ")))
        .and_then(|token| {
            base64::engine::general_purpose::STANDARD
                .decode(token)
                .ok()
                .and_then(|bytes| String::from_utf8(bytes).ok())
                .and_then(|s| {
                    let mut parts = s.splitn(2, ':');
                    let user = parts.next()?.to_string();
                    let pass = parts.next()?.to_string();
                    Some((user, pass))
                })
        })
}

/// Require authentication, with a fallback to Bearer-as-base64 credentials.
///
/// Used by format handlers (npm, cargo, goproxy) where clients may send
/// credentials as a base64-encoded `user:pass` in a Bearer token rather than
/// using standard Basic auth.
#[allow(clippy::result_large_err)]
pub async fn require_auth_with_bearer_fallback(
    auth: Option<AuthExtension>,
    headers: &HeaderMap,
    db: &sqlx::PgPool,
    config: &crate::config::Config,
    realm: &str,
) -> std::result::Result<uuid::Uuid, Response> {
    if let Some(ext) = auth {
        return Ok(ext.user_id);
    }
    let (username, password) = extract_bearer_credentials(headers).ok_or_else(|| {
        Response::builder()
            .status(StatusCode::UNAUTHORIZED)
            .header("WWW-Authenticate", format!("Basic realm=\"{}\"", realm))
            .body(axum::body::Body::from("Authentication required"))
            .unwrap()
    })?;
    let auth_service = AuthService::new(db.clone(), std::sync::Arc::new(config.clone()));
    let (user, _) = auth_service
        .authenticate(&username, &password)
        .await
        .map_err(|e| {
            // A pool-acquire timeout during the credential DB lookup is a
            // transient capacity problem (POOL_EXHAUSTED), not a bad password:
            // surface a retryable 503 rather than flattening it to a spurious
            // 401 (#2125). Any genuine failure keeps the existing 401.
            if e.is_pool_timeout() {
                return service_unavailable_response();
            }
            Response::builder()
                .status(StatusCode::UNAUTHORIZED)
                .header("WWW-Authenticate", format!("Basic realm=\"{}\"", realm))
                .body(axum::body::Body::from("Invalid credentials"))
                .unwrap()
        })?;
    Ok(user.id)
}

/// Token extraction result
#[derive(Debug, Clone, Copy)]
pub(crate) enum ExtractedToken<'a> {
    /// JWT or API token from the `Bearer` scheme — or from the
    /// `Token` scheme, which `ansible-galaxy` uses and which is treated as
    /// Bearer-equivalent (#3137), or from a scheme-less cargo credential.
    Bearer(&'a str),
    /// API token from ApiKey scheme
    ApiKey(&'a str),
    /// HTTP Basic credentials (base64-encoded user:password)
    Basic(&'a str),
    /// No token found
    None,
    /// Invalid header format
    Invalid,
}

/// Extract token from Authorization header (supports the Bearer, Token,
/// ApiKey, and Basic schemes, plus the scheme-less cargo credential).
/// `Token` — the scheme `ansible-galaxy` sends — resolves to the same
/// [`ExtractedToken::Bearer`] variant as `Bearer` (#3137).
fn extract_token_from_auth_header(auth_header: &str) -> ExtractedToken<'_> {
    if let Some(token) = auth_header.strip_prefix("Bearer ") {
        ExtractedToken::Bearer(token)
    } else if let Some(token) = auth_header.strip_prefix("Token ") {
        // `ansible-galaxy` authenticates Galaxy API calls with
        // `Authorization: Token <api_key>` — ansible-core
        // `lib/ansible/galaxy/token.py` sets `GalaxyToken.token_type = 'Token'`
        // and builds the header as `'%s %s' % (self.token_type, self.get())`;
        // only its Keycloak/Automation-Hub variant uses `Bearer`. Treat the
        // `Token` scheme as Bearer-equivalent so the credential flows through
        // the same JWT → API-token validation chain instead of being rejected
        // as a malformed header (#3137).
        ExtractedToken::Bearer(token)
    } else if let Some(token) = auth_header.strip_prefix("ApiKey ") {
        ExtractedToken::ApiKey(token)
    } else if let Some(creds) = auth_header
        .strip_prefix("Basic ")
        .or_else(|| auth_header.strip_prefix("basic "))
    {
        ExtractedToken::Basic(creds)
    } else if !auth_header.is_empty() && !auth_header.contains(' ') {
        // The native cargo client's `cargo:token` credential provider sends the
        // raw token as the Authorization header value with NO scheme prefix
        // (e.g. `Authorization: <token>`). A scheme-less, single-word value is
        // therefore treated as a Bearer token so cargo can authenticate.
        ExtractedToken::Bearer(auth_header)
    } else {
        ExtractedToken::Invalid
    }
}

/// Extract token from request headers
/// Checks: Authorization (Bearer/Token/ApiKey/Basic), X-API-Key
pub(crate) fn extract_token(request: &Request) -> ExtractedToken<'_> {
    // First, check Authorization header
    if let Some(auth_header) = request
        .headers()
        .get(AUTHORIZATION)
        .and_then(|h| h.to_str().ok())
    {
        let result = extract_token_from_auth_header(auth_header);
        if !matches!(result, ExtractedToken::None) {
            return result;
        }
    }

    // Check X-API-Key header
    if let Some(api_key) = request
        .headers()
        .get(&X_API_KEY)
        .and_then(|h| h.to_str().ok())
    {
        return ExtractedToken::ApiKey(api_key);
    }

    // Check cookie as fallback (for browser sessions with httpOnly cookies)
    if let Some(token) = session_cookie_token(request.headers()) {
        return ExtractedToken::Bearer(token);
    }

    ExtractedToken::None
}

/// The web-UI session access token carried in the `ak_access_token` cookie,
/// if the request has one.
///
/// Single source for "is there a session cookie", shared by [`extract_token`]
/// (which turns it into a credential) and [`credential_is_session_cookie`]
/// (which decides whether the CSRF contract applies).
fn session_cookie_token(headers: &HeaderMap) -> Option<&str> {
    headers
        .get(COOKIE)
        .and_then(|h| h.to_str().ok())?
        .split(';')
        .find_map(|cookie| cookie.trim().strip_prefix(SESSION_COOKIE_NAME))
}

/// Whether this request would be authenticated by the browser session cookie
/// rather than by an explicitly-presented header credential.
///
/// Mirrors [`extract_token`]'s precedence exactly, and that is the whole
/// point: `Authorization` wins, then `X-API-Key`, and only then the cookie.
/// Native package-manager clients (pip, npm, cargo, docker, maven, …)
/// authenticate with HTTP Basic or a Bearer/API-key token, so they take one of
/// the earlier branches and are never treated as cookie-authenticated — which
/// is what keeps the CSRF header requirement off them.
///
/// Deliberately does not care whether the cookie is *valid*: an attacker
/// cannot make the browser omit it, so the contract has to be decided on the
/// request's shape, before any credential is resolved.
fn credential_is_session_cookie(headers: &HeaderMap) -> bool {
    !has_header_credential(headers) && session_cookie_token(headers).is_some()
}

/// Whether the request presents a credential in a HEADER (`Authorization` or
/// `X-API-Key`), as opposed to the session cookie.
fn has_header_credential(headers: &HeaderMap) -> bool {
    headers
        .get(AUTHORIZATION)
        .and_then(|h| h.to_str().ok())
        .is_some_and(|h| !matches!(extract_token_from_auth_header(h), ExtractedToken::None))
        || headers.contains_key(&X_API_KEY)
}

/// Whether this request carries ANY caller credential — `Authorization`,
/// `X-API-Key`, or the `ak_access_token` session cookie.
///
/// The single source of truth for "is this request credentialed", so a
/// caller-dependent response's cacheability (`cache_headers::
/// negotiated_cache_control`, #3406) cannot drift from the set of carriers
/// [`extract_token`] actually accepts. Adding a fourth carrier there without
/// updating this would let a shared cache store and replay a response built
/// for one caller.
///
/// Like [`credential_is_session_cookie`], this is a test on the request's
/// SHAPE, not on whether the credential authenticates.
pub fn request_carries_credentials(headers: &HeaderMap) -> bool {
    has_header_credential(headers) || session_cookie_token(headers).is_some()
}

/// Whether `method` can change server state, and therefore falls under the
/// CSRF contract. `GET`/`HEAD`/`OPTIONS` (and anything else safe) do not.
fn is_state_changing_method(method: &Method) -> bool {
    matches!(
        *method,
        Method::POST | Method::PUT | Method::PATCH | Method::DELETE
    )
}

/// Whether this request breaks the web-UI CSRF contract and must be refused
/// (#3065).
///
/// All four conditions must hold, and each one is load-bearing:
///
/// 1. **State-changing method.** Reads are not the CSRF threat.
/// 2. **Cookie-authenticated** ([`credential_is_session_cookie`]). This is the
///    exemption that keeps native package-manager clients and every
///    token-authenticated API call working: they present a Basic/Bearer/API-key
///    header, so the contract never applies to them. Only the credential a
///    browser attaches *automatically* — and which the attacker therefore does
///    not need to know — is in scope.
/// 3. **Browser-originated** ([`is_browser_request`], the detector added in
///    #3389; reused rather than duplicated). This costs nothing in security:
///    a forged cookie-riding request is by construction issued by the victim's
///    browser, which stamps `Sec-Fetch-*` on every request in a secure context
///    and sends `Accept: text/html` on a form navigation. A non-browser client
///    can set any header it likes, so requiring one of it would prove nothing.
/// 4. **No same-origin proof** — neither the custom header
///    ([`X_REQUESTED_WITH`], see that constant) nor a Fetch Metadata
///    same-origin declaration ([`declares_same_origin`], #3592).
///
/// This is belt-and-suspenders behind the primary mitigation, `SameSite=Strict`
/// on the session cookie (`handlers::auth::set_auth_cookies`), and exists so a
/// future weakening of that attribute cannot silently re-open cross-site
/// mutations.
///
/// Pure and header-only, so the decision is unit-testable without a request.
fn violates_csrf_contract(method: &Method, headers: &HeaderMap) -> bool {
    is_state_changing_method(method)
        && credential_is_session_cookie(headers)
        && is_browser_request(headers)
        && !headers.contains_key(&X_REQUESTED_WITH)
        && !declares_same_origin(headers)
}

/// Whether the browser itself declares this request same-origin, via the
/// `Sec-Fetch-Site` Fetch Metadata header (#3592).
///
/// `Sec-Fetch-Site` is a forbidden request header: only the user agent sets
/// it, and page script cannot override it. `same-origin` therefore proves what
/// [`X_REQUESTED_WITH`] proves — the request was issued from our own origin —
/// with no cooperation required from the client code. `none` is the
/// user-initiated case (typed URL, bookmark), which is likewise not an
/// attacker-controlled document.
///
/// Every other value stays a violation, deliberately:
///
/// * `cross-site` is the classic cookie-riding vector;
/// * `same-site` is a *different* origin under the same registrable domain
///   (a sibling subdomain, e.g. one that has been taken over), which is a real
///   CSRF position and not something this contract should trust.
///
/// An absent header is not a same-origin declaration either, so an older
/// browser that sends no Fetch Metadata still has to send
/// [`X_REQUESTED_WITH`]; this only ever *adds* an accepted proof.
///
/// The motivating case is the web UI's artifact upload (#3592): it posts
/// `multipart/form-data` through `fetch()` from the app's own origin without
/// attaching `X-Requested-With`, and was refused with a 403 that told the user
/// to use a token instead — for the one operation the UI exists to perform.
fn declares_same_origin(headers: &HeaderMap) -> bool {
    headers
        .get("sec-fetch-site")
        .and_then(|v| v.to_str().ok())
        .is_some_and(|v| {
            let v = v.trim();
            v.eq_ignore_ascii_case("same-origin") || v.eq_ignore_ascii_case("none")
        })
}

/// 403 for a cookie-authenticated mutation that did not carry the custom
/// header. Distinct from 401: the caller *is* authenticated, the request shape
/// is what was refused, so retrying with the header is the fix.
fn csrf_forbidden_response() -> Response {
    (
        StatusCode::FORBIDDEN,
        "Cookie-authenticated state-changing requests must prove same origin \
         (CSRF protection): send the X-Requested-With header, or issue the \
         request from the application's own origin so the browser stamps \
         Sec-Fetch-Site: same-origin. Use a Bearer or API token for \
         non-browser clients.",
    )
        .into_response()
}

/// Enforce the CSRF contract for one request, if it applies.
///
/// Returns `Some(403)` for a request to refuse, `None` to continue. Called at
/// the head of every authentication middleware so the check cannot be skipped
/// by whichever one a route happens to mount.
fn csrf_guard(request: &Request) -> Option<Response> {
    violates_csrf_contract(request.method(), request.headers()).then(csrf_forbidden_response)
}

/// Standalone CSRF layer for the whole `/api/v1` surface (#3065).
///
/// Deliberately overlaps with the [`csrf_guard`] call inside each
/// authentication middleware, because neither alone covers everything:
/// this layer reaches the `/api/v1` routes that carry no auth middleware at
/// all (`/auth/login`, `/auth/refresh`, `/auth/logout` — all cookie-writing
/// and all worth protecting), while the in-middleware calls reach the
/// auth-gated routes mounted *outside* `/api/v1`. Running the predicate twice
/// on the overlap costs one header lookup.
pub async fn csrf_middleware(request: Request, next: Next) -> Response {
    match csrf_guard(&request) {
        Some(refusal) => refusal,
        None => next.run(request).await,
    }
}

/// Decode a base64-encoded Basic auth string into (username, password).
///
/// Returns `None` if the base64 is invalid, the bytes are not valid UTF-8,
/// or the decoded string does not contain a `:` separator.
fn decode_basic_credentials(encoded: &str) -> Option<(String, String)> {
    let bytes = base64::engine::general_purpose::STANDARD
        .decode(encoded)
        .ok()?;
    let decoded = String::from_utf8(bytes).ok()?;
    let (user, pass) = decoded.split_once(':')?;
    Some((user.to_owned(), pass.to_owned()))
}

/// Whether `path` is reachable by a principal flagged `must_change_password`.
///
/// A forced-rotation user is otherwise blocked from every route (see
/// [`auth_middleware`]); this allowlist is the narrow set of endpoints that
/// let them recover without admin intervention:
///
///   * the current-user self lookup (`.../me`, i.e. `GET /api/v1/auth/me`) —
///     a read-only call the mandatory first-login change screen makes to
///     render (who is logged in / which account is being rotated),
///   * the self password-change route (`.../password`, e.g.
///     `POST /api/v1/users/:id/password`) — clears the flag, and
///   * logout (`.../auth/logout`) — lets the client end the session.
///
/// Matching is by suffix of the FULL, un-stripped request path (see
/// [`auth_middleware`], which reads `OriginalUri`). This middleware is layered
/// *inside* the `/api/v1` + `/auth` nests, so `request.uri().path()` is the
/// fully nest-stripped suffix — `GET /api/v1/auth/me` and
/// `DELETE /api/v1/sbom/me` (id = "me") both arrive as exactly `/me`, which a
/// stripped-path predicate cannot tell apart. The genuine self-lookup is
/// therefore anchored to the full route `.../auth/me`, so impostors like
/// `/api/v1/sbom/me`, `/api/v1/webhooks/me`, and `/api/v1/promotion-rules/me`
/// stay gated. The admin reset / force-change routes
/// (`.../password/reset`, `.../force-password-change`) deliberately do NOT
/// match — they sit behind `admin_middleware`, not this one, and would not be
/// self-recoverable. Only read-only / self-recovery endpoints are exempt;
/// every state-changing API surface stays gated until the flag is cleared.
fn path_exempt_from_password_change(path: &str) -> bool {
    let path = path.strip_suffix('/').unwrap_or(path);
    path.ends_with("/auth/me") || path.ends_with("/password") || path.ends_with("/auth/logout")
}

/// 428 Precondition Required: the principal must rotate their password before
/// any further (non-recovery) request is honoured. Distinct from 401 so the
/// client can tell "rotate your password" apart from "log in again".
fn must_change_password_response() -> Response {
    (
        StatusCode::PRECONDITION_REQUIRED,
        "Password change required: rotate your password before continuing",
    )
        .into_response()
}

/// Read the live `must_change_password` watermark for `user_id`.
///
/// The flag is not carried in JWT claims, so it is read from the DB on the
/// request path (only for non-exempt routes — see [`auth_middleware`]). A
/// missing row or query error is treated as "not flagged": the principal has
/// already authenticated, and a transient DB hiccup must not convert a normal
/// request into a forced-rotation lockout. Uses runtime `query_scalar` (not
/// the compile-time macro) so it needs no offline SQLx cache.
async fn principal_must_change_password(db: &sqlx::PgPool, user_id: Uuid) -> bool {
    sqlx::query_scalar::<_, bool>(
        "SELECT must_change_password FROM users WHERE id = $1 AND is_active = true",
    )
    .bind(user_id)
    .fetch_optional(db)
    .await
    .ok()
    .flatten()
    .unwrap_or(false)
}

/// Authentication middleware function - requires valid token
///
/// Supports multiple authentication schemes:
/// - Bearer JWT tokens
/// - Bearer API tokens
/// - ApiKey API tokens
/// - X-API-Key header
pub async fn auth_middleware(
    State(auth_service): State<Arc<AuthService>>,
    mut request: Request,
    next: Next,
) -> Response {
    // CSRF contract for cookie-authenticated browser mutations (#3065). Header
    // -only and credential-independent, so it runs before anything is resolved.
    if let Some(refusal) = csrf_guard(&request) {
        return refusal;
    }

    // Extract token from request headers
    let extracted = extract_token(&request);

    // Track whether the request even attempted header-based auth, so the
    // 401 message stays informative when only a ?ticket= was supplied.
    let had_header_credentials = !matches!(extracted, ExtractedToken::None);

    // The resolved principal. The JWT `iat` used by credential-change
    // invalidation (TOTP, password) to exempt the calling session's own token
    // now travels as `AuthExtension::iat_ms`, stamped at the single
    // `From<Claims>` source; it is `None` for non-JWT principals (#1394).
    let header_result: Result<AuthExtension, &'static str> = match extracted {
        // Replica-safe access-token validation. The async variant consults the
        // DB credential-change watermark (#1173) so a password reset, TOTP
        // change, or deactivation on a peer replica is honoured here on the
        // request path within `CREDENTIAL_DB_CACHE_TTL_SECS`. The sync variant
        // (which only reads the in-memory map) would silently keep accepting
        // pre-change tokens across replicas — that's the architectural gap
        // PR #1190 was supposed to close.
        ExtractedToken::Bearer(token) => {
            match auth_service.validate_access_token_async(token).await {
                Ok(claims) => Ok(AuthExtension::from(claims)),
                Err(_) => match validate_api_token_with_scopes(&auth_service, token).await {
                    Ok(ext) => Ok(ext),
                    // Same transient bcrypt-capacity shed as the Basic branch
                    // below: a saturated cap is "retry shortly", not "wrong
                    // token". See `TokenAuthError::Overloaded`.
                    Err(TokenAuthError::Overloaded) => return service_unavailable_response(),
                    Err(TokenAuthError::Invalid) => Err("Invalid or expired token"),
                },
            }
        }
        ExtractedToken::ApiKey(token) => {
            match validate_api_token_with_scopes(&auth_service, token).await {
                Ok(ext) => Ok(ext),
                Err(TokenAuthError::Overloaded) => return service_unavailable_response(),
                Err(TokenAuthError::Invalid) => Err("Invalid or expired API token"),
            }
        }
        ExtractedToken::Basic(encoded) => match decode_basic_credentials(encoded) {
            None => Err("Invalid Basic auth credentials"),
            Some((username, password)) => {
                match auth_service.authenticate(&username, &password).await {
                    Ok((user, _token_pair)) => Ok(AuthExtension::from(user)),
                    // A transient bcrypt-capacity shed must NOT be collapsed
                    // into a 401. `authenticate()` runs bcrypt(cost=12) under a
                    // process-wide concurrency cap (see
                    // `auth_service::acquire_auth_permit_for_bcrypt`); when that
                    // cap saturates under a burst of concurrent Basic-auth
                    // requests it returns `AppError::ServiceUnavailable`, which
                    // is a retryable 503, not "wrong password". Collapsing it to
                    // 401 "Invalid credentials" is what made `twine upload` fail
                    // in the release gate (a curl -u upload with byte-identical
                    // credentials passed because it didn't coincide with a
                    // saturated cap): twine does not retry on 401 but does on
                    // 503. Surface the shed as 503 + Retry-After so well-behaved
                    // clients back off and retry instead of aborting.
                    Err(AppError::ServiceUnavailable(msg)) => {
                        return (
                            StatusCode::SERVICE_UNAVAILABLE,
                            [(axum::http::header::RETRY_AFTER, "1")],
                            msg,
                        )
                            .into_response();
                    }
                    // A pool-acquire timeout during the credential DB lookup is
                    // a transient capacity problem (POOL_EXHAUSTED), not "wrong
                    // password": surface the same retryable 503 the #2101/#2102
                    // handlers return rather than flattening it to a spurious
                    // 401 (#2125). Clients retry on 503 but abort on 401.
                    Err(ref e) if e.is_pool_timeout() => {
                        return service_unavailable_response();
                    }
                    Err(_) => {
                        // Try treating the password as a short-lived JWT access
                        // token. This enables CI/CD keyless flows (e.g. OIDC
                        // token exchange) where package managers like Maven,
                        // pip/twine, and Helm send the AK access token as the
                        // Basic-auth password. `From<Claims>` stamps `iat_ms` so
                        // credential-change invalidation can exempt the calling
                        // session.
                        //
                        // An API token is deliberately NOT accepted as the Basic
                        // password here: this is the hard-auth middleware for the
                        // management API (/api/v1/auth, /profile, /signing, …).
                        // Per the openapi.rs contract, an API token is only ever
                        // valid as a `Bearer`/`X-Api-Key` credential or the Basic
                        // password on the FORMAT/registry endpoints (handled by
                        // `repo_visibility_middleware` → `try_resolve_auth_outcome`
                        // with `allow_basic_api_token=true`). Accepting it here
                        // (added by #2798) over-reached the #2786 need; #2806
                        // restores the /api/v1 Basic-auth boundary.
                        match auth_service.validate_access_token_async(&password).await {
                            Ok(claims) => Ok(AuthExtension::from(claims)),
                            Err(_) => Err("Invalid credentials"),
                        }
                    }
                }
            }
        },
        ExtractedToken::None => Err("Missing authorization header"),
        ExtractedToken::Invalid => Err("Invalid authorization header format"),
    };

    let header_error = match header_result {
        Ok(ext) => {
            // Enforce a forced password rotation (`must_change_password`).
            //
            // The flag is advisory in the token/claims, so we read the live DB
            // watermark for the principal. A flagged user must be unable to do
            // anything except recover: change their own password or log out.
            // Every other route is refused with 428 Precondition Required so
            // clients know the account is in a "must rotate" state rather than
            // "unauthenticated". The DB read only happens for non-exempt paths,
            // so the common authenticated request pays nothing extra on the
            // password-change / logout recovery routes.
            //
            // Use the FULL request path via `OriginalUri` (populated by the
            // outer router before any nest stripped its prefix), not
            // `request.uri().path()` which axum has already stripped down to a
            // bare suffix. The exemption anchors the self-lookup to
            // `.../auth/me`, and the stripped suffix `/me` is identical for the
            // genuine `GET /api/v1/auth/me` and impostors like
            // `DELETE /api/v1/sbom/me`; only the original path can tell them
            // apart. Fall back to `request.uri().path()` when `OriginalUri` is
            // absent (e.g. a flat-router unit test with no nest) so the path
            // still carries the full route.
            let gate_path = request
                .extensions()
                .get::<OriginalUri>()
                .map(|o| o.0.path().to_string())
                .unwrap_or_else(|| request.uri().path().to_string());
            if !path_exempt_from_password_change(&gate_path)
                && principal_must_change_password(auth_service.db(), ext.user_id).await
            {
                return must_change_password_response();
            }
            // Insert BOTH shapes so handlers behind this middleware can
            // extract either `Extension<AuthExtension>` or
            // `Extension<Option<AuthExtension>>`. Without the Option-wrapped
            // copy, a handler declaring `Extension<Option<AuthExtension>>`
            // (e.g. the permission handlers, which gate on require_auth +
            // require_scope) fails Axum extraction with HTTP 500
            // ("Missing request extension: Extension of type
            // Option<AuthExtension>") before the in-handler scope check runs.
            // That surfaced as a 500 instead of the canonical 403 for a
            // read-scope service-account token on POST /api/v1/permissions.
            // See #1438 (B10).
            request.extensions_mut().insert(Some(ext.clone()));
            request.extensions_mut().insert(ext);
            return next.run(request).await;
        }
        Err(msg) => msg,
    };

    // Header-based auth failed. Fall back to a `?ticket=` download ticket
    // if present in the query string. Tickets only authenticate read methods
    // and only for the path the ticket was minted against.
    let ticket_parts = extract_ticket_request_parts(&request);
    if let Some(parts) = ticket_parts.as_ref() {
        if let Some(ext) = try_resolve_ticket_for_parts(auth_service.db(), parts).await {
            // Same dual-shape insertion as the header-auth path above so
            // `Extension<Option<AuthExtension>>` handlers resolve under a
            // ticket-authenticated request too (#1438 / B10).
            request.extensions_mut().insert(Some(ext.clone()));
            request.extensions_mut().insert(ext);
            request.extensions_mut().insert(DownloadTicketAuth);
            return next.run(request).await;
        }
    }

    // Note on the ambiguous message: "Invalid or expired download ticket"
    // intentionally does not distinguish between
    //   (a) ticket not found,
    //   (b) ticket expired,
    //   (c) bound-path mismatch,
    //   (d) write method on a read-only ticket.
    // Leaking which case it is would help an attacker who has a partial
    // ticket value (or who is probing path bindings) narrow down the cause.
    // High-entropy tickets and a 30-second TTL make ambiguity cheap. Do not
    // "fix" this by giving a more specific message.
    let message = if !had_header_credentials && ticket_parts.is_some() {
        "Invalid or expired download ticket"
    } else {
        header_error
    };
    (StatusCode::UNAUTHORIZED, message).into_response()
}

/// Why an API-token validation attempt did not produce an [`AuthExtension`].
///
/// Two outcomes matter to the middleware: the token is genuinely bad
/// (unknown, expired, revoked, deactivated owner — answer with 401), or
/// validation could not be completed because the process-wide bcrypt
/// concurrency cap is saturated (`AppError::ServiceUnavailable` from
/// `auth_service::acquire_auth_permit_for_bcrypt` — answer with a retryable
/// 503, exactly like the username/password branch). Flattening both into a
/// unit error is what made cargo/twine API-token clients receive a spurious
/// 401 under a concurrent burst; they retry on 503 but abort on 401.
#[derive(Debug, PartialEq, Eq)]
enum TokenAuthError {
    /// The credential failed validation; the caller owes the client a 401.
    Invalid,
    /// The bcrypt-bound auth-concurrency cap is saturated; the caller must
    /// surface a retryable 503 (see [`service_unavailable_response`]), never
    /// a 401.
    Overloaded,
}

/// Classify a `validate_api_token` error into the two outcomes the
/// middleware distinguishes. Only the transient bcrypt-capacity shed
/// (`AppError::ServiceUnavailable`) maps to [`TokenAuthError::Overloaded`];
/// everything else (authentication, unauthorized, database, internal) is a
/// genuine validation failure and stays [`TokenAuthError::Invalid`] so the
/// existing 401 behaviour is preserved.
fn classify_token_validation_err(err: AppError) -> TokenAuthError {
    match err {
        AppError::ServiceUnavailable(_) => TokenAuthError::Overloaded,
        // A pool-acquire timeout during the token's DB lookup is a transient
        // capacity problem, not a bad token: surface it as a retryable 503
        // (POOL_EXHAUSTED) exactly like the #2101/#2102 handler path instead of
        // flattening it to a spurious 401 (#2125). Reuses the shared
        // `AppError::is_pool_timeout` predicate so the classification stays
        // consistent all the way up the stack.
        ref e if e.is_pool_timeout() => TokenAuthError::Overloaded,
        _ => TokenAuthError::Invalid,
    }
}

/// Validate an API token and create an AuthExtension with scopes and repo restrictions.
async fn validate_api_token_with_scopes(
    auth_service: &AuthService,
    token: &str,
) -> Result<AuthExtension, TokenAuthError> {
    let validation = auth_service
        .validate_api_token(token)
        .await
        .map_err(classify_token_validation_err)?;

    Ok(AuthExtension {
        user_id: validation.user.id,
        username: validation.user.username,
        email: validation.user.email,
        is_admin: validation.user.is_admin,
        is_api_token: true,
        is_service_account: validation.user.is_service_account,
        scopes: Some(validation.scopes),
        allowed_repo_ids: validation.allowed_repo_ids,
        // API tokens are not JWTs and carry no `iat`.
        iat_ms: None,
    }
    // An admin-owned token only wields admin when its scope ceiling grants
    // the `admin` scope (or `*`); a narrow-scoped token is demoted to a
    // non-admin principal here (GHSA-vvc3).
    .with_scope_gated_admin())
}

/// Outcome of resolving an authentication credential.
///
/// Distinguishes three states an optional-auth path needs to handle
/// differently after #1371:
///
///   * [`AuthOutcome::Resolved`] - a credential was presented and validated.
///   * [`AuthOutcome::NoCredential`] - no credential was presented; the
///     caller may continue as an anonymous request when policy allows.
///   * [`AuthOutcome::InvalidCredential`] - a credential WAS presented but
///     failed validation (expired JWT, revoked / deactivated API token,
///     wrong basic-auth password, etc.). RFC 7235 calls for 401 here — and
///     for off-boarding (issue #1371) it is load-bearing: silently
///     downgrading a deactivated user's still-cached API token to "no auth"
///     means the user's token continues to receive public-only responses
///     instead of being unambiguously rejected, which masks the
///     deactivation and weakens the security posture.
///
/// Use [`try_resolve_auth_outcome`] to obtain this tri-state result.
#[derive(Debug)]
pub(crate) enum AuthOutcome {
    Resolved(AuthExtension),
    NoCredential,
    InvalidCredential,
    /// A credential was presented and is well-formed, but validation could
    /// not be completed because the bcrypt-bound auth-concurrency cap is
    /// saturated (see `auth_service::acquire_auth_permit_for_bcrypt`). This
    /// is a transient overload, NOT "wrong password": the correct response
    /// is a retryable 503, never a 401. Collapsing it into `InvalidCredential`
    /// is what made `twine upload` fail in the release gate under parallel
    /// load (a curl -u upload with byte-identical credentials passed because
    /// it did not coincide with a saturated cap); twine does not retry on
    /// 401 but does on 503.
    Overloaded,
}

/// Resolve a possibly-missing credential into an [`AuthOutcome`].
///
/// Preserves the distinction between "no credential presented", "credential
/// presented but invalid", and "transiently overloaded" so callers can return
/// 401 on invalid, 503 on overload, and continue as anonymous only on the
/// no-credential case — rather than silently collapsing all three.
///
/// Decision tree:
///   * `ExtractedToken::None` -> `NoCredential` (anonymous request)
///   * `ExtractedToken::Invalid` -> `InvalidCredential` (malformed Authorization
///     header; the client explicitly attempted to authenticate)
///   * `ExtractedToken::Bearer` / `ApiKey` / `Basic` ->
///     - `Resolved(ext)` on any successful path
///     - `InvalidCredential` if every validation attempt failed
///
/// `allow_basic_api_token` controls the ONE difference between the format/registry
/// callers and the management-API (/api/v1) callers: whether an API token is
/// accepted as the HTTP Basic *password*.
///   * `true`  — `repo_visibility_middleware` (npm/maven/pypi/v2/… format
///     endpoints): pip-netrc / Artifactory-style `username:<api_token>` Basic
///     auth resolves to the token owner (the #2786 customer need).
///   * `false` — `optional_auth_middleware` / `admin_middleware` (/api/v1/*):
///     a Basic password is ONLY ever a bcrypt `username:password`. An API token
///     is refused as the Basic password, enforcing the openapi.rs contract that
///     API tokens never authenticate as Basic on the management API (#2806).
///
/// Bearer `<api_token>`, `X-Api-Key`, JWT-as-password, and real bcrypt
/// `username:password` logins are unaffected in BOTH modes. The discrimination is
/// per-middleware (structural), never request-path string matching — axum's
/// nest-prefix stripping makes path matching unreliable here.
pub(crate) async fn try_resolve_auth_outcome(
    auth_service: &AuthService,
    extracted: ExtractedToken<'_>,
    allow_basic_api_token: bool,
) -> AuthOutcome {
    match extracted {
        ExtractedToken::Bearer(token) => {
            // See `auth_middleware` for why this is the async variant. Same
            // rationale: optional-auth routes still need to reject pre-change
            // tokens across replicas (#1173).
            if let Ok(claims) = auth_service.validate_access_token_async(token).await {
                return AuthOutcome::Resolved(AuthExtension::from(claims));
            }
            match validate_api_token_with_scopes(auth_service, token).await {
                Ok(ext) => return AuthOutcome::Resolved(ext),
                // A transient bcrypt-capacity shed must surface as 503, not
                // 401. See `AuthOutcome::Overloaded`.
                Err(TokenAuthError::Overloaded) => return AuthOutcome::Overloaded,
                Err(TokenAuthError::Invalid) => {}
            }
            // Some package managers (npm, cargo, goproxy) send Bearer tokens
            // that are base64-encoded `username:password` rather than JWTs or
            // API keys. Try decoding as credentials before giving up.
            if let Some((username, password)) = decode_basic_credentials(token) {
                match auth_service.authenticate(&username, &password).await {
                    Ok((user, _)) => return AuthOutcome::Resolved(AuthExtension::from(user)),
                    // A transient bcrypt-capacity shed must surface as 503, not
                    // 401. See `AuthOutcome::Overloaded`.
                    Err(AppError::ServiceUnavailable(_)) => return AuthOutcome::Overloaded,
                    Err(_) => {}
                }
            }
            AuthOutcome::InvalidCredential
        }
        ExtractedToken::ApiKey(token) => {
            match validate_api_token_with_scopes(auth_service, token).await {
                Ok(ext) => AuthOutcome::Resolved(ext),
                // See `AuthOutcome::Overloaded`: saturated bcrypt cap is a
                // retryable 503, never a 401.
                Err(TokenAuthError::Overloaded) => AuthOutcome::Overloaded,
                Err(TokenAuthError::Invalid) => AuthOutcome::InvalidCredential,
            }
        }
        ExtractedToken::Basic(encoded) => {
            let Some((username, password)) = decode_basic_credentials(encoded) else {
                return AuthOutcome::InvalidCredential;
            };
            // Try bcrypt username/password auth first
            match auth_service.authenticate(&username, &password).await {
                Ok((user, _)) => return AuthOutcome::Resolved(AuthExtension::from(user)),
                // A transient bcrypt-capacity shed must surface as 503, not a
                // 401. Without this, twine (which sends standard Basic auth)
                // gets a spurious 401 under parallel-suite load and aborts,
                // while a single curl -u upload with the same credentials
                // succeeds. See `AuthOutcome::Overloaded`.
                Err(AppError::ServiceUnavailable(_)) => return AuthOutcome::Overloaded,
                // A pool-acquire timeout is a retryable 503, never a 401.
                // Short-circuit here so a saturated pool does not pay a second
                // acquire-timeout on the API-token fallback below before the
                // classifier reaches the same conclusion (#2125). See
                // `AuthOutcome::Overloaded`.
                Err(ref e) if e.is_pool_timeout() => return AuthOutcome::Overloaded,
                Err(_) => {}
            }
            // Try treating the password as a short-lived JWT access token.
            // This enables CI/CD keyless flows (e.g. OIDC token exchange) where
            // package managers like Maven, pip/twine, and Helm send the AK access
            // token as the Basic auth password.
            if let Ok(claims) = auth_service.validate_access_token_async(&password).await {
                return AuthOutcome::Resolved(AuthExtension::from(claims));
            }
            // Fall back to treating the password as an API token — compatible with
            // pip netrc / Artifactory-style `token:<api_token>` credential format.
            //
            // Only the format/registry endpoints (`repo_visibility_middleware`)
            // opt into this via `allow_basic_api_token=true`. The /api/v1
            // management callers (`optional_auth_middleware`, `admin_middleware`)
            // pass `false`, so an API token presented as a Basic password there is
            // refused (falls through to `InvalidCredential`), honouring the
            // openapi.rs contract (#2806). Bearer/X-Api-Key token auth and
            // bcrypt/JWT Basic auth above are unaffected.
            if !allow_basic_api_token {
                return AuthOutcome::InvalidCredential;
            }
            match validate_api_token_with_scopes(auth_service, &password).await {
                Ok(ext) => AuthOutcome::Resolved(ext),
                // The token fallback also burns a bcrypt verify under the
                // same process-wide cap; preserve the shed as Overloaded so
                // pip-netrc-style `token:<api_token>` clients get the
                // retryable 503, not a spurious 401.
                Err(TokenAuthError::Overloaded) => AuthOutcome::Overloaded,
                Err(TokenAuthError::Invalid) => AuthOutcome::InvalidCredential,
            }
        }
        ExtractedToken::None => AuthOutcome::NoCredential,
        ExtractedToken::Invalid => AuthOutcome::InvalidCredential,
    }
}

// ---------------------------------------------------------------------------
// Download ticket auth (?ticket= query param)
// ---------------------------------------------------------------------------

/// Extract the value of a `ticket` query parameter from a URI's query string.
///
/// Returns `None` when no query string is present, no `ticket` key exists, or
/// the value is empty. Repeated `ticket=` keys take the first occurrence.
/// Performs simple percent-decoding of `+` -> space and `%XX` byte escapes; the
/// ticket itself is hex (no special characters), but query-decoding keeps
/// behaviour consistent with HTTP clients that always encode.
pub(crate) fn extract_ticket_from_query(query: Option<&str>) -> Option<String> {
    let q = query?;
    for pair in q.split('&') {
        let mut it = pair.splitn(2, '=');
        let key = it.next()?;
        if key != "ticket" {
            continue;
        }
        let raw = it.next().unwrap_or("");
        if raw.is_empty() {
            return None;
        }
        // Minimal percent-decoding sufficient for hex tickets.
        let mut out = String::with_capacity(raw.len());
        let bytes = raw.as_bytes();
        let mut i = 0;
        while i < bytes.len() {
            let b = bytes[i];
            if b == b'+' {
                out.push(' ');
                i += 1;
            } else if b == b'%' && i + 2 < bytes.len() {
                let hi = (bytes[i + 1] as char).to_digit(16);
                let lo = (bytes[i + 2] as char).to_digit(16);
                match (hi, lo) {
                    (Some(h), Some(l)) => {
                        out.push(((h * 16 + l) as u8) as char);
                        i += 3;
                    }
                    _ => {
                        out.push(b as char);
                        i += 1;
                    }
                }
            } else {
                out.push(b as char);
                i += 1;
            }
        }
        return Some(out);
    }
    None
}

/// HTTP methods that download tickets are allowed to authenticate.
///
/// Tickets are minted for downloads/streams only. Any write operation
/// (POST, PUT, PATCH, DELETE) authenticated by a ticket must be rejected
/// even when the underlying user has write permission, because the ticket
/// embeds no scope information and the calling client may be a browser
/// `<a href>` or `EventSource` that the user did not consent to use for
/// mutations.
fn ticket_method_allowed(method: &Method) -> bool {
    matches!(*method, Method::GET | Method::HEAD)
}

/// Decide whether a ticket bound to `bound_path` may authenticate a request
/// for `request_path`.
///
/// A ticket with `bound_path = None` authenticates any read path the minting
/// user can reach (legacy behaviour). A ticket with `bound_path = Some(p)`
/// authenticates only requests whose URL path equals `p`. We compare by exact
/// match to keep the policy auditable; callers that want a directory-prefix
/// must mint one ticket per resource.
fn ticket_path_allowed(bound_path: Option<&str>, request_path: &str) -> bool {
    match bound_path {
        None => true,
        Some(p) => p == request_path,
    }
}

/// Resolve a download ticket to an [`AuthExtension`] without consuming it.
///
/// Wraps [`AuthConfigService::validate_download_ticket`], which atomically
/// deletes the ticket on success (single-use enforcement) and rejects expired
/// tickets via `expires_at > NOW()`. After the ticket is consumed, the
/// owning user is loaded so the resulting extension carries the same identity
/// downstream handlers see for any other auth method.
async fn try_resolve_ticket_auth(
    db: &sqlx::PgPool,
    ticket: &str,
    method: &Method,
    request_path: &str,
) -> Option<AuthExtension> {
    if !ticket_method_allowed(method) {
        return None;
    }

    let (user_id, _purpose, resource_path) =
        crate::services::auth_config_service::AuthConfigService::validate_download_ticket(
            db, ticket,
        )
        .await
        .ok()?;

    if !ticket_path_allowed(resource_path.as_deref(), request_path) {
        // Ticket has been consumed by validate_download_ticket; treat the
        // mismatch as an authentication failure so the client cannot reuse
        // the same ticket against a different path.
        //
        // Trade-off: a mistyped path by a legitimate client will burn the
        // ticket and the client must mint a new one. We accept this cost
        // because single-use is the security invariant we cannot weaken
        // without breaking the threat model (a stolen ticket adversary
        // would simply replay against the right path).
        //
        // The cleaner alternative is `SELECT then DELETE WHERE ... RETURNING`
        // inside a transaction so wrong-path attempts do not consume. That
        // is a follow-up change; not in this PR because the existing
        // single-statement DELETE-RETURNING is the only thing that gives
        // us atomic single-use under concurrent retry.
        return None;
    }

    // Load the owning user. We block deactivated users so a revoked account
    // cannot keep downloading via outstanding tickets, but we honour service
    // accounts and not-yet-rotated passwords because the ticket itself is
    // the proof of intent: the JWT session that minted it had whatever
    // rights the user had at mint time.
    //
    // Uses `sqlx::query_as::<_, User>` rather than the `query_as!` macro so
    // adding the ticket-consumer middleware does not require regenerating
    // the offline SQLx query cache.
    let user: User = sqlx::query_as::<_, User>(
        r#"
        SELECT
            id, username, email, password_hash, display_name,
            auth_provider, external_id, is_admin, is_active,
            is_service_account, must_change_password,
            totp_secret, totp_enabled, totp_backup_codes, totp_verified_at,
            last_login_at, created_at, updated_at
        FROM users
        WHERE id = $1 AND is_active = true
        "#,
    )
    .bind(user_id)
    .fetch_optional(db)
    .await
    .ok()??;

    let mut ext = AuthExtension::from(user);
    // Tickets are read-only. Drop admin elevation so a ticket minted by an
    // admin cannot be replayed against admin-only routes that happen to
    // accept tickets in their middleware chain. Callers also insert the
    // [`DownloadTicketAuth`] marker extension so write-gating middleware
    // can recognise the request as ticket-authenticated.
    ext.is_admin = false;

    // Scope hardening: `AuthExtension::has_scope` returns `true` only when
    // `scopes` is `None` (action-unrestricted). No handler today calls
    // `has_scope("admin")` for elevation, but a future one could, and a
    // ticket-authenticated request must not silently pass that check. Stamp an
    // empty scope allowlist so any explicit scope check defaults to deny.
    //
    // This intentionally does not modify `is_service_account` or
    // `must_change_password`: a ticket inherits the minter's identity for
    // those flags so downstream handlers see the same view they would for
    // any other auth method. Accepting the inherited identity is the
    // design — the ticket is proof that a session with those flags
    // intentionally minted a download URL.
    ext.is_api_token = true;
    ext.scopes = Some(vec![]);
    Some(ext)
}

/// Snapshot of the request fields needed to authenticate a download ticket.
///
/// Cloned out of the [`Request`] before the async ticket-validation work
/// runs, so the resulting future does not borrow the request. Without this,
/// callers would hold a borrow across `.await` and the middleware future
/// would not be `Send`, which `axum::middleware::from_fn_with_state` requires.
struct TicketRequestParts {
    ticket: String,
    method: Method,
    path: String,
}

fn extract_ticket_request_parts(request: &Request) -> Option<TicketRequestParts> {
    let ticket = extract_ticket_from_query(request.uri().query())?;
    Some(TicketRequestParts {
        ticket,
        method: request.method().clone(),
        path: request.uri().path().to_string(),
    })
}

/// Try to authenticate via a `?ticket=` query param when no header credentials
/// are present (or all of them have failed).
///
/// Returns `Some(ext)` when the ticket is valid, the request method is a
/// read, and the bound path matches. Returns `None` otherwise. The ticket
/// is consumed (single-use) on the validation attempt regardless of whether
/// the request is ultimately allowed.
async fn try_resolve_ticket_for_parts(
    db: &sqlx::PgPool,
    parts: &TicketRequestParts,
) -> Option<AuthExtension> {
    try_resolve_ticket_auth(db, &parts.ticket, &parts.method, &parts.path).await
}

/// Optional authentication middleware - allows unauthenticated requests
///
/// Supports the same authentication schemes as auth_middleware but
/// allows requests without any authentication to proceed.
///
/// Off-boarding semantics (#1371): when the client explicitly presents a
/// credential that fails to validate (expired JWT, revoked or deactivated
/// API token, wrong basic-auth password, malformed Authorization header),
/// the request is rejected with 401 rather than being silently downgraded
/// to anonymous. Without this, a deactivated user whose API token is still
/// in the upstream `validate_api_token` cache (post-#931) would continue to
/// receive 200-with-public-list responses on optional-auth routes for up to
/// `API_TOKEN_CACHE_TTL_SECS` — masking the deactivation and breaking the
/// off-boarding contract. We only short-circuit when no `?ticket=` fallback
/// is available, since download tickets are a legitimate alternative
/// credential for read-only routes.
pub async fn optional_auth_middleware(
    State(auth_service): State<Arc<AuthService>>,
    mut request: Request,
    next: Next,
) -> Response {
    // See `auth_middleware`: the CSRF contract applies wherever a session
    // cookie can authenticate a mutation (#3065).
    if let Some(refusal) = csrf_guard(&request) {
        return refusal;
    }

    let extracted = extract_token(&request);
    // /api/v1 optional-auth route: an API token is NOT accepted as the Basic
    // password (`allow_basic_api_token=false`) — the /api/v1 Basic-auth boundary
    // (#2806). Bearer/X-Api-Key token auth and bcrypt/JWT Basic auth still work.
    let outcome = try_resolve_auth_outcome(&auth_service, extracted, false).await;
    // A transient bcrypt-capacity shed surfaces here as `Overloaded`. Return a
    // retryable 503 immediately rather than silently dropping to anonymous and
    // letting a downstream `require_auth_basic*` turn it into a misleading 401
    // "Authentication required" (the twine-upload gate failure). See
    // `AuthOutcome::Overloaded`.
    if matches!(outcome, AuthOutcome::Overloaded) {
        return service_unavailable_response();
    }
    let credential_invalid = matches!(outcome, AuthOutcome::InvalidCredential);
    let mut auth_ext: Option<AuthExtension> = match outcome {
        AuthOutcome::Resolved(ext) => Some(ext),
        AuthOutcome::NoCredential | AuthOutcome::InvalidCredential => None,
        // Handled above with an early 503 return.
        AuthOutcome::Overloaded => None,
    };

    // If header-based auth produced no identity, fall back to a `?ticket=`
    // query param. Optional-auth routes are typically reads, so a ticket can
    // legitimately stand in for headers (e.g. browser <a href> downloads).
    let mut authed_via_ticket = false;
    if auth_ext.is_none() {
        if let Some(parts) = extract_ticket_request_parts(&request) {
            if let Some(ext) = try_resolve_ticket_for_parts(auth_service.db(), &parts).await {
                auth_ext = Some(ext);
                authed_via_ticket = true;
            }
        }
    }

    // Off-boarding: an explicitly-presented credential that failed validation
    // must produce 401. We allow a ticket to rescue the request because a
    // browser may include a stale Authorization cookie alongside a fresh
    // download ticket — the ticket is what authorizes the read.
    //
    // Header-aware: a browser fetch carrying a stale token must not trigger
    // the native Basic popup over the web UI's own login flow (#2936/#3082);
    // package clients keep the full challenge set.
    if credential_invalid && auth_ext.is_none() {
        return unauthorized_response_for(request.headers());
    }

    request.extensions_mut().insert(auth_ext);
    if authed_via_ticket {
        request.extensions_mut().insert(DownloadTicketAuth);
    }
    next.run(request).await
}

/// Admin-only middleware - requires authenticated admin user
///
/// Supports the same authentication schemes as auth_middleware but
/// additionally requires the user to have admin privileges.
pub async fn admin_middleware(
    State(auth_service): State<Arc<AuthService>>,
    mut request: Request,
    next: Next,
) -> Response {
    // See `auth_middleware`: the CSRF contract applies wherever a session
    // cookie can authenticate a mutation (#3065).
    if let Some(refusal) = csrf_guard(&request) {
        return refusal;
    }

    let extracted = extract_token(&request);

    if matches!(extracted, ExtractedToken::Basic(encoded) if decode_basic_credentials(encoded).is_none())
    {
        return (StatusCode::UNAUTHORIZED, "Invalid Basic auth credentials").into_response();
    }

    // Shared credential resolution (same forms as the other authenticated
    // routes, including CI/CD keyless flows where the AK access token is sent
    // as the Basic-auth password). Use the tri-state outcome so a transient
    // bcrypt-cap or pool-acquire shed surfaces as a retryable 503, never a
    // spurious 401 (#2101/#2125). Admin privilege is enforced below.
    //
    // /api/v1 admin route: an API token is NOT accepted as the Basic password
    // (`allow_basic_api_token=false`) — the /api/v1 Basic-auth boundary (#2806).
    let auth_ext = match try_resolve_auth_outcome(&auth_service, extracted, false).await {
        AuthOutcome::Resolved(ext) => ext,
        AuthOutcome::Overloaded => return service_unavailable_response(),
        AuthOutcome::NoCredential | AuthOutcome::InvalidCredential => {
            let msg = match extracted {
                ExtractedToken::Bearer(_) => "Invalid or expired token",
                ExtractedToken::ApiKey(_) => "Invalid or expired API token",
                ExtractedToken::Basic(_) => "Invalid credentials",
                ExtractedToken::None => "Missing authorization header",
                ExtractedToken::Invalid => "Invalid authorization header format",
            };
            return (StatusCode::UNAUTHORIZED, msg).into_response();
        }
    };

    if !auth_ext.is_admin {
        // Best-effort RBAC-deny audit event (#2366): an authenticated non-admin
        // reaching an admin-only route is exactly the kind of authorization
        // decision an auditor wants recorded. Fire-and-forget so an audit-table
        // outage can never turn a clean 403 into a 500. The attempted path is
        // recorded (never any credential material).
        {
            use crate::services::audit_service::{
                audit_fire_and_forget, AuditAction, AuditEntry, ResourceType,
            };
            let entry = AuditEntry::new(AuditAction::PermissionDenied, ResourceType::User)
                .user(auth_ext.user_id)
                .resource(auth_ext.user_id)
                .actor_name(auth_ext.username.clone())
                .details_typed(
                    crate::services::audit_export::details::AuthDetails::permission_denied(
                        request.uri().path(),
                        request.method().as_str(),
                        "admin_privileges_required",
                    ),
                );
            audit_fire_and_forget(auth_service.db().clone(), entry).await;
        }
        return (StatusCode::FORBIDDEN, "Admin access required").into_response();
    }

    // #3723: the forced rotation applies to admin routes too. Without it a
    // pending admin -- the built-in admin reactivated before its password was
    // ever changed, say -- could use every admin route while `auth_middleware`
    // refused it everywhere else. Same path exemptions, same 428, same
    // `OriginalUri` reasoning as in `auth_middleware`.
    let gate_path = request
        .extensions()
        .get::<OriginalUri>()
        .map(|o| o.0.path().to_string())
        .unwrap_or_else(|| request.uri().path().to_string());
    if !path_exempt_from_password_change(&gate_path)
        && principal_must_change_password(auth_service.db(), auth_ext.user_id).await
    {
        return must_change_password_response();
    }

    request.extensions_mut().insert(auth_ext);
    next.run(request).await
}

/// State for the repo visibility middleware.
#[derive(Clone)]
pub struct RepoVisibilityState {
    pub auth_service: Arc<AuthService>,
    pub db: sqlx::PgPool,
    /// Shared with `AppState::repo_cache` so format-handler resolvers can
    /// reuse the repo metadata fetched here without a second DB round-trip.
    pub repo_cache: RepoCache,
    /// Shared with `AppState::repo_miss_cache`: keys that recently resolved to
    /// no repository row. Middleware-private (no handler reads it) and evicted
    /// alongside `repo_cache`, so a repeated probe of a nonexistent key costs
    /// the same as a repeated probe of an existing one (#3750).
    pub repo_miss_cache: RepoMissCache,
    /// Permission service for fine-grained repository access control.
    pub permission_service: Arc<PermissionService>,
}

/// Decode one hex digit of a percent escape; `None` for non-hex input.
fn percent_hex_val(b: u8) -> Option<u8> {
    match b {
        b'0'..=b'9' => Some(b - b'0'),
        b'a'..=b'f' => Some(b - b'a' + 10),
        b'A'..=b'F' => Some(b - b'A' + 10),
        _ => None,
    }
}

/// Percent-decode a single path segment with the same semantics axum's
/// `PercentDecodedStr` applies to `Path<...>` route params: `%XX` escapes
/// become their byte, everything else (including `+`, which is NOT a space in
/// a path) stays literal, and the decoded bytes must be valid UTF-8.
///
/// Returns `None` when the encoding is malformed (truncated or non-hex
/// escape) or the decoded bytes are not UTF-8 — the same conditions under
/// which axum rejects the route-param extraction, so the caller must treat
/// the segment as unresolvable rather than guessing at a key. The borrowed
/// fast path avoids any allocation for the overwhelmingly common case of a
/// segment with no `%` at all.
fn percent_decode_path_segment(segment: &str) -> Option<Cow<'_, str>> {
    if !segment.as_bytes().contains(&b'%') {
        return Some(Cow::Borrowed(segment));
    }
    let bytes = segment.as_bytes();
    let mut decoded = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'%' => {
                let hi = percent_hex_val(*bytes.get(i + 1)?)?;
                let lo = percent_hex_val(*bytes.get(i + 2)?)?;
                decoded.push((hi << 4) | lo);
                i += 3;
            }
            b => {
                decoded.push(b);
                i += 1;
            }
        }
    }
    String::from_utf8(decoded).ok().map(Cow::Owned)
}

/// Extract the repository key from a format handler request path.
///
/// Format routes are nested as `/{format}/{repo_key}/...`, so the repo key
/// is the second path segment (e.g. `/pypi/my-repo/simple/` -> `"my-repo"`).
///
/// The segment is percent-DECODED before it is returned (GHSA-fv45-mwhh-q23r):
/// axum's `Path<String>` extraction percent-decodes route params, so the
/// handler resolves the decoded key (`/maven/privat%65/...` -> `"private"`).
/// Evaluating the RAW segment here instead made the DB lookup miss every
/// percent-encoded spelling of a real key and dropped the request into the
/// no-repo branch, which let any authenticated caller through with no
/// visibility/scope/ACL check — an authenticated cross-tenant read of any
/// private repo. Decoding with the same per-segment semantics
/// ([`percent_decode_path_segment`]) guarantees the middleware and the
/// handler always evaluate the SAME key.
pub(crate) fn extract_repo_key(path: &str) -> Cow<'_, str> {
    let trimmed = path.trim_start_matches('/');
    let mut segments = trimmed.split('/');
    // Format prefix (pypi, npm, maven, ...).
    let format = segments.next().unwrap_or("");
    // Conda token channels embed the credential in the URL path:
    //   /conda/t/<TOKEN>/<repo_key>/<subdir>/...
    // The generic "skip one prefix segment" rule would return "t" as the repo
    // key (the conda token router is mounted at /conda/t), so the visibility
    // middleware would resolve a nonexistent repo and 401 an otherwise valid
    // token-channel read. Skip the `t/<TOKEN>` pair for conda token URLs so the
    // actual repository key is returned.
    if format == "conda" && segments.clone().next() == Some("t") {
        // Only a real token channel carries the repository key AFTER the
        // credential (`/conda/t/<TOKEN>/<repo_key>/...`). A two-segment
        // `/conda/t/<route>` — `/conda/t/upload`, `/conda/t/channeldata.json`,
        // `/conda/t/notices.json` — is the PLAIN conda router serving a
        // repository whose key is literally `t`, and skipping the pair there
        // yields an empty key for a request that does name a repository.
        // Only skip when a segment actually follows the token.
        let mut after_token = segments.clone();
        after_token.next(); // "t"
        after_token.next(); // "<TOKEN>"
        if after_token.next().is_some() {
            segments.next(); // "t"
            segments.next(); // "<TOKEN>"
        }
    }
    // WASM plugin proxy routes are nested as
    //   /ext/<format_key>/<repo_key>/...
    // so the repository key is the THIRD path segment, not the second
    // (GHSA-9rqp-mgmw-5879). Returning the second segment (the plugin format
    // key) made the visibility middleware resolve a nonexistent repo and fall
    // into its no-repo branch: anonymous callers were 401'd, but ANY
    // authenticated caller passed through with no visibility/permission check
    // on the actual target repo — including private repos. Skip the
    // format-key segment so the real repository key is evaluated.
    if format == "ext" {
        segments.next(); // "<format_key>"
    }
    // Two format routers are ALSO mounted under an `/api` prefix, matching the
    // URL shape their clients build:
    //   /api/cargo/<repo_key>/...    sparse index (#3000)
    //   /api/helm/<repo_key>/charts  ChartMuseum cm-push (#2941)
    // Those paths are `/api/<format>/<repo_key>/...`, so the generic rule
    // returned the literal "cargo"/"helm" as the key, nothing resolved, and
    // the visibility middleware answered from its no-repo branch — 401 for
    // anonymous callers, existence-hiding 404 for a valid credential. Both
    // aliases were mounted but dead. Skip the `/api` prefix for exactly those
    // two format names so the real repository key is evaluated; every other
    // `/api` path, `/api/v1/...` included, keeps its second segment.
    if format == "api" && matches!(segments.clone().next(), Some("cargo" | "helm")) {
        segments.next(); // "<format>"
    }
    let raw = segments.next().unwrap_or("");
    match percent_decode_path_segment(raw) {
        Some(decoded) => decoded,
        // Malformed percent-encoding or non-UTF-8 bytes: keep the raw
        // segment. A repository key can never contain '%' (the charset is
        // alphanumeric plus `-`, `_`, `.`), so the lookup misses and the
        // request fails closed in the no-repo branch — which is also what
        // axum's own extraction rejection produces downstream.
        None => Cow::Borrowed(raw),
    }
}

/// Extract the credential from a conda token-channel URL path.
///
/// Conda clients embed the token directly in the path as
/// `/conda/t/<TOKEN>/<repo_key>/...` (configured in `.condarc`). This
/// credential is invisible to [`extract_token`], which only inspects headers
/// and cookies, so without this helper the visibility middleware treats an
/// authenticated token-channel request as anonymous and rejects reads of
/// private channels. Returns `None` for any non-conda-token path or an empty
/// token segment.
pub(crate) fn extract_conda_url_token(path: &str) -> Option<&str> {
    let trimmed = path.trim_start_matches('/');
    let mut segments = trimmed.split('/');
    if segments.next()? != "conda" {
        return None;
    }
    if segments.next()? != "t" {
        return None;
    }
    let token = match segments.next() {
        Some(token) if !token.is_empty() => token,
        _ => return None,
    };
    // A token channel carries the repository key AFTER the credential
    // (`/conda/t/<TOKEN>/<repo_key>/...`). With nothing after it, the path is
    // the plain conda route for a repository whose key is literally `t`
    // (`/conda/t/upload`, `/conda/t/channeldata.json`) and that route segment
    // is not a credential — treating it as one made an anonymous read of such
    // a repository fail with 401 for an *invalid credential* it never sent.
    // Same shape test `extract_repo_key` applies to the matching skip.
    segments.next()?;
    Some(token)
}

/// Is `path` the NuGet package-push route (`/nuget/<repo_key>/api/v2/package`)?
///
/// Matched exactly — with or without the trailing slash that `dotnet nuget
/// push` appends to the `PackagePublish/2.0.0` URL it discovers from the v3
/// service index (both spellings are registered in `nuget::router`). Every
/// other NuGet route (service index, search, registration, flat container) and
/// every other format returns `false`, which is what keeps the
/// `X-NuGet-ApiKey` credential fallback from widening the accepted credential
/// surface anywhere else.
fn is_nuget_push_path(path: &str) -> bool {
    let trimmed = path.trim_start_matches('/');
    let mut segments = trimmed.split('/');
    if segments.next() != Some("nuget") {
        return false;
    }
    // Repository key.
    match segments.next() {
        Some(key) if !key.is_empty() => {}
        _ => return false,
    }
    if segments.next() != Some("api") || segments.next() != Some("v2") {
        return false;
    }
    if segments.next() != Some("package") {
        return false;
    }
    // Nothing may follow except the optional trailing slash.
    match segments.next() {
        None => true,
        Some("") => segments.next().is_none(),
        Some(_) => false,
    }
}

/// Extract the credential from the NuGet `X-NuGet-ApiKey` push header.
///
/// `dotnet nuget push --api-key <key>` against a source with no configured
/// credentials sends the key in `X-NuGet-ApiKey` and nothing in
/// `Authorization`. That header is invisible to [`extract_token`], so the
/// visibility middleware treated such a push as anonymous and rejected it with
/// 401 (writes always require auth) *before* `push_package` — which has its own
/// `X-NuGet-ApiKey` fallback — could ever run.
///
/// Scoped to `PUT` on the push route alone: this header is a NuGet client
/// convention, so it must not become a general-purpose credential channel on
/// read routes or on other formats. Returns `None` for any other method, path,
/// or an empty header value.
fn extract_nuget_push_api_key(request: &Request) -> Option<&str> {
    if request.method() != Method::PUT || !is_nuget_push_path(request.uri().path()) {
        return None;
    }
    request
        .headers()
        .get(&X_NUGET_API_KEY)
        .and_then(|v| v.to_str().ok())
        .filter(|v| !v.is_empty())
}

/// Resolve the request credential for the visibility middleware, falling back
/// to format-specific credential channels when no header/cookie credential is
/// present: the conda token-channel URL, and the NuGet push `X-NuGet-ApiKey`
/// header. Header credentials always take precedence, and an unparseable or
/// invalid fallback credential still fails closed downstream.
pub(crate) fn extract_visibility_token(request: &Request) -> ExtractedToken<'_> {
    let extracted = extract_token(request);
    if !matches!(extracted, ExtractedToken::None) {
        return extracted;
    }
    if let Some(token) = extract_conda_url_token(request.uri().path()) {
        return ExtractedToken::ApiKey(token);
    }
    if let Some(token) = extract_nuget_push_api_key(request) {
        return ExtractedToken::ApiKey(token);
    }
    ExtractedToken::None
}

/// Decide whether a request to a repository should be allowed past the coarse
/// visibility gate.
///
/// Returns `true` when the request should proceed: a repository anyone may read
/// anonymously, or any repository with an authenticated caller. Returns `false`
/// only for an anonymous caller against a repository that is not anonymously
/// readable.
///
/// `internal` and `private` answer identically here, and deliberately so. This
/// gate decides only whether the request reaches the finer checks below; what
/// separates the two is which principals satisfy the ACL baseline once there,
/// not whether an anonymous caller is turned away -- neither admits one.
pub(crate) fn should_allow_repo_access(visibility: RepositoryVisibility, has_auth: bool) -> bool {
    visibility.allows_anonymous_read() || has_auth
}

/// Return true when the HTTP method is a write operation (POST, PUT, PATCH,
/// DELETE). Used by [`repo_visibility_middleware`] to require authentication
/// for uploads and mutations even on public repositories.
fn is_write_method(method: &Method) -> bool {
    matches!(
        *method,
        Method::POST | Method::PUT | Method::PATCH | Method::DELETE
    )
}

/// Is `path` a POST route that is *not* a repository mutation despite using a
/// write HTTP method?
///
/// A handful of format endpoints are `POST` by protocol but are negotiation /
/// credential-exchange steps rather than artifact writes. The method-based
/// mutation gate in [`repo_visibility_middleware`] (#2603 G1) would otherwise
/// reject them with 403 for any caller lacking the repository `write` action,
/// which breaks legitimate reads/logins:
///
/// * **git-lfs batch** — `POST /lfs/<repo_key>/objects/batch` is the mandatory
///   download/upload negotiation. `git lfs pull` issues an `{"operation":
///   "download"}` batch, so a read-only member or a public-repo non-member must
///   be able to reach it. The `batch` handler self-gates uploads: an
///   `{"operation":"upload"}` batch is authorized as a repository `write`
///   in-handler, and the subsequent object `PUT` is write-gated by this same
///   middleware, so exempting the batch POST does not open an upload hole.
/// * **conan authenticate** — `POST /conan/<repo_key>/v2/users/authenticate` is
///   a Basic→JWT credential exchange, not a write. The handler requires a valid
///   credential and mints a scope-ceilinged token; no repository `write` is
///   needed or implied.
/// * **VS Code gallery query** — `POST /vscode/<repo_key>/gallery/extensionquery`
///   is a metadata search protocol request. It neither uploads nor changes AK
///   state, and a public gallery must permit it anonymously for VSCodium and
///   code-server to search extensions.
/// * **PyPI XML-RPC** — `POST /pypi/<repo_key>/pypi` is the legacy PyPI
///   XML-RPC endpoint (`browse`, `list_packages`), a protocol-mandated POST
///   that only reads stored metadata (#3783). JupyterLab's Extension Manager
///   issues it with no credential, so a public index must serve it like a
///   `GET`. It is distinct from the twine upload at `POST /pypi/<repo_key>/`,
///   which stays a write.
///
/// These paths are classified as reads for the *permission* check only. The
/// `#508` write-auth requirement (writes require authentication; anonymous
/// callers get 401) still applies to them independently, so this exemption
/// never loosens the anonymous contract — it only routes the *authenticated*
/// caller through the read/visibility path instead of the deny-by-default
/// write choke-point.
///
/// The narrower question "may an ANONYMOUS caller issue this POST against a
/// public repository?" is answered by [`is_anonymous_readable_format_post`],
/// which is deliberately a strict subset.
fn is_non_mutating_format_post(path: &str) -> bool {
    let trimmed = path.trim_start_matches('/');
    let mut segments = trimmed.split('/');
    match segments.next() {
        // /lfs/<repo_key>/objects/batch
        Some("lfs") => {
            matches!(segments.next(), Some(k) if !k.is_empty())
                && segments.next() == Some("objects")
                && segments.next() == Some("batch")
                && segments.next().is_none()
        }
        // /conan/<repo_key>/v2/users/authenticate
        Some("conan") => {
            matches!(segments.next(), Some(k) if !k.is_empty())
                && segments.next() == Some("v2")
                && segments.next() == Some("users")
                && segments.next() == Some("authenticate")
                && segments.next().is_none()
        }
        // /vscode/<repo_key>/gallery/extensionquery
        Some("vscode") => {
            matches!(segments.next(), Some(k) if !k.is_empty())
                && segments.next() == Some("gallery")
                && segments.next() == Some("extensionquery")
                && segments.next().is_none()
        }
        // /pypi/<repo_key>/pypi (XML-RPC, #3783)
        Some("pypi") => is_pypi_xmlrpc_tail(segments),
        _ => false,
    }
}

/// The strict subset of [`is_non_mutating_format_post`] that a **public**
/// repository must also serve to an **anonymous** caller, i.e. the paths that
/// are exempt from the `#508` anonymous-write 401.
///
/// * **VS Code gallery query** — `POST /vscode/<repo_key>/gallery/extensionquery`
///   is the gallery protocol's *search* verb. VSCodium and code-server issue it
///   with no credential (the client has no way to configure one for a gallery),
///   so a public Remote gallery is unusable without this. It neither uploads nor
///   changes AK state, and the handler is public-Remote-only regardless.
///
/// * **PyPI XML-RPC** — `POST /pypi/<repo_key>/pypi` is a read of stored
///   metadata (#3783). JupyterLab's `PyPIExtensionManager` calls it through
///   `xmlrpc.client.ServerProxy` with no credential, exactly as pip reads
///   `/simple/` anonymously from a public index.
///
/// git-lfs `objects/batch` and conan `users/authenticate` are deliberately NOT
/// here. `batch` is an upload *and* download negotiation whose upload arm mints
/// object hrefs, and `authenticate` is a credential exchange that requires a
/// credential to be useful; both keep the `#508` contract of answering 401 to an
/// anonymous caller. Widening that is a separate decision from shipping a
/// gallery, and would need its own tests.
/// `<repo_key>/pypi` or `<repo_key>/pypi/` — the remaining segments of the
/// PyPI XML-RPC path after the leading `pypi` (#3783). Exactly one optional
/// trailing empty segment is accepted, because `xmlrpc.client.ServerProxy`
/// posts to the configured `base_url` verbatim and operators write it both
/// ways; anything deeper (`/pypi/<repo_key>/pypi/<project>/json` is a GET
/// route) is not this endpoint.
fn is_pypi_xmlrpc_tail<'a>(mut segments: impl Iterator<Item = &'a str>) -> bool {
    matches!(segments.next(), Some(k) if !k.is_empty())
        && segments.next() == Some("pypi")
        && matches!(segments.next(), None | Some(""))
        && segments.next().is_none()
}

fn is_anonymous_readable_format_post(path: &str) -> bool {
    let trimmed = path.strip_prefix('/').unwrap_or(path);
    let mut segments = trimmed.split('/');
    match segments.next() {
        // /vscode/<repo_key>/gallery/extensionquery
        Some("vscode") => {
            matches!(segments.next(), Some(k) if !k.is_empty())
                && segments.next() == Some("gallery")
                && segments.next() == Some("extensionquery")
                && segments.next().is_none()
        }
        // /pypi/<repo_key>/pypi (XML-RPC, #3783)
        Some("pypi") => is_pypi_xmlrpc_tail(segments),
        _ => false,
    }
}

/// True when the request plausibly originates from an interactive web browser
/// rather than a package-manager client (#2936 / #3082).
///
/// Browsers pop up a native credential dialog whenever a 401 carries a
/// `WWW-Authenticate: Basic` challenge — including for `fetch()`/XHR calls
/// made by the web UI — hijacking the login screen with a Basic auth box.
/// Package clients (pip, npm, docker, cargo, maven, …) rely on those
/// challenges to decide how to retry with credentials, so the challenge is
/// only suppressed when the request is identifiably browser-originated:
///
/// * any Fetch Metadata header (`Sec-Fetch-Mode` / `Sec-Fetch-Site`) — these
///   are forbidden request headers that every modern browser attaches to
///   every request (navigations *and* `fetch()`/XHR) in secure contexts, and
///   that no package-manager client sends;
/// * an `Accept` header explicitly listing `text/html` — the classic HTML
///   navigation signal, covering older browsers and plain-HTTP deployments
///   where Fetch Metadata is not sent.
///
/// Pure and header-only so the negotiation is unit-testable.
pub(crate) fn is_browser_request(headers: &HeaderMap) -> bool {
    if headers.contains_key("sec-fetch-mode") || headers.contains_key("sec-fetch-site") {
        return true;
    }
    headers
        .get(axum::http::header::ACCEPT)
        .and_then(|v| v.to_str().ok())
        .is_some_and(|v| v.to_ascii_lowercase().contains("text/html"))
}

/// Build a 401 response with `WWW-Authenticate` challenges for both Basic
/// and Bearer schemes.  Package manager clients use the challenge to decide
/// how to retry with credentials.
///
/// `pub(crate)` so the WASM proxy handler (`/ext/*`) can emit the identical
/// anonymous-denial response as this middleware (GHSA-9rqp-mgmw-5879).
pub(crate) fn unauthorized_response() -> Response {
    challenge_unauthorized_response(true)
}

/// Header-aware variant of [`unauthorized_response`]: browser-originated
/// requests (see [`is_browser_request`]) get a 401 *without* the `Basic`
/// challenge so the browser shows the web UI's login screen instead of a
/// native Basic auth popup (#2936 / #3082). Every other caller — package
/// managers included — receives the identical challenges as before.
pub(crate) fn unauthorized_response_for(headers: &HeaderMap) -> Response {
    challenge_unauthorized_response(!is_browser_request(headers))
}

/// Shared 401 builder. `challenge_basic = false` omits the `Basic` (and the
/// cargo-only `Cargo`) challenge for browser requests, keeping the `Bearer`
/// challenge so the response stays RFC 7235-compliant without triggering the
/// native browser credential dialog (only `Basic` does that).
fn challenge_unauthorized_response(challenge_basic: bool) -> Response {
    let mut builder = Response::builder().status(StatusCode::UNAUTHORIZED);
    if challenge_basic {
        builder = builder.header("WWW-Authenticate", "Basic realm=\"artifact-keeper\"");
    }
    builder = builder.header(
        "WWW-Authenticate",
        "Bearer realm=\"artifact-keeper\", charset=\"UTF-8\"",
    );
    if challenge_basic {
        // Signals cargo 1.67+ to use the Cargo token protocol (sends the token
        // as the raw Authorization header value) rather than aborting on the
        // Basic/Bearer challenges it does not understand. Browsers never speak
        // the cargo protocol, so this challenge is browser-suppressed too.
        builder = builder.header("WWW-Authenticate", "Cargo");
    }
    builder
        .header(axum::http::header::CONTENT_TYPE, "text/plain")
        .body(axum::body::Body::from("Authentication required"))
        .unwrap()
}

/// Build a 503 response for the transient bcrypt-capacity shed
/// (`AuthOutcome::Overloaded`). Carries a `Retry-After: 1` hint so
/// well-behaved clients (twine, cargo, pip) back off and retry instead of
/// aborting the way they would on a 401. Keeping this distinct from
/// `unauthorized_response` is the load-bearing fix for the twine-upload
/// gate failure: a saturated auth cap is "retry shortly", not "wrong
/// password".
///
/// `pub(super)` so the sibling `guest_access_guard` can return the same 503 for
/// an `AuthOutcome::Overloaded` shed instead of collapsing it into a 401.
pub(super) fn service_unavailable_response() -> Response {
    Response::builder()
        .status(StatusCode::SERVICE_UNAVAILABLE)
        .header(axum::http::header::RETRY_AFTER, "1")
        .header(axum::http::header::CONTENT_TYPE, "text/plain")
        .body(axum::body::Body::from(
            "Authentication service is at capacity, retry shortly",
        ))
        .unwrap()
}

/// Build a 403 response for API tokens that lack access to the requested
/// repository.
fn forbidden_repo_response() -> Response {
    Response::builder()
        .status(StatusCode::FORBIDDEN)
        .header(axum::http::header::CONTENT_TYPE, "text/plain")
        .body(axum::body::Body::from(
            "Token does not have access to this repository",
        ))
        .unwrap()
}

/// Build a 403 response when fine-grained permission rules deny access.
fn forbidden_permission_response() -> Response {
    Response::builder()
        .status(StatusCode::FORBIDDEN)
        .header(axum::http::header::CONTENT_TYPE, "text/plain")
        .body(axum::body::Body::from(
            "You do not have permission to perform this action on this repository",
        ))
        .unwrap()
}

/// Build a 404 response that hides the existence of a private repository the
/// caller is not authorized to see. Mirrors the REST `require_visible` helper
/// (which returns `NotFound`) so the native-protocol and REST paths give the
/// same existence-hiding answer for an inaccessible private repo.
fn not_found_response() -> Response {
    Response::builder()
        .status(StatusCode::NOT_FOUND)
        .header(axum::http::header::CONTENT_TYPE, "text/plain")
        .body(axum::body::Body::from("Repository not found"))
        .unwrap()
}

/// Map an HTTP method to a permission action string.
///
/// Used by [`repo_visibility_middleware`] to determine the required permission
/// action when fine-grained rules exist for a repository.
pub(crate) fn action_for_method(method: &Method) -> &'static str {
    match *method {
        Method::GET | Method::HEAD | Method::OPTIONS => "read",
        Method::PUT | Method::POST | Method::PATCH => "write",
        Method::DELETE => "delete",
        _ => "read",
    }
}

/// Whether a fine-grained ACL check may be skipped because the repository is
/// public and the requested action is a read.
///
/// On a public repository, anonymous callers are granted read access by the
/// visibility check (see [`should_allow_repo_access`]) without ever consulting
/// permission rules. Authenticated callers must therefore receive *at least*
/// that same read allowance: enforcing the ACL against them when rules exist
/// would make an authenticated principal strictly less privileged than an
/// anonymous one on the same public repository (#2329).
///
/// This applies only to the `read` action. Write and delete actions are still
/// fully governed by the ACL when rules exist, and repositories that are not
/// anonymously readable never take this shortcut.
///
/// Use this ONLY where the question is the *anonymous* baseline -- the token
/// repository-scope ceilings (#3648, #3704). An `internal` repository has no
/// anonymous baseline to have fallen below (an anonymous caller is turned away
/// by [`should_allow_repo_access`]), so it must NOT be exempted from a scope
/// ceiling. For the authenticated baseline, use
/// [`authenticated_read_satisfies_acl`] instead.
pub(crate) fn public_read_satisfies_acl(visibility: RepositoryVisibility, action: &str) -> bool {
    visibility.allows_anonymous_read() && action == "read"
}

/// Whether a fine-grained ACL check may be skipped for an ALREADY-AUTHENTICATED
/// caller because the repository's visibility grants them a read baseline.
///
/// This is the #2329 argument applied to the full visibility axis: a caller must
/// never be left below the baseline their repository already grants them. On a
/// `public` repository that baseline comes from anonymous access; on an
/// `internal` one it comes from being a resolved principal at all. Enforcing the
/// ACL against them where rules happen to exist would make holding a credential
/// strictly worse than the baseline in both cases.
///
/// Reads only, exactly as [`public_read_satisfies_acl`]: writes and deletes stay
/// fully governed by `check_repository_action`, deny-by-default (#2603 G1), and
/// `private` never takes this shortcut.
///
/// Callers MUST have established that the request is authenticated. Every
/// current call site sits inside an `auth_ext`/`claims` binding, which is why
/// this takes no `has_auth` argument -- passing one would invite calling it on
/// the anonymous path, where it would grant an `internal` repository to the
/// world.
pub(crate) fn authenticated_read_satisfies_acl(
    visibility: RepositoryVisibility,
    action: &str,
) -> bool {
    visibility.allows_authenticated_read() && action == "read"
}

/// Middleware that enforces repository visibility on format handler routes.
///
/// For routes whose first path segment is a repository key, this middleware
/// checks whether the repository is public. If it is not public, the request
/// must carry a valid authentication token; otherwise a 401 is returned so
/// that package manager clients can retry with credentials.
///
/// Additionally, this middleware enforces two policies that individual format
/// handlers must not need to remember:
///
/// 1. **Write operations require authentication** regardless of repository
///    visibility. Even public repos must not accept anonymous uploads, deletes,
///    or mutations. (Fixes #508)
///
/// 2. **API token repo scope is enforced**: when the authenticated token
///    carries `allowed_repo_ids`, the target repository must be in that set.
///    Without this check, a token scoped to repo A could access repo B.
///    (Fixes #504)
pub async fn repo_visibility_middleware(
    State(vis_state): State<RepoVisibilityState>,
    mut request: Request,
    next: Next,
) -> Response {
    // Extract the repository key segment. The path here is the RAW request
    // URI; `extract_repo_key` percent-decodes the segment so `repo_key` is
    // the same decoded value the handler's `Path<String>` extraction will
    // resolve (GHSA-fv45-mwhh-q23r).
    let path = request.uri().path().to_string();
    let repo_key = extract_repo_key(&path);

    if repo_key.is_empty() {
        // An empty `:repo_key` segment names no repository: repository keys are
        // non-empty by construction, so no row can ever match and no format
        // route can serve anything here. Every format route reaches this branch
        // when its key segment is empty (`/npm//pkg`, `/maven//`,
        // `/pypi//simple/`, `/api/cargo//ve/ri/x`).
        //
        // Answer the existence-hiding 404 directly instead of running the
        // handler. Two properties depend on not falling through:
        //
        // 1. No unauthenticated 500. The handler binds
        //    `Extension<Option<AuthExtension>>`, and axum answers a missing
        //    extension with a 500 that prints the extension's type path (#3443
        //    / #3444). Never invoking the handler closes that without having to
        //    inject an extension for it.
        //
        // 2. No request body is read for a caller this middleware has not
        //    authorized. `next.run` hands the request to the handler, whose
        //    extractors run in order, so a body extractor (`Bytes`, `Multipart`,
        //    ...) buffers the WHOLE upload before the handler's own auth check
        //    can reject it. Falling through therefore gave an anonymous caller a
        //    `MAX_UPLOAD_SIZE`-per-request (10 GiB default) heap allocation on
        //    every format prefix, with no credential and no repository — the
        //    write gate below, which would have refused it, sits after this
        //    branch. Returning here rejects before the body is touched.
        //
        // The empty key carries no information about which repositories exist,
        // so a flat 404 leaks nothing (contrast the non-empty no-repo branch
        // below, which mirrors the private-repo 401 to close the #1808
        // existence oracle).
        return not_found_response();
    }

    // Check the shared repo cache first to avoid a DB round-trip on every
    // request.  The cache is populated with full repo metadata so that
    // format-handler resolvers (e.g. resolve_cargo_repo) can reuse it
    // without issuing their own DB lookup.
    let cached = {
        let cache = vis_state.repo_cache.read().await;
        cache.get(&*repo_key).and_then(|(entry, at)| {
            if at.elapsed().as_secs() < REPO_CACHE_TTL_SECS {
                Some(entry.clone())
            } else {
                None
            }
        })
    };

    // #3750: a key that recently resolved to NO repository is remembered too,
    // for the same TTL. Without this the positive cache alone made an existing
    // repository the caller may not see cheaper on the second probe than a
    // nonexistent one (no query vs. a fresh `SELECT` each time) — a timing
    // oracle for repository existence on every native read surface, which the
    // byte-identical responses of #1808/#3709/#3717/#3728 otherwise close.
    // A fresh tombstone takes the no-repository path below without a query, so
    // both cases are answered from memory on repeat.
    let negatively_cached = cached.is_none() && {
        let miss_cache = vis_state.repo_miss_cache.read().await;
        miss_cache
            .get(&*repo_key)
            .is_some_and(|at| at.elapsed().as_secs() < REPO_CACHE_TTL_SECS)
    };

    let repo = match cached {
        Some(r) => Some(r),
        None if negatively_cached => None,
        None => {
            // Cache miss: fetch full repo metadata in one query so we can
            // populate the cache for both this middleware and downstream
            // handlers.  Uses sqlx::query() (not the macro) so no new entry
            // in the sqlx offline-query cache is required.
            use sqlx::Row;
            let row = sqlx::query(
                "SELECT id, format::text as format, repo_type::text as repo_type, \
                 upstream_url, storage_backend, storage_path, visibility, \
                 promotion_only, age_gate_enabled, age_gate_min_age_days, age_gate_mode, \
                 curation_enabled, curation_default_action, \
                 (SELECT value FROM repository_config \
                  WHERE repository_id = repositories.id \
                  AND key = 'index_upstream_url') AS index_upstream_url \
                 FROM repositories WHERE key = $1",
            )
            .bind(&*repo_key)
            .fetch_optional(&vis_state.db)
            .await;
            // A query ERROR is not evidence that the key names no repository,
            // so it must not be negative-cached (#3750): otherwise one
            // database blip would pin a real repository out of sight for a
            // whole TTL. `.ok().flatten()` keeps the pre-existing answer for
            // this request (an error falls into the no-repo branch below);
            // only a genuine `Ok(None)` earns a tombstone.
            let query_succeeded = row.is_ok();
            let row = row.ok().flatten();

            if let Some(r) = row {
                let entry = CachedRepo {
                    id: r.get("id"),
                    format: r.get("format"),
                    repo_type: r.get("repo_type"),
                    upstream_url: r.get("upstream_url"),
                    storage_backend: r.get("storage_backend"),
                    storage_path: r.get("storage_path"),
                    // Fails closed: an unreadable/unknown visibility is
                    // treated as `private`, the narrowest audience, rather
                    // than defaulting a repository open.
                    visibility: r
                        .try_get::<RepositoryVisibility, _>("visibility")
                        .unwrap_or_else(|e| {
                            tracing::error!(
                                error = %e,
                                repo_key = %repo_key,
                                "unreadable repository visibility; failing closed to private"
                            );
                            RepositoryVisibility::Private
                        }),
                    index_upstream_url: r.get("index_upstream_url"),
                    promotion_only: r.get("promotion_only"),
                    age_gate_enabled: r.get("age_gate_enabled"),
                    age_gate_min_age_days: r.get("age_gate_min_age_days"),
                    age_gate_mode: r.get("age_gate_mode"),
                    curation_enabled: r.get("curation_enabled"),
                    curation_default_action: r.get("curation_default_action"),
                };
                // Populate the shared cache; evict stale entries on write.
                {
                    let mut cache = vis_state.repo_cache.write().await;
                    cache.retain(|_, (_, at)| at.elapsed().as_secs() < REPO_CACHE_TTL_SECS);
                    cache.insert(repo_key.to_string(), (entry.clone(), Instant::now()));
                }
                Some(entry)
            } else {
                // #3750: remember a confirmed miss for the same TTL, so the
                // next probe of this key is answered from memory like a
                // cached hit.
                //
                // Unlike the positive cache the key space here is whatever a
                // caller types, so the map is bounded explicitly: expired
                // entries are dropped on each write exactly as above, and if
                // the map is still over `REPO_MISS_CACHE_MAX_ENTRIES` it is
                // cleared outright. Clearing costs each cleared key one more
                // `SELECT` on its next probe — the pre-#3750 behaviour — which
                // is the right way for a memory bound to fail.
                //
                // The sweep runs even when the query failed, so the entry this
                // request just aged out cannot linger until the next confirmed
                // miss happens to sweep it; only the INSERT is conditional.
                {
                    let mut miss_cache = vis_state.repo_miss_cache.write().await;
                    miss_cache.retain(|_, at| at.elapsed().as_secs() < REPO_CACHE_TTL_SECS);
                    if miss_cache.len() > REPO_MISS_CACHE_MAX_ENTRIES {
                        miss_cache.clear();
                    }
                    if query_succeeded {
                        miss_cache.insert(repo_key.to_string(), Instant::now());
                    }
                }
                None
            }
        }
    };

    // No repository row matched this (decoded) key. Every format route is
    // `/{format}/{repo_key}/...`, so a non-empty key always NAMES a repo;
    // the only key-less paths (format roots such as `/` or `/pypi`) already
    // returned early above. This branch therefore decides how a request that
    // can never resolve a repo is answered, per credential state:
    //
    // - transient auth-capacity shed -> retryable 503;
    // - an explicitly-presented credential that failed validation -> 401
    //   (off-boarding, #1371: honour the deactivation even before we know
    //   whether the repo exists);
    // - no credential at all -> the same 401 + `WWW-Authenticate` challenge
    //   an existing *private* repo produces (#1808, the anonymous
    //   repo-existence oracle);
    // - a VALID credential -> the existence-hiding 404 below
    //   (GHSA-fv45-mwhh-q23r).
    let Some(repo) = repo else {
        let extracted = extract_visibility_token(&request);
        // Format/registry endpoint: preserve pip-netrc / Artifactory-style
        // `username:<api_token>` Basic auth (`allow_basic_api_token=true`, #2786).
        let outcome = try_resolve_auth_outcome(&vis_state.auth_service, extracted, true).await;
        // Transient bcrypt-capacity shed -> retryable 503 (see
        // `AuthOutcome::Overloaded`), never a 401.
        if matches!(outcome, AuthOutcome::Overloaded) {
            return service_unavailable_response();
        }
        let credential_invalid = matches!(outcome, AuthOutcome::InvalidCredential);
        // #1808: Close the anonymous repo-existence oracle. An existing
        // *private* repo returns 401 to an anonymous caller (visibility check
        // below), so a nonexistent repo must not return the handler's 404 to
        // that same caller -- the differing status would leak which repo keys
        // exist. Mirror the existing-private response: emit the identical
        // 401 + `WWW-Authenticate` challenge whenever no credential is
        // presented, so the status, body, and headers are byte-identical for
        // existing-private and nonexistent keys. This also preserves
        // package-manager 401-retry semantics (clients still see the
        // challenge and can retry with credentials).
        let no_credential = matches!(outcome, AuthOutcome::NoCredential);
        let auth_ext: Option<AuthExtension> = match outcome {
            AuthOutcome::Resolved(ext) => Some(ext),
            AuthOutcome::NoCredential | AuthOutcome::InvalidCredential => None,
            AuthOutcome::Overloaded => None,
        };
        if credential_invalid && auth_ext.is_none() {
            return unauthorized_response();
        }
        if no_credential {
            return unauthorized_response();
        }
        // GHSA-fv45-mwhh-q23r: a VALID credential whose (decoded) repo key
        // matches no row must NOT fall through to the handler. Before this
        // fix the request continued with no visibility/scope/ACL check at
        // all; combined with the raw-segment lookup, `/{format}/privat%65/...`
        // matched nothing here while the handler resolved the decoded
        // `private` — an authenticated cross-tenant read of any private repo.
        // Answer with the same existence-hiding 404 an authenticated
        // non-member gets for an EXISTING private repo (`not_found_response`,
        // mirroring REST `require_visible`), so "no such repo" and "repo you
        // may not see" stay indistinguishable for authenticated callers too.
        return not_found_response();
    };

    let visibility = repo.visibility;
    // The VS Code gallery query is a protocol-mandated POST that is purely a
    // metadata search, so it must be reachable anonymously on a public repo.
    // Only that strict subset skips the #508 anonymous-write gate: git-lfs
    // batch and conan authenticate stay write-gated for anonymous callers
    // exactly as before, and are exempted only from the *permission* check
    // further down (`non_mutating_post`).
    let non_mutating_post = is_non_mutating_format_post(&path);
    let anonymous_readable_post =
        request.method() == Method::POST && is_anonymous_readable_format_post(&path);
    let is_write = is_write_method(request.method()) && !anonymous_readable_post;

    // Perform optional auth (shared with optional_auth_middleware). Conda
    // token channels carry the credential in the URL path, so fall back to it
    // when no header/cookie credential is present.
    let extracted = extract_visibility_token(&request);
    // Format/registry endpoint: preserve pip-netrc / Artifactory-style
    // `username:<api_token>` Basic auth (`allow_basic_api_token=true`, #2786).
    let outcome = try_resolve_auth_outcome(&vis_state.auth_service, extracted, true).await;
    // Transient bcrypt-capacity shed -> retryable 503 (see
    // `AuthOutcome::Overloaded`), never a 401.
    if matches!(outcome, AuthOutcome::Overloaded) {
        return service_unavailable_response();
    }
    let credential_invalid = matches!(outcome, AuthOutcome::InvalidCredential);
    let mut auth_ext: Option<AuthExtension> = match outcome {
        AuthOutcome::Resolved(ext) => Some(ext),
        AuthOutcome::NoCredential | AuthOutcome::InvalidCredential => None,
        AuthOutcome::Overloaded => None,
    };
    // `credential_invalid` was captured before the match consumed `outcome`.

    // Fall back to a `?ticket=` query param when no header credentials were
    // supplied or accepted. Tickets are read-only and bound to a path; the
    // helper itself rejects non-read methods, and the `is_write` check below
    // also covers the case where a ticket somehow leaked into a write request.
    let mut authed_via_ticket = false;
    if auth_ext.is_none() {
        if let Some(parts) = extract_ticket_request_parts(&request) {
            if let Some(ext) = try_resolve_ticket_for_parts(&vis_state.db, &parts).await {
                auth_ext = Some(ext);
                authed_via_ticket = true;
            }
        }
    }

    // Off-boarding (#1371): explicit credential presented but invalid (and
    // no rescuing ticket) means 401, not anonymous read.
    if credential_invalid && auth_ext.is_none() {
        return unauthorized_response();
    }

    // Insert auth extension for downstream handlers.
    request.extensions_mut().insert(auth_ext.clone());
    if authed_via_ticket {
        request.extensions_mut().insert(DownloadTicketAuth);
    }

    // #508: Write operations (PUT, POST, PATCH, DELETE) always require
    // authentication, even on public repositories. Without this, unauthenticated
    // upload requests to public repos fall through to the handler which returns
    // 404 (misleading) instead of 401.
    //
    // Tickets must never authorize writes even if the bound path happens to
    // be writable: a ticket is effectively a single-use download URL, not a
    // capability token. Treat ticket-authenticated requests as anonymous for
    // the purpose of write gating.
    let has_write_auth = auth_ext.is_some() && !authed_via_ticket;
    if is_write && !has_write_auth {
        return unauthorized_response();
    }

    // Check visibility: public repos are open for reads, private repos need auth.
    if !should_allow_repo_access(visibility, auth_ext.is_some()) {
        // #1849: an anonymous caller may still hold an anonymous read rule
        // (`principal_type = 'anonymous'`) on this non-public repository —
        // the IP-restricted CI download grant — evaluated against the
        // in-flight request's client IP. This arm is only reachable for a
        // READ: anonymous writes already left by the #508 gate above, and
        // `auth_ext.is_some()` callers answered `true` just now. A denial
        // keeps the identical 401 challenge, so a caller outside the CIDRs
        // cannot tell a conditioned repo from a rules-less one; a lookup
        // error fails closed (denied, not served).
        let anonymous_read_granted = auth_ext.is_none()
            && vis_state
                .permission_service
                .check_anonymous_repository_action(repo.id, "read")
                .await
                .unwrap_or(false);
        if !anonymous_read_granted {
            return unauthorized_response();
        }
    }

    // #504: Enforce API token repository scope. If the token carries an
    // allowed_repo_ids restriction, the target repository must be in that set.
    // Without this, a token scoped to repo A could read/write repo B.
    //
    // #3648: reads of a PUBLIC repository are exempt, via the same
    // `public_read_satisfies_acl` baseline the ACL arm below applies (#2329).
    // The visibility check above serves an anonymous caller a public repo
    // unconditionally, and anonymous callers never reach this branch (no
    // `auth_ext`) — so without the exemption, presenting a repo-scoped
    // credential returned 403 where presenting NO credential returned 200, i.e.
    // a credential granted strictly less access than none. pip surfaced that as
    // "No matching distribution found".
    //
    // Reads only. Writes and deletes keep enforcing the scope unchanged: a
    // token scoped to repo A must still not push to public repo B, which is
    // what REST `require_repo_write_access` (`require_repo_access` before its
    // `is_public` short-circuit) already does on the other side. Private
    // repositories never take this shortcut, so the existence-hiding answer a
    // scoped token gets for an out-of-scope private repo is unchanged.
    //
    // The action is derived the way the permission arm below derives its own
    // (`non_mutating_post`), except that the qualifying subset here is
    // `anonymous_readable_post`, not `non_mutating_post`. That subset
    // (`is_anonymous_readable_format_post`) is defined as the POSTs a PUBLIC
    // repository must serve to an ANONYMOUS caller — today only the VS Code
    // gallery query — which is exactly the baseline this bypass restores: those
    // requests skip the #508 write gate, carry no `auth_ext` when anonymous, and
    // so were served with no credential while a scoped credential got 403.
    // git-lfs `objects/batch` and conan `users/authenticate` are NOT in that
    // subset and stay scope-gated: `batch` is an upload negotiation whose upload
    // arm mints object hrefs, `authenticate` is a credential exchange, and both
    // answer 401 to an anonymous caller under #508 — so neither has an anonymous
    // baseline to have fallen below, and widening them is a separate decision.
    let scope_gate_action = if anonymous_readable_post {
        "read"
    } else {
        action_for_method(request.method())
    };
    if let Some(ref ext) = auth_ext {
        if !public_read_satisfies_acl(visibility, scope_gate_action)
            && !ext.can_access_repo(repo.id)
        {
            // #3717: a READ refused here is always a read of a repository
            // that is NOT anonymously readable -- `private`, or `internal`,
            // whose scope ceiling is deliberately not relaxed (an anonymous
            // caller gets nothing from it, so a scoped credential has no
            // baseline to have fallen below). The public case short-circuited
            // just above. Both hide their existence identically, so it
            // takes the same existence-hiding `not_found_response()` the
            // no-repo branch and both ACL read denials (#3524, #3709) answer.
            // Repository-scoped tokens are self-service, so a 403 here handed
            // any user holding a token to a repository of their own a
            // 200/403/404 existence oracle over every other private key.
            // Writes keep the 403, matching #3524's decision for the ACL arm.
            //
            // "Read" here is the set the ACL arm below calls a read: the
            // method-derived action plus the `non_mutating_post` routes
            // (git-lfs `objects/batch`, conan `users/authenticate`), which
            // that arm reclassifies via the same predicate and, since #3709,
            // denies with this same 404. They stay scope-GATED (the #3648
            // exemption above is not widened); only the shape of a denial
            // that happens either way changes -- and only on a PRIVATE
            // repository. A method-derived read never reaches this point for a
            // public repository (the short-circuit above), but the two POSTs
            // do, and a public repository has no existence to hide: they keep
            // the 403 there, as `test_3648` pins.
            if !visibility.allows_anonymous_read()
                && (scope_gate_action == "read" || non_mutating_post)
            {
                // Same fields and level as the two ACL read denials below, so
                // the operator can still tell this from a missing repository.
                tracing::info!(
                    repository_id = %repo.id,
                    user_id = %ext.user_id,
                    "token repository scope denied read; answering the existence-hiding 404"
                );
                return not_found_response();
            }
            return forbidden_repo_response();
        }
    }

    // Repository permission enforcement (#817 reads, #2603 G1 writes).
    //
    // If the authenticated user is an admin, skip permission checks entirely
    // to preserve backward compatibility and avoid unnecessary DB lookups.
    if let Some(ref ext) = auth_ext {
        if !ext.is_admin {
            // A few POST routes are negotiation / credential-exchange steps, not
            // repository mutations, even though the HTTP method is a write (see
            // `is_non_mutating_format_post`). Classify them as reads so a
            // read-only member or a public-repo non-member can still perform
            // download negotiation / token exchange. The #508 write-auth gate
            // above (401 for anonymous) is unaffected, and actual LFS uploads
            // remain write-gated by the batch handler and the object-PUT path.
            let action = if non_mutating_post {
                "read"
            } else {
                action_for_method(request.method())
            };

            if is_write && !non_mutating_post {
                // #2603 G1: writes and deletes route through the single
                // canonical action choke-point, DENY-BY-DEFAULT. `is_public`
                // confers a read baseline only and never satisfies a write, and
                // a repository with NO fine-grained rules does not fall open —
                // the caller must hold a role assignment carrying the action
                // (or an allowing fine-grained rule, or `admin`), for public
                // and private repositories alike. This closes the rules-less
                // public-repo write hole (any authed caller could PUT/DELETE)
                // and the rules-less private-repo case (a read-only `viewer`
                // member could write/delete). DB error fails closed (503).
                match vis_state
                    .permission_service
                    .check_repository_action(ext.user_id, repo.id, action, false)
                    .await
                {
                    Ok(true) => {}
                    Ok(false) => return forbidden_permission_response(),
                    Err(_) => {
                        tracing::error!("permission check failed: database unreachable");
                        return service_unavailable_response();
                    }
                }
            } else {
                // Reads: preserve the public-anonymous baseline + private
                // membership + fine-grained ACL model (#817 / #2329). For a
                // non-admin user, check whether any permission rules exist for
                // this repository. If no rules exist, fall through to the
                // default access model (the visibility checks above are
                // sufficient for public repos; private repos still require a
                // role assignment). If rules do exist, the user must hold the
                // read action.
                let has_rules = match vis_state
                    .permission_service
                    .has_any_rules_for_target("repository", repo.id)
                    .await
                {
                    Ok(v) => v,
                    Err(_) => {
                        // DB error on permission check: fail closed.
                        tracing::error!("permission check failed: database unreachable");
                        return Response::builder()
                            .status(StatusCode::SERVICE_UNAVAILABLE)
                            .body(axum::body::Body::from(
                                "permission service temporarily unavailable",
                            ))
                            .unwrap();
                    }
                };

                if has_rules {
                    // #2329, applied to the full visibility axis: a caller
                    // must never end up with *less* read access than the
                    // baseline their repository already grants them, merely
                    // because ACL rules happen to exist. On `public` that
                    // baseline is anonymous access; on `internal` it is being a
                    // resolved principal at all. Skip the ACL for reads only;
                    // `private` never takes this shortcut. Anonymous callers
                    // never reach this block (no `auth_ext`), which is what
                    // makes it safe to grant the internal baseline here --
                    // the caller is authenticated by construction.
                    if !authenticated_read_satisfies_acl(visibility, action) {
                        // Check for the specific action first, then fall back to
                        // "admin" which implies all actions (#827 policy compat).
                        // Both calls resolve from the same cached action set, so
                        // the second call is essentially free.
                        //
                        // These two are a CACHED FAST PATH for the common
                        // "an applicable rule names this principal" case, not
                        // the decision itself: `check_permission` reads the
                        // `permissions` table only. The canonical decision is
                        // `check_repository_action` below (#3387/#3452).
                        let allowed = vis_state
                            .permission_service
                            .check_permission(ext.user_id, "repository", repo.id, action, false)
                            .await
                            .unwrap_or(false)
                            || vis_state
                                .permission_service
                                .check_permission(
                                    ext.user_id,
                                    "repository",
                                    repo.id,
                                    "admin",
                                    false,
                                )
                                .await
                                .unwrap_or(false)
                            // #3387/#3452: role assignments are part of the read
                            // decision, exactly as they already are for the
                            // write/delete arm ~40 lines above, for REST reads
                            // (`require_visible` -> `user_can_access_repo` ->
                            // `RepoAccess::READ`) and for virtual members
                            // (`try_authorize_virtual_members`). This branch was
                            // the ONLY read gate in the codebase resolving reads
                            // from `permissions` alone, so the FIRST fine-grained
                            // rule written against a repository — for any
                            // principal, including an unrelated one — silently
                            // revoked native-protocol READ for every principal
                            // whose grant is a `role_assignment` (the creator
                            // auto-grant, `repository-owner`, and the rows
                            // migration 172 wrote on upgrade), while leaving that
                            // same principal's WRITE on the same route intact.
                            // Reproduced as 403 on `GET /maven/{repo}/…` with 201
                            // on `PUT` to the same path and 200 on
                            // `GET /api/v1/repositories/{key}`.
                            //
                            // `check_repository_action` is a strict SUPERSET of
                            // the two calls above (an applicable rule carrying
                            // `action` or `admin` satisfies both), so this can
                            // only widen, never narrow. What it adds is the
                            // codebase's documented rule, in FULL:
                            //
                            //   a) a role assignment carrying `admin` wins over
                            //      everything, including an applicable rule —
                            //      the "durable owner capability" migration 172
                            //      established, OR-ed OUTSIDE the CASE in
                            //      `check_repository_action`;
                            //   b) otherwise an applicable direct/group/project
                            //      rule is authoritative for the principals it
                            //      names;
                            //   c) otherwise the principal keeps its role
                            //      capabilities.
                            //
                            // (a) is easy to state loosely and get wrong: the
                            // consequence is that `POST /api/v1/permissions`
                            // CANNOT narrow a repository owner's read here, and
                            // `repository-owner` is auto-granted to every
                            // repository creator. That is not introduced by this
                            // line — the write/delete arm below, `require_visible`
                            // (~23 REST read surfaces) and
                            // `try_authorize_virtual_members` have all resolved
                            // through this same function since #3331, and a
                            // baseline `GET /api/v1/artifacts/…/download`
                            // already answered 200 for exactly that principal.
                            // This line makes the native read arm agree with
                            // them instead of being the lone holdout.
                            // `test_3387_applicable_rule_beats_an_ordinary_role_but_not_an_admin_carrying_one`
                            // pins all three arms, including (a), so the
                            // carve-out cannot be quietly re-described.
                            //
                            // Ordering is deliberate but is NOT a claim that the
                            // canonical query only runs on denials: for the
                            // role-assignment principal this change unblocks,
                            // `check_permission` returns false every time, so
                            // the uncached 2-CTE query runs on every ALLOWED
                            // read too (measured ~0.5 ms cold, ~0 warm). What
                            // the two cached calls do buy is short-circuiting
                            // the population that IS named by a rule — the
                            // common case on a ruled repository — off the
                            // uncached path. `unwrap_or(false)` keeps the
                            // existing fail-closed direction of this branch
                            // rather than converting a DB blip from 403 to 503.
                            || vis_state
                                .permission_service
                                .check_repository_action(ext.user_id, repo.id, action, false)
                                .await
                                .unwrap_or(false);

                        if !allowed {
                            tracing::info!(
                                repository_id = %repo.id,
                                user_id = %ext.user_id,
                                action,
                                "native-format read denied: no applicable permission rule and no \
                                 role assignment carrying the action; answering the \
                                 existence-hiding 404"
                            );
                            // #3524: the existence-hiding 404, not a 403. This
                            // branch is only ever reached for a PRIVATE
                            // repository — `action` is always "read" here (the
                            // #2603 G1 arm above owns write and delete) and
                            // `public_read_satisfies_acl` therefore short-circuits
                            // every public repository before this point — so the
                            // denial an authenticated non-member sees must not
                            // depend on whether the repository happens to carry
                            // any fine-grained rule, which is not something the
                            // caller has any business learning. A 403 here told
                            // that caller both that the repository exists and
                            // that it is governed by an ACL, while the rules-less
                            // branch below and a key naming no repository at all
                            // answered `not_found_response()`. All three are now
                            // byte-identical, matching REST `require_visible`,
                            // which returns `NotFound` for every denial. Writes
                            // are deliberately unchanged: a caller doing a PUT
                            // has generally already read the repository, and 403
                            // is the more useful answer there.
                            return not_found_response();
                        }
                    }
                } else if !visibility.allows_authenticated_read() {
                    // A repo with NO fine-grained permission rules whose
                    // visibility grants no authenticated baseline -- i.e.
                    // `private` -- must still not be readable by every
                    // authenticated user. Mirror the REST `require_visible`
                    // model: a non-admin needs a role assignment scoped to this
                    // repo (or a global assignment). An `internal` repository
                    // is exactly the case that SHOULD fall through to a read
                    // here, which is why the condition asks about the
                    // authenticated baseline rather than about `is_public`.
                    //
                    // Without this branch the native-protocol path
                    // default-ALLOWED rule-less private repos to any
                    // authenticated principal, while the REST download path
                    // denied the same caller (404) — a cross-tenant
                    // private-artifact leak (red-team round 2).
                    //
                    // Uses sqlx::query_scalar (not the macro) so no new entry in
                    // the sqlx offline-query cache is required, matching the rest
                    // of this middleware. Same predicate as
                    // RepositoryService::user_can_access_repo.
                    let granted = sqlx::query_scalar::<_, bool>(
                        "SELECT EXISTS ( \
                             SELECT 1 FROM role_assignments ra \
                             WHERE ra.user_id = $1 \
                               AND (ra.repository_id = $2 OR ra.repository_id IS NULL) \
                         )",
                    )
                    .bind(ext.user_id)
                    .bind(repo.id)
                    .fetch_one(&vis_state.db)
                    .await;

                    match granted {
                        Ok(true) => {}
                        // Existence-hiding 404, matching REST `require_visible`.
                        //
                        // The RESPONSE stays byte-identical to the one a
                        // nonexistent key produces — that indistinguishability
                        // is the point (#1808 / GHSA-fv45-mwhh-q23r) and is not
                        // traded away here. The operator-facing half of #3452
                        // was that nothing on the server said WHICH of the two
                        // it was either: the only clue in the reporter's log was
                        // an unrelated `no permission rules found for target`
                        // line, so a 20-byte `Repository not found` was
                        // indistinguishable from a missing repository in the
                        // logs as well as on the wire. Say it here, where the
                        // decision is made.
                        Ok(false) => {
                            tracing::info!(
                                repository_id = %repo.id,
                                user_id = %ext.user_id,
                                "private repository read denied: caller holds no grant on this \
                                 repository; answering the existence-hiding 404"
                            );
                            return not_found_response();
                        }
                        Err(_) => {
                            // DB error on access check: fail closed.
                            tracing::error!("repo access check failed: database unreachable");
                            return service_unavailable_response();
                        }
                    }
                }
            }
        }
    }

    // #2598: attribute every downstream ingestion/serve archive decode to this
    // repository so the per-tenant fairness sub-limit applies. This is the
    // single seam that resolves the repo id for all format routes, so scoping
    // here gives every extractor call site per-tenant fairness without any
    // per-handler plumbing.
    crate::util::bounded_archive::run_with_tenant_scope(
        crate::util::bounded_archive::TenantKey::Repo(repo.id),
        next.run(request),
    )
    .await
}

// Appended by extract_upstream.py: private items for the tests.
#[cfg(test)]
#[path = "../../../probes/auth.rs"]
pub(crate) mod probe;
