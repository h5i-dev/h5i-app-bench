#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ThumbnailFormat {Webp,Jpeg}
impl ThumbnailFormat {
    /// Stable name, byte-identical to the derived `Debug` output (see
    /// [`ThumbnailSize::as_str`] — same ETag-stability contract).
    pub fn as_str(self) -> &'static str {
        match self {
            ThumbnailFormat::Webp => "Webp",
            ThumbnailFormat::Jpeg => "Jpeg",
        }
    }
    /// On-disk file extension for this format (no dot).
    pub fn ext(self) -> &'static str {
        match self {
            ThumbnailFormat::Webp => "webp",
            ThumbnailFormat::Jpeg => "jpg",
        }
    }
    /// Media type, for `content_derived_blobs.content_type` and for any
    /// response serving these bytes.
    ///
    /// Beside `ext` deliberately: the two must agree, and an extension
    /// without a matching media type is how a WebP ends up labelled JPEG.
    pub fn mime(self) -> &'static str {
        match self {
            ThumbnailFormat::Webp => "image/webp",
            ThumbnailFormat::Jpeg => "image/jpeg",
        }
    }
}
fn main(){
println!("as_str/Webp\t{:?}",ThumbnailFormat::Webp.as_str().as_bytes());
println!("as_str/Jpeg\t{:?}",ThumbnailFormat::Jpeg.as_str().as_bytes());
println!("ext/Webp\t{:?}",ThumbnailFormat::Webp.ext().as_bytes());
println!("ext/Jpeg\t{:?}",ThumbnailFormat::Jpeg.ext().as_bytes());
println!("mime/Webp\t{:?}",ThumbnailFormat::Webp.mime().as_bytes());
println!("mime/Jpeg\t{:?}",ThumbnailFormat::Jpeg.mime().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(ThumbnailFormat::Webp.as_str().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_format_e90c1659::ThumbnailFormat::Webp.as_str(),"thumbnail_format_e90c1659/as_str/Webp");
assert_eq!(ThumbnailFormat::Jpeg.as_str().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_format_e90c1659::ThumbnailFormat::Jpeg.as_str(),"thumbnail_format_e90c1659/as_str/Jpeg");
assert_eq!(ThumbnailFormat::Webp.ext().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_format_e90c1659::ThumbnailFormat::Webp.ext(),"thumbnail_format_e90c1659/ext/Webp");
assert_eq!(ThumbnailFormat::Jpeg.ext().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_format_e90c1659::ThumbnailFormat::Jpeg.ext(),"thumbnail_format_e90c1659/ext/Jpeg");
assert_eq!(ThumbnailFormat::Webp.mime().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_format_e90c1659::ThumbnailFormat::Webp.mime(),"thumbnail_format_e90c1659/mime/Webp");
assert_eq!(ThumbnailFormat::Jpeg.mime().as_bytes(),oxicloud_kernel::finite_catalog::thumbnail_format_e90c1659::ThumbnailFormat::Jpeg.mime(),"thumbnail_format_e90c1659/mime/Jpeg");
}
