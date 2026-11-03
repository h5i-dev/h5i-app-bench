#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OpaqueMode {Off,Migrate,OpaqueOnly}
impl OpaqueMode {
    /// Canonical wire spelling — the token the operator sets in
    /// `OXICLOUD_AUTH_OPAQUE_MODE` and the value published on
    /// `GET /api/config`. Kept in sync with `parse()` on the primary
    /// spellings.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Off => "off",
            Self::Migrate => "migrate",
            Self::OpaqueOnly => "opaque_only",
        }
    }
}
fn main(){
println!("as_str/Off\t{:?}",OpaqueMode::Off.as_str().as_bytes());
println!("as_str/Migrate\t{:?}",OpaqueMode::Migrate.as_str().as_bytes());
println!("as_str/OpaqueOnly\t{:?}",OpaqueMode::OpaqueOnly.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(OpaqueMode::Off.as_str().as_bytes(),oxicloud_kernel::finite_catalog::opaque_mode_b0957357::OpaqueMode::Off.as_str(),"opaque_mode_b0957357/as_str/Off");
assert_eq!(OpaqueMode::Migrate.as_str().as_bytes(),oxicloud_kernel::finite_catalog::opaque_mode_b0957357::OpaqueMode::Migrate.as_str(),"opaque_mode_b0957357/as_str/Migrate");
assert_eq!(OpaqueMode::OpaqueOnly.as_str().as_bytes(),oxicloud_kernel::finite_catalog::opaque_mode_b0957357::OpaqueMode::OpaqueOnly.as_str(),"opaque_mode_b0957357/as_str/OpaqueOnly");
}
