#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum SignedReleaseVariant {InRelease,ReleaseGpg}
impl SignedReleaseVariant {
    fn as_str(self) -> &'static str {
        match self {
            SignedReleaseVariant::InRelease => "InRelease",
            SignedReleaseVariant::ReleaseGpg => "Release.gpg",
        }
    }
}
fn main(){
println!("as_str/InRelease\t{:?}",SignedReleaseVariant::InRelease.as_str().as_bytes());
println!("as_str/ReleaseGpg\t{:?}",SignedReleaseVariant::ReleaseGpg.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(SignedReleaseVariant::InRelease.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::signed_release_variant_007f0cf5::SignedReleaseVariant::InRelease.as_str(),"signed_release_variant_007f0cf5/as_str/InRelease");
assert_eq!(SignedReleaseVariant::ReleaseGpg.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::signed_release_variant_007f0cf5::SignedReleaseVariant::ReleaseGpg.as_str(),"signed_release_variant_007f0cf5/as_str/ReleaseGpg");
}
