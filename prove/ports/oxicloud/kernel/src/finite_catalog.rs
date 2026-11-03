//! Exhaustive finite enum decisions; see DEVIATIONS.md.
pub mod authz_denial_visibility_4079d78e {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AuthzDenialVisibility {Visible,Hidden}
impl AuthzDenialVisibility {
    pub fn as_str(self) -> Vec<u8> {
        match self {
            Self::Visible => Vec::from([118u8, 105u8, 115u8, 105u8, 98u8, 108u8, 101u8]),
            Self::Hidden => Vec::from([104u8, 105u8, 100u8, 100u8, 101u8, 110u8]),
        }
    }
}
}
pub mod ref_level_2ec664a4 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum RefLevel {Chunk,Manifest}
impl RefLevel {
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            RefLevel::Chunk => Vec::from([99u8, 104u8, 117u8, 110u8, 107u8]),
            RefLevel::Manifest => Vec::from([109u8, 97u8, 110u8, 105u8, 102u8, 101u8, 115u8, 116u8]),
        }
    }
}
}
pub mod checksum_alg_cf7683cd {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ChecksumAlg {Md5,Sha256,Blake3}
impl ChecksumAlg {
    pub fn as_str(self) -> Vec<u8> {
        match self {
            Self::Md5 => Vec::from([109u8, 100u8, 53u8]),
            Self::Sha256 => Vec::from([115u8, 104u8, 97u8, 50u8, 53u8, 54u8]),
            Self::Blake3 => Vec::from([98u8, 108u8, 97u8, 107u8, 101u8, 51u8]),
        }
    }
}
}
pub mod thumbnail_size_e90c1659 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ThumbnailSize {Icon,Preview,Large}
impl ThumbnailSize {
    
    
    
    
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            ThumbnailSize::Icon => Vec::from([73u8, 99u8, 111u8, 110u8]),
            ThumbnailSize::Preview => Vec::from([80u8, 114u8, 101u8, 118u8, 105u8, 101u8, 119u8]),
            ThumbnailSize::Large => Vec::from([76u8, 97u8, 114u8, 103u8, 101u8]),
        }
    }
    
    pub fn max_dimension(&self) -> u32 {
        match self {
            ThumbnailSize::Icon => 150,
            ThumbnailSize::Preview => 400,
            ThumbnailSize::Large => 800,
        }
    }
    
    pub fn dir_name(&self) -> Vec<u8> {
        match self {
            ThumbnailSize::Icon => Vec::from([105u8, 99u8, 111u8, 110u8]),
            ThumbnailSize::Preview => Vec::from([112u8, 114u8, 101u8, 118u8, 105u8, 101u8, 119u8]),
            ThumbnailSize::Large => Vec::from([108u8, 97u8, 114u8, 103u8, 101u8]),
        }
    }
}
}
pub mod thumbnail_format_e90c1659 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ThumbnailFormat {Webp,Jpeg}
impl ThumbnailFormat {
    
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            ThumbnailFormat::Webp => Vec::from([87u8, 101u8, 98u8, 112u8]),
            ThumbnailFormat::Jpeg => Vec::from([74u8, 112u8, 101u8, 103u8]),
        }
    }
    
    pub fn ext(self) -> Vec<u8> {
        match self {
            ThumbnailFormat::Webp => Vec::from([119u8, 101u8, 98u8, 112u8]),
            ThumbnailFormat::Jpeg => Vec::from([106u8, 112u8, 103u8]),
        }
    }
    
    
    
    
    
    pub fn mime(self) -> Vec<u8> {
        match self {
            ThumbnailFormat::Webp => Vec::from([105u8, 109u8, 97u8, 103u8, 101u8, 47u8, 119u8, 101u8, 98u8, 112u8]),
            ThumbnailFormat::Jpeg => Vec::from([105u8, 109u8, 97u8, 103u8, 101u8, 47u8, 106u8, 112u8, 101u8, 103u8]),
        }
    }
}
}
pub mod output_format_f1a5ab73 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OutputFormat {WebP}
impl OutputFormat {
    
