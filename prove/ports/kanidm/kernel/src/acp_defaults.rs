//! Complete owned built-in ACP records. See DEVIATIONS.md and difftest/acp_defaults.
#[derive(Debug,PartialEq,Eq)]
pub struct Profile {
 pub classes:Vec<u16>,
 pub name:Vec<u8>,
 pub uuid:u128,
 pub description:Vec<u8>,
 pub receiver:u8,
 pub groups:Vec<u128>,
 pub target:Vec<u8>,
 pub search_attrs:Vec<u16>,
 pub modify_present_attrs:Vec<u16>,
 pub modify_removed_attrs:Vec<u16>,
 pub modify_classes:Vec<u16>,
 pub modify_present_classes:Vec<u16>,
 pub modify_remove_classes:Vec<u16>,
 pub create_classes:Vec<u16>,
 pub create_attrs:Vec<u16>,
}

/// Exact snapshot for dl11/IDM_ACP_OAUTH2_MANAGE, dl12/IDM_ACP_OAUTH2_MANAGE.
pub fn dl11_oauth2_manage()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933493u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 32u8, 105u8, 110u8, 116u8, 101u8, 103u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([39u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 22u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 19u16, 20u16, 49u16, 68u16, 63u16, 59u16, 60u16, 61u16, 62u16, 56u16, 50u16, 53u16, 54u16, 51u16, 57u16, 31u16, 64u16, 52u16, 36u16]),
  modify_present_attrs: Vec::from([19u16, 20u16, 49u16, 59u16, 60u16, 62u16, 61u16, 50u16, 53u16, 54u16, 51u16, 57u16, 31u16, 64u16, 52u16, 34u16, 35u16]),
  modify_removed_attrs: Vec::from([19u16, 20u16, 49u16, 63u16, 59u16, 60u16, 61u16, 62u16, 56u16, 50u16, 53u16, 54u16, 51u16, 57u16, 31u16, 64u16, 52u16, 34u16, 35u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([15u16, 5u16, 12u16, 13u16, 14u16]),
  create_attrs: Vec::from([16u16, 19u16, 49u16, 20u16, 58u16, 59u16, 60u16, 62u16, 61u16, 50u16, 53u16, 54u16, 51u16, 57u16, 31u16, 64u16, 52u16]),
 }
}

/// Exact snapshot for dl11/IDM_ACP_ACP_MANAGE_V1, dl12/IDM_ACP_ACP_MANAGE_V1.
pub fn dl11_acp_manage_v1()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 99u8, 112u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933465u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 112u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8, 115u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 109u8, 101u8, 110u8, 116u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([17u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 22u8, 0u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 112u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 49u16, 19u16, 4u16, 8u16, 10u16, 9u16, 7u16, 6u16, 5u16, 3u16, 2u16]),
  modify_present_attrs: Vec::from([16u16, 49u16, 19u16, 4u16, 8u16, 10u16, 9u16, 7u16, 6u16, 5u16, 3u16, 2u16]),
  modify_removed_attrs: Vec::from([16u16, 49u16, 19u16, 4u16, 8u16, 10u16, 9u16, 7u16, 6u16, 5u16, 3u16, 2u16]),
  modify_classes: Vec::from([3u16, 4u16, 2u16, 0u16, 1u16]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([3u16, 4u16, 2u16, 0u16, 1u16]),
  create_attrs: Vec::from([16u16, 49u16, 19u16, 4u16, 8u16, 10u16, 9u16, 7u16, 6u16, 5u16, 3u16, 2u16]),
 }
}

