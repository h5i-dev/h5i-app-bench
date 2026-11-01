#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum DriveKind {Personal,Shared}
impl DriveKind {
    pub fn as_str(self) -> &'static str {
        match self {
            DriveKind::Personal => "personal",
            DriveKind::Shared => "shared",
        }
    }
}
fn main(){
println!("as_str/Personal\t{:?}",DriveKind::Personal.as_str().as_bytes());
println!("as_str/Shared\t{:?}",DriveKind::Shared.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(DriveKind::Personal.as_str().as_bytes(),oxicloud_kernel::finite_catalog::drive_kind_bf867fda::DriveKind::Personal.as_str(),"drive_kind_bf867fda/as_str/Personal");
assert_eq!(DriveKind::Shared.as_str().as_bytes(),oxicloud_kernel::finite_catalog::drive_kind_bf867fda::DriveKind::Shared.as_str(),"drive_kind_bf867fda/as_str/Shared");
}
