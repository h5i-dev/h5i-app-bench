#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum DpopVerifyError {Malformed,WrongTyp,WrongAlg,WrongJwk,SignatureInvalid,WrongHtm,WrongHtu,IatMissing,IatOutOfWindow,JtiMissing,JktMismatch}
impl DpopVerifyError {
    /// Stable machine-readable reason string for audit lines.
    pub fn reason(&self) -> &'static str {
        match self {
            Self::Malformed => "malformed_jws",
            Self::WrongTyp => "wrong_typ",
            Self::WrongAlg => "wrong_alg",
            Self::WrongJwk => "wrong_jwk",
            Self::SignatureInvalid => "signature_invalid",
            Self::WrongHtm => "wrong_htm",
            Self::WrongHtu => "wrong_htu",
            Self::IatMissing => "iat_missing",
            Self::IatOutOfWindow => "iat_out_of_window",
            Self::JtiMissing => "jti_missing",
            Self::JktMismatch => "jkt_mismatch",
        }
    }
}
fn main(){
println!("reason/Malformed\t{:?}",DpopVerifyError::Malformed.reason().as_bytes());
println!("reason/WrongTyp\t{:?}",DpopVerifyError::WrongTyp.reason().as_bytes());
println!("reason/WrongAlg\t{:?}",DpopVerifyError::WrongAlg.reason().as_bytes());
println!("reason/WrongJwk\t{:?}",DpopVerifyError::WrongJwk.reason().as_bytes());
println!("reason/SignatureInvalid\t{:?}",DpopVerifyError::SignatureInvalid.reason().as_bytes());
println!("reason/WrongHtm\t{:?}",DpopVerifyError::WrongHtm.reason().as_bytes());
println!("reason/WrongHtu\t{:?}",DpopVerifyError::WrongHtu.reason().as_bytes());
println!("reason/IatMissing\t{:?}",DpopVerifyError::IatMissing.reason().as_bytes());
println!("reason/IatOutOfWindow\t{:?}",DpopVerifyError::IatOutOfWindow.reason().as_bytes());
println!("reason/JtiMissing\t{:?}",DpopVerifyError::JtiMissing.reason().as_bytes());
println!("reason/JktMismatch\t{:?}",DpopVerifyError::JktMismatch.reason().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(DpopVerifyError::Malformed.reason().as_bytes(),oxicloud_kernel::finite_catalog::dpop_verify_error_8219bbef::DpopVerifyError::Malformed.reason(),"dpop_verify_error_8219bbef/reason/Malformed");
assert_eq!(DpopVerifyError::WrongTyp.reason().as_bytes(),oxicloud_kernel::finite_catalog::dpop_verify_error_8219bbef::DpopVerifyError::WrongTyp.reason(),"dpop_verify_error_8219bbef/reason/WrongTyp");
assert_eq!(DpopVerifyError::WrongAlg.reason().as_bytes(),oxicloud_kernel::finite_catalog::dpop_verify_error_8219bbef::DpopVerifyError::WrongAlg.reason(),"dpop_verify_error_8219bbef/reason/WrongAlg");
assert_eq!(DpopVerifyError::WrongJwk.reason().as_bytes(),oxicloud_kernel::finite_catalog::dpop_verify_error_8219bbef::DpopVerifyError::WrongJwk.reason(),"dpop_verify_error_8219bbef/reason/WrongJwk");
assert_eq!(DpopVerifyError::SignatureInvalid.reason().as_bytes(),oxicloud_kernel::finite_catalog::dpop_verify_error_8219bbef::DpopVerifyError::SignatureInvalid.reason(),"dpop_verify_error_8219bbef/reason/SignatureInvalid");
assert_eq!(DpopVerifyError::WrongHtm.reason().as_bytes(),oxicloud_kernel::finite_catalog::dpop_verify_error_8219bbef::DpopVerifyError::WrongHtm.reason(),"dpop_verify_error_8219bbef/reason/WrongHtm");
assert_eq!(DpopVerifyError::WrongHtu.reason().as_bytes(),oxicloud_kernel::finite_catalog::dpop_verify_error_8219bbef::DpopVerifyError::WrongHtu.reason(),"dpop_verify_error_8219bbef/reason/WrongHtu");
assert_eq!(DpopVerifyError::IatMissing.reason().as_bytes(),oxicloud_kernel::finite_catalog::dpop_verify_error_8219bbef::DpopVerifyError::IatMissing.reason(),"dpop_verify_error_8219bbef/reason/IatMissing");
assert_eq!(DpopVerifyError::IatOutOfWindow.reason().as_bytes(),oxicloud_kernel::finite_catalog::dpop_verify_error_8219bbef::DpopVerifyError::IatOutOfWindow.reason(),"dpop_verify_error_8219bbef/reason/IatOutOfWindow");
assert_eq!(DpopVerifyError::JtiMissing.reason().as_bytes(),oxicloud_kernel::finite_catalog::dpop_verify_error_8219bbef::DpopVerifyError::JtiMissing.reason(),"dpop_verify_error_8219bbef/reason/JtiMissing");
assert_eq!(DpopVerifyError::JktMismatch.reason().as_bytes(),oxicloud_kernel::finite_catalog::dpop_verify_error_8219bbef::DpopVerifyError::JktMismatch.reason(),"dpop_verify_error_8219bbef/reason/JktMismatch");
}
