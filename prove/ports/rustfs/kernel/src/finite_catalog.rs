//! Exhaustive finite enum decisions; see DEVIATIONS.md.
pub mod admin_action_dfb862e5 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AdminAction {HealAdminAction,DecommissionAdminAction,RebalanceAdminAction,StorageInfoAdminAction,PrometheusAdminAction,DataUsageInfoAdminAction,ForceUnlockAdminAction,TopLocksAdminAction,ProfilingAdminAction,TraceAdminAction,ConsoleLogAdminAction,ServerInfoAdminAction,HealthInfoAdminAction,LicenseInfoAdminAction,BandwidthMonitorAction,InspectDataAction,ServerUpdateAdminAction,ServiceRestartAdminAction,ServiceStopAdminAction,ServiceFreezeAdminAction,ConfigUpdateAdminAction,CreateUserAdminAction,DeleteUserAdminAction,ListUsersAdminAction,EnableUserAdminAction,DisableUserAdminAction,GetUserAdminAction,SiteReplicationAddAction,SiteReplicationDisableAction,SiteReplicationRemoveAction,SiteReplicationResyncAction,SiteReplicationInfoAction,SiteReplicationOperationAction,CreateServiceAccountAdminAction,UpdateServiceAccountAdminAction,RemoveServiceAccountAdminAction,ListServiceAccountsAdminAction,ListTemporaryAccountsAdminAction,AddUserToGroupAdminAction,RemoveUserFromGroupAdminAction,GetGroupAdminAction,ListGroupsAdminAction,EnableGroupAdminAction,DisableGroupAdminAction,CreatePolicyAdminAction,DeletePolicyAdminAction,GetPolicyAdminAction,AttachPolicyAdminAction,UpdatePolicyAssociationAction,ListUserPoliciesAdminAction,SetBucketQuotaAdminAction,SetBucketTargetAction,GetBucketTargetAction,SetBucketOnDemandMigrationAction,GetBucketOnDemandMigrationAction,GetMetricsAction,ReplicationDiff,GetReplicationMetricsAction,ImportBucketMetadataAction,ExportBucketMetadataAction,GetTableCatalogAction,MigrateTableCatalogAction,GetTableBucketAction,SetTableBucketAction,GetTableNamespaceAction,SetTableNamespaceAction,UpdateTableNamespacePropertiesAction,DeleteTableNamespaceAction,GetTableAction,SetTableAction,CreateTableAction,RegisterTableAction,CommitTableAction,DeleteTableAction,GetTableLifecycleAction,SetTableLifecycleAction,GetTableCredentialsAction,RunTableMaintenanceAction,GetTableMetadataLocationAction,SetTableMetadataLocationAction,GetTableMetadataAction,SetTableMetadataAction,SetTierAction,ListTierAction,ExportIAMAction,ImportIAMAction,ListBatchJobsAction,DescribeBatchJobAction,StartBatchJobAction,CancelBatchJobAction,AllAdminActions}
impl AdminAction {
    pub fn is_table_resource_scoped(&self) -> bool {
        matches!(
            self,
            AdminAction::GetTableBucketAction
                | AdminAction::SetTableBucketAction
                | AdminAction::GetTableNamespaceAction
                | AdminAction::SetTableNamespaceAction
                | AdminAction::UpdateTableNamespacePropertiesAction
                | AdminAction::DeleteTableNamespaceAction
                | AdminAction::GetTableAction
                | AdminAction::SetTableAction
                | AdminAction::CreateTableAction
                | AdminAction::RegisterTableAction
                | AdminAction::CommitTableAction
                | AdminAction::DeleteTableAction
                | AdminAction::GetTableLifecycleAction
                | AdminAction::SetTableLifecycleAction
                | AdminAction::GetTableCredentialsAction
                | AdminAction::RunTableMaintenanceAction
                | AdminAction::GetTableMetadataLocationAction
                | AdminAction::SetTableMetadataLocationAction
                | AdminAction::GetTableMetadataAction
                | AdminAction::SetTableMetadataAction
        )
    }
    pub fn is_valid(&self) -> bool {
        matches!(
            self,
            AdminAction::HealAdminAction
                | AdminAction::DecommissionAdminAction
                | AdminAction::RebalanceAdminAction
                | AdminAction::StorageInfoAdminAction
                | AdminAction::PrometheusAdminAction
                | AdminAction::DataUsageInfoAdminAction
                | AdminAction::ForceUnlockAdminAction
                | AdminAction::TopLocksAdminAction
                | AdminAction::ProfilingAdminAction
                | AdminAction::TraceAdminAction
                | AdminAction::ConsoleLogAdminAction
                | AdminAction::ServerInfoAdminAction
                | AdminAction::HealthInfoAdminAction
                | AdminAction::LicenseInfoAdminAction
                | AdminAction::BandwidthMonitorAction
                | AdminAction::InspectDataAction
                | AdminAction::ServerUpdateAdminAction
                | AdminAction::ServiceRestartAdminAction
                | AdminAction::ServiceStopAdminAction
                | AdminAction::ServiceFreezeAdminAction
                | AdminAction::ConfigUpdateAdminAction
                | AdminAction::CreateUserAdminAction
                | AdminAction::DeleteUserAdminAction
                | AdminAction::ListUsersAdminAction
                | AdminAction::EnableUserAdminAction
                | AdminAction::DisableUserAdminAction
                | AdminAction::GetUserAdminAction
                | AdminAction::SiteReplicationAddAction
                | AdminAction::SiteReplicationDisableAction
                | AdminAction::SiteReplicationRemoveAction
                | AdminAction::SiteReplicationResyncAction
                | AdminAction::SiteReplicationInfoAction
                | AdminAction::SiteReplicationOperationAction
                | AdminAction::CreateServiceAccountAdminAction
                | AdminAction::UpdateServiceAccountAdminAction
                | AdminAction::RemoveServiceAccountAdminAction
                | AdminAction::ListServiceAccountsAdminAction
                | AdminAction::ListTemporaryAccountsAdminAction
                | AdminAction::AddUserToGroupAdminAction
                | AdminAction::RemoveUserFromGroupAdminAction
                | AdminAction::GetGroupAdminAction
                | AdminAction::ListGroupsAdminAction
                | AdminAction::EnableGroupAdminAction
                | AdminAction::DisableGroupAdminAction
                | AdminAction::CreatePolicyAdminAction
                | AdminAction::DeletePolicyAdminAction
                | AdminAction::GetPolicyAdminAction
                | AdminAction::AttachPolicyAdminAction
                | AdminAction::UpdatePolicyAssociationAction
                | AdminAction::ListUserPoliciesAdminAction
                | AdminAction::SetBucketQuotaAdminAction
                | AdminAction::SetBucketTargetAction
                | AdminAction::GetBucketTargetAction
                | AdminAction::SetBucketOnDemandMigrationAction
                | AdminAction::GetBucketOnDemandMigrationAction
                | AdminAction::GetMetricsAction
                | AdminAction::ReplicationDiff
                | AdminAction::GetReplicationMetricsAction
                | AdminAction::ImportBucketMetadataAction
                | AdminAction::ExportBucketMetadataAction
                | AdminAction::GetTableCatalogAction
                | AdminAction::MigrateTableCatalogAction
                | AdminAction::GetTableBucketAction
                | AdminAction::SetTableBucketAction
                | AdminAction::GetTableNamespaceAction
                | AdminAction::SetTableNamespaceAction
                | AdminAction::UpdateTableNamespacePropertiesAction
                | AdminAction::DeleteTableNamespaceAction
                | AdminAction::GetTableAction
                | AdminAction::SetTableAction
                | AdminAction::CreateTableAction
                | AdminAction::RegisterTableAction
                | AdminAction::CommitTableAction
                | AdminAction::DeleteTableAction
                | AdminAction::GetTableLifecycleAction
                | AdminAction::SetTableLifecycleAction
                | AdminAction::GetTableCredentialsAction
                | AdminAction::RunTableMaintenanceAction
                | AdminAction::GetTableMetadataLocationAction
                | AdminAction::SetTableMetadataLocationAction
                | AdminAction::GetTableMetadataAction
                | AdminAction::SetTableMetadataAction
                | AdminAction::SetTierAction
                | AdminAction::ListTierAction
                | AdminAction::ExportIAMAction
                | AdminAction::ImportIAMAction
                | AdminAction::ListBatchJobsAction
                | AdminAction::DescribeBatchJobAction
                | AdminAction::StartBatchJobAction
                | AdminAction::CancelBatchJobAction
                | AdminAction::AllAdminActions
        )
    }
}
}
