#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum SessionOrigin {Password,Opaque,MagicLink,Oidc,Device,Unknown}
impl SessionOrigin {
    /// Wire / column string form. Kept out of `Display` to avoid
    /// accidental use in log lines where the Debug form is fine.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Password => "password",
            Self::Opaque => "opaque",
            Self::MagicLink => "magic_link",
            Self::Oidc => "oidc",
            Self::Device => "device",
            Self::Unknown => "unknown",
        }
    }
}
fn main(){
println!("as_str/Password\t{:?}",SessionOrigin::Password.as_str().as_bytes());
println!("as_str/Opaque\t{:?}",SessionOrigin::Opaque.as_str().as_bytes());
println!("as_str/MagicLink\t{:?}",SessionOrigin::MagicLink.as_str().as_bytes());
println!("as_str/Oidc\t{:?}",SessionOrigin::Oidc.as_str().as_bytes());
println!("as_str/Device\t{:?}",SessionOrigin::Device.as_str().as_bytes());
println!("as_str/Unknown\t{:?}",SessionOrigin::Unknown.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(SessionOrigin::Password.as_str().as_bytes(),oxicloud_kernel::finite_catalog::session_origin_086d7c6c::SessionOrigin::Password.as_str(),"session_origin_086d7c6c/as_str/Password");
assert_eq!(SessionOrigin::Opaque.as_str().as_bytes(),oxicloud_kernel::finite_catalog::session_origin_086d7c6c::SessionOrigin::Opaque.as_str(),"session_origin_086d7c6c/as_str/Opaque");
assert_eq!(SessionOrigin::MagicLink.as_str().as_bytes(),oxicloud_kernel::finite_catalog::session_origin_086d7c6c::SessionOrigin::MagicLink.as_str(),"session_origin_086d7c6c/as_str/MagicLink");
assert_eq!(SessionOrigin::Oidc.as_str().as_bytes(),oxicloud_kernel::finite_catalog::session_origin_086d7c6c::SessionOrigin::Oidc.as_str(),"session_origin_086d7c6c/as_str/Oidc");
assert_eq!(SessionOrigin::Device.as_str().as_bytes(),oxicloud_kernel::finite_catalog::session_origin_086d7c6c::SessionOrigin::Device.as_str(),"session_origin_086d7c6c/as_str/Device");
assert_eq!(SessionOrigin::Unknown.as_str().as_bytes(),oxicloud_kernel::finite_catalog::session_origin_086d7c6c::SessionOrigin::Unknown.as_str(),"session_origin_086d7c6c/as_str/Unknown");
}
