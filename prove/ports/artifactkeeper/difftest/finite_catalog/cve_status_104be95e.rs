#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum CveStatus {Open,Fixed,Acknowledged,FalsePositive}
impl CveStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            CveStatus::Open => "open",
            CveStatus::Fixed => "fixed",
            CveStatus::Acknowledged => "acknowledged",
            CveStatus::FalsePositive => "false_positive",
        }
    }
}
fn main(){
println!("as_str/Open\t{:?}",CveStatus::Open.as_str().as_bytes());
println!("as_str/Fixed\t{:?}",CveStatus::Fixed.as_str().as_bytes());
println!("as_str/Acknowledged\t{:?}",CveStatus::Acknowledged.as_str().as_bytes());
println!("as_str/FalsePositive\t{:?}",CveStatus::FalsePositive.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(CveStatus::Open.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::cve_status_104be95e::CveStatus::Open.as_str(),"cve_status_104be95e/as_str/Open");
assert_eq!(CveStatus::Fixed.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::cve_status_104be95e::CveStatus::Fixed.as_str(),"cve_status_104be95e/as_str/Fixed");
assert_eq!(CveStatus::Acknowledged.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::cve_status_104be95e::CveStatus::Acknowledged.as_str(),"cve_status_104be95e/as_str/Acknowledged");
assert_eq!(CveStatus::FalsePositive.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::cve_status_104be95e::CveStatus::FalsePositive.as_str(),"cve_status_104be95e/as_str/FalsePositive");
}
