#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum MagicLinkStatus {Pending,Used,Expired}
impl MagicLinkStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Pending => "pending",
            Self::Used => "used",
            Self::Expired => "expired",
        }
    }
}
fn main(){
println!("as_str/Pending\t{:?}",MagicLinkStatus::Pending.as_str().as_bytes());
println!("as_str/Used\t{:?}",MagicLinkStatus::Used.as_str().as_bytes());
println!("as_str/Expired\t{:?}",MagicLinkStatus::Expired.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(MagicLinkStatus::Pending.as_str().as_bytes(),oxicloud_kernel::finite_catalog::magic_link_status_023c994e::MagicLinkStatus::Pending.as_str(),"magic_link_status_023c994e/as_str/Pending");
assert_eq!(MagicLinkStatus::Used.as_str().as_bytes(),oxicloud_kernel::finite_catalog::magic_link_status_023c994e::MagicLinkStatus::Used.as_str(),"magic_link_status_023c994e/as_str/Used");
assert_eq!(MagicLinkStatus::Expired.as_str().as_bytes(),oxicloud_kernel::finite_catalog::magic_link_status_023c994e::MagicLinkStatus::Expired.as_str(),"magic_link_status_023c994e/as_str/Expired");
}
