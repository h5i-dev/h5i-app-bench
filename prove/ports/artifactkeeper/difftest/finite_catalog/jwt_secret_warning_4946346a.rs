#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum JwtSecretWarning {TooShort,KnownPlaceholder,LowEntropy}
impl JwtSecretWarning {
    fn message(self) -> &'static str {
        match self {
            JwtSecretWarning::TooShort => "it is shorter than 32 characters.",
            JwtSecretWarning::KnownPlaceholder => "it is a known placeholder/default value.",
            JwtSecretWarning::LowEntropy => {
                "it has low entropy (under 128 estimated bits, or an obvious repeat or sequence)."
            }
        }
    }
}
fn main(){
println!("message/TooShort\t{:?}",JwtSecretWarning::TooShort.message().as_bytes());
println!("message/KnownPlaceholder\t{:?}",JwtSecretWarning::KnownPlaceholder.message().as_bytes());
println!("message/LowEntropy\t{:?}",JwtSecretWarning::LowEntropy.message().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(JwtSecretWarning::TooShort.message().as_bytes(),artifactkeeper_kernel::finite_catalog::jwt_secret_warning_4946346a::JwtSecretWarning::TooShort.message(),"jwt_secret_warning_4946346a/message/TooShort");
assert_eq!(JwtSecretWarning::KnownPlaceholder.message().as_bytes(),artifactkeeper_kernel::finite_catalog::jwt_secret_warning_4946346a::JwtSecretWarning::KnownPlaceholder.message(),"jwt_secret_warning_4946346a/message/KnownPlaceholder");
assert_eq!(JwtSecretWarning::LowEntropy.message().as_bytes(),artifactkeeper_kernel::finite_catalog::jwt_secret_warning_4946346a::JwtSecretWarning::LowEntropy.message(),"jwt_secret_warning_4946346a/message/LowEntropy");
}