    pub fn extension(&self) -> Vec<u8> {
        match self {
            OutputFormat::WebP => Vec::from([119u8, 101u8, 98u8, 112u8]),
        }
    }
    
    pub fn mime_type(&self) -> Vec<u8> {
        match self {
            OutputFormat::WebP => Vec::from([105u8, 109u8, 97u8, 103u8, 101u8, 47u8, 119u8, 101u8, 98u8, 112u8]),
        }
    }
}
}
pub mod device_poll_error_1fb5547a {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum DevicePollError {AuthorizationPending,SlowDown,AccessDenied,ExpiredToken,InvalidDeviceCode}
impl DevicePollError {
    
    pub fn error_code(&self) -> Vec<u8> {
        match self {
            Self::AuthorizationPending => Vec::from([97u8, 117u8, 116u8, 104u8, 111u8, 114u8, 105u8, 122u8, 97u8, 116u8, 105u8, 111u8, 110u8, 95u8, 112u8, 101u8, 110u8, 100u8, 105u8, 110u8, 103u8]),
            Self::SlowDown => Vec::from([115u8, 108u8, 111u8, 119u8, 95u8, 100u8, 111u8, 119u8, 110u8]),
            Self::AccessDenied => Vec::from([97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 100u8, 101u8, 110u8, 105u8, 101u8, 100u8]),
            Self::ExpiredToken => Vec::from([101u8, 120u8, 112u8, 105u8, 114u8, 101u8, 100u8, 95u8, 116u8, 111u8, 107u8, 101u8, 110u8]),
            Self::InvalidDeviceCode => Vec::from([105u8, 110u8, 118u8, 97u8, 108u8, 105u8, 100u8, 95u8, 103u8, 114u8, 97u8, 110u8, 116u8]),
        }
    }
    pub fn description(&self) -> Vec<u8> {
        match self {
            Self::AuthorizationPending => {
                Vec::from([84u8, 104u8, 101u8, 32u8, 97u8, 117u8, 116u8, 104u8, 111u8, 114u8, 105u8, 122u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 114u8, 101u8, 113u8, 117u8, 101u8, 115u8, 116u8, 32u8, 105u8, 115u8, 32u8, 115u8, 116u8, 105u8, 108u8, 108u8, 32u8, 112u8, 101u8, 110u8, 100u8, 105u8, 110u8, 103u8, 46u8, 32u8, 67u8, 111u8, 110u8, 116u8, 105u8, 110u8, 117u8, 101u8, 32u8, 112u8, 111u8, 108u8, 108u8, 105u8, 110u8, 103u8, 46u8])
            }
            Self::SlowDown => Vec::from([89u8, 111u8, 117u8, 32u8, 97u8, 114u8, 101u8, 32u8, 112u8, 111u8, 108u8, 108u8, 105u8, 110u8, 103u8, 32u8, 116u8, 111u8, 111u8, 32u8, 102u8, 114u8, 101u8, 113u8, 117u8, 101u8, 110u8, 116u8, 108u8, 121u8, 46u8, 32u8, 80u8, 108u8, 101u8, 97u8, 115u8, 101u8, 32u8, 115u8, 108u8, 111u8, 119u8, 32u8, 100u8, 111u8, 119u8, 110u8, 46u8]),
            Self::AccessDenied => Vec::from([84u8, 104u8, 101u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 100u8, 101u8, 110u8, 105u8, 101u8, 100u8, 32u8, 116u8, 104u8, 101u8, 32u8, 97u8, 117u8, 116u8, 104u8, 111u8, 114u8, 105u8, 122u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 114u8, 101u8, 113u8, 117u8, 101u8, 115u8, 116u8, 46u8]),
            Self::ExpiredToken => {
                Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 101u8, 118u8, 105u8, 99u8, 101u8, 95u8, 99u8, 111u8, 100u8, 101u8, 32u8, 104u8, 97u8, 115u8, 32u8, 101u8, 120u8, 112u8, 105u8, 114u8, 101u8, 100u8, 46u8, 32u8, 80u8, 108u8, 101u8, 97u8, 115u8, 101u8, 32u8, 115u8, 116u8, 97u8, 114u8, 116u8, 32u8, 97u8, 32u8, 110u8, 101u8, 119u8, 32u8, 97u8, 117u8, 116u8, 104u8, 111u8, 114u8, 105u8, 122u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 102u8, 108u8, 111u8, 119u8, 46u8])
            }
            Self::InvalidDeviceCode => Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 101u8, 118u8, 105u8, 99u8, 101u8, 95u8, 99u8, 111u8, 100u8, 101u8, 32u8, 105u8, 115u8, 32u8, 110u8, 111u8, 116u8, 32u8, 114u8, 101u8, 99u8, 111u8, 103u8, 110u8, 105u8, 122u8, 101u8, 100u8, 46u8]),
        }
    }
    
    
    
    
    pub fn http_status(&self) -> u16 {
        match self {
            Self::AuthorizationPending | Self::SlowDown | Self::ExpiredToken => 400,
            Self::AccessDenied => 403,
            Self::InvalidDeviceCode => 400,
        }
    }
}
}
pub mod notify_trigger_5dfe5802 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum NotifyTrigger {GrantCreated,ManualResend}
impl NotifyTrigger {
    pub fn audit_str(self) -> Vec<u8> {
        match self {
            NotifyTrigger::GrantCreated => Vec::from([103u8, 114u8, 97u8, 110u8, 116u8, 95u8, 99u8, 114u8, 101u8, 97u8, 116u8, 101u8, 100u8]),
            NotifyTrigger::ManualResend => Vec::from([109u8, 97u8, 110u8, 117u8, 97u8, 108u8, 95u8, 114u8, 101u8, 115u8, 101u8, 110u8, 100u8]),
        }
    }
}
}
pub mod notify_kind_5dfe5802 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum NotifyKind {MagicLink,PlainNotification}
impl NotifyKind {
    pub fn audit_str(self) -> Vec<u8> {
        match self {
            NotifyKind::MagicLink => Vec::from([109u8, 97u8, 103u8, 105u8, 99u8, 95u8, 108u8, 105u8, 110u8, 107u8]),
            NotifyKind::PlainNotification => Vec::from([112u8, 108u8, 97u8, 105u8, 110u8, 95u8, 110u8, 111u8, 116u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
        }
    }
}
}
pub mod cipher_kind_a4fe67b2 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum CipherKind {AesGcm256,None}
impl CipherKind {
    
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            CipherKind::AesGcm256 => Vec::from([97u8, 101u8, 115u8, 45u8, 50u8, 53u8, 54u8, 45u8, 103u8, 99u8, 109u8]),
            CipherKind::None => Vec::from([110u8, 111u8, 110u8, 101u8]),
        }
    }
    
    
    
    
    pub fn needs_key(self) -> bool {
        matches!(self, CipherKind::AesGcm256)
    }
}
}
pub mod device_code_status_fb933849 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum DeviceCodeStatus {Pending,Authorized,Denied,Expired}
impl DeviceCodeStatus {
    pub fn as_str(&self) -> Vec<u8> {
        match self {
            Self::Pending => Vec::from([112u8, 101u8, 110u8, 100u8, 105u8, 110u8, 103u8]),
            Self::Authorized => Vec::from([97u8, 117u8, 116u8, 104u8, 111u8, 114u8, 105u8, 122u8, 101u8, 100u8]),
            Self::Denied => Vec::from([100u8, 101u8, 110u8, 105u8, 101u8, 100u8]),
            Self::Expired => Vec::from([101u8, 120u8, 112u8, 105u8, 114u8, 101u8, 100u8]),
        }
    }
}
}
pub mod drive_kind_bf867fda {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum DriveKind {Personal,Shared}
impl DriveKind {
    pub fn as_str(self) -> Vec<u8> {
        match self {
            DriveKind::Personal => Vec::from([112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 97u8, 108u8]),
            DriveKind::Shared => Vec::from([115u8, 104u8, 97u8, 114u8, 101u8, 100u8]),
        }
    }
}
}
pub mod magic_link_status_023c994e {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum MagicLinkStatus {Pending,Used,Expired}
impl MagicLinkStatus {
    pub fn as_str(&self) -> Vec<u8> {
        match self {
            Self::Pending => Vec::from([112u8, 101u8, 110u8, 100u8, 105u8, 110u8, 103u8]),
            Self::Used => Vec::from([117u8, 115u8, 101u8, 100u8]),
            Self::Expired => Vec::from([101u8, 120u8, 112u8, 105u8, 114u8, 101u8, 100u8]),
        }
    }
}
}
pub mod session_origin_086d7c6c {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum SessionOrigin {Password,Opaque,MagicLink,Oidc,Device,Unknown}
impl SessionOrigin {
    
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            Self::Password => Vec::from([112u8, 97u8, 115u8, 115u8, 119u8, 111u8, 114u8, 100u8]),
            Self::Opaque => Vec::from([111u8, 112u8, 97u8, 113u8, 117u8, 101u8]),
            Self::MagicLink => Vec::from([109u8, 97u8, 103u8, 105u8, 99u8, 95u8, 108u8, 105u8, 110u8, 107u8]),
            Self::Oidc => Vec::from([111u8, 105u8, 100u8, 99u8]),
            Self::Device => Vec::from([100u8, 101u8, 118u8, 105u8, 99u8, 101u8]),
            Self::Unknown => Vec::from([117u8, 110u8, 107u8, 110u8, 111u8, 119u8, 110u8]),
        }
    }
}
}
pub mod user_role_d47f77bc {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum UserRole {Owner,Admin,User,Anonymous}
impl UserRole {
    
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            UserRole::Owner => Vec::from([111u8, 119u8, 110u8, 101u8, 114u8]),
            UserRole::Admin => Vec::from([97u8, 100u8, 109u8, 105u8, 110u8]),
            UserRole::User => Vec::from([117u8, 115u8, 101u8, 114u8]),
            UserRole::Anonymous => Vec::from([97u8, 110u8, 111u8, 110u8, 121u8, 109u8, 111u8, 117u8, 115u8]),
        }
    }
    
    
    
    
    
    
    
    
    
    pub fn rank(self) -> u8 {
        match self {
            UserRole::Anonymous => 0,
            UserRole::User => 1,
            UserRole::Admin => 2,
            UserRole::Owner => 3,
        }
    }
    
    pub fn is_anonymous(self) -> bool {
        matches!(self, UserRole::Anonymous)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    pub fn is_privileged(self) -> bool {
        self.rank() > UserRole::User.rank()
    }
}
}
pub mod federation_kind_d47f77bc {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum FederationKind {MagicLink,Ocm,Oidc}
impl FederationKind {
    
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            FederationKind::MagicLink => Vec::from([109u8, 97u8, 103u8, 105u8, 99u8, 95u8, 108u8, 105u8, 110u8, 107u8]),
            FederationKind::Ocm => Vec::from([111u8, 99u8, 109u8]),
            FederationKind::Oidc => Vec::from([111u8, 105u8, 100u8, 99u8]),
        }
    }
}
}
pub mod error_kind_59712eff {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ErrorKind {NotFound,AlreadyExists,InvalidInput,AccessDenied,Timeout,TransientBackend,InternalError,NotImplemented,UnsupportedOperation,DatabaseError,QuotaExceeded,Conflict,PreconditionFailed}
impl ErrorKind {
    
    
    
