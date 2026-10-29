"""Reproduce the unmodified softlock reference body from the pinned git object."""
import hashlib, pathlib, subprocess, sys
PIN = 'f608c4fe14dfd8d5df8edeed470bf1fb92060abd'
PATH = 'server/lib/src/credential/softlock.rs'
repo = sys.argv[1]
raw = subprocess.check_output(['git', '--git-dir='+repo, 'show', PIN+':'+PATH])
src = raw.decode().split('\n#[cfg(test)]\nmod tests {')[0]
seam = '''
// Test seam only: construct arbitrary states and expose every state field.
pub fn reference(policy: u8, step: u64, state: (u8, usize, Duration, Duration),
    last: Duration, action: u8, now: Duration, expiry: Option<Duration>)
    -> ((u8, usize, Duration, Duration), Duration, bool) {
    let policy = match policy { 0 => CredSoftLockPolicy::Password,
        1 => CredSoftLockPolicy::Totp(step), 2 => CredSoftLockPolicy::Webauthn,
        _ => CredSoftLockPolicy::Unrestricted };
    let mut lock = CredSoftLock::new(policy);
    lock.state = match state.0 { 0 => LockState::Init,
        1 => LockState::Locked { count: state.1, reset_at: state.2, unlock_at: state.3 },
        _ => LockState::Unlocked(state.1, state.2) };
    lock.last_expire_at = last;
    if action == 0 { lock.apply_time_step(now, expiry); } else { lock.record_failure(now); }
    let valid = lock.is_valid();
    let s = match lock.state { LockState::Init => (0,0,Duration::ZERO,Duration::ZERO),
        LockState::Locked { count, reset_at, unlock_at } => (1,count,reset_at,unlock_at),
        LockState::Unlocked(count, reset_at) => (2,count,reset_at,Duration::ZERO) };
    (s,lock.last_expire_at,valid)
}
'''
out = pathlib.Path(__file__).with_name('softlock_reference.rs')
out.write_text(src+seam)
print(PIN, PATH, 'sha256='+hashlib.sha256(raw).hexdigest(), 'reference='+hashlib.sha256(out.read_bytes()).hexdigest())
