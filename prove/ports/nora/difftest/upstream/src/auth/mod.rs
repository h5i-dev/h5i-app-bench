// Copied from getnora-io/nora @ f864a9a by extract_upstream.py. Do not edit.
// Copyright (c) 2026 The NORA Authors
// SPDX-License-Identifier: MIT

//! Authentication module — middleware, providers, and token routes.
//!
//! Supports:
//! - Basic auth via htpasswd files
//! - Bearer token auth (opaque tokens with Argon2 verification)
//! - Brute-force protection with exponential backoff

mod htpasswd;
mod namespace;
pub mod oidc;

pub use htpasswd::HtpasswdAuth;
pub use namespace::{enforce_namespace_scope, NamespaceAuthority};
pub use oidc::OidcValidator;

/// Authenticated username carried in request extensions after successful auth.
#[derive(Clone, Debug)]
pub struct AuthenticatedUser(pub String);

/// The verified role carried in request extensions after successful auth.
/// Basic-auth (htpasswd) identities have no role concept and are recorded as
/// `Write` (never admin), so role-gated owner-scope treats them as non-admin.
#[derive(Clone, Debug)]
pub struct AuthenticatedRole(pub crate::tokens::Role);

use axum::{
    body::Body,
    extract::{ConnectInfo, State},
    http::{header, HeaderMap, Request, StatusCode},
    middleware::Next,
    response::{IntoResponse, Response},
};
use base64::{engine::general_purpose::STANDARD, Engine};
use std::collections::HashMap;
use std::net::{IpAddr, SocketAddr};
use std::time::Instant;

use crate::AppState;

/// Resolve the audit actor for a request-driven event (#985): the authenticated
/// username, or `anonymous` when the request carries no identity. Write handlers
/// take `user: Option<axum::Extension<AuthenticatedUser>>` (which never fails to
/// extract) and pass this to `AuditEntry::new` instead of a hardcoded actor.
pub fn audit_actor(user: &Option<axum::Extension<AuthenticatedUser>>) -> &str {
    match user {
        Some(axum::Extension(AuthenticatedUser(name))) => name,
        None => "anonymous",
    }
}

/// Tracks failed authentication attempts per IP for brute-force protection.
///
/// After `max_failures` consecutive failures, the IP is locked out with
/// exponential backoff: 2^(failures - max_failures) seconds, capped at 15 minutes.
pub struct AuthFailureTracker {
    /// IP -> (consecutive failures, last failure time)
    entries: parking_lot::Mutex<HashMap<IpAddr, (u32, Instant)>>,
    /// Number of failures before lockout kicks in (default: 5)
    max_failures: u32,
    /// Maximum lockout duration in seconds (default: 900 = 15 minutes)
    max_lockout_secs: u64,
}

impl AuthFailureTracker {
    pub fn new(max_failures: u32, max_lockout_secs: u64) -> Self {
        Self {
            entries: parking_lot::Mutex::new(HashMap::new()),
            max_failures,
            max_lockout_secs,
        }
    }

    /// Check if IP is currently locked out. Returns remaining lockout seconds if blocked.
    pub fn check_blocked(&self, ip: &IpAddr) -> Option<u64> {
        let entries = self.entries.lock();
        let (failures, last_failure) = entries.get(ip)?;
        if *failures < self.max_failures {
            return None;
        }
        let exponent = (*failures - self.max_failures).min(20);
        let lockout_secs = (1u64 << exponent).min(self.max_lockout_secs);
        let elapsed = last_failure.elapsed().as_secs();
        if elapsed < lockout_secs {
            Some(lockout_secs - elapsed)
        } else {
            None
        }
    }

    /// Record a failed auth attempt for an IP.
    pub fn record_failure(&self, ip: IpAddr) {
        let mut entries = self.entries.lock();
        let entry = entries.entry(ip).or_insert_with(|| (0, Instant::now()));
        entry.0 += 1;
        entry.1 = Instant::now();
    }

    /// Clear failure count on successful auth.
    pub fn record_success(&self, ip: &IpAddr) {
        let mut entries = self.entries.lock();
        entries.remove(ip);
    }

    /// Remove entries older than max_lockout_secs (call periodically).
    pub fn cleanup(&self) {
        let mut entries = self.entries.lock();
        entries.retain(|_, (_, last)| last.elapsed().as_secs() < self.max_lockout_secs * 2);
    }
}

