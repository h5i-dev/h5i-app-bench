#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Severity {Critical = 0,High = 1,Medium = 2,Low = 3,Info = 4}
impl Severity {
    /// Penalty weight used in security score calculation.
    pub fn penalty_weight(self) -> i32 {
        match self {
            Severity::Critical => 25,
            Severity::High => 10,
            Severity::Medium => 3,
            Severity::Low => 1,
            Severity::Info => 0,
        }
    }
    /// Canonical lowercase form, matching the `scan_configs_severity_threshold_check`
    /// database CHECK constraint (`critical|high|medium|low|info`). Use this when
    /// persisting a severity so a normalized value (e.g. "High" -> "high",
    /// "moderate" -> "medium") is what reaches Postgres.
    pub fn as_str(self) -> &'static str {
        match self {
            Severity::Critical => "critical",
            Severity::High => "high",
            Severity::Medium => "medium",
            Severity::Low => "low",
            Severity::Info => "info",
        }
    }
}
fn main(){
println!("penalty_weight/Critical\t{:?}",Severity::Critical.penalty_weight());
println!("penalty_weight/High\t{:?}",Severity::High.penalty_weight());
println!("penalty_weight/Medium\t{:?}",Severity::Medium.penalty_weight());
println!("penalty_weight/Low\t{:?}",Severity::Low.penalty_weight());
println!("penalty_weight/Info\t{:?}",Severity::Info.penalty_weight());
println!("as_str/Critical\t{:?}",Severity::Critical.as_str().as_bytes());
println!("as_str/High\t{:?}",Severity::High.as_str().as_bytes());
println!("as_str/Medium\t{:?}",Severity::Medium.as_str().as_bytes());
println!("as_str/Low\t{:?}",Severity::Low.as_str().as_bytes());
println!("as_str/Info\t{:?}",Severity::Info.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(Severity::Critical.penalty_weight(),artifactkeeper_kernel::finite_catalog::severity_1259a9af::Severity::Critical.penalty_weight(),"severity_1259a9af/penalty_weight/Critical");
assert_eq!(Severity::High.penalty_weight(),artifactkeeper_kernel::finite_catalog::severity_1259a9af::Severity::High.penalty_weight(),"severity_1259a9af/penalty_weight/High");
assert_eq!(Severity::Medium.penalty_weight(),artifactkeeper_kernel::finite_catalog::severity_1259a9af::Severity::Medium.penalty_weight(),"severity_1259a9af/penalty_weight/Medium");
assert_eq!(Severity::Low.penalty_weight(),artifactkeeper_kernel::finite_catalog::severity_1259a9af::Severity::Low.penalty_weight(),"severity_1259a9af/penalty_weight/Low");
assert_eq!(Severity::Info.penalty_weight(),artifactkeeper_kernel::finite_catalog::severity_1259a9af::Severity::Info.penalty_weight(),"severity_1259a9af/penalty_weight/Info");
assert_eq!(Severity::Critical.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::severity_1259a9af::Severity::Critical.as_str(),"severity_1259a9af/as_str/Critical");
assert_eq!(Severity::High.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::severity_1259a9af::Severity::High.as_str(),"severity_1259a9af/as_str/High");
assert_eq!(Severity::Medium.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::severity_1259a9af::Severity::Medium.as_str(),"severity_1259a9af/as_str/Medium");
assert_eq!(Severity::Low.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::severity_1259a9af::Severity::Low.as_str(),"severity_1259a9af/as_str/Low");
assert_eq!(Severity::Info.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::severity_1259a9af::Severity::Info.as_str(),"severity_1259a9af/as_str/Info");
}