/// Exact snapshot for dl11/IDM_ACP_APPLICATION_MANAGE_DL8, dl12/IDM_ACP_APPLICATION_MANAGE_DL8.
pub fn dl11_application_manage_dl8()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933555u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 100u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 32u8, 105u8, 110u8, 32u8, 116u8, 104u8, 101u8, 32u8, 100u8, 105u8, 114u8, 101u8, 99u8, 116u8, 111u8, 114u8, 121u8]),
  receiver: 1u8,
  groups: Vec::from([80u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 11u8, 0u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 80u16, 49u16, 19u16, 20u16, 43u16, 78u16, 12u16, 79u16, 41u16, 29u16]),
  modify_present_attrs: Vec::from([49u16, 19u16, 20u16, 43u16, 78u16, 12u16, 41u16, 29u16]),
  modify_removed_attrs: Vec::from([49u16, 19u16, 20u16, 43u16, 78u16, 12u16, 79u16, 41u16, 29u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([15u16, 5u16, 17u16, 7u16]),
  create_attrs: Vec::from([16u16, 80u16, 49u16, 19u16, 20u16, 43u16, 41u16, 29u16]),
 }
}

/// Exact snapshot for dl11/IDM_ACP_DOMAIN_ADMIN_DL9, dl12/IDM_ACP_DOMAIN_ADMIN_DL9, dl13/IDM_ACP_DOMAIN_ADMIN_DL9.
pub fn dl11_domain_admin_dl9()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]),
  uuid: 281474959933478u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 103u8, 114u8, 97u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 105u8, 110u8, 102u8, 111u8, 32u8, 97u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 108u8, 111u8, 99u8, 97u8, 108u8, 108u8, 121u8]),
  receiver: 1u8,
  groups: Vec::from([32u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 4u8, 0u8, 117u8, 117u8, 105u8, 100u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 102u8, 102u8, 102u8, 102u8, 102u8, 102u8, 48u8, 48u8, 48u8, 48u8, 50u8, 53u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 49u16, 80u16, 22u16, 23u16, 25u16, 24u16, 38u16, 26u16, 27u16, 36u16, 37u16, 81u16, 31u16]),
  modify_present_attrs: Vec::from([23u16, 24u16, 38u16, 26u16, 22u16, 37u16, 34u16, 35u16, 31u16]),
  modify_removed_attrs: Vec::from([23u16, 26u16, 24u16, 38u16, 22u16, 37u16, 34u16, 35u16, 31u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact snapshot for dl11/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1.
pub fn dl11_service_account_entry_manager_v1()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]),
  uuid: 281474959933537u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8, 115u8, 32u8, 116u8, 111u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8]),
  receiver: 2u8,
  groups: Vec::from([]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 49u16, 68u16, 80u16, 29u16, 20u16, 69u16, 30u16, 42u16, 78u16, 65u16, 66u16, 0u16, 1u16, 12u16, 79u16]),
  modify_present_attrs: Vec::from([20u16, 69u16, 66u16, 0u16, 1u16, 12u16]),
  modify_removed_attrs: Vec::from([20u16, 69u16, 66u16, 78u16, 65u16, 0u16, 1u16, 12u16, 79u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact snapshot for dl11/IDM_ACP_SCHEMA_WRITE_ATTRS_V1, dl12/IDM_ACP_SCHEMA_WRITE_ATTRS_V1, dl13/IDM_ACP_SCHEMA_WRITE_ATTRS_V1, dl14/IDM_ACP_SCHEMA_WRITE_ATTRS_V1, dl15/IDM_ACP_SCHEMA_WRITE_ATTRS_V1, dl_1_12/IDM_ACP_SCHEMA_WRITE_ATTRS_V1.
pub fn dl11_schema_write_attrs_v1()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 0u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 99u8, 104u8, 101u8, 109u8, 97u8, 95u8, 119u8, 114u8, 105u8, 116u8, 101u8, 95u8, 97u8, 116u8, 116u8, 114u8, 115u8]),
  uuid: 281474959933464u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 109u8, 101u8, 110u8, 116u8, 32u8, 111u8, 102u8, 32u8, 115u8, 99u8, 104u8, 101u8, 109u8, 97u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([16u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 13u8, 0u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 116u8, 121u8, 112u8, 101u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 19u16, 32u16, 77u16, 47u16, 13u16, 74u16, 80u16]),
  modify_present_attrs: Vec::from([19u16, 32u16, 77u16, 47u16, 74u16]),
  modify_removed_attrs: Vec::from([19u16, 32u16, 77u16, 47u16, 74u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([15u16, 8u16]),
  create_attrs: Vec::from([16u16, 19u16, 32u16, 77u16, 47u16, 13u16, 74u16, 80u16]),
 }
}

