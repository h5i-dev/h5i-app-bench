//! A verified decision core for the Anova oven Pico W controller, as an
//! h5i-app kernel for a microcontroller.
//!
//! `no_std`, no allocation, in the Rust subset Charon and Aeneas translate to
//! Lean. `proofs/` proves, about this code:
//!
//! * `transition_total` / `classify_total`: no command and no classification
//!   input panics (including the `fail_count` saturating increment, which is
//!   guarded, not `+ 1` into an overflow).
//! * `inv_reachable`: in every reachable scheduler state the next poll is
//!   scheduled within `TIER3_SECS` (30 s) — the backoff can never grow without
//!   bound and abandon the server/oven.
//! * `enqueue_keeps_others` / `enqueue_present`: enqueuing one command kind
//!   never evicts another and always leaves that kind pending — a user Stop,
//!   once scheduled, is retained (and the 6-slot shape makes overflow
//!   structurally impossible, so it is never dropped for lack of room).
//! * `user_preempts_poll`: when a user command and a poll are both due, a poll
//!   is popped only if it is strictly sooner; at equal time the user command
//!   wins — a Stop is never starved behind a same-instant poll.
//! * `poll_ok_recovers`: a single successful poll clears `fail_count`, so the
//!   device leaves the offline/backoff regime immediately.
//! * `panic_never_masked` / `coldboot_dominates`: reset classification keeps
//!   its documented precedence (a panic is attributed to the panic even when
//!   the watchdog also fired; a lost RAM image is always a cold boot).
//!
//! This models the pure logic of `anova-oven-pico-core` (`scheduler.rs`,
//! `reset.rs`) and the backoff tiers in `anova-oven-pico/src/api_client.rs`
//! at upstream `robdimsdale/anova-oven-rs@43ac1a7`. The firmware is a
//! display/remote-control panel: it never drives a heating element, and the
//! only network control path is this scheduler feeding coarse
//! start/stop/next-stage commands to a server. See `DEVIATIONS.md`.

#![no_std]

// ------------------------------------------------------------------------
// Poll-health thresholds and backoff tiers.
//
// `OFFLINE_THRESHOLD` and the tier constants mirror
// `anova-oven-pico-core/src/fsm.rs` (`OFFLINE_THRESHOLD`) and
// `anova-oven-pico/src/api_client.rs` (`POLL_BACKOFF_TIER*`,
// `*_POLL_INTERVAL_SECS`).
// ------------------------------------------------------------------------

/// Consecutive fast-poll failures before the server is considered offline.
pub const OFFLINE_THRESHOLD: u64 = 3;

pub const TIER1_FAILS: u64 = 5;
pub const TIER2_FAILS: u64 = 10;
pub const TIER3_FAILS: u64 = 15;

pub const NORMAL_POLL_SECS: u64 = 1;
pub const TIER1_SECS: u64 = 5;
pub const TIER2_SECS: u64 = 15;
pub const TIER3_SECS: u64 = 30;

/// The event kinds the scheduler tracks. Mirrors
/// `scheduler::EventKind`: three polls and three user-initiated commands.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Kind {
    PollStatus,
    PollCurrentCook,
    PollRecipes,
    UserStart,
    UserStop,
    UserNextStage,
}

/// Lower sorts first on an equal execution time. User commands (priority 0)
/// outrank polls (priority 1) at the same instant — `EventKind::priority`.
pub fn priority(k: Kind) -> u8 {
    match k {
        Kind::UserStart => 0,
        Kind::UserStop => 0,
        Kind::UserNextStage => 0,
        Kind::PollStatus => 1,
        Kind::PollCurrentCook => 1,
        Kind::PollRecipes => 1,
    }
}

/// Whether a kind is a user-initiated command (vs a background poll).
pub fn is_user(k: Kind) -> bool {
    match k {
        Kind::UserStart => true,
        Kind::UserStop => true,
        Kind::UserNextStage => true,
        Kind::PollStatus => false,
        Kind::PollCurrentCook => false,
        Kind::PollRecipes => false,
    }
}

/// The scheduler state: one pending slot per kind (dedup by kind, as
/// `scheduler::EventQueue` does — see `DEVIATIONS.md` for why this is a
/// 6-slot record rather than a `heapless::Vec`), plus the consecutive
/// poll-failure counter. A slot holds the event's execution time in whole
/// seconds since boot, or `None` when that kind is not pending.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Queue {
    pub status: Option<u64>,
    pub cook: Option<u64>,
    pub recipes: Option<u64>,
    pub start: Option<u64>,
    pub stop: Option<u64>,
    pub next: Option<u64>,
    pub fail_count: u64,
}

