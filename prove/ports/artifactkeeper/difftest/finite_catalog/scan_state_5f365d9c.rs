#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ScanState {Completed,InProgress,Failed,NeverScanned,NotApplicable}
impl ScanState {
    /// True when the artifact is "genuinely unscanned" for gating purposes:
    /// no completed scan exists and the reason is not "scanning does not apply".
    /// [`ScanState::NotApplicable`] and [`ScanState::Completed`] both return
    /// false (they must never be blocked by the `block_unscanned` gate).
    pub(crate) fn is_unscanned(self) -> bool {
        matches!(
            self,
            ScanState::InProgress | ScanState::Failed | ScanState::NeverScanned
        )
    }
    /// A short, stable token describing the unscanned reason, for the violation
    /// detail payload and the allowed-unscanned WARN log.
    pub(crate) fn reason_token(self) -> &'static str {
        match self {
            ScanState::Completed => "completed",
            ScanState::InProgress => "scan_in_progress",
            ScanState::Failed => "scan_failed",
            ScanState::NeverScanned => "never_scanned",
            ScanState::NotApplicable => "not_applicable",
        }
    }
}
fn main(){
println!("is_unscanned/Completed\t{:?}",ScanState::Completed.is_unscanned());
println!("is_unscanned/InProgress\t{:?}",ScanState::InProgress.is_unscanned());
println!("is_unscanned/Failed\t{:?}",ScanState::Failed.is_unscanned());
println!("is_unscanned/NeverScanned\t{:?}",ScanState::NeverScanned.is_unscanned());
println!("is_unscanned/NotApplicable\t{:?}",ScanState::NotApplicable.is_unscanned());
println!("reason_token/Completed\t{:?}",ScanState::Completed.reason_token().as_bytes());
println!("reason_token/InProgress\t{:?}",ScanState::InProgress.reason_token().as_bytes());
println!("reason_token/Failed\t{:?}",ScanState::Failed.reason_token().as_bytes());
println!("reason_token/NeverScanned\t{:?}",ScanState::NeverScanned.reason_token().as_bytes());
println!("reason_token/NotApplicable\t{:?}",ScanState::NotApplicable.reason_token().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(ScanState::Completed.is_unscanned(),artifactkeeper_kernel::finite_catalog::scan_state_5f365d9c::ScanState::Completed.is_unscanned(),"scan_state_5f365d9c/is_unscanned/Completed");
assert_eq!(ScanState::InProgress.is_unscanned(),artifactkeeper_kernel::finite_catalog::scan_state_5f365d9c::ScanState::InProgress.is_unscanned(),"scan_state_5f365d9c/is_unscanned/InProgress");
assert_eq!(ScanState::Failed.is_unscanned(),artifactkeeper_kernel::finite_catalog::scan_state_5f365d9c::ScanState::Failed.is_unscanned(),"scan_state_5f365d9c/is_unscanned/Failed");
assert_eq!(ScanState::NeverScanned.is_unscanned(),artifactkeeper_kernel::finite_catalog::scan_state_5f365d9c::ScanState::NeverScanned.is_unscanned(),"scan_state_5f365d9c/is_unscanned/NeverScanned");
assert_eq!(ScanState::NotApplicable.is_unscanned(),artifactkeeper_kernel::finite_catalog::scan_state_5f365d9c::ScanState::NotApplicable.is_unscanned(),"scan_state_5f365d9c/is_unscanned/NotApplicable");
assert_eq!(ScanState::Completed.reason_token().as_bytes(),artifactkeeper_kernel::finite_catalog::scan_state_5f365d9c::ScanState::Completed.reason_token(),"scan_state_5f365d9c/reason_token/Completed");
assert_eq!(ScanState::InProgress.reason_token().as_bytes(),artifactkeeper_kernel::finite_catalog::scan_state_5f365d9c::ScanState::InProgress.reason_token(),"scan_state_5f365d9c/reason_token/InProgress");
assert_eq!(ScanState::Failed.reason_token().as_bytes(),artifactkeeper_kernel::finite_catalog::scan_state_5f365d9c::ScanState::Failed.reason_token(),"scan_state_5f365d9c/reason_token/Failed");
assert_eq!(ScanState::NeverScanned.reason_token().as_bytes(),artifactkeeper_kernel::finite_catalog::scan_state_5f365d9c::ScanState::NeverScanned.reason_token(),"scan_state_5f365d9c/reason_token/NeverScanned");
assert_eq!(ScanState::NotApplicable.reason_token().as_bytes(),artifactkeeper_kernel::finite_catalog::scan_state_5f365d9c::ScanState::NotApplicable.reason_token(),"scan_state_5f365d9c/reason_token/NotApplicable");
}
