#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Role {Read,Write,Admin}
impl Role {
    pub fn can_write(&self) -> bool {
        matches!(self, Role::Write | Role::Admin)
    }
    pub fn can_admin(&self) -> bool {
        matches!(self, Role::Admin)
    }
}
fn main(){
println!("can_write/Read\t{:?}",Role::Read.can_write());
println!("can_write/Write\t{:?}",Role::Write.can_write());
println!("can_write/Admin\t{:?}",Role::Admin.can_write());
println!("can_admin/Read\t{:?}",Role::Read.can_admin());
println!("can_admin/Write\t{:?}",Role::Write.can_admin());
println!("can_admin/Admin\t{:?}",Role::Admin.can_admin());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(Role::Read.can_write(),nora_kernel::finite_catalog::role_a890c86c::Role::Read.can_write(),"role_a890c86c/can_write/Read");
assert_eq!(Role::Write.can_write(),nora_kernel::finite_catalog::role_a890c86c::Role::Write.can_write(),"role_a890c86c/can_write/Write");
assert_eq!(Role::Admin.can_write(),nora_kernel::finite_catalog::role_a890c86c::Role::Admin.can_write(),"role_a890c86c/can_write/Admin");
assert_eq!(Role::Read.can_admin(),nora_kernel::finite_catalog::role_a890c86c::Role::Read.can_admin(),"role_a890c86c/can_admin/Read");
assert_eq!(Role::Write.can_admin(),nora_kernel::finite_catalog::role_a890c86c::Role::Write.can_admin(),"role_a890c86c/can_admin/Write");
assert_eq!(Role::Admin.can_admin(),nora_kernel::finite_catalog::role_a890c86c::Role::Admin.can_admin(),"role_a890c86c/can_admin/Admin");
}
