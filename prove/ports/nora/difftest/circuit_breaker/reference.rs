// Generated from the pinned source; only clock/derive adapters, see identity.json.
// Copyright (c) 2026 The NORA Authors
// SPDX-License-Identifier: MIT


use crate::config::CircuitBreakerConfig;
use crate::metrics::{CIRCUIT_BREAKER_REJECTIONS, CIRCUIT_BREAKER_STATE};
use crate::registry::ProxyError;
use parking_lot::RwLock;
use std::collections::HashMap;
use crate::Instant;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum BreakerState {
    Closed,
    Open,
    HalfOpen,
}

impl BreakerState {
    fn as_gauge(self) -> i64 {
        match self {
            BreakerState::Closed => 0,
            BreakerState::Open => 1,
            BreakerState::HalfOpen => 2,
        }
    }

    /// Stable string used in the `/health` API. Mirrors the
    /// `nora_circuit_breaker_state` gauge semantics (0=closed, 1=open,
    /// 2=half_open) so operators see the same labels in both places.
    fn as_health_str(self) -> &'static str {
        match self {
            BreakerState::Closed => "closed",
            BreakerState::Open => "open",
            BreakerState::HalfOpen => "half_open",
        }
    }
}

/// Read-only snapshot of one upstream's circuit-breaker state for the `/health`
/// API. Built from cached in-memory state only — never triggers a live upstream
/// probe, so the health endpoint stays fast and non-blocking.
#[derive(Debug, Clone)]
pub(crate) struct UpstreamHealth {
    /// Breaker state: `closed` (healthy), `open` (failing fast), or
    /// `half_open` (probing recovery). The caller reports `disabled` when the
    /// circuit-breaker feature is off.
    pub status: &'static str,
    /// Accumulated consecutive-failure count (resets to 0 on success).
    pub failure_count: u32,
    /// Seconds since the most recent recorded failure, or `null` if the
    /// upstream has not failed since startup.
    pub last_failure_seconds_ago: Option<u64>,
}

/// Identifies the probe a caller was allowed to run, so a later
/// `record_success`/`record_failure`/`record_alive` can be FENCED. When the
/// #585 stall-recovery starts a fresh probe, the old probe is superseded; its
/// late report carries an older generation and must NOT mutate the breaker
/// ("treat as lost" — the comment's intent, now enforced). A non-probe
/// (Closed-path) request carries [`ProbeToken::BACKGROUND`], which is never
/// fenced — its failure simply accrues to the Closed-path tally.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) struct ProbeToken(u64);

impl ProbeToken {
    /// Not a probe — a Closed-path request. Its outcome accrues normally and is
    /// never fenced.
    pub(crate) const BACKGROUND: ProbeToken = ProbeToken(0);
}

#[derive(Debug)]
struct BreakerInner {
    state: BreakerState,
    failures: u32,
    last_failure: Option<Instant>,
    half_open_in_flight: bool,
    /// When the current half-open probe started. Used to release a probe slot
    /// that was never reported back (a `check()` that returned Ok but whose
    /// caller exited without `record_success`/`record_failure`, e.g. a 4xx or
    /// body-extract path), so the breaker cannot wedge at 503 forever (#585).
    half_open_started: Option<Instant>,
    /// Monotonic generation of the CURRENT probe. Bumped each time `check()`
    /// grants a probe slot (Open→HalfOpen, or a fresh probe after a #585 stall).
    /// A probe holds the generation it was granted; `record_*` fence on it so a
    /// superseded ("lost") probe's late report is ignored (contract
    /// `circuit-breaker-probe-fenced`).
    probe_gen: u64,
}

impl BreakerInner {
    fn new() -> Self {
        Self {
            state: BreakerState::Closed,
            failures: 0,
            last_failure: None,
            half_open_in_flight: false,
            half_open_started: None,
            probe_gen: 0,
        }
    }

    /// Grant a fresh probe slot: bump the generation and return its token.
    fn grant_probe(&mut self) -> ProbeToken {
        self.probe_gen += 1;
        self.half_open_in_flight = true;
        self.half_open_started = Some(Instant::now());
        ProbeToken(self.probe_gen)
    }

    /// True if `token` is NOT the current probe and not a background request —
    /// i.e. a superseded "lost" probe whose report must be ignored.
    fn is_stale(&self, token: ProbeToken) -> bool {
        token != ProbeToken::BACKGROUND && token.0 != self.probe_gen
    }
}

/// Per-registry circuit breaker registry.
///
/// All methods are no-ops when `config.enabled == false`.
pub(crate) struct CircuitBreakerRegistry {
    config: CircuitBreakerConfig,
    breakers: RwLock<HashMap<String, BreakerInner>>,
}

impl CircuitBreakerRegistry {
    pub(crate) fn new(config: CircuitBreakerConfig) -> Self {
        Self {
            config,
            breakers: RwLock::new(HashMap::new()),
        }
    }

    /// Create a disabled (no-op) circuit breaker registry.
    pub(crate) fn noop() -> Self {
        Self::new(CircuitBreakerConfig::default())
    }

