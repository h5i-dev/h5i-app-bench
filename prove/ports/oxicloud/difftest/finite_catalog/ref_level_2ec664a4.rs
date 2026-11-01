#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum RefLevel {Chunk,Manifest}
impl RefLevel {
    /// Stable name for logs and consistency-finding fields.
    pub fn as_str(self) -> &'static str {
        match self {
            RefLevel::Chunk => "chunk",
            RefLevel::Manifest => "manifest",
        }
    }
}
fn main(){
println!("as_str/Chunk\t{:?}",RefLevel::Chunk.as_str().as_bytes());
println!("as_str/Manifest\t{:?}",RefLevel::Manifest.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(RefLevel::Chunk.as_str().as_bytes(),oxicloud_kernel::finite_catalog::ref_level_2ec664a4::RefLevel::Chunk.as_str(),"ref_level_2ec664a4/as_str/Chunk");
assert_eq!(RefLevel::Manifest.as_str().as_bytes(),oxicloud_kernel::finite_catalog::ref_level_2ec664a4::RefLevel::Manifest.as_str(),"ref_level_2ec664a4/as_str/Manifest");
}
