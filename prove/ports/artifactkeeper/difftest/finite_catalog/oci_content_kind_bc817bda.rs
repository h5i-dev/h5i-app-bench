#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OciContentKind {Blob,Manifest}
impl OciContentKind {
    /// The registry-API path segment (`blobs` or `manifests`) for this kind.
    pub fn path_segment(self) -> &'static str {
        match self {
            OciContentKind::Blob => "blobs",
            OciContentKind::Manifest => "manifests",
        }
    }
}
fn main(){
println!("path_segment/Blob\t{:?}",OciContentKind::Blob.path_segment().as_bytes());
println!("path_segment/Manifest\t{:?}",OciContentKind::Manifest.path_segment().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(OciContentKind::Blob.path_segment().as_bytes(),artifactkeeper_kernel::finite_catalog::oci_content_kind_bc817bda::OciContentKind::Blob.path_segment(),"oci_content_kind_bc817bda/path_segment/Blob");
assert_eq!(OciContentKind::Manifest.path_segment().as_bytes(),artifactkeeper_kernel::finite_catalog::oci_content_kind_bc817bda::OciContentKind::Manifest.path_segment(),"oci_content_kind_bc817bda/path_segment/Manifest");
}