/// Exact snapshot for dl11/IDM_ACP_GROUP_MANAGE_DL9.
pub fn dl11_group_manage_dl9()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933474u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 100u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 105u8, 110u8, 103u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 115u8, 32u8, 105u8, 110u8, 32u8, 116u8, 104u8, 101u8, 32u8, 100u8, 105u8, 114u8, 101u8, 99u8, 116u8, 111u8, 114u8, 121u8]),
  receiver: 1u8,
  groups: Vec::from([21u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 49u16, 80u16, 68u16, 80u16, 19u16, 43u16, 45u16, 28u16, 29u16]),
  modify_present_attrs: Vec::from([49u16, 19u16, 43u16, 45u16, 29u16]),
  modify_removed_attrs: Vec::from([49u16, 19u16, 43u16, 45u16, 29u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([15u16, 11u16]),
  create_attrs: Vec::from([16u16, 49u16, 80u16, 19u16, 43u16, 45u16, 29u16]),
 }
}

/// Exact snapshot for dl11/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8, dl12/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8, dl13/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8, dl14/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8, dl15/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8, dl_1_12/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8.
pub fn dl11_group_account_policy_manage_dl8()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933513u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 109u8, 101u8, 110u8, 116u8, 32u8, 111u8, 102u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8, 32u8, 111u8, 110u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([71u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 49u16, 80u16, 15u16, 14u16, 18u16, 67u16, 82u16, 40u16, 39u16, 11u16]),
  modify_present_attrs: Vec::from([16u16, 15u16, 14u16, 18u16, 67u16, 82u16, 40u16, 39u16, 11u16]),
  modify_removed_attrs: Vec::from([16u16, 15u16, 14u16, 18u16, 67u16, 82u16, 40u16, 39u16, 11u16]),
  modify_classes: Vec::from([6u16]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact snapshot for dl11/IDM_ACP_SCHEMA_WRITE_CLASSES_V1, dl12/IDM_ACP_SCHEMA_WRITE_CLASSES_V1, dl13/IDM_ACP_SCHEMA_WRITE_CLASSES_V1, dl14/IDM_ACP_SCHEMA_WRITE_CLASSES_V1, dl15/IDM_ACP_SCHEMA_WRITE_CLASSES_V1, dl_1_12/IDM_ACP_SCHEMA_WRITE_CLASSES_V1.
pub fn dl11_schema_write_classes_v1()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 0u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 99u8, 104u8, 101u8, 109u8, 97u8, 95u8, 119u8, 114u8, 105u8, 116u8, 101u8, 95u8, 99u8, 108u8, 97u8, 115u8, 115u8, 101u8, 115u8]),
  uuid: 281474959933472u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 109u8, 101u8, 110u8, 116u8, 32u8, 111u8, 102u8, 32u8, 115u8, 99u8, 104u8, 101u8, 109u8, 97u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 101u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([16u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 116u8, 121u8, 112u8, 101u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 17u16, 19u16, 75u16, 44u16, 76u16, 48u16, 80u16]),
  modify_present_attrs: Vec::from([49u16, 19u16, 44u16, 48u16]),
  modify_removed_attrs: Vec::from([16u16, 19u16, 44u16, 48u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([15u16, 10u16]),
  create_attrs: Vec::from([16u16, 17u16, 19u16, 44u16, 48u16, 80u16]),
 }
}

