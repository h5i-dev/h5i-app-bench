#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AttestationState {Unverified,Verified,Failed}
impl AttestationState {
    pub fn as_str(self) -> &'static str {
        match self {
            AttestationState::Unverified => "unverified",
            AttestationState::Verified => "verified",
            AttestationState::Failed => "failed",
        }
    }
}
fn main(){
println!("as_str/Unverified\t{:?}",AttestationState::Unverified.as_str().as_bytes());
println!("as_str/Verified\t{:?}",AttestationState::Verified.as_str().as_bytes());
println!("as_str/Failed\t{:?}",AttestationState::Failed.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(AttestationState::Unverified.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::attestation_state_b0946112::AttestationState::Unverified.as_str(),"attestation_state_b0946112/as_str/Unverified");
assert_eq!(AttestationState::Verified.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::attestation_state_b0946112::AttestationState::Verified.as_str(),"attestation_state_b0946112/as_str/Verified");
assert_eq!(AttestationState::Failed.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::attestation_state_b0946112::AttestationState::Failed.as_str(),"attestation_state_b0946112/as_str/Failed");
}
