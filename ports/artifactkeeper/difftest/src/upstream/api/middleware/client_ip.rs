// Copied from artifact-keeper/artifact-keeper @ 7c42891 by extract_upstream.py. Do not edit.
//! Request-scoped client-IP context (#3888).
//!
//! [`client_ip_context_middleware`] resolves the request's client IP once —
//! the socket peer from `ConnectInfo`, with `X-Forwarded-For` believed only
//! when the peer falls inside a configured trusted-proxy CIDR (the
//! `RATE_LIMIT_TRUSTED_PROXY_CIDRS` policy, shared with the rate limiter;
//! see [`resolve_client_ip_addr`] and #2023, GHSA-8jm4-4x6c-6787) — and
//! scopes it as a task-local around the downstream request future, so
//! anything `.await`ed while handling the request (handlers, services,
//! audit emitters, permission gates) observes the same address without
//! threading it through every signature. This mirrors the correlation-ID
//! task-local in [`crate::api::middleware::tracing`].
//!
//! Consumers that need the address call [`current_client_ip`]. Outside a
//! request scope (startup, background jobs, detached `tokio::spawn` tasks,
//! tests that do not establish one) it resolves to `None` — callers must
//! treat `None` as "unknown", never as a sentinel address. Authorization
//! decisions keyed on the client IP (permission `allowed_cidrs` conditions,
//! #1849) fail closed on `None`.

use std::future::Future;
use std::net::{IpAddr, SocketAddr};
use std::sync::Arc;

use axum::{
    extract::{ConnectInfo, Request, State},
    middleware::Next,
    response::Response,
};

use super::rate_limit::{resolve_client_ip_addr, CidrRange};

tokio::task_local! {
    /// The resolved client IP of the request currently being handled.
    ///
    /// [`client_ip_context_middleware`] scopes this around the downstream
    /// request future; the scope wraps the future, not the OS task, so it is
    /// correct under HTTP/2 multiplexing. A future detached with
    /// `tokio::spawn` does NOT inherit the value, which fails closed for
    /// IP-conditioned authorization (#1849): code that needs the address in
    /// a detached task must capture it first with [`current_client_ip`].
    static CURRENT_CLIENT_IP: Option<IpAddr>;
}

/// The resolved client IP of the in-flight request, or `None` when called
/// outside a request scope (background jobs, startup, detached tasks) or when
/// the address could not be resolved. Mirrors
/// [`crate::api::middleware::tracing::current_correlation_id`].
pub fn current_client_ip() -> Option<IpAddr> {
    CURRENT_CLIENT_IP.try_with(|ip| *ip).ok().flatten()
}

/// Runs `fut` with [`current_client_ip`] resolving to `ip` — the same
/// scoping the middleware applies to each request. Public so tests (and any
/// future non-HTTP entry point that knows its caller's address, e.g. a gRPC
/// handler) can establish a scope without standing up a router.
pub async fn with_client_ip_scope<F: Future>(ip: Option<IpAddr>, fut: F) -> F::Output {
    CURRENT_CLIENT_IP.scope(ip, fut).await
}

/// Resolve the request's client IP and scope it for the downstream future.
///
/// Layered once, globally, next to `correlation_id_middleware` in
/// `create_router`, so every route (`/api/v1`, `/v2`, native formats) runs
/// inside the scope. The resolution is the trusted-proxy-aware
/// [`resolve_client_ip_addr`]: the TCP peer is authoritative and a spoofed
/// `X-Forwarded-For` from an untrusted peer is ignored.
pub async fn client_ip_context_middleware(
    State(trusted_proxies): State<Arc<Vec<CidrRange>>>,
    request: Request,
    next: Next,
) -> Response {
    let peer = request
        .extensions()
        .get::<ConnectInfo<SocketAddr>>()
        .map(|ci| ci.0.ip());
    let ip = resolve_client_ip_addr(request.headers(), peer, &trusted_proxies);
    with_client_ip_scope(ip, next.run(request)).await
}
