//! Upstream code compiled from the pinned checkout (see build.rs).
#![allow(dead_code, clippy::all)]

pub mod clock {
    use std::cell::Cell;

    use chrono::{DateTime, Local, NaiveDateTime, TimeZone, Utc};

    thread_local!(static NOW: Cell<i64> = const { Cell::new(0) });

    /// Set the time every clock read returns (nanoseconds since the epoch).
    pub fn set(ns: i64) {
        NOW.with(|c| c.set(ns));
    }

    pub fn now() -> DateTime<Local> {
        Local.timestamp_nanos(NOW.with(Cell::get))
    }

    pub fn utc_now() -> DateTime<Utc> {
        Utc.timestamp_nanos(NOW.with(Cell::get))
    }

    pub fn naive(ns: i64) -> NaiveDateTime {
        Utc.timestamp_nanos(ns).naive_utc()
    }
}

pub mod failed_login {
    include!(concat!(env!("OUT_DIR"), "/failed_login.rs"));

    impl FailedLoginMap {
        /// Seam: read an entry (the map is private upstream).
        pub fn entry(&self, key: &str) -> Option<(u32, i64, i64)> {
            self.0.get(key).map(|f| {
                (f.attempt_count, f.first_attempt.timestamp_nanos_opt().unwrap(), f.last_attempt.timestamp_nanos_opt().unwrap())
            })
        }
    }
}

pub mod utils {
    include!(concat!(env!("OUT_DIR"), "/utils.rs"));
}

pub mod enrollment {
    use chrono::{NaiveDateTime, TimeDelta};
    use tracing::debug;

    /// The fields of `Token` the checks read.
    pub struct Token {
        pub id: String,
        pub used_at: Option<NaiveDateTime>,
        pub expires_at: NaiveDateTime,
    }

    #[derive(Debug, PartialEq, Eq)]
    pub enum TokenError {
        TokenExpired,
        TokenUsed,
    }

    pub type PgConnection = ();

    include!(concat!(env!("OUT_DIR"), "/token_impl.rs"));
}

/// The comparisons; `main` runs them.
pub mod diff {
    use std::ops::RangeInclusive;

    use defguard_kernel as k;
    use rand::{Rng, SeedableRng};
    use rand_chacha::ChaCha8Rng;

    use crate::{clock, enrollment, failed_login, utils};

    const S: i64 = 1_000_000_000;

    /// The tracker: random failures and checks of three names at times that
    /// hit the 60 s window and 300 s timeout exactly, just before and after.
    pub fn lockout(seed: u64, steps: usize) -> (usize, usize) {
        let mut rng = ChaCha8Rng::seed_from_u64(seed);
        let keys = ["alice", "bob", "Alice"];
        let deltas = [0, 1, S, 10 * S, 59 * S, 60 * S, 60 * S + 1, 299 * S, 300 * S, 300 * S + 1, 301 * S, 1000 * S];
        let mut up = failed_login::FailedLoginMap::new();
        let mut km: Vec<k::lockout::FailedLogin> = Vec::new();
        let mut now: i64 = 1_700_000_000 * S;
        let mut blocked = 0;
        for step in 0..steps {
            now += if rng.gen_bool(0.2) { deltas[rng.gen_range(0..deltas.len())] } else { rng.gen_range(0..20 * S) };
            clock::set(now);
            let key = keys[rng.gen_range(0..keys.len())];
            if rng.gen_bool(0.5) {
                up.log_failed_attempt(key);
                km = k::lockout::log_failed_attempt(&km, key.as_bytes(), now);
            } else {
                let r = up.verify_username(key);
                let (m, b) = k::lockout::verify_username(&km, key.as_bytes(), now);
                km = m;
                assert_eq!(r.is_err(), b, "step {step}: verify {key} at {now}");
                if b {
                    blocked += 1;
                }
            }
            for key in keys {
                let ke = k::lockout::find_entry(&km, key.as_bytes())
                    .map(|i| (km[i].attempt_count, km[i].first_attempt, km[i].last_attempt));
                assert_eq!(up.entry(key), ke, "step {step}: entry for {key}");
            }
        }
        (steps, blocked)
    }

