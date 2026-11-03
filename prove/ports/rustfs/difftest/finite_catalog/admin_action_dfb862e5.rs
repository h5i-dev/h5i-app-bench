#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AdminAction {HealAdminAction,DecommissionAdminAction,RebalanceAdminAction,StorageInfoAdminAction,PrometheusAdminAction,DataUsageInfoAdminAction,ForceUnlockAdminAction,TopLocksAdminAction,ProfilingAdminAction,TraceAdminAction,ConsoleLogAdminAction,ServerInfoAdminAction,HealthInfoAdminAction,LicenseInfoAdminAction,BandwidthMonitorAction,InspectDataAction,ServerUpdateAdminAction,ServiceRestartAdminAction,ServiceStopAdminAction,ServiceFreezeAdminAction,ConfigUpdateAdminAction,CreateUserAdminAction,DeleteUserAdminAction,ListUsersAdminAction,EnableUserAdminAction,DisableUserAdminAction,GetUserAdminAction,SiteReplicationAddAction,SiteReplicationDisableAction,SiteReplicationRemoveAction,SiteReplicationResyncAction,SiteReplicationInfoAction,SiteReplicationOperationAction,CreateServiceAccountAdminAction,UpdateServiceAccountAdminAction,RemoveServiceAccountAdminAction,ListServiceAccountsAdminAction,ListTemporaryAccountsAdminAction,AddUserToGroupAdminAction,RemoveUserFromGroupAdminAction,GetGroupAdminAction,ListGroupsAdminAction,EnableGroupAdminAction,DisableGroupAdminAction,CreatePolicyAdminAction,DeletePolicyAdminAction,GetPolicyAdminAction,AttachPolicyAdminAction,UpdatePolicyAssociationAction,ListUserPoliciesAdminAction,SetBucketQuotaAdminAction,SetBucketTargetAction,GetBucketTargetAction,SetBucketOnDemandMigrationAction,GetBucketOnDemandMigrationAction,GetMetricsAction,ReplicationDiff,GetReplicationMetricsAction,ImportBucketMetadataAction,ExportBucketMetadataAction,GetTableCatalogAction,MigrateTableCatalogAction,GetTableBucketAction,SetTableBucketAction,GetTableNamespaceAction,SetTableNamespaceAction,UpdateTableNamespacePropertiesAction,DeleteTableNamespaceAction,GetTableAction,SetTableAction,CreateTableAction,RegisterTableAction,CommitTableAction,DeleteTableAction,GetTableLifecycleAction,SetTableLifecycleAction,GetTableCredentialsAction,RunTableMaintenanceAction,GetTableMetadataLocationAction,SetTableMetadataLocationAction,GetTableMetadataAction,SetTableMetadataAction,SetTierAction,ListTierAction,ExportIAMAction,ImportIAMAction,ListBatchJobsAction,DescribeBatchJobAction,StartBatchJobAction,CancelBatchJobAction,AllAdminActions}
impl AdminAction {
    pub(crate) fn is_table_resource_scoped(&self) -> bool {
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
fn main(){
println!("is_table_resource_scoped/HealAdminAction\t{:?}",AdminAction::HealAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/DecommissionAdminAction\t{:?}",AdminAction::DecommissionAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/RebalanceAdminAction\t{:?}",AdminAction::RebalanceAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/StorageInfoAdminAction\t{:?}",AdminAction::StorageInfoAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/PrometheusAdminAction\t{:?}",AdminAction::PrometheusAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/DataUsageInfoAdminAction\t{:?}",AdminAction::DataUsageInfoAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ForceUnlockAdminAction\t{:?}",AdminAction::ForceUnlockAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/TopLocksAdminAction\t{:?}",AdminAction::TopLocksAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ProfilingAdminAction\t{:?}",AdminAction::ProfilingAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/TraceAdminAction\t{:?}",AdminAction::TraceAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ConsoleLogAdminAction\t{:?}",AdminAction::ConsoleLogAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ServerInfoAdminAction\t{:?}",AdminAction::ServerInfoAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/HealthInfoAdminAction\t{:?}",AdminAction::HealthInfoAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/LicenseInfoAdminAction\t{:?}",AdminAction::LicenseInfoAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/BandwidthMonitorAction\t{:?}",AdminAction::BandwidthMonitorAction.is_table_resource_scoped());
println!("is_table_resource_scoped/InspectDataAction\t{:?}",AdminAction::InspectDataAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ServerUpdateAdminAction\t{:?}",AdminAction::ServerUpdateAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ServiceRestartAdminAction\t{:?}",AdminAction::ServiceRestartAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ServiceStopAdminAction\t{:?}",AdminAction::ServiceStopAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ServiceFreezeAdminAction\t{:?}",AdminAction::ServiceFreezeAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ConfigUpdateAdminAction\t{:?}",AdminAction::ConfigUpdateAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/CreateUserAdminAction\t{:?}",AdminAction::CreateUserAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/DeleteUserAdminAction\t{:?}",AdminAction::DeleteUserAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ListUsersAdminAction\t{:?}",AdminAction::ListUsersAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/EnableUserAdminAction\t{:?}",AdminAction::EnableUserAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/DisableUserAdminAction\t{:?}",AdminAction::DisableUserAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/GetUserAdminAction\t{:?}",AdminAction::GetUserAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SiteReplicationAddAction\t{:?}",AdminAction::SiteReplicationAddAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SiteReplicationDisableAction\t{:?}",AdminAction::SiteReplicationDisableAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SiteReplicationRemoveAction\t{:?}",AdminAction::SiteReplicationRemoveAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SiteReplicationResyncAction\t{:?}",AdminAction::SiteReplicationResyncAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SiteReplicationInfoAction\t{:?}",AdminAction::SiteReplicationInfoAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SiteReplicationOperationAction\t{:?}",AdminAction::SiteReplicationOperationAction.is_table_resource_scoped());
println!("is_table_resource_scoped/CreateServiceAccountAdminAction\t{:?}",AdminAction::CreateServiceAccountAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/UpdateServiceAccountAdminAction\t{:?}",AdminAction::UpdateServiceAccountAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/RemoveServiceAccountAdminAction\t{:?}",AdminAction::RemoveServiceAccountAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ListServiceAccountsAdminAction\t{:?}",AdminAction::ListServiceAccountsAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ListTemporaryAccountsAdminAction\t{:?}",AdminAction::ListTemporaryAccountsAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/AddUserToGroupAdminAction\t{:?}",AdminAction::AddUserToGroupAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/RemoveUserFromGroupAdminAction\t{:?}",AdminAction::RemoveUserFromGroupAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/GetGroupAdminAction\t{:?}",AdminAction::GetGroupAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ListGroupsAdminAction\t{:?}",AdminAction::ListGroupsAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/EnableGroupAdminAction\t{:?}",AdminAction::EnableGroupAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/DisableGroupAdminAction\t{:?}",AdminAction::DisableGroupAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/CreatePolicyAdminAction\t{:?}",AdminAction::CreatePolicyAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/DeletePolicyAdminAction\t{:?}",AdminAction::DeletePolicyAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/GetPolicyAdminAction\t{:?}",AdminAction::GetPolicyAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/AttachPolicyAdminAction\t{:?}",AdminAction::AttachPolicyAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/UpdatePolicyAssociationAction\t{:?}",AdminAction::UpdatePolicyAssociationAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ListUserPoliciesAdminAction\t{:?}",AdminAction::ListUserPoliciesAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SetBucketQuotaAdminAction\t{:?}",AdminAction::SetBucketQuotaAdminAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SetBucketTargetAction\t{:?}",AdminAction::SetBucketTargetAction.is_table_resource_scoped());
println!("is_table_resource_scoped/GetBucketTargetAction\t{:?}",AdminAction::GetBucketTargetAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SetBucketOnDemandMigrationAction\t{:?}",AdminAction::SetBucketOnDemandMigrationAction.is_table_resource_scoped());
println!("is_table_resource_scoped/GetBucketOnDemandMigrationAction\t{:?}",AdminAction::GetBucketOnDemandMigrationAction.is_table_resource_scoped());
println!("is_table_resource_scoped/GetMetricsAction\t{:?}",AdminAction::GetMetricsAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ReplicationDiff\t{:?}",AdminAction::ReplicationDiff.is_table_resource_scoped());
println!("is_table_resource_scoped/GetReplicationMetricsAction\t{:?}",AdminAction::GetReplicationMetricsAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ImportBucketMetadataAction\t{:?}",AdminAction::ImportBucketMetadataAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ExportBucketMetadataAction\t{:?}",AdminAction::ExportBucketMetadataAction.is_table_resource_scoped());
println!("is_table_resource_scoped/GetTableCatalogAction\t{:?}",AdminAction::GetTableCatalogAction.is_table_resource_scoped());
println!("is_table_resource_scoped/MigrateTableCatalogAction\t{:?}",AdminAction::MigrateTableCatalogAction.is_table_resource_scoped());
println!("is_table_resource_scoped/GetTableBucketAction\t{:?}",AdminAction::GetTableBucketAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SetTableBucketAction\t{:?}",AdminAction::SetTableBucketAction.is_table_resource_scoped());
println!("is_table_resource_scoped/GetTableNamespaceAction\t{:?}",AdminAction::GetTableNamespaceAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SetTableNamespaceAction\t{:?}",AdminAction::SetTableNamespaceAction.is_table_resource_scoped());
println!("is_table_resource_scoped/UpdateTableNamespacePropertiesAction\t{:?}",AdminAction::UpdateTableNamespacePropertiesAction.is_table_resource_scoped());
println!("is_table_resource_scoped/DeleteTableNamespaceAction\t{:?}",AdminAction::DeleteTableNamespaceAction.is_table_resource_scoped());
println!("is_table_resource_scoped/GetTableAction\t{:?}",AdminAction::GetTableAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SetTableAction\t{:?}",AdminAction::SetTableAction.is_table_resource_scoped());
println!("is_table_resource_scoped/CreateTableAction\t{:?}",AdminAction::CreateTableAction.is_table_resource_scoped());
println!("is_table_resource_scoped/RegisterTableAction\t{:?}",AdminAction::RegisterTableAction.is_table_resource_scoped());
println!("is_table_resource_scoped/CommitTableAction\t{:?}",AdminAction::CommitTableAction.is_table_resource_scoped());
println!("is_table_resource_scoped/DeleteTableAction\t{:?}",AdminAction::DeleteTableAction.is_table_resource_scoped());
println!("is_table_resource_scoped/GetTableLifecycleAction\t{:?}",AdminAction::GetTableLifecycleAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SetTableLifecycleAction\t{:?}",AdminAction::SetTableLifecycleAction.is_table_resource_scoped());
println!("is_table_resource_scoped/GetTableCredentialsAction\t{:?}",AdminAction::GetTableCredentialsAction.is_table_resource_scoped());
println!("is_table_resource_scoped/RunTableMaintenanceAction\t{:?}",AdminAction::RunTableMaintenanceAction.is_table_resource_scoped());
println!("is_table_resource_scoped/GetTableMetadataLocationAction\t{:?}",AdminAction::GetTableMetadataLocationAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SetTableMetadataLocationAction\t{:?}",AdminAction::SetTableMetadataLocationAction.is_table_resource_scoped());
println!("is_table_resource_scoped/GetTableMetadataAction\t{:?}",AdminAction::GetTableMetadataAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SetTableMetadataAction\t{:?}",AdminAction::SetTableMetadataAction.is_table_resource_scoped());
println!("is_table_resource_scoped/SetTierAction\t{:?}",AdminAction::SetTierAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ListTierAction\t{:?}",AdminAction::ListTierAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ExportIAMAction\t{:?}",AdminAction::ExportIAMAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ImportIAMAction\t{:?}",AdminAction::ImportIAMAction.is_table_resource_scoped());
println!("is_table_resource_scoped/ListBatchJobsAction\t{:?}",AdminAction::ListBatchJobsAction.is_table_resource_scoped());
println!("is_table_resource_scoped/DescribeBatchJobAction\t{:?}",AdminAction::DescribeBatchJobAction.is_table_resource_scoped());
println!("is_table_resource_scoped/StartBatchJobAction\t{:?}",AdminAction::StartBatchJobAction.is_table_resource_scoped());
println!("is_table_resource_scoped/CancelBatchJobAction\t{:?}",AdminAction::CancelBatchJobAction.is_table_resource_scoped());
println!("is_table_resource_scoped/AllAdminActions\t{:?}",AdminAction::AllAdminActions.is_table_resource_scoped());
println!("is_valid/HealAdminAction\t{:?}",AdminAction::HealAdminAction.is_valid());
println!("is_valid/DecommissionAdminAction\t{:?}",AdminAction::DecommissionAdminAction.is_valid());
println!("is_valid/RebalanceAdminAction\t{:?}",AdminAction::RebalanceAdminAction.is_valid());
println!("is_valid/StorageInfoAdminAction\t{:?}",AdminAction::StorageInfoAdminAction.is_valid());
println!("is_valid/PrometheusAdminAction\t{:?}",AdminAction::PrometheusAdminAction.is_valid());
println!("is_valid/DataUsageInfoAdminAction\t{:?}",AdminAction::DataUsageInfoAdminAction.is_valid());
println!("is_valid/ForceUnlockAdminAction\t{:?}",AdminAction::ForceUnlockAdminAction.is_valid());
println!("is_valid/TopLocksAdminAction\t{:?}",AdminAction::TopLocksAdminAction.is_valid());
println!("is_valid/ProfilingAdminAction\t{:?}",AdminAction::ProfilingAdminAction.is_valid());
println!("is_valid/TraceAdminAction\t{:?}",AdminAction::TraceAdminAction.is_valid());
println!("is_valid/ConsoleLogAdminAction\t{:?}",AdminAction::ConsoleLogAdminAction.is_valid());
println!("is_valid/ServerInfoAdminAction\t{:?}",AdminAction::ServerInfoAdminAction.is_valid());
println!("is_valid/HealthInfoAdminAction\t{:?}",AdminAction::HealthInfoAdminAction.is_valid());
println!("is_valid/LicenseInfoAdminAction\t{:?}",AdminAction::LicenseInfoAdminAction.is_valid());
println!("is_valid/BandwidthMonitorAction\t{:?}",AdminAction::BandwidthMonitorAction.is_valid());
println!("is_valid/InspectDataAction\t{:?}",AdminAction::InspectDataAction.is_valid());
println!("is_valid/ServerUpdateAdminAction\t{:?}",AdminAction::ServerUpdateAdminAction.is_valid());
println!("is_valid/ServiceRestartAdminAction\t{:?}",AdminAction::ServiceRestartAdminAction.is_valid());
println!("is_valid/ServiceStopAdminAction\t{:?}",AdminAction::ServiceStopAdminAction.is_valid());
println!("is_valid/ServiceFreezeAdminAction\t{:?}",AdminAction::ServiceFreezeAdminAction.is_valid());
println!("is_valid/ConfigUpdateAdminAction\t{:?}",AdminAction::ConfigUpdateAdminAction.is_valid());
println!("is_valid/CreateUserAdminAction\t{:?}",AdminAction::CreateUserAdminAction.is_valid());
println!("is_valid/DeleteUserAdminAction\t{:?}",AdminAction::DeleteUserAdminAction.is_valid());
println!("is_valid/ListUsersAdminAction\t{:?}",AdminAction::ListUsersAdminAction.is_valid());
println!("is_valid/EnableUserAdminAction\t{:?}",AdminAction::EnableUserAdminAction.is_valid());
println!("is_valid/DisableUserAdminAction\t{:?}",AdminAction::DisableUserAdminAction.is_valid());
println!("is_valid/GetUserAdminAction\t{:?}",AdminAction::GetUserAdminAction.is_valid());
println!("is_valid/SiteReplicationAddAction\t{:?}",AdminAction::SiteReplicationAddAction.is_valid());
println!("is_valid/SiteReplicationDisableAction\t{:?}",AdminAction::SiteReplicationDisableAction.is_valid());
println!("is_valid/SiteReplicationRemoveAction\t{:?}",AdminAction::SiteReplicationRemoveAction.is_valid());
println!("is_valid/SiteReplicationResyncAction\t{:?}",AdminAction::SiteReplicationResyncAction.is_valid());
println!("is_valid/SiteReplicationInfoAction\t{:?}",AdminAction::SiteReplicationInfoAction.is_valid());
println!("is_valid/SiteReplicationOperationAction\t{:?}",AdminAction::SiteReplicationOperationAction.is_valid());
println!("is_valid/CreateServiceAccountAdminAction\t{:?}",AdminAction::CreateServiceAccountAdminAction.is_valid());
println!("is_valid/UpdateServiceAccountAdminAction\t{:?}",AdminAction::UpdateServiceAccountAdminAction.is_valid());
println!("is_valid/RemoveServiceAccountAdminAction\t{:?}",AdminAction::RemoveServiceAccountAdminAction.is_valid());
println!("is_valid/ListServiceAccountsAdminAction\t{:?}",AdminAction::ListServiceAccountsAdminAction.is_valid());
println!("is_valid/ListTemporaryAccountsAdminAction\t{:?}",AdminAction::ListTemporaryAccountsAdminAction.is_valid());
println!("is_valid/AddUserToGroupAdminAction\t{:?}",AdminAction::AddUserToGroupAdminAction.is_valid());
println!("is_valid/RemoveUserFromGroupAdminAction\t{:?}",AdminAction::RemoveUserFromGroupAdminAction.is_valid());
println!("is_valid/GetGroupAdminAction\t{:?}",AdminAction::GetGroupAdminAction.is_valid());
println!("is_valid/ListGroupsAdminAction\t{:?}",AdminAction::ListGroupsAdminAction.is_valid());
println!("is_valid/EnableGroupAdminAction\t{:?}",AdminAction::EnableGroupAdminAction.is_valid());
println!("is_valid/DisableGroupAdminAction\t{:?}",AdminAction::DisableGroupAdminAction.is_valid());
println!("is_valid/CreatePolicyAdminAction\t{:?}",AdminAction::CreatePolicyAdminAction.is_valid());
println!("is_valid/DeletePolicyAdminAction\t{:?}",AdminAction::DeletePolicyAdminAction.is_valid());
println!("is_valid/GetPolicyAdminAction\t{:?}",AdminAction::GetPolicyAdminAction.is_valid());
println!("is_valid/AttachPolicyAdminAction\t{:?}",AdminAction::AttachPolicyAdminAction.is_valid());
println!("is_valid/UpdatePolicyAssociationAction\t{:?}",AdminAction::UpdatePolicyAssociationAction.is_valid());
println!("is_valid/ListUserPoliciesAdminAction\t{:?}",AdminAction::ListUserPoliciesAdminAction.is_valid());
println!("is_valid/SetBucketQuotaAdminAction\t{:?}",AdminAction::SetBucketQuotaAdminAction.is_valid());
println!("is_valid/SetBucketTargetAction\t{:?}",AdminAction::SetBucketTargetAction.is_valid());
println!("is_valid/GetBucketTargetAction\t{:?}",AdminAction::GetBucketTargetAction.is_valid());
println!("is_valid/SetBucketOnDemandMigrationAction\t{:?}",AdminAction::SetBucketOnDemandMigrationAction.is_valid());
println!("is_valid/GetBucketOnDemandMigrationAction\t{:?}",AdminAction::GetBucketOnDemandMigrationAction.is_valid());
println!("is_valid/GetMetricsAction\t{:?}",AdminAction::GetMetricsAction.is_valid());
println!("is_valid/ReplicationDiff\t{:?}",AdminAction::ReplicationDiff.is_valid());
println!("is_valid/GetReplicationMetricsAction\t{:?}",AdminAction::GetReplicationMetricsAction.is_valid());
println!("is_valid/ImportBucketMetadataAction\t{:?}",AdminAction::ImportBucketMetadataAction.is_valid());
println!("is_valid/ExportBucketMetadataAction\t{:?}",AdminAction::ExportBucketMetadataAction.is_valid());
println!("is_valid/GetTableCatalogAction\t{:?}",AdminAction::GetTableCatalogAction.is_valid());
println!("is_valid/MigrateTableCatalogAction\t{:?}",AdminAction::MigrateTableCatalogAction.is_valid());
println!("is_valid/GetTableBucketAction\t{:?}",AdminAction::GetTableBucketAction.is_valid());
println!("is_valid/SetTableBucketAction\t{:?}",AdminAction::SetTableBucketAction.is_valid());
println!("is_valid/GetTableNamespaceAction\t{:?}",AdminAction::GetTableNamespaceAction.is_valid());
println!("is_valid/SetTableNamespaceAction\t{:?}",AdminAction::SetTableNamespaceAction.is_valid());
println!("is_valid/UpdateTableNamespacePropertiesAction\t{:?}",AdminAction::UpdateTableNamespacePropertiesAction.is_valid());
println!("is_valid/DeleteTableNamespaceAction\t{:?}",AdminAction::DeleteTableNamespaceAction.is_valid());
println!("is_valid/GetTableAction\t{:?}",AdminAction::GetTableAction.is_valid());
println!("is_valid/SetTableAction\t{:?}",AdminAction::SetTableAction.is_valid());
println!("is_valid/CreateTableAction\t{:?}",AdminAction::CreateTableAction.is_valid());
println!("is_valid/RegisterTableAction\t{:?}",AdminAction::RegisterTableAction.is_valid());
println!("is_valid/CommitTableAction\t{:?}",AdminAction::CommitTableAction.is_valid());
println!("is_valid/DeleteTableAction\t{:?}",AdminAction::DeleteTableAction.is_valid());
println!("is_valid/GetTableLifecycleAction\t{:?}",AdminAction::GetTableLifecycleAction.is_valid());
println!("is_valid/SetTableLifecycleAction\t{:?}",AdminAction::SetTableLifecycleAction.is_valid());
println!("is_valid/GetTableCredentialsAction\t{:?}",AdminAction::GetTableCredentialsAction.is_valid());
println!("is_valid/RunTableMaintenanceAction\t{:?}",AdminAction::RunTableMaintenanceAction.is_valid());
println!("is_valid/GetTableMetadataLocationAction\t{:?}",AdminAction::GetTableMetadataLocationAction.is_valid());
println!("is_valid/SetTableMetadataLocationAction\t{:?}",AdminAction::SetTableMetadataLocationAction.is_valid());
println!("is_valid/GetTableMetadataAction\t{:?}",AdminAction::GetTableMetadataAction.is_valid());
println!("is_valid/SetTableMetadataAction\t{:?}",AdminAction::SetTableMetadataAction.is_valid());
println!("is_valid/SetTierAction\t{:?}",AdminAction::SetTierAction.is_valid());
println!("is_valid/ListTierAction\t{:?}",AdminAction::ListTierAction.is_valid());
println!("is_valid/ExportIAMAction\t{:?}",AdminAction::ExportIAMAction.is_valid());
println!("is_valid/ImportIAMAction\t{:?}",AdminAction::ImportIAMAction.is_valid());
println!("is_valid/ListBatchJobsAction\t{:?}",AdminAction::ListBatchJobsAction.is_valid());
println!("is_valid/DescribeBatchJobAction\t{:?}",AdminAction::DescribeBatchJobAction.is_valid());
println!("is_valid/StartBatchJobAction\t{:?}",AdminAction::StartBatchJobAction.is_valid());
println!("is_valid/CancelBatchJobAction\t{:?}",AdminAction::CancelBatchJobAction.is_valid());
println!("is_valid/AllAdminActions\t{:?}",AdminAction::AllAdminActions.is_valid());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(AdminAction::HealAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::HealAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/HealAdminAction");
assert_eq!(AdminAction::DecommissionAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DecommissionAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/DecommissionAdminAction");
assert_eq!(AdminAction::RebalanceAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::RebalanceAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/RebalanceAdminAction");
assert_eq!(AdminAction::StorageInfoAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::StorageInfoAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/StorageInfoAdminAction");
assert_eq!(AdminAction::PrometheusAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::PrometheusAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/PrometheusAdminAction");
assert_eq!(AdminAction::DataUsageInfoAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DataUsageInfoAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/DataUsageInfoAdminAction");
assert_eq!(AdminAction::ForceUnlockAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ForceUnlockAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ForceUnlockAdminAction");
assert_eq!(AdminAction::TopLocksAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::TopLocksAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/TopLocksAdminAction");
assert_eq!(AdminAction::ProfilingAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ProfilingAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ProfilingAdminAction");
assert_eq!(AdminAction::TraceAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::TraceAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/TraceAdminAction");
assert_eq!(AdminAction::ConsoleLogAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ConsoleLogAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ConsoleLogAdminAction");
assert_eq!(AdminAction::ServerInfoAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ServerInfoAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ServerInfoAdminAction");
assert_eq!(AdminAction::HealthInfoAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::HealthInfoAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/HealthInfoAdminAction");
assert_eq!(AdminAction::LicenseInfoAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::LicenseInfoAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/LicenseInfoAdminAction");
assert_eq!(AdminAction::BandwidthMonitorAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::BandwidthMonitorAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/BandwidthMonitorAction");
assert_eq!(AdminAction::InspectDataAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::InspectDataAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/InspectDataAction");
assert_eq!(AdminAction::ServerUpdateAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ServerUpdateAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ServerUpdateAdminAction");
assert_eq!(AdminAction::ServiceRestartAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ServiceRestartAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ServiceRestartAdminAction");
assert_eq!(AdminAction::ServiceStopAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ServiceStopAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ServiceStopAdminAction");
assert_eq!(AdminAction::ServiceFreezeAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ServiceFreezeAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ServiceFreezeAdminAction");
assert_eq!(AdminAction::ConfigUpdateAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ConfigUpdateAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ConfigUpdateAdminAction");
assert_eq!(AdminAction::CreateUserAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::CreateUserAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/CreateUserAdminAction");
assert_eq!(AdminAction::DeleteUserAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DeleteUserAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/DeleteUserAdminAction");
assert_eq!(AdminAction::ListUsersAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ListUsersAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ListUsersAdminAction");
assert_eq!(AdminAction::EnableUserAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::EnableUserAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/EnableUserAdminAction");
assert_eq!(AdminAction::DisableUserAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DisableUserAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/DisableUserAdminAction");
assert_eq!(AdminAction::GetUserAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetUserAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetUserAdminAction");
assert_eq!(AdminAction::SiteReplicationAddAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SiteReplicationAddAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SiteReplicationAddAction");
assert_eq!(AdminAction::SiteReplicationDisableAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SiteReplicationDisableAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SiteReplicationDisableAction");
assert_eq!(AdminAction::SiteReplicationRemoveAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SiteReplicationRemoveAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SiteReplicationRemoveAction");
assert_eq!(AdminAction::SiteReplicationResyncAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SiteReplicationResyncAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SiteReplicationResyncAction");
assert_eq!(AdminAction::SiteReplicationInfoAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SiteReplicationInfoAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SiteReplicationInfoAction");
assert_eq!(AdminAction::SiteReplicationOperationAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SiteReplicationOperationAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SiteReplicationOperationAction");
assert_eq!(AdminAction::CreateServiceAccountAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::CreateServiceAccountAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/CreateServiceAccountAdminAction");
assert_eq!(AdminAction::UpdateServiceAccountAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::UpdateServiceAccountAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/UpdateServiceAccountAdminAction");
assert_eq!(AdminAction::RemoveServiceAccountAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::RemoveServiceAccountAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/RemoveServiceAccountAdminAction");
assert_eq!(AdminAction::ListServiceAccountsAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ListServiceAccountsAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ListServiceAccountsAdminAction");
assert_eq!(AdminAction::ListTemporaryAccountsAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ListTemporaryAccountsAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ListTemporaryAccountsAdminAction");
assert_eq!(AdminAction::AddUserToGroupAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::AddUserToGroupAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/AddUserToGroupAdminAction");
assert_eq!(AdminAction::RemoveUserFromGroupAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::RemoveUserFromGroupAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/RemoveUserFromGroupAdminAction");
assert_eq!(AdminAction::GetGroupAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetGroupAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetGroupAdminAction");
assert_eq!(AdminAction::ListGroupsAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ListGroupsAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ListGroupsAdminAction");
assert_eq!(AdminAction::EnableGroupAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::EnableGroupAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/EnableGroupAdminAction");
assert_eq!(AdminAction::DisableGroupAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DisableGroupAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/DisableGroupAdminAction");
assert_eq!(AdminAction::CreatePolicyAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::CreatePolicyAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/CreatePolicyAdminAction");
assert_eq!(AdminAction::DeletePolicyAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DeletePolicyAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/DeletePolicyAdminAction");
assert_eq!(AdminAction::GetPolicyAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetPolicyAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetPolicyAdminAction");
assert_eq!(AdminAction::AttachPolicyAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::AttachPolicyAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/AttachPolicyAdminAction");
assert_eq!(AdminAction::UpdatePolicyAssociationAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::UpdatePolicyAssociationAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/UpdatePolicyAssociationAction");
assert_eq!(AdminAction::ListUserPoliciesAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ListUserPoliciesAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ListUserPoliciesAdminAction");
assert_eq!(AdminAction::SetBucketQuotaAdminAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetBucketQuotaAdminAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SetBucketQuotaAdminAction");
assert_eq!(AdminAction::SetBucketTargetAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetBucketTargetAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SetBucketTargetAction");
assert_eq!(AdminAction::GetBucketTargetAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetBucketTargetAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetBucketTargetAction");
assert_eq!(AdminAction::SetBucketOnDemandMigrationAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetBucketOnDemandMigrationAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SetBucketOnDemandMigrationAction");
assert_eq!(AdminAction::GetBucketOnDemandMigrationAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetBucketOnDemandMigrationAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetBucketOnDemandMigrationAction");
assert_eq!(AdminAction::GetMetricsAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetMetricsAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetMetricsAction");
assert_eq!(AdminAction::ReplicationDiff.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ReplicationDiff.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ReplicationDiff");
assert_eq!(AdminAction::GetReplicationMetricsAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetReplicationMetricsAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetReplicationMetricsAction");
assert_eq!(AdminAction::ImportBucketMetadataAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ImportBucketMetadataAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ImportBucketMetadataAction");
assert_eq!(AdminAction::ExportBucketMetadataAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ExportBucketMetadataAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ExportBucketMetadataAction");
assert_eq!(AdminAction::GetTableCatalogAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableCatalogAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetTableCatalogAction");
assert_eq!(AdminAction::MigrateTableCatalogAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::MigrateTableCatalogAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/MigrateTableCatalogAction");
assert_eq!(AdminAction::GetTableBucketAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableBucketAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetTableBucketAction");
assert_eq!(AdminAction::SetTableBucketAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetTableBucketAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SetTableBucketAction");
assert_eq!(AdminAction::GetTableNamespaceAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableNamespaceAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetTableNamespaceAction");
assert_eq!(AdminAction::SetTableNamespaceAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetTableNamespaceAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SetTableNamespaceAction");
assert_eq!(AdminAction::UpdateTableNamespacePropertiesAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::UpdateTableNamespacePropertiesAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/UpdateTableNamespacePropertiesAction");
assert_eq!(AdminAction::DeleteTableNamespaceAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DeleteTableNamespaceAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/DeleteTableNamespaceAction");
assert_eq!(AdminAction::GetTableAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetTableAction");
assert_eq!(AdminAction::SetTableAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetTableAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SetTableAction");
assert_eq!(AdminAction::CreateTableAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::CreateTableAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/CreateTableAction");
assert_eq!(AdminAction::RegisterTableAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::RegisterTableAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/RegisterTableAction");
assert_eq!(AdminAction::CommitTableAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::CommitTableAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/CommitTableAction");
assert_eq!(AdminAction::DeleteTableAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DeleteTableAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/DeleteTableAction");
assert_eq!(AdminAction::GetTableLifecycleAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableLifecycleAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetTableLifecycleAction");
assert_eq!(AdminAction::SetTableLifecycleAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetTableLifecycleAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SetTableLifecycleAction");
assert_eq!(AdminAction::GetTableCredentialsAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableCredentialsAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetTableCredentialsAction");
assert_eq!(AdminAction::RunTableMaintenanceAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::RunTableMaintenanceAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/RunTableMaintenanceAction");
assert_eq!(AdminAction::GetTableMetadataLocationAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableMetadataLocationAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetTableMetadataLocationAction");
assert_eq!(AdminAction::SetTableMetadataLocationAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetTableMetadataLocationAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SetTableMetadataLocationAction");
assert_eq!(AdminAction::GetTableMetadataAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableMetadataAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/GetTableMetadataAction");
assert_eq!(AdminAction::SetTableMetadataAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetTableMetadataAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SetTableMetadataAction");
assert_eq!(AdminAction::SetTierAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetTierAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/SetTierAction");
assert_eq!(AdminAction::ListTierAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ListTierAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ListTierAction");
assert_eq!(AdminAction::ExportIAMAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ExportIAMAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ExportIAMAction");
assert_eq!(AdminAction::ImportIAMAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ImportIAMAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ImportIAMAction");
assert_eq!(AdminAction::ListBatchJobsAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ListBatchJobsAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/ListBatchJobsAction");
assert_eq!(AdminAction::DescribeBatchJobAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DescribeBatchJobAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/DescribeBatchJobAction");
assert_eq!(AdminAction::StartBatchJobAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::StartBatchJobAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/StartBatchJobAction");
assert_eq!(AdminAction::CancelBatchJobAction.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::CancelBatchJobAction.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/CancelBatchJobAction");
assert_eq!(AdminAction::AllAdminActions.is_table_resource_scoped(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::AllAdminActions.is_table_resource_scoped(),"admin_action_dfb862e5/is_table_resource_scoped/AllAdminActions");
assert_eq!(AdminAction::HealAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::HealAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/HealAdminAction");
assert_eq!(AdminAction::DecommissionAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DecommissionAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/DecommissionAdminAction");
assert_eq!(AdminAction::RebalanceAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::RebalanceAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/RebalanceAdminAction");
assert_eq!(AdminAction::StorageInfoAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::StorageInfoAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/StorageInfoAdminAction");
assert_eq!(AdminAction::PrometheusAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::PrometheusAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/PrometheusAdminAction");
assert_eq!(AdminAction::DataUsageInfoAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DataUsageInfoAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/DataUsageInfoAdminAction");
assert_eq!(AdminAction::ForceUnlockAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ForceUnlockAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/ForceUnlockAdminAction");
assert_eq!(AdminAction::TopLocksAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::TopLocksAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/TopLocksAdminAction");
assert_eq!(AdminAction::ProfilingAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ProfilingAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/ProfilingAdminAction");
assert_eq!(AdminAction::TraceAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::TraceAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/TraceAdminAction");
assert_eq!(AdminAction::ConsoleLogAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ConsoleLogAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/ConsoleLogAdminAction");
assert_eq!(AdminAction::ServerInfoAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ServerInfoAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/ServerInfoAdminAction");
assert_eq!(AdminAction::HealthInfoAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::HealthInfoAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/HealthInfoAdminAction");
assert_eq!(AdminAction::LicenseInfoAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::LicenseInfoAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/LicenseInfoAdminAction");
assert_eq!(AdminAction::BandwidthMonitorAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::BandwidthMonitorAction.is_valid(),"admin_action_dfb862e5/is_valid/BandwidthMonitorAction");
assert_eq!(AdminAction::InspectDataAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::InspectDataAction.is_valid(),"admin_action_dfb862e5/is_valid/InspectDataAction");
assert_eq!(AdminAction::ServerUpdateAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ServerUpdateAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/ServerUpdateAdminAction");
assert_eq!(AdminAction::ServiceRestartAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ServiceRestartAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/ServiceRestartAdminAction");
assert_eq!(AdminAction::ServiceStopAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ServiceStopAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/ServiceStopAdminAction");
assert_eq!(AdminAction::ServiceFreezeAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ServiceFreezeAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/ServiceFreezeAdminAction");
assert_eq!(AdminAction::ConfigUpdateAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ConfigUpdateAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/ConfigUpdateAdminAction");
assert_eq!(AdminAction::CreateUserAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::CreateUserAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/CreateUserAdminAction");
assert_eq!(AdminAction::DeleteUserAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DeleteUserAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/DeleteUserAdminAction");
assert_eq!(AdminAction::ListUsersAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ListUsersAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/ListUsersAdminAction");
assert_eq!(AdminAction::EnableUserAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::EnableUserAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/EnableUserAdminAction");
assert_eq!(AdminAction::DisableUserAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DisableUserAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/DisableUserAdminAction");
assert_eq!(AdminAction::GetUserAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetUserAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/GetUserAdminAction");
assert_eq!(AdminAction::SiteReplicationAddAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SiteReplicationAddAction.is_valid(),"admin_action_dfb862e5/is_valid/SiteReplicationAddAction");
assert_eq!(AdminAction::SiteReplicationDisableAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SiteReplicationDisableAction.is_valid(),"admin_action_dfb862e5/is_valid/SiteReplicationDisableAction");
assert_eq!(AdminAction::SiteReplicationRemoveAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SiteReplicationRemoveAction.is_valid(),"admin_action_dfb862e5/is_valid/SiteReplicationRemoveAction");
assert_eq!(AdminAction::SiteReplicationResyncAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SiteReplicationResyncAction.is_valid(),"admin_action_dfb862e5/is_valid/SiteReplicationResyncAction");
assert_eq!(AdminAction::SiteReplicationInfoAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SiteReplicationInfoAction.is_valid(),"admin_action_dfb862e5/is_valid/SiteReplicationInfoAction");
assert_eq!(AdminAction::SiteReplicationOperationAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SiteReplicationOperationAction.is_valid(),"admin_action_dfb862e5/is_valid/SiteReplicationOperationAction");
assert_eq!(AdminAction::CreateServiceAccountAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::CreateServiceAccountAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/CreateServiceAccountAdminAction");
assert_eq!(AdminAction::UpdateServiceAccountAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::UpdateServiceAccountAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/UpdateServiceAccountAdminAction");
assert_eq!(AdminAction::RemoveServiceAccountAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::RemoveServiceAccountAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/RemoveServiceAccountAdminAction");
assert_eq!(AdminAction::ListServiceAccountsAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ListServiceAccountsAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/ListServiceAccountsAdminAction");
assert_eq!(AdminAction::ListTemporaryAccountsAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ListTemporaryAccountsAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/ListTemporaryAccountsAdminAction");
assert_eq!(AdminAction::AddUserToGroupAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::AddUserToGroupAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/AddUserToGroupAdminAction");
assert_eq!(AdminAction::RemoveUserFromGroupAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::RemoveUserFromGroupAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/RemoveUserFromGroupAdminAction");
assert_eq!(AdminAction::GetGroupAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetGroupAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/GetGroupAdminAction");
assert_eq!(AdminAction::ListGroupsAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ListGroupsAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/ListGroupsAdminAction");
assert_eq!(AdminAction::EnableGroupAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::EnableGroupAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/EnableGroupAdminAction");
assert_eq!(AdminAction::DisableGroupAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DisableGroupAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/DisableGroupAdminAction");
assert_eq!(AdminAction::CreatePolicyAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::CreatePolicyAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/CreatePolicyAdminAction");
assert_eq!(AdminAction::DeletePolicyAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DeletePolicyAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/DeletePolicyAdminAction");
assert_eq!(AdminAction::GetPolicyAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetPolicyAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/GetPolicyAdminAction");
assert_eq!(AdminAction::AttachPolicyAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::AttachPolicyAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/AttachPolicyAdminAction");
assert_eq!(AdminAction::UpdatePolicyAssociationAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::UpdatePolicyAssociationAction.is_valid(),"admin_action_dfb862e5/is_valid/UpdatePolicyAssociationAction");
assert_eq!(AdminAction::ListUserPoliciesAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ListUserPoliciesAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/ListUserPoliciesAdminAction");
assert_eq!(AdminAction::SetBucketQuotaAdminAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetBucketQuotaAdminAction.is_valid(),"admin_action_dfb862e5/is_valid/SetBucketQuotaAdminAction");
assert_eq!(AdminAction::SetBucketTargetAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetBucketTargetAction.is_valid(),"admin_action_dfb862e5/is_valid/SetBucketTargetAction");
assert_eq!(AdminAction::GetBucketTargetAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetBucketTargetAction.is_valid(),"admin_action_dfb862e5/is_valid/GetBucketTargetAction");
assert_eq!(AdminAction::SetBucketOnDemandMigrationAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetBucketOnDemandMigrationAction.is_valid(),"admin_action_dfb862e5/is_valid/SetBucketOnDemandMigrationAction");
assert_eq!(AdminAction::GetBucketOnDemandMigrationAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetBucketOnDemandMigrationAction.is_valid(),"admin_action_dfb862e5/is_valid/GetBucketOnDemandMigrationAction");
assert_eq!(AdminAction::GetMetricsAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetMetricsAction.is_valid(),"admin_action_dfb862e5/is_valid/GetMetricsAction");
assert_eq!(AdminAction::ReplicationDiff.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ReplicationDiff.is_valid(),"admin_action_dfb862e5/is_valid/ReplicationDiff");
assert_eq!(AdminAction::GetReplicationMetricsAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetReplicationMetricsAction.is_valid(),"admin_action_dfb862e5/is_valid/GetReplicationMetricsAction");
assert_eq!(AdminAction::ImportBucketMetadataAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ImportBucketMetadataAction.is_valid(),"admin_action_dfb862e5/is_valid/ImportBucketMetadataAction");
assert_eq!(AdminAction::ExportBucketMetadataAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ExportBucketMetadataAction.is_valid(),"admin_action_dfb862e5/is_valid/ExportBucketMetadataAction");
assert_eq!(AdminAction::GetTableCatalogAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableCatalogAction.is_valid(),"admin_action_dfb862e5/is_valid/GetTableCatalogAction");
assert_eq!(AdminAction::MigrateTableCatalogAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::MigrateTableCatalogAction.is_valid(),"admin_action_dfb862e5/is_valid/MigrateTableCatalogAction");
assert_eq!(AdminAction::GetTableBucketAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableBucketAction.is_valid(),"admin_action_dfb862e5/is_valid/GetTableBucketAction");
assert_eq!(AdminAction::SetTableBucketAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetTableBucketAction.is_valid(),"admin_action_dfb862e5/is_valid/SetTableBucketAction");
assert_eq!(AdminAction::GetTableNamespaceAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableNamespaceAction.is_valid(),"admin_action_dfb862e5/is_valid/GetTableNamespaceAction");
assert_eq!(AdminAction::SetTableNamespaceAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetTableNamespaceAction.is_valid(),"admin_action_dfb862e5/is_valid/SetTableNamespaceAction");
assert_eq!(AdminAction::UpdateTableNamespacePropertiesAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::UpdateTableNamespacePropertiesAction.is_valid(),"admin_action_dfb862e5/is_valid/UpdateTableNamespacePropertiesAction");
assert_eq!(AdminAction::DeleteTableNamespaceAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DeleteTableNamespaceAction.is_valid(),"admin_action_dfb862e5/is_valid/DeleteTableNamespaceAction");
assert_eq!(AdminAction::GetTableAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableAction.is_valid(),"admin_action_dfb862e5/is_valid/GetTableAction");
assert_eq!(AdminAction::SetTableAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetTableAction.is_valid(),"admin_action_dfb862e5/is_valid/SetTableAction");
assert_eq!(AdminAction::CreateTableAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::CreateTableAction.is_valid(),"admin_action_dfb862e5/is_valid/CreateTableAction");
assert_eq!(AdminAction::RegisterTableAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::RegisterTableAction.is_valid(),"admin_action_dfb862e5/is_valid/RegisterTableAction");
assert_eq!(AdminAction::CommitTableAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::CommitTableAction.is_valid(),"admin_action_dfb862e5/is_valid/CommitTableAction");
assert_eq!(AdminAction::DeleteTableAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DeleteTableAction.is_valid(),"admin_action_dfb862e5/is_valid/DeleteTableAction");
assert_eq!(AdminAction::GetTableLifecycleAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableLifecycleAction.is_valid(),"admin_action_dfb862e5/is_valid/GetTableLifecycleAction");
assert_eq!(AdminAction::SetTableLifecycleAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetTableLifecycleAction.is_valid(),"admin_action_dfb862e5/is_valid/SetTableLifecycleAction");
assert_eq!(AdminAction::GetTableCredentialsAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableCredentialsAction.is_valid(),"admin_action_dfb862e5/is_valid/GetTableCredentialsAction");
assert_eq!(AdminAction::RunTableMaintenanceAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::RunTableMaintenanceAction.is_valid(),"admin_action_dfb862e5/is_valid/RunTableMaintenanceAction");
assert_eq!(AdminAction::GetTableMetadataLocationAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableMetadataLocationAction.is_valid(),"admin_action_dfb862e5/is_valid/GetTableMetadataLocationAction");
assert_eq!(AdminAction::SetTableMetadataLocationAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetTableMetadataLocationAction.is_valid(),"admin_action_dfb862e5/is_valid/SetTableMetadataLocationAction");
assert_eq!(AdminAction::GetTableMetadataAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::GetTableMetadataAction.is_valid(),"admin_action_dfb862e5/is_valid/GetTableMetadataAction");
assert_eq!(AdminAction::SetTableMetadataAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetTableMetadataAction.is_valid(),"admin_action_dfb862e5/is_valid/SetTableMetadataAction");
assert_eq!(AdminAction::SetTierAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::SetTierAction.is_valid(),"admin_action_dfb862e5/is_valid/SetTierAction");
assert_eq!(AdminAction::ListTierAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ListTierAction.is_valid(),"admin_action_dfb862e5/is_valid/ListTierAction");
assert_eq!(AdminAction::ExportIAMAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ExportIAMAction.is_valid(),"admin_action_dfb862e5/is_valid/ExportIAMAction");
assert_eq!(AdminAction::ImportIAMAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ImportIAMAction.is_valid(),"admin_action_dfb862e5/is_valid/ImportIAMAction");
assert_eq!(AdminAction::ListBatchJobsAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::ListBatchJobsAction.is_valid(),"admin_action_dfb862e5/is_valid/ListBatchJobsAction");
assert_eq!(AdminAction::DescribeBatchJobAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::DescribeBatchJobAction.is_valid(),"admin_action_dfb862e5/is_valid/DescribeBatchJobAction");
assert_eq!(AdminAction::StartBatchJobAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::StartBatchJobAction.is_valid(),"admin_action_dfb862e5/is_valid/StartBatchJobAction");
assert_eq!(AdminAction::CancelBatchJobAction.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::CancelBatchJobAction.is_valid(),"admin_action_dfb862e5/is_valid/CancelBatchJobAction");
assert_eq!(AdminAction::AllAdminActions.is_valid(),rustfs_kernel::finite_catalog::admin_action_dfb862e5::AdminAction::AllAdminActions.is_valid(),"admin_action_dfb862e5/is_valid/AllAdminActions");
}
