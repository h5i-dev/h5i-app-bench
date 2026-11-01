#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum CandidateConfidence {Low,Medium,High}
impl CandidateConfidence {
    /// The stable wire form used by the API response.
    pub fn as_str(self) -> &'static str {
        match self {
            CandidateConfidence::Low => "low",
            CandidateConfidence::Medium => "medium",
            CandidateConfidence::High => "high",
        }
    }
}
fn main(){
println!("as_str/Low\t{:?}",CandidateConfidence::Low.as_str().as_bytes());
println!("as_str/Medium\t{:?}",CandidateConfidence::Medium.as_str().as_bytes());
println!("as_str/High\t{:?}",CandidateConfidence::High.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(CandidateConfidence::Low.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::candidate_confidence_8223875f::CandidateConfidence::Low.as_str(),"candidate_confidence_8223875f/as_str/Low");
assert_eq!(CandidateConfidence::Medium.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::candidate_confidence_8223875f::CandidateConfidence::Medium.as_str(),"candidate_confidence_8223875f/as_str/Medium");
assert_eq!(CandidateConfidence::High.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::candidate_confidence_8223875f::CandidateConfidence::High.as_str(),"candidate_confidence_8223875f/as_str/High");
}
