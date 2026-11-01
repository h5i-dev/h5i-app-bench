#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum DeviceCodeStatus {Pending,Authorized,Denied,Expired}
impl DeviceCodeStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Pending => "pending",
            Self::Authorized => "authorized",
            Self::Denied => "denied",
            Self::Expired => "expired",
        }
    }
}
fn main(){
println!("as_str/Pending\t{:?}",DeviceCodeStatus::Pending.as_str().as_bytes());
println!("as_str/Authorized\t{:?}",DeviceCodeStatus::Authorized.as_str().as_bytes());
println!("as_str/Denied\t{:?}",DeviceCodeStatus::Denied.as_str().as_bytes());
println!("as_str/Expired\t{:?}",DeviceCodeStatus::Expired.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(DeviceCodeStatus::Pending.as_str().as_bytes(),oxicloud_kernel::finite_catalog::device_code_status_fb933849::DeviceCodeStatus::Pending.as_str(),"device_code_status_fb933849/as_str/Pending");
assert_eq!(DeviceCodeStatus::Authorized.as_str().as_bytes(),oxicloud_kernel::finite_catalog::device_code_status_fb933849::DeviceCodeStatus::Authorized.as_str(),"device_code_status_fb933849/as_str/Authorized");
assert_eq!(DeviceCodeStatus::Denied.as_str().as_bytes(),oxicloud_kernel::finite_catalog::device_code_status_fb933849::DeviceCodeStatus::Denied.as_str(),"device_code_status_fb933849/as_str/Denied");
assert_eq!(DeviceCodeStatus::Expired.as_str().as_bytes(),oxicloud_kernel::finite_catalog::device_code_status_fb933849::DeviceCodeStatus::Expired.as_str(),"device_code_status_fb933849/as_str/Expired");
}
