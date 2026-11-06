//! defguard (DefGuard/defguard @ 12508b4) as an h5i-app kernel: the API's
//! authentication guards, the failed-login lockout of the login handler,
//! enrollment tokens, and the range merging behind firewall rules.
//!
//! Written in the subset of Rust that Charon and Aeneas translate. Each
//! function names the upstream code it follows; the differences are in
//! ../DEVIATIONS.md. Databases, clocks and password hashing are inputs.

pub mod auth;
pub mod lockout;
pub mod ranges;
pub mod token;
