// Copied from artifact-keeper/artifact-keeper @ 7c42891 by extract_upstream.py. Do not edit.
//! Guest-access guard middleware (issue #850).
//!
//! Enforces a server-wide policy that disables anonymous (unauthenticated)
//! access. When `config.guest_access_enabled` is `false`, this middleware
//! returns `401 Unauthorized` for any request that does not present valid
//! credentials, with a small allowlist for endpoints that must remain
//! reachable so users and package clients can authenticate:
//!
//! * `/api/v1/auth/*`              login, refresh, logout, SSO callbacks
//! * `/api/v1/setup/*`             initial setup wizard
//! * `/api/v1/system/config`       web UI fetches before login
//! * `/health`, `/healthz`,
//!   `/ready`, `/readyz`, `/livez`  Kubernetes / load-balancer probes
//! * `/v2/token`                   OCI credential exchange (see below)
//!
//! **The OCI content surface is not exempt** (#3854). `/v2`, `/v2/` and every
//! manifest, blob, tag and referrer path are gated like any other
//! content-serving endpoint, so an anonymous `docker pull` of a `public`
//! repository is refused while the flag is off. The allowlist used to carry the
//! whole `/v2` subtree, but that was a response-*shape* workaround rather than a
//! policy carve-out: the guard's REST-shaped 401 names a bare realm that no
//! container client can fetch a token from. The refusal is now built by
//! [`oci_unauthorized_response`], which returns the distribution-spec error
//! envelope with a `Bearer` challenge naming this registry's token endpoint, so
//! the allowlist has nothing left to work around there.
//!
//! **`/v2/token` is the exception, and the guard cannot decide it.** The guard
//! resolves credentials from request headers. The token endpoint is where
//! credentials are *exchanged*, and one of the shapes reaching it — the OAuth2
//! refresh grant that every container client switches to after `docker login` —
//! carries its credential in the form body, where this layer cannot see it.
//! Gating the route therefore refuses authenticated pulls, not just anonymous
//! ones. The policy is applied inside `token()` instead, at the single exit that
//! hands a capability to a caller who presented none; every other credential the
//! endpoint accepts is authenticated there exactly as before.
//!
//! When `guest_access_enabled` is `true` (the default), the middleware is a
//! no-op so existing deployments are unaffected.
//!
//! ### Why we resolve auth ourselves
//!
//! The guard is registered as an outer (global) layer in `routes::create_router`,
//! which means it runs **before** the inner `auth_middleware` /
//! `optional_auth_middleware` / `repo_visibility_middleware` layers populate
//! request extensions. To make the gating decision we therefore resolve auth
//! directly and short-circuit if the path is not allowlisted. We resolve via
//! [`extract_visibility_token`] — the same channel-aware extractor the
//! repo-visibility middleware uses — so the guard honours every credential
//! channel the handlers accept, including the conda URL-embedded token and the
//! NuGet push `X-NuGet-ApiKey` header (not just the standard `Authorization` /
//! `X-API-Key` headers). Inner middlewares run again on requests that pass the
//! guard and populate the extensions used by handlers.
//!
//! We resolve via [`try_resolve_auth_outcome`] and match on the full
//! [`AuthOutcome`] rather than a boolean "is there a principal?" check, so a
//! transient [`AuthOutcome::Overloaded`] shed (the bcrypt-capacity cap
//! saturating) becomes a retryable **503**, not a 401. Flattening `Overloaded`
//! into an "unauthenticated" 401 would fail requests carrying valid credentials
//! under load — the exact regression `AuthOutcome::Overloaded` exists to prevent
//! (a saturated auth cap is retryable; non-retrying clients such as twine abort
//! on 401). The guard therefore returns the same 503 the inner middlewares do.

use std::sync::Arc;

