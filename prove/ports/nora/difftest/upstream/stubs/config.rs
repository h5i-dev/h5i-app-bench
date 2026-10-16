//! Stub `config`: the copied `TrustedProxies` and `ScopeEnforcement`, and
//! the fields of `Config` the middleware reads.
use serde::{Deserialize, Serialize};
include!("config_upstream.rs");

pub struct AuthConfig {
    pub enabled: bool,
    pub anonymous_read: bool,
    pub public_web_ui: bool,
    pub public_metrics: bool,
    pub docker_anon_pull: bool,
    pub trusted_proxies: TrustedProxies,
}

pub struct ServerConfig {
    pub public_url: Option<String>,
}

pub struct Config {
    pub auth: AuthConfig,
    pub server: ServerConfig,
}
