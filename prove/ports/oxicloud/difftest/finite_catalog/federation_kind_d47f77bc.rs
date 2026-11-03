#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum FederationKind {MagicLink,Ocm,Oidc}
impl FederationKind {
    /// Canonical DB / wire spelling — matches the CHECK constraint on
    /// `auth.users.federation_kind`.
    pub fn as_str(self) -> &'static str {
        match self {
            FederationKind::MagicLink => "magic_link",
            FederationKind::Ocm => "ocm",
            FederationKind::Oidc => "oidc",
        }
    }
}
fn main(){
println!("as_str/MagicLink\t{:?}",FederationKind::MagicLink.as_str().as_bytes());
println!("as_str/Ocm\t{:?}",FederationKind::Ocm.as_str().as_bytes());
println!("as_str/Oidc\t{:?}",FederationKind::Oidc.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(FederationKind::MagicLink.as_str().as_bytes(),oxicloud_kernel::finite_catalog::federation_kind_d47f77bc::FederationKind::MagicLink.as_str(),"federation_kind_d47f77bc/as_str/MagicLink");
assert_eq!(FederationKind::Ocm.as_str().as_bytes(),oxicloud_kernel::finite_catalog::federation_kind_d47f77bc::FederationKind::Ocm.as_str(),"federation_kind_d47f77bc/as_str/Ocm");
assert_eq!(FederationKind::Oidc.as_str().as_bytes(),oxicloud_kernel::finite_catalog::federation_kind_d47f77bc::FederationKind::Oidc.as_str(),"federation_kind_d47f77bc/as_str/Oidc");
}
