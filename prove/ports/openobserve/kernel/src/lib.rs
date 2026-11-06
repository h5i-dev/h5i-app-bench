//! OpenObserve's security decision logic (openobserve/openobserve @ a774547)
//! as an h5i-app kernel: pure functions in the subset of Rust that Charon and
//! Aeneas translate. See ../DEVIATIONS.md for what each module ports.
pub mod auth;
pub mod bytes;
pub mod delegation;
pub mod grpc;
pub mod tables;
