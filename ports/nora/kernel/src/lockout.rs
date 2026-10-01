//! `auth/mod.rs` `AuthFailureTracker`. The map is a list of entries; times
//! are nanoseconds on the monotonic clock (`Instant`).
use crate::net::IpAddr;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct FailureEntry {
    pub ip: IpAddr,
    pub failures: u32,
    pub last_failure: u64,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct AuthFailureTracker {
    pub max_failures: u32,
    pub max_lockout_secs: u64,
}

pub const NANOS_PER_SEC: u64 = 1_000_000_000;

fn find(entries: &[FailureEntry], ip: IpAddr) -> Option<FailureEntry> {
    let mut i = 0;
    while i < entries.len() {
        if entries[i].ip == ip {
            return Some(entries[i]);
        }
        i += 1;
    }
    None
}

impl AuthFailureTracker {
    /// `check_blocked`: the remaining lockout in seconds, if locked out.
    pub fn check_blocked(&self, entries: &[FailureEntry], ip: IpAddr, now: u64) -> Option<u64> {
        let e = match find(entries, ip) {
            Some(e) => e,
            None => return None,
        };
        if e.failures < self.max_failures {
            return None;
        }
        let d = e.failures - self.max_failures;
        let exponent = if d < 20 { d } else { 20 };
        let full = 1u64 << exponent;
        let lockout_secs = if full < self.max_lockout_secs { full } else { self.max_lockout_secs };
        // `last_failure.elapsed().as_secs()`
        let elapsed = now.saturating_sub(e.last_failure) / NANOS_PER_SEC;
        if elapsed < lockout_secs {
            Some(lockout_secs - elapsed)
        } else {
            None
        }
    }
}

/// `record_failure`: the entry after one more failure at `now`.
pub fn after_failure(entries: &[FailureEntry], ip: IpAddr, now: u64) -> FailureEntry {
    let failures = match find(entries, ip) {
        Some(e) => e.failures,
        None => 0,
    };
    FailureEntry { ip, failures: failures + 1, last_failure: now }
}
