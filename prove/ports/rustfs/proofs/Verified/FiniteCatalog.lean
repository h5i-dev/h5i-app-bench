import RustfsKernel
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib rustfs_kernel
namespace rustfs_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def admin_action_dfb862e5_is_table_resource_scoped_model (v : finite_catalog.admin_action_dfb862e5.AdminAction) : Bool :=
  match v with
  | .HealAdminAction => false
  | .DecommissionAdminAction => false
  | .RebalanceAdminAction => false
  | .StorageInfoAdminAction => false
  | .PrometheusAdminAction => false
  | .DataUsageInfoAdminAction => false
  | .ForceUnlockAdminAction => false
  | .TopLocksAdminAction => false
  | .ProfilingAdminAction => false
  | .TraceAdminAction => false
  | .ConsoleLogAdminAction => false
  | .ServerInfoAdminAction => false
  | .HealthInfoAdminAction => false
  | .LicenseInfoAdminAction => false
  | .BandwidthMonitorAction => false
  | .InspectDataAction => false
  | .ServerUpdateAdminAction => false
  | .ServiceRestartAdminAction => false
  | .ServiceStopAdminAction => false
  | .ServiceFreezeAdminAction => false
  | .ConfigUpdateAdminAction => false
  | .CreateUserAdminAction => false
  | .DeleteUserAdminAction => false
  | .ListUsersAdminAction => false
  | .EnableUserAdminAction => false
  | .DisableUserAdminAction => false
  | .GetUserAdminAction => false
  | .SiteReplicationAddAction => false
  | .SiteReplicationDisableAction => false
  | .SiteReplicationRemoveAction => false
  | .SiteReplicationResyncAction => false
  | .SiteReplicationInfoAction => false
  | .SiteReplicationOperationAction => false
  | .CreateServiceAccountAdminAction => false
  | .UpdateServiceAccountAdminAction => false
  | .RemoveServiceAccountAdminAction => false
  | .ListServiceAccountsAdminAction => false
  | .ListTemporaryAccountsAdminAction => false
  | .AddUserToGroupAdminAction => false
  | .RemoveUserFromGroupAdminAction => false
  | .GetGroupAdminAction => false
  | .ListGroupsAdminAction => false
  | .EnableGroupAdminAction => false
  | .DisableGroupAdminAction => false
  | .CreatePolicyAdminAction => false
  | .DeletePolicyAdminAction => false
  | .GetPolicyAdminAction => false
  | .AttachPolicyAdminAction => false
  | .UpdatePolicyAssociationAction => false
  | .ListUserPoliciesAdminAction => false
  | .SetBucketQuotaAdminAction => false
  | .SetBucketTargetAction => false
  | .GetBucketTargetAction => false
  | .SetBucketOnDemandMigrationAction => false
  | .GetBucketOnDemandMigrationAction => false
  | .GetMetricsAction => false
  | .ReplicationDiff => false
  | .GetReplicationMetricsAction => false
  | .ImportBucketMetadataAction => false
  | .ExportBucketMetadataAction => false
  | .GetTableCatalogAction => false
  | .MigrateTableCatalogAction => false
  | .GetTableBucketAction => true
  | .SetTableBucketAction => true
  | .GetTableNamespaceAction => true
  | .SetTableNamespaceAction => true
  | .UpdateTableNamespacePropertiesAction => true
  | .DeleteTableNamespaceAction => true
  | .GetTableAction => true
  | .SetTableAction => true
  | .CreateTableAction => true
  | .RegisterTableAction => true
  | .CommitTableAction => true
  | .DeleteTableAction => true
  | .GetTableLifecycleAction => true
  | .SetTableLifecycleAction => true
  | .GetTableCredentialsAction => true
  | .RunTableMaintenanceAction => true
  | .GetTableMetadataLocationAction => true
  | .SetTableMetadataLocationAction => true
  | .GetTableMetadataAction => true
  | .SetTableMetadataAction => true
  | .SetTierAction => false
  | .ListTierAction => false
  | .ExportIAMAction => false
  | .ImportIAMAction => false
  | .ListBatchJobsAction => false
  | .DescribeBatchJobAction => false
  | .StartBatchJobAction => false
  | .CancelBatchJobAction => false
  | .AllAdminActions => false
theorem admin_action_dfb862e5_is_table_resource_scoped_complete (v : finite_catalog.admin_action_dfb862e5.AdminAction) :
    finite_catalog.admin_action_dfb862e5.AdminAction.is_table_resource_scoped v ⦃r => r = admin_action_dfb862e5_is_table_resource_scoped_model v⦄ := by
  cases v <;> simp only [admin_action_dfb862e5_is_table_resource_scoped_model]
  all_goals simp only [finite_catalog.admin_action_dfb862e5.AdminAction.is_table_resource_scoped, finite_catalog.admin_action_dfb862e5.AdminAction.is_valid]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end rustfs_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib rustfs_kernel
