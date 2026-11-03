#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ProxyScanAction {FailOpen,FailClosed}
impl ProxyScanAction {
    pub fn is_fail_closed(self) -> bool {
        matches!(self, ProxyScanAction::FailClosed)
    }
}
fn main(){
println!("is_fail_closed/FailOpen\t{:?}",ProxyScanAction::FailOpen.is_fail_closed());
println!("is_fail_closed/FailClosed\t{:?}",ProxyScanAction::FailClosed.is_fail_closed());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(ProxyScanAction::FailOpen.is_fail_closed(),artifactkeeper_kernel::finite_catalog::proxy_scan_action_2c5d20ab::ProxyScanAction::FailOpen.is_fail_closed(),"proxy_scan_action_2c5d20ab/is_fail_closed/FailOpen");
assert_eq!(ProxyScanAction::FailClosed.is_fail_closed(),artifactkeeper_kernel::finite_catalog::proxy_scan_action_2c5d20ab::ProxyScanAction::FailClosed.is_fail_closed(),"proxy_scan_action_2c5d20ab/is_fail_closed/FailClosed");
}
