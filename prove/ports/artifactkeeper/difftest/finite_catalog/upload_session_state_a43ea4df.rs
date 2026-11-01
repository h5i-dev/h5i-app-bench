#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum UploadSessionState {Open,Committing}
impl UploadSessionState {
    fn as_str(self) -> &'static str {
        match self {
            UploadSessionState::Open => "open",
            UploadSessionState::Committing => "committing",
        }
    }
}
fn main(){
println!("as_str/Open\t{:?}",UploadSessionState::Open.as_str().as_bytes());
println!("as_str/Committing\t{:?}",UploadSessionState::Committing.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(UploadSessionState::Open.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::upload_session_state_a43ea4df::UploadSessionState::Open.as_str(),"upload_session_state_a43ea4df/as_str/Open");
assert_eq!(UploadSessionState::Committing.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::upload_session_state_a43ea4df::UploadSessionState::Committing.as_str(),"upload_session_state_a43ea4df/as_str/Committing");
}
