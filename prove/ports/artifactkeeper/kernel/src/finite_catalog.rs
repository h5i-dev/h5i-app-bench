//! Exhaustive finite enum decisions; see DEVIATIONS.md.
pub mod repodata_encoding_df7b79f6 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum RepodataEncoding {Json,Bz2,Zst}
impl RepodataEncoding {
    pub fn content_type(&self) -> Vec<u8> {
        match self {
            Self::Json => Vec::from([97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 47u8, 106u8, 115u8, 111u8, 110u8]),
            Self::Bz2 => Vec::from([97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 47u8, 120u8, 45u8, 98u8, 122u8, 105u8, 112u8, 50u8]),
            Self::Zst => Vec::from([97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 47u8, 122u8, 115u8, 116u8, 100u8]),
        }
    }
    pub fn upstream_filename(&self) -> Vec<u8> {
        match self {
            Self::Json => Vec::from([114u8, 101u8, 112u8, 111u8, 100u8, 97u8, 116u8, 97u8, 46u8, 106u8, 115u8, 111u8, 110u8]),
            Self::Bz2 => Vec::from([114u8, 101u8, 112u8, 111u8, 100u8, 97u8, 116u8, 97u8, 46u8, 106u8, 115u8, 111u8, 110u8, 46u8, 98u8, 122u8, 50u8]),
            Self::Zst => Vec::from([114u8, 101u8, 112u8, 111u8, 100u8, 97u8, 116u8, 97u8, 46u8, 106u8, 115u8, 111u8, 110u8, 46u8, 122u8, 115u8, 116u8]),
        }
    }
}
}
pub mod signed_release_variant_007f0cf5 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum SignedReleaseVariant {InRelease,ReleaseGpg}
impl SignedReleaseVariant {
    pub fn as_str(self) -> Vec<u8> {
        match self {
            SignedReleaseVariant::InRelease => Vec::from([73u8, 110u8, 82u8, 101u8, 108u8, 101u8, 97u8, 115u8, 101u8]),
            SignedReleaseVariant::ReleaseGpg => Vec::from([82u8, 101u8, 108u8, 101u8, 97u8, 115u8, 101u8, 46u8, 103u8, 112u8, 103u8]),
        }
    }
}
}
pub mod upload_session_state_a43ea4df {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum UploadSessionState {Open,Committing}
impl UploadSessionState {
    pub fn as_str(self) -> Vec<u8> {
        match self {
            UploadSessionState::Open => Vec::from([111u8, 112u8, 101u8, 110u8]),
            UploadSessionState::Committing => Vec::from([99u8, 111u8, 109u8, 109u8, 105u8, 116u8, 116u8, 105u8, 110u8, 103u8]),
        }
    }
}
}
pub mod cached_object_verdict_b87a78e2 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum CachedObjectVerdict {NotProxyCache,Vouched,Unvouched,Held}
impl CachedObjectVerdict {
    pub fn may_serve_stored_object(self) -> bool {
        matches!(self, Self::NotProxyCache | Self::Vouched)
    }
}
}
pub mod outbound_url_context_dd3b7559 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OutboundUrlContext {Upstream,Webhook,SsoDiscovery,TrustedInternal}
impl OutboundUrlContext {
    
    
    pub fn env_var(self) -> Vec<u8> {
        match self {
            OutboundUrlContext::Upstream => Vec::from([85u8, 80u8, 83u8, 84u8, 82u8, 69u8, 65u8, 77u8, 95u8, 65u8, 76u8, 76u8, 79u8, 87u8, 95u8, 80u8, 82u8, 73u8, 86u8, 65u8, 84u8, 69u8, 95u8, 73u8, 80u8, 83u8]),
            OutboundUrlContext::Webhook => Vec::from([87u8, 69u8, 66u8, 72u8, 79u8, 79u8, 75u8, 95u8, 65u8, 76u8, 76u8, 79u8, 87u8, 95u8, 80u8, 82u8, 73u8, 86u8, 65u8, 84u8, 69u8, 95u8, 73u8, 80u8, 83u8]),
            OutboundUrlContext::SsoDiscovery => Vec::from([83u8, 83u8, 79u8, 95u8, 65u8, 76u8, 76u8, 79u8, 87u8, 95u8, 80u8, 82u8, 73u8, 86u8, 65u8, 84u8, 69u8, 95u8, 73u8, 80u8, 83u8]),
            
            
            
            
            
            OutboundUrlContext::TrustedInternal => Vec::from([65u8, 75u8, 95u8, 84u8, 82u8, 85u8, 83u8, 84u8, 69u8, 68u8, 95u8, 73u8, 78u8, 84u8, 69u8, 82u8, 78u8, 65u8, 76u8, 95u8, 65u8, 76u8, 76u8, 79u8, 87u8, 95u8, 80u8, 82u8, 73u8, 86u8, 65u8, 84u8, 69u8, 95u8, 73u8, 80u8, 83u8]),
        }
    }
}
}
pub mod jwt_secret_warning_4946346a {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum JwtSecretWarning {TooShort,KnownPlaceholder,LowEntropy}
impl JwtSecretWarning {
    pub fn message(self) -> Vec<u8> {
        match self {
            JwtSecretWarning::TooShort => Vec::from([105u8, 116u8, 32u8, 105u8, 115u8, 32u8, 115u8, 104u8, 111u8, 114u8, 116u8, 101u8, 114u8, 32u8, 116u8, 104u8, 97u8, 110u8, 32u8, 51u8, 50u8, 32u8, 99u8, 104u8, 97u8, 114u8, 97u8, 99u8, 116u8, 101u8, 114u8, 115u8, 46u8]),
            JwtSecretWarning::KnownPlaceholder => Vec::from([105u8, 116u8, 32u8, 105u8, 115u8, 32u8, 97u8, 32u8, 107u8, 110u8, 111u8, 119u8, 110u8, 32u8, 112u8, 108u8, 97u8, 99u8, 101u8, 104u8, 111u8, 108u8, 100u8, 101u8, 114u8, 47u8, 100u8, 101u8, 102u8, 97u8, 117u8, 108u8, 116u8, 32u8, 118u8, 97u8, 108u8, 117u8, 101u8, 46u8]),
            JwtSecretWarning::LowEntropy => {
                Vec::from([105u8, 116u8, 32u8, 104u8, 97u8, 115u8, 32u8, 108u8, 111u8, 119u8, 32u8, 101u8, 110u8, 116u8, 114u8, 111u8, 112u8, 121u8, 32u8, 40u8, 117u8, 110u8, 100u8, 101u8, 114u8, 32u8, 49u8, 50u8, 56u8, 32u8, 101u8, 115u8, 116u8, 105u8, 109u8, 97u8, 116u8, 101u8, 100u8, 32u8, 98u8, 105u8, 116u8, 115u8, 44u8, 32u8, 111u8, 114u8, 32u8, 97u8, 110u8, 32u8, 111u8, 98u8, 118u8, 105u8, 111u8, 117u8, 115u8, 32u8, 114u8, 101u8, 112u8, 101u8, 97u8, 116u8, 32u8, 111u8, 114u8, 32u8, 115u8, 101u8, 113u8, 117u8, 101u8, 110u8, 99u8, 101u8, 41u8, 46u8])
            }
        }
    }
}
}
pub mod incus_file_type_eee7eb85 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum IncusFileType {UnifiedTarball,MetadataTarball,RootfsSquashfs,RootfsQcow2,StreamsIndex}
impl IncusFileType {
    pub fn as_str(&self) -> Vec<u8> {
        match self {
            Self::UnifiedTarball => Vec::from([117u8, 110u8, 105u8, 102u8, 105u8, 101u8, 100u8, 95u8, 116u8, 97u8, 114u8, 98u8, 97u8, 108u8, 108u8]),
            Self::MetadataTarball => Vec::from([109u8, 101u8, 116u8, 97u8, 100u8, 97u8, 116u8, 97u8, 95u8, 116u8, 97u8, 114u8, 98u8, 97u8, 108u8, 108u8]),
            Self::RootfsSquashfs => Vec::from([114u8, 111u8, 111u8, 116u8, 102u8, 115u8, 95u8, 115u8, 113u8, 117u8, 97u8, 115u8, 104u8, 102u8, 115u8]),
            Self::RootfsQcow2 => Vec::from([114u8, 111u8, 111u8, 116u8, 102u8, 115u8, 95u8, 113u8, 99u8, 111u8, 119u8, 50u8]),
            Self::StreamsIndex => Vec::from([115u8, 116u8, 114u8, 101u8, 97u8, 109u8, 115u8, 95u8, 105u8, 110u8, 100u8, 101u8, 120u8]),
        }
    }
    pub fn is_tarball(&self) -> bool {
        matches!(self, Self::UnifiedTarball | Self::MetadataTarball)
    }
}
}
pub mod sbom_format_104be95e {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum SbomFormat {CycloneDX,SPDX}
impl SbomFormat {
    pub fn as_str(&self) -> Vec<u8> {
        match self {
            SbomFormat::CycloneDX => Vec::from([99u8, 121u8, 99u8, 108u8, 111u8, 110u8, 101u8, 100u8, 120u8]),
            SbomFormat::SPDX => Vec::from([115u8, 112u8, 100u8, 120u8]),
        }
    }
    pub fn content_type(&self) -> Vec<u8> {
        match self {
            SbomFormat::CycloneDX => Vec::from([97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 47u8, 118u8, 110u8, 100u8, 46u8, 99u8, 121u8, 99u8, 108u8, 111u8, 110u8, 101u8, 100u8, 120u8, 43u8, 106u8, 115u8, 111u8, 110u8]),
            SbomFormat::SPDX => Vec::from([97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 47u8, 115u8, 112u8, 100u8, 120u8, 43u8, 106u8, 115u8, 111u8, 110u8]),
        }
    }
}
}
pub mod cve_status_104be95e {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum CveStatus {Open,Fixed,Acknowledged,FalsePositive}
impl CveStatus {
    pub fn as_str(&self) -> Vec<u8> {
        match self {
            CveStatus::Open => Vec::from([111u8, 112u8, 101u8, 110u8]),
            CveStatus::Fixed => Vec::from([102u8, 105u8, 120u8, 101u8, 100u8]),
            CveStatus::Acknowledged => Vec::from([97u8, 99u8, 107u8, 110u8, 111u8, 119u8, 108u8, 101u8, 100u8, 103u8, 101u8, 100u8]),
            CveStatus::FalsePositive => Vec::from([102u8, 97u8, 108u8, 115u8, 101u8, 95u8, 112u8, 111u8, 115u8, 105u8, 116u8, 105u8, 118u8, 101u8]),
        }
    }
}
}
pub mod policy_action_104be95e {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum PolicyAction {Allow,Warn,Block}
impl PolicyAction {
    pub fn as_str(&self) -> Vec<u8> {
        match self {
            PolicyAction::Allow => Vec::from([97u8, 108u8, 108u8, 111u8, 119u8]),
            PolicyAction::Warn => Vec::from([119u8, 97u8, 114u8, 110u8]),
            PolicyAction::Block => Vec::from([98u8, 108u8, 111u8, 99u8, 107u8]),
        }
    }
}
}
pub mod severity_1259a9af {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Severity {Critical = 0,High = 1,Medium = 2,Low = 3,Info = 4}
impl Severity {
    
