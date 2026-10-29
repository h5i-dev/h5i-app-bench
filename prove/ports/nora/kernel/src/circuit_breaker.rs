//! One registry's circuit-breaker decisions at f864a9a.
//! Locks/map lookup, logging/metrics, and monotonic elapsed-time reads are adapter
//! boundaries. Instant fields hold their elapsed seconds at this invocation;
//! a freshly written Instant is represented by Some(0). The adapter advances
//! ages between calls. Counter overflow is excluded by the proof preconditions.
#[derive(Clone, Copy)]
pub enum Phase {
    Closed,
    Open,
    HalfOpen,
}
#[derive(Clone, Copy)]
pub struct Breaker {
    pub phase: Phase,
    pub failures: u32,
    pub failure_age: Option<u64>,
    pub in_flight: bool,
    pub probe_age: Option<u64>,
    pub generation: u64,
}
pub fn new() -> Breaker {
    Breaker {
        phase: Phase::Closed,
        failures: 0,
        failure_age: None,
        in_flight: false,
        probe_age: None,
        generation: 0,
    }
}
pub fn is_stale(b: &Breaker, token: u64) -> bool {
    token != 0 && token != b.generation
}
pub fn grant_probe(mut b: Breaker) -> (Breaker, u64) {
    b.generation += 1;
    b.in_flight = true;
    b.probe_age = Some(0);
    let token = b.generation;
    (b, token)
}
/// None means CircuitOpen for the registry being checked.
pub fn check(mut b: Breaker, enabled: bool, reset: u64) -> (Breaker, Option<u64>) {
    if !enabled {
        return (b, Some(0));
    }
    match b.phase {
        Phase::Closed => (b, Some(0)),
        Phase::Open => {
            let elapsed = match b.failure_age {
                Some(n) => n,
                None => u64::MAX,
            };
            if elapsed >= reset {
                b.phase = Phase::HalfOpen;
                let (b, token) = grant_probe(b);
                (b, Some(token))
            } else {
                (b, None)
            }
        }
        Phase::HalfOpen => {
            let stalled = reset > 0
                && match b.probe_age {
                    None => true,
                    Some(age) => age >= reset,
                };
            if b.in_flight && !stalled {
                (b, None)
            } else {
                let (b, token) = grant_probe(b);
                (b, Some(token))
            }
        }
    }
}
pub fn record_success(mut b: Breaker, enabled: bool, token: u64) -> Breaker {
    if !enabled || is_stale(&b, token) {
        return b;
    }
    b.phase = Phase::Closed;
    b.failures = 0;
    b.in_flight = false;
    b.probe_age = None;
    b
}
pub fn record_alive(mut b: Breaker, enabled: bool, token: u64) -> Breaker {
    if !enabled || is_stale(&b, token) {
        return b;
    }
    match b.phase {
        Phase::HalfOpen => {
            b.phase = Phase::Closed;
            b.failures = 0;
            b.in_flight = false;
            b.probe_age = None;
        }
        _ => {}
    }
    b
}
pub fn record_failure(mut b: Breaker, enabled: bool, token: u64, threshold: u32) -> Breaker {
    if !enabled || is_stale(&b, token) {
        return b;
    }
    match b.phase {
        Phase::Closed => {
            b.failures += 1;
            b.failure_age = Some(0);
            if b.failures >= threshold {
                b.phase = Phase::Open;
            }
        }
        Phase::HalfOpen => {
            b.phase = Phase::Open;
            b.failure_age = Some(0);
            b.in_flight = false;
            b.probe_age = None;
        }
        Phase::Open => {
            b.failure_age = Some(0);
        }
    }
    b
}
pub fn threshold(default: u32, override_value: Option<u32>) -> u32 {
    match override_value {
        Some(x) => x,
        None => default,
    }
}
pub fn reset_timeout(default: u64, override_value: Option<u64>) -> u64 {
    match override_value {
        Some(x) => x,
        None => default,
    }
}