/// Exact snapshot for dl11/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8, dl12/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8.
pub fn dl11_application_entry_manager_dl8()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]),
  uuid: 281474959933554u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 69u8, 110u8, 116u8, 114u8, 121u8, 77u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 97u8, 110u8, 100u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8]),
  receiver: 2u8,
  groups: Vec::from([]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 11u8, 0u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 80u16, 49u16, 20u16, 43u16, 78u16, 12u16, 79u16, 19u16, 41u16, 29u16]),
  modify_present_attrs: Vec::from([49u16, 19u16, 20u16, 43u16, 78u16, 12u16, 41u16]),
  modify_removed_attrs: Vec::from([49u16, 19u16, 20u16, 43u16, 78u16, 12u16, 79u16, 41u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact snapshot for dl11/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1, dl12/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1.
pub fn dl11_sync_account_manage_v1()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 121u8, 110u8, 99u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933541u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 73u8, 68u8, 77u8, 32u8, 115u8, 121u8, 110u8, 99u8, 104u8, 114u8, 111u8, 110u8, 105u8, 115u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 32u8, 47u8, 32u8, 99u8, 111u8, 110u8, 110u8, 101u8, 99u8, 116u8, 105u8, 111u8, 110u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([32u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 12u8, 0u8, 115u8, 121u8, 110u8, 99u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 80u16, 49u16, 19u16, 33u16, 72u16, 71u16, 73u16, 70u16]),
  modify_present_attrs: Vec::from([49u16, 19u16, 72u16, 71u16, 73u16]),
  modify_removed_attrs: Vec::from([49u16, 19u16, 33u16, 72u16, 71u16, 70u16, 73u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([15u16, 18u16]),
  create_attrs: Vec::from([16u16, 49u16, 19u16]),
 }
}

/// Exact snapshot for dl12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1, dl13/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1, dl14/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1, dl15/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1, dl_1_12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1.
pub fn dl12_service_account_entry_manager_v1()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]),
  uuid: 281474959933537u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8, 115u8, 32u8, 116u8, 111u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8]),
  receiver: 2u8,
  groups: Vec::from([]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 49u16, 68u16, 80u16, 29u16, 20u16, 69u16, 30u16, 42u16, 78u16, 65u16, 66u16, 0u16, 1u16, 12u16, 79u16, 43u16]),
  modify_present_attrs: Vec::from([20u16, 69u16, 66u16, 0u16, 1u16, 12u16]),
  modify_removed_attrs: Vec::from([20u16, 69u16, 66u16, 78u16, 65u16, 0u16, 1u16, 12u16, 79u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact snapshot for dl12/IDM_ACP_GROUP_MANAGE_DL9, dl13/IDM_ACP_GROUP_MANAGE_DL9, dl14/IDM_ACP_GROUP_MANAGE_DL9, dl15/IDM_ACP_GROUP_MANAGE_DL9, dl_1_12/IDM_ACP_GROUP_MANAGE_DL9.
pub fn dl12_group_manage_dl9()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933474u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 100u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 105u8, 110u8, 103u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 115u8, 32u8, 105u8, 110u8, 32u8, 116u8, 104u8, 101u8, 32u8, 100u8, 105u8, 114u8, 101u8, 99u8, 116u8, 111u8, 114u8, 121u8]),
  receiver: 1u8,
  groups: Vec::from([21u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 49u16, 80u16, 68u16, 80u16, 19u16, 43u16, 45u16, 46u16, 28u16, 29u16]),
  modify_present_attrs: Vec::from([49u16, 19u16, 43u16, 45u16, 29u16]),
  modify_removed_attrs: Vec::from([49u16, 19u16, 43u16, 45u16, 29u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([15u16, 11u16]),
  create_attrs: Vec::from([16u16, 49u16, 80u16, 19u16, 43u16, 45u16, 29u16]),
 }
}

/// Exact snapshot for dl13/IDM_ACP_OAUTH2_MANAGE.
pub fn dl13_oauth2_manage()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933493u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 32u8, 105u8, 110u8, 116u8, 101u8, 103u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([39u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 22u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 19u16, 20u16, 49u16, 80u16, 68u16, 63u16, 59u16, 60u16, 61u16, 62u16, 56u16, 50u16, 53u16, 54u16, 51u16, 57u16, 31u16, 64u16, 52u16, 36u16]),
  modify_present_attrs: Vec::from([19u16, 20u16, 49u16, 59u16, 60u16, 62u16, 61u16, 50u16, 53u16, 54u16, 51u16, 57u16, 31u16, 64u16, 52u16, 34u16, 35u16]),
  modify_removed_attrs: Vec::from([19u16, 20u16, 49u16, 63u16, 59u16, 60u16, 61u16, 62u16, 56u16, 50u16, 53u16, 54u16, 51u16, 57u16, 31u16, 64u16, 52u16, 34u16, 35u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([15u16, 5u16, 12u16, 13u16, 14u16]),
  create_attrs: Vec::from([16u16, 19u16, 49u16, 20u16, 58u16, 59u16, 60u16, 62u16, 61u16, 50u16, 53u16, 54u16, 51u16, 57u16, 31u16, 64u16, 52u16]),
 }
}