    pub fn penalty_weight(self) -> i32 {
        match self {
            Severity::Critical => 25,
            Severity::High => 10,
            Severity::Medium => 3,
            Severity::Low => 1,
            Severity::Info => 0,
        }
    }
    
    
    
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            Severity::Critical => Vec::from([99u8, 114u8, 105u8, 116u8, 105u8, 99u8, 97u8, 108u8]),
            Severity::High => Vec::from([104u8, 105u8, 103u8, 104u8]),
            Severity::Medium => Vec::from([109u8, 101u8, 100u8, 105u8, 117u8, 109u8]),
            Severity::Low => Vec::from([108u8, 111u8, 119u8]),
            Severity::Info => Vec::from([105u8, 110u8, 102u8, 111u8]),
        }
    }
}
}
pub mod age_gate_mode_3fdb45b7 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AgeGateMode {UpstreamPublishTime,FirstSeen}
impl AgeGateMode {
    pub fn as_str(self) -> Vec<u8> {
        match self {
            Self::UpstreamPublishTime => Vec::from([117u8, 112u8, 115u8, 116u8, 114u8, 101u8, 97u8, 109u8, 95u8, 112u8, 117u8, 98u8, 108u8, 105u8, 115u8, 104u8, 95u8, 116u8, 105u8, 109u8, 101u8]),
            Self::FirstSeen => Vec::from([102u8, 105u8, 114u8, 115u8, 116u8, 95u8, 115u8, 101u8, 101u8, 110u8]),
        }
    }
}
}
pub mod age_gate_review_status_3fdb45b7 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AgeGateReviewStatus {Pending,Approved,Rejected}
impl AgeGateReviewStatus {
    pub fn as_str(&self) -> Vec<u8> {
        match self {
            Self::Pending => Vec::from([112u8, 101u8, 110u8, 100u8, 105u8, 110u8, 103u8]),
            Self::Approved => Vec::from([97u8, 112u8, 112u8, 114u8, 111u8, 118u8, 101u8, 100u8]),
            Self::Rejected => Vec::from([114u8, 101u8, 106u8, 101u8, 99u8, 116u8, 101u8, 100u8]),
        }
    }
}
}
pub mod audit_stream_mode_8053ef47 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AuditStreamMode {Off,Stdout}
impl AuditStreamMode {
    
