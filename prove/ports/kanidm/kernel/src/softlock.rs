//! Credential throttling, kanidm f608c4f, credential/softlock.rs.
//! Duration is represented by its canonical seconds/nanoseconds pair.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Time { pub secs: u64, pub nanos: u32 }
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Policy { Password, Totp(u64), Webauthn, Unrestricted }
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum State {
    Init,
    Locked { count: usize, reset_at: Time, unlock_at: Time },
    Unlocked(usize, Time),
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct SoftLock { pub state: State, pub policy: Policy, pub last_expire_at: Time }

pub fn after(a: Time, b: Time) -> bool {
    a.secs > b.secs || (a.secs == b.secs && a.nanos > b.nanos)
}
pub fn same_time(a: Time, b: Time) -> bool { a.secs == b.secs && a.nanos == b.nanos }
pub fn plus_seconds(t: Time, seconds: u64) -> Time {
    Time { secs: t.secs + seconds, nanos: t.nanos }
}
pub fn failure_next_state(policy: Policy, count: usize, ct: Time) -> State {
    match policy {
        Policy::Password => {
            let next_day_end = ct.secs + 86400;
            let rem = next_day_end % 86400;
            let reset_at = Time { secs: next_day_end - rem, nanos: 0 };
            let unlock_at = if count < 3 { plus_seconds(ct, 1) }
                else if count < 9 { plus_seconds(ct, 3) }
                else if count < 25 { plus_seconds(ct, 5) }
                else if count < 100 { plus_seconds(ct, 10) }
                else { reset_at };
            State::Locked { count, reset_at, unlock_at }
        }
        Policy::Totp(step) => {
            let next_window_end = ct.secs + step;
            let rem = next_window_end % step;
            let reset_at = Time { secs: next_window_end - rem, nanos: 0 };
            let unlock_at = if count >= 3 { reset_at } else { plus_seconds(ct, 1) };
            State::Locked { count, reset_at, unlock_at }
        }
        Policy::Webauthn => {
            let next = plus_seconds(ct, 1);
            State::Locked { count, reset_at: next, unlock_at: next }
        }
        Policy::Unrestricted => State::Init,
    }
}
pub fn new(policy: Policy) -> SoftLock {
    SoftLock { state: State::Init, policy, last_expire_at: Time { secs: 0, nanos: 0 } }
}
pub fn apply_time_step(mut lock: SoftLock, ct: Time, expire_at: Option<Time>) -> SoftLock {
    lock.state = match lock.state {
        State::Init => State::Init,
        State::Locked { count, mut reset_at, unlock_at } => {
            if let Some(expiry) = expire_at {
                if !same_time(lock.last_expire_at, expiry) {
                    lock.last_expire_at = expiry;
                    if after(reset_at, expiry) { reset_at = expiry; }
                }
            }
            if after(ct, reset_at) { State::Init }
            else if after(ct, unlock_at) { State::Unlocked(count, reset_at) }
            else { State::Locked { count, reset_at, unlock_at } }
        }
        State::Unlocked(count, reset_at) => {
            if after(ct, reset_at) { State::Init }
            else { State::Unlocked(count, reset_at) }
        }
    };
    lock
}
pub fn is_valid(lock: &SoftLock) -> bool {
    !matches!(lock.state, State::Locked { .. })
}
pub fn record_failure(mut lock: SoftLock, ct: Time) -> SoftLock {
    lock.state = match lock.state {
        State::Init => failure_next_state(lock.policy, 1, ct),
        State::Locked { count, reset_at: _, unlock_at: _ } => failure_next_state(lock.policy, count + 1, ct),
        State::Unlocked(count, _) => failure_next_state(lock.policy, count + 1, ct),
    };
    lock
}
