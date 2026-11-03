#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum RepodataEncoding {Json,Bz2,Zst}
impl RepodataEncoding {
    fn content_type(&self) -> &'static str {
        match self {
            Self::Json => "application/json",
            Self::Bz2 => "application/x-bzip2",
            Self::Zst => "application/zstd",
        }
    }
    fn upstream_filename(&self) -> &'static str {
        match self {
            Self::Json => "repodata.json",
            Self::Bz2 => "repodata.json.bz2",
            Self::Zst => "repodata.json.zst",
        }
    }
}
fn main(){
println!("content_type/Json\t{:?}",RepodataEncoding::Json.content_type().as_bytes());
println!("content_type/Bz2\t{:?}",RepodataEncoding::Bz2.content_type().as_bytes());
println!("content_type/Zst\t{:?}",RepodataEncoding::Zst.content_type().as_bytes());
println!("upstream_filename/Json\t{:?}",RepodataEncoding::Json.upstream_filename().as_bytes());
println!("upstream_filename/Bz2\t{:?}",RepodataEncoding::Bz2.upstream_filename().as_bytes());
println!("upstream_filename/Zst\t{:?}",RepodataEncoding::Zst.upstream_filename().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(RepodataEncoding::Json.content_type().as_bytes(),artifactkeeper_kernel::finite_catalog::repodata_encoding_df7b79f6::RepodataEncoding::Json.content_type(),"repodata_encoding_df7b79f6/content_type/Json");
assert_eq!(RepodataEncoding::Bz2.content_type().as_bytes(),artifactkeeper_kernel::finite_catalog::repodata_encoding_df7b79f6::RepodataEncoding::Bz2.content_type(),"repodata_encoding_df7b79f6/content_type/Bz2");
assert_eq!(RepodataEncoding::Zst.content_type().as_bytes(),artifactkeeper_kernel::finite_catalog::repodata_encoding_df7b79f6::RepodataEncoding::Zst.content_type(),"repodata_encoding_df7b79f6/content_type/Zst");
assert_eq!(RepodataEncoding::Json.upstream_filename().as_bytes(),artifactkeeper_kernel::finite_catalog::repodata_encoding_df7b79f6::RepodataEncoding::Json.upstream_filename(),"repodata_encoding_df7b79f6/upstream_filename/Json");
assert_eq!(RepodataEncoding::Bz2.upstream_filename().as_bytes(),artifactkeeper_kernel::finite_catalog::repodata_encoding_df7b79f6::RepodataEncoding::Bz2.upstream_filename(),"repodata_encoding_df7b79f6/upstream_filename/Bz2");
assert_eq!(RepodataEncoding::Zst.upstream_filename().as_bytes(),artifactkeeper_kernel::finite_catalog::repodata_encoding_df7b79f6::RepodataEncoding::Zst.upstream_filename(),"repodata_encoding_df7b79f6/upstream_filename/Zst");
}
