#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Check {BundleWellFormed = 0,SubjectDigestBound = 1,CryptoAndChain = 2,RekorInclusion = 3,IdentityExtracted = 4,IssuerAllowlisted = 5,PublisherOwnerBound = 6,RekorSet = 7,StatementPolicy = 8}
impl Check {
    fn bit(self) -> u16 {
        1 << (self as u16)
    }
    fn reason_label(self) -> &'static str {
        match self {
            Check::BundleWellFormed => "bundle",
            Check::SubjectDigestBound => "subject binding",
            Check::CryptoAndChain => "signature/certificate chain",
            Check::RekorSet => "transparency (Rekor SET)",
            Check::RekorInclusion => "transparency (Rekor inclusion)",
            Check::IssuerAllowlisted => "issuer",
            Check::IdentityExtracted => "identity",
            Check::PublisherOwnerBound => "identity binding",
            Check::StatementPolicy => "statement policy",
        }
    }
}
fn main(){
println!("bit/BundleWellFormed\t{:?}",Check::BundleWellFormed.bit());
println!("bit/SubjectDigestBound\t{:?}",Check::SubjectDigestBound.bit());
println!("bit/CryptoAndChain\t{:?}",Check::CryptoAndChain.bit());
println!("bit/RekorInclusion\t{:?}",Check::RekorInclusion.bit());
println!("bit/IdentityExtracted\t{:?}",Check::IdentityExtracted.bit());
println!("bit/IssuerAllowlisted\t{:?}",Check::IssuerAllowlisted.bit());
println!("bit/PublisherOwnerBound\t{:?}",Check::PublisherOwnerBound.bit());
println!("bit/RekorSet\t{:?}",Check::RekorSet.bit());
println!("bit/StatementPolicy\t{:?}",Check::StatementPolicy.bit());
println!("reason_label/BundleWellFormed\t{:?}",Check::BundleWellFormed.reason_label().as_bytes());
println!("reason_label/SubjectDigestBound\t{:?}",Check::SubjectDigestBound.reason_label().as_bytes());
println!("reason_label/CryptoAndChain\t{:?}",Check::CryptoAndChain.reason_label().as_bytes());
println!("reason_label/RekorInclusion\t{:?}",Check::RekorInclusion.reason_label().as_bytes());
println!("reason_label/IdentityExtracted\t{:?}",Check::IdentityExtracted.reason_label().as_bytes());
println!("reason_label/IssuerAllowlisted\t{:?}",Check::IssuerAllowlisted.reason_label().as_bytes());
println!("reason_label/PublisherOwnerBound\t{:?}",Check::PublisherOwnerBound.reason_label().as_bytes());
println!("reason_label/RekorSet\t{:?}",Check::RekorSet.reason_label().as_bytes());
println!("reason_label/StatementPolicy\t{:?}",Check::StatementPolicy.reason_label().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(Check::BundleWellFormed.bit(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::BundleWellFormed.bit(),"check_b0946112/bit/BundleWellFormed");
assert_eq!(Check::SubjectDigestBound.bit(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::SubjectDigestBound.bit(),"check_b0946112/bit/SubjectDigestBound");
assert_eq!(Check::CryptoAndChain.bit(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::CryptoAndChain.bit(),"check_b0946112/bit/CryptoAndChain");
assert_eq!(Check::RekorInclusion.bit(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::RekorInclusion.bit(),"check_b0946112/bit/RekorInclusion");
assert_eq!(Check::IdentityExtracted.bit(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::IdentityExtracted.bit(),"check_b0946112/bit/IdentityExtracted");
assert_eq!(Check::IssuerAllowlisted.bit(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::IssuerAllowlisted.bit(),"check_b0946112/bit/IssuerAllowlisted");
assert_eq!(Check::PublisherOwnerBound.bit(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::PublisherOwnerBound.bit(),"check_b0946112/bit/PublisherOwnerBound");
assert_eq!(Check::RekorSet.bit(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::RekorSet.bit(),"check_b0946112/bit/RekorSet");
assert_eq!(Check::StatementPolicy.bit(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::StatementPolicy.bit(),"check_b0946112/bit/StatementPolicy");
assert_eq!(Check::BundleWellFormed.reason_label().as_bytes(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::BundleWellFormed.reason_label(),"check_b0946112/reason_label/BundleWellFormed");
assert_eq!(Check::SubjectDigestBound.reason_label().as_bytes(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::SubjectDigestBound.reason_label(),"check_b0946112/reason_label/SubjectDigestBound");
assert_eq!(Check::CryptoAndChain.reason_label().as_bytes(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::CryptoAndChain.reason_label(),"check_b0946112/reason_label/CryptoAndChain");
assert_eq!(Check::RekorInclusion.reason_label().as_bytes(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::RekorInclusion.reason_label(),"check_b0946112/reason_label/RekorInclusion");
assert_eq!(Check::IdentityExtracted.reason_label().as_bytes(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::IdentityExtracted.reason_label(),"check_b0946112/reason_label/IdentityExtracted");
assert_eq!(Check::IssuerAllowlisted.reason_label().as_bytes(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::IssuerAllowlisted.reason_label(),"check_b0946112/reason_label/IssuerAllowlisted");
assert_eq!(Check::PublisherOwnerBound.reason_label().as_bytes(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::PublisherOwnerBound.reason_label(),"check_b0946112/reason_label/PublisherOwnerBound");
assert_eq!(Check::RekorSet.reason_label().as_bytes(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::RekorSet.reason_label(),"check_b0946112/reason_label/RekorSet");
assert_eq!(Check::StatementPolicy.reason_label().as_bytes(),artifactkeeper_kernel::finite_catalog::check_b0946112::Check::StatementPolicy.reason_label(),"check_b0946112/reason_label/StatementPolicy");
}
