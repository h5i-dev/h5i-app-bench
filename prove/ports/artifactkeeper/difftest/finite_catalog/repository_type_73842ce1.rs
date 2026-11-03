#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum RepositoryType {Local,Remote,Virtual}
impl RepositoryType {
    /// Convert to Artifact Keeper repository type string
    pub fn to_artifact_keeper(&self) -> &'static str {
        match self {
            Self::Local => "local",
            Self::Remote => "remote",
            Self::Virtual => "virtual",
        }
    }
}
fn main(){
println!("to_artifact_keeper/Local\t{:?}",RepositoryType::Local.to_artifact_keeper().as_bytes());
println!("to_artifact_keeper/Remote\t{:?}",RepositoryType::Remote.to_artifact_keeper().as_bytes());
println!("to_artifact_keeper/Virtual\t{:?}",RepositoryType::Virtual.to_artifact_keeper().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(RepositoryType::Local.to_artifact_keeper().as_bytes(),artifactkeeper_kernel::finite_catalog::repository_type_73842ce1::RepositoryType::Local.to_artifact_keeper(),"repository_type_73842ce1/to_artifact_keeper/Local");
assert_eq!(RepositoryType::Remote.to_artifact_keeper().as_bytes(),artifactkeeper_kernel::finite_catalog::repository_type_73842ce1::RepositoryType::Remote.to_artifact_keeper(),"repository_type_73842ce1/to_artifact_keeper/Remote");
assert_eq!(RepositoryType::Virtual.to_artifact_keeper().as_bytes(),artifactkeeper_kernel::finite_catalog::repository_type_73842ce1::RepositoryType::Virtual.to_artifact_keeper(),"repository_type_73842ce1/to_artifact_keeper/Virtual");
}
