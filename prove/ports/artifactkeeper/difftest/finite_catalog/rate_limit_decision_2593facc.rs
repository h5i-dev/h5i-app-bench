#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum RateLimitDecision {Allowed,RecipientLimited,DomainLimited}
impl RateLimitDecision {
    /// Stable label string for Prometheus.
    pub fn label(self) -> &'static str {
        match self {
            RateLimitDecision::Allowed => "allowed",
            RateLimitDecision::RecipientLimited => "recipient",
            RateLimitDecision::DomainLimited => "domain",
        }
    }
}
fn main(){
println!("label/Allowed\t{:?}",RateLimitDecision::Allowed.label().as_bytes());
println!("label/RecipientLimited\t{:?}",RateLimitDecision::RecipientLimited.label().as_bytes());
println!("label/DomainLimited\t{:?}",RateLimitDecision::DomainLimited.label().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(RateLimitDecision::Allowed.label().as_bytes(),artifactkeeper_kernel::finite_catalog::rate_limit_decision_2593facc::RateLimitDecision::Allowed.label(),"rate_limit_decision_2593facc/label/Allowed");
assert_eq!(RateLimitDecision::RecipientLimited.label().as_bytes(),artifactkeeper_kernel::finite_catalog::rate_limit_decision_2593facc::RateLimitDecision::RecipientLimited.label(),"rate_limit_decision_2593facc/label/RecipientLimited");
assert_eq!(RateLimitDecision::DomainLimited.label().as_bytes(),artifactkeeper_kernel::finite_catalog::rate_limit_decision_2593facc::RateLimitDecision::DomainLimited.label(),"rate_limit_decision_2593facc/label/DomainLimited");
}
