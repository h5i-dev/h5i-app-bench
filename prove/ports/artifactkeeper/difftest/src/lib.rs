//! Runs the kernel and artifact-keeper's own code on the same random inputs.
pub mod upstream;
// The copied code names its modules from the crate root (`crate::api::...`).
pub use upstream::{api, config, error, models, services, util};

pub mod gen;
pub mod shell;

/// Expose the unchanged upstream crate-private helper to the paired benchmark.
#[inline]
pub fn upstream_scopes_grant_access(scopes: &[String], required_scope: &str) -> bool {
    upstream::services::token_service::scopes_grant_access(scopes, required_scope)
}
#[cfg(test)]
mod tests;
#[cfg(test)]
mod props;
