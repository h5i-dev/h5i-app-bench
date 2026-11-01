#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum NotifyTrigger {GrantCreated,ManualResend}
impl NotifyTrigger {
    fn audit_str(self) -> &'static str {
        match self {
            NotifyTrigger::GrantCreated => "grant_created",
            NotifyTrigger::ManualResend => "manual_resend",
        }
    }
}
fn main(){
println!("audit_str/GrantCreated\t{:?}",NotifyTrigger::GrantCreated.audit_str().as_bytes());
println!("audit_str/ManualResend\t{:?}",NotifyTrigger::ManualResend.audit_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(NotifyTrigger::GrantCreated.audit_str().as_bytes(),oxicloud_kernel::finite_catalog::notify_trigger_5dfe5802::NotifyTrigger::GrantCreated.audit_str(),"notify_trigger_5dfe5802/audit_str/GrantCreated");
assert_eq!(NotifyTrigger::ManualResend.audit_str().as_bytes(),oxicloud_kernel::finite_catalog::notify_trigger_5dfe5802::NotifyTrigger::ManualResend.audit_str(),"notify_trigger_5dfe5802/audit_str/ManualResend");
}
