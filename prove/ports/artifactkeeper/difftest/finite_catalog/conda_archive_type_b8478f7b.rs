#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum CondaArchiveType {CondaV2,TarBz2}
impl CondaArchiveType {
    pub fn as_str(&self) -> &'static str {
        match self {
            CondaArchiveType::CondaV2 => "conda",
            CondaArchiveType::TarBz2 => "tar.bz2",
        }
    }
}
fn main(){
println!("as_str/CondaV2\t{:?}",CondaArchiveType::CondaV2.as_str().as_bytes());
println!("as_str/TarBz2\t{:?}",CondaArchiveType::TarBz2.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(CondaArchiveType::CondaV2.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::conda_archive_type_b8478f7b::CondaArchiveType::CondaV2.as_str(),"conda_archive_type_b8478f7b/as_str/CondaV2");
assert_eq!(CondaArchiveType::TarBz2.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::conda_archive_type_b8478f7b::CondaArchiveType::TarBz2.as_str(),"conda_archive_type_b8478f7b/as_str/TarBz2");
}
