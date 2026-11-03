#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum TotpPolicy {Disabled,RequiredForAdmins,RequiredForAll}
impl TotpPolicy {
    /// Canonical wire/storage spelling.
    pub fn as_str(self) -> &'static str {
        match self {
            TotpPolicy::Disabled => "disabled",
            TotpPolicy::RequiredForAdmins => "required_for_admins",
            TotpPolicy::RequiredForAll => "required_for_all",
        }
    }
    /// Whether this policy enforces anything at all.
    pub fn is_enforcing(self) -> bool {
        !matches!(self, TotpPolicy::Disabled)
    }
}
fn main(){
println!("as_str/Disabled\t{:?}",TotpPolicy::Disabled.as_str().as_bytes());
println!("as_str/RequiredForAdmins\t{:?}",TotpPolicy::RequiredForAdmins.as_str().as_bytes());
println!("as_str/RequiredForAll\t{:?}",TotpPolicy::RequiredForAll.as_str().as_bytes());
println!("is_enforcing/Disabled\t{:?}",TotpPolicy::Disabled.is_enforcing());
println!("is_enforcing/RequiredForAdmins\t{:?}",TotpPolicy::RequiredForAdmins.is_enforcing());
println!("is_enforcing/RequiredForAll\t{:?}",TotpPolicy::RequiredForAll.is_enforcing());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(TotpPolicy::Disabled.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::totp_policy_31812d2d::TotpPolicy::Disabled.as_str(),"totp_policy_31812d2d/as_str/Disabled");
assert_eq!(TotpPolicy::RequiredForAdmins.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::totp_policy_31812d2d::TotpPolicy::RequiredForAdmins.as_str(),"totp_policy_31812d2d/as_str/RequiredForAdmins");
assert_eq!(TotpPolicy::RequiredForAll.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::totp_policy_31812d2d::TotpPolicy::RequiredForAll.as_str(),"totp_policy_31812d2d/as_str/RequiredForAll");
assert_eq!(TotpPolicy::Disabled.is_enforcing(),artifactkeeper_kernel::finite_catalog::totp_policy_31812d2d::TotpPolicy::Disabled.is_enforcing(),"totp_policy_31812d2d/is_enforcing/Disabled");
assert_eq!(TotpPolicy::RequiredForAdmins.is_enforcing(),artifactkeeper_kernel::finite_catalog::totp_policy_31812d2d::TotpPolicy::RequiredForAdmins.is_enforcing(),"totp_policy_31812d2d/is_enforcing/RequiredForAdmins");
assert_eq!(TotpPolicy::RequiredForAll.is_enforcing(),artifactkeeper_kernel::finite_catalog::totp_policy_31812d2d::TotpPolicy::RequiredForAll.is_enforcing(),"totp_policy_31812d2d/is_enforcing/RequiredForAll");
}