/// Check if path is public (no auth required)
/// Paths that are public UNCONDITIONALLY: probes (a gated /health takes the
/// whole deployment down behind an LB) and the token endpoints, which do
/// their own credential handling.
fn is_public_path(path: &str) -> bool {
    matches!(
        path,
        "/" | "/health" | "/ready" | "/api/tokens" | "/api/tokens/list" | "/api/tokens/revoke"
    )
}

/// The browse web surface: UI pages, their JSON API, and the API docs. All
/// of it enumerates repositories and packages, so under an auth-enabled
/// deployment it is gated unless `anonymous_read` or `public_web_ui` opens
/// it (token-management pages stay ALWAYS gated — they were before, too).
fn is_web_surface(path: &str) -> bool {
    if path.starts_with("/ui/tokens") || path.starts_with("/api/ui/tokens") {
        return false;
    }
    path.starts_with("/ui") || path.starts_with("/api/ui") || path.starts_with("/api-docs")
}

/// Check if a path belongs to the Docker/OCI registry (`/v2`, `/v2/…`).
///
/// Docker anonymous access is governed by `docker_anon_pull` (separate from
/// the general `anonymous_read`), so all `/v2` paths are matched as one group:
/// the `/v2/` auth-challenge ping and every manifest/blob/tag endpoint. Per the
/// Docker Registry V2 spec, an unauthenticated `GET /v2/` returns 401 with a
/// WWW-Authenticate header (so clients send credentials) UNLESS anonymous Docker
/// pull is explicitly enabled.
fn is_docker_path(path: &str) -> bool {
    path == "/v2" || path.starts_with("/v2/")
}

/// Check if path is an admin-only control-plane endpoint.
///
/// Admin paths require a token whose role satisfies `can_admin()` regardless of
/// HTTP method, and are never served anonymously (not even under
/// `anonymous_read`). Basic-auth has no role concept, so it can never satisfy
/// an admin path — it is denied fail-closed. Scoped strictly to `/api/v1/admin/`
/// so it never widens the privilege bar of existing routes (e.g. `/raw/-/reindex`
/// stays at write-level).
fn is_admin_path(path: &str) -> bool {
    path.starts_with("/api/v1/admin/")
}

/// Extract client IP from request, honoring XFF/X-Real-IP only from trusted proxies.
///
/// If the direct peer IP is not in `trusted_proxies`, XFF/X-Real-IP headers are
/// ignored and the peer IP is returned. This prevents attackers from spoofing
/// their IP to bypass `AuthFailureTracker` lockout.
pub(crate) fn resolve_client_ip(
    peer: IpAddr,
    headers: &HeaderMap,
    trusted_proxies: &crate::config::TrustedProxies,
) -> IpAddr {
    if !trusted_proxies.contains(peer) {
        return peer;
    }

    // Try X-Forwarded-For first (first IP in chain is the client)
    if let Some(xff) = headers.get("x-forwarded-for") {
        if let Ok(s) = xff.to_str() {
            if let Some(first) = s.split(',').next() {
                if let Ok(ip) = first.trim().parse::<IpAddr>() {
                    return ip;
                }
            }
        }
    }
    // Try X-Real-IP
    if let Some(xri) = headers.get("x-real-ip") {
        if let Ok(s) = xri.to_str() {
            if let Ok(ip) = s.trim().parse::<IpAddr>() {
                return ip;
            }
        }
    }
    // No forwarding headers — use peer IP
    peer
}

fn extract_client_ip(
    request: &Request<Body>,
    trusted_proxies: &crate::config::TrustedProxies,
) -> Option<IpAddr> {
    let peer = request
        .extensions()
        .get::<ConnectInfo<SocketAddr>>()
        .map(|ci| ci.0.ip())?;
    Some(resolve_client_ip(peer, request.headers(), trusted_proxies))
}

/// Insert the anonymous identity (read-only role, unrestricted namespace) and
/// run the downstream handler. Shared by the `anonymous_read` (non-Docker) and
/// `docker_anon_pull` (Docker `/v2`) bypass paths.
async fn anonymous_read_passthrough(mut request: Request<Body>, next: Next) -> Response {
    request
        .extensions_mut()
        .insert(NamespaceAuthority::Unrestricted);
    request
        .extensions_mut()
        .insert(AuthenticatedUser("anonymous".to_string()));
    request
        .extensions_mut()
        .insert(AuthenticatedRole(crate::tokens::Role::Read));
    next.run(request).await
}

