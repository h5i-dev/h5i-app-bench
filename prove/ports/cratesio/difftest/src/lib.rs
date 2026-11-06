//! Differential tests of the crates.io kernel against crates.io @ e0fc83a.
//!
//! `crates_io_validation` is linked as the upstream crate itself; the other
//! items are copied verbatim by `build.rs` from the pinned revision, with the
//! few crate types they name stubbed below. Every test uses a fixed seed.

#![allow(dead_code, clippy::all)]

/// `models/token/scopes.rs` `CrateScope`.
pub mod scopes {
    use crates_io_validation::validate_crate_name;
    include!(concat!(env!("OUT_DIR"), "/upstream_scopes.rs"));
}

/// `src/auth.rs` items. Stubs: `EndpointScope` (the same five variants;
/// upstream's derives need diesel), `AuthCheck`'s fields (copied from the
/// struct), `User`'s two lock columns, the error constructors.
pub mod auth {
    use chrono::{DateTime, Utc};
    use http::StatusCode;
    use http::header;
    use http::request::Parts;
    use secrecy::SecretString;

    #[derive(Clone, Copy, Debug, PartialEq, Eq)]
    pub enum EndpointScope {
        PublishNew,
        PublishUpdate,
        TrustedPublishing,
        Yank,
        ChangeOwners,
    }
    pub use crate::scopes::CrateScope;

    pub type BoxedAppError = (StatusCode, String);
    pub type AppResult<T> = Result<T, BoxedAppError>;
    pub fn custom(status: StatusCode, message: impl Into<String>) -> BoxedAppError {
        (status, message.into())
    }
    pub fn account_locked(_reason: &str, _until: Option<DateTime<Utc>>) -> BoxedAppError {
        (StatusCode::FORBIDDEN, "locked".into())
    }

    pub struct User {
        pub account_lock_reason: Option<String>,
        pub account_lock_until: Option<DateTime<Utc>>,
    }

    #[derive(Debug, Clone)]
    pub struct AuthCheck {
        pub allow_token: bool,
        pub endpoint_scope: Option<EndpointScope>,
        pub crate_name: Option<String>,
        pub allow_any_crate_scope: bool,
    }

    include!(concat!(env!("OUT_DIR"), "/upstream_auth_items.rs"));

    /// Wrappers for the private methods, for the tests.
    pub fn endpoint_matches(c: &AuthCheck, s: Option<&Vec<EndpointScope>>) -> bool {
        c.endpoint_scope_matches(s)
    }
    pub fn crate_matches(c: &AuthCheck, s: Option<&Vec<CrateScope>>) -> bool {
        c.crate_scope_matches(s)
    }
    pub fn header_token(h: &AuthHeader) -> &SecretString {
        &h.0
    }
}

/// `crates_io_trustpub` items: `AccessToken` and `extract_workflow_filename`.
pub mod trustpub {
    use rand::distr::{Alphanumeric, SampleString};
    use secrecy::{ExposeSecret, SecretString};
    use sha2::digest::Output;
    use sha2::{Digest, Sha256};
    use std::str::FromStr;
    use regex::regex;
    include!(concat!(env!("OUT_DIR"), "/upstream_trustpub.rs"));

    pub fn workflow_filename(s: &str) -> Option<&str> {
        extract_workflow_filename(s)
    }
}

/// SplitMix64.
pub struct Rng(pub u64);

impl Rng {
    pub fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9e37_79b9_7f4a_7c15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xbf58_476d_1ce4_e5b9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94d0_49bb_1331_11eb);
        z ^ (z >> 31)
    }
    pub fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
    pub fn chance(&mut self, num: u64, den: u64) -> bool {
        self.below(den) < num
    }
    pub fn pick<'a, T>(&mut self, xs: &'a [T]) -> &'a T {
        &xs[self.below(xs.len() as u64) as usize]
    }
    pub fn string(&mut self, alphabet: &[char], len: usize) -> String {
        (0..len).map(|_| *self.pick(alphabet)).collect()
    }
}

#[cfg(test)]
mod tests;
