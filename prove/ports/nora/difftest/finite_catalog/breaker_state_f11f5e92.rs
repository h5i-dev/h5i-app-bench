#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum BreakerState {Closed,Open,HalfOpen}
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
fn main(){
println!("as_gauge/Closed\t{:?}",BreakerState::Closed.as_gauge());
println!("as_gauge/Open\t{:?}",BreakerState::Open.as_gauge());
println!("as_gauge/HalfOpen\t{:?}",BreakerState::HalfOpen.as_gauge());
println!("as_health_str/Closed\t{:?}",BreakerState::Closed.as_health_str().as_bytes());
println!("as_health_str/Open\t{:?}",BreakerState::Open.as_health_str().as_bytes());
println!("as_health_str/HalfOpen\t{:?}",BreakerState::HalfOpen.as_health_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(BreakerState::Closed.as_gauge(),nora_kernel::finite_catalog::breaker_state_f11f5e92::BreakerState::Closed.as_gauge(),"breaker_state_f11f5e92/as_gauge/Closed");
assert_eq!(BreakerState::Open.as_gauge(),nora_kernel::finite_catalog::breaker_state_f11f5e92::BreakerState::Open.as_gauge(),"breaker_state_f11f5e92/as_gauge/Open");
assert_eq!(BreakerState::HalfOpen.as_gauge(),nora_kernel::finite_catalog::breaker_state_f11f5e92::BreakerState::HalfOpen.as_gauge(),"breaker_state_f11f5e92/as_gauge/HalfOpen");
assert_eq!(BreakerState::Closed.as_health_str().as_bytes(),nora_kernel::finite_catalog::breaker_state_f11f5e92::BreakerState::Closed.as_health_str(),"breaker_state_f11f5e92/as_health_str/Closed");
assert_eq!(BreakerState::Open.as_health_str().as_bytes(),nora_kernel::finite_catalog::breaker_state_f11f5e92::BreakerState::Open.as_health_str(),"breaker_state_f11f5e92/as_health_str/Open");
assert_eq!(BreakerState::HalfOpen.as_health_str().as_bytes(),nora_kernel::finite_catalog::breaker_state_f11f5e92::BreakerState::HalfOpen.as_health_str(),"breaker_state_f11f5e92/as_health_str/HalfOpen");
}