    pub fn name(self) -> Vec<u8> {
        match self {
            Self::Off => Vec::from([111u8, 102u8, 102u8]),
            Self::Stdout => Vec::from([115u8, 116u8, 100u8, 111u8, 117u8, 116u8]),
        }
    }
}
}
pub mod audit_action_3ef0ea8f {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AuditAction {Login,Logout,LoginFailed,PasswordChanged,ApiTokenCreated,ApiTokenRevoked,UserCreated,UserUpdated,UserDeleted,UserDisabled,RoleAssigned,RoleRevoked,RepositoryCreated,RepositoryUpdated,RepositoryDeleted,RepositoryPermissionChanged,ArtifactUploaded,ArtifactDownloaded,ArtifactDeleted,ArtifactMetadataUpdated,BackupStarted,BackupCompleted,BackupFailed,RestoreStarted,RestoreCompleted,RestoreFailed,PeerRegistered,PeerUnregistered,PeerSyncStarted,PeerSyncCompleted,SettingChanged,PluginInstalled,PluginUninstalled,PluginEnabled,PluginDisabled,EmailSubscriptionCreated,EmailSubscriptionDeleted,SbomGenerated,SbomRead,ScanReaped,TotpEnabled,TotpDisabled,SessionsInvalidated,TotpEnrollmentRequired,TotpPolicyChanged,ApiTokenPolicyChanged,AgeGateQueued,AgeGateApproved,AgeGateRejected,AgeGateReopened,PermissionDenied,CurationSyncTriggered,CurationVersionCreated,CurationVersionPublished,ProxyScanVerdictDeleted,CiOidcGroupBindingReconciled}
impl AuditAction {
    pub fn as_str(&self) -> Vec<u8> {
        match self {
            AuditAction::Login => Vec::from([76u8, 79u8, 71u8, 73u8, 78u8]),
            AuditAction::Logout => Vec::from([76u8, 79u8, 71u8, 79u8, 85u8, 84u8]),
            AuditAction::LoginFailed => Vec::from([76u8, 79u8, 71u8, 73u8, 78u8, 95u8, 70u8, 65u8, 73u8, 76u8, 69u8, 68u8]),
            AuditAction::PasswordChanged => Vec::from([80u8, 65u8, 83u8, 83u8, 87u8, 79u8, 82u8, 68u8, 95u8, 67u8, 72u8, 65u8, 78u8, 71u8, 69u8, 68u8]),
            AuditAction::ApiTokenCreated => Vec::from([65u8, 80u8, 73u8, 95u8, 84u8, 79u8, 75u8, 69u8, 78u8, 95u8, 67u8, 82u8, 69u8, 65u8, 84u8, 69u8, 68u8]),
            AuditAction::ApiTokenRevoked => Vec::from([65u8, 80u8, 73u8, 95u8, 84u8, 79u8, 75u8, 69u8, 78u8, 95u8, 82u8, 69u8, 86u8, 79u8, 75u8, 69u8, 68u8]),
            AuditAction::UserCreated => Vec::from([85u8, 83u8, 69u8, 82u8, 95u8, 67u8, 82u8, 69u8, 65u8, 84u8, 69u8, 68u8]),
            AuditAction::UserUpdated => Vec::from([85u8, 83u8, 69u8, 82u8, 95u8, 85u8, 80u8, 68u8, 65u8, 84u8, 69u8, 68u8]),
            AuditAction::UserDeleted => Vec::from([85u8, 83u8, 69u8, 82u8, 95u8, 68u8, 69u8, 76u8, 69u8, 84u8, 69u8, 68u8]),
            AuditAction::UserDisabled => Vec::from([85u8, 83u8, 69u8, 82u8, 95u8, 68u8, 73u8, 83u8, 65u8, 66u8, 76u8, 69u8, 68u8]),
            AuditAction::RoleAssigned => Vec::from([82u8, 79u8, 76u8, 69u8, 95u8, 65u8, 83u8, 83u8, 73u8, 71u8, 78u8, 69u8, 68u8]),
            AuditAction::RoleRevoked => Vec::from([82u8, 79u8, 76u8, 69u8, 95u8, 82u8, 69u8, 86u8, 79u8, 75u8, 69u8, 68u8]),
            AuditAction::RepositoryCreated => Vec::from([82u8, 69u8, 80u8, 79u8, 83u8, 73u8, 84u8, 79u8, 82u8, 89u8, 95u8, 67u8, 82u8, 69u8, 65u8, 84u8, 69u8, 68u8]),
            AuditAction::RepositoryUpdated => Vec::from([82u8, 69u8, 80u8, 79u8, 83u8, 73u8, 84u8, 79u8, 82u8, 89u8, 95u8, 85u8, 80u8, 68u8, 65u8, 84u8, 69u8, 68u8]),
            AuditAction::RepositoryDeleted => Vec::from([82u8, 69u8, 80u8, 79u8, 83u8, 73u8, 84u8, 79u8, 82u8, 89u8, 95u8, 68u8, 69u8, 76u8, 69u8, 84u8, 69u8, 68u8]),
            AuditAction::RepositoryPermissionChanged => Vec::from([82u8, 69u8, 80u8, 79u8, 83u8, 73u8, 84u8, 79u8, 82u8, 89u8, 95u8, 80u8, 69u8, 82u8, 77u8, 73u8, 83u8, 83u8, 73u8, 79u8, 78u8, 95u8, 67u8, 72u8, 65u8, 78u8, 71u8, 69u8, 68u8]),
            AuditAction::ArtifactUploaded => Vec::from([65u8, 82u8, 84u8, 73u8, 70u8, 65u8, 67u8, 84u8, 95u8, 85u8, 80u8, 76u8, 79u8, 65u8, 68u8, 69u8, 68u8]),
            AuditAction::ArtifactDownloaded => Vec::from([65u8, 82u8, 84u8, 73u8, 70u8, 65u8, 67u8, 84u8, 95u8, 68u8, 79u8, 87u8, 78u8, 76u8, 79u8, 65u8, 68u8, 69u8, 68u8]),
            AuditAction::ArtifactDeleted => Vec::from([65u8, 82u8, 84u8, 73u8, 70u8, 65u8, 67u8, 84u8, 95u8, 68u8, 69u8, 76u8, 69u8, 84u8, 69u8, 68u8]),
            AuditAction::ArtifactMetadataUpdated => Vec::from([65u8, 82u8, 84u8, 73u8, 70u8, 65u8, 67u8, 84u8, 95u8, 77u8, 69u8, 84u8, 65u8, 68u8, 65u8, 84u8, 65u8, 95u8, 85u8, 80u8, 68u8, 65u8, 84u8, 69u8, 68u8]),
            AuditAction::BackupStarted => Vec::from([66u8, 65u8, 67u8, 75u8, 85u8, 80u8, 95u8, 83u8, 84u8, 65u8, 82u8, 84u8, 69u8, 68u8]),
            AuditAction::BackupCompleted => Vec::from([66u8, 65u8, 67u8, 75u8, 85u8, 80u8, 95u8, 67u8, 79u8, 77u8, 80u8, 76u8, 69u8, 84u8, 69u8, 68u8]),
            AuditAction::BackupFailed => Vec::from([66u8, 65u8, 67u8, 75u8, 85u8, 80u8, 95u8, 70u8, 65u8, 73u8, 76u8, 69u8, 68u8]),
            AuditAction::RestoreStarted => Vec::from([82u8, 69u8, 83u8, 84u8, 79u8, 82u8, 69u8, 95u8, 83u8, 84u8, 65u8, 82u8, 84u8, 69u8, 68u8]),
            AuditAction::RestoreCompleted => Vec::from([82u8, 69u8, 83u8, 84u8, 79u8, 82u8, 69u8, 95u8, 67u8, 79u8, 77u8, 80u8, 76u8, 69u8, 84u8, 69u8, 68u8]),
            AuditAction::RestoreFailed => Vec::from([82u8, 69u8, 83u8, 84u8, 79u8, 82u8, 69u8, 95u8, 70u8, 65u8, 73u8, 76u8, 69u8, 68u8]),
            AuditAction::PeerRegistered => Vec::from([80u8, 69u8, 69u8, 82u8, 95u8, 82u8, 69u8, 71u8, 73u8, 83u8, 84u8, 69u8, 82u8, 69u8, 68u8]),
            AuditAction::PeerUnregistered => Vec::from([80u8, 69u8, 69u8, 82u8, 95u8, 85u8, 78u8, 82u8, 69u8, 71u8, 73u8, 83u8, 84u8, 69u8, 82u8, 69u8, 68u8]),
            AuditAction::PeerSyncStarted => Vec::from([80u8, 69u8, 69u8, 82u8, 95u8, 83u8, 89u8, 78u8, 67u8, 95u8, 83u8, 84u8, 65u8, 82u8, 84u8, 69u8, 68u8]),
            AuditAction::PeerSyncCompleted => Vec::from([80u8, 69u8, 69u8, 82u8, 95u8, 83u8, 89u8, 78u8, 67u8, 95u8, 67u8, 79u8, 77u8, 80u8, 76u8, 69u8, 84u8, 69u8, 68u8]),
            AuditAction::SettingChanged => Vec::from([83u8, 69u8, 84u8, 84u8, 73u8, 78u8, 71u8, 95u8, 67u8, 72u8, 65u8, 78u8, 71u8, 69u8, 68u8]),
            AuditAction::PluginInstalled => Vec::from([80u8, 76u8, 85u8, 71u8, 73u8, 78u8, 95u8, 73u8, 78u8, 83u8, 84u8, 65u8, 76u8, 76u8, 69u8, 68u8]),
            AuditAction::PluginUninstalled => Vec::from([80u8, 76u8, 85u8, 71u8, 73u8, 78u8, 95u8, 85u8, 78u8, 73u8, 78u8, 83u8, 84u8, 65u8, 76u8, 76u8, 69u8, 68u8]),
            AuditAction::PluginEnabled => Vec::from([80u8, 76u8, 85u8, 71u8, 73u8, 78u8, 95u8, 69u8, 78u8, 65u8, 66u8, 76u8, 69u8, 68u8]),
            AuditAction::PluginDisabled => Vec::from([80u8, 76u8, 85u8, 71u8, 73u8, 78u8, 95u8, 68u8, 73u8, 83u8, 65u8, 66u8, 76u8, 69u8, 68u8]),
            AuditAction::EmailSubscriptionCreated => Vec::from([69u8, 77u8, 65u8, 73u8, 76u8, 95u8, 83u8, 85u8, 66u8, 83u8, 67u8, 82u8, 73u8, 80u8, 84u8, 73u8, 79u8, 78u8, 95u8, 67u8, 82u8, 69u8, 65u8, 84u8, 69u8, 68u8]),
            AuditAction::EmailSubscriptionDeleted => Vec::from([69u8, 77u8, 65u8, 73u8, 76u8, 95u8, 83u8, 85u8, 66u8, 83u8, 67u8, 82u8, 73u8, 80u8, 84u8, 73u8, 79u8, 78u8, 95u8, 68u8, 69u8, 76u8, 69u8, 84u8, 69u8, 68u8]),
            AuditAction::SbomGenerated => Vec::from([83u8, 66u8, 79u8, 77u8, 95u8, 71u8, 69u8, 78u8, 69u8, 82u8, 65u8, 84u8, 69u8, 68u8]),
            AuditAction::SbomRead => Vec::from([83u8, 66u8, 79u8, 77u8, 95u8, 82u8, 69u8, 65u8, 68u8]),
            AuditAction::ScanReaped => Vec::from([83u8, 67u8, 65u8, 78u8, 95u8, 82u8, 69u8, 65u8, 80u8, 69u8, 68u8]),
            AuditAction::TotpEnabled => Vec::from([84u8, 79u8, 84u8, 80u8, 95u8, 69u8, 78u8, 65u8, 66u8, 76u8, 69u8, 68u8]),
            AuditAction::TotpDisabled => Vec::from([84u8, 79u8, 84u8, 80u8, 95u8, 68u8, 73u8, 83u8, 65u8, 66u8, 76u8, 69u8, 68u8]),
            AuditAction::SessionsInvalidated => Vec::from([83u8, 69u8, 83u8, 83u8, 73u8, 79u8, 78u8, 83u8, 95u8, 73u8, 78u8, 86u8, 65u8, 76u8, 73u8, 68u8, 65u8, 84u8, 69u8, 68u8]),
            AuditAction::TotpEnrollmentRequired => Vec::from([84u8, 79u8, 84u8, 80u8, 95u8, 69u8, 78u8, 82u8, 79u8, 76u8, 76u8, 77u8, 69u8, 78u8, 84u8, 95u8, 82u8, 69u8, 81u8, 85u8, 73u8, 82u8, 69u8, 68u8]),
            AuditAction::TotpPolicyChanged => Vec::from([84u8, 79u8, 84u8, 80u8, 95u8, 80u8, 79u8, 76u8, 73u8, 67u8, 89u8, 95u8, 67u8, 72u8, 65u8, 78u8, 71u8, 69u8, 68u8]),
            AuditAction::ApiTokenPolicyChanged => Vec::from([65u8, 80u8, 73u8, 95u8, 84u8, 79u8, 75u8, 69u8, 78u8, 95u8, 80u8, 79u8, 76u8, 73u8, 67u8, 89u8, 95u8, 67u8, 72u8, 65u8, 78u8, 71u8, 69u8, 68u8]),
            AuditAction::AgeGateQueued => Vec::from([65u8, 71u8, 69u8, 95u8, 71u8, 65u8, 84u8, 69u8, 95u8, 81u8, 85u8, 69u8, 85u8, 69u8, 68u8]),
            AuditAction::AgeGateApproved => Vec::from([65u8, 71u8, 69u8, 95u8, 71u8, 65u8, 84u8, 69u8, 95u8, 65u8, 80u8, 80u8, 82u8, 79u8, 86u8, 69u8, 68u8]),
            AuditAction::AgeGateRejected => Vec::from([65u8, 71u8, 69u8, 95u8, 71u8, 65u8, 84u8, 69u8, 95u8, 82u8, 69u8, 74u8, 69u8, 67u8, 84u8, 69u8, 68u8]),
            AuditAction::AgeGateReopened => Vec::from([65u8, 71u8, 69u8, 95u8, 71u8, 65u8, 84u8, 69u8, 95u8, 82u8, 69u8, 79u8, 80u8, 69u8, 78u8, 69u8, 68u8]),
            AuditAction::PermissionDenied => Vec::from([80u8, 69u8, 82u8, 77u8, 73u8, 83u8, 83u8, 73u8, 79u8, 78u8, 95u8, 68u8, 69u8, 78u8, 73u8, 69u8, 68u8]),
            AuditAction::CurationSyncTriggered => Vec::from([67u8, 85u8, 82u8, 65u8, 84u8, 73u8, 79u8, 78u8, 95u8, 83u8, 89u8, 78u8, 67u8, 95u8, 84u8, 82u8, 73u8, 71u8, 71u8, 69u8, 82u8, 69u8, 68u8]),
            AuditAction::CurationVersionCreated => Vec::from([67u8, 85u8, 82u8, 65u8, 84u8, 73u8, 79u8, 78u8, 95u8, 86u8, 69u8, 82u8, 83u8, 73u8, 79u8, 78u8, 95u8, 67u8, 82u8, 69u8, 65u8, 84u8, 69u8, 68u8]),
            AuditAction::CurationVersionPublished => Vec::from([67u8, 85u8, 82u8, 65u8, 84u8, 73u8, 79u8, 78u8, 95u8, 86u8, 69u8, 82u8, 83u8, 73u8, 79u8, 78u8, 95u8, 80u8, 85u8, 66u8, 76u8, 73u8, 83u8, 72u8, 69u8, 68u8]),
            AuditAction::ProxyScanVerdictDeleted => Vec::from([80u8, 82u8, 79u8, 88u8, 89u8, 95u8, 83u8, 67u8, 65u8, 78u8, 95u8, 86u8, 69u8, 82u8, 68u8, 73u8, 67u8, 84u8, 95u8, 68u8, 69u8, 76u8, 69u8, 84u8, 69u8, 68u8]),
            AuditAction::CiOidcGroupBindingReconciled => Vec::from([67u8, 73u8, 95u8, 79u8, 73u8, 68u8, 67u8, 95u8, 71u8, 82u8, 79u8, 85u8, 80u8, 95u8, 66u8, 73u8, 78u8, 68u8, 73u8, 78u8, 71u8, 95u8, 82u8, 69u8, 67u8, 79u8, 78u8, 67u8, 73u8, 76u8, 69u8, 68u8]),
        }
    }
}
}
pub mod resource_type_3ef0ea8f {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ResourceType {User,Repository,Artifact,Role,ApiToken,PeerInstance,Backup,Setting,Plugin,ScanResult}
impl ResourceType {
    pub fn as_str(&self) -> Vec<u8> {
        match self {
            ResourceType::User => Vec::from([117u8, 115u8, 101u8, 114u8]),
            ResourceType::Repository => Vec::from([114u8, 101u8, 112u8, 111u8, 115u8, 105u8, 116u8, 111u8, 114u8, 121u8]),
            ResourceType::Artifact => Vec::from([97u8, 114u8, 116u8, 105u8, 102u8, 97u8, 99u8, 116u8]),
            ResourceType::Role => Vec::from([114u8, 111u8, 108u8, 101u8]),
            ResourceType::ApiToken => Vec::from([97u8, 112u8, 105u8, 95u8, 116u8, 111u8, 107u8, 101u8, 110u8]),
            ResourceType::PeerInstance => Vec::from([112u8, 101u8, 101u8, 114u8, 95u8, 105u8, 110u8, 115u8, 116u8, 97u8, 110u8, 99u8, 101u8]),
            ResourceType::Backup => Vec::from([98u8, 97u8, 99u8, 107u8, 117u8, 112u8]),
            ResourceType::Setting => Vec::from([115u8, 101u8, 116u8, 116u8, 105u8, 110u8, 103u8]),
            ResourceType::Plugin => Vec::from([112u8, 108u8, 117u8, 103u8, 105u8, 110u8]),
            ResourceType::ScanResult => Vec::from([115u8, 99u8, 97u8, 110u8, 95u8, 114u8, 101u8, 115u8, 117u8, 108u8, 116u8]),
        }
    }
}
}
pub mod noarch_kind_b8478f7b {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum NoarchKind {Python,Generic}
impl NoarchKind {
    pub fn as_str(&self) -> Vec<u8> {
        match self {
            NoarchKind::Python => Vec::from([112u8, 121u8, 116u8, 104u8, 111u8, 110u8]),
            NoarchKind::Generic => Vec::from([103u8, 101u8, 110u8, 101u8, 114u8, 105u8, 99u8]),
        }
    }
}
}
pub mod conda_archive_type_b8478f7b {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum CondaArchiveType {CondaV2,TarBz2}
impl CondaArchiveType {
    pub fn as_str(&self) -> Vec<u8> {
        match self {
            CondaArchiveType::CondaV2 => Vec::from([99u8, 111u8, 110u8, 100u8, 97u8]),
            CondaArchiveType::TarBz2 => Vec::from([116u8, 97u8, 114u8, 46u8, 98u8, 122u8, 50u8]),
        }
    }
}
}
pub mod script_kind_a04cea8b {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ScriptKind {PostLink,PreLink,PreUnlink,PreInstall,Install,PostInstall,Prepare,RpmPre,RpmPost,RpmPreUn,RpmPostUn,DebPreInst,DebPostInst,DebPreRm,DebPostRm,ApkPreInstall,ApkPostInstall,PythonSetupPy}
impl ScriptKind {
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            ScriptKind::PostLink => Vec::from([112u8, 111u8, 115u8, 116u8, 45u8, 108u8, 105u8, 110u8, 107u8]),
            ScriptKind::PreLink => Vec::from([112u8, 114u8, 101u8, 45u8, 108u8, 105u8, 110u8, 107u8]),
            ScriptKind::PreUnlink => Vec::from([112u8, 114u8, 101u8, 45u8, 117u8, 110u8, 108u8, 105u8, 110u8, 107u8]),
            ScriptKind::PreInstall => Vec::from([112u8, 114u8, 101u8, 105u8, 110u8, 115u8, 116u8, 97u8, 108u8, 108u8]),
            ScriptKind::Install => Vec::from([105u8, 110u8, 115u8, 116u8, 97u8, 108u8, 108u8]),
            ScriptKind::PostInstall => Vec::from([112u8, 111u8, 115u8, 116u8, 105u8, 110u8, 115u8, 116u8, 97u8, 108u8, 108u8]),
            ScriptKind::Prepare => Vec::from([112u8, 114u8, 101u8, 112u8, 97u8, 114u8, 101u8]),
            ScriptKind::RpmPre => Vec::from([114u8, 112u8, 109u8, 45u8, 112u8, 114u8, 101u8]),
            ScriptKind::RpmPost => Vec::from([114u8, 112u8, 109u8, 45u8, 112u8, 111u8, 115u8, 116u8]),
            ScriptKind::RpmPreUn => Vec::from([114u8, 112u8, 109u8, 45u8, 112u8, 114u8, 101u8, 117u8, 110u8]),
            ScriptKind::RpmPostUn => Vec::from([114u8, 112u8, 109u8, 45u8, 112u8, 111u8, 115u8, 116u8, 117u8, 110u8]),
            ScriptKind::DebPreInst => Vec::from([100u8, 101u8, 98u8, 45u8, 112u8, 114u8, 101u8, 105u8, 110u8, 115u8, 116u8]),
            ScriptKind::DebPostInst => Vec::from([100u8, 101u8, 98u8, 45u8, 112u8, 111u8, 115u8, 116u8, 105u8, 110u8, 115u8, 116u8]),
            ScriptKind::DebPreRm => Vec::from([100u8, 101u8, 98u8, 45u8, 112u8, 114u8, 101u8, 114u8, 109u8]),
            ScriptKind::DebPostRm => Vec::from([100u8, 101u8, 98u8, 45u8, 112u8, 111u8, 115u8, 116u8, 114u8, 109u8]),
            ScriptKind::ApkPreInstall => Vec::from([97u8, 112u8, 107u8, 45u8, 112u8, 114u8, 101u8, 45u8, 105u8, 110u8, 115u8, 116u8, 97u8, 108u8, 108u8]),
            ScriptKind::ApkPostInstall => Vec::from([97u8, 112u8, 107u8, 45u8, 112u8, 111u8, 115u8, 116u8, 45u8, 105u8, 110u8, 115u8, 116u8, 97u8, 108u8, 108u8]),
            ScriptKind::PythonSetupPy => Vec::from([112u8, 121u8, 116u8, 104u8, 111u8, 110u8, 45u8, 115u8, 101u8, 116u8, 117u8, 112u8, 45u8, 112u8, 121u8]),
        }
    }
    
    
    
    
    
    pub fn runs_as_root(self) -> bool {
        matches!(
            self,
            ScriptKind::RpmPre
                | ScriptKind::RpmPost
                | ScriptKind::RpmPreUn
                | ScriptKind::RpmPostUn
                | ScriptKind::DebPreInst
                | ScriptKind::DebPostInst
                | ScriptKind::DebPreRm
                | ScriptKind::DebPostRm
                | ScriptKind::ApkPreInstall
                | ScriptKind::ApkPostInstall
        )
    }
}
}
pub mod candidate_confidence_8223875f {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum CandidateConfidence {Low,Medium,High}
impl CandidateConfidence {
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            CandidateConfidence::Low => Vec::from([108u8, 111u8, 119u8]),
            CandidateConfidence::Medium => Vec::from([109u8, 101u8, 100u8, 105u8, 117u8, 109u8]),
            CandidateConfidence::High => Vec::from([104u8, 105u8, 103u8, 104u8]),
        }
    }
}
}
pub mod check_b0946112 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Check {BundleWellFormed = 0,SubjectDigestBound = 1,CryptoAndChain = 2,RekorInclusion = 3,IdentityExtracted = 4,IssuerAllowlisted = 5,PublisherOwnerBound = 6,RekorSet = 7,StatementPolicy = 8}
impl Check {
    pub fn bit(self) -> u16 {
        1 << (self as u16)
    }
    pub fn reason_label(self) -> Vec<u8> {
        match self {
            Check::BundleWellFormed => Vec::from([98u8, 117u8, 110u8, 100u8, 108u8, 101u8]),
            Check::SubjectDigestBound => Vec::from([115u8, 117u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 98u8, 105u8, 110u8, 100u8, 105u8, 110u8, 103u8]),
            Check::CryptoAndChain => Vec::from([115u8, 105u8, 103u8, 110u8, 97u8, 116u8, 117u8, 114u8, 101u8, 47u8, 99u8, 101u8, 114u8, 116u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 101u8, 32u8, 99u8, 104u8, 97u8, 105u8, 110u8]),
            Check::RekorSet => Vec::from([116u8, 114u8, 97u8, 110u8, 115u8, 112u8, 97u8, 114u8, 101u8, 110u8, 99u8, 121u8, 32u8, 40u8, 82u8, 101u8, 107u8, 111u8, 114u8, 32u8, 83u8, 69u8, 84u8, 41u8]),
            Check::RekorInclusion => Vec::from([116u8, 114u8, 97u8, 110u8, 115u8, 112u8, 97u8, 114u8, 101u8, 110u8, 99u8, 121u8, 32u8, 40u8, 82u8, 101u8, 107u8, 111u8, 114u8, 32u8, 105u8, 110u8, 99u8, 108u8, 117u8, 115u8, 105u8, 111u8, 110u8, 41u8]),
            Check::IssuerAllowlisted => Vec::from([105u8, 115u8, 115u8, 117u8, 101u8, 114u8]),
            Check::IdentityExtracted => Vec::from([105u8, 100u8, 101u8, 110u8, 116u8, 105u8, 116u8, 121u8]),
            Check::PublisherOwnerBound => Vec::from([105u8, 100u8, 101u8, 110u8, 116u8, 105u8, 116u8, 121u8, 32u8, 98u8, 105u8, 110u8, 100u8, 105u8, 110u8, 103u8]),
            Check::StatementPolicy => Vec::from([115u8, 116u8, 97u8, 116u8, 101u8, 109u8, 101u8, 110u8, 116u8, 32u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8]),
        }
    }
}
}
pub mod attestation_state_b0946112 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AttestationState {Unverified,Verified,Failed}
impl AttestationState {
    pub fn as_str(self) -> Vec<u8> {
        match self {
            AttestationState::Unverified => Vec::from([117u8, 110u8, 118u8, 101u8, 114u8, 105u8, 102u8, 105u8, 101u8, 100u8]),
            AttestationState::Verified => Vec::from([118u8, 101u8, 114u8, 105u8, 102u8, 105u8, 101u8, 100u8]),
            AttestationState::Failed => Vec::from([102u8, 97u8, 105u8, 108u8, 101u8, 100u8]),
        }
    }
}
}
pub mod inventory_completeness_0e70a8c0 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum InventoryCompleteness {Complete,Declared,Partial,None}
impl InventoryCompleteness {
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            InventoryCompleteness::Complete => Vec::from([99u8, 111u8, 109u8, 112u8, 108u8, 101u8, 116u8, 101u8]),
            InventoryCompleteness::Declared => Vec::from([100u8, 101u8, 99u8, 108u8, 97u8, 114u8, 101u8, 100u8]),
            InventoryCompleteness::Partial => Vec::from([112u8, 97u8, 114u8, 116u8, 105u8, 97u8, 108u8]),
            InventoryCompleteness::None => Vec::from([110u8, 111u8, 110u8, 101u8]),
        }
    }
}
}
pub mod egress_proxy_mode_2d09e195 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum EgressProxyMode {Inherit,Direct,Explicit}
impl EgressProxyMode {
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            EgressProxyMode::Inherit => Vec::from([105u8, 110u8, 104u8, 101u8, 114u8, 105u8, 116u8]),
            EgressProxyMode::Direct => Vec::from([100u8, 105u8, 114u8, 101u8, 99u8, 116u8]),
            EgressProxyMode::Explicit => Vec::from([101u8, 120u8, 112u8, 108u8, 105u8, 99u8, 105u8, 116u8]),
        }
    }
}
}
pub mod rate_limit_decision_2593facc {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum RateLimitDecision {Allowed,RecipientLimited,DomainLimited}
impl RateLimitDecision {
    
