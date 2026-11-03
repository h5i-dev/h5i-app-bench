#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ThumbnailSize {Icon,Preview,Large}
impl ThumbnailSize {
    /// Get the maximum dimension for this size
    pub fn max_dimension(&self) -> u32 {
        match self {
            ThumbnailSize::Icon => 150,
            ThumbnailSize::Preview => 400,
            ThumbnailSize::Large => 800,
        }
    }
    /// Get the directory name for this size
    pub fn dir_name(&self) -> &'static str {
        match self {
            ThumbnailSize::Icon => "icon",
            ThumbnailSize::Preview => "preview",
            ThumbnailSize::Large => "large",
        }
    }
}
fn main(){
println!("max_dimension/Icon\t{:?}",ThumbnailSize::Icon.max_dimension());
println!("max_dimension/Preview\t{:?}",ThumbnailSize::Preview.max_dimension());
println!("max_dimension/Large\t{:?}",ThumbnailSize::Large.max_dimension());
println!("dir_name/Icon\t{:?}",ThumbnailSize::Icon.dir_name().as_bytes());
println!("dir_name/Preview\t{:?}",ThumbnailSize::Preview.dir_name().as_bytes());
println!("dir_name/Large\t{:?}",ThumbnailSize::Large.dir_name().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(ThumbnailSize::Icon.max_dimension(),oxicloud_kernel::finite_catalog::thumbnail_size_4088a69a::ThumbnailSize::Icon.max_dimension(),"thumbnail_size_4088a69a/max_dimension/Icon");
assert_eq!(ThumbnailSize::Preview.max_dimension(),oxicloud_kernel::finite_catalog::thumbnail_size_4088a69a::ThumbnailSize::Preview.max_dimension(),"thumbnail_size_4088a69a/max_dimension/Preview");
assert_eq!(ThumbnailSize::Large.max_dimension(),oxicloud_kernel::finite_catalog::thumbnail_size_4088a69a::ThumbnailSize::Large.max_dimension(),"thumbnail_size_4088a69a/max_dimension/Large");
assert_eq!(ThumbnailSize::Icon.dir_name().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_size_4088a69a::ThumbnailSize::Icon.dir_name(),"thumbnail_size_4088a69a/dir_name/Icon");
assert_eq!(ThumbnailSize::Preview.dir_name().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_size_4088a69a::ThumbnailSize::Preview.dir_name(),"thumbnail_size_4088a69a/dir_name/Preview");
assert_eq!(ThumbnailSize::Large.dir_name().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_size_4088a69a::ThumbnailSize::Large.dir_name(),"thumbnail_size_4088a69a/dir_name/Large");
}
