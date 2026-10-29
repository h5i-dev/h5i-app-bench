//! Differential decisions against pinned, otherwise verbatim upstream methods.
#![allow(dead_code)]
extern crate self as parking_lot;
extern crate self as tracing;
use nora_kernel::circuit_breaker::{self as candidate, Breaker, Phase};

#[macro_export]
macro_rules! info { ($($tt:tt)*) => {{}} }
#[macro_export]
macro_rules! warn { ($($tt:tt)*) => {{}} }

#[derive(Debug)]
pub struct RwLock<T>(std::sync::RwLock<T>);
impl<T> RwLock<T> {
    pub fn new(x: T) -> Self { Self(std::sync::RwLock::new(x)) }
    pub fn read(&self) -> std::sync::RwLockReadGuard<'_, T> { self.0.read().unwrap() }
    pub fn write(&self) -> std::sync::RwLockWriteGuard<'_, T> { self.0.write().unwrap() }
}
#[derive(Debug, Clone, Copy)]
struct Instant(u64);
impl Instant {
    fn now() -> Self { Self(u64::MAX) }
    fn elapsed(self) -> std::time::Duration {
        std::time::Duration::from_secs(u64::MAX - self.0)
    }
}
mod config {
    #[derive(Default)]
    pub struct Override { pub failure_threshold: Option<u32>, pub reset_timeout: Option<u64> }
    #[derive(Default)]
    pub struct CircuitBreakerConfig {
        pub enabled: bool, pub failure_threshold: u32, pub reset_timeout: u64,
        pub overrides: std::collections::HashMap<String, Override>,
    }
}
mod registry { #[derive(Debug)] pub enum ProxyError { CircuitOpen(String) } }
mod metrics {
    pub struct Metric;
    pub static CIRCUIT_BREAKER_STATE: Metric = Metric;
    pub static CIRCUIT_BREAKER_REJECTIONS: Metric = Metric;
    impl Metric {
        pub fn with_label_values(&self, _: &[&str]) -> &Self { self }
        pub fn set(&self, _: i64) {}
        pub fn inc(&self) {}
    }
}
mod reference {
    include!("../../difftest/circuit_breaker/reference.rs");
    use super::{candidate, Breaker, Phase};
    pub fn run(b: Breaker, enabled: bool, token: u64, threshold: u32, reset: u64, op: u8)
        -> (Breaker, Option<u64>) {
        let cb = CircuitBreakerRegistry::new(crate::config::CircuitBreakerConfig {
            enabled, failure_threshold: threshold, reset_timeout: reset,
            ..Default::default()
        });
        let phase = match b.phase {
            Phase::Closed => BreakerState::Closed, Phase::Open => BreakerState::Open,
            Phase::HalfOpen => BreakerState::HalfOpen,
        };
        cb.breakers.write().insert("r".into(), BreakerInner {
            state: phase, failures: b.failures,
            last_failure: b.failure_age.map(|x| crate::Instant(u64::MAX - x)),
            half_open_in_flight: b.in_flight,
            half_open_started: b.probe_age.map(|x| crate::Instant(u64::MAX - x)),
            probe_gen: b.generation,
        });
        let result = match op {
            0 => cb.check("r").ok().map(|t| t.0),
            1 => { cb.record_success("r", ProbeToken(token)); None }
            2 => { cb.record_alive("r", ProbeToken(token)); None }
            _ => { cb.record_failure("r", ProbeToken(token)); None }
        };
        let map = cb.breakers.read();
        let x = &map["r"];
        (candidate::Breaker {
            phase: match x.state { BreakerState::Closed => Phase::Closed,
                BreakerState::Open => Phase::Open, BreakerState::HalfOpen => Phase::HalfOpen },
            failures: x.failures, failure_age: x.last_failure.map(|t| t.elapsed().as_secs()),
            in_flight: x.half_open_in_flight,
            probe_age: x.half_open_started.map(|t| t.elapsed().as_secs()), generation: x.probe_gen,
        }, result)
    }
}
fn snapshot(b: Breaker) -> (u8, u32, Option<u64>, bool, Option<u64>, u64) {
    (match b.phase { Phase::Closed => 0, Phase::Open => 1, Phase::HalfOpen => 2 },
     b.failures, b.failure_age, b.in_flight, b.probe_age, b.generation)
}
fn compare(b: Breaker, enabled: bool, token: u64, threshold: u32, reset: u64, op: u8) {
    let (expected, expected_token) = reference::run(b, enabled, token, threshold, reset, op);
    let (actual, actual_token) = match op {
        0 => candidate::check(b, enabled, reset),
        1 => (candidate::record_success(b, enabled, token), None),
        2 => (candidate::record_alive(b, enabled, token), None),
        _ => (candidate::record_failure(b, enabled, token, threshold), None),
    };
    assert_eq!((snapshot(actual), actual_token), (snapshot(expected), expected_token),
        "input={:?} enabled={enabled} token={token} threshold={threshold} reset={reset} op={op}", snapshot(b));
}
#[test]
fn pinned_decision_boundaries() {
    // Arbitrary (including unreachable) states, exact counter/timestamp preservation,
    // generation fencing, zero timeout, absent timestamps, and integer boundaries.
    for phase in [Phase::Closed, Phase::Open, Phase::HalfOpen] {
        for enabled in [false, true] {
            for in_flight in [false, true] {
                for failures in [0, 1, 2, u32::MAX - 1] {
                    for generation in [0, 1, 2, u64::MAX - 1] {
                        for token in [0, generation, generation + 1] {
                            for age in [None, Some(0), Some(1), Some(2), Some(u64::MAX)] {
                                for probe_age in [None, Some(0), Some(1), Some(2), Some(u64::MAX)] {
                                    for reset in [0, 1, 2, u64::MAX] {
                                        for threshold in [0, 1, 2, u32::MAX] {
                                            for op in 0..4 {
                                                compare(Breaker { phase, failures, failure_age: age,
                                                    in_flight, probe_age, generation },
                                                    enabled, token, threshold, reset, op);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