/// Exact snapshot for dl13/IDM_ACP_ACP_MANAGE_V1, dl14/IDM_ACP_ACP_MANAGE_V1, dl15/IDM_ACP_ACP_MANAGE_V1, dl_1_12/IDM_ACP_ACP_MANAGE_V1.
pub fn dl13_acp_manage_v1()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 99u8, 112u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933465u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 112u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8, 115u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 109u8, 101u8, 110u8, 116u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([17u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 22u8, 0u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 112u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 49u16, 80u16, 19u16, 4u16, 8u16, 10u16, 9u16, 7u16, 6u16, 5u16, 3u16, 2u16]),
  modify_present_attrs: Vec::from([16u16, 49u16, 19u16, 4u16, 8u16, 10u16, 9u16, 7u16, 6u16, 5u16, 3u16, 2u16]),
  modify_removed_attrs: Vec::from([16u16, 49u16, 19u16, 4u16, 8u16, 10u16, 9u16, 7u16, 6u16, 5u16, 3u16, 2u16]),
  modify_classes: Vec::from([3u16, 4u16, 2u16, 0u16, 1u16]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([3u16, 4u16, 2u16, 0u16, 1u16]),
  create_attrs: Vec::from([16u16, 49u16, 19u16, 4u16, 8u16, 10u16, 9u16, 7u16, 6u16, 5u16, 3u16, 2u16]),
 }
}

/// Exact snapshot for dl13/IDM_ACP_APPLICATION_MANAGE_DL8, dl14/IDM_ACP_APPLICATION_MANAGE_DL8, dl15/IDM_ACP_APPLICATION_MANAGE_DL8, dl_1_12/IDM_ACP_APPLICATION_MANAGE_DL8.
pub fn dl13_application_manage_dl8()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933555u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 100u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 32u8, 105u8, 110u8, 32u8, 116u8, 104u8, 101u8, 32u8, 100u8, 105u8, 114u8, 101u8, 99u8, 116u8, 111u8, 114u8, 121u8]),
  receiver: 1u8,
  groups: Vec::from([80u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 11u8, 0u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 80u16, 49u16, 68u16, 19u16, 20u16, 43u16, 78u16, 12u16, 79u16, 41u16, 29u16]),
  modify_present_attrs: Vec::from([49u16, 19u16, 20u16, 43u16, 78u16, 12u16, 41u16, 29u16]),
  modify_removed_attrs: Vec::from([49u16, 19u16, 20u16, 43u16, 78u16, 12u16, 79u16, 41u16, 29u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([15u16, 5u16, 17u16, 7u16]),
  create_attrs: Vec::from([16u16, 80u16, 49u16, 19u16, 20u16, 43u16, 41u16, 29u16]),
 }
}

