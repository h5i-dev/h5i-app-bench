use kanidm_kernel::softlock::*;
use std::time::Duration;
#[path="../../difftest/softlock_reference.rs"]
#[allow(dead_code)]
mod upstream;
fn duration(t: Time) -> Duration { Duration::new(t.secs,t.nanos) }
fn snapshot(s: State) -> (u8,usize,Duration,Duration) {
    match s {
        State::Init => (0,0,Duration::ZERO,Duration::ZERO),
        State::Locked { count, reset_at, unlock_at } => (1,count,duration(reset_at),duration(unlock_at)),
        State::Unlocked(n,t) => (2,n,duration(t),Duration::ZERO),
    }
}
fn compare(policy: Policy, state: State, last: Time, now: Time, expiry: Option<Time>, action: u8) {
    let (p,step) = match policy { Policy::Password=>(0,0),Policy::Totp(s)=>(1,s),Policy::Webauthn=>(2,0),Policy::Unrestricted=>(3,0) };
    let lock = SoftLock { state,policy,last_expire_at:last };
    let got = if action==0 { apply_time_step(lock,now,expiry) } else { record_failure(lock,now) };
    let expected = upstream::reference(p,step,snapshot(state),duration(last),action,duration(now),expiry.map(duration));
    assert_eq!((snapshot(got.state),duration(got.last_expire_at),is_valid(&got)),expected,
        "policy={policy:?} state={state:?} last={last:?} now={now:?} expiry={expiry:?} action={action}");
}
#[test]
fn softlock_differential() {
    // Fixed deterministic generator, all state fields compared after each operation.
    let mut seed = 0x6b616e69646d2026u64;
    let mut next = || { seed ^= seed<<13; seed ^= seed>>7; seed ^= seed<<17; seed };
    for _ in 0..150_000 {
        let mut time = || Time { secs:next()%200_000, nanos:(next()%1_000_000_000) as u32 };
        let now=time(); let reset=time(); let unlock=time(); let last=time(); let exp=time();
        let policy = match next()%4 { 0=>Policy::Password,1=>Policy::Totp(1+next()%120),2=>Policy::Webauthn,_=>Policy::Unrestricted };
        let n = (next()%150) as usize;
        let state = match next()%3 { 0=>State::Init,1=>State::Locked { count:n,reset_at:reset,unlock_at:unlock },_=>State::Unlocked(n,reset) };
        compare(policy,state,last,now,Some(exp),0);
        compare(policy,state,last,now,Some(last),0);
        compare(policy,state,last,now,None,0);
        compare(policy,state,last,now,None,1);
    }
    // Exact boundaries and one nanosecond either side, plus threshold counts.
    for policy in [Policy::Password,Policy::Totp(30),Policy::Webauthn,Policy::Unrestricted] {
        for secs in [0,1,29,30,31,86399,86400,86401] {
            for nanos in [0,1,999_999_999] {
                let t=Time{secs,nanos};
                for count in [0,1,2,3,8,9,24,25,99,100,101] {
                    let state=State::Locked{count,reset_at:t,unlock_at:t};
                    compare(policy,state,t,t,None,0);
                    compare(policy,state,t,t,Some(t),0);
                    compare(policy,state,t,t,None,1);
                }
            }
        }
    }
}
