#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Permission {Read,Create,Share,Comment,Delete,Update,Manage}
impl Permission {
    pub fn as_str(&self) -> &'static str {
        match self {
            Permission::Read => "read",
            Permission::Create => "create",
            Permission::Share => "share",
            Permission::Comment => "comment",
            Permission::Delete => "delete",
            Permission::Update => "update",
            Permission::Manage => "manage",
        }
    }
}
fn main(){
println!("as_str/Read\t{:?}",Permission::Read.as_str().as_bytes());
println!("as_str/Create\t{:?}",Permission::Create.as_str().as_bytes());
println!("as_str/Share\t{:?}",Permission::Share.as_str().as_bytes());
println!("as_str/Comment\t{:?}",Permission::Comment.as_str().as_bytes());
println!("as_str/Delete\t{:?}",Permission::Delete.as_str().as_bytes());
println!("as_str/Update\t{:?}",Permission::Update.as_str().as_bytes());
println!("as_str/Manage\t{:?}",Permission::Manage.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(Permission::Read.as_str().as_bytes(),oxicloud_kernel::finite_catalog::permission_5d9dca62::Permission::Read.as_str(),"permission_5d9dca62/as_str/Read");
assert_eq!(Permission::Create.as_str().as_bytes(),oxicloud_kernel::finite_catalog::permission_5d9dca62::Permission::Create.as_str(),"permission_5d9dca62/as_str/Create");
assert_eq!(Permission::Share.as_str().as_bytes(),oxicloud_kernel::finite_catalog::permission_5d9dca62::Permission::Share.as_str(),"permission_5d9dca62/as_str/Share");
assert_eq!(Permission::Comment.as_str().as_bytes(),oxicloud_kernel::finite_catalog::permission_5d9dca62::Permission::Comment.as_str(),"permission_5d9dca62/as_str/Comment");
assert_eq!(Permission::Delete.as_str().as_bytes(),oxicloud_kernel::finite_catalog::permission_5d9dca62::Permission::Delete.as_str(),"permission_5d9dca62/as_str/Delete");
assert_eq!(Permission::Update.as_str().as_bytes(),oxicloud_kernel::finite_catalog::permission_5d9dca62::Permission::Update.as_str(),"permission_5d9dca62/as_str/Update");
assert_eq!(Permission::Manage.as_str().as_bytes(),oxicloud_kernel::finite_catalog::permission_5d9dca62::Permission::Manage.as_str(),"permission_5d9dca62/as_str/Manage");
}
