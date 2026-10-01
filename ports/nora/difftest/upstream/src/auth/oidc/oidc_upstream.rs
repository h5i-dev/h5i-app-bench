// Copied from getnora-io/nora @ f864a9a by extract_upstream.py. Do not edit.
use super::*;
use crate::tokens::Role;

/// Simple glob matching: supports `*` (any chars within segment) and `**` is not needed
/// since sub claims use `:` as separator, not `/`.
/// Patterns: "repo:org/*" matches "repo:org/myrepo:ref:refs/heads/main"
fn glob_match(pattern: &str, value: &str) -> bool {
    if pattern == "*" {
        return true;
    }

    let parts: Vec<&str> = pattern.split('*').collect();
    if parts.len() == 1 {
        // No wildcard — exact match
        return pattern == value;
    }

    // First part must be prefix, last part must be suffix
    let mut remaining = value;

    for (i, part) in parts.iter().enumerate() {
        if part.is_empty() {
            continue;
        }
        if i == 0 {
            // Must start with this
            if !remaining.starts_with(part) {
                return false;
            }
            remaining = &remaining[part.len()..];
        } else if i == parts.len() - 1 {
            // Must end with this
            if !remaining.ends_with(part) {
                return false;
            }
            return true;
        } else {
            // Must contain this
            match remaining.find(part) {
                Some(pos) => remaining = &remaining[pos + part.len()..],
                None => return false,
            }
        }
    }

    true
}
/// Classify a [`OidcValidator::validate_token`] rejection string into a bounded
/// reason label for metrics/logs (#994). The caller still logs the full string;
/// this only buckets it so `nora_auth_oidc_rejected_total{reason}` stays
/// low-cardinality (no issuer/subject/provider in the label).
pub fn classify_rejection(reason: &str) -> &'static str {
    if reason.starts_with("OIDC not enabled") {
        "disabled"
    } else if reason.starts_with("No matching OIDC provider") {
        "no_provider"
    } else if reason.starts_with("Token lifetime") {
        "lifetime_exceeded"
    } else if reason.starts_with("No role rule matches") {
        "no_role_rule"
    } else if reason.starts_with("Symmetric algorithms") || reason.starts_with("Algorithm ") {
        "algorithm"
    } else if reason.contains("JWK") {
        // JWKS fetch/endpoint/key errors ("...JWK...", "JWKS ..."); checked
        // before jwt_invalid because none of those strings contain "JWK".
        "jwks"
    } else if reason.starts_with("Invalid JWT header")
        || reason.starts_with("Cannot decode claims")
        || reason.starts_with("JWT validation failed")
    {
        "jwt_invalid"
    } else {
        "other"
    }
}

impl OidcValidator {
    /// Match subject against provider's role_rules. First match wins.
    /// Returns the role plus the rule's namespace-scope override, if any.
    fn match_role(
        &self,
        provider: &OidcProvider,
        subject: &str,
    ) -> Option<(Role, Option<Vec<String>>)> {
        for rule in &provider.role_rules {
            if glob_match(&rule.pattern, subject) {
                let role = match rule.role.as_str() {
                    "admin" => Role::Admin,
                    "write" => Role::Write,
                    "read" => Role::Read,
                    _ => return None,
                };
                return Some((role, rule.namespace_scope.clone()));
            }
        }
        None
    }

    /// The claims half of `validate_token`, verbatim.
    pub fn validate_claims(&self, provider: &OidcProvider, claims: Claims) -> Result<OidcIdentity, String> {
        // Enforce token lifetime ceiling
        if let (Some(iat), Some(exp)) = (claims.iat, claims.exp) {
            let lifetime = exp.saturating_sub(iat);
            if lifetime > provider.max_token_lifetime_secs {
                return Err(format!(
                    "Token lifetime {} exceeds max {} for provider {}",
                    lifetime, provider.max_token_lifetime_secs, provider.name
                ));
            }
        }

        // Map claims to role via role_rules
        let subject = claims.sub.unwrap_or_default();
        let (role, rule_scope) = self.match_role(provider, &subject).ok_or_else(|| {
            format!(
                "No role rule matches sub='{}' for provider {}",
                subject, provider.name
            )
        })?;

        Ok(OidcIdentity {
            provider: provider.name.clone(),
            subject,
            issuer: provider.issuer.clone(),
            role,
            namespace_scope: provider.namespace_scope.clone(),
            rule_namespace_scope: rule_scope,
            namespace_scope_enforcement: provider.namespace_scope_enforcement,
        })
    }
}
