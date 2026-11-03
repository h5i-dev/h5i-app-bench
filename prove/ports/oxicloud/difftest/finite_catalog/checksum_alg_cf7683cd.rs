#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ChecksumAlg {Md5,Sha256,Blake3}
impl ChecksumAlg {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Md5 => "md5",
            Self::Sha256 => "sha256",
            Self::Blake3 => "blake3",
        }
    }
}
fn main(){
println!("as_str/Md5\t{:?}",ChecksumAlg::Md5.as_str().as_bytes());
println!("as_str/Sha256\t{:?}",ChecksumAlg::Sha256.as_str().as_bytes());
println!("as_str/Blake3\t{:?}",ChecksumAlg::Blake3.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(ChecksumAlg::Md5.as_str().as_bytes(),oxicloud_kernel::finite_catalog::checksum_alg_cf7683cd::ChecksumAlg::Md5.as_str(),"checksum_alg_cf7683cd/as_str/Md5");
assert_eq!(ChecksumAlg::Sha256.as_str().as_bytes(),oxicloud_kernel::finite_catalog::checksum_alg_cf7683cd::ChecksumAlg::Sha256.as_str(),"checksum_alg_cf7683cd/as_str/Sha256");
assert_eq!(ChecksumAlg::Blake3.as_str().as_bytes(),oxicloud_kernel::finite_catalog::checksum_alg_cf7683cd::ChecksumAlg::Blake3.as_str(),"checksum_alg_cf7683cd/as_str/Blake3");
}
