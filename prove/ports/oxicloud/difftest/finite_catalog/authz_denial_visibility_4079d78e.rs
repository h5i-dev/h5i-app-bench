#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AuthzDenialVisibility {Visible,Hidden}
impl AuthzDenialVisibility {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Visible => "visible",
            Self::Hidden => "hidden",
        }
    }
}
fn main(){
println!("as_str/Visible\t{:?}",AuthzDenialVisibility::Visible.as_str().as_bytes());
println!("as_str/Hidden\t{:?}",AuthzDenialVisibility::Hidden.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(AuthzDenialVisibility::Visible.as_str().as_bytes(),oxicloud_kernel::finite_catalog::authz_denial_visibility_4079d78e::AuthzDenialVisibility::Visible.as_str(),"authz_denial_visibility_4079d78e/as_str/Visible");
assert_eq!(AuthzDenialVisibility::Hidden.as_str().as_bytes(),oxicloud_kernel::finite_catalog::authz_denial_visibility_4079d78e::AuthzDenialVisibility::Hidden.as_str(),"authz_denial_visibility_4079d78e/as_str/Hidden");
}
