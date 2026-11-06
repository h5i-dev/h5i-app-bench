//! Differential tests: the verified kernel's decisions vs the REAL upstream
//! decision logic in `anova-oven-pico-core@43ac1a7`.
//!
//! Three comparisons:
//!
//! 1. `scheduler` — a random sequence of enqueue/pop operations is replayed
//!    against both upstream's `EventQueue` (a `heapless::Vec` with `min_by` /
//!    `swap_remove`) and the kernel's 6-slot `Queue`. Every pop must agree on
//!    the `(execution_time, priority)` of the event taken — so both
//!    implementations preempt identically (a user command before a poll at the
//!    same instant). Upstream must also never report `QueueOverflow`, which is
//!    what the kernel models structurally.
//!
//! 2. `classify_reset` — exhaustive over all boolean breadcrumbs and a range of
//!    `last_app_state` values: the kernel's `ResetReason` must equal upstream's.
//!
//! 3. `next_poll_interval` — the kernel's backoff tiers vs an oracle copied
//!    verbatim from `anova-oven-pico/src/api_client.rs:161-166` (the function is
//!    private to the firmware bin, so it is replicated here and cited).

use anova_oven_kernel as k;
use anova_oven_pico_core::reset as up_reset;
use anova_oven_pico_core::scheduler as up_sched;
use embassy_time::Instant;
use rand::{Rng, SeedableRng};
use rand::rngs::StdRng;

// ---- Kind mapping -------------------------------------------------------

fn up_kind(i: u8) -> up_sched::EventKind {
    match i % 6 {
        0 => up_sched::EventKind::PollStatus,
        1 => up_sched::EventKind::PollCurrentCook,
        2 => up_sched::EventKind::PollRecipes,
        3 => up_sched::EventKind::ApiStart,
        4 => up_sched::EventKind::ApiStop,
        _ => up_sched::EventKind::ApiNextStage,
    }
}

fn my_kind(i: u8) -> k::Kind {
    match i % 6 {
        0 => k::Kind::PollStatus,
        1 => k::Kind::PollCurrentCook,
        2 => k::Kind::PollRecipes,
        3 => k::Kind::UserStart,
        4 => k::Kind::UserStop,
        _ => k::Kind::UserNextStage,
    }
}

/// Clear the slot for `kind` in the kernel queue (the kernel exposes
/// `with_slot` only via kinds; mirror upstream's `swap_remove`).
fn my_pop(q: &k::Queue, now: u64) -> (k::Queue, Option<(u64, k::Kind)>) {
    match k::soonest_due(q, now) {
        None => (*q, None),
        Some((t, kind)) => (k::with_slot(q, kind, None), Some((t, kind))),
    }
}

#[test]
fn scheduler_matches_upstream() {
    // Distinct, strictly increasing enqueue times so no two pending entries
    // ever share a `(time, priority)`. Upstream breaks such ties by vector
    // order after `swap_remove` (nondeterministic by design; see
    // scheduler.rs `soonest_index`), which the kernel does not reproduce, so
    // ties are excluded here and the kernel's own deterministic tie-break is
    // proved separately (`user_preempts_poll`). With distinct times the two
    // queues stay identical and we can assert the exact popped kind.
    let mut rng = StdRng::seed_from_u64(0xA0_0E_17);
    for _ in 0..4000 {
        let mut uq = up_sched::EventQueue::new();
        let mut mq = k::EMPTY;
        let mut clock: u64 = 0;
        let steps = rng.gen_range(1..40);
        for _ in 0..steps {
            if rng.gen_bool(0.6) {
                // enqueue at a fresh, strictly larger time
                clock += rng.gen_range(1u64..4);
                let ki = rng.gen_range(0u8..6);
                let t = clock;
                let replace = rng.gen_bool(0.5);
                let mode = if replace {
                    up_sched::EnqueueMode::Replace
                } else {
                    up_sched::EnqueueMode::PreferEarlier
                };
                let ur = uq.enqueue(up_kind(ki), Instant::from_ticks(t), mode);
                assert!(
                    ur.is_ok(),
                    "upstream EventQueue overflowed — the kernel models this as \
                     structurally impossible, so this would be a real divergence"
                );
                mq = k::enqueue(&mq, my_kind(ki), t, replace);
            } else {
                // pop at a random instant within the clock's span
                let now = rng.gen_range(0u64..(clock + 5));
                let uev = uq.pop_due(Instant::from_ticks(now));
                let (nq, mev) = my_pop(&mq, now);
                mq = nq;
                match (uev, mev) {
                    (None, None) => {}
                    (Some(ue), Some((mt, mk))) => {
                        assert_eq!(ue.execution_time, Instant::from_ticks(mt), "time");
                        assert_eq!(ue.priority, k::priority(mk), "priority");
                        assert_eq!(ue.kind, up_kind_of(mk), "kind");
                    }
                    (u, m) => panic!(
                        "one popped, the other didn't: up={:?} mine={:?}",
                        u.map(|e| e.kind),
                        m.map(|x| x.1)
                    ),
                }
            }
        }
    }
}

