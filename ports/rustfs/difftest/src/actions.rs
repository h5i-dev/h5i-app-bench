use crate::tests::*;
use rustfs_kernel::{
    acts::{Action, Family},
    actsets as k,
};
use rustfs_policy::policy::{
    ActionSet, Validator,
    action::{Action as U, AdminAction, KmsAction, S3Action, StsAction},
};

#[test]
fn action_tables_agree() {
    let variants = vec![
        U::S3Action(S3Action::AllActions),
        U::S3Action(S3Action::AbortMultipartUploadAction),
        U::S3Action(S3Action::CreateBucketAction),
        U::S3Action(S3Action::DeleteBucketAction),
        U::S3Action(S3Action::ForceDeleteBucketAction),
        U::S3Action(S3Action::ForceDeleteObjectAction),
        U::S3Action(S3Action::DeleteBucketPolicyAction),
        U::S3Action(S3Action::DeleteBucketPublicAccessBlockAction),
        U::S3Action(S3Action::DeleteBucketCorsAction),
        U::S3Action(S3Action::DeleteObjectAction),
        U::S3Action(S3Action::GetBucketLocationAction),
        U::S3Action(S3Action::GetBucketNotificationAction),
        U::S3Action(S3Action::GetBucketPolicyAction),
        U::S3Action(S3Action::GetBucketPublicAccessBlockAction),
        U::S3Action(S3Action::GetBucketCorsAction),
        U::S3Action(S3Action::GetBucketAclAction),
        U::S3Action(S3Action::PutBucketAclAction),
        U::S3Action(S3Action::GetObjectAction),
        U::S3Action(S3Action::GetObjectAclAction),
        U::S3Action(S3Action::GetObjectAttributesAction),
        U::S3Action(S3Action::HeadBucketAction),
        U::S3Action(S3Action::ListAllMyBucketsAction),
        U::S3Action(S3Action::ListBucketAction),
        U::S3Action(S3Action::GetBucketPolicyStatusAction),
        U::S3Action(S3Action::ListBucketVersionsAction),
        U::S3Action(S3Action::ListBucketMultipartUploadsAction),
        U::S3Action(S3Action::ListenNotificationAction),
        U::S3Action(S3Action::ListenBucketNotificationAction),
        U::S3Action(S3Action::ListMultipartUploadPartsAction),
        U::S3Action(S3Action::PutBucketLifecycleAction),
        U::S3Action(S3Action::GetBucketLifecycleAction),
        U::S3Action(S3Action::PutBucketLoggingAction),
        U::S3Action(S3Action::GetBucketLoggingAction),
        U::S3Action(S3Action::PutBucketNotificationAction),
        U::S3Action(S3Action::PutBucketPolicyAction),
        U::S3Action(S3Action::PutBucketPublicAccessBlockAction),
        U::S3Action(S3Action::PutBucketCorsAction),
        U::S3Action(S3Action::PutObjectAction),
        U::S3Action(S3Action::PutObjectAclAction),
        U::S3Action(S3Action::DeleteObjectVersionAction),
        U::S3Action(S3Action::DeleteObjectVersionTaggingAction),
        U::S3Action(S3Action::GetObjectVersionAction),
        U::S3Action(S3Action::GetObjectVersionAttributesAction),
        U::S3Action(S3Action::GetObjectVersionTaggingAction),
        U::S3Action(S3Action::PutObjectVersionTaggingAction),
        U::S3Action(S3Action::BypassGovernanceRetentionAction),
        U::S3Action(S3Action::PutObjectRetentionAction),
        U::S3Action(S3Action::GetObjectRetentionAction),
        U::S3Action(S3Action::GetObjectLegalHoldAction),
        U::S3Action(S3Action::PutObjectLegalHoldAction),
        U::S3Action(S3Action::GetBucketObjectLockConfigurationAction),
        U::S3Action(S3Action::PutBucketObjectLockConfigurationAction),
        U::S3Action(S3Action::GetBucketTaggingAction),
        U::S3Action(S3Action::PutBucketTaggingAction),
        U::S3Action(S3Action::GetObjectTaggingAction),
        U::S3Action(S3Action::PutObjectTaggingAction),
        U::S3Action(S3Action::DeleteObjectTaggingAction),
        U::S3Action(S3Action::PutBucketEncryptionAction),
        U::S3Action(S3Action::GetBucketEncryptionAction),
        U::S3Action(S3Action::PutBucketVersioningAction),
        U::S3Action(S3Action::GetBucketVersioningAction),
        U::S3Action(S3Action::GetReplicationConfigurationAction),
        U::S3Action(S3Action::PutReplicationConfigurationAction),
        U::S3Action(S3Action::ReplicateObjectAction),
        U::S3Action(S3Action::ReplicateDeleteAction),
        U::S3Action(S3Action::ReplicateTagsAction),
        U::S3Action(S3Action::GetObjectVersionForReplicationAction),
        U::S3Action(S3Action::RestoreObjectAction),
        U::S3Action(S3Action::ResetBucketReplicationStateAction),
        U::S3Action(S3Action::PutObjectFanOutAction),
        U::S3Action(S3Action::GetBucketQuotaAction),
    ];
    assert_eq!(k::action_count(Family::S3), variants.len());
    for (i, a) in variants.iter().enumerate() {
        assert_eq!(k::action_name(Family::S3, i), b(<&str>::from(a)));
        assert!(k::contains_name(Family::S3, <&str>::from(a).as_bytes()));
    }
    assert!(k::action_name(Family::S3, variants.len()).is_empty());
    let variants = vec![
        U::AdminAction(AdminAction::HealAdminAction),
        U::AdminAction(AdminAction::DecommissionAdminAction),
        U::AdminAction(AdminAction::RebalanceAdminAction),
        U::AdminAction(AdminAction::StorageInfoAdminAction),
        U::AdminAction(AdminAction::PrometheusAdminAction),
        U::AdminAction(AdminAction::DataUsageInfoAdminAction),
        U::AdminAction(AdminAction::ForceUnlockAdminAction),
        U::AdminAction(AdminAction::TopLocksAdminAction),
        U::AdminAction(AdminAction::ProfilingAdminAction),
        U::AdminAction(AdminAction::TraceAdminAction),
        U::AdminAction(AdminAction::ConsoleLogAdminAction),
        U::AdminAction(AdminAction::ServerInfoAdminAction),
        U::AdminAction(AdminAction::HealthInfoAdminAction),
        U::AdminAction(AdminAction::LicenseInfoAdminAction),
        U::AdminAction(AdminAction::BandwidthMonitorAction),
        U::AdminAction(AdminAction::InspectDataAction),
        U::AdminAction(AdminAction::ServerUpdateAdminAction),
        U::AdminAction(AdminAction::ServiceRestartAdminAction),
        U::AdminAction(AdminAction::ServiceStopAdminAction),
        U::AdminAction(AdminAction::ServiceFreezeAdminAction),
        U::AdminAction(AdminAction::ConfigUpdateAdminAction),
        U::AdminAction(AdminAction::CreateUserAdminAction),
        U::AdminAction(AdminAction::DeleteUserAdminAction),
        U::AdminAction(AdminAction::ListUsersAdminAction),
        U::AdminAction(AdminAction::EnableUserAdminAction),
        U::AdminAction(AdminAction::DisableUserAdminAction),
        U::AdminAction(AdminAction::GetUserAdminAction),
        U::AdminAction(AdminAction::SiteReplicationAddAction),
        U::AdminAction(AdminAction::SiteReplicationDisableAction),
        U::AdminAction(AdminAction::SiteReplicationRemoveAction),
        U::AdminAction(AdminAction::SiteReplicationResyncAction),
        U::AdminAction(AdminAction::SiteReplicationInfoAction),
        U::AdminAction(AdminAction::SiteReplicationOperationAction),
        U::AdminAction(AdminAction::CreateServiceAccountAdminAction),
        U::AdminAction(AdminAction::UpdateServiceAccountAdminAction),
        U::AdminAction(AdminAction::RemoveServiceAccountAdminAction),
        U::AdminAction(AdminAction::ListServiceAccountsAdminAction),
        U::AdminAction(AdminAction::ListTemporaryAccountsAdminAction),
        U::AdminAction(AdminAction::AddUserToGroupAdminAction),
        U::AdminAction(AdminAction::RemoveUserFromGroupAdminAction),
        U::AdminAction(AdminAction::GetGroupAdminAction),
        U::AdminAction(AdminAction::ListGroupsAdminAction),
        U::AdminAction(AdminAction::EnableGroupAdminAction),
        U::AdminAction(AdminAction::DisableGroupAdminAction),
        U::AdminAction(AdminAction::CreatePolicyAdminAction),
        U::AdminAction(AdminAction::DeletePolicyAdminAction),
        U::AdminAction(AdminAction::GetPolicyAdminAction),
        U::AdminAction(AdminAction::AttachPolicyAdminAction),
        U::AdminAction(AdminAction::UpdatePolicyAssociationAction),
        U::AdminAction(AdminAction::ListUserPoliciesAdminAction),
        U::AdminAction(AdminAction::SetBucketQuotaAdminAction),
        U::AdminAction(AdminAction::SetBucketTargetAction),
        U::AdminAction(AdminAction::GetBucketTargetAction),
        U::AdminAction(AdminAction::SetBucketOnDemandMigrationAction),
        U::AdminAction(AdminAction::GetBucketOnDemandMigrationAction),
        U::AdminAction(AdminAction::GetMetricsAction),
        U::AdminAction(AdminAction::ReplicationDiff),
        U::AdminAction(AdminAction::GetReplicationMetricsAction),
        U::AdminAction(AdminAction::ImportBucketMetadataAction),
        U::AdminAction(AdminAction::ExportBucketMetadataAction),
        U::AdminAction(AdminAction::GetTableCatalogAction),
        U::AdminAction(AdminAction::MigrateTableCatalogAction),
        U::AdminAction(AdminAction::GetTableBucketAction),
        U::AdminAction(AdminAction::SetTableBucketAction),
        U::AdminAction(AdminAction::GetTableNamespaceAction),
        U::AdminAction(AdminAction::SetTableNamespaceAction),
        U::AdminAction(AdminAction::UpdateTableNamespacePropertiesAction),
        U::AdminAction(AdminAction::DeleteTableNamespaceAction),
        U::AdminAction(AdminAction::GetTableAction),
        U::AdminAction(AdminAction::SetTableAction),
        U::AdminAction(AdminAction::CreateTableAction),
        U::AdminAction(AdminAction::RegisterTableAction),
        U::AdminAction(AdminAction::CommitTableAction),
        U::AdminAction(AdminAction::DeleteTableAction),
        U::AdminAction(AdminAction::GetTableLifecycleAction),
        U::AdminAction(AdminAction::SetTableLifecycleAction),
        U::AdminAction(AdminAction::GetTableCredentialsAction),
        U::AdminAction(AdminAction::RunTableMaintenanceAction),
        U::AdminAction(AdminAction::GetTableMetadataLocationAction),
        U::AdminAction(AdminAction::SetTableMetadataLocationAction),
        U::AdminAction(AdminAction::GetTableMetadataAction),
        U::AdminAction(AdminAction::SetTableMetadataAction),
        U::AdminAction(AdminAction::SetTierAction),
        U::AdminAction(AdminAction::ListTierAction),
        U::AdminAction(AdminAction::ExportIAMAction),
        U::AdminAction(AdminAction::ImportIAMAction),
        U::AdminAction(AdminAction::ListBatchJobsAction),
        U::AdminAction(AdminAction::DescribeBatchJobAction),
        U::AdminAction(AdminAction::StartBatchJobAction),
        U::AdminAction(AdminAction::CancelBatchJobAction),
        U::AdminAction(AdminAction::AllAdminActions),
    ];
    assert_eq!(k::action_count(Family::Admin), variants.len());
    for (i, a) in variants.iter().enumerate() {
        assert_eq!(k::action_name(Family::Admin, i), b(<&str>::from(a)));
        assert!(k::contains_name(Family::Admin, <&str>::from(a).as_bytes()));
        if let U::AdminAction(a) = a {
            assert_eq!(k::admin_is_valid(<&str>::from(a).as_bytes()), a.is_valid());
        }
    }
    assert!(k::action_name(Family::Admin, variants.len()).is_empty());
    let variants = vec![
        U::StsAction(StsAction::AllActions),
        U::StsAction(StsAction::AssumeRoleAction),
    ];
    assert_eq!(k::action_count(Family::Sts), variants.len());
    for (i, a) in variants.iter().enumerate() {
        assert_eq!(k::action_name(Family::Sts, i), b(<&str>::from(a)));
        assert!(k::contains_name(Family::Sts, <&str>::from(a).as_bytes()));
    }
    assert!(k::action_name(Family::Sts, variants.len()).is_empty());
    let variants = vec![
        U::KmsAction(KmsAction::AllActions),
        U::KmsAction(KmsAction::ConfigureAction),
        U::KmsAction(KmsAction::ServiceControlAction),
        U::KmsAction(KmsAction::ClearCacheAction),
        U::KmsAction(KmsAction::GenerateDataKeyAction),
        U::KmsAction(KmsAction::DeleteKeyAction),
        U::KmsAction(KmsAction::EnableKeyAction),
        U::KmsAction(KmsAction::DisableKeyAction),
        U::KmsAction(KmsAction::RotateKeyAction),
        U::KmsAction(KmsAction::UpdateKeyDescriptionAction),
        U::KmsAction(KmsAction::TagResourceAction),
        U::KmsAction(KmsAction::UntagResourceAction),
        U::KmsAction(KmsAction::ListKeysAction),
        U::KmsAction(KmsAction::DescribeKeyAction),
        U::KmsAction(KmsAction::DecryptAction),
        U::KmsAction(KmsAction::BackupAction),
        U::KmsAction(KmsAction::RestoreAction),
        U::KmsAction(KmsAction::RekeyAction),
    ];
    assert_eq!(k::action_count(Family::Kms), variants.len());
    for (i, a) in variants.iter().enumerate() {
        assert_eq!(k::action_name(Family::Kms, i), b(<&str>::from(a)));
        assert!(k::contains_name(Family::Kms, <&str>::from(a).as_bytes()));
    }
    assert!(k::action_name(Family::Kms, variants.len()).is_empty());
    assert_eq!(k::action_count(Family::None), 0);
    assert!(k::action_name(Family::None, 0).is_empty());
    let mut rng = Rng(897);
    for _ in 0..3000 {
        let name = String::from_utf8(
            (0..rng.below(24))
                .map(|_| *rng.pick(b"s3:admin*KMSGetObjectx"))
                .collect(),
        )
        .unwrap();
        for f in [Family::S3, Family::Admin, Family::Sts, Family::Kms] {
            let valid = match f {
                Family::S3 => S3Action::try_from(name.as_str()).is_ok(),
                Family::Admin => AdminAction::try_from(name.as_str()).is_ok(),
                Family::Sts => StsAction::try_from(name.as_str()).is_ok(),
                Family::Kms => KmsAction::try_from(name.as_str()).is_ok(),
                Family::None => false,
            };
            assert_eq!(k::contains_name(f, name.as_bytes()), valid, "{name}");
        }
        assert_eq!(
            k::admin_is_valid(name.as_bytes()),
            AdminAction::try_from(name.as_str()).is_ok()
        );
    }
}