use axum::{
    extract::{Request, State},
    http::{header, HeaderValue, StatusCode},
    middleware::Next,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;

use crate::api::extractors::request_base_url_from_request;
use crate::api::middleware::auth::{
    extract_visibility_token, is_browser_request, service_unavailable_response,
    try_resolve_auth_outcome, AuthOutcome,
};
use crate::api::middleware::oci_errors::{is_oci_v2_path, oci_unauthorized_response};
use crate::services::auth_service::AuthService;

/// Shared state for the guest-access guard.
///
/// Holds the policy flag and the `AuthService` needed to validate tokens.
#[derive(Clone)]
pub struct GuestAccessState {
    pub guest_access_enabled: bool,
    pub auth_service: Arc<AuthService>,
}

/// Endpoints that remain reachable without authentication even when
/// `guest_access_enabled` is `false`.
///
/// The list is intentionally tight: only the endpoints required for users to
/// log in, finish first-run setup, or run liveness probes. No content-serving
/// endpoint is exempt — the OCI Distribution *content* surface included
/// (#3854). An OCI client still learns where to authenticate, because the
/// refusal it gets carries the token-endpoint challenge; see the module docs.
///
/// `/v2/token` is the one OCI entry, and it is not a carve-out for anonymity:
/// it is the endpoint by which credentials are *obtained*, the OCI analogue of
/// `/api/v1/auth/login` above, and the anonymous mint is refused inside the
/// handler instead. The guard cannot decide this route — it resolves
/// credentials from headers, and the OAuth2 refresh grant every container
/// client uses after `docker login` carries its credential in the form body,
/// so gating it breaks authenticated `docker pull`, not just anonymous ones.
/// Matched by exact equality, never as a prefix: `/v2/tokenX` and
/// `/v2/token/<anything>` stay gated and fail closed.
fn is_allowlisted(path: &str) -> bool {
    // Exact-match health and readiness paths.
    matches!(
        path,
        "/health"
            | "/healthz"
            | "/ready"
            | "/readyz"
            | "/livez"
            | "/api/v1/system/config"
            | "/v2/token"
    ) || path.starts_with("/api/v1/auth/")
        || path == "/api/v1/auth"
        || path.starts_with("/api/v1/setup/")
        || path == "/api/v1/setup"
}

/// 401 response body returned when guest access is disabled.
/// Includes `WWW-Authenticate` headers (Basic, Bearer, Cargo) so
/// RFC 7235-compliant clients (Maven, pip, npm, etc.) can determine
/// the auth scheme and retry with credentials.
///
/// When the request is browser-originated (`for_browser`, see
/// [`is_browser_request`]), the `Basic` and `Cargo` challenges are omitted so
/// the browser does not raise its native Basic credential popup over the web
/// UI's own login screen (#2936 / #3082). The `Bearer` challenge is kept for
/// RFC 7235 compliance — it never triggers a popup — and the web UI reacts to
/// the 401 body by routing to its login / OIDC flow. Package-manager clients
/// (pip, npm, docker, cargo, maven, …) are never classified as browsers and
/// keep the full challenge set.
fn unauthorized_response(for_browser: bool) -> Response {
    let mut response = (
        StatusCode::UNAUTHORIZED,
        Json(json!({
            "error": "GUEST_ACCESS_DISABLED",
            "message": "This instance requires authentication. Please log in.",
        })),
    )
        .into_response();

    if !for_browser {
        response.headers_mut().append(
            header::WWW_AUTHENTICATE,
            HeaderValue::from_static("Basic realm=\"artifact-keeper\""),
        );
    }
    response.headers_mut().append(
        header::WWW_AUTHENTICATE,
        HeaderValue::from_static("Bearer realm=\"artifact-keeper\", charset=\"UTF-8\""),
    );
    if !for_browser {
        response
            .headers_mut()
            .append(header::WWW_AUTHENTICATE, HeaderValue::from_static("Cargo"));
    }

    response
}

/// Map a resolved [`AuthOutcome`] to the guard's short-circuit response, or
/// `None` when the request should be allowed through to the inner layers.
///
/// This is the load-bearing distinction: an `Overloaded` shed must yield a
/// retryable **503**, NOT a 401. Collapsing it into the "unauthenticated" 401
/// would make valid credentials fail under transient auth-cap saturation. Kept
/// as a pure function so the mapping is unit-testable without a live auth backend.
///
/// `for_browser` selects the popup-free challenge variant of the 401 for
/// browser-originated requests (#2936 / #3082); it never changes the status.
///
/// `oci_base_url` is `Some(base_url)` when the request is on the OCI
/// Distribution surface, and selects the distribution-spec refusal instead of
/// the REST one (#3854). It applies to the 401 only: an `Overloaded` shed stays
/// the retryable plain-text 503 with `Retry-After` on `/v2` exactly as it is
/// everywhere else. The spec constrains the body of JSON `4XX` responses; a
/// plain-text `5XX` is already conformant, and dressing a capacity shed up as a
/// registry error would misreport it — while collapsing it into the new 401
/// would fail valid credentials under load, the regression `AuthOutcome::
/// Overloaded` exists to prevent.
fn guard_short_circuit(
    outcome: &AuthOutcome,
    for_browser: bool,
    oci_base_url: Option<&str>,
) -> Option<Response> {
    match outcome {
        // A principal resolved — let the request through; inner middlewares
        // re-resolve and populate request extensions for handlers.
        AuthOutcome::Resolved(_) => None,
        // Transient bcrypt-capacity shed: retryable 503, never a 401 — on the
        // OCI surface as on every other.
        AuthOutcome::Overloaded => Some(service_unavailable_response()),
        // No/invalid credential presented: guest access is disabled → 401,
        // shaped for the protocol the client is speaking.
        AuthOutcome::NoCredential | AuthOutcome::InvalidCredential => Some(match oci_base_url {
            Some(base_url) => oci_unauthorized_response(base_url),
            None => unauthorized_response(for_browser),
        }),
    }
}

/// Middleware that blocks unauthenticated requests when guest access is
/// disabled server-wide. See module docs for behaviour and allowlist.
pub async fn guest_access_guard(
    State(state): State<GuestAccessState>,
    request: Request,
    next: Next,
) -> Response {
    if state.guest_access_enabled {
        return next.run(request).await;
    }

    let path = request.uri().path();
    if is_allowlisted(path) {
        return next.run(request).await;
    }

    // On the OCI Distribution surface the refusal must be the distribution
    // spec's error envelope carrying a challenge that names the token endpoint
    // as the realm, or a container client cannot render it and has nowhere to
    // authenticate (#3854). Resolve the realm's base URL through the same
    // function the OCI handlers use (`AK_EXTERNAL_URL`, then `X-Forwarded-*`,
    // then the URI authority, then `Host`) rather than a second copy that would
    // drift: a drifted realm points clients at the wrong host and fails in a
    // way nobody notices until a reverse proxy changes. Computed before the
    // request is moved into `next.run`.
    let oci_base_url = is_oci_v2_path(path)
        .then(|| request_base_url_from_request(request.headers(), Some(request.uri())));

    // Resolve auth via `extract_visibility_token` (NOT the header-only
    // `extract_token`) so the guard recognises the SAME credential channels the
    // repo-visibility middleware and format handlers accept — including the
    // conda URL-embedded token (`/conda/t/<TOKEN>/...`) and the NuGet push
    // `X-NuGet-ApiKey` header. Using the narrower `extract_token` here treated a
    // legitimately-authenticated conda/nuget client as a guest and 401'd it when
    // guest access was disabled, rendering issues #2631 / #2644 inert. We then
    // match the full outcome so a transient `AuthOutcome::Overloaded` shed
    // becomes a retryable 503 rather than a spurious 401 — see module docs.
    // Inner middlewares re-resolve and populate request extensions for handlers
    // on requests that pass the guard.
    let extracted = extract_visibility_token(&request);
    // Pass `allow_basic_api_token=true`: this global guard runs BEFORE the inner
    // middlewares and only decides pass/block for the anonymous-disabled policy,
    // mirroring the format extractor above. A package client pulling a format
    // endpoint with `-u any:<api_token>` must clear this gate exactly as it did
    // before the #2806 boundary fix. It does NOT grant /api/v1 access: the inner
    // `optional_auth_middleware` / `admin_middleware` re-resolve with
    // `allow_basic_api_token=false` and still refuse an API token as the Basic
    // password on the management API.
    let outcome = try_resolve_auth_outcome(&state.auth_service, extracted, true).await;
    // Browser-originated requests get the popup-free 401 variant so the web
    // UI can show its login / OIDC screen instead of the native Basic dialog
    // (#2936 / #3082). Classified from request headers only (Fetch Metadata /
    // `Accept: text/html`), so package clients are unaffected.
    let for_browser = is_browser_request(request.headers());
    match guard_short_circuit(&outcome, for_browser, oci_base_url.as_deref()) {
        Some(response) => response,
        None => next.run(request).await,
    }
}

/// The startup notice for a server that accepts anonymous requests.
///
/// `AK_GUEST_ACCESS_ENABLED` defaults to `true` for backward compatibility
/// (#850, #866): every repository is still private unless someone marks it
/// public, so a fresh install exposes nothing. What an operator who never set
/// the variable lacks is a *signal* that the instance is serving anonymous
/// pulls at all, and how much of it is exposed. This returns that signal --
/// `Some(message)` only when anonymous access is on and at least one
/// repository is public -- so `main` can emit it the way it emits
/// `setup_required` (#3489).
pub fn startup_notice(guest_access_enabled: bool, public_repositories: i64) -> Option<String> {
    if !guest_access_enabled || public_repositories <= 0 {
        return None;
    }
    let plural = if public_repositories == 1 {
        "repository is"
    } else {
        "repositories are"
    };
    Some(format!(
        "AK_GUEST_ACCESS_ENABLED is on and {public_repositories} {plural} public: anonymous \
         clients can list and download from them. Set AK_GUEST_ACCESS_ENABLED=false to refuse \
         anonymous access server-wide (this also coerces every repository to private), or mark \
         the repositories private individually."
    ))
}

/// Number of repositories anonymous clients could read right now.
pub async fn public_repository_count(pool: &sqlx::PgPool) -> sqlx::Result<i64> {
    sqlx::query_scalar("SELECT COUNT(*) FROM repositories WHERE is_public = true")
        .fetch_one(pool)
        .await
}
