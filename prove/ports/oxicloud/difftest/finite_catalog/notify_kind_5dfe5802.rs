#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum NotifyKind {MagicLink,PlainNotification}
impl NotifyKind {
    fn audit_str(self) -> &'static str {
        match self {
            NotifyKind::MagicLink => "magic_link",
            NotifyKind::PlainNotification => "plain_notification",
        }
    }
}
fn main(){
println!("audit_str/MagicLink\t{:?}",NotifyKind::MagicLink.audit_str().as_bytes());
println!("audit_str/PlainNotification\t{:?}",NotifyKind::PlainNotification.audit_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(NotifyKind::MagicLink.audit_str().as_bytes(),oxicloud_kernel::finite_catalog::notify_kind_5dfe5802::NotifyKind::MagicLink.audit_str(),"notify_kind_5dfe5802/audit_str/MagicLink");
assert_eq!(NotifyKind::PlainNotification.audit_str().as_bytes(),oxicloud_kernel::finite_catalog::notify_kind_5dfe5802::NotifyKind::PlainNotification.audit_str(),"notify_kind_5dfe5802/audit_str/PlainNotification");
}