namespace rustfs_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def admin_action_dfb862e5_is_valid_model (v : finite_catalog.admin_action_dfb862e5.AdminAction) : Bool :=
  match v with
  | .HealAdminAction => true
  | .DecommissionAdminAction => true
  | .RebalanceAdminAction => true
  | .StorageInfoAdminAction => true
  | .PrometheusAdminAction => true
  | .DataUsageInfoAdminAction => true
  | .ForceUnlockAdminAction => true
  | .TopLocksAdminAction => true
  | .ProfilingAdminAction => true
  | .TraceAdminAction => true
  | .ConsoleLogAdminAction => true
  | .ServerInfoAdminAction => true
  | .HealthInfoAdminAction => true
  | .LicenseInfoAdminAction => true
  | .BandwidthMonitorAction => true
  | .InspectDataAction => true
  | .ServerUpdateAdminAction => true
  | .ServiceRestartAdminAction => true
  | .ServiceStopAdminAction => true
  | .ServiceFreezeAdminAction => true
  | .ConfigUpdateAdminAction => true
  | .CreateUserAdminAction => true
  | .DeleteUserAdminAction => true
  | .ListUsersAdminAction => true
  | .EnableUserAdminAction => true
  | .DisableUserAdminAction => true
  | .GetUserAdminAction => true
  | .SiteReplicationAddAction => true
  | .SiteReplicationDisableAction => true
  | .SiteReplicationRemoveAction => true
  | .SiteReplicationResyncAction => true
  | .SiteReplicationInfoAction => true
  | .SiteReplicationOperationAction => true
  | .CreateServiceAccountAdminAction => true
  | .UpdateServiceAccountAdminAction => true
  | .RemoveServiceAccountAdminAction => true
  | .ListServiceAccountsAdminAction => true
  | .ListTemporaryAccountsAdminAction => true
  | .AddUserToGroupAdminAction => true
  | .RemoveUserFromGroupAdminAction => true
  | .GetGroupAdminAction => true
  | .ListGroupsAdminAction => true
  | .EnableGroupAdminAction => true
  | .DisableGroupAdminAction => true
  | .CreatePolicyAdminAction => true
  | .DeletePolicyAdminAction => true
  | .GetPolicyAdminAction => true
  | .AttachPolicyAdminAction => true
  | .UpdatePolicyAssociationAction => true
  | .ListUserPoliciesAdminAction => true
  | .SetBucketQuotaAdminAction => true
  | .SetBucketTargetAction => true
  | .GetBucketTargetAction => true
  | .SetBucketOnDemandMigrationAction => true
  | .GetBucketOnDemandMigrationAction => true
  | .GetMetricsAction => true
  | .ReplicationDiff => true
  | .GetReplicationMetricsAction => true
  | .ImportBucketMetadataAction => true
  | .ExportBucketMetadataAction => true
  | .GetTableCatalogAction => true
  | .MigrateTableCatalogAction => true
  | .GetTableBucketAction => true
  | .SetTableBucketAction => true
  | .GetTableNamespaceAction => true
  | .SetTableNamespaceAction => true
  | .UpdateTableNamespacePropertiesAction => true
  | .DeleteTableNamespaceAction => true
  | .GetTableAction => true
  | .SetTableAction => true
  | .CreateTableAction => true
  | .RegisterTableAction => true
  | .CommitTableAction => true
  | .DeleteTableAction => true
  | .GetTableLifecycleAction => true
  | .SetTableLifecycleAction => true
  | .GetTableCredentialsAction => true
  | .RunTableMaintenanceAction => true
  | .GetTableMetadataLocationAction => true
  | .SetTableMetadataLocationAction => true
  | .GetTableMetadataAction => true
  | .SetTableMetadataAction => true
  | .SetTierAction => true
  | .ListTierAction => true
  | .ExportIAMAction => true
  | .ImportIAMAction => true
  | .ListBatchJobsAction => true
  | .DescribeBatchJobAction => true
  | .StartBatchJobAction => true
  | .CancelBatchJobAction => true
  | .AllAdminActions => true
theorem admin_action_dfb862e5_is_valid_complete (v : finite_catalog.admin_action_dfb862e5.AdminAction) :
    finite_catalog.admin_action_dfb862e5.AdminAction.is_valid v ⦃r => r = admin_action_dfb862e5_is_valid_model v⦄ := by
  cases v <;> simp only [admin_action_dfb862e5_is_valid_model]
  all_goals simp only [finite_catalog.admin_action_dfb862e5.AdminAction.is_table_resource_scoped, finite_catalog.admin_action_dfb862e5.AdminAction.is_valid]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end rustfs_kernel.Verified.FiniteCatalog
