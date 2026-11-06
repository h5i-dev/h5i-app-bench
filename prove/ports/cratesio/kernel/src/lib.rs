//! crates.io (rust-lang/crates.io @ e0fc83a) as an h5i-app kernel.
//!
//! The decisions that guard publishing: which API token scopes an endpoint
//! accepts, how a request is authenticated (session cookie, then API token),
//! which rights a user has on a crate, when a publish is authorized (API
//! token or Trusted Publishing token), which Trusted Publishing configs a CI
//! token matches, and the publish rate limit. Each module names the upstream
//! code it follows. Text is bytes; database tables are lists of rows;
//! hashing, JWT signatures and the GitHub API are inputs (see DEVIATIONS.md).

pub mod auth;
pub mod bytes;
pub mod scopes;
pub mod validation;