/// Auth middleware - supports Basic auth, Bearer tokens, and OIDC JWT
pub async fn auth_middleware(
    State(state): State<AppState>,
    mut request: Request<Body>,
    next: Next,
) -> Response {
    // Skip auth if disabled (neither htpasswd nor OIDC configured)
    if !state.config.auth.enabled {
        request
            .extensions_mut()
            .insert(NamespaceAuthority::Unrestricted);
        request
            .extensions_mut()
            .insert(AuthenticatedUser("anonymous".to_string()));
        return next.run(request).await;
    }

    // Skip auth for public endpoints
    {
        let path = request.uri().path();
        // Unconditional publics (probes, token endpoints), plus the web
        // surface and /metrics when the config opens them. The web surface
        // enumerates every repository, so it follows `anonymous_read` (the
        // registry read APIs would expose the same names) or the explicit
        // `public_web_ui` escape; /metrics has its own default-open switch —
        // labels carry registry formats, not repository names.
        let config = &state.config.auth;
        let open = is_public_path(path)
            || (is_web_surface(path) && (config.anonymous_read || config.public_web_ui))
            || (path == "/metrics" && config.public_metrics);
        if open {
            // Opportunistic auth: if the caller provided credentials on an
            // open path, try to validate them so downstream handlers can
            // distinguish "anonymous browse" from "authenticated browse"
            // (e.g. to gate proxy_upstreams disclosure). If validation fails
            // we fall through to anonymous — the path is open regardless.
            if let Some(auth_val) = request
                .headers()
                .get(axum::http::header::AUTHORIZATION)
                .and_then(|h| h.to_str().ok())
            {
                if let Some(encoded) = auth_val.strip_prefix("Basic ") {
                    if let Some(username) = try_basic_auth(encoded, state.auth.as_deref()) {
                        request
                            .extensions_mut()
                            .insert(NamespaceAuthority::Unrestricted);
                        request.extensions_mut().insert(AuthenticatedUser(username));
                        request
                            .extensions_mut()
                            .insert(AuthenticatedRole(crate::tokens::Role::Write));
                        return next.run(request).await;
                    }
                } else if let Some(token) = auth_val.strip_prefix("Bearer ") {
                    if let Some(ref token_store) = state.tokens {
                        if let Ok((user, role)) = token_store.verify_token(token) {
                            request
                                .extensions_mut()
                                .insert(NamespaceAuthority::Unrestricted);
                            request.extensions_mut().insert(AuthenticatedUser(user));
                            request.extensions_mut().insert(AuthenticatedRole(role));
                            return next.run(request).await;
                        }
                    }
                }
            }
            // No credentials or validation failed — anonymous browse
            let mut request = request;
            request
                .extensions_mut()
                .insert(NamespaceAuthority::Unrestricted);
            request
                .extensions_mut()
                .insert(AuthenticatedUser("anonymous".to_string()));
            return next.run(request).await;
        }
        // A gated web-surface request without credentials gets a Basic
        // challenge so browsers prompt instead of rendering a bare 401.
        if (is_web_surface(path) || path == "/metrics")
            && request
                .headers()
                .get(axum::http::header::AUTHORIZATION)
                .is_none()
        {
            return axum::http::Response::builder()
                .status(axum::http::StatusCode::UNAUTHORIZED)
                .header("WWW-Authenticate", "Basic realm=\"nora\"")
                .body(axum::body::Body::from("Authentication required"))
                .expect("valid response");
        }
    }

    let path = request.uri().path();

    // Docker/OCI paths (`/v2`, `/v2/…`) are governed by `docker_anon_pull`,
    // NOT the general `anonymous_read`: anonymous Docker pull changes the `/v2/`
    // auth-challenge handshake, so it is opted into explicitly and enabling
    // anonymous Maven/raw/npm never silently exposes container images.
    let is_docker = is_docker_path(path);

    // `/v2/_catalog` enumerates every repository — never served anonymously, even
    // under docker_anon_pull (anonymous pull-by-name is not list-all-repos).
    let is_docker_catalog = path == "/v2/_catalog";

    // Token management always requires auth, even with anonymous_read
    let is_token_management = path.starts_with("/ui/tokens") || path.starts_with("/api/ui/tokens");

    // npm whoami always requires auth (otherwise it returns "anonymous" for every user)
    let is_whoami = path.ends_with("/-/whoami");

    // Admin control-plane paths always require an admin token — never anonymous,
    // even under anonymous_read, and method-independent (covers a future GET).
    let is_admin = is_admin_path(path);

    let is_read_method = matches!(
        *request.method(),
        axum::http::Method::GET | axum::http::Method::HEAD
    );

    // npm audit (#597) is a read-semantics query that npm sends as a POST (npm7
    // `advisories/bulk`, npm6 `audits/quick`). Treat it as read-eligible under
    // `anonymous_read` so anonymous `npm audit` works wherever anonymous install
    // works. Safe: the handler (registry/npm.rs) mutates nothing (forwards to the
    // configured upstream, returns advisories), caps the body, strips internal
    // package names under a filter, and never forwards the client credential.
    let is_npm_audit = *request.method() == axum::http::Method::POST
        && (path == "/npm/-/npm/v1/security/advisories/bulk"
            || path == "/npm/-/npm/v1/security/audits/quick");

    // A request that presents credentials is always validated below (honest
    // `docker login`, correct audit attribution) — never short-circuited to
    // anonymous. Anonymous Docker bypass applies only when no Authorization sent.
    let has_auth_header = request.headers().contains_key(header::AUTHORIZATION);

    // Anonymous read for non-Docker registries (Maven/raw/npm/…) if configured.
    // Token management, whoami, admin, and all Docker `/v2` paths are excluded.
    if state.config.auth.anonymous_read
        && (is_read_method || is_npm_audit)
        && !is_docker
        && !is_token_management
        && !is_whoami
        && !is_admin
    {
        return anonymous_read_passthrough(request, next).await;
    }

    // Anonymous Docker/OCI pull, when explicitly enabled. The `/v2/` ping then
    // returns 200 (so the client proceeds without a Basic challenge) and
    // manifest/blob/tag reads are served without auth; writes (POST/PUT/PATCH/
    // DELETE) are not read methods, so they fall through and still require auth.
    // With the flag off (default), `/v2/` returns 401 + WWW-Authenticate: Basic
    // so `docker login` works and the basic-auth-accepts-api-token contract holds.
    if state.config.auth.docker_anon_pull
        && is_read_method
        && is_docker
        && !is_docker_catalog
        && !has_auth_header
    {
        return anonymous_read_passthrough(request, next).await;
    }

    // Compute realm from public_url for WWW-Authenticate header
    let realm = state.config.server.public_url.as_deref().unwrap_or("Nora");

    // Check if client IP is blocked due to too many failed attempts
    let client_ip = extract_client_ip(&request, &state.config.auth.trusted_proxies);
    if let Some(ip) = client_ip {
        if let Some(retry_after) = state.auth_failures.check_blocked(&ip) {
            return (
                StatusCode::TOO_MANY_REQUESTS,
                [
                    (header::RETRY_AFTER, retry_after.to_string()),
                    (header::CONTENT_TYPE, "application/json".to_string()),
                ],
                format!(
                    r#"{{"error":"Too many failed attempts. Retry after {} seconds."}}"#,
                    retry_after
                ),
            )
                .into_response();
        }
    }

    // Extract Authorization header
    let auth_header = request
        .headers()
        .get(header::AUTHORIZATION)
        .and_then(|h| h.to_str().ok());

    let auth_header = match auth_header {
        Some(h) => h,
        None => return unauthorized_response("Authentication required", realm),
    };

    // Try Bearer token first (opaque nra_ tokens, then OIDC JWT)
    if let Some(token) = auth_header.strip_prefix("Bearer ") {
        // 1. Try opaque token (nra_ prefix)
        if let Some(ref token_store) = state.tokens {
            match token_store.verify_token(token) {
                Ok((user, role)) => {
                    if let Some(ip) = client_ip {
                        state.auth_failures.record_success(&ip);
                    }
                    let method = request.method().clone();
                    if (method == axum::http::Method::PUT
                        || method == axum::http::Method::POST
                        || method == axum::http::Method::DELETE
                        || method == axum::http::Method::PATCH)
                        && !role.can_write()
                    {
                        return (StatusCode::FORBIDDEN, "Read-only token").into_response();
                    }
                    if is_admin && !role.can_admin() {
                        return (StatusCode::FORBIDDEN, "Admin role required").into_response();
                    }
                    // Opaque (nra_) tokens are not namespace-scoped (#583 is OIDC-only).
                    request
                        .extensions_mut()
                        .insert(NamespaceAuthority::Unrestricted);
                    request.extensions_mut().insert(AuthenticatedUser(user));
                    request.extensions_mut().insert(AuthenticatedRole(role));
                    return next.run(request).await;
                }
                // A store I/O/parse failure is not a credential verdict. Only an
                // `nra_`-prefixed token reaches disk (anything else returns
                // `InvalidFormat` first), so there is no OIDC identity to fall
                // through to: answer 503 so the client retries, instead of a 401
                // that makes valid creds flap during a storage blip.
                Err(crate::tokens::TokenError::Storage(e)) => {
                    tracing::error!(error = %e, "token store read failed during Bearer auth");
                    return (
                        StatusCode::SERVICE_UNAVAILABLE,
                        "Token verification unavailable",
                    )
                        .into_response();
                }
                Err(_) => {
                    // Token verification failed — fall through to OIDC
                }
            }
        }

        // 2. Try OIDC JWT validation
        if let Some(ref oidc_validator) = state.oidc {
            if oidc_validator.is_active() {
                match oidc_validator.validate_token(token).await {
                    Ok(identity) => {
                        if let Some(ip) = client_ip {
                            state.auth_failures.record_success(&ip);
                        }
                        tracing::debug!(
                            provider = %identity.provider,
                            subject = %identity.subject,
                            role = ?identity.role,
                            "OIDC authentication successful"
                        );
                        let method = request.method().clone();
                        if (method == axum::http::Method::PUT
                            || method == axum::http::Method::POST
                            || method == axum::http::Method::DELETE
                            || method == axum::http::Method::PATCH)
                            && !identity.role.can_write()
                        {
                            return (StatusCode::FORBIDDEN, "Read-only OIDC identity")
                                .into_response();
                        }
                        if is_admin && !identity.role.can_admin() {
                            return (StatusCode::FORBIDDEN, "Admin role required").into_response();
                        }
                        // Carry the namespace scopes into the request so write
                        // handlers can enforce them on the artifact coordinate
                        // (#583). Provider scope and rule scope are a conjunction:
                        // the provider scope is a ceiling a rule cannot widen.
                        let authority = NamespaceAuthority::from_oidc_scopes(
                            &identity.provider,
                            std::iter::once(identity.namespace_scope.as_slice())
                                .chain(identity.rule_namespace_scope.as_deref()),
                            identity.namespace_scope_enforcement,
                        );
                        request.extensions_mut().insert(authority);
                        request
                            .extensions_mut()
                            .insert(AuthenticatedUser(identity.subject.clone()));
                        request
                            .extensions_mut()
                            .insert(AuthenticatedRole(identity.role));
                        return next.run(request).await;
                    }
                    Err(reason) => {
                        // #994 — surface *why* OIDC rejected the token: a bounded
                        // metric bucket for alerting plus the full reason in a warn
                        // log (never the token). Without this a lifetime ceiling, a
                        // wrong audience and a missing role rule are indistinguishable.
                        crate::metrics::record_oidc_rejection(
                            crate::auth::oidc::classify_rejection(&reason),
                        );
                        tracing::warn!(reason = %reason, "OIDC authentication rejected");
                    }
                }
            }
        }

        // Both token and OIDC failed
        if let Some(ip) = client_ip {
            state.auth_failures.record_failure(ip);
        }
        return unauthorized_response("Invalid or expired token", realm);
    }

    // Parse Basic auth
    if !auth_header.starts_with("Basic ") {
        return unauthorized_response("Basic or Bearer authentication required", realm);
    }

    // htpasswd provider required for Basic auth
    let auth = match &state.auth {
        Some(auth) => auth,
        None => return unauthorized_response("Basic auth not configured", realm),
    };

    let encoded = &auth_header[6..];
    let decoded = match STANDARD.decode(encoded) {
        Ok(d) => d,
        Err(_) => return unauthorized_response("Invalid credentials encoding", realm),
    };

    let credentials = match String::from_utf8(decoded) {
        Ok(c) => c,
        Err(_) => return unauthorized_response("Invalid credentials encoding", realm),
    };

    let (username, password) = match credentials.split_once(':') {
        Some((u, p)) => (u, p),
        None => return unauthorized_response("Invalid credentials format", realm),
    };

    // Verify credentials. htpasswd first; if that fails, the password may be an API
    // token (`nra_…`). Docker, twine and Maven send the token as the Basic-auth
    // password and never use Bearer (the `/v2/` challenge is Basic), so the Basic
    // path must fall through to token verification for token auth to work at all. (#736)
    if !auth.authenticate(username, password) {
        let token_result = state.tokens.as_ref().map(|ts| ts.verify_token(password));
        // Same fail-closed rule as the Bearer path: a store I/O/parse failure is
        // not "wrong password". A 401 here makes valid token creds flap and feeds
        // the failure tracker toward lockout for the duration of a storage blip.
        if let Some(Err(crate::tokens::TokenError::Storage(ref e))) = token_result {
            tracing::error!(error = %e, "token store read failed during Basic auth fallback");
            return (
                StatusCode::SERVICE_UNAVAILABLE,
                "Token verification unavailable",
            )
                .into_response();
        }
        if let Some(Ok((token_user, role))) = token_result {
            if let Some(ip) = client_ip {
                state.auth_failures.record_success(&ip);
            }
            let method = request.method().clone();
            if (method == axum::http::Method::PUT
                || method == axum::http::Method::POST
                || method == axum::http::Method::DELETE
                || method == axum::http::Method::PATCH)
                && !role.can_write()
            {
                return (StatusCode::FORBIDDEN, "Read-only token").into_response();
            }
            // An API token sent as the Basic password is a full bearer identity
            // (#737), so it must clear the admin gate too — else a write token via
            // Basic would reach /api/v1/admin/* unchecked.
            if is_admin && !role.can_admin() {
                return (StatusCode::FORBIDDEN, "Admin role required").into_response();
            }
            // Opaque (nra_) tokens are not namespace-scoped (#583 is OIDC-only).
            request
                .extensions_mut()
                .insert(NamespaceAuthority::Unrestricted);
            request
                .extensions_mut()
                .insert(AuthenticatedUser(token_user));
            request.extensions_mut().insert(AuthenticatedRole(role));
            return next.run(request).await;
        }
        if let Some(ip) = client_ip {
            state.auth_failures.record_failure(ip);
        }
        return unauthorized_response("Invalid username or password", realm);
    }

    // Auth successful — clear failure counter
    if let Some(ip) = client_ip {
        state.auth_failures.record_success(&ip);
    }
    // Basic-auth carries no role, so it can never satisfy an admin path: deny
    // fail-closed (403 — authenticated but not authorized).
    if is_admin {
        return (StatusCode::FORBIDDEN, "Admin role required").into_response();
    }
    // Basic-auth identities are not namespace-scoped (#583 is OIDC-only).
    request
        .extensions_mut()
        .insert(NamespaceAuthority::Unrestricted);
    request
        .extensions_mut()
        .insert(AuthenticatedUser(username.to_string()));
    request
        .extensions_mut()
        .insert(AuthenticatedRole(crate::tokens::Role::Write));
    next.run(request).await
}

