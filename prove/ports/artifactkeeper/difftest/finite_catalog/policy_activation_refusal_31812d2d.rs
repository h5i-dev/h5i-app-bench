#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum PolicyActivationRefusal {PinnedByEnvironment,ActorNotEnrolled}
impl PolicyActivationRefusal {
    /// Operator-facing explanation, including the way out.
    pub fn message(self) -> &'static str {
        match self {
            PolicyActivationRefusal::PinnedByEnvironment => {
                "The TOTP enforcement policy is pinned by the TOTP_POLICY environment variable \
                 and cannot be changed through the API. Unset TOTP_POLICY and restart to manage \
                 it here."
            }
            PolicyActivationRefusal::ActorNotEnrolled => {
                "Enable TOTP on your own account before requiring it for others. This guarantees \
                 at least one administrator can still sign in if the enrollment flow does not \
                 work in your environment."
            }
        }
    }
}
fn main(){
println!("message/PinnedByEnvironment\t{:?}",PolicyActivationRefusal::PinnedByEnvironment.message().as_bytes());
println!("message/ActorNotEnrolled\t{:?}",PolicyActivationRefusal::ActorNotEnrolled.message().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(PolicyActivationRefusal::PinnedByEnvironment.message().as_bytes(),artifactkeeper_kernel::finite_catalog::policy_activation_refusal_31812d2d::PolicyActivationRefusal::PinnedByEnvironment.message(),"policy_activation_refusal_31812d2d/message/PinnedByEnvironment");
assert_eq!(PolicyActivationRefusal::ActorNotEnrolled.message().as_bytes(),artifactkeeper_kernel::finite_catalog::policy_activation_refusal_31812d2d::PolicyActivationRefusal::ActorNotEnrolled.message(),"policy_activation_refusal_31812d2d/message/ActorNotEnrolled");
}