#[test]
fn action_sets_agree() {
    let mut rng = Rng(898);
    for _ in 0..5000 {
        let draw = |rng: &mut Rng| {
            if rng.chance(10) {
                U::None
            } else {
                U::try_from(*rng.pick(ACTIONS)).unwrap()
            }
        };
        let up = ActionSet((0..rng.below(9)).map(|_| draw(&mut rng)).collect());
        let other = ActionSet((0..rng.below(9)).map(|_| draw(&mut rng)).collect());
        let port = up.0.iter().map(kaction).collect::<Vec<_>>();
        let right = other.0.iter().map(kaction).collect::<Vec<_>>();
        assert_eq!(k::is_empty(&port), up.is_empty());
        assert_eq!(k::as_slice(&port), port.as_slice());
        assert_eq!(k::is_valid(&port), up.is_valid().is_ok());
        assert_eq!(k::eq(&port, &right), up == other);
        let mut rev = port.clone();
        rev.reverse();
        rev.extend(port.clone());
        assert!(k::eq(&port, &rev));
        let a = draw(&mut rng);
        assert_eq!(k::set_is_match(&port, &kaction(&a)), up.is_match(&a));
        for this in &up.0 {
            assert_eq!(
                k::action_is_match(&kaction(this), &kaction(&a)),
                this.is_match(&a)
            );
        }
        let mut dedup = Vec::<Action>::new();
        for a in &port {
            k::push_unique(&mut dedup, a.clone());
        }
        let mut expected = Vec::new();
        for a in &up.0 {
            if !expected.contains(a) {
                expected.push(*a);
            }
        }
        assert_eq!(dedup, expected.iter().map(kaction).collect::<Vec<_>>());
    }
}
