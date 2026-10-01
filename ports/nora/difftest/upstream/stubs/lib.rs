//! Stub crate root: the modules nora's authorization code uses, and the
//! fields of `AppState` it reads.
#![allow(dead_code, unused_imports)]
pub mod auth;
pub mod config;
pub mod metrics;
pub mod tokens;
pub mod validation;

use std::sync::Arc;

#[derive(Clone)]
pub struct AppState {
    pub config: Arc<config::Config>,
    pub auth: Option<Arc<auth::HtpasswdAuth>>,
    pub tokens: Option<Arc<tokens::TokenStore>>,
    pub auth_failures: Arc<auth::AuthFailureTracker>,
    pub oidc: Option<Arc<auth::OidcValidator>>,
}
