#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AgeGateReviewStatus {Pending,Approved,Rejected}
impl AgeGateReviewStatus {
    fn as_str(&self) -> &'static str {
        match self {
            Self::Pending => "pending",
            Self::Approved => "approved",
            Self::Rejected => "rejected",
        }
    }
}
fn main(){
println!("as_str/Pending\t{:?}",AgeGateReviewStatus::Pending.as_str().as_bytes());
println!("as_str/Approved\t{:?}",AgeGateReviewStatus::Approved.as_str().as_bytes());
println!("as_str/Rejected\t{:?}",AgeGateReviewStatus::Rejected.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(AgeGateReviewStatus::Pending.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::age_gate_review_status_3fdb45b7::AgeGateReviewStatus::Pending.as_str(),"age_gate_review_status_3fdb45b7/as_str/Pending");
assert_eq!(AgeGateReviewStatus::Approved.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::age_gate_review_status_3fdb45b7::AgeGateReviewStatus::Approved.as_str(),"age_gate_review_status_3fdb45b7/as_str/Approved");
assert_eq!(AgeGateReviewStatus::Rejected.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::age_gate_review_status_3fdb45b7::AgeGateReviewStatus::Rejected.as_str(),"age_gate_review_status_3fdb45b7/as_str/Rejected");
}
