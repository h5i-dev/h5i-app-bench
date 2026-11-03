#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum StoragePathFormat {Native,Artifactory,Migration}
impl StoragePathFormat {
    /// Check if this format supports fallback paths
    pub fn has_fallback(&self) -> bool {
        matches!(self, Self::Migration)
    }
}
fn main(){
println!("has_fallback/Native\t{:?}",StoragePathFormat::Native.has_fallback());
println!("has_fallback/Artifactory\t{:?}",StoragePathFormat::Artifactory.has_fallback());
println!("has_fallback/Migration\t{:?}",StoragePathFormat::Migration.has_fallback());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(StoragePathFormat::Native.has_fallback(),artifactkeeper_kernel::finite_catalog::storage_path_format_9d04c6bd::StoragePathFormat::Native.has_fallback(),"storage_path_format_9d04c6bd/has_fallback/Native");
assert_eq!(StoragePathFormat::Artifactory.has_fallback(),artifactkeeper_kernel::finite_catalog::storage_path_format_9d04c6bd::StoragePathFormat::Artifactory.has_fallback(),"storage_path_format_9d04c6bd/has_fallback/Artifactory");
assert_eq!(StoragePathFormat::Migration.has_fallback(),artifactkeeper_kernel::finite_catalog::storage_path_format_9d04c6bd::StoragePathFormat::Migration.has_fallback(),"storage_path_format_9d04c6bd/has_fallback/Migration");
}