    pub fn label(self) -> Vec<u8> {
        match self {
            RateLimitDecision::Allowed => Vec::from([97u8, 108u8, 108u8, 111u8, 119u8, 101u8, 100u8]),
            RateLimitDecision::RecipientLimited => Vec::from([114u8, 101u8, 99u8, 105u8, 112u8, 105u8, 101u8, 110u8, 116u8]),
            RateLimitDecision::DomainLimited => Vec::from([100u8, 111u8, 109u8, 97u8, 105u8, 110u8]),
        }
    }
}
}
pub mod lock_format_99735155 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum LockFormat {PixiLock,CondaLock,NpmPackageLock,CargoLock,PoetryLock,UvLock}
impl LockFormat {
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            LockFormat::PixiLock => Vec::from([112u8, 105u8, 120u8, 105u8, 46u8, 108u8, 111u8, 99u8, 107u8]),
            LockFormat::CondaLock => Vec::from([99u8, 111u8, 110u8, 100u8, 97u8, 45u8, 108u8, 111u8, 99u8, 107u8]),
            LockFormat::NpmPackageLock => Vec::from([112u8, 97u8, 99u8, 107u8, 97u8, 103u8, 101u8, 45u8, 108u8, 111u8, 99u8, 107u8, 46u8, 106u8, 115u8, 111u8, 110u8]),
            LockFormat::CargoLock => Vec::from([67u8, 97u8, 114u8, 103u8, 111u8, 46u8, 108u8, 111u8, 99u8, 107u8]),
            LockFormat::PoetryLock => Vec::from([112u8, 111u8, 101u8, 116u8, 114u8, 121u8, 46u8, 108u8, 111u8, 99u8, 107u8]),
            LockFormat::UvLock => Vec::from([117u8, 118u8, 46u8, 108u8, 111u8, 99u8, 107u8]),
        }
    }
    
    
    
    pub fn is_per_platform(self) -> bool {
        matches!(self, LockFormat::PixiLock | LockFormat::CondaLock)
    }
}
}
pub mod ecosystem_99735155 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Ecosystem {Conda,PyPi,Npm,Cargo}
impl Ecosystem {
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            Ecosystem::Conda => Vec::from([99u8, 111u8, 110u8, 100u8, 97u8]),
            Ecosystem::PyPi => Vec::from([112u8, 121u8, 112u8, 105u8]),
            Ecosystem::Npm => Vec::from([110u8, 112u8, 109u8]),
            Ecosystem::Cargo => Vec::from([99u8, 97u8, 114u8, 103u8, 111u8]),
        }
    }
}
}
pub mod edge_kind_99735155 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum EdgeKind {Runtime,Build,Dev,Optional,Peer,Constrains}
impl EdgeKind {
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            EdgeKind::Runtime => Vec::from([114u8, 117u8, 110u8, 116u8, 105u8, 109u8, 101u8]),
            EdgeKind::Build => Vec::from([98u8, 117u8, 105u8, 108u8, 100u8]),
            EdgeKind::Dev => Vec::from([100u8, 101u8, 118u8]),
            EdgeKind::Optional => Vec::from([111u8, 112u8, 116u8, 105u8, 111u8, 110u8, 97u8, 108u8]),
            EdgeKind::Peer => Vec::from([112u8, 101u8, 101u8, 114u8]),
            EdgeKind::Constrains => Vec::from([99u8, 111u8, 110u8, 115u8, 116u8, 114u8, 97u8, 105u8, 110u8, 115u8]),
        }
    }
}
}
pub mod unresolved_kind_99735155 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum UnresolvedKind {Unparsed,MissingDependency,ConditionalNotInstalled,VirtualPackage,Ambiguous}
impl UnresolvedKind {
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            UnresolvedKind::Unparsed => Vec::from([117u8, 110u8, 112u8, 97u8, 114u8, 115u8, 101u8, 100u8]),
            UnresolvedKind::MissingDependency => Vec::from([109u8, 105u8, 115u8, 115u8, 105u8, 110u8, 103u8, 95u8, 100u8, 101u8, 112u8, 101u8, 110u8, 100u8, 101u8, 110u8, 99u8, 121u8]),
            UnresolvedKind::ConditionalNotInstalled => Vec::from([99u8, 111u8, 110u8, 100u8, 105u8, 116u8, 105u8, 111u8, 110u8, 97u8, 108u8, 95u8, 110u8, 111u8, 116u8, 95u8, 105u8, 110u8, 115u8, 116u8, 97u8, 108u8, 108u8, 101u8, 100u8]),
            UnresolvedKind::VirtualPackage => Vec::from([118u8, 105u8, 114u8, 116u8, 117u8, 97u8, 108u8, 95u8, 112u8, 97u8, 99u8, 107u8, 97u8, 103u8, 101u8]),
            UnresolvedKind::Ambiguous => Vec::from([97u8, 109u8, 98u8, 105u8, 103u8, 117u8, 111u8, 117u8, 115u8]),
        }
    }
    
    
    pub fn is_parse_failure(self) -> bool {
        matches!(self, UnresolvedKind::Unparsed)
    }
    
    pub fn is_graph_gap(self) -> bool {
        matches!(
            self,
            UnresolvedKind::Unparsed
                | UnresolvedKind::MissingDependency
                | UnresolvedKind::Ambiguous
        )
    }
}
}
pub mod package_manager_7f965e35 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum PackageManager {Apt,Dnf,Microdnf,Yum,Apk,Pip,Conda}
impl PackageManager {
    pub fn as_str(self) -> Vec<u8> {
        match self {
            PackageManager::Apt => Vec::from([97u8, 112u8, 116u8]),
            PackageManager::Dnf => Vec::from([100u8, 110u8, 102u8]),
            PackageManager::Microdnf => Vec::from([109u8, 105u8, 99u8, 114u8, 111u8, 100u8, 110u8, 102u8]),
            PackageManager::Yum => Vec::from([121u8, 117u8, 109u8]),
            PackageManager::Apk => Vec::from([97u8, 112u8, 107u8]),
            PackageManager::Pip => Vec::from([112u8, 105u8, 112u8]),
            PackageManager::Conda => Vec::from([99u8, 111u8, 110u8, 100u8, 97u8]),
        }
    }
    
