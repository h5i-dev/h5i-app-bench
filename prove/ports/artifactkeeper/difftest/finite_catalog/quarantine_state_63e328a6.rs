#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum QuarantineState {Quarantined,Released,Rejected}
impl QuarantineState {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Quarantined => "quarantined",
            Self::Released => "released",
            Self::Rejected => "rejected",
        }
    }
}
fn main(){
println!("as_str/Quarantined\t{:?}",QuarantineState::Quarantined.as_str().as_bytes());
println!("as_str/Released\t{:?}",QuarantineState::Released.as_str().as_bytes());
println!("as_str/Rejected\t{:?}",QuarantineState::Rejected.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(QuarantineState::Quarantined.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::quarantine_state_63e328a6::QuarantineState::Quarantined.as_str(),"quarantine_state_63e328a6/as_str/Quarantined");
assert_eq!(QuarantineState::Released.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::quarantine_state_63e328a6::QuarantineState::Released.as_str(),"quarantine_state_63e328a6/as_str/Released");
assert_eq!(QuarantineState::Rejected.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::quarantine_state_63e328a6::QuarantineState::Rejected.as_str(),"quarantine_state_63e328a6/as_str/Rejected");
}
