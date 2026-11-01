#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ThumbnailSize {Icon,Preview,Large}
impl ThumbnailSize {
    /// Stable name, byte-identical to the derived `Debug` output. Used by
    /// the thumbnail/preview ETags on the hottest revalidation path — a
    /// `&'static str` push beats routing through the `Debug` machinery
    /// (benches/ROUND11.md §7) while keeping every already-cached client
    /// ETag valid.
    pub fn as_str(self) -> &'static str {
        match self {
            ThumbnailSize::Icon => "Icon",
            ThumbnailSize::Preview => "Preview",
            ThumbnailSize::Large => "Large",
        }
    }
    /// Get the maximum dimension for this size.
    pub fn max_dimension(&self) -> u32 {
        match self {
            ThumbnailSize::Icon => 150,
            ThumbnailSize::Preview => 400,
            ThumbnailSize::Large => 800,
        }
    }
    /// Get the directory name for this size.
    pub fn dir_name(&self) -> &'static str {
        match self {
            ThumbnailSize::Icon => "icon",
            ThumbnailSize::Preview => "preview",
            ThumbnailSize::Large => "large",
        }
    }
}
fn main(){
println!("as_str/Icon\t{:?}",ThumbnailSize::Icon.as_str().as_bytes());
println!("as_str/Preview\t{:?}",ThumbnailSize::Preview.as_str().as_bytes());
println!("as_str/Large\t{:?}",ThumbnailSize::Large.as_str().as_bytes());
println!("max_dimension/Icon\t{:?}",ThumbnailSize::Icon.max_dimension());
println!("max_dimension/Preview\t{:?}",ThumbnailSize::Preview.max_dimension());
println!("max_dimension/Large\t{:?}",ThumbnailSize::Large.max_dimension());
println!("dir_name/Icon\t{:?}",ThumbnailSize::Icon.dir_name().as_bytes());
println!("dir_name/Preview\t{:?}",ThumbnailSize::Preview.dir_name().as_bytes());
println!("dir_name/Large\t{:?}",ThumbnailSize::Large.dir_name().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(ThumbnailSize::Icon.as_str().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_size_e90c1659::ThumbnailSize::Icon.as_str(),"thumbnail_size_e90c1659/as_str/Icon");
assert_eq!(ThumbnailSize::Preview.as_str().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_size_e90c1659::ThumbnailSize::Preview.as_str(),"thumbnail_size_e90c1659/as_str/Preview");
assert_eq!(ThumbnailSize::Large.as_str().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_size_e90c1659::ThumbnailSize::Large.as_str(),"thumbnail_size_e90c1659/as_str/Large");
assert_eq!(ThumbnailSize::Icon.max_dimension(),oxicloud_kernel::finite_catalog::thumbnail_size_e90c1659::ThumbnailSize::Icon.max_dimension(),"thumbnail_size_e90c1659/max_dimension/Icon");
assert_eq!(ThumbnailSize::Preview.max_dimension(),oxicloud_kernel::finite_catalog::thumbnail_size_e90c1659::ThumbnailSize::Preview.max_dimension(),"thumbnail_size_e90c1659/max_dimension/Preview");
assert_eq!(ThumbnailSize::Large.max_dimension(),oxicloud_kernel::finite_catalog::thumbnail_size_e90c1659::ThumbnailSize::Large.max_dimension(),"thumbnail_size_e90c1659/max_dimension/Large");
assert_eq!(ThumbnailSize::Icon.dir_name().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_size_e90c1659::ThumbnailSize::Icon.dir_name(),"thumbnail_size_e90c1659/dir_name/Icon");
assert_eq!(ThumbnailSize::Preview.dir_name().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_size_e90c1659::ThumbnailSize::Preview.dir_name(),"thumbnail_size_e90c1659/dir_name/Preview");
assert_eq!(ThumbnailSize::Large.dir_name().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_size_e90c1659::ThumbnailSize::Large.dir_name(),"thumbnail_size_e90c1659/dir_name/Large");
}
