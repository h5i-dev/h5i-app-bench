//! Exhaustive finite enum decisions; see DEVIATIONS.md.
pub mod breaker_state_f11f5e92 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum BreakerState {Closed,Open,HalfOpen}
impl BreakerState {
    pub fn as_gauge(self) -> i64 {
        match self {
            BreakerState::Closed => 0,
            BreakerState::Open => 1,
            BreakerState::HalfOpen => 2,
        }
    }
    
    
    
    pub fn as_health_str(self) -> Vec<u8> {
        match self {
            BreakerState::Closed => Vec::from([99u8, 108u8, 111u8, 115u8, 101u8, 100u8]),
            BreakerState::Open => Vec::from([111u8, 112u8, 101u8, 110u8]),
            BreakerState::HalfOpen => Vec::from([104u8, 97u8, 108u8, 102u8, 95u8, 111u8, 112u8, 101u8, 110u8]),
        }
    }
}
}
pub mod role_a890c86c {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Role {Read,Write,Admin}
impl Role {
    pub fn can_write(&self) -> bool {
        matches!(self, Role::Write | Role::Admin)
    }
    pub fn can_admin(&self) -> bool {
        matches!(self, Role::Admin)
    }
}
}
pub mod lang_986f59b4 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Lang {En,Ru,Zh}
impl Lang {
    pub fn code(&self) -> Vec<u8> {
        match self {
            Lang::En => Vec::from([101u8, 110u8]),
            Lang::Ru => Vec::from([114u8, 117u8]),
            Lang::Zh => Vec::from([122u8, 104u8]),
        }
    }
}
}