    pub fn is_system(self) -> bool {
        matches!(
            self,
            PackageManager::Apt
                | PackageManager::Dnf
                | PackageManager::Microdnf
                | PackageManager::Yum
                | PackageManager::Apk
        )
    }
}
}
pub mod policy_type_080e6210 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum PolicyType {MaxAgeDays,MaxVersions,NoDownloadsDays,TagPatternKeep,TagPatternDelete,SizeQuotaBytes}
impl PolicyType {
    
    
    pub fn as_wire_str(self) -> Vec<u8> {
        match self {
            Self::MaxAgeDays => Vec::from([109u8, 97u8, 120u8, 95u8, 97u8, 103u8, 101u8, 95u8, 100u8, 97u8, 121u8, 115u8]),
            Self::MaxVersions => Vec::from([109u8, 97u8, 120u8, 95u8, 118u8, 101u8, 114u8, 115u8, 105u8, 111u8, 110u8, 115u8]),
            Self::NoDownloadsDays => Vec::from([110u8, 111u8, 95u8, 100u8, 111u8, 119u8, 110u8, 108u8, 111u8, 97u8, 100u8, 115u8, 95u8, 100u8, 97u8, 121u8, 115u8]),
            Self::TagPatternKeep => Vec::from([116u8, 97u8, 103u8, 95u8, 112u8, 97u8, 116u8, 116u8, 101u8, 114u8, 110u8, 95u8, 107u8, 101u8, 101u8, 112u8]),
            Self::TagPatternDelete => Vec::from([116u8, 97u8, 103u8, 95u8, 112u8, 97u8, 116u8, 116u8, 101u8, 114u8, 110u8, 95u8, 100u8, 101u8, 108u8, 101u8, 116u8, 101u8]),
            Self::SizeQuotaBytes => Vec::from([115u8, 105u8, 122u8, 101u8, 95u8, 113u8, 117u8, 111u8, 116u8, 97u8, 95u8, 98u8, 121u8, 116u8, 101u8, 115u8]),
        }
    }
}
}
pub mod flat_key_write_claim_6572c2eb {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum FlatKeyWriteClaim {NotApplicable,Claimed,AlreadyOwned}
impl FlatKeyWriteClaim {
    
    
    pub fn needs_release_on_failure(self) -> bool {
        matches!(self, FlatKeyWriteClaim::Claimed)
    }
}
}
pub mod source_view_73842ce1 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum SourceView {Partial,Complete}
impl SourceView {
    