    /// `Token::start_session` and `is_session_valid` on random tokens.
    pub fn tokens(seed: u64, cases: usize) -> usize {
        let mut rng = ChaCha8Rng::seed_from_u64(seed);
        let base: i64 = 1_700_000_000 * S;
        let offs = [-601 * S, -600 * S, -1, 0, 1, 599 * S, 600 * S, 601 * S];
        let pick = |rng: &mut ChaCha8Rng| {
            if rng.gen_bool(0.5) { offs[rng.gen_range(0..offs.len())] } else { rng.gen_range(-2000 * S..2000 * S) }
        };
        for case in 0..cases {
            let now = base;
            let expires = base + pick(&mut rng);
            let used = if rng.gen_bool(0.4) { None } else { Some(base + pick(&mut rng)) };
            let timeout_s: u64 = [0, 1, 600, 3600][rng.gen_range(0..4)];
            clock::set(now);
            let mut ut = enrollment::Token { id: "t".into(), used_at: used.map(clock::naive), expires_at: clock::naive(expires) };
            let valid = ut.is_session_valid(timeout_s);
            let r = futures::executor::block_on(ut.start_session(&mut (), timeout_s));
            let kt = k::token::Token { user_id: 1, expires_at: expires, used_at: used, enrollment_type: true };
            let tns = timeout_s as i64 * S;
            assert_eq!(valid, k::token::is_session_valid(&kt, now, tns), "case {case}: is_session_valid");
            let (kt2, kr) = k::token::start_session(&kt, now, tns);
            let ur = r.map(|d| d.and_utc().timestamp_nanos_opt().unwrap()).map_err(|e| match e {
                enrollment::TokenError::TokenExpired => k::token::TokenError::TokenExpired,
                enrollment::TokenError::TokenUsed => k::token::TokenError::TokenUsed,
            });
            assert_eq!(ur, kr, "case {case}: start_session");
            let uu = ut.used_at.map(|d| d.and_utc().timestamp_nanos_opt().unwrap());
            assert_eq!(uu, kt2.used_at, "case {case}: used_at");
        }
        cases
    }

    fn covered(rs: &[(u128, u128)], x: u128) -> bool {
        rs.iter().any(|&(a, b)| a <= x && x <= b)
    }

    /// `merge_ranges` on ports: exact output, or (when a range ends at the
    /// maximum, where upstream's unstable sort can order equal starts
    /// differently) the same covered set. Also counts outputs that overlap.
    pub fn ranges(seed: u64, cases: usize) -> (usize, usize, usize) {
        let mut rng = ChaCha8Rng::seed_from_u64(seed);
        let (mut exact, mut by_set, mut overlapping) = (0, 0, 0);
        for case in 0..cases {
            let n = rng.gen_range(0..8);
            let mut input: Vec<RangeInclusive<u16>> = Vec::new();
            for _ in 0..n {
                let a: u16 = if rng.gen_bool(0.2) { [0, 1, 65534, 65535][rng.gen_range(0..4)] } else { rng.gen_range(0..200) };
                let len: u16 = if rng.gen_bool(0.1) { 65535 } else { rng.gen_range(0..40) };
                let b = a.saturating_add(len);
                input.push(a..=b);
            }
            let up: Vec<(u128, u128)> =
                utils::merge_ranges(input.clone()).into_iter().map(|r| (*r.start() as u128, *r.end() as u128)).collect();
            let kin: Vec<k::ranges::Range> =
                input.iter().map(|r| k::ranges::Range { start: *r.start() as u128, end: *r.end() as u128 }).collect();
            let kout: Vec<(u128, u128)> =
                k::ranges::merge_ranges(&kin, 65535).into_iter().map(|r| (r.start, r.end)).collect();
            let at_max = input.iter().any(|r| *r.end() == 65535);
            if at_max && up != kout {
                let ins: Vec<(u128, u128)> = kin.iter().map(|r| (r.start, r.end)).collect();
                for x in 0..=65535u128 {
                    let c = covered(&ins, x);
                    assert_eq!(covered(&up, x), c, "case {case}: upstream coverage at {x}");
                    assert_eq!(covered(&kout, x), c, "case {case}: kernel coverage at {x}");
                }
                by_set += 1;
            } else {
                assert_eq!(up, kout, "case {case}: {input:?}");
                exact += 1;
            }
            if up.windows(2).any(|w| w[1].0 <= w[0].1) {
                overlapping += 1;
            }
        }
        (exact, by_set, overlapping)
    }
}
