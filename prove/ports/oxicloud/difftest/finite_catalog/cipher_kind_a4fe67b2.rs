#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum CipherKind {AesGcm256,None}
impl CipherKind {
    /// Stable env-var-friendly name — the exact string the parser
    /// accepts back and the string admin surfaces render.
    pub fn as_str(self) -> &'static str {
        match self {
            CipherKind::AesGcm256 => "aes-256-gcm",
            CipherKind::None => "none",
        }
    }
    /// `true` iff this cipher carries key material. `false` for
    /// `CipherKind::None`. Used by the parser to enforce
    /// "no key after `none:`" and by K2's write path to skip the
    /// AEAD call.
    pub fn needs_key(self) -> bool {
        matches!(self, CipherKind::AesGcm256)
    }
}
fn main(){
println!("as_str/AesGcm256\t{:?}",CipherKind::AesGcm256.as_str().as_bytes());
println!("as_str/None\t{:?}",CipherKind::None.as_str().as_bytes());
println!("needs_key/AesGcm256\t{:?}",CipherKind::AesGcm256.needs_key());
println!("needs_key/None\t{:?}",CipherKind::None.needs_key());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(CipherKind::AesGcm256.as_str().as_bytes(),oxicloud_kernel::finite_catalog::cipher_kind_a4fe67b2::CipherKind::AesGcm256.as_str(),"cipher_kind_a4fe67b2/as_str/AesGcm256");
assert_eq!(CipherKind::None.as_str().as_bytes(),oxicloud_kernel::finite_catalog::cipher_kind_a4fe67b2::CipherKind::None.as_str(),"cipher_kind_a4fe67b2/as_str/None");
assert_eq!(CipherKind::AesGcm256.needs_key(),oxicloud_kernel::finite_catalog::cipher_kind_a4fe67b2::CipherKind::AesGcm256.needs_key(),"cipher_kind_a4fe67b2/needs_key/AesGcm256");
assert_eq!(CipherKind::None.needs_key(),oxicloud_kernel::finite_catalog::cipher_kind_a4fe67b2::CipherKind::None.needs_key(),"cipher_kind_a4fe67b2/needs_key/None");
}
