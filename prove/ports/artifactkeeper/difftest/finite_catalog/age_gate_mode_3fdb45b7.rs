#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AgeGateMode {UpstreamPublishTime,FirstSeen}
impl AgeGateMode {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::UpstreamPublishTime => "upstream_publish_time",
            Self::FirstSeen => "first_seen",
        }
    }
}
fn main(){
println!("as_str/UpstreamPublishTime\t{:?}",AgeGateMode::UpstreamPublishTime.as_str().as_bytes());
println!("as_str/FirstSeen\t{:?}",AgeGateMode::FirstSeen.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(AgeGateMode::UpstreamPublishTime.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::age_gate_mode_3fdb45b7::AgeGateMode::UpstreamPublishTime.as_str(),"age_gate_mode_3fdb45b7/as_str/UpstreamPublishTime");
assert_eq!(AgeGateMode::FirstSeen.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::age_gate_mode_3fdb45b7::AgeGateMode::FirstSeen.as_str(),"age_gate_mode_3fdb45b7/as_str/FirstSeen");
}
