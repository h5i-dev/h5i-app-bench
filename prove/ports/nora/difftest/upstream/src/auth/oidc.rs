//! Stub `auth/oidc.rs`: JWT decoding and signature checks are replaced by a
//! table from token to claims; the claims half, `match_role`, `glob_match`
//! and `classify_rejection` are copied in `oidc/oidc_upstream.rs`.
use std::collections::HashMap;

pub use crate::config::ScopeEnforcement;
use crate::tokens::Role;

#[path = "oidc/oidc_upstream.rs"]
mod oidc_upstream;
pub use oidc_upstream::classify_rejection;

#[derive(Debug, Clone)]
pub struct OidcRoleRule {
    pub pattern: String,
    pub role: String,
    pub namespace_scope: Option<Vec<String>>,
}

#[derive(Debug, Clone)]
pub struct OidcProvider {
    pub name: String,
    pub issuer: String,
    pub max_token_lifetime_secs: u64,
    pub role_rules: Vec<OidcRoleRule>,
    pub namespace_scope: Vec<String>,
    pub namespace_scope_enforcement: ScopeEnforcement,
}

#[derive(Debug, Clone)]
pub struct Claims {
    pub sub: Option<String>,
    pub iat: Option<u64>,
    pub exp: Option<u64>,
}

#[derive(Debug, Clone)]
pub struct OidcIdentity {
    pub provider: String,
    pub subject: String,
    pub issuer: String,
    pub role: Role,
    pub namespace_scope: Vec<String>,
    pub rule_namespace_scope: Option<Vec<String>>,
    pub namespace_scope_enforcement: ScopeEnforcement,
}

pub struct OidcValidator {
    pub provider: OidcProvider,
    pub active: bool,
    /// Tokens whose signature, issuer and audience check out, with their claims.
    pub jwt: HashMap<String, Claims>,
}

impl OidcValidator {
    pub fn is_active(&self) -> bool {
        self.active
    }

    pub async fn validate_token(&self, token: &str) -> Result<OidcIdentity, String> {
        match self.jwt.get(token) {
            Some(c) => self.validate_claims(&self.provider, c.clone()),
            None => Err("JWT validation failed".to_string()),
        }
    }
}