    pub fn as_str(&self) -> Vec<u8> {
        match self {
            ErrorKind::NotFound => Vec::from([78u8, 111u8, 116u8, 32u8, 70u8, 111u8, 117u8, 110u8, 100u8]),
            ErrorKind::AlreadyExists => Vec::from([65u8, 108u8, 114u8, 101u8, 97u8, 100u8, 121u8, 32u8, 69u8, 120u8, 105u8, 115u8, 116u8, 115u8]),
            ErrorKind::InvalidInput => Vec::from([73u8, 110u8, 118u8, 97u8, 108u8, 105u8, 100u8, 32u8, 73u8, 110u8, 112u8, 117u8, 116u8]),
            ErrorKind::AccessDenied => Vec::from([65u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 68u8, 101u8, 110u8, 105u8, 101u8, 100u8]),
            ErrorKind::Timeout => Vec::from([84u8, 105u8, 109u8, 101u8, 111u8, 117u8, 116u8]),
            
            
            
            ErrorKind::TransientBackend => Vec::from([84u8, 114u8, 97u8, 110u8, 115u8, 105u8, 101u8, 110u8, 116u8, 32u8, 66u8, 97u8, 99u8, 107u8, 101u8, 110u8, 100u8]),
            ErrorKind::InternalError => Vec::from([73u8, 110u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 69u8, 114u8, 114u8, 111u8, 114u8]),
            ErrorKind::NotImplemented => Vec::from([78u8, 111u8, 116u8, 32u8, 73u8, 109u8, 112u8, 108u8, 101u8, 109u8, 101u8, 110u8, 116u8, 101u8, 100u8]),
            ErrorKind::UnsupportedOperation => Vec::from([85u8, 110u8, 115u8, 117u8, 112u8, 112u8, 111u8, 114u8, 116u8, 101u8, 100u8, 32u8, 79u8, 112u8, 101u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
            ErrorKind::DatabaseError => Vec::from([68u8, 97u8, 116u8, 97u8, 98u8, 97u8, 115u8, 101u8, 32u8, 69u8, 114u8, 114u8, 111u8, 114u8]),
            ErrorKind::QuotaExceeded => Vec::from([81u8, 117u8, 111u8, 116u8, 97u8, 32u8, 69u8, 120u8, 99u8, 101u8, 101u8, 100u8, 101u8, 100u8]),
            ErrorKind::Conflict => Vec::from([67u8, 111u8, 110u8, 102u8, 108u8, 105u8, 99u8, 116u8]),
            ErrorKind::PreconditionFailed => Vec::from([80u8, 114u8, 101u8, 99u8, 111u8, 110u8, 100u8, 105u8, 116u8, 105u8, 111u8, 110u8, 32u8, 70u8, 97u8, 105u8, 108u8, 101u8, 100u8]),
        }
    }
}
}
pub mod permission_5d9dca62 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Permission {Read,Create,Share,Comment,Delete,Update,Manage}
impl Permission {
    pub fn as_str(&self) -> Vec<u8> {
        match self {
            Permission::Read => Vec::from([114u8, 101u8, 97u8, 100u8]),
            Permission::Create => Vec::from([99u8, 114u8, 101u8, 97u8, 116u8, 101u8]),
            Permission::Share => Vec::from([115u8, 104u8, 97u8, 114u8, 101u8]),
            Permission::Comment => Vec::from([99u8, 111u8, 109u8, 109u8, 101u8, 110u8, 116u8]),
            Permission::Delete => Vec::from([100u8, 101u8, 108u8, 101u8, 116u8, 101u8]),
            Permission::Update => Vec::from([117u8, 112u8, 100u8, 97u8, 116u8, 101u8]),
            Permission::Manage => Vec::from([109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
        }
    }
}
}
pub mod role_5d9dca62 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Role {Viewer,Commenter,Contributor,Editor,Owner}
impl Role {
    
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            Role::Viewer => Vec::from([118u8, 105u8, 101u8, 119u8, 101u8, 114u8]),
            Role::Commenter => Vec::from([99u8, 111u8, 109u8, 109u8, 101u8, 110u8, 116u8, 101u8, 114u8]),
            Role::Contributor => Vec::from([99u8, 111u8, 110u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 111u8, 114u8]),
            Role::Editor => Vec::from([101u8, 100u8, 105u8, 116u8, 111u8, 114u8]),
            Role::Owner => Vec::from([111u8, 119u8, 110u8, 101u8, 114u8]),
        }
    }
}
}
pub mod run_status_dbd87cc3 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum RunStatus {Running,Paused,CancelRequested,Completed,Failed,Cancelled}
impl RunStatus {
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            RunStatus::Running => Vec::from([82u8, 117u8, 110u8, 110u8, 105u8, 110u8, 103u8]),
            RunStatus::Paused => Vec::from([80u8, 97u8, 117u8, 115u8, 101u8, 100u8]),
            RunStatus::CancelRequested => Vec::from([67u8, 97u8, 110u8, 99u8, 101u8, 108u8, 82u8, 101u8, 113u8, 117u8, 101u8, 115u8, 116u8, 101u8, 100u8]),
            RunStatus::Completed => Vec::from([67u8, 111u8, 109u8, 112u8, 108u8, 101u8, 116u8, 101u8, 100u8]),
            RunStatus::Failed => Vec::from([70u8, 97u8, 105u8, 108u8, 101u8, 100u8]),
            RunStatus::Cancelled => Vec::from([67u8, 97u8, 110u8, 99u8, 101u8, 108u8, 108u8, 101u8, 100u8]),
        }
    }
    
    
    pub fn is_non_terminal(self) -> bool {
        matches!(
            self,
            RunStatus::Running | RunStatus::Paused | RunStatus::CancelRequested
        )
    }
}
}
pub mod progress_kind_dbd87cc3 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ProgressKind {Count,Approximate}
impl ProgressKind {
    pub fn as_str(self) -> Vec<u8> {
        match self {
            ProgressKind::Count => Vec::from([99u8, 111u8, 117u8, 110u8, 116u8]),
            ProgressKind::Approximate => Vec::from([97u8, 112u8, 112u8, 114u8, 111u8, 120u8, 105u8, 109u8, 97u8, 116u8, 101u8]),
        }
    }
}
}
pub mod err_cause_75575f17 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ErrCause {Handler,Timeout,Panicked}
impl ErrCause {
    
    
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            ErrCause::Handler => Vec::from([104u8, 97u8, 110u8, 100u8, 108u8, 101u8, 114u8]),
            ErrCause::Timeout => Vec::from([116u8, 105u8, 109u8, 101u8, 111u8, 117u8, 116u8]),
            ErrCause::Panicked => Vec::from([112u8, 97u8, 110u8, 105u8, 99u8, 107u8, 101u8, 100u8]),
        }
    }
}
}
pub mod dpop_verify_error_8219bbef {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum DpopVerifyError {Malformed,WrongTyp,WrongAlg,WrongJwk,SignatureInvalid,WrongHtm,WrongHtu,IatMissing,IatOutOfWindow,JtiMissing,JktMismatch}
impl DpopVerifyError {
    
