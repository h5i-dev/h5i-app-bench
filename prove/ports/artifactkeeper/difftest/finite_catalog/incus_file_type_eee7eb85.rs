#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum IncusFileType {UnifiedTarball,MetadataTarball,RootfsSquashfs,RootfsQcow2,StreamsIndex}
impl IncusFileType {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::UnifiedTarball => "unified_tarball",
            Self::MetadataTarball => "metadata_tarball",
            Self::RootfsSquashfs => "rootfs_squashfs",
            Self::RootfsQcow2 => "rootfs_qcow2",
            Self::StreamsIndex => "streams_index",
        }
    }
    pub fn is_tarball(&self) -> bool {
        matches!(self, Self::UnifiedTarball | Self::MetadataTarball)
    }
}
fn main(){
println!("as_str/UnifiedTarball\t{:?}",IncusFileType::UnifiedTarball.as_str().as_bytes());
println!("as_str/MetadataTarball\t{:?}",IncusFileType::MetadataTarball.as_str().as_bytes());
println!("as_str/RootfsSquashfs\t{:?}",IncusFileType::RootfsSquashfs.as_str().as_bytes());
println!("as_str/RootfsQcow2\t{:?}",IncusFileType::RootfsQcow2.as_str().as_bytes());
println!("as_str/StreamsIndex\t{:?}",IncusFileType::StreamsIndex.as_str().as_bytes());
println!("is_tarball/UnifiedTarball\t{:?}",IncusFileType::UnifiedTarball.is_tarball());
println!("is_tarball/MetadataTarball\t{:?}",IncusFileType::MetadataTarball.is_tarball());
println!("is_tarball/RootfsSquashfs\t{:?}",IncusFileType::RootfsSquashfs.is_tarball());
println!("is_tarball/RootfsQcow2\t{:?}",IncusFileType::RootfsQcow2.is_tarball());
println!("is_tarball/StreamsIndex\t{:?}",IncusFileType::StreamsIndex.is_tarball());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(IncusFileType::UnifiedTarball.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::incus_file_type_eee7eb85::IncusFileType::UnifiedTarball.as_str(),"incus_file_type_eee7eb85/as_str/UnifiedTarball");
assert_eq!(IncusFileType::MetadataTarball.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::incus_file_type_eee7eb85::IncusFileType::MetadataTarball.as_str(),"incus_file_type_eee7eb85/as_str/MetadataTarball");
assert_eq!(IncusFileType::RootfsSquashfs.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::incus_file_type_eee7eb85::IncusFileType::RootfsSquashfs.as_str(),"incus_file_type_eee7eb85/as_str/RootfsSquashfs");
assert_eq!(IncusFileType::RootfsQcow2.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::incus_file_type_eee7eb85::IncusFileType::RootfsQcow2.as_str(),"incus_file_type_eee7eb85/as_str/RootfsQcow2");
assert_eq!(IncusFileType::StreamsIndex.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::incus_file_type_eee7eb85::IncusFileType::StreamsIndex.as_str(),"incus_file_type_eee7eb85/as_str/StreamsIndex");
assert_eq!(IncusFileType::UnifiedTarball.is_tarball(),artifactkeeper_kernel::finite_catalog::incus_file_type_eee7eb85::IncusFileType::UnifiedTarball.is_tarball(),"incus_file_type_eee7eb85/is_tarball/UnifiedTarball");
assert_eq!(IncusFileType::MetadataTarball.is_tarball(),artifactkeeper_kernel::finite_catalog::incus_file_type_eee7eb85::IncusFileType::MetadataTarball.is_tarball(),"incus_file_type_eee7eb85/is_tarball/MetadataTarball");
assert_eq!(IncusFileType::RootfsSquashfs.is_tarball(),artifactkeeper_kernel::finite_catalog::incus_file_type_eee7eb85::IncusFileType::RootfsSquashfs.is_tarball(),"incus_file_type_eee7eb85/is_tarball/RootfsSquashfs");
assert_eq!(IncusFileType::RootfsQcow2.is_tarball(),artifactkeeper_kernel::finite_catalog::incus_file_type_eee7eb85::IncusFileType::RootfsQcow2.is_tarball(),"incus_file_type_eee7eb85/is_tarball/RootfsQcow2");
assert_eq!(IncusFileType::StreamsIndex.is_tarball(),artifactkeeper_kernel::finite_catalog::incus_file_type_eee7eb85::IncusFileType::StreamsIndex.is_tarball(),"incus_file_type_eee7eb85/is_tarball/StreamsIndex");
}