pub const EMPTY: Queue = Queue {
    status: None,
    cook: None,
    recipes: None,
    start: None,
    stop: None,
    next: None,
    fail_count: 0,
};

impl Default for Queue {
    fn default() -> Self {
        EMPTY
    }
}

/// The pending slot for `k`.
pub fn slot(q: &Queue, k: Kind) -> Option<u64> {
    match k {
        Kind::PollStatus => q.status,
        Kind::PollCurrentCook => q.cook,
        Kind::PollRecipes => q.recipes,
        Kind::UserStart => q.start,
        Kind::UserStop => q.stop,
        Kind::UserNextStage => q.next,
    }
}

/// `q` with the slot for `k` set to `v`, every other slot unchanged.
pub fn with_slot(q: &Queue, k: Kind, v: Option<u64>) -> Queue {
    let mut n = *q;
    match k {
        Kind::PollStatus => n.status = v,
        Kind::PollCurrentCook => n.cook = v,
        Kind::PollRecipes => n.recipes = v,
        Kind::UserStart => n.start = v,
        Kind::UserStop => n.stop = v,
        Kind::UserNextStage => n.next = v,
    }
    n
}

/// `EnqueueMode::PreferEarlier` keeps the earlier of the two times; `Replace`
/// overwrites. Modelled as a bool: `replace = false` is `PreferEarlier`.
pub fn enqueue(q: &Queue, k: Kind, time: u64, replace: bool) -> Queue {
    let v = match slot(q, k) {
        None => time,
        Some(existing) => {
            if replace {
                time
            } else if existing < time {
                existing
            } else {
                time
            }
        }
    };
    with_slot(q, k, Some(v))
}

/// Does candidate `(ct, ck)` pop before current best `(bt, bk)`? Orders by
/// execution time, then by priority — `soonest_index`'s comparator.
pub fn better(ct: u64, ck: Kind, bt: u64, bk: Kind) -> bool {
    if ct < bt {
        true
    } else if ct > bt {
        false
    } else {
        priority(ck) < priority(bk)
    }
}

/// Fold one slot into the running best-due event.
pub fn consider(best: Option<(u64, Kind)>, s: Option<u64>, k: Kind, now: u64) -> Option<(u64, Kind)> {
    match s {
        None => best,
        Some(t) => {
            if t > now {
                best
            } else {
                match best {
                    None => Some((t, k)),
                    Some(b) => {
                        if better(t, k, b.0, b.1) {
                            Some((t, k))
                        } else {
                            best
                        }
                    }
                }
            }
        }
    }
}

/// The soonest-due kind at or before `now`, ordered by `(time, priority)`, or
/// `None` if nothing is due.
pub fn soonest_due(q: &Queue, now: u64) -> Option<Kind> {
    let b0 = consider(None, q.status, Kind::PollStatus, now);
    let b1 = consider(b0, q.cook, Kind::PollCurrentCook, now);
    let b2 = consider(b1, q.recipes, Kind::PollRecipes, now);
    let b3 = consider(b2, q.start, Kind::UserStart, now);
    let b4 = consider(b3, q.stop, Kind::UserStop, now);
    let b5 = consider(b4, q.next, Kind::UserNextStage, now);
    match b5 {
        None => None,
        Some(b) => Some(b.1),
    }
}

/// Pop the soonest-due event: clear its slot and report which kind popped.
pub fn pop_due(q: &Queue, now: u64) -> (Queue, Option<Kind>) {
    match soonest_due(q, now) {
        None => (*q, None),
        Some(k) => (with_slot(q, k, None), Some(k)),
    }
}

/// The poll interval for a failure count: a monotone, bounded backoff. The
/// caller clamps the floor per endpoint (`.max(NORMAL/COOK/RECIPE)`); this is
/// the tier choice itself — `ApiRuntime::next_poll_interval_secs`.
pub fn next_poll_interval(fail_count: u64) -> u64 {
    if fail_count >= TIER3_FAILS {
        TIER3_SECS
    } else if fail_count >= TIER2_FAILS {
        TIER2_SECS
    } else if fail_count >= TIER1_FAILS {
        TIER1_SECS
    } else {
        NORMAL_POLL_SECS
    }
}

/// Whether the server is considered offline — `ApiSnapshot::is_offline`.
pub fn is_offline(fail_count: u64) -> bool {
    fail_count >= OFFLINE_THRESHOLD
}

