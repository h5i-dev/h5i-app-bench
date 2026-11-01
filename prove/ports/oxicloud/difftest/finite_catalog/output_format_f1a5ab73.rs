#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OutputFormat {WebP}
impl OutputFormat {
    /// Get the file extension for this format.
    pub fn extension(&self) -> &'static str {
        match self {
            OutputFormat::WebP => "webp",
        }
    }
    /// Get the MIME type for this format.
    pub fn mime_type(&self) -> &'static str {
        match self {
            OutputFormat::WebP => "image/webp",
        }
    }
}
fn main(){
println!("extension/WebP\t{:?}",OutputFormat::WebP.extension().as_bytes());
println!("mime_type/WebP\t{:?}",OutputFormat::WebP.mime_type().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(OutputFormat::WebP.extension().as_bytes(),oxicloud_kernel::finite_catalog::output_format_f1a5ab73::OutputFormat::WebP.extension(),"output_format_f1a5ab73/extension/WebP");
assert_eq!(OutputFormat::WebP.mime_type().as_bytes(),oxicloud_kernel::finite_catalog::output_format_f1a5ab73::OutputFormat::WebP.mime_type(),"output_format_f1a5ab73/mime_type/WebP");
}