/// Exact snapshot for dl13/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8, dl14/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8, dl15/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8, dl_1_12/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8.
pub fn dl13_application_entry_manager_dl8()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]),
  uuid: 281474959933554u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 69u8, 110u8, 116u8, 114u8, 121u8, 77u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 97u8, 110u8, 100u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8]),
  receiver: 2u8,
  groups: Vec::from([]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 11u8, 0u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 80u16, 49u16, 68u16, 20u16, 43u16, 78u16, 12u16, 79u16, 19u16, 41u16, 29u16]),
  modify_present_attrs: Vec::from([49u16, 19u16, 20u16, 43u16, 78u16, 12u16, 41u16]),
  modify_removed_attrs: Vec::from([49u16, 19u16, 20u16, 43u16, 78u16, 12u16, 79u16, 41u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact snapshot for dl13/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1, dl14/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1, dl15/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1, dl_1_12/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1.
pub fn dl13_sync_account_manage_v1()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 121u8, 110u8, 99u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933541u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 73u8, 68u8, 77u8, 32u8, 115u8, 121u8, 110u8, 99u8, 104u8, 114u8, 111u8, 110u8, 105u8, 115u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 32u8, 47u8, 32u8, 99u8, 111u8, 110u8, 110u8, 101u8, 99u8, 116u8, 105u8, 111u8, 110u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([32u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 12u8, 0u8, 115u8, 121u8, 110u8, 99u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 49u16, 80u16, 19u16, 33u16, 72u16, 71u16, 73u16, 70u16]),
  modify_present_attrs: Vec::from([49u16, 19u16, 72u16, 71u16, 73u16]),
  modify_removed_attrs: Vec::from([49u16, 19u16, 33u16, 72u16, 71u16, 70u16, 73u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([15u16, 18u16]),
  create_attrs: Vec::from([16u16, 49u16, 19u16]),
 }
}

/// Exact snapshot for dl14/IDM_ACP_OAUTH2_MANAGE, dl15/IDM_ACP_OAUTH2_MANAGE, dl_1_12/IDM_ACP_OAUTH2_MANAGE.
pub fn dl14_oauth2_manage()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933493u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 32u8, 105u8, 110u8, 116u8, 101u8, 103u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([39u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 22u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 19u16, 20u16, 49u16, 80u16, 68u16, 63u16, 59u16, 60u16, 61u16, 62u16, 56u16, 50u16, 53u16, 54u16, 55u16, 51u16, 57u16, 31u16, 64u16, 52u16, 36u16]),
  modify_present_attrs: Vec::from([19u16, 20u16, 49u16, 59u16, 60u16, 62u16, 61u16, 50u16, 53u16, 54u16, 55u16, 51u16, 57u16, 31u16, 64u16, 52u16, 34u16, 35u16]),
  modify_removed_attrs: Vec::from([19u16, 20u16, 49u16, 63u16, 59u16, 60u16, 61u16, 62u16, 56u16, 50u16, 53u16, 54u16, 55u16, 51u16, 57u16, 31u16, 64u16, 52u16, 34u16, 35u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([15u16, 5u16, 12u16, 13u16, 14u16]),
  create_attrs: Vec::from([16u16, 19u16, 49u16, 20u16, 58u16, 59u16, 60u16, 62u16, 61u16, 50u16, 53u16, 54u16, 55u16, 51u16, 57u16, 31u16, 64u16, 52u16]),
 }
}

/// Exact snapshot for dl14/IDM_ACP_DOMAIN_ADMIN_DL9, dl15/IDM_ACP_DOMAIN_ADMIN_DL9, dl_1_12/IDM_ACP_DOMAIN_ADMIN_DL9.
pub fn dl14_domain_admin_dl9()->Profile {
 Profile {
  classes: Vec::from([15u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]),
  uuid: 281474959933478u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 103u8, 114u8, 97u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 105u8, 110u8, 102u8, 111u8, 32u8, 97u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 108u8, 111u8, 99u8, 97u8, 108u8, 108u8, 121u8]),
  receiver: 1u8,
  groups: Vec::from([32u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 4u8, 0u8, 117u8, 117u8, 105u8, 100u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 102u8, 102u8, 102u8, 102u8, 102u8, 102u8, 48u8, 48u8, 48u8, 48u8, 50u8, 53u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([16u16, 49u16, 80u16, 22u16, 21u16, 23u16, 25u16, 24u16, 38u16, 26u16, 27u16, 36u16, 37u16, 81u16, 31u16]),
  modify_present_attrs: Vec::from([23u16, 24u16, 38u16, 26u16, 22u16, 21u16, 37u16, 34u16, 35u16, 31u16]),
  modify_removed_attrs: Vec::from([23u16, 26u16, 24u16, 38u16, 22u16, 21u16, 37u16, 34u16, 35u16, 31u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}
