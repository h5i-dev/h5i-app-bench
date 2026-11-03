#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AdvisoryScanStatus {Ok,NotRun,Partial}
impl AdvisoryScanStatus {
    /// The stable wire form. An open union on the client: an unrecognised
    /// value narrows to "unknown", which asserts neither `ok` nor `partial`.
    pub fn as_str(self) -> &'static str {
        match self {
            AdvisoryScanStatus::Ok => "ok",
            AdvisoryScanStatus::NotRun => "not_run",
            AdvisoryScanStatus::Partial => "partial",
        }
    }
}
fn main(){
println!("as_str/Ok\t{:?}",AdvisoryScanStatus::Ok.as_str().as_bytes());
println!("as_str/NotRun\t{:?}",AdvisoryScanStatus::NotRun.as_str().as_bytes());
println!("as_str/Partial\t{:?}",AdvisoryScanStatus::Partial.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(AdvisoryScanStatus::Ok.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::advisory_scan_status_38f3e57f::AdvisoryScanStatus::Ok.as_str(),"advisory_scan_status_38f3e57f/as_str/Ok");
assert_eq!(AdvisoryScanStatus::NotRun.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::advisory_scan_status_38f3e57f::AdvisoryScanStatus::NotRun.as_str(),"advisory_scan_status_38f3e57f/as_str/NotRun");
assert_eq!(AdvisoryScanStatus::Partial.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::advisory_scan_status_38f3e57f::AdvisoryScanStatus::Partial.as_str(),"advisory_scan_status_38f3e57f/as_str/Partial");
}
