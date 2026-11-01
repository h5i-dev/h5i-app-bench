#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ResourceType {User,Repository,Artifact,Role,ApiToken,PeerInstance,Backup,Setting,Plugin,ScanResult}
impl ResourceType {
    pub fn as_str(&self) -> &'static str {
        match self {
            ResourceType::User => "user",
            ResourceType::Repository => "repository",
            ResourceType::Artifact => "artifact",
            ResourceType::Role => "role",
            ResourceType::ApiToken => "api_token",
            ResourceType::PeerInstance => "peer_instance",
            ResourceType::Backup => "backup",
            ResourceType::Setting => "setting",
            ResourceType::Plugin => "plugin",
            ResourceType::ScanResult => "scan_result",
        }
    }
}
fn main(){
println!("as_str/User\t{:?}",ResourceType::User.as_str().as_bytes());
println!("as_str/Repository\t{:?}",ResourceType::Repository.as_str().as_bytes());
println!("as_str/Artifact\t{:?}",ResourceType::Artifact.as_str().as_bytes());
println!("as_str/Role\t{:?}",ResourceType::Role.as_str().as_bytes());
println!("as_str/ApiToken\t{:?}",ResourceType::ApiToken.as_str().as_bytes());
println!("as_str/PeerInstance\t{:?}",ResourceType::PeerInstance.as_str().as_bytes());
println!("as_str/Backup\t{:?}",ResourceType::Backup.as_str().as_bytes());
println!("as_str/Setting\t{:?}",ResourceType::Setting.as_str().as_bytes());
println!("as_str/Plugin\t{:?}",ResourceType::Plugin.as_str().as_bytes());
println!("as_str/ScanResult\t{:?}",ResourceType::ScanResult.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(ResourceType::User.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::resource_type_3ef0ea8f::ResourceType::User.as_str(),"resource_type_3ef0ea8f/as_str/User");
assert_eq!(ResourceType::Repository.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::resource_type_3ef0ea8f::ResourceType::Repository.as_str(),"resource_type_3ef0ea8f/as_str/Repository");
assert_eq!(ResourceType::Artifact.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::resource_type_3ef0ea8f::ResourceType::Artifact.as_str(),"resource_type_3ef0ea8f/as_str/Artifact");
assert_eq!(ResourceType::Role.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::resource_type_3ef0ea8f::ResourceType::Role.as_str(),"resource_type_3ef0ea8f/as_str/Role");
assert_eq!(ResourceType::ApiToken.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::resource_type_3ef0ea8f::ResourceType::ApiToken.as_str(),"resource_type_3ef0ea8f/as_str/ApiToken");
assert_eq!(ResourceType::PeerInstance.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::resource_type_3ef0ea8f::ResourceType::PeerInstance.as_str(),"resource_type_3ef0ea8f/as_str/PeerInstance");
assert_eq!(ResourceType::Backup.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::resource_type_3ef0ea8f::ResourceType::Backup.as_str(),"resource_type_3ef0ea8f/as_str/Backup");
assert_eq!(ResourceType::Setting.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::resource_type_3ef0ea8f::ResourceType::Setting.as_str(),"resource_type_3ef0ea8f/as_str/Setting");
assert_eq!(ResourceType::Plugin.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::resource_type_3ef0ea8f::ResourceType::Plugin.as_str(),"resource_type_3ef0ea8f/as_str/Plugin");
assert_eq!(ResourceType::ScanResult.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::resource_type_3ef0ea8f::ResourceType::ScanResult.as_str(),"resource_type_3ef0ea8f/as_str/ScanResult");
}
