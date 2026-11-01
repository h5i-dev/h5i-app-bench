#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum UserRole {Owner,Admin,User,Anonymous}
impl UserRole {
    /// Canonical wire/DB spelling — the single source the `Display` impl
    /// and every hot-path role render go through (no format machinery).
    pub fn as_str(self) -> &'static str {
        match self {
            UserRole::Owner => "owner",
            UserRole::Admin => "admin",
            UserRole::User => "user",
            UserRole::Anonymous => "anonymous",
        }
    }
    /// Privilege order: `Anonymous` < `User` < `Admin` < `Owner`.
    ///
    /// Deliberately an explicit rank rather than a derived `Ord` — a derive
    /// follows declaration order, so reordering the variants would silently
    /// invert every comparison.
    ///
    /// Contiguous on purpose. Gaps "reserved for future roles" buy nothing:
    /// adding a variant means revisiting every `match` on this enum anyway,
    /// and the integers appear in no wire format.
    pub fn rank(self) -> u8 {
        match self {
            UserRole::Anonymous => 0,
            UserRole::User => 1,
            UserRole::Admin => 2,
            UserRole::Owner => 3,
        }
    }
    /// True for a principal with no `auth.users` row behind it.
    pub fn is_anonymous(self) -> bool {
        matches!(self, UserRole::Anonymous)
    }
    /// True for any role carrying more authority than a regular user.
    ///
    /// The external-identity guards ask this question — "may an
    /// IdP-provisioned account hold this role?" — and they MUST ask it
    /// this way rather than comparing against `Admin`. `Admin` was
    /// historically the only privileged role, so the guards were written
    /// as `role == Admin`; a role added *above* Admin would then walk
    /// straight through them, letting a federated identity hold the most
    /// privileged account on the instance.
    ///
    /// Phrased as a negative ("more than a plain user") this stays correct
    /// for roles that do not exist yet. Do not respell it as a list.
    /// See `docs/plan/role-hierarchy-owner.md`.
    pub fn is_privileged(self) -> bool {
        self.rank() > UserRole::User.rank()
    }
}
fn main(){
println!("as_str/Owner\t{:?}",UserRole::Owner.as_str().as_bytes());
println!("as_str/Admin\t{:?}",UserRole::Admin.as_str().as_bytes());
println!("as_str/User\t{:?}",UserRole::User.as_str().as_bytes());
println!("as_str/Anonymous\t{:?}",UserRole::Anonymous.as_str().as_bytes());
println!("rank/Owner\t{:?}",UserRole::Owner.rank());
println!("rank/Admin\t{:?}",UserRole::Admin.rank());
println!("rank/User\t{:?}",UserRole::User.rank());
println!("rank/Anonymous\t{:?}",UserRole::Anonymous.rank());
println!("is_anonymous/Owner\t{:?}",UserRole::Owner.is_anonymous());
println!("is_anonymous/Admin\t{:?}",UserRole::Admin.is_anonymous());
println!("is_anonymous/User\t{:?}",UserRole::User.is_anonymous());
println!("is_anonymous/Anonymous\t{:?}",UserRole::Anonymous.is_anonymous());
println!("is_privileged/Owner\t{:?}",UserRole::Owner.is_privileged());
println!("is_privileged/Admin\t{:?}",UserRole::Admin.is_privileged());
println!("is_privileged/User\t{:?}",UserRole::User.is_privileged());
println!("is_privileged/Anonymous\t{:?}",UserRole::Anonymous.is_privileged());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(UserRole::Owner.as_str().as_bytes(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::Owner.as_str(),"user_role_d47f77bc/as_str/Owner");
assert_eq!(UserRole::Admin.as_str().as_bytes(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::Admin.as_str(),"user_role_d47f77bc/as_str/Admin");
assert_eq!(UserRole::User.as_str().as_bytes(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::User.as_str(),"user_role_d47f77bc/as_str/User");
assert_eq!(UserRole::Anonymous.as_str().as_bytes(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::Anonymous.as_str(),"user_role_d47f77bc/as_str/Anonymous");
assert_eq!(UserRole::Owner.rank(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::Owner.rank(),"user_role_d47f77bc/rank/Owner");
assert_eq!(UserRole::Admin.rank(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::Admin.rank(),"user_role_d47f77bc/rank/Admin");
assert_eq!(UserRole::User.rank(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::User.rank(),"user_role_d47f77bc/rank/User");
assert_eq!(UserRole::Anonymous.rank(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::Anonymous.rank(),"user_role_d47f77bc/rank/Anonymous");
assert_eq!(UserRole::Owner.is_anonymous(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::Owner.is_anonymous(),"user_role_d47f77bc/is_anonymous/Owner");
assert_eq!(UserRole::Admin.is_anonymous(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::Admin.is_anonymous(),"user_role_d47f77bc/is_anonymous/Admin");
assert_eq!(UserRole::User.is_anonymous(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::User.is_anonymous(),"user_role_d47f77bc/is_anonymous/User");
assert_eq!(UserRole::Anonymous.is_anonymous(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::Anonymous.is_anonymous(),"user_role_d47f77bc/is_anonymous/Anonymous");
assert_eq!(UserRole::Owner.is_privileged(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::Owner.is_privileged(),"user_role_d47f77bc/is_privileged/Owner");
assert_eq!(UserRole::Admin.is_privileged(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::Admin.is_privileged(),"user_role_d47f77bc/is_privileged/Admin");
assert_eq!(UserRole::User.is_privileged(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::User.is_privileged(),"user_role_d47f77bc/is_privileged/User");
assert_eq!(UserRole::Anonymous.is_privileged(),oxicloud_kernel::finite_catalog::user_role_d47f77bc::UserRole::Anonymous.is_privileged(),"user_role_d47f77bc/is_privileged/Anonymous");
}
