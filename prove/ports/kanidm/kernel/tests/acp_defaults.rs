#[path = "../../difftest/acp_defaults/reference.rs"]
mod reference;
use kanidm_kernel::acp_defaults;
#[test]
fn all_66_pinned_profiles_match_every_field(){
 let upstream=reference::profiles();
 assert_eq!(upstream.len(),66);
 for (name,expected) in upstream {
 let actual = match name {
  "dl11/IDM_ACP_OAUTH2_MANAGE" | "dl12/IDM_ACP_OAUTH2_MANAGE" => acp_defaults::dl11_oauth2_manage(),
  "dl11/IDM_ACP_ACP_MANAGE_V1" | "dl12/IDM_ACP_ACP_MANAGE_V1" => acp_defaults::dl11_acp_manage_v1(),
  "dl11/IDM_ACP_APPLICATION_MANAGE_DL8" | "dl12/IDM_ACP_APPLICATION_MANAGE_DL8" => acp_defaults::dl11_application_manage_dl8(),
  "dl11/IDM_ACP_DOMAIN_ADMIN_DL9" | "dl12/IDM_ACP_DOMAIN_ADMIN_DL9" | "dl13/IDM_ACP_DOMAIN_ADMIN_DL9" => acp_defaults::dl11_domain_admin_dl9(),
  "dl11/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1" => acp_defaults::dl11_service_account_entry_manager_v1(),
  "dl11/IDM_ACP_SCHEMA_WRITE_ATTRS_V1" | "dl12/IDM_ACP_SCHEMA_WRITE_ATTRS_V1" | "dl13/IDM_ACP_SCHEMA_WRITE_ATTRS_V1" | "dl14/IDM_ACP_SCHEMA_WRITE_ATTRS_V1" | "dl15/IDM_ACP_SCHEMA_WRITE_ATTRS_V1" | "dl_1_12/IDM_ACP_SCHEMA_WRITE_ATTRS_V1" => acp_defaults::dl11_schema_write_attrs_v1(),
  "dl11/IDM_ACP_GROUP_MANAGE_DL9" => acp_defaults::dl11_group_manage_dl9(),
  "dl11/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8" | "dl12/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8" | "dl13/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8" | "dl14/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8" | "dl15/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8" | "dl_1_12/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8" => acp_defaults::dl11_group_account_policy_manage_dl8(),
  "dl11/IDM_ACP_SCHEMA_WRITE_CLASSES_V1" | "dl12/IDM_ACP_SCHEMA_WRITE_CLASSES_V1" | "dl13/IDM_ACP_SCHEMA_WRITE_CLASSES_V1" | "dl14/IDM_ACP_SCHEMA_WRITE_CLASSES_V1" | "dl15/IDM_ACP_SCHEMA_WRITE_CLASSES_V1" | "dl_1_12/IDM_ACP_SCHEMA_WRITE_CLASSES_V1" => acp_defaults::dl11_schema_write_classes_v1(),
  "dl11/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8" | "dl12/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8" => acp_defaults::dl11_application_entry_manager_dl8(),
  "dl11/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1" | "dl12/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1" => acp_defaults::dl11_sync_account_manage_v1(),
  "dl12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1" | "dl13/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1" | "dl14/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1" | "dl15/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1" | "dl_1_12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1" => acp_defaults::dl12_service_account_entry_manager_v1(),
  "dl12/IDM_ACP_GROUP_MANAGE_DL9" | "dl13/IDM_ACP_GROUP_MANAGE_DL9" | "dl14/IDM_ACP_GROUP_MANAGE_DL9" | "dl15/IDM_ACP_GROUP_MANAGE_DL9" | "dl_1_12/IDM_ACP_GROUP_MANAGE_DL9" => acp_defaults::dl12_group_manage_dl9(),
  "dl13/IDM_ACP_OAUTH2_MANAGE" => acp_defaults::dl13_oauth2_manage(),
  "dl13/IDM_ACP_ACP_MANAGE_V1" | "dl14/IDM_ACP_ACP_MANAGE_V1" | "dl15/IDM_ACP_ACP_MANAGE_V1" | "dl_1_12/IDM_ACP_ACP_MANAGE_V1" => acp_defaults::dl13_acp_manage_v1(),
  "dl13/IDM_ACP_APPLICATION_MANAGE_DL8" | "dl14/IDM_ACP_APPLICATION_MANAGE_DL8" | "dl15/IDM_ACP_APPLICATION_MANAGE_DL8" | "dl_1_12/IDM_ACP_APPLICATION_MANAGE_DL8" => acp_defaults::dl13_application_manage_dl8(),
  "dl13/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8" | "dl14/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8" | "dl15/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8" | "dl_1_12/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8" => acp_defaults::dl13_application_entry_manager_dl8(),
  "dl13/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1" | "dl14/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1" | "dl15/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1" | "dl_1_12/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1" => acp_defaults::dl13_sync_account_manage_v1(),
  "dl14/IDM_ACP_OAUTH2_MANAGE" | "dl15/IDM_ACP_OAUTH2_MANAGE" | "dl_1_12/IDM_ACP_OAUTH2_MANAGE" => acp_defaults::dl14_oauth2_manage(),
  "dl14/IDM_ACP_DOMAIN_ADMIN_DL9" | "dl15/IDM_ACP_DOMAIN_ADMIN_DL9" | "dl_1_12/IDM_ACP_DOMAIN_ADMIN_DL9" => acp_defaults::dl14_domain_admin_dl9(),
 _=>panic!("unexpected upstream profile: {name}"),
 };
 assert_eq!(actual,expected,"complete profile {name}");
 assert!(!actual.name.is_empty());assert!(!actual.target.is_empty());assert!(actual.receiver==1 || actual.receiver==2);
 }
 println!("66 pinned built-in profiles / all 15 fields / 20 distinct records matched");
}