    /// Initialize gauge to 0 (Closed) for all known registries so Prometheus
    /// exports the metric immediately, even before any state transition (#441).
    pub(crate) fn init_gauges(&self, registries: &[&str]) {
        if !self.config.enabled {
            return;
        }
        for name in registries {
            CIRCUIT_BREAKER_STATE
                .with_label_values(&[name])
                .set(BreakerState::Closed.as_gauge());
        }
    }

    /// Whether the circuit-breaker feature is enabled (it is disabled by
    /// default). Used by `/health` to report `disabled` instead of a state.
    pub(crate) fn is_enabled(&self) -> bool {
        self.config.enabled
    }

    /// Read-only health snapshot for `registry` from cached in-memory state.
    ///
    /// Never performs a live upstream probe, so it is safe to call from the
    /// `/health` request path. Returns `None` when no breaker has been recorded
    /// for `registry` yet (no proxy traffic since startup), which the caller
    /// renders as a healthy `closed` default. The `last_failure` `Instant` is a
    /// monotonic clock, so the snapshot reports *seconds ago* rather than a
    /// wall-clock timestamp.
    pub(crate) fn health_snapshot(&self, registry: &str) -> Option<UpstreamHealth> {
        let breakers = self.breakers.read();
        let breaker = breakers.get(registry)?;
        Some(UpstreamHealth {
            status: breaker.state.as_health_str(),
            failure_count: breaker.failures,
            last_failure_seconds_ago: breaker.last_failure.map(|t| t.elapsed().as_secs()),
        })
    }

    /// Resolve the failure threshold for a given registry key, checking overrides first.
    fn threshold_for(&self, registry: &str) -> u32 {
        self.config
            .overrides
            .get(registry)
            .and_then(|o| o.failure_threshold)
            .unwrap_or(self.config.failure_threshold)
    }

    /// Resolve the reset timeout for a given registry key, checking overrides first.
    fn reset_timeout_for(&self, registry: &str) -> u64 {
        self.config
            .overrides
            .get(registry)
            .and_then(|o| o.reset_timeout)
            .unwrap_or(self.config.reset_timeout)
    }

    /// Check if a request to `registry` should proceed.
    ///
    /// On success returns a [`ProbeToken`] the caller MUST pass back to
    /// `record_success`/`record_failure`/`record_alive` so a superseded probe's
    /// report can be fenced (#585 stall recovery). A Closed-path request gets
    /// [`ProbeToken::BACKGROUND`]; a HalfOpen probe gets its generation's token.
    /// Returns `Err(ProxyError::CircuitOpen)` if the breaker is open.
    pub(crate) fn check(&self, registry: &str) -> Result<ProbeToken, ProxyError> {
        if !self.config.enabled {
            return Ok(ProbeToken::BACKGROUND);
        }

        let mut breakers = self.breakers.write();
        let breaker = breakers
            .entry(registry.to_string())
            .or_insert_with(BreakerInner::new);

        match breaker.state {
            BreakerState::Closed => Ok(ProbeToken::BACKGROUND),
            BreakerState::Open => {
                let elapsed = breaker
                    .last_failure
                    .map(|t| t.elapsed().as_secs())
                    .unwrap_or(u64::MAX);
                if elapsed >= self.reset_timeout_for(registry) {
                    // Transition to HalfOpen — allow one probe (fresh generation).
                    breaker.state = BreakerState::HalfOpen;
                    let token = breaker.grant_probe();
                    CIRCUIT_BREAKER_STATE
                        .with_label_values(&[registry])
                        .set(BreakerState::HalfOpen.as_gauge());
                    tracing::info!(
                        registry = registry,
                        "Circuit breaker half-open, allowing probe"
                    );
                    Ok(token)
                } else {
                    CIRCUIT_BREAKER_REJECTIONS
                        .with_label_values(&[registry])
                        .inc();
                    Err(ProxyError::CircuitOpen(registry.to_string()))
                }
            }
            BreakerState::HalfOpen => {
                // A probe slot is held until the caller reports back via
                // `record_success`/`record_failure`. Some upstream outcomes
                // exit without reporting (4xx, body-extract error), which would
                // otherwise pin the slot and 503 every request forever. Treat a
                // probe outstanding longer than the reset timeout as lost and
                // start a fresh one (#585). `reset_timeout == 0` is the
                // degenerate "retry immediately" mode and keeps the strict
                // single-probe behavior.
                //
                // The complementary fix (#606): a 4xx upstream probe means the
                // upstream is alive, so call-sites now `record_alive()` which
                // closes the breaker from HalfOpen instead of leaving it to
                // slow-probe here forever.
                let reset = self.reset_timeout_for(registry);
                let probe_stalled = reset > 0
                    && breaker
                        .half_open_started
                        .is_none_or(|t| t.elapsed().as_secs() >= reset);
                if breaker.half_open_in_flight && !probe_stalled {
                    // Probe genuinely in flight — reject additional requests.
                    CIRCUIT_BREAKER_REJECTIONS
                        .with_label_values(&[registry])
                        .inc();
                    Err(ProxyError::CircuitOpen(registry.to_string()))
                } else {
                    if probe_stalled {
                        tracing::warn!(
                            registry = registry,
                            "Circuit breaker probe stalled (no result within reset timeout) — starting fresh probe"
                        );
                    }
                    // Slot free, or previous probe was lost — start a fresh probe
                    // (new generation supersedes the lost one; its late report is
                    // fenced in record_*).
                    let token = breaker.grant_probe();
                    Ok(token)
                }
            }
        }
    }