/// Attempt to validate a Base64-encoded Basic auth credential against the
/// htpasswd store. Returns the username on success, `None` on any failure.
/// Used by the opportunistic-auth path on open web surfaces so that
/// authenticated users get their real identity even on publicly browsable
/// pages.
fn try_basic_auth(encoded: &str, auth: Option<&HtpasswdAuth>) -> Option<String> {
    use base64::{engine::general_purpose::STANDARD, Engine};
    let decoded = String::from_utf8(STANDARD.decode(encoded).ok()?).ok()?;
    let (username, password) = decoded.split_once(':')?;
    let htpasswd = auth?;
    if htpasswd.authenticate(username, password) {
        Some(username.to_string())
    } else {
        None
    }
}

fn unauthorized_response(message: &str, realm: &str) -> Response {
    (
        StatusCode::UNAUTHORIZED,
        [
            (
                header::WWW_AUTHENTICATE,
                format!("Basic realm=\"{}\"", realm),
            ),
            (header::CONTENT_TYPE, "application/json".to_string()),
        ],
        format!(r#"{{"error":"{}"}}"#, message),
    )
        .into_response()
}


// Test seam appended by extract_upstream.py: seed and read the private state.
impl AuthFailureTracker {
    pub fn seed(&self, ip: IpAddr, failures: u32, last_failure: Instant) {
        self.entries.lock().insert(ip, (failures, last_failure));
    }
    pub fn entries_now(&self) -> Vec<(IpAddr, u32, Instant)> {
        let mut v: Vec<_> = self.entries.lock().iter().map(|(ip, (n, t))| (*ip, *n, *t)).collect();
        v.sort_by_key(|e| e.0);
        v
    }
}