/// `fail_count + 1`, capped at `TIER3_FAILS`. Beyond the top backoff tier the
/// exact count changes no decision (the poll interval and the offline flag are
/// already saturated), so the kernel stops counting at the tier instead of
/// tracking an unbounded value. Upstream keeps a `saturating_add(1)` counter
/// for its logs; its *decisions* (`next_poll_interval`, `is_offline`) are
/// identical once past `TIER3_FAILS`. The cap also makes the `+ 1` provably
/// panic-free. See `DEVIATIONS.md`.
pub fn incr_sat(x: u64) -> u64 {
    if x >= TIER3_FAILS {
        TIER3_FAILS
    } else {
        x + 1
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Command {
    /// Schedule (or re-time) an event of this kind.
    Enqueue { kind: Kind, time: u64, replace: bool },
    /// Pop the soonest-due event at or before `now`.
    PopDue { now: u64 },
    /// A `/status` poll succeeded: clear the failure count.
    PollOk,
    /// A `/status` poll failed: bump the failure count (saturating).
    PollFail,
    /// Report poll health without changing state.
    Peek,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Reply {
    Queued,
    Popped(Option<Kind>),
    Health {
        fail_count: u64,
        interval: u64,
        offline: bool,
    },
}

/// This kernel refuses nothing; the type mirrors the thermostat template.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    Never,
}

/// One scheduler step: the next state (`Some`) or nothing to write (`None`),
/// and the reply.
pub fn transition(s: &Queue, cmd: &Command) -> Result<(Option<Queue>, Reply), Error> {
    match cmd {
        Command::Enqueue { kind, time, replace } => {
            let n = enqueue(s, *kind, *time, *replace);
            Ok((Some(n), Reply::Queued))
        }
        Command::PopDue { now } => {
            let (n, popped) = pop_due(s, *now);
            Ok((Some(n), Reply::Popped(popped)))
        }
        Command::PollOk => {
            let mut n = *s;
            n.fail_count = 0;
            Ok((Some(n), Reply::Queued))
        }
        Command::PollFail => {
            let mut n = *s;
            n.fail_count = incr_sat(s.fail_count);
            Ok((Some(n), Reply::Queued))
        }
        Command::Peek => Ok((
            None,
            Reply::Health {
                fail_count: s.fail_count,
                interval: next_poll_interval(s.fail_count),
                offline: is_offline(s.fail_count),
            },
        )),
    }
}

pub fn apply(s: &Queue, w: &Option<Queue>) -> Queue {
    match w {
        Some(n) => *n,
        None => *s,
    }
}

/// `Peek` writes nothing.
pub fn read_only(cmd: &Command) -> bool {
    match cmd {
        Command::Peek => true,
        _ => false,
    }
}

// ------------------------------------------------------------------------
// Reset classification — `anova-oven-pico-core/src/reset.rs`.
// ------------------------------------------------------------------------

/// What caused the boot we are currently in. Mirrors `reset::ResetReason`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ResetReason {
    Unknown,
    ColdBoot,
    Panic,
    WatchdogTimeout,
    WatchdogForced,
    OtherSoftReset,
    InitTimeout,
}

pub const INIT_STAGE_WIFI: u32 = 100;
pub const INIT_STAGE_DHCP: u32 = 101;

pub fn is_init_stage(s: u32) -> bool {
    s == INIT_STAGE_WIFI || s == INIT_STAGE_DHCP
}

/// Decode a stored `u32` to a `ResetReason`, mapping unknown values to
/// `Unknown` (forward compatibility) — `ResetReason::from_u32`.
pub fn reset_from_u32(v: u32) -> ResetReason {
    match v {
        1 => ResetReason::ColdBoot,
        2 => ResetReason::Panic,
        3 => ResetReason::WatchdogTimeout,
        4 => ResetReason::WatchdogForced,
        5 => ResetReason::OtherSoftReset,
        6 => ResetReason::InitTimeout,
        _ => ResetReason::Unknown,
    }
}

/// Encode a `ResetReason` as its stored `u32` (the `#[repr(u32)]` value).
pub fn reset_to_u32(r: ResetReason) -> u32 {
    match r {
        ResetReason::Unknown => 0,
        ResetReason::ColdBoot => 1,
        ResetReason::Panic => 2,
        ResetReason::WatchdogTimeout => 3,
        ResetReason::WatchdogForced => 4,
        ResetReason::OtherSoftReset => 5,
        ResetReason::InitTimeout => 6,
    }
}

/// Classify the cause of this boot from the breadcrumbs and watchdog bits,
/// with the documented precedence — `reset::classify_reset`:
/// cold boot (lost RAM) dominates everything; a panic is attributed to the
/// panic even if the watchdog fired too; then watchdog timer, watchdog force,
/// an init-stage soft reset, and finally a plain soft reset.
pub fn classify_reset(
    magic_was_valid: bool,
    panic_count_advanced: bool,
    last_app_state: u32,
    watchdog_timer: bool,
    watchdog_force: bool,
) -> ResetReason {
    if !magic_was_valid {
        ResetReason::ColdBoot
    } else if panic_count_advanced {
        ResetReason::Panic
    } else if watchdog_timer {
        ResetReason::WatchdogTimeout
    } else if watchdog_force {
        ResetReason::WatchdogForced
    } else if is_init_stage(last_app_state) {
        ResetReason::InitTimeout
    } else {
        ResetReason::OtherSoftReset
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn run(s: Queue, c: Command) -> Queue {
        let (w, _) = transition(&s, &c).unwrap();
        apply(&s, &w)
    }

    #[test]
    fn enqueue_dedups_and_prefers_earlier() {
        let q = enqueue(&EMPTY, Kind::PollStatus, 100, false);
        let q = enqueue(&q, Kind::PollStatus, 50, false);
        let q = enqueue(&q, Kind::PollStatus, 200, false);
        assert_eq!(q.status, Some(50));
        // other slots untouched
        assert_eq!(q.stop, None);
    }

    #[test]
    fn replace_overwrites() {
        let q = enqueue(&EMPTY, Kind::PollStatus, 100, false);
        let q = enqueue(&q, Kind::PollStatus, 200, true);
        assert_eq!(q.status, Some(200));
    }

    #[test]
    fn user_command_beats_poll_at_equal_time() {
        let q = enqueue(&EMPTY, Kind::PollStatus, 100, false);
        let q = enqueue(&q, Kind::UserStop, 100, false);
        let (_, popped) = pop_due(&q, 100);
        assert_eq!(popped, Some(Kind::UserStop));
    }

    #[test]
    fn overdue_poll_beats_just_enqueued_command() {
        let q = enqueue(&EMPTY, Kind::PollStatus, 50, false);
        let q = enqueue(&q, Kind::UserStop, 100, false);
        let (_, popped) = pop_due(&q, 100);
        assert_eq!(popped, Some(Kind::PollStatus));
    }

    #[test]
    fn pop_nothing_when_not_due() {
        let q = enqueue(&EMPTY, Kind::PollStatus, 1000, false);
        let (_, popped) = pop_due(&q, 500);
        assert_eq!(popped, None);
    }

    #[test]
    fn backoff_tiers() {
        assert_eq!(next_poll_interval(0), 1);
        assert_eq!(next_poll_interval(4), 1);
        assert_eq!(next_poll_interval(5), 5);
        assert_eq!(next_poll_interval(10), 15);
        assert_eq!(next_poll_interval(15), 30);
        assert_eq!(next_poll_interval(1000), 30);
    }

    #[test]
    fn poll_ok_recovers() {
        let mut q = EMPTY;
        q.fail_count = 42;
        let q = run(q, Command::PollOk);
        assert_eq!(q.fail_count, 0);
        assert!(!is_offline(q.fail_count));
        assert_eq!(next_poll_interval(q.fail_count), 1);
    }

    #[test]
    fn poll_fail_caps_at_tier3() {
        let mut q = EMPTY;
        q.fail_count = TIER3_FAILS;
        let q = run(q, Command::PollFail);
        assert_eq!(q.fail_count, TIER3_FAILS);
        // Decisions are already saturated at the top tier.
        assert_eq!(next_poll_interval(q.fail_count), TIER3_SECS);
        assert!(is_offline(q.fail_count));
    }

    #[test]
    fn classify_precedence() {
        assert_eq!(
            classify_reset(false, true, INIT_STAGE_WIFI, true, true),
            ResetReason::ColdBoot
        );
        assert_eq!(classify_reset(true, true, 0, true, true), ResetReason::Panic);
        assert_eq!(classify_reset(true, false, 0, true, false), ResetReason::WatchdogTimeout);
        assert_eq!(classify_reset(true, false, 0, false, true), ResetReason::WatchdogForced);
        assert_eq!(
            classify_reset(true, false, INIT_STAGE_DHCP, false, false),
            ResetReason::InitTimeout
        );
        assert_eq!(classify_reset(true, false, 3, false, false), ResetReason::OtherSoftReset);
    }
}
