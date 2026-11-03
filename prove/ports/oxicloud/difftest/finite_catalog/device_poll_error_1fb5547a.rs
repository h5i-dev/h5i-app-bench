#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum DevicePollError {AuthorizationPending,SlowDown,AccessDenied,ExpiredToken,InvalidDeviceCode}
impl DevicePollError {
    /// RFC 8628 error string for the JSON response.
    pub fn error_code(&self) -> &'static str {
        match self {
            Self::AuthorizationPending => "authorization_pending",
            Self::SlowDown => "slow_down",
            Self::AccessDenied => "access_denied",
            Self::ExpiredToken => "expired_token",
            Self::InvalidDeviceCode => "invalid_grant",
        }
    }
    pub fn description(&self) -> &'static str {
        match self {
            Self::AuthorizationPending => {
                "The authorization request is still pending. Continue polling."
            }
            Self::SlowDown => "You are polling too frequently. Please slow down.",
            Self::AccessDenied => "The user denied the authorization request.",
            Self::ExpiredToken => {
                "The device_code has expired. Please start a new authorization flow."
            }
            Self::InvalidDeviceCode => "The device_code is not recognized.",
        }
    }
    /// HTTP status code per RFC 8628 §3.5:
    /// - authorization_pending and slow_down: 400
    /// - access_denied: 403
    /// - expired_token: 400
    pub fn http_status(&self) -> u16 {
        match self {
            Self::AuthorizationPending | Self::SlowDown | Self::ExpiredToken => 400,
            Self::AccessDenied => 403,
            Self::InvalidDeviceCode => 400,
        }
    }
}
fn main(){
println!("error_code/AuthorizationPending\t{:?}",DevicePollError::AuthorizationPending.error_code().as_bytes());
println!("error_code/SlowDown\t{:?}",DevicePollError::SlowDown.error_code().as_bytes());
println!("error_code/AccessDenied\t{:?}",DevicePollError::AccessDenied.error_code().as_bytes());
println!("error_code/ExpiredToken\t{:?}",DevicePollError::ExpiredToken.error_code().as_bytes());
println!("error_code/InvalidDeviceCode\t{:?}",DevicePollError::InvalidDeviceCode.error_code().as_bytes());
println!("description/AuthorizationPending\t{:?}",DevicePollError::AuthorizationPending.description().as_bytes());
println!("description/SlowDown\t{:?}",DevicePollError::SlowDown.description().as_bytes());
println!("description/AccessDenied\t{:?}",DevicePollError::AccessDenied.description().as_bytes());
println!("description/ExpiredToken\t{:?}",DevicePollError::ExpiredToken.description().as_bytes());
println!("description/InvalidDeviceCode\t{:?}",DevicePollError::InvalidDeviceCode.description().as_bytes());
println!("http_status/AuthorizationPending\t{:?}",DevicePollError::AuthorizationPending.http_status());
println!("http_status/SlowDown\t{:?}",DevicePollError::SlowDown.http_status());
println!("http_status/AccessDenied\t{:?}",DevicePollError::AccessDenied.http_status());
println!("http_status/ExpiredToken\t{:?}",DevicePollError::ExpiredToken.http_status());
println!("http_status/InvalidDeviceCode\t{:?}",DevicePollError::InvalidDeviceCode.http_status());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(DevicePollError::AuthorizationPending.error_code().as_bytes(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::AuthorizationPending.error_code(),"device_poll_error_1fb5547a/error_code/AuthorizationPending");
assert_eq!(DevicePollError::SlowDown.error_code().as_bytes(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::SlowDown.error_code(),"device_poll_error_1fb5547a/error_code/SlowDown");
assert_eq!(DevicePollError::AccessDenied.error_code().as_bytes(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::AccessDenied.error_code(),"device_poll_error_1fb5547a/error_code/AccessDenied");
assert_eq!(DevicePollError::ExpiredToken.error_code().as_bytes(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::ExpiredToken.error_code(),"device_poll_error_1fb5547a/error_code/ExpiredToken");
assert_eq!(DevicePollError::InvalidDeviceCode.error_code().as_bytes(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::InvalidDeviceCode.error_code(),"device_poll_error_1fb5547a/error_code/InvalidDeviceCode");
assert_eq!(DevicePollError::AuthorizationPending.description().as_bytes(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::AuthorizationPending.description(),"device_poll_error_1fb5547a/description/AuthorizationPending");
assert_eq!(DevicePollError::SlowDown.description().as_bytes(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::SlowDown.description(),"device_poll_error_1fb5547a/description/SlowDown");
assert_eq!(DevicePollError::AccessDenied.description().as_bytes(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::AccessDenied.description(),"device_poll_error_1fb5547a/description/AccessDenied");
assert_eq!(DevicePollError::ExpiredToken.description().as_bytes(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::ExpiredToken.description(),"device_poll_error_1fb5547a/description/ExpiredToken");
assert_eq!(DevicePollError::InvalidDeviceCode.description().as_bytes(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::InvalidDeviceCode.description(),"device_poll_error_1fb5547a/description/InvalidDeviceCode");
assert_eq!(DevicePollError::AuthorizationPending.http_status(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::AuthorizationPending.http_status(),"device_poll_error_1fb5547a/http_status/AuthorizationPending");
assert_eq!(DevicePollError::SlowDown.http_status(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::SlowDown.http_status(),"device_poll_error_1fb5547a/http_status/SlowDown");
assert_eq!(DevicePollError::AccessDenied.http_status(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::AccessDenied.http_status(),"device_poll_error_1fb5547a/http_status/AccessDenied");
assert_eq!(DevicePollError::ExpiredToken.http_status(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::ExpiredToken.http_status(),"device_poll_error_1fb5547a/http_status/ExpiredToken");
assert_eq!(DevicePollError::InvalidDeviceCode.http_status(),oxicloud_kernel::finite_catalog::device_poll_error_1fb5547a::DevicePollError::InvalidDeviceCode.http_status(),"device_poll_error_1fb5547a/http_status/InvalidDeviceCode");
}