fn up_kind_of(k: k::Kind) -> up_sched::EventKind {
    match k {
        k::Kind::PollStatus => up_sched::EventKind::PollStatus,
        k::Kind::PollCurrentCook => up_sched::EventKind::PollCurrentCook,
        k::Kind::PollRecipes => up_sched::EventKind::PollRecipes,
        k::Kind::UserStart => up_sched::EventKind::ApiStart,
        k::Kind::UserStop => up_sched::EventKind::ApiStop,
        k::Kind::UserNextStage => up_sched::EventKind::ApiNextStage,
    }
}

// ---- reset classification ----------------------------------------------

fn reason_to_u32(r: up_reset::ResetReason) -> u32 {
    r as u32
}

#[test]
fn classify_reset_matches_upstream() {
    for &mv in &[false, true] {
        for &pa in &[false, true] {
            for &wt in &[false, true] {
                for &wf in &[false, true] {
                    for las in [0u32, 1, 2, 8, 9, 99, 100, 101, 102, 255].iter().copied() {
                        let up = up_reset::classify_reset(mv, pa, las, wt, wf);
                        let mine = k::classify_reset(mv, pa, las, wt, wf);
                        assert_eq!(
                            reason_to_u32(up),
                            k::reset_to_u32(mine),
                            "classify_reset diverged at ({mv},{pa},{las},{wt},{wf})"
                        );
                    }
                }
            }
        }
    }
}

#[test]
fn reset_from_u32_matches_upstream() {
    for v in 0u32..=10 {
        let up = up_reset::ResetReason::from_u32(v);
        let mine = k::reset_from_u32(v);
        assert_eq!(reason_to_u32(up), k::reset_to_u32(mine), "from_u32 diverged at {v}");
    }
}

// ---- backoff tiers ------------------------------------------------------
//
// Oracle copied verbatim from anova-oven-pico/src/api_client.rs:161-166 and
// the POLL_BACKOFF_* / *_POLL_INTERVAL_SECS constants at lines 29-34. The
// function `next_poll_interval_secs` is private to the firmware bin, so it is
// replicated here (the only such replication; EventQueue and classify_reset
// are compared against the real crate directly).

const POLL_BACKOFF_TIER1_FAILS: u64 = 5;
const POLL_BACKOFF_TIER2_FAILS: u64 = 10;
const POLL_BACKOFF_TIER3_FAILS: u64 = 15;
const POLL_BACKOFF_TIER1_SECS: u64 = 5;
const POLL_BACKOFF_TIER2_SECS: u64 = 15;
const POLL_BACKOFF_TIER3_SECS: u64 = 30;
const NORMAL_POLL_INTERVAL_SECS: u64 = 1;

fn upstream_next_poll_interval_secs(fail_count: u64) -> u64 {
    match fail_count {
        n if n >= POLL_BACKOFF_TIER3_FAILS => POLL_BACKOFF_TIER3_SECS,
        n if n >= POLL_BACKOFF_TIER2_FAILS => POLL_BACKOFF_TIER2_SECS,
        n if n >= POLL_BACKOFF_TIER1_FAILS => POLL_BACKOFF_TIER1_SECS,
        _ => NORMAL_POLL_INTERVAL_SECS,
    }
}

#[test]
fn backoff_matches_oracle() {
    for fc in 0u64..40 {
        assert_eq!(
            k::next_poll_interval(fc),
            upstream_next_poll_interval_secs(fc),
            "backoff diverged at fail_count={fc}"
        );
    }
    // And the kernel's offline threshold matches fsm::OFFLINE_THRESHOLD.
    assert_eq!(k::OFFLINE_THRESHOLD, anova_oven_pico_core::fsm::OFFLINE_THRESHOLD);
}