    pub fn reason(&self) -> Vec<u8> {
        match self {
            Self::Malformed => Vec::from([109u8, 97u8, 108u8, 102u8, 111u8, 114u8, 109u8, 101u8, 100u8, 95u8, 106u8, 119u8, 115u8]),
            Self::WrongTyp => Vec::from([119u8, 114u8, 111u8, 110u8, 103u8, 95u8, 116u8, 121u8, 112u8]),
            Self::WrongAlg => Vec::from([119u8, 114u8, 111u8, 110u8, 103u8, 95u8, 97u8, 108u8, 103u8]),
            Self::WrongJwk => Vec::from([119u8, 114u8, 111u8, 110u8, 103u8, 95u8, 106u8, 119u8, 107u8]),
            Self::SignatureInvalid => Vec::from([115u8, 105u8, 103u8, 110u8, 97u8, 116u8, 117u8, 114u8, 101u8, 95u8, 105u8, 110u8, 118u8, 97u8, 108u8, 105u8, 100u8]),
            Self::WrongHtm => Vec::from([119u8, 114u8, 111u8, 110u8, 103u8, 95u8, 104u8, 116u8, 109u8]),
            Self::WrongHtu => Vec::from([119u8, 114u8, 111u8, 110u8, 103u8, 95u8, 104u8, 116u8, 117u8]),
            Self::IatMissing => Vec::from([105u8, 97u8, 116u8, 95u8, 109u8, 105u8, 115u8, 115u8, 105u8, 110u8, 103u8]),
            Self::IatOutOfWindow => Vec::from([105u8, 97u8, 116u8, 95u8, 111u8, 117u8, 116u8, 95u8, 111u8, 102u8, 95u8, 119u8, 105u8, 110u8, 100u8, 111u8, 119u8]),
            Self::JtiMissing => Vec::from([106u8, 116u8, 105u8, 95u8, 109u8, 105u8, 115u8, 115u8, 105u8, 110u8, 103u8]),
            Self::JktMismatch => Vec::from([106u8, 107u8, 116u8, 95u8, 109u8, 105u8, 115u8, 109u8, 97u8, 116u8, 99u8, 104u8]),
        }
    }
}
}
pub mod output_format_a83b795c {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OutputFormat {WebP}
impl OutputFormat {
    pub fn extension(&self) -> Vec<u8> {
        match self {
            OutputFormat::WebP => Vec::from([119u8, 101u8, 98u8, 112u8]),
        }
    }
    pub fn mime_type(&self) -> Vec<u8> {
        match self {
            OutputFormat::WebP => Vec::from([105u8, 109u8, 97u8, 103u8, 101u8, 47u8, 119u8, 101u8, 98u8, 112u8]),
        }
    }
}
}
pub mod opaque_mode_b0957357 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OpaqueMode {Off,Migrate,OpaqueOnly}
impl OpaqueMode {
    
    
    
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            Self::Off => Vec::from([111u8, 102u8, 102u8]),
            Self::Migrate => Vec::from([109u8, 105u8, 103u8, 114u8, 97u8, 116u8, 101u8]),
            Self::OpaqueOnly => Vec::from([111u8, 112u8, 97u8, 113u8, 117u8, 101u8, 95u8, 111u8, 110u8, 108u8, 121u8]),
        }
    }
}
}
pub mod phase_ce65bf5b {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Phase {Derived,Attached}
impl Phase {
    pub fn as_str(self) -> Vec<u8> {
        match self {
            Phase::Derived => Vec::from([100u8, 101u8, 114u8, 105u8, 118u8, 101u8, 100u8]),
            Phase::Attached => Vec::from([97u8, 116u8, 116u8, 97u8, 99u8, 104u8, 101u8, 100u8]),
        }
    }
}
}
pub mod thumbnail_size_4088a69a {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ThumbnailSize {Icon,Preview,Large}
impl ThumbnailSize {
    
    pub fn max_dimension(&self) -> u32 {
        match self {
            ThumbnailSize::Icon => 150,
            ThumbnailSize::Preview => 400,
            ThumbnailSize::Large => 800,
        }
    }
    
    pub fn dir_name(&self) -> Vec<u8> {
        match self {
            ThumbnailSize::Icon => Vec::from([105u8, 99u8, 111u8, 110u8]),
            ThumbnailSize::Preview => Vec::from([112u8, 114u8, 101u8, 118u8, 105u8, 101u8, 119u8]),
            ThumbnailSize::Large => Vec::from([108u8, 97u8, 114u8, 103u8, 101u8]),
        }
    }
}
}
