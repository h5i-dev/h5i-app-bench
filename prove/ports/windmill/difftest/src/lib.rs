//! Differential tests: the windmill kernel against windmill-common and windmill-api-auth
//! @ 9dedc42.
//!
//! Public upstream items are called through the crates (linked from `../upstream-src`,
//! built with `SQLX_OFFLINE=true`). The private resource matchers of
//! `windmill-common/src/scopes.rs` are copied verbatim from the pinned commit by `build.rs`.
//! Inputs come from a fixed-seed splitmix64, so every run checks the same cases. This
//! is evidence of agreement on the tested inputs, not a proof of equivalence.

pub mod upstream_private {
    include!(concat!(env!("OUT_DIR"), "/scopes_private.rs"));
}

/// splitmix64.
pub struct Rng(pub u64);

impl Rng {
    pub fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E37_79B9_7F4A_7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
        z ^ (z >> 31)
    }
    pub fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
    pub fn bool(&mut self) -> bool {
        self.next() & 1 == 1
    }
    pub fn pick<'a>(&mut self, xs: &[&'a str]) -> &'a str {
        xs[self.below(xs.len() as u64) as usize]
    }
}

pub const DOMAINS: &[&str] = &["jobs", "scripts", "apps", "flows", "variables", "resources", "x", ""];
pub const ACTIONS: &[&str] = &["read", "write", "run", "cancel", "delete", "", "Read"];
pub const KINDS: &[&str] = &["scripts", "flows", "f/a/*", ""];
pub const RESOURCES: &[&str] = &[
    "*", "f/a/*", "f/a/x", "f/a", "f/ab/x", "f/ab/*", "f/a/x/*", "f/a/x/y", "u/alice/*",
    "u/alice/s", "u/ali/*", "f/d\u{e9}/*", "f/d\u{e9}x/y", "f/d\u{e9}/z", "", "/*", "f/*", "f",
    "*/x", "f/a*", "g/team",
];

pub fn random_resources(r: &mut Rng) -> Vec<String> {
    let n = if r.below(5) == 0 { 4 + r.below(4) } else { 1 + r.below(4) };
    (0..n).map(|_| r.pick(RESOURCES).to_string()).collect()
}

/// A scope string of 1 to 5 `:`-separated parts, mostly well-formed.
pub fn random_scope(r: &mut Rng) -> String {
    let d = r.pick(DOMAINS);
    let a = r.pick(ACTIONS);
    match r.below(7) {
        0 => d.to_string(),
        1 | 2 => format!("{d}:{a}"),
        3 | 4 => format!("{d}:{a}:{}", random_resources(r).join(",")),
        5 => format!("jobs:run:{}:{}", r.pick(KINDS), random_resources(r).join(",")),
        _ => format!("{d}:{a}:{}:{}:{}", r.pick(KINDS), r.pick(RESOURCES), r.pick(RESOURCES)),
    }
}

pub fn b(s: &str) -> Vec<u8> {
    s.as_bytes().to_vec()
}

pub fn bl(v: &[String]) -> Vec<Vec<u8>> {
    v.iter().map(|s| b(s)).collect()
}

#[cfg(test)]
mod scopes_tests;
#[cfg(test)]
mod authz_tests;
