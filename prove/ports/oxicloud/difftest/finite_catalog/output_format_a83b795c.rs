#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OutputFormat {WebP}
impl OutputFormat {
    pub fn extension(&self) -> &'static str {
        match self {
            OutputFormat::WebP => "webp",
        }
    }
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
assert_eq!(OutputFormat::WebP.extension().as_bytes(),oxicloud_kernel::finite_catalog::output_format_a83b795c::OutputFormat::WebP.extension(),"output_format_a83b795c/extension/WebP");
assert_eq!(OutputFormat::WebP.mime_type().as_bytes(),oxicloud_kernel::finite_catalog::output_format_a83b795c::OutputFormat::WebP.mime_type(),"output_format_a83b795c/mime_type/WebP");
}