    pub fn overwrites(self) -> bool {
        matches!(self, SourceView::Complete)
    }
}
}
pub mod repository_type_73842ce1 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum RepositoryType {Local,Remote,Virtual}
impl RepositoryType {
    
    pub fn to_artifact_keeper(&self) -> Vec<u8> {
        match self {
            Self::Local => Vec::from([108u8, 111u8, 99u8, 97u8, 108u8]),
            Self::Remote => Vec::from([114u8, 101u8, 109u8, 111u8, 116u8, 101u8]),
            Self::Virtual => Vec::from([118u8, 105u8, 114u8, 116u8, 117u8, 97u8, 108u8]),
        }
    }
}
}
pub mod advisory_scan_status_38f3e57f {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AdvisoryScanStatus {Ok,NotRun,Partial}
impl AdvisoryScanStatus {
    
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            AdvisoryScanStatus::Ok => Vec::from([111u8, 107u8]),
            AdvisoryScanStatus::NotRun => Vec::from([110u8, 111u8, 116u8, 95u8, 114u8, 117u8, 110u8]),
            AdvisoryScanStatus::Partial => Vec::from([112u8, 97u8, 114u8, 116u8, 105u8, 97u8, 108u8]),
        }
    }
}
}
pub mod proxy_scan_action_2c5d20ab {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ProxyScanAction {FailOpen,FailClosed}
impl ProxyScanAction {
    pub fn is_fail_closed(self) -> bool {
        matches!(self, ProxyScanAction::FailClosed)
    }
}
}
pub mod vendoring_tool_8d235a49 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum VendoringTool {AuditWheel,Delocate,DelvEWheel}
impl VendoringTool {
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            VendoringTool::AuditWheel => Vec::from([97u8, 117u8, 100u8, 105u8, 116u8, 119u8, 104u8, 101u8, 101u8, 108u8]),
            VendoringTool::Delocate => Vec::from([100u8, 101u8, 108u8, 111u8, 99u8, 97u8, 116u8, 101u8]),
            VendoringTool::DelvEWheel => Vec::from([100u8, 101u8, 108u8, 118u8, 101u8, 119u8, 104u8, 101u8, 101u8, 108u8]),
        }
    }
}
}
pub mod quarantine_state_63e328a6 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum QuarantineState {Quarantined,Released,Rejected}
impl QuarantineState {
    pub fn as_str(&self) -> Vec<u8> {
        match self {
            Self::Quarantined => Vec::from([113u8, 117u8, 97u8, 114u8, 97u8, 110u8, 116u8, 105u8, 110u8, 101u8, 100u8]),
            Self::Released => Vec::from([114u8, 101u8, 108u8, 101u8, 97u8, 115u8, 101u8, 100u8]),
            Self::Rejected => Vec::from([114u8, 101u8, 106u8, 101u8, 99u8, 116u8, 101u8, 100u8]),
        }
    }
}
}
pub mod inventory_status_731e13d3 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum InventoryStatus {Complete,Partial,Failed}
impl InventoryStatus {
    pub fn as_db_str(self) -> Vec<u8> {
        match self {
            InventoryStatus::Complete => Vec::from([99u8, 111u8, 109u8, 112u8, 108u8, 101u8, 116u8, 101u8]),
            InventoryStatus::Partial => Vec::from([112u8, 97u8, 114u8, 116u8, 105u8, 97u8, 108u8]),
            InventoryStatus::Failed => Vec::from([102u8, 97u8, 105u8, 108u8, 101u8, 100u8]),
        }
    }
}
}
pub mod scan_state_5f365d9c {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ScanState {Completed,InProgress,Failed,NeverScanned,NotApplicable}
impl ScanState {
    
    
    
    
    pub fn is_unscanned(self) -> bool {
        matches!(
            self,
            ScanState::InProgress | ScanState::Failed | ScanState::NeverScanned
        )
    }
    
    
    pub fn reason_token(self) -> Vec<u8> {
        match self {
            ScanState::Completed => Vec::from([99u8, 111u8, 109u8, 112u8, 108u8, 101u8, 116u8, 101u8, 100u8]),
            ScanState::InProgress => Vec::from([115u8, 99u8, 97u8, 110u8, 95u8, 105u8, 110u8, 95u8, 112u8, 114u8, 111u8, 103u8, 114u8, 101u8, 115u8, 115u8]),
            ScanState::Failed => Vec::from([115u8, 99u8, 97u8, 110u8, 95u8, 102u8, 97u8, 105u8, 108u8, 101u8, 100u8]),
            ScanState::NeverScanned => Vec::from([110u8, 101u8, 118u8, 101u8, 114u8, 95u8, 115u8, 99u8, 97u8, 110u8, 110u8, 101u8, 100u8]),
            ScanState::NotApplicable => Vec::from([110u8, 111u8, 116u8, 95u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 98u8, 108u8, 101u8]),
        }
    }
}
}
pub mod scan_completeness_ba4d10ac {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ScanCompleteness {Complete,Partial,NotCataloged}
impl ScanCompleteness {
    
    
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            ScanCompleteness::Complete => Vec::from([99u8, 111u8, 109u8, 112u8, 108u8, 101u8, 116u8, 101u8]),
            ScanCompleteness::Partial => Vec::from([112u8, 97u8, 114u8, 116u8, 105u8, 97u8, 108u8]),
            ScanCompleteness::NotCataloged => Vec::from([110u8, 111u8, 116u8, 95u8, 99u8, 97u8, 116u8, 97u8, 108u8, 111u8, 103u8, 101u8, 100u8]),
        }
    }
}
}
pub mod oci_content_kind_bc817bda {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OciContentKind {Blob,Manifest}
impl OciContentKind {
    
