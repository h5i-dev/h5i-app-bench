#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AuditAction {Login,Logout,LoginFailed,PasswordChanged,ApiTokenCreated,ApiTokenRevoked,UserCreated,UserUpdated,UserDeleted,UserDisabled,RoleAssigned,RoleRevoked,RepositoryCreated,RepositoryUpdated,RepositoryDeleted,RepositoryPermissionChanged,ArtifactUploaded,ArtifactDownloaded,ArtifactDeleted,ArtifactMetadataUpdated,BackupStarted,BackupCompleted,BackupFailed,RestoreStarted,RestoreCompleted,RestoreFailed,PeerRegistered,PeerUnregistered,PeerSyncStarted,PeerSyncCompleted,SettingChanged,PluginInstalled,PluginUninstalled,PluginEnabled,PluginDisabled,EmailSubscriptionCreated,EmailSubscriptionDeleted,SbomGenerated,SbomRead,ScanReaped,TotpEnabled,TotpDisabled,SessionsInvalidated,TotpEnrollmentRequired,TotpPolicyChanged,ApiTokenPolicyChanged,AgeGateQueued,AgeGateApproved,AgeGateRejected,AgeGateReopened,PermissionDenied,CurationSyncTriggered,CurationVersionCreated,CurationVersionPublished,ProxyScanVerdictDeleted,CiOidcGroupBindingReconciled}
impl AuditAction {
    pub fn as_str(&self) -> &'static str {
        match self {
            AuditAction::Login => "LOGIN",
            AuditAction::Logout => "LOGOUT",
            AuditAction::LoginFailed => "LOGIN_FAILED",
            AuditAction::PasswordChanged => "PASSWORD_CHANGED",
            AuditAction::ApiTokenCreated => "API_TOKEN_CREATED",
            AuditAction::ApiTokenRevoked => "API_TOKEN_REVOKED",
            AuditAction::UserCreated => "USER_CREATED",
            AuditAction::UserUpdated => "USER_UPDATED",
            AuditAction::UserDeleted => "USER_DELETED",
            AuditAction::UserDisabled => "USER_DISABLED",
            AuditAction::RoleAssigned => "ROLE_ASSIGNED",
            AuditAction::RoleRevoked => "ROLE_REVOKED",
            AuditAction::RepositoryCreated => "REPOSITORY_CREATED",
            AuditAction::RepositoryUpdated => "REPOSITORY_UPDATED",
            AuditAction::RepositoryDeleted => "REPOSITORY_DELETED",
            AuditAction::RepositoryPermissionChanged => "REPOSITORY_PERMISSION_CHANGED",
            AuditAction::ArtifactUploaded => "ARTIFACT_UPLOADED",
            AuditAction::ArtifactDownloaded => "ARTIFACT_DOWNLOADED",
            AuditAction::ArtifactDeleted => "ARTIFACT_DELETED",
            AuditAction::ArtifactMetadataUpdated => "ARTIFACT_METADATA_UPDATED",
            AuditAction::BackupStarted => "BACKUP_STARTED",
            AuditAction::BackupCompleted => "BACKUP_COMPLETED",
            AuditAction::BackupFailed => "BACKUP_FAILED",
            AuditAction::RestoreStarted => "RESTORE_STARTED",
            AuditAction::RestoreCompleted => "RESTORE_COMPLETED",
            AuditAction::RestoreFailed => "RESTORE_FAILED",
            AuditAction::PeerRegistered => "PEER_REGISTERED",
            AuditAction::PeerUnregistered => "PEER_UNREGISTERED",
            AuditAction::PeerSyncStarted => "PEER_SYNC_STARTED",
            AuditAction::PeerSyncCompleted => "PEER_SYNC_COMPLETED",
            AuditAction::SettingChanged => "SETTING_CHANGED",
            AuditAction::PluginInstalled => "PLUGIN_INSTALLED",
            AuditAction::PluginUninstalled => "PLUGIN_UNINSTALLED",
            AuditAction::PluginEnabled => "PLUGIN_ENABLED",
            AuditAction::PluginDisabled => "PLUGIN_DISABLED",
            AuditAction::EmailSubscriptionCreated => "EMAIL_SUBSCRIPTION_CREATED",
            AuditAction::EmailSubscriptionDeleted => "EMAIL_SUBSCRIPTION_DELETED",
            AuditAction::SbomGenerated => "SBOM_GENERATED",
            AuditAction::SbomRead => "SBOM_READ",
            AuditAction::ScanReaped => "SCAN_REAPED",
            AuditAction::TotpEnabled => "TOTP_ENABLED",
            AuditAction::TotpDisabled => "TOTP_DISABLED",
            AuditAction::SessionsInvalidated => "SESSIONS_INVALIDATED",
            AuditAction::TotpEnrollmentRequired => "TOTP_ENROLLMENT_REQUIRED",
            AuditAction::TotpPolicyChanged => "TOTP_POLICY_CHANGED",
            AuditAction::ApiTokenPolicyChanged => "API_TOKEN_POLICY_CHANGED",
            AuditAction::AgeGateQueued => "AGE_GATE_QUEUED",
            AuditAction::AgeGateApproved => "AGE_GATE_APPROVED",
            AuditAction::AgeGateRejected => "AGE_GATE_REJECTED",
            AuditAction::AgeGateReopened => "AGE_GATE_REOPENED",
            AuditAction::PermissionDenied => "PERMISSION_DENIED",
            AuditAction::CurationSyncTriggered => "CURATION_SYNC_TRIGGERED",
            AuditAction::CurationVersionCreated => "CURATION_VERSION_CREATED",
            AuditAction::CurationVersionPublished => "CURATION_VERSION_PUBLISHED",
            AuditAction::ProxyScanVerdictDeleted => "PROXY_SCAN_VERDICT_DELETED",
            AuditAction::CiOidcGroupBindingReconciled => "CI_OIDC_GROUP_BINDING_RECONCILED",
        }
    }
}
fn main(){
println!("as_str/Login\t{:?}",AuditAction::Login.as_str().as_bytes());
println!("as_str/Logout\t{:?}",AuditAction::Logout.as_str().as_bytes());
println!("as_str/LoginFailed\t{:?}",AuditAction::LoginFailed.as_str().as_bytes());
println!("as_str/PasswordChanged\t{:?}",AuditAction::PasswordChanged.as_str().as_bytes());
println!("as_str/ApiTokenCreated\t{:?}",AuditAction::ApiTokenCreated.as_str().as_bytes());
println!("as_str/ApiTokenRevoked\t{:?}",AuditAction::ApiTokenRevoked.as_str().as_bytes());
println!("as_str/UserCreated\t{:?}",AuditAction::UserCreated.as_str().as_bytes());
println!("as_str/UserUpdated\t{:?}",AuditAction::UserUpdated.as_str().as_bytes());
println!("as_str/UserDeleted\t{:?}",AuditAction::UserDeleted.as_str().as_bytes());
println!("as_str/UserDisabled\t{:?}",AuditAction::UserDisabled.as_str().as_bytes());
println!("as_str/RoleAssigned\t{:?}",AuditAction::RoleAssigned.as_str().as_bytes());
println!("as_str/RoleRevoked\t{:?}",AuditAction::RoleRevoked.as_str().as_bytes());
println!("as_str/RepositoryCreated\t{:?}",AuditAction::RepositoryCreated.as_str().as_bytes());
println!("as_str/RepositoryUpdated\t{:?}",AuditAction::RepositoryUpdated.as_str().as_bytes());
println!("as_str/RepositoryDeleted\t{:?}",AuditAction::RepositoryDeleted.as_str().as_bytes());
println!("as_str/RepositoryPermissionChanged\t{:?}",AuditAction::RepositoryPermissionChanged.as_str().as_bytes());
println!("as_str/ArtifactUploaded\t{:?}",AuditAction::ArtifactUploaded.as_str().as_bytes());
println!("as_str/ArtifactDownloaded\t{:?}",AuditAction::ArtifactDownloaded.as_str().as_bytes());
println!("as_str/ArtifactDeleted\t{:?}",AuditAction::ArtifactDeleted.as_str().as_bytes());
println!("as_str/ArtifactMetadataUpdated\t{:?}",AuditAction::ArtifactMetadataUpdated.as_str().as_bytes());
println!("as_str/BackupStarted\t{:?}",AuditAction::BackupStarted.as_str().as_bytes());
println!("as_str/BackupCompleted\t{:?}",AuditAction::BackupCompleted.as_str().as_bytes());
println!("as_str/BackupFailed\t{:?}",AuditAction::BackupFailed.as_str().as_bytes());
println!("as_str/RestoreStarted\t{:?}",AuditAction::RestoreStarted.as_str().as_bytes());
println!("as_str/RestoreCompleted\t{:?}",AuditAction::RestoreCompleted.as_str().as_bytes());
println!("as_str/RestoreFailed\t{:?}",AuditAction::RestoreFailed.as_str().as_bytes());
println!("as_str/PeerRegistered\t{:?}",AuditAction::PeerRegistered.as_str().as_bytes());
println!("as_str/PeerUnregistered\t{:?}",AuditAction::PeerUnregistered.as_str().as_bytes());
println!("as_str/PeerSyncStarted\t{:?}",AuditAction::PeerSyncStarted.as_str().as_bytes());
println!("as_str/PeerSyncCompleted\t{:?}",AuditAction::PeerSyncCompleted.as_str().as_bytes());
println!("as_str/SettingChanged\t{:?}",AuditAction::SettingChanged.as_str().as_bytes());
println!("as_str/PluginInstalled\t{:?}",AuditAction::PluginInstalled.as_str().as_bytes());
println!("as_str/PluginUninstalled\t{:?}",AuditAction::PluginUninstalled.as_str().as_bytes());
println!("as_str/PluginEnabled\t{:?}",AuditAction::PluginEnabled.as_str().as_bytes());
println!("as_str/PluginDisabled\t{:?}",AuditAction::PluginDisabled.as_str().as_bytes());
println!("as_str/EmailSubscriptionCreated\t{:?}",AuditAction::EmailSubscriptionCreated.as_str().as_bytes());
println!("as_str/EmailSubscriptionDeleted\t{:?}",AuditAction::EmailSubscriptionDeleted.as_str().as_bytes());
println!("as_str/SbomGenerated\t{:?}",AuditAction::SbomGenerated.as_str().as_bytes());
println!("as_str/SbomRead\t{:?}",AuditAction::SbomRead.as_str().as_bytes());
println!("as_str/ScanReaped\t{:?}",AuditAction::ScanReaped.as_str().as_bytes());
println!("as_str/TotpEnabled\t{:?}",AuditAction::TotpEnabled.as_str().as_bytes());
println!("as_str/TotpDisabled\t{:?}",AuditAction::TotpDisabled.as_str().as_bytes());
println!("as_str/SessionsInvalidated\t{:?}",AuditAction::SessionsInvalidated.as_str().as_bytes());
println!("as_str/TotpEnrollmentRequired\t{:?}",AuditAction::TotpEnrollmentRequired.as_str().as_bytes());
println!("as_str/TotpPolicyChanged\t{:?}",AuditAction::TotpPolicyChanged.as_str().as_bytes());
println!("as_str/ApiTokenPolicyChanged\t{:?}",AuditAction::ApiTokenPolicyChanged.as_str().as_bytes());
println!("as_str/AgeGateQueued\t{:?}",AuditAction::AgeGateQueued.as_str().as_bytes());
println!("as_str/AgeGateApproved\t{:?}",AuditAction::AgeGateApproved.as_str().as_bytes());
println!("as_str/AgeGateRejected\t{:?}",AuditAction::AgeGateRejected.as_str().as_bytes());
println!("as_str/AgeGateReopened\t{:?}",AuditAction::AgeGateReopened.as_str().as_bytes());
println!("as_str/PermissionDenied\t{:?}",AuditAction::PermissionDenied.as_str().as_bytes());
println!("as_str/CurationSyncTriggered\t{:?}",AuditAction::CurationSyncTriggered.as_str().as_bytes());
println!("as_str/CurationVersionCreated\t{:?}",AuditAction::CurationVersionCreated.as_str().as_bytes());
println!("as_str/CurationVersionPublished\t{:?}",AuditAction::CurationVersionPublished.as_str().as_bytes());
println!("as_str/ProxyScanVerdictDeleted\t{:?}",AuditAction::ProxyScanVerdictDeleted.as_str().as_bytes());
println!("as_str/CiOidcGroupBindingReconciled\t{:?}",AuditAction::CiOidcGroupBindingReconciled.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(AuditAction::Login.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::Login.as_str(),"audit_action_3ef0ea8f/as_str/Login");
assert_eq!(AuditAction::Logout.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::Logout.as_str(),"audit_action_3ef0ea8f/as_str/Logout");
assert_eq!(AuditAction::LoginFailed.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::LoginFailed.as_str(),"audit_action_3ef0ea8f/as_str/LoginFailed");
assert_eq!(AuditAction::PasswordChanged.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::PasswordChanged.as_str(),"audit_action_3ef0ea8f/as_str/PasswordChanged");
assert_eq!(AuditAction::ApiTokenCreated.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::ApiTokenCreated.as_str(),"audit_action_3ef0ea8f/as_str/ApiTokenCreated");
assert_eq!(AuditAction::ApiTokenRevoked.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::ApiTokenRevoked.as_str(),"audit_action_3ef0ea8f/as_str/ApiTokenRevoked");
assert_eq!(AuditAction::UserCreated.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::UserCreated.as_str(),"audit_action_3ef0ea8f/as_str/UserCreated");
assert_eq!(AuditAction::UserUpdated.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::UserUpdated.as_str(),"audit_action_3ef0ea8f/as_str/UserUpdated");
assert_eq!(AuditAction::UserDeleted.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::UserDeleted.as_str(),"audit_action_3ef0ea8f/as_str/UserDeleted");
assert_eq!(AuditAction::UserDisabled.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::UserDisabled.as_str(),"audit_action_3ef0ea8f/as_str/UserDisabled");
assert_eq!(AuditAction::RoleAssigned.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::RoleAssigned.as_str(),"audit_action_3ef0ea8f/as_str/RoleAssigned");
assert_eq!(AuditAction::RoleRevoked.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::RoleRevoked.as_str(),"audit_action_3ef0ea8f/as_str/RoleRevoked");
assert_eq!(AuditAction::RepositoryCreated.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::RepositoryCreated.as_str(),"audit_action_3ef0ea8f/as_str/RepositoryCreated");
assert_eq!(AuditAction::RepositoryUpdated.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::RepositoryUpdated.as_str(),"audit_action_3ef0ea8f/as_str/RepositoryUpdated");
assert_eq!(AuditAction::RepositoryDeleted.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::RepositoryDeleted.as_str(),"audit_action_3ef0ea8f/as_str/RepositoryDeleted");
assert_eq!(AuditAction::RepositoryPermissionChanged.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::RepositoryPermissionChanged.as_str(),"audit_action_3ef0ea8f/as_str/RepositoryPermissionChanged");
assert_eq!(AuditAction::ArtifactUploaded.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::ArtifactUploaded.as_str(),"audit_action_3ef0ea8f/as_str/ArtifactUploaded");
assert_eq!(AuditAction::ArtifactDownloaded.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::ArtifactDownloaded.as_str(),"audit_action_3ef0ea8f/as_str/ArtifactDownloaded");
assert_eq!(AuditAction::ArtifactDeleted.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::ArtifactDeleted.as_str(),"audit_action_3ef0ea8f/as_str/ArtifactDeleted");
assert_eq!(AuditAction::ArtifactMetadataUpdated.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::ArtifactMetadataUpdated.as_str(),"audit_action_3ef0ea8f/as_str/ArtifactMetadataUpdated");
assert_eq!(AuditAction::BackupStarted.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::BackupStarted.as_str(),"audit_action_3ef0ea8f/as_str/BackupStarted");
assert_eq!(AuditAction::BackupCompleted.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::BackupCompleted.as_str(),"audit_action_3ef0ea8f/as_str/BackupCompleted");
assert_eq!(AuditAction::BackupFailed.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::BackupFailed.as_str(),"audit_action_3ef0ea8f/as_str/BackupFailed");
assert_eq!(AuditAction::RestoreStarted.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::RestoreStarted.as_str(),"audit_action_3ef0ea8f/as_str/RestoreStarted");
assert_eq!(AuditAction::RestoreCompleted.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::RestoreCompleted.as_str(),"audit_action_3ef0ea8f/as_str/RestoreCompleted");
assert_eq!(AuditAction::RestoreFailed.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::RestoreFailed.as_str(),"audit_action_3ef0ea8f/as_str/RestoreFailed");
assert_eq!(AuditAction::PeerRegistered.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::PeerRegistered.as_str(),"audit_action_3ef0ea8f/as_str/PeerRegistered");
assert_eq!(AuditAction::PeerUnregistered.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::PeerUnregistered.as_str(),"audit_action_3ef0ea8f/as_str/PeerUnregistered");
assert_eq!(AuditAction::PeerSyncStarted.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::PeerSyncStarted.as_str(),"audit_action_3ef0ea8f/as_str/PeerSyncStarted");
assert_eq!(AuditAction::PeerSyncCompleted.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::PeerSyncCompleted.as_str(),"audit_action_3ef0ea8f/as_str/PeerSyncCompleted");
assert_eq!(AuditAction::SettingChanged.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::SettingChanged.as_str(),"audit_action_3ef0ea8f/as_str/SettingChanged");
assert_eq!(AuditAction::PluginInstalled.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::PluginInstalled.as_str(),"audit_action_3ef0ea8f/as_str/PluginInstalled");
assert_eq!(AuditAction::PluginUninstalled.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::PluginUninstalled.as_str(),"audit_action_3ef0ea8f/as_str/PluginUninstalled");
assert_eq!(AuditAction::PluginEnabled.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::PluginEnabled.as_str(),"audit_action_3ef0ea8f/as_str/PluginEnabled");
assert_eq!(AuditAction::PluginDisabled.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::PluginDisabled.as_str(),"audit_action_3ef0ea8f/as_str/PluginDisabled");
assert_eq!(AuditAction::EmailSubscriptionCreated.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::EmailSubscriptionCreated.as_str(),"audit_action_3ef0ea8f/as_str/EmailSubscriptionCreated");
assert_eq!(AuditAction::EmailSubscriptionDeleted.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::EmailSubscriptionDeleted.as_str(),"audit_action_3ef0ea8f/as_str/EmailSubscriptionDeleted");
assert_eq!(AuditAction::SbomGenerated.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::SbomGenerated.as_str(),"audit_action_3ef0ea8f/as_str/SbomGenerated");
assert_eq!(AuditAction::SbomRead.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::SbomRead.as_str(),"audit_action_3ef0ea8f/as_str/SbomRead");
assert_eq!(AuditAction::ScanReaped.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::ScanReaped.as_str(),"audit_action_3ef0ea8f/as_str/ScanReaped");
assert_eq!(AuditAction::TotpEnabled.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::TotpEnabled.as_str(),"audit_action_3ef0ea8f/as_str/TotpEnabled");
assert_eq!(AuditAction::TotpDisabled.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::TotpDisabled.as_str(),"audit_action_3ef0ea8f/as_str/TotpDisabled");
assert_eq!(AuditAction::SessionsInvalidated.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::SessionsInvalidated.as_str(),"audit_action_3ef0ea8f/as_str/SessionsInvalidated");
assert_eq!(AuditAction::TotpEnrollmentRequired.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::TotpEnrollmentRequired.as_str(),"audit_action_3ef0ea8f/as_str/TotpEnrollmentRequired");
assert_eq!(AuditAction::TotpPolicyChanged.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::TotpPolicyChanged.as_str(),"audit_action_3ef0ea8f/as_str/TotpPolicyChanged");
assert_eq!(AuditAction::ApiTokenPolicyChanged.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::ApiTokenPolicyChanged.as_str(),"audit_action_3ef0ea8f/as_str/ApiTokenPolicyChanged");
assert_eq!(AuditAction::AgeGateQueued.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::AgeGateQueued.as_str(),"audit_action_3ef0ea8f/as_str/AgeGateQueued");
assert_eq!(AuditAction::AgeGateApproved.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::AgeGateApproved.as_str(),"audit_action_3ef0ea8f/as_str/AgeGateApproved");
assert_eq!(AuditAction::AgeGateRejected.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::AgeGateRejected.as_str(),"audit_action_3ef0ea8f/as_str/AgeGateRejected");
assert_eq!(AuditAction::AgeGateReopened.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::AgeGateReopened.as_str(),"audit_action_3ef0ea8f/as_str/AgeGateReopened");
assert_eq!(AuditAction::PermissionDenied.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::PermissionDenied.as_str(),"audit_action_3ef0ea8f/as_str/PermissionDenied");
assert_eq!(AuditAction::CurationSyncTriggered.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::CurationSyncTriggered.as_str(),"audit_action_3ef0ea8f/as_str/CurationSyncTriggered");
assert_eq!(AuditAction::CurationVersionCreated.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::CurationVersionCreated.as_str(),"audit_action_3ef0ea8f/as_str/CurationVersionCreated");
assert_eq!(AuditAction::CurationVersionPublished.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::CurationVersionPublished.as_str(),"audit_action_3ef0ea8f/as_str/CurationVersionPublished");
assert_eq!(AuditAction::ProxyScanVerdictDeleted.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::ProxyScanVerdictDeleted.as_str(),"audit_action_3ef0ea8f/as_str/ProxyScanVerdictDeleted");
assert_eq!(AuditAction::CiOidcGroupBindingReconciled.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_action_3ef0ea8f::AuditAction::CiOidcGroupBindingReconciled.as_str(),"audit_action_3ef0ea8f/as_str/CiOidcGroupBindingReconciled");
}
