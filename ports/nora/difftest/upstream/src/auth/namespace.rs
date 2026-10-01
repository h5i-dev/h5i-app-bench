// Copied from getnora-io/nora @ f864a9a by extract_upstream.py. Do not edit.
// Copyright (c) 2026 The NORA Authors
// SPDX-License-Identifier: MIT

//! OIDC `namespace_scope` authorization (#583).
//!
//! The auth middleware stamps a [`NamespaceAuthority`] into the request
//! extensions on every path; write handlers call [`enforce_namespace_scope`]
//! with the artifact coordinate they parsed (never the storage key). The
//! segment-aware matcher itself lives in `crate::validation` so it can be fuzzed
//! without pulling in the binary-only metrics/config wired up here.

use std::sync::Arc;

use crate::config::ScopeEnforcement;
use crate::metrics::NAMESPACE_SCOPE_DECISIONS;
use crate::validation::namespace_match;

/// Per-request namespace authorization, derived from the authenticated identity.
///
/// Present on every request (the middleware inserts it on all paths), so write
/// handlers can extract it without a fallback.
#[derive(Clone, Debug)]
pub enum NamespaceAuthority {
    /// No namespace restriction: Basic auth, opaque (`nra_`) tokens, anonymous
    /// reads, auth disabled, or an OIDC provider scoped to `["*"]`.
    Unrestricted,
    /// An OIDC identity restricted to the given scopes.
    Scoped {
        /// Conjunction of scope pattern-sets (segment-aware globs, see
        /// [`crate::validation::namespace_match`]): a namespace is in scope
        /// only if it matches at least one pattern in **every** set. One set
        /// is the provider's `namespace_scope`; a matched rule's
        /// `namespace_scope` adds a second — so a rule can only narrow the
        /// provider scope, never widen past it.
        scopes: Arc<[Arc<[String]>]>,
        /// Provider name, included in deny logs and the metric (never the token).
        provider: Arc<str>,
        /// Whether a mismatch denies (403) or is only audited.
        mode: ScopeEnforcement,
    },
}

impl NamespaceAuthority {
    /// Build an authority from a single `namespace_scope`.
    ///
    /// A scope containing a bare `*` collapses to [`NamespaceAuthority::Unrestricted`]
    /// so the default `namespace_scope = ["*"]` is a true no-op. An empty scope
    /// (`[]`) stays `Scoped` with no patterns and therefore denies every write
    /// (fail-closed) — a deliberate operator lockout.
    #[cfg(test)]
    pub fn from_oidc_scope(provider: &str, scope: &[String], mode: ScopeEnforcement) -> Self {
        Self::from_oidc_scopes(provider, [scope], mode)
    }

    /// Build an authority from a conjunction of scopes, all of which a write
    /// must satisfy (provider scope + optional per-rule scope).
    ///
    /// Each set collapses independently: a set containing a bare `*` is
    /// unrestricted and drops out of the conjunction; if every set drops out
    /// the authority is [`NamespaceAuthority::Unrestricted`]. An empty set
    /// (`[]`) is kept and denies every write (fail-closed), exactly as in
    /// [`NamespaceAuthority::from_oidc_scope`].
    pub fn from_oidc_scopes<'a>(
        provider: &str,
        scopes: impl IntoIterator<Item = &'a [String]>,
        mode: ScopeEnforcement,
    ) -> Self {
        let scopes: Vec<Arc<[String]>> = scopes
            .into_iter()
            .filter(|scope| !scope.iter().any(|p| p == "*"))
            .map(Arc::from)
            .collect();
        if scopes.is_empty() {
            return NamespaceAuthority::Unrestricted;
        }
        NamespaceAuthority::Scoped {
            scopes: Arc::from(scopes),
            provider: Arc::from(provider),
            mode,
        }
    }
}

/// A write was denied because its artifact coordinate fell outside the
/// authenticated OIDC identity's `namespace_scope`. Callers map this to HTTP 403
/// and must not touch storage (fail-closed).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NamespaceDenied;

/// Enforce an OIDC `namespace_scope` against the artifact `namespace` coordinate
/// a write handler is about to act on.
///
/// `namespace` MUST be the canonical artifact coordinate the handler derived
/// (docker image name, npm package, raw path, …) — never the raw URL path and
/// never the storage key, which carry transport prefixes/suffixes that would make
/// scoping format-dependent and bypassable.
///
/// Returns `Ok(())` for an [`NamespaceAuthority::Unrestricted`] authority, when
/// `namespace` matches a scope pattern, or when the provider is in
/// [`ScopeEnforcement::Audit`] mode (the mismatch is logged and counted as
/// `would_deny`, but allowed). Returns `Err(NamespaceDenied)` only for an
/// enforced mismatch. Every decision increments `nora_auth_namespace_scope_total`.
pub fn enforce_namespace_scope(
    authority: &NamespaceAuthority,
    namespace: &str,
) -> Result<(), NamespaceDenied> {
    let (scopes, provider, mode) = match authority {
        NamespaceAuthority::Unrestricted => return Ok(()),
        NamespaceAuthority::Scoped {
            scopes,
            provider,
            mode,
        } => (scopes, provider, *mode),
    };
    // Use `provider` as `&str` for the metric label slices below. The mixed
    // `&[&Arc<str>, &'static str]` array relied on element LUB coercion, which the
    // Kani verifier's pinned rustc rejects (E0308) where stable accepts it — this
    // explicit deref makes both elements `&str` and compiles under both toolchains.
    let provider: &str = provider;

    if scopes
        .iter()
        .all(|scope| scope.iter().any(|p| namespace_match(p, namespace)))
    {
        NAMESPACE_SCOPE_DECISIONS
            .with_label_values(&[provider, "allow"])
            .inc();
        return Ok(());
    }

    match mode {
        ScopeEnforcement::Enforce => {
            NAMESPACE_SCOPE_DECISIONS
                .with_label_values(&[provider, "deny"])
                .inc();
            tracing::warn!(
                provider = %provider,
                namespace = %namespace,
                scopes = ?scopes,
                "OIDC namespace_scope denied write outside provider scope"
            );
            Err(NamespaceDenied)
        }
        ScopeEnforcement::Audit => {
            NAMESPACE_SCOPE_DECISIONS
                .with_label_values(&[provider, "would_deny"])
                .inc();
            tracing::warn!(
                provider = %provider,
                namespace = %namespace,
                scopes = ?scopes,
                "OIDC namespace_scope (audit) would have denied write outside provider scope"
            );
            Ok(())
        }
    }
}