    pub fn path_segment(self) -> Vec<u8> {
        match self {
            OciContentKind::Blob => Vec::from([98u8, 108u8, 111u8, 98u8, 115u8]),
            OciContentKind::Manifest => Vec::from([109u8, 97u8, 110u8, 105u8, 102u8, 101u8, 115u8, 116u8, 115u8]),
        }
    }
}
}
pub mod oci_cleanup_key_family_c9cc8f67 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OciCleanupKeyFamily {Pending,Unreferenced}
impl OciCleanupKeyFamily {
    
    
    
    
    pub fn session_predicate_sql(self) -> Vec<u8> {
        match self {
            OciCleanupKeyFamily::Pending => {
                Vec::from([115u8, 46u8, 105u8, 100u8, 32u8, 61u8, 32u8, 99u8, 46u8, 117u8, 112u8, 108u8, 111u8, 97u8, 100u8, 95u8, 115u8, 101u8, 115u8, 115u8, 105u8, 111u8, 110u8, 95u8, 105u8, 100u8, 10u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 32u8, 79u8, 82u8, 32u8, 115u8, 46u8, 115u8, 116u8, 111u8, 114u8, 97u8, 103u8, 101u8, 95u8, 116u8, 101u8, 109u8, 112u8, 95u8, 107u8, 101u8, 121u8, 32u8, 61u8, 32u8, 99u8, 46u8, 115u8, 116u8, 111u8, 114u8, 97u8, 103u8, 101u8, 95u8, 107u8, 101u8, 121u8])
            }
            OciCleanupKeyFamily::Unreferenced => Vec::from([115u8, 46u8, 115u8, 116u8, 111u8, 114u8, 97u8, 103u8, 101u8, 95u8, 116u8, 101u8, 109u8, 112u8, 95u8, 107u8, 101u8, 121u8, 32u8, 61u8, 32u8, 99u8, 46u8, 115u8, 116u8, 111u8, 114u8, 97u8, 103u8, 101u8, 95u8, 107u8, 101u8, 121u8]),
        }
    }
}
}
pub mod dedup_scope_78b2cf8c {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum DedupScope {PerRepo,Instance}
impl DedupScope {
    
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            DedupScope::PerRepo => Vec::from([112u8, 101u8, 114u8, 95u8, 114u8, 101u8, 112u8, 111u8]),
            DedupScope::Instance => Vec::from([105u8, 110u8, 115u8, 116u8, 97u8, 110u8, 99u8, 101u8]),
        }
    }
}
}
pub mod totp_policy_31812d2d {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum TotpPolicy {Disabled,RequiredForAdmins,RequiredForAll}
impl TotpPolicy {
    
