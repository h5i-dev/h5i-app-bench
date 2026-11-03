#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum PolicyAction {Allow,Warn,Block}
impl PolicyAction {
    pub fn as_str(&self) -> &'static str {
        match self {
            PolicyAction::Allow => "allow",
            PolicyAction::Warn => "warn",
            PolicyAction::Block => "block",
        }
    }
}
fn main(){
println!("as_str/Allow\t{:?}",PolicyAction::Allow.as_str().as_bytes());
println!("as_str/Warn\t{:?}",PolicyAction::Warn.as_str().as_bytes());
println!("as_str/Block\t{:?}",PolicyAction::Block.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(PolicyAction::Allow.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::policy_action_104be95e::PolicyAction::Allow.as_str(),"policy_action_104be95e/as_str/Allow");
assert_eq!(PolicyAction::Warn.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::policy_action_104be95e::PolicyAction::Warn.as_str(),"policy_action_104be95e/as_str/Warn");
assert_eq!(PolicyAction::Block.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::policy_action_104be95e::PolicyAction::Block.as_str(),"policy_action_104be95e/as_str/Block");
}