    /// Record a successful upstream response. `token` is the [`ProbeToken`] from
    /// the matching `check()`; a superseded ("lost") probe's report is fenced.
    pub(crate) fn record_success(&self, registry: &str, token: ProbeToken) {
        if !self.config.enabled {
            return;
        }

        let mut breakers = self.breakers.write();
        let breaker = breakers
            .entry(registry.to_string())
            .or_insert_with(BreakerInner::new);

        // Fence: ignore a superseded ("lost") probe's late report (#585) so it
        // cannot close/free a breaker that a newer probe now owns.
        if breaker.is_stale(token) {
            return;
        }

        if breaker.state != BreakerState::Closed {
            tracing::info!(
                registry = registry,
                previous_state = ?breaker.state,
                "Circuit breaker recovered — closing"
            );
        }
        breaker.state = BreakerState::Closed;
        breaker.failures = 0;
        breaker.half_open_in_flight = false;
        breaker.half_open_started = None;
        CIRCUIT_BREAKER_STATE
            .with_label_values(&[registry])
            .set(BreakerState::Closed.as_gauge());
    }

    /// Record that the upstream is alive and answered, without it being a
    /// successful fetch — specifically a 4xx response (e.g. artifact not found).
    ///
    /// In **HalfOpen** this closes the breaker: the probe proved the upstream is
    /// reachable, which is exactly the recovery #606 wants. In **Closed** it is a
    /// deliberate no-op — a 4xx must NOT reset the accumulated failure count, or
    /// an upstream interleaving 4xx (cache-miss probes) with 5xx (real failures)
    /// would never trip the breaker. This is stronger than `record_success`,
    /// which always resets `failures` and would mask such a partial outage.
    pub(crate) fn record_alive(&self, registry: &str, token: ProbeToken) {
        if !self.config.enabled {
            return;
        }

        let mut breakers = self.breakers.write();
        let breaker = breakers
            .entry(registry.to_string())
            .or_insert_with(BreakerInner::new);

        // Fence: ignore a superseded ("lost") probe's late report (#585).
        if breaker.is_stale(token) {
            return;
        }

        // Only HalfOpen transitions on an "alive" signal; Closed/Open are left
        // untouched so a 4xx never clears a real failure tally.
        if breaker.state == BreakerState::HalfOpen {
            tracing::info!(
                registry = registry,
                "Circuit breaker probe answered (4xx) — closing"
            );
            breaker.state = BreakerState::Closed;
            breaker.failures = 0;
            breaker.half_open_in_flight = false;
            breaker.half_open_started = None;
            CIRCUIT_BREAKER_STATE
                .with_label_values(&[registry])
                .set(BreakerState::Closed.as_gauge());
        }
    }

    /// Record a failed upstream response. `token` is the [`ProbeToken`] from the
    /// matching `check()`; a superseded ("lost") probe's report is fenced so it
    /// cannot re-open or ghost-increment a breaker a newer probe now owns.
    pub(crate) fn record_failure(&self, registry: &str, token: ProbeToken) {
        if !self.config.enabled {
            return;
        }

        let now = Instant::now();
        let mut breakers = self.breakers.write();
        let breaker = breakers
            .entry(registry.to_string())
            .or_insert_with(BreakerInner::new);

        // Fence: ignore a superseded ("lost") probe's late report (#585).
        if breaker.is_stale(token) {
            return;
        }

        match breaker.state {
            BreakerState::Closed => {
                breaker.failures += 1;
                breaker.last_failure = Some(now);
                if breaker.failures >= self.threshold_for(registry) {
                    breaker.state = BreakerState::Open;
                    CIRCUIT_BREAKER_STATE
                        .with_label_values(&[registry])
                        .set(BreakerState::Open.as_gauge());
                    tracing::warn!(
                        registry = registry,
                        failures = breaker.failures,
                        threshold = self.threshold_for(registry),
                        "Circuit breaker OPEN — upstream failing"
                    );
                }
            }
            BreakerState::HalfOpen => {
                // Probe failed — back to Open
                breaker.state = BreakerState::Open;
                breaker.last_failure = Some(now);
                breaker.half_open_in_flight = false;
                breaker.half_open_started = None;
                CIRCUIT_BREAKER_STATE
                    .with_label_values(&[registry])
                    .set(BreakerState::Open.as_gauge());
                tracing::warn!(
                    registry = registry,
                    "Circuit breaker probe failed — re-opening"
                );
            }
            BreakerState::Open => {
                // Already open — just update timestamp
                breaker.last_failure = Some(now);
            }
        }
    }
}