    pub fn as_str(self) -> Vec<u8> {
        match self {
            TotpPolicy::Disabled => Vec::from([100u8, 105u8, 115u8, 97u8, 98u8, 108u8, 101u8, 100u8]),
            TotpPolicy::RequiredForAdmins => Vec::from([114u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 100u8, 95u8, 102u8, 111u8, 114u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
            TotpPolicy::RequiredForAll => Vec::from([114u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 100u8, 95u8, 102u8, 111u8, 114u8, 95u8, 97u8, 108u8, 108u8]),
        }
    }
    
    pub fn is_enforcing(self) -> bool {
        !matches!(self, TotpPolicy::Disabled)
    }
}
}
pub mod policy_activation_refusal_31812d2d {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum PolicyActivationRefusal {PinnedByEnvironment,ActorNotEnrolled}
impl PolicyActivationRefusal {
    
    pub fn message(self) -> Vec<u8> {
        match self {
            PolicyActivationRefusal::PinnedByEnvironment => {
                Vec::from([84u8, 104u8, 101u8, 32u8, 84u8, 79u8, 84u8, 80u8, 32u8, 101u8, 110u8, 102u8, 111u8, 114u8, 99u8, 101u8, 109u8, 101u8, 110u8, 116u8, 32u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8, 32u8, 105u8, 115u8, 32u8, 112u8, 105u8, 110u8, 110u8, 101u8, 100u8, 32u8, 98u8, 121u8, 32u8, 116u8, 104u8, 101u8, 32u8, 84u8, 79u8, 84u8, 80u8, 95u8, 80u8, 79u8, 76u8, 73u8, 67u8, 89u8, 32u8, 101u8, 110u8, 118u8, 105u8, 114u8, 111u8, 110u8, 109u8, 101u8, 110u8, 116u8, 32u8, 118u8, 97u8, 114u8, 105u8, 97u8, 98u8, 108u8, 101u8, 32u8, 97u8, 110u8, 100u8, 32u8, 99u8, 97u8, 110u8, 110u8, 111u8, 116u8, 32u8, 98u8, 101u8, 32u8, 99u8, 104u8, 97u8, 110u8, 103u8, 101u8, 100u8, 32u8, 116u8, 104u8, 114u8, 111u8, 117u8, 103u8, 104u8, 32u8, 116u8, 104u8, 101u8, 32u8, 65u8, 80u8, 73u8, 46u8, 32u8, 85u8, 110u8, 115u8, 101u8, 116u8, 32u8, 84u8, 79u8, 84u8, 80u8, 95u8, 80u8, 79u8, 76u8, 73u8, 67u8, 89u8, 32u8, 97u8, 110u8, 100u8, 32u8, 114u8, 101u8, 115u8, 116u8, 97u8, 114u8, 116u8, 32u8, 116u8, 111u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 32u8, 105u8, 116u8, 32u8, 104u8, 101u8, 114u8, 101u8, 46u8])
            }
            PolicyActivationRefusal::ActorNotEnrolled => {
                Vec::from([69u8, 110u8, 97u8, 98u8, 108u8, 101u8, 32u8, 84u8, 79u8, 84u8, 80u8, 32u8, 111u8, 110u8, 32u8, 121u8, 111u8, 117u8, 114u8, 32u8, 111u8, 119u8, 110u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 98u8, 101u8, 102u8, 111u8, 114u8, 101u8, 32u8, 114u8, 101u8, 113u8, 117u8, 105u8, 114u8, 105u8, 110u8, 103u8, 32u8, 105u8, 116u8, 32u8, 102u8, 111u8, 114u8, 32u8, 111u8, 116u8, 104u8, 101u8, 114u8, 115u8, 46u8, 32u8, 84u8, 104u8, 105u8, 115u8, 32u8, 103u8, 117u8, 97u8, 114u8, 97u8, 110u8, 116u8, 101u8, 101u8, 115u8, 32u8, 97u8, 116u8, 32u8, 108u8, 101u8, 97u8, 115u8, 116u8, 32u8, 111u8, 110u8, 101u8, 32u8, 97u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 111u8, 114u8, 32u8, 99u8, 97u8, 110u8, 32u8, 115u8, 116u8, 105u8, 108u8, 108u8, 32u8, 115u8, 105u8, 103u8, 110u8, 32u8, 105u8, 110u8, 32u8, 105u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 101u8, 110u8, 114u8, 111u8, 108u8, 108u8, 109u8, 101u8, 110u8, 116u8, 32u8, 102u8, 108u8, 111u8, 119u8, 32u8, 100u8, 111u8, 101u8, 115u8, 32u8, 110u8, 111u8, 116u8, 32u8, 119u8, 111u8, 114u8, 107u8, 32u8, 105u8, 110u8, 32u8, 121u8, 111u8, 117u8, 114u8, 32u8, 101u8, 110u8, 118u8, 105u8, 114u8, 111u8, 110u8, 109u8, 101u8, 110u8, 116u8, 46u8])
            }
        }
    }
}
}
pub mod storage_path_format_9d04c6bd {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum StoragePathFormat {Native,Artifactory,Migration}
impl StoragePathFormat {
    
    pub fn has_fallback(&self) -> bool {
        matches!(self, Self::Migration)
    }
}
}
pub mod log_format_f5cc6ea1 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum LogFormat {Pretty,Json}
impl LogFormat {
    
    pub fn name(self) -> Vec<u8> {
        match self {
            Self::Pretty => Vec::from([112u8, 114u8, 101u8, 116u8, 116u8, 121u8]),
            Self::Json => Vec::from([106u8, 115u8, 111u8, 110u8]),
        }
    }
}
}
pub mod otlp_protocol_f5cc6ea1 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OtlpProtocol {Grpc,HttpProtobuf}
impl OtlpProtocol {
    
    pub fn name(self) -> Vec<u8> {
        match self {
            Self::Grpc => Vec::from([103u8, 114u8, 112u8, 99u8]),
            Self::HttpProtobuf => Vec::from([104u8, 116u8, 116u8, 112u8, 47u8, 112u8, 114u8, 111u8, 116u8, 111u8, 98u8, 117u8, 102u8]),
        }
    }
}
}
pub mod sampler_choice_f5cc6ea1 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum SamplerChoice {AlwaysOn,AlwaysOff,TraceIdRatio,ParentBasedAlwaysOn,ParentBasedAlwaysOff,ParentBasedTraceIdRatio}
impl SamplerChoice {
    pub fn name(self) -> Vec<u8> {
        match self {
            Self::AlwaysOn => Vec::from([97u8, 108u8, 119u8, 97u8, 121u8, 115u8, 95u8, 111u8, 110u8]),
            Self::AlwaysOff => Vec::from([97u8, 108u8, 119u8, 97u8, 121u8, 115u8, 95u8, 111u8, 102u8, 102u8]),
            Self::TraceIdRatio => Vec::from([116u8, 114u8, 97u8, 99u8, 101u8, 105u8, 100u8, 114u8, 97u8, 116u8, 105u8, 111u8]),
            Self::ParentBasedAlwaysOn => Vec::from([112u8, 97u8, 114u8, 101u8, 110u8, 116u8, 98u8, 97u8, 115u8, 101u8, 100u8, 95u8, 97u8, 108u8, 119u8, 97u8, 121u8, 115u8, 95u8, 111u8, 110u8]),
            Self::ParentBasedAlwaysOff => Vec::from([112u8, 97u8, 114u8, 101u8, 110u8, 116u8, 98u8, 97u8, 115u8, 101u8, 100u8, 95u8, 97u8, 108u8, 119u8, 97u8, 121u8, 115u8, 95u8, 111u8, 102u8, 102u8]),
            Self::ParentBasedTraceIdRatio => Vec::from([112u8, 97u8, 114u8, 101u8, 110u8, 116u8, 98u8, 97u8, 115u8, 101u8, 100u8, 95u8, 116u8, 114u8, 97u8, 99u8, 101u8, 105u8, 100u8, 114u8, 97u8, 116u8, 105u8, 111u8]),
        }
    }
    
    pub fn uses_ratio(self) -> bool {
        matches!(self, Self::TraceIdRatio | Self::ParentBasedTraceIdRatio)
    }
}
}
