#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Role {Viewer,Commenter,Contributor,Editor,Owner}
impl Role {
    /// Lowercase discriminator — matches the SQL `role` ENUM values in
    /// `storage.role_grants` (after the `::text` cast).
    pub fn as_str(self) -> &'static str {
        match self {
            Role::Viewer => "viewer",
            Role::Commenter => "commenter",
            Role::Contributor => "contributor",
            Role::Editor => "editor",
            Role::Owner => "owner",
        }
    }
}
fn main(){
println!("as_str/Viewer\t{:?}",Role::Viewer.as_str().as_bytes());
println!("as_str/Commenter\t{:?}",Role::Commenter.as_str().as_bytes());
println!("as_str/Contributor\t{:?}",Role::Contributor.as_str().as_bytes());
println!("as_str/Editor\t{:?}",Role::Editor.as_str().as_bytes());
println!("as_str/Owner\t{:?}",Role::Owner.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(Role::Viewer.as_str().as_bytes(),oxicloud_kernel::finite_catalog::role_5d9dca62::Role::Viewer.as_str(),"role_5d9dca62/as_str/Viewer");
assert_eq!(Role::Commenter.as_str().as_bytes(),oxicloud_kernel::finite_catalog::role_5d9dca62::Role::Commenter.as_str(),"role_5d9dca62/as_str/Commenter");
assert_eq!(Role::Contributor.as_str().as_bytes(),oxicloud_kernel::finite_catalog::role_5d9dca62::Role::Contributor.as_str(),"role_5d9dca62/as_str/Contributor");
assert_eq!(Role::Editor.as_str().as_bytes(),oxicloud_kernel::finite_catalog::role_5d9dca62::Role::Editor.as_str(),"role_5d9dca62/as_str/Editor");
assert_eq!(Role::Owner.as_str().as_bytes(),oxicloud_kernel::finite_catalog::role_5d9dca62::Role::Owner.as_str(),"role_5d9dca62/as_str/Owner");
}
