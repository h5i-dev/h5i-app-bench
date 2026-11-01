//! Complete remaining pinned built-in ACP records. See DEVIATIONS.md.
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

/// Exact complete record for dl11/IDM_ACP_ACCOUNT_MAIL_READ_DL6, dl12/IDM_ACP_ACCOUNT_MAIL_READ_DL6, dl13/IDM_ACP_ACCOUNT_MAIL_READ_DL6, dl14/IDM_ACP_ACCOUNT_MAIL_READ_DL6, dl15/IDM_ACP_ACCOUNT_MAIL_READ_DL6, dl_1_12/IDM_ACP_ACCOUNT_MAIL_READ_DL6.
pub fn dl11_account_mail_read_dl6()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 109u8, 97u8, 105u8, 108u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
  uuid: 281474959933509u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 114u8, 101u8, 97u8, 100u8, 105u8, 110u8, 103u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 97u8, 110u8, 100u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 109u8, 97u8, 105u8, 108u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([57u128]),
  target: Vec::from([1u8, 2u8, 0u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([53u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_ACCOUNT_SELF_WRITE_V1, dl12/IDM_ACP_ACCOUNT_SELF_WRITE_V1, dl13/IDM_ACP_ACCOUNT_SELF_WRITE_V1, dl14/IDM_ACP_ACCOUNT_SELF_WRITE_V1, dl15/IDM_ACP_ACCOUNT_SELF_WRITE_V1, dl_1_12/IDM_ACP_ACCOUNT_SELF_WRITE_V1.
pub fn dl11_account_self_write_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 115u8, 101u8, 108u8, 102u8, 95u8, 119u8, 114u8, 105u8, 116u8, 101u8]),
  uuid: 281474959933510u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 115u8, 101u8, 108u8, 102u8, 32u8, 119u8, 114u8, 105u8, 116u8, 101u8, 32u8, 45u8, 32u8, 114u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 100u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 32u8, 116u8, 111u8, 32u8, 117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 32u8, 116u8, 104u8, 101u8, 105u8, 114u8, 32u8, 111u8, 119u8, 110u8, 32u8, 115u8, 101u8, 115u8, 115u8, 105u8, 111u8, 110u8, 32u8, 115u8, 116u8, 97u8, 116u8, 101u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([54u128]),
  target: Vec::from([4u8]),
  search_attrs: Vec::from([]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([108u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1, dl12/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1, dl13/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1, dl14/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1, dl15/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1, dl_1_12/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1.
pub fn dl11_account_unix_extend_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 117u8, 110u8, 105u8, 120u8, 95u8, 101u8, 120u8, 116u8, 101u8, 110u8, 100u8]),
  uuid: 281474959933545u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 100u8, 32u8, 101u8, 120u8, 116u8, 101u8, 110u8, 100u8, 105u8, 110u8, 103u8, 32u8, 117u8, 110u8, 105u8, 120u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([68u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 96u16, 26u16, 38u16, 52u16, 107u16, 97u16]),
  modify_present_attrs: Vec::from([21u16, 38u16, 52u16, 107u16, 97u16]),
  modify_removed_attrs: Vec::from([38u16, 52u16, 107u16, 97u16]),
  modify_classes: Vec::from([22u16]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_ACP_MANAGE_V1, dl12/IDM_ACP_ACP_MANAGE_V1.
pub fn dl11_acp_manage_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 99u8, 112u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933465u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 112u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8, 115u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 109u8, 101u8, 110u8, 116u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([17u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 22u8, 0u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 112u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 26u16, 5u16, 9u16, 11u16, 10u16, 8u16, 7u16, 6u16, 4u16, 3u16]),
  modify_present_attrs: Vec::from([21u16, 61u16, 26u16, 5u16, 9u16, 11u16, 10u16, 8u16, 7u16, 6u16, 4u16, 3u16]),
  modify_removed_attrs: Vec::from([21u16, 61u16, 26u16, 5u16, 9u16, 11u16, 10u16, 8u16, 7u16, 6u16, 4u16, 3u16]),
  modify_classes: Vec::from([3u16, 4u16, 2u16, 0u16, 1u16]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([3u16, 4u16, 2u16, 0u16, 1u16]),
  create_attrs: Vec::from([21u16, 61u16, 26u16, 5u16, 9u16, 11u16, 10u16, 8u16, 7u16, 6u16, 4u16, 3u16]),
 }
}

/// Exact complete record for dl11/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1.
pub fn dl11_all_accounts_posix_read_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 108u8, 108u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 95u8, 112u8, 111u8, 115u8, 105u8, 120u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
  uuid: 281474959933446u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 114u8, 101u8, 97u8, 100u8, 105u8, 110u8, 103u8, 32u8, 109u8, 105u8, 110u8, 105u8, 109u8, 97u8, 108u8, 32u8, 112u8, 111u8, 115u8, 105u8, 120u8, 32u8, 97u8, 116u8, 116u8, 114u8, 115u8, 32u8, 45u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 101u8, 115u8, 32u8, 97u8, 110u8, 111u8, 110u8, 121u8, 109u8, 111u8, 117u8, 115u8, 32u8, 97u8, 110u8, 100u8, 32u8, 97u8, 108u8, 108u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 101u8, 100u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([54u128]),
  target: Vec::from([1u8, 2u8, 0u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 27u16, 21u16, 57u16, 56u16, 35u16, 109u16, 38u16, 52u16, 97u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8, dl12/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8.
pub fn dl11_application_entry_manager_dl8()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]),
  uuid: 281474959933554u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 69u8, 110u8, 116u8, 114u8, 121u8, 77u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 97u8, 110u8, 100u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8]),
  receiver: 2u8,
  groups: Vec::from([]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 11u8, 0u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 61u16, 27u16, 53u16, 107u16, 13u16, 108u16, 26u16, 51u16, 37u16]),
  modify_present_attrs: Vec::from([61u16, 26u16, 27u16, 53u16, 107u16, 13u16, 51u16]),
  modify_removed_attrs: Vec::from([61u16, 26u16, 27u16, 53u16, 107u16, 13u16, 108u16, 51u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_APPLICATION_MANAGE_DL8, dl12/IDM_ACP_APPLICATION_MANAGE_DL8.
pub fn dl11_application_manage_dl8()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933555u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 100u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 32u8, 105u8, 110u8, 32u8, 116u8, 104u8, 101u8, 32u8, 100u8, 105u8, 114u8, 101u8, 99u8, 116u8, 111u8, 114u8, 121u8]),
  receiver: 1u8,
  groups: Vec::from([80u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 11u8, 0u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 61u16, 26u16, 27u16, 53u16, 107u16, 13u16, 108u16, 51u16, 37u16]),
  modify_present_attrs: Vec::from([61u16, 26u16, 27u16, 53u16, 107u16, 13u16, 51u16, 37u16]),
  modify_removed_attrs: Vec::from([61u16, 26u16, 27u16, 53u16, 107u16, 13u16, 108u16, 51u16, 37u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 5u16, 25u16, 7u16]),
  create_attrs: Vec::from([21u16, 109u16, 61u16, 26u16, 27u16, 53u16, 51u16, 37u16]),
 }
}

/// Exact complete record for dl11/IDM_ACP_DOMAIN_ADMIN_DL9, dl12/IDM_ACP_DOMAIN_ADMIN_DL9, dl13/IDM_ACP_DOMAIN_ADMIN_DL9.
pub fn dl11_domain_admin_dl9()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]),
  uuid: 281474959933478u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 103u8, 114u8, 97u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 105u8, 110u8, 102u8, 111u8, 32u8, 97u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 108u8, 111u8, 99u8, 97u8, 108u8, 108u8, 121u8]),
  receiver: 1u8,
  groups: Vec::from([32u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 4u8, 0u8, 117u8, 117u8, 105u8, 100u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 102u8, 102u8, 102u8, 102u8, 102u8, 102u8, 48u8, 48u8, 48u8, 48u8, 50u8, 53u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 29u16, 30u16, 32u16, 31u16, 47u16, 33u16, 34u16, 44u16, 46u16, 110u16, 39u16]),
  modify_present_attrs: Vec::from([30u16, 31u16, 47u16, 33u16, 29u16, 46u16, 42u16, 43u16, 39u16]),
  modify_removed_attrs: Vec::from([30u16, 33u16, 31u16, 47u16, 29u16, 46u16, 42u16, 43u16, 39u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8, dl12/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8, dl13/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8, dl14/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8, dl15/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8, dl_1_12/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8.
pub fn dl11_group_account_policy_manage_dl8()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933513u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 109u8, 101u8, 110u8, 116u8, 32u8, 111u8, 102u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8, 32u8, 111u8, 110u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([71u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 18u16, 17u16, 23u16, 91u16, 111u16, 50u16, 49u16, 12u16]),
  modify_present_attrs: Vec::from([21u16, 18u16, 17u16, 23u16, 91u16, 111u16, 50u16, 49u16, 12u16]),
  modify_removed_attrs: Vec::from([21u16, 18u16, 17u16, 23u16, 91u16, 111u16, 50u16, 49u16, 12u16]),
  modify_classes: Vec::from([6u16]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1, dl12/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1, dl13/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1, dl14/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1, dl15/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1, dl_1_12/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1.
pub fn dl11_group_entry_managed_by_modify_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 100u8, 95u8, 98u8, 121u8, 95u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8]),
  uuid: 281474959933512u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 100u8, 95u8, 98u8, 121u8, 32u8, 116u8, 111u8, 32u8, 98u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 110u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 101u8, 110u8, 116u8, 114u8, 105u8, 101u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([17u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 109u16, 37u16]),
  modify_present_attrs: Vec::from([37u16]),
  modify_removed_attrs: Vec::from([37u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_GROUP_ENTRY_MANAGER_V1, dl12/IDM_ACP_GROUP_ENTRY_MANAGER_V1, dl13/IDM_ACP_GROUP_ENTRY_MANAGER_V1, dl14/IDM_ACP_GROUP_ENTRY_MANAGER_V1, dl15/IDM_ACP_GROUP_ENTRY_MANAGER_V1, dl_1_12/IDM_ACP_GROUP_ENTRY_MANAGER_V1.
pub fn dl11_group_entry_manager_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]),
  uuid: 281474959933520u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 69u8, 110u8, 116u8, 114u8, 121u8, 77u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 97u8, 110u8, 100u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 115u8]),
  receiver: 2u8,
  groups: Vec::from([]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 96u16, 109u16, 26u16, 56u16, 35u16, 37u16]),
  modify_present_attrs: Vec::from([26u16, 56u16]),
  modify_removed_attrs: Vec::from([26u16, 56u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_GROUP_MANAGE_DL9.
pub fn dl11_group_manage_dl9()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933474u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 100u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 105u8, 110u8, 103u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 115u8, 32u8, 105u8, 110u8, 32u8, 116u8, 104u8, 101u8, 32u8, 100u8, 105u8, 114u8, 101u8, 99u8, 116u8, 111u8, 114u8, 121u8]),
  receiver: 1u8,
  groups: Vec::from([21u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 96u16, 109u16, 26u16, 53u16, 56u16, 35u16, 37u16]),
  modify_present_attrs: Vec::from([61u16, 26u16, 53u16, 56u16, 37u16]),
  modify_removed_attrs: Vec::from([61u16, 26u16, 53u16, 56u16, 37u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 13u16]),
  create_attrs: Vec::from([21u16, 61u16, 109u16, 26u16, 53u16, 56u16, 37u16]),
 }
}

/// Exact complete record for dl11/IDM_ACP_GROUP_READ_V1.
pub fn dl11_group_read_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
  uuid: 281474959933522u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 97u8, 108u8, 108u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 115u8, 32u8, 116u8, 111u8, 32u8, 98u8, 101u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 98u8, 121u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([17u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 35u16, 61u16, 109u16, 96u16, 26u16, 56u16, 37u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_GROUP_UNIX_MANAGE_V1, dl12/IDM_ACP_GROUP_UNIX_MANAGE_V1, dl13/IDM_ACP_GROUP_UNIX_MANAGE_V1, dl14/IDM_ACP_GROUP_UNIX_MANAGE_V1, dl15/IDM_ACP_GROUP_UNIX_MANAGE_V1, dl_1_12/IDM_ACP_GROUP_UNIX_MANAGE_V1.
pub fn dl11_group_unix_manage_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8, 95u8, 117u8, 110u8, 105u8, 120u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933544u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 117u8, 110u8, 105u8, 120u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([68u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([35u16, 21u16, 61u16, 109u16, 96u16, 26u16, 56u16, 38u16]),
  modify_present_attrs: Vec::from([21u16, 38u16]),
  modify_removed_attrs: Vec::from([38u16]),
  modify_classes: Vec::from([23u16]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7, dl12/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7, dl13/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7, dl14/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7, dl15/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7, dl_1_12/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7.
pub fn dl11_hp_client_certificate_manager_dl7()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 104u8, 112u8, 95u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 95u8, 99u8, 101u8, 114u8, 116u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 101u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]),
  uuid: 281474959933553u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 32u8, 99u8, 101u8, 114u8, 116u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 101u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 109u8, 101u8, 110u8, 116u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([73u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 18u8, 0u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 95u8, 99u8, 101u8, 114u8, 116u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 101u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 20u16, 93u16]),
  modify_present_attrs: Vec::from([20u16, 93u16]),
  modify_removed_attrs: Vec::from([20u16, 93u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 11u16]),
  create_attrs: Vec::from([21u16, 20u16, 93u16]),
 }
}

/// Exact complete record for dl11/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1.
pub fn dl11_hp_group_unix_manage_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 104u8, 112u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8, 95u8, 117u8, 110u8, 105u8, 120u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933543u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 100u8, 32u8, 101u8, 120u8, 116u8, 101u8, 110u8, 100u8, 105u8, 110u8, 103u8, 32u8, 104u8, 105u8, 103u8, 104u8, 32u8, 112u8, 114u8, 105u8, 118u8, 105u8, 108u8, 101u8, 103u8, 101u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 115u8, 32u8, 119u8, 105u8, 116u8, 104u8, 32u8, 117u8, 110u8, 105u8, 120u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([68u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([35u16, 21u16, 61u16, 109u16, 96u16, 26u16, 56u16, 38u16]),
  modify_present_attrs: Vec::from([21u16, 38u16]),
  modify_removed_attrs: Vec::from([38u16]),
  modify_classes: Vec::from([23u16]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1, dl12/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1, dl13/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1, dl14/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1, dl15/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1, dl_1_12/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1.
pub fn dl11_hp_people_credential_reset_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 104u8, 112u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 95u8, 114u8, 101u8, 115u8, 101u8, 116u8]),
  uuid: 281474959933528u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 114u8, 101u8, 115u8, 101u8, 116u8, 116u8, 105u8, 110u8, 103u8, 32u8, 104u8, 105u8, 103u8, 104u8, 32u8, 112u8, 114u8, 105u8, 118u8, 105u8, 108u8, 101u8, 103u8, 101u8, 32u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 115u8, 32u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 115u8, 32u8]),
  receiver: 1u8,
  groups: Vec::from([19u128]),
  target: Vec::from([1u8, 4u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 61u16, 96u16, 90u16, 0u16, 2u16, 88u16, 15u16]),
  modify_present_attrs: Vec::from([90u16, 0u16, 2u16, 88u16, 15u16]),
  modify_removed_attrs: Vec::from([90u16, 0u16, 2u16, 88u16, 15u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1, dl12/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1, dl13/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1, dl14/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1, dl15/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1, dl_1_12/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1.
pub fn dl11_hp_service_account_entry_managed_by_modify_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 104u8, 112u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 100u8, 95u8, 98u8, 121u8]),
  uuid: 281474959933539u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 100u8, 95u8, 98u8, 121u8, 32u8, 116u8, 111u8, 32u8, 98u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 110u8, 32u8, 104u8, 105u8, 103u8, 104u8, 32u8, 112u8, 114u8, 105u8, 118u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 101u8, 110u8, 116u8, 114u8, 105u8, 101u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([17u128]),
  target: Vec::from([1u8, 4u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 109u16, 37u16]),
  modify_present_attrs: Vec::from([37u16]),
  modify_removed_attrs: Vec::from([37u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_MAIL_SERVERS_DL8, dl12/IDM_ACP_MAIL_SERVERS_DL8.
pub fn dl11_mail_servers_dl8()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 109u8, 97u8, 105u8, 108u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 115u8]),
  uuid: 281474959933556u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 77u8, 65u8, 73u8, 76u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 115u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 101u8, 109u8, 97u8, 105u8, 108u8, 32u8, 97u8, 100u8, 100u8, 114u8, 101u8, 115u8, 115u8, 101u8, 115u8, 32u8, 97u8, 110u8, 100u8, 32u8, 111u8, 116u8, 104u8, 101u8, 114u8, 32u8, 110u8, 101u8, 101u8, 100u8, 101u8, 100u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([82u128]),
  target: Vec::from([1u8, 2u8, 0u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 109u16, 27u16, 53u16, 56u16, 35u16, 57u16, 38u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_OAUTH2_MANAGE, dl12/IDM_ACP_OAUTH2_MANAGE.
pub fn dl11_oauth2_manage()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933493u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 32u8, 105u8, 110u8, 116u8, 101u8, 103u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([39u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 22u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 26u16, 27u16, 61u16, 96u16, 84u16, 80u16, 81u16, 82u16, 83u16, 77u16, 66u16, 73u16, 74u16, 67u16, 78u16, 39u16, 85u16, 72u16, 44u16]),
  modify_present_attrs: Vec::from([26u16, 27u16, 61u16, 80u16, 81u16, 83u16, 82u16, 66u16, 73u16, 74u16, 67u16, 78u16, 39u16, 85u16, 72u16, 42u16, 43u16]),
  modify_removed_attrs: Vec::from([26u16, 27u16, 61u16, 84u16, 80u16, 81u16, 82u16, 83u16, 77u16, 66u16, 73u16, 74u16, 67u16, 78u16, 39u16, 85u16, 72u16, 42u16, 43u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 5u16, 16u16, 17u16, 18u16]),
  create_attrs: Vec::from([21u16, 26u16, 61u16, 27u16, 79u16, 80u16, 81u16, 83u16, 82u16, 66u16, 73u16, 74u16, 67u16, 78u16, 39u16, 85u16, 72u16]),
 }
}

/// Exact complete record for dl11/IDM_ACP_PEOPLE_CREATE_DL6, dl12/IDM_ACP_PEOPLE_CREATE_DL6, dl13/IDM_ACP_PEOPLE_CREATE_DL6, dl14/IDM_ACP_PEOPLE_CREATE_DL6, dl15/IDM_ACP_PEOPLE_CREATE_DL6, dl_1_12/IDM_ACP_PEOPLE_CREATE_DL6.
pub fn dl11_people_create_dl6()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 99u8, 114u8, 101u8, 97u8, 116u8, 101u8]),
  uuid: 281474959933524u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 110u8, 101u8, 119u8, 32u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([19u128, 69u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 5u16, 21u16]),
  create_attrs: Vec::from([21u16, 109u16, 61u16, 27u16, 53u16, 0u16, 2u16]),
 }
}

/// Exact complete record for dl11/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1, dl12/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1.
pub fn dl11_people_credential_reset_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 95u8, 114u8, 101u8, 115u8, 101u8, 116u8]),
  uuid: 281474959933527u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 114u8, 101u8, 115u8, 101u8, 116u8, 116u8, 105u8, 110u8, 103u8, 32u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 115u8, 32u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 115u8, 32u8]),
  receiver: 1u8,
  groups: Vec::from([19u128, 65u128, 69u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 61u16, 96u16, 90u16, 0u16, 2u16, 88u16, 15u16]),
  modify_present_attrs: Vec::from([90u16, 88u16, 15u16]),
  modify_removed_attrs: Vec::from([90u16, 88u16, 15u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_PEOPLE_DELETE_V1, dl12/IDM_ACP_PEOPLE_DELETE_V1, dl13/IDM_ACP_PEOPLE_DELETE_V1, dl14/IDM_ACP_PEOPLE_DELETE_V1, dl15/IDM_ACP_PEOPLE_DELETE_V1, dl_1_12/IDM_ACP_PEOPLE_DELETE_V1.
pub fn dl11_people_delete_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 1u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 100u8, 101u8, 108u8, 101u8, 116u8, 101u8]),
  uuid: 281474959933525u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 105u8, 110u8, 103u8, 32u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([19u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_PEOPLE_MANAGE_V1, dl12/IDM_ACP_PEOPLE_MANAGE_V1, dl13/IDM_ACP_PEOPLE_MANAGE_V1, dl14/IDM_ACP_PEOPLE_MANAGE_V1, dl15/IDM_ACP_PEOPLE_MANAGE_V1, dl_1_12/IDM_ACP_PEOPLE_MANAGE_V1.
pub fn dl11_people_manage_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933526u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 109u8, 101u8, 110u8, 116u8, 32u8, 111u8, 102u8, 32u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 115u8, 32u8, 110u8, 111u8, 110u8, 32u8, 115u8, 101u8, 110u8, 115u8, 105u8, 116u8, 105u8, 118u8, 101u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([19u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([]),
  modify_present_attrs: Vec::from([0u16, 2u16]),
  modify_removed_attrs: Vec::from([0u16, 2u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_PEOPLE_PII_MANAGE_V1, dl12/IDM_ACP_PEOPLE_PII_MANAGE_V1, dl13/IDM_ACP_PEOPLE_PII_MANAGE_V1, dl14/IDM_ACP_PEOPLE_PII_MANAGE_V1, dl15/IDM_ACP_PEOPLE_PII_MANAGE_V1, dl_1_12/IDM_ACP_PEOPLE_PII_MANAGE_V1.
pub fn dl11_people_pii_manage_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 112u8, 105u8, 105u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933459u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 105u8, 110u8, 103u8, 32u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 115u8, 32u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 97u8, 108u8, 32u8, 97u8, 110u8, 100u8, 32u8, 115u8, 101u8, 110u8, 115u8, 105u8, 116u8, 105u8, 118u8, 101u8, 32u8, 100u8, 97u8, 116u8, 97u8]),
  receiver: 1u8,
  groups: Vec::from([19u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([]),
  modify_present_attrs: Vec::from([61u16, 27u16, 48u16, 53u16]),
  modify_removed_attrs: Vec::from([61u16, 27u16, 48u16, 53u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_PEOPLE_PII_READ_V1, dl12/IDM_ACP_PEOPLE_PII_READ_V1, dl13/IDM_ACP_PEOPLE_PII_READ_V1, dl14/IDM_ACP_PEOPLE_PII_READ_V1, dl15/IDM_ACP_PEOPLE_PII_READ_V1, dl_1_12/IDM_ACP_PEOPLE_PII_READ_V1.
pub fn dl11_people_pii_read_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 112u8, 105u8, 105u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
  uuid: 281474959933447u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 114u8, 101u8, 97u8, 100u8, 105u8, 110u8, 103u8, 32u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 97u8, 108u8, 32u8, 97u8, 110u8, 100u8, 32u8, 115u8, 101u8, 110u8, 115u8, 105u8, 116u8, 105u8, 118u8, 101u8, 32u8, 100u8, 97u8, 116u8, 97u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([19u128, 2u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 96u16, 27u16, 48u16, 53u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_PEOPLE_READ_V1, dl12/IDM_ACP_PEOPLE_READ_V1, dl13/IDM_ACP_PEOPLE_READ_V1, dl14/IDM_ACP_PEOPLE_READ_V1, dl15/IDM_ACP_PEOPLE_READ_V1, dl_1_12/IDM_ACP_PEOPLE_READ_V1.
pub fn dl11_people_read_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
  uuid: 281474959933523u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 114u8, 101u8, 97u8, 100u8, 105u8, 110u8, 103u8, 32u8, 110u8, 111u8, 110u8, 45u8, 115u8, 101u8, 110u8, 115u8, 105u8, 116u8, 105u8, 118u8, 101u8, 32u8, 100u8, 97u8, 116u8, 97u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([19u128, 2u128, 57u128, 65u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 109u16, 27u16, 57u16, 109u16, 0u16, 2u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1, dl12/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1, dl13/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1, dl14/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1, dl15/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1, dl_1_12/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1.
pub fn dl11_people_self_write_mail_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 115u8, 101u8, 108u8, 102u8, 95u8, 119u8, 114u8, 105u8, 116u8, 101u8, 95u8, 109u8, 97u8, 105u8, 108u8]),
  uuid: 281474959933505u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 115u8, 101u8, 108u8, 102u8, 32u8, 119u8, 114u8, 105u8, 116u8, 101u8, 32u8, 111u8, 102u8, 32u8, 109u8, 97u8, 105u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([51u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 4u8]),
  search_attrs: Vec::from([]),
  modify_present_attrs: Vec::from([53u16]),
  modify_removed_attrs: Vec::from([53u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_RADIUS_SECRET_MANAGE_V1, dl12/IDM_ACP_RADIUS_SECRET_MANAGE_V1, dl13/IDM_ACP_RADIUS_SECRET_MANAGE_V1, dl14/IDM_ACP_RADIUS_SECRET_MANAGE_V1, dl15/IDM_ACP_RADIUS_SECRET_MANAGE_V1, dl_1_12/IDM_ACP_RADIUS_SECRET_MANAGE_V1.
pub fn dl11_radius_secret_manage_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 114u8, 97u8, 100u8, 105u8, 117u8, 115u8, 95u8, 115u8, 101u8, 99u8, 114u8, 101u8, 116u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933542u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 114u8, 101u8, 97u8, 100u8, 115u8, 32u8, 97u8, 110u8, 100u8, 32u8, 119u8, 114u8, 105u8, 116u8, 101u8, 115u8, 32u8, 116u8, 111u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 114u8, 97u8, 100u8, 105u8, 117u8, 115u8, 32u8, 115u8, 101u8, 99u8, 114u8, 101u8, 116u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([67u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([92u16]),
  modify_present_attrs: Vec::from([92u16]),
  modify_removed_attrs: Vec::from([92u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_RADIUS_SERVERS_V1.
pub fn dl11_radius_servers_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 114u8, 97u8, 100u8, 105u8, 117u8, 115u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 115u8]),
  uuid: 281474959933460u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 82u8, 65u8, 68u8, 73u8, 85u8, 83u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 115u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 115u8, 32u8, 97u8, 110u8, 100u8, 32u8, 111u8, 116u8, 104u8, 101u8, 114u8, 32u8, 110u8, 101u8, 101u8, 100u8, 101u8, 100u8, 32u8, 100u8, 101u8, 116u8, 97u8, 105u8, 108u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([7u128]),
  target: Vec::from([1u8, 2u8, 0u8, 5u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 109u16, 92u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_RECYCLE_BIN_REVIVE_V1, dl12/IDM_ACP_RECYCLE_BIN_REVIVE_V1, dl13/IDM_ACP_RECYCLE_BIN_REVIVE_V1, dl14/IDM_ACP_RECYCLE_BIN_REVIVE_V1, dl15/IDM_ACP_RECYCLE_BIN_REVIVE_V1, dl_1_12/IDM_ACP_RECYCLE_BIN_REVIVE_V1.
pub fn dl11_recycle_bin_revive_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 95u8, 98u8, 105u8, 110u8, 95u8, 114u8, 101u8, 118u8, 105u8, 118u8, 101u8]),
  uuid: 281474959933443u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 32u8, 98u8, 105u8, 110u8, 32u8, 114u8, 101u8, 118u8, 105u8, 118u8, 101u8, 32u8, 112u8, 101u8, 114u8, 109u8, 105u8, 115u8, 115u8, 105u8, 111u8, 110u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([66u128]),
  target: Vec::from([0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8]),
  search_attrs: Vec::from([]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([21u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([24u16]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_RECYCLE_BIN_SEARCH_V1, dl12/IDM_ACP_RECYCLE_BIN_SEARCH_V1, dl13/IDM_ACP_RECYCLE_BIN_SEARCH_V1, dl14/IDM_ACP_RECYCLE_BIN_SEARCH_V1, dl15/IDM_ACP_RECYCLE_BIN_SEARCH_V1, dl_1_12/IDM_ACP_RECYCLE_BIN_SEARCH_V1.
pub fn dl11_recycle_bin_search_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 95u8, 98u8, 105u8, 110u8, 95u8, 115u8, 101u8, 97u8, 114u8, 99u8, 104u8]),
  uuid: 281474959933442u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 32u8, 98u8, 105u8, 110u8, 32u8, 115u8, 101u8, 97u8, 114u8, 99u8, 104u8, 32u8, 112u8, 101u8, 114u8, 109u8, 105u8, 115u8, 115u8, 105u8, 111u8, 110u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([66u128]),
  target: Vec::from([0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 45u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_SCHEMA_WRITE_ATTRS_V1, dl12/IDM_ACP_SCHEMA_WRITE_ATTRS_V1, dl13/IDM_ACP_SCHEMA_WRITE_ATTRS_V1, dl14/IDM_ACP_SCHEMA_WRITE_ATTRS_V1, dl15/IDM_ACP_SCHEMA_WRITE_ATTRS_V1, dl_1_12/IDM_ACP_SCHEMA_WRITE_ATTRS_V1.
pub fn dl11_schema_write_attrs_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 99u8, 104u8, 101u8, 109u8, 97u8, 95u8, 119u8, 114u8, 105u8, 116u8, 101u8, 95u8, 97u8, 116u8, 116u8, 114u8, 115u8]),
  uuid: 281474959933464u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 109u8, 101u8, 110u8, 116u8, 32u8, 111u8, 102u8, 32u8, 115u8, 99u8, 104u8, 101u8, 109u8, 97u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([16u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 13u8, 0u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 116u8, 121u8, 112u8, 101u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 26u16, 40u16, 106u16, 59u16, 16u16, 103u16, 109u16]),
  modify_present_attrs: Vec::from([26u16, 40u16, 106u16, 59u16, 103u16]),
  modify_removed_attrs: Vec::from([26u16, 40u16, 106u16, 59u16, 103u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 8u16]),
  create_attrs: Vec::from([21u16, 26u16, 40u16, 106u16, 59u16, 16u16, 103u16, 109u16]),
 }
}

/// Exact complete record for dl11/IDM_ACP_SCHEMA_WRITE_CLASSES_V1, dl12/IDM_ACP_SCHEMA_WRITE_CLASSES_V1, dl13/IDM_ACP_SCHEMA_WRITE_CLASSES_V1, dl14/IDM_ACP_SCHEMA_WRITE_CLASSES_V1, dl15/IDM_ACP_SCHEMA_WRITE_CLASSES_V1, dl_1_12/IDM_ACP_SCHEMA_WRITE_CLASSES_V1.
pub fn dl11_schema_write_classes_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 99u8, 104u8, 101u8, 109u8, 97u8, 95u8, 119u8, 114u8, 105u8, 116u8, 101u8, 95u8, 99u8, 108u8, 97u8, 115u8, 115u8, 101u8, 115u8]),
  uuid: 281474959933472u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 109u8, 101u8, 110u8, 116u8, 32u8, 111u8, 102u8, 32u8, 115u8, 99u8, 104u8, 101u8, 109u8, 97u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 101u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([16u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 116u8, 121u8, 112u8, 101u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 22u16, 26u16, 104u16, 55u16, 105u16, 60u16, 109u16]),
  modify_present_attrs: Vec::from([61u16, 26u16, 55u16, 60u16]),
  modify_removed_attrs: Vec::from([21u16, 26u16, 55u16, 60u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 10u16]),
  create_attrs: Vec::from([21u16, 22u16, 26u16, 55u16, 60u16, 109u16]),
 }
}

/// Exact complete record for dl11/IDM_ACP_SELF_NAME_WRITE_DL7, dl12/IDM_ACP_SELF_NAME_WRITE_DL7, dl13/IDM_ACP_SELF_NAME_WRITE_DL7, dl14/IDM_ACP_SELF_NAME_WRITE_DL7, dl15/IDM_ACP_SELF_NAME_WRITE_DL7, dl_1_12/IDM_ACP_SELF_NAME_WRITE_DL7.
pub fn dl11_self_name_write_dl7()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 108u8, 102u8, 95u8, 110u8, 97u8, 109u8, 101u8, 95u8, 119u8, 114u8, 105u8, 116u8, 101u8]),
  uuid: 281474959933521u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 115u8, 101u8, 108u8, 102u8, 32u8, 119u8, 114u8, 105u8, 116u8, 101u8, 32u8, 111u8, 102u8, 32u8, 110u8, 97u8, 109u8, 101u8, 32u8, 45u8, 32u8, 114u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 100u8, 32u8, 102u8, 111u8, 114u8, 32u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 32u8, 116u8, 111u8, 32u8, 117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 32u8, 116u8, 104u8, 101u8, 105u8, 114u8, 32u8, 111u8, 119u8, 110u8, 32u8, 105u8, 100u8, 101u8, 110u8, 116u8, 105u8, 116u8, 105u8, 101u8, 115u8, 32u8, 105u8, 110u8, 32u8, 108u8, 105u8, 110u8, 101u8, 32u8, 119u8, 105u8, 116u8, 104u8, 32u8, 98u8, 101u8, 115u8, 116u8, 32u8, 112u8, 114u8, 97u8, 99u8, 116u8, 105u8, 99u8, 101u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([72u128]),
  target: Vec::from([1u8, 3u8, 0u8, 4u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([]),
  modify_present_attrs: Vec::from([61u16, 27u16, 48u16]),
  modify_removed_attrs: Vec::from([61u16, 27u16, 48u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_SELF_READ_DL8, dl12/IDM_ACP_SELF_READ_DL8.
pub fn dl11_self_read_dl8()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 108u8, 102u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
  uuid: 281474959933444u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 115u8, 101u8, 108u8, 102u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 45u8, 32u8, 114u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 100u8, 32u8, 102u8, 111u8, 114u8, 32u8, 119u8, 104u8, 111u8, 97u8, 109u8, 105u8, 32u8, 97u8, 110u8, 100u8, 32u8, 109u8, 97u8, 110u8, 121u8, 32u8, 111u8, 116u8, 104u8, 101u8, 114u8, 32u8, 102u8, 117u8, 110u8, 99u8, 116u8, 105u8, 111u8, 110u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([54u128]),
  target: Vec::from([4u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 27u16, 48u16, 21u16, 57u16, 53u16, 92u16, 38u16, 52u16, 109u16, 100u16, 0u16, 2u16, 90u16, 108u16, 88u16, 15u16, 14u16, 97u16, 107u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_SELF_WRITE_DL8, dl12/IDM_ACP_SELF_WRITE_DL8, dl13/IDM_ACP_SELF_WRITE_DL8, dl14/IDM_ACP_SELF_WRITE_DL8, dl15/IDM_ACP_SELF_WRITE_DL8, dl_1_12/IDM_ACP_SELF_WRITE_DL8.
pub fn dl11_self_write_dl8()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 108u8, 102u8, 95u8, 119u8, 114u8, 105u8, 116u8, 101u8]),
  uuid: 281474959933473u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 115u8, 101u8, 108u8, 102u8, 32u8, 119u8, 114u8, 105u8, 116u8, 101u8, 32u8, 45u8, 32u8, 114u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 100u8, 32u8, 102u8, 111u8, 114u8, 32u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 32u8, 116u8, 111u8, 32u8, 117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 32u8, 116u8, 104u8, 101u8, 105u8, 114u8, 32u8, 111u8, 119u8, 110u8, 32u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 115u8, 32u8, 105u8, 110u8, 32u8, 108u8, 105u8, 110u8, 101u8, 32u8, 119u8, 105u8, 116u8, 104u8, 32u8, 98u8, 101u8, 115u8, 116u8, 32u8, 112u8, 114u8, 97u8, 99u8, 116u8, 105u8, 99u8, 101u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([53u128]),
  target: Vec::from([4u8]),
  search_attrs: Vec::from([]),
  modify_present_attrs: Vec::from([92u16, 90u16, 97u16, 107u16, 88u16, 15u16, 14u16]),
  modify_removed_attrs: Vec::from([92u16, 90u16, 97u16, 107u16, 88u16, 15u16, 108u16, 14u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1.
pub fn dl11_service_account_create_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 99u8, 114u8, 101u8, 97u8, 116u8, 101u8]),
  uuid: 281474959933529u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 110u8, 101u8, 119u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([70u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 5u16, 25u16]),
  create_attrs: Vec::from([21u16, 61u16, 27u16, 37u16, 26u16, 0u16, 2u16]),
 }
}

/// Exact complete record for dl11/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1, dl12/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1, dl13/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1, dl14/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1, dl15/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1, dl_1_12/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1.
pub fn dl11_service_account_delete_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 1u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 100u8, 101u8, 108u8, 101u8, 116u8, 101u8]),
  uuid: 281474959933536u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 105u8, 110u8, 103u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([70u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1.
pub fn dl11_service_account_entry_managed_by_modify_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 100u8, 95u8, 98u8, 121u8, 95u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8]),
  uuid: 281474959933538u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 100u8, 95u8, 98u8, 121u8, 32u8, 116u8, 111u8, 32u8, 98u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 110u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 101u8, 110u8, 116u8, 114u8, 105u8, 101u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([70u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 109u16, 37u16]),
  modify_present_attrs: Vec::from([37u16]),
  modify_removed_attrs: Vec::from([37u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1.
pub fn dl11_service_account_entry_manager_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]),
  uuid: 281474959933537u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8, 115u8, 32u8, 116u8, 111u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8]),
  receiver: 2u8,
  groups: Vec::from([]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 109u16, 37u16, 27u16, 97u16, 38u16, 52u16, 107u16, 88u16, 90u16, 0u16, 2u16, 13u16, 108u16]),
  modify_present_attrs: Vec::from([27u16, 97u16, 90u16, 0u16, 2u16, 13u16]),
  modify_removed_attrs: Vec::from([27u16, 97u16, 90u16, 107u16, 88u16, 0u16, 2u16, 13u16, 108u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1, dl12/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1, dl13/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1, dl14/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1.
pub fn dl11_service_account_manage_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933540u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 105u8, 110u8, 103u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 100u8, 97u8, 116u8, 97u8]),
  receiver: 1u8,
  groups: Vec::from([70u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([]),
  modify_present_attrs: Vec::from([61u16, 27u16, 53u16]),
  modify_removed_attrs: Vec::from([61u16, 27u16, 53u16, 97u16, 107u16, 90u16, 13u16, 108u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl11/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1, dl12/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1.
pub fn dl11_sync_account_manage_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 121u8, 110u8, 99u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933541u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 73u8, 68u8, 77u8, 32u8, 115u8, 121u8, 110u8, 99u8, 104u8, 114u8, 111u8, 110u8, 105u8, 115u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 32u8, 47u8, 32u8, 99u8, 111u8, 110u8, 110u8, 101u8, 99u8, 116u8, 105u8, 111u8, 110u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([32u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 12u8, 0u8, 115u8, 121u8, 110u8, 99u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 61u16, 26u16, 41u16, 101u16, 99u16, 102u16, 98u16]),
  modify_present_attrs: Vec::from([61u16, 26u16, 101u16, 99u16, 102u16]),
  modify_removed_attrs: Vec::from([61u16, 26u16, 41u16, 101u16, 99u16, 98u16, 102u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 26u16]),
  create_attrs: Vec::from([21u16, 61u16, 26u16]),
 }
}

/// Exact complete record for dl11/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1, dl12/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1.
pub fn dl11_system_config_account_policy_manage_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 95u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933480u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 103u8, 114u8, 97u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8]),
  receiver: 1u8,
  groups: Vec::from([71u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 4u8, 0u8, 117u8, 117u8, 105u8, 100u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 102u8, 102u8, 102u8, 102u8, 102u8, 102u8, 48u8, 48u8, 48u8, 48u8, 50u8, 55u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 26u16, 19u16, 25u16, 18u16, 91u16, 110u16]),
  modify_present_attrs: Vec::from([19u16, 25u16, 18u16, 91u16]),
  modify_removed_attrs: Vec::from([19u16, 25u16, 18u16, 91u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl12/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1.
pub fn dl12_all_accounts_posix_read_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 108u8, 108u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 95u8, 112u8, 111u8, 115u8, 105u8, 120u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
  uuid: 281474959933446u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 114u8, 101u8, 97u8, 100u8, 105u8, 110u8, 103u8, 32u8, 109u8, 105u8, 110u8, 105u8, 109u8, 97u8, 108u8, 32u8, 80u8, 79u8, 83u8, 73u8, 88u8, 32u8, 97u8, 116u8, 116u8, 114u8, 115u8, 46u8, 32u8, 82u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 100u8, 32u8, 102u8, 111u8, 114u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 115u8, 32u8, 116u8, 111u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 101u8, 32u8, 85u8, 78u8, 73u8, 88u8, 32u8, 117u8, 115u8, 101u8, 114u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([83u128]),
  target: Vec::from([1u8, 2u8, 0u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 12u8, 0u8, 112u8, 111u8, 115u8, 105u8, 120u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 10u8, 0u8, 112u8, 111u8, 115u8, 105u8, 120u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 27u16, 21u16, 57u16, 56u16, 35u16, 109u16, 38u16, 52u16, 97u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl12/IDM_ACP_GROUP_MANAGE_DL9, dl13/IDM_ACP_GROUP_MANAGE_DL9, dl14/IDM_ACP_GROUP_MANAGE_DL9, dl15/IDM_ACP_GROUP_MANAGE_DL9, dl_1_12/IDM_ACP_GROUP_MANAGE_DL9.
pub fn dl12_group_manage_dl9()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933474u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 100u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 105u8, 110u8, 103u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 115u8, 32u8, 105u8, 110u8, 32u8, 116u8, 104u8, 101u8, 32u8, 100u8, 105u8, 114u8, 101u8, 99u8, 116u8, 111u8, 114u8, 121u8]),
  receiver: 1u8,
  groups: Vec::from([21u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 96u16, 109u16, 26u16, 53u16, 56u16, 57u16, 35u16, 37u16]),
  modify_present_attrs: Vec::from([61u16, 26u16, 53u16, 56u16, 37u16]),
  modify_removed_attrs: Vec::from([61u16, 26u16, 53u16, 56u16, 37u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 13u16]),
  create_attrs: Vec::from([21u16, 61u16, 109u16, 26u16, 53u16, 56u16, 37u16]),
 }
}

/// Exact complete record for dl12/IDM_ACP_GROUP_READ_V1, dl13/IDM_ACP_GROUP_READ_V1, dl14/IDM_ACP_GROUP_READ_V1, dl15/IDM_ACP_GROUP_READ_V1, dl_1_12/IDM_ACP_GROUP_READ_V1.
pub fn dl12_group_read_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
  uuid: 281474959933522u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 97u8, 108u8, 108u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 115u8, 32u8, 116u8, 111u8, 32u8, 98u8, 101u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 98u8, 121u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([17u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 35u16, 61u16, 109u16, 96u16, 26u16, 56u16, 57u16, 37u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl12/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1, dl13/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1, dl14/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1, dl15/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1, dl_1_12/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1.
pub fn dl12_hp_group_unix_manage_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 104u8, 112u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8, 95u8, 117u8, 110u8, 105u8, 120u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933543u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 100u8, 32u8, 101u8, 120u8, 116u8, 101u8, 110u8, 100u8, 105u8, 110u8, 103u8, 32u8, 104u8, 105u8, 103u8, 104u8, 32u8, 112u8, 114u8, 105u8, 118u8, 105u8, 108u8, 101u8, 103u8, 101u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 115u8, 32u8, 119u8, 105u8, 116u8, 104u8, 32u8, 117u8, 110u8, 105u8, 120u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([68u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([35u16, 21u16, 61u16, 109u16, 96u16, 26u16, 56u16, 57u16, 38u16]),
  modify_present_attrs: Vec::from([21u16, 38u16]),
  modify_removed_attrs: Vec::from([38u16]),
  modify_classes: Vec::from([23u16]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl12/IDM_ACP_MESSAGE_MANAGE, dl13/IDM_ACP_MESSAGE_MANAGE, dl14/IDM_ACP_MESSAGE_MANAGE, dl15/IDM_ACP_MESSAGE_MANAGE, dl_1_12/IDM_ACP_MESSAGE_MANAGE.
pub fn dl12_message_manage()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16, 0u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933559u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 109u8, 101u8, 110u8, 116u8, 32u8, 111u8, 102u8, 32u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 32u8, 101u8, 110u8, 116u8, 114u8, 105u8, 101u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([84u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 16u8, 0u8, 111u8, 117u8, 116u8, 98u8, 111u8, 117u8, 110u8, 100u8, 95u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 58u16, 94u16, 24u16, 95u16, 54u16]),
  modify_present_attrs: Vec::from([95u16, 94u16]),
  modify_removed_attrs: Vec::from([95u16, 94u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 20u16]),
  create_attrs: Vec::from([21u16, 58u16, 94u16, 24u16, 54u16]),
 }
}

/// Exact complete record for dl12/IDM_ACP_MESSAGE_SENDER, dl13/IDM_ACP_MESSAGE_SENDER, dl14/IDM_ACP_MESSAGE_SENDER, dl15/IDM_ACP_MESSAGE_SENDER, dl_1_12/IDM_ACP_MESSAGE_SENDER.
pub fn dl12_message_sender()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 95u8, 115u8, 101u8, 110u8, 100u8, 101u8, 114u8]),
  uuid: 281474959933560u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 32u8, 101u8, 120u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 115u8, 101u8, 110u8, 100u8, 101u8, 114u8, 32u8, 116u8, 111u8, 32u8, 112u8, 114u8, 111u8, 99u8, 101u8, 115u8, 115u8, 32u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([85u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 16u8, 0u8, 111u8, 117u8, 116u8, 98u8, 111u8, 117u8, 110u8, 100u8, 95u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 58u16, 94u16, 24u16, 95u16, 54u16]),
  modify_present_attrs: Vec::from([95u16]),
  modify_removed_attrs: Vec::from([95u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl12/IDM_ACP_OAUTH2_ACCOUNT_ENROL.
pub fn dl12_oauth2_account_enrol()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 101u8, 110u8, 114u8, 111u8, 108u8]),
  uuid: 281474959933568u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 101u8, 110u8, 114u8, 111u8, 108u8, 105u8, 110u8, 103u8, 32u8, 111u8, 116u8, 104u8, 101u8, 114u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 32u8, 97u8, 115u8, 32u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 99u8, 111u8, 110u8, 115u8, 117u8, 109u8, 101u8, 114u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([87u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 63u16, 64u16, 62u16]),
  modify_present_attrs: Vec::from([21u16, 63u16, 64u16, 62u16]),
  modify_removed_attrs: Vec::from([21u16, 63u16, 64u16, 62u16]),
  modify_classes: Vec::from([14u16]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl12/IDM_ACP_OAUTH2_CLIENT_ADMIN.
pub fn dl12_oauth2_client_admin()->Profile {
 Profile {
  classes: Vec::from([19u16, 0u16, 2u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]),
  uuid: 281474959933561u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 103u8, 114u8, 97u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 32u8, 116u8, 114u8, 117u8, 115u8, 116u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8, 32u8, 97u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 114u8, 105u8, 103u8, 104u8, 116u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([86u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 13u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 61u16, 69u16, 70u16, 68u16, 86u16, 76u16]),
  modify_present_attrs: Vec::from([61u16, 69u16, 70u16, 68u16, 86u16, 76u16]),
  modify_removed_attrs: Vec::from([61u16, 69u16, 70u16, 68u16, 86u16, 76u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([15u16]),
  create_attrs: Vec::from([21u16, 61u16, 69u16, 70u16, 68u16, 86u16, 76u16]),
 }
}

/// Exact complete record for dl12/IDM_ACP_RADIUS_SERVERS_V1.
pub fn dl12_radius_servers_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 114u8, 97u8, 100u8, 105u8, 117u8, 115u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 115u8]),
  uuid: 281474959933460u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 82u8, 65u8, 68u8, 73u8, 85u8, 83u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 115u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 115u8, 32u8, 97u8, 110u8, 100u8, 32u8, 111u8, 116u8, 104u8, 101u8, 114u8, 32u8, 110u8, 101u8, 101u8, 100u8, 101u8, 100u8, 32u8, 100u8, 101u8, 116u8, 97u8, 105u8, 108u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([7u128]),
  target: Vec::from([1u8, 2u8, 0u8, 5u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 27u16, 57u16, 96u16, 109u16, 92u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl12/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1, dl13/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1, dl14/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1, dl15/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1, dl_1_12/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1.
pub fn dl12_service_account_create_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 99u8, 114u8, 101u8, 97u8, 116u8, 101u8]),
  uuid: 281474959933529u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 110u8, 101u8, 119u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([70u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 5u16, 25u16]),
  create_attrs: Vec::from([21u16, 61u16, 27u16, 37u16, 26u16, 0u16, 2u16, 53u16]),
 }
}

/// Exact complete record for dl12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1.
pub fn dl12_service_account_entry_managed_by_modify_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 100u8, 95u8, 98u8, 121u8, 95u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8]),
  uuid: 281474959933538u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 100u8, 95u8, 98u8, 121u8, 32u8, 116u8, 111u8, 32u8, 98u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 110u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 101u8, 110u8, 116u8, 114u8, 105u8, 101u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([70u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 109u16, 37u16, 53u16]),
  modify_present_attrs: Vec::from([37u16]),
  modify_removed_attrs: Vec::from([37u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1, dl13/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1, dl14/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1, dl15/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1, dl_1_12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1.
pub fn dl12_service_account_entry_manager_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]),
  uuid: 281474959933537u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8, 115u8, 32u8, 116u8, 111u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8]),
  receiver: 2u8,
  groups: Vec::from([]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 109u16, 37u16, 27u16, 97u16, 38u16, 52u16, 107u16, 88u16, 90u16, 0u16, 2u16, 13u16, 108u16, 53u16]),
  modify_present_attrs: Vec::from([27u16, 97u16, 90u16, 0u16, 2u16, 13u16]),
  modify_removed_attrs: Vec::from([27u16, 97u16, 90u16, 107u16, 88u16, 0u16, 2u16, 13u16, 108u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl13/IDM_ACP_ACP_MANAGE_V1, dl14/IDM_ACP_ACP_MANAGE_V1, dl15/IDM_ACP_ACP_MANAGE_V1, dl_1_12/IDM_ACP_ACP_MANAGE_V1.
pub fn dl13_acp_manage_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 99u8, 112u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933465u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 112u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8, 115u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 109u8, 101u8, 110u8, 116u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([17u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 22u8, 0u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 112u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 26u16, 5u16, 9u16, 11u16, 10u16, 8u16, 7u16, 6u16, 4u16, 3u16]),
  modify_present_attrs: Vec::from([21u16, 61u16, 26u16, 5u16, 9u16, 11u16, 10u16, 8u16, 7u16, 6u16, 4u16, 3u16]),
  modify_removed_attrs: Vec::from([21u16, 61u16, 26u16, 5u16, 9u16, 11u16, 10u16, 8u16, 7u16, 6u16, 4u16, 3u16]),
  modify_classes: Vec::from([3u16, 4u16, 2u16, 0u16, 1u16]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([3u16, 4u16, 2u16, 0u16, 1u16]),
  create_attrs: Vec::from([21u16, 61u16, 26u16, 5u16, 9u16, 11u16, 10u16, 8u16, 7u16, 6u16, 4u16, 3u16]),
 }
}

/// Exact complete record for dl13/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1.
pub fn dl13_all_accounts_posix_read_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 108u8, 108u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 95u8, 112u8, 111u8, 115u8, 105u8, 120u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
  uuid: 281474959933446u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 114u8, 101u8, 97u8, 100u8, 105u8, 110u8, 103u8, 32u8, 109u8, 105u8, 110u8, 105u8, 109u8, 97u8, 108u8, 32u8, 80u8, 79u8, 83u8, 73u8, 88u8, 32u8, 97u8, 116u8, 116u8, 114u8, 115u8, 46u8, 32u8, 82u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 100u8, 32u8, 102u8, 111u8, 114u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 115u8, 32u8, 116u8, 111u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 101u8, 32u8, 85u8, 78u8, 73u8, 88u8, 32u8, 117u8, 115u8, 101u8, 114u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([83u128]),
  target: Vec::from([1u8, 2u8, 0u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 12u8, 0u8, 112u8, 111u8, 115u8, 105u8, 120u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 10u8, 0u8, 112u8, 111u8, 115u8, 105u8, 120u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 96u16, 27u16, 21u16, 57u16, 56u16, 35u16, 38u16, 52u16, 97u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl13/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8, dl14/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8, dl15/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8, dl_1_12/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8.
pub fn dl13_application_entry_manager_dl8()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]),
  uuid: 281474959933554u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 69u8, 110u8, 116u8, 114u8, 121u8, 77u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 97u8, 110u8, 100u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8]),
  receiver: 2u8,
  groups: Vec::from([]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 11u8, 0u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 61u16, 96u16, 27u16, 53u16, 107u16, 13u16, 108u16, 26u16, 51u16, 37u16]),
  modify_present_attrs: Vec::from([61u16, 26u16, 27u16, 53u16, 107u16, 13u16, 51u16]),
  modify_removed_attrs: Vec::from([61u16, 26u16, 27u16, 53u16, 107u16, 13u16, 108u16, 51u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl13/IDM_ACP_APPLICATION_MANAGE_DL8, dl14/IDM_ACP_APPLICATION_MANAGE_DL8, dl15/IDM_ACP_APPLICATION_MANAGE_DL8, dl_1_12/IDM_ACP_APPLICATION_MANAGE_DL8.
pub fn dl13_application_manage_dl8()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933555u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 100u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 32u8, 105u8, 110u8, 32u8, 116u8, 104u8, 101u8, 32u8, 100u8, 105u8, 114u8, 101u8, 99u8, 116u8, 111u8, 114u8, 121u8]),
  receiver: 1u8,
  groups: Vec::from([80u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 11u8, 0u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 61u16, 96u16, 26u16, 27u16, 53u16, 107u16, 13u16, 108u16, 51u16, 37u16]),
  modify_present_attrs: Vec::from([61u16, 26u16, 27u16, 53u16, 107u16, 13u16, 51u16, 37u16]),
  modify_removed_attrs: Vec::from([61u16, 26u16, 27u16, 53u16, 107u16, 13u16, 108u16, 51u16, 37u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 5u16, 25u16, 7u16]),
  create_attrs: Vec::from([21u16, 109u16, 61u16, 26u16, 27u16, 53u16, 51u16, 37u16]),
 }
}

/// Exact complete record for dl13/IDM_ACP_MAIL_SERVERS_DL8, dl14/IDM_ACP_MAIL_SERVERS_DL8, dl15/IDM_ACP_MAIL_SERVERS_DL8, dl_1_12/IDM_ACP_MAIL_SERVERS_DL8.
pub fn dl13_mail_servers_dl8()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 109u8, 97u8, 105u8, 108u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 115u8]),
  uuid: 281474959933556u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 77u8, 65u8, 73u8, 76u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 115u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 101u8, 109u8, 97u8, 105u8, 108u8, 32u8, 97u8, 100u8, 100u8, 114u8, 101u8, 115u8, 115u8, 101u8, 115u8, 32u8, 97u8, 110u8, 100u8, 32u8, 111u8, 116u8, 104u8, 101u8, 114u8, 32u8, 110u8, 101u8, 101u8, 100u8, 101u8, 100u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([82u128]),
  target: Vec::from([1u8, 2u8, 0u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 96u16, 27u16, 53u16, 56u16, 35u16, 57u16, 38u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl13/IDM_ACP_OAUTH2_ACCOUNT_ENROL, dl14/IDM_ACP_OAUTH2_ACCOUNT_ENROL.
pub fn dl13_oauth2_account_enrol()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 101u8, 110u8, 114u8, 111u8, 108u8]),
  uuid: 281474959933568u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 101u8, 110u8, 114u8, 111u8, 108u8, 105u8, 110u8, 103u8, 32u8, 111u8, 116u8, 104u8, 101u8, 114u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 32u8, 97u8, 115u8, 32u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 99u8, 111u8, 110u8, 115u8, 117u8, 109u8, 101u8, 114u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([87u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 109u16, 63u16, 64u16, 62u16]),
  modify_present_attrs: Vec::from([21u16, 63u16, 64u16, 62u16]),
  modify_removed_attrs: Vec::from([21u16, 63u16, 64u16, 62u16]),
  modify_classes: Vec::from([14u16]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl13/IDM_ACP_OAUTH2_CLIENT_ADMIN, dl14/IDM_ACP_OAUTH2_CLIENT_ADMIN.
pub fn dl13_oauth2_client_admin()->Profile {
 Profile {
  classes: Vec::from([19u16, 0u16, 2u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]),
  uuid: 281474959933561u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 103u8, 114u8, 97u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 32u8, 116u8, 114u8, 117u8, 115u8, 116u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8, 32u8, 97u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 114u8, 105u8, 103u8, 104u8, 116u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([86u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 13u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 61u16, 96u16, 69u16, 70u16, 68u16, 86u16, 76u16]),
  modify_present_attrs: Vec::from([61u16, 69u16, 70u16, 68u16, 86u16, 76u16]),
  modify_removed_attrs: Vec::from([61u16, 69u16, 70u16, 68u16, 86u16, 76u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([15u16]),
  create_attrs: Vec::from([21u16, 61u16, 69u16, 70u16, 68u16, 86u16, 76u16]),
 }
}

/// Exact complete record for dl13/IDM_ACP_OAUTH2_MANAGE.
pub fn dl13_oauth2_manage()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933493u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 32u8, 105u8, 110u8, 116u8, 101u8, 103u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([39u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 22u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 26u16, 27u16, 61u16, 109u16, 96u16, 84u16, 80u16, 81u16, 82u16, 83u16, 77u16, 66u16, 73u16, 74u16, 67u16, 78u16, 39u16, 85u16, 72u16, 44u16]),
  modify_present_attrs: Vec::from([26u16, 27u16, 61u16, 80u16, 81u16, 83u16, 82u16, 66u16, 73u16, 74u16, 67u16, 78u16, 39u16, 85u16, 72u16, 42u16, 43u16]),
  modify_removed_attrs: Vec::from([26u16, 27u16, 61u16, 84u16, 80u16, 81u16, 82u16, 83u16, 77u16, 66u16, 73u16, 74u16, 67u16, 78u16, 39u16, 85u16, 72u16, 42u16, 43u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 5u16, 16u16, 17u16, 18u16]),
  create_attrs: Vec::from([21u16, 26u16, 61u16, 27u16, 79u16, 80u16, 81u16, 83u16, 82u16, 66u16, 73u16, 74u16, 67u16, 78u16, 39u16, 85u16, 72u16]),
 }
}

/// Exact complete record for dl13/IDM_ACP_OAUTH2_MANAGE_BASIC, dl14/IDM_ACP_OAUTH2_MANAGE_BASIC, dl15/IDM_ACP_OAUTH2_MANAGE_BASIC, dl_1_12/IDM_ACP_OAUTH2_MANAGE_BASIC.
pub fn dl13_oauth2_manage_basic()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 95u8, 98u8, 97u8, 115u8, 105u8, 99u8]),
  uuid: 281474959933569u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 66u8, 97u8, 115u8, 105u8, 99u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 32u8, 105u8, 110u8, 116u8, 101u8, 103u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([39u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 28u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 95u8, 98u8, 97u8, 115u8, 105u8, 99u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([71u16]),
  modify_present_attrs: Vec::from([71u16]),
  modify_removed_attrs: Vec::from([71u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl13/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1, dl14/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1, dl15/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1, dl_1_12/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1.
pub fn dl13_people_credential_reset_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 95u8, 114u8, 101u8, 115u8, 101u8, 116u8]),
  uuid: 281474959933527u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 114u8, 101u8, 115u8, 101u8, 116u8, 116u8, 105u8, 110u8, 103u8, 32u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 115u8, 32u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 115u8, 32u8]),
  receiver: 1u8,
  groups: Vec::from([19u128, 65u128, 69u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 61u16, 96u16, 90u16, 0u16, 2u16, 88u16, 15u16, 1u16]),
  modify_present_attrs: Vec::from([90u16, 88u16, 15u16, 2u16, 0u16, 1u16]),
  modify_removed_attrs: Vec::from([90u16, 88u16, 15u16, 2u16, 0u16, 1u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl13/IDM_ACP_RADIUS_SERVERS_V1, dl14/IDM_ACP_RADIUS_SERVERS_V1, dl15/IDM_ACP_RADIUS_SERVERS_V1, dl_1_12/IDM_ACP_RADIUS_SERVERS_V1.
pub fn dl13_radius_servers_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 114u8, 97u8, 100u8, 105u8, 117u8, 115u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 115u8]),
  uuid: 281474959933460u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 82u8, 65u8, 68u8, 73u8, 85u8, 83u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 115u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 115u8, 32u8, 97u8, 110u8, 100u8, 32u8, 111u8, 116u8, 104u8, 101u8, 114u8, 32u8, 110u8, 101u8, 101u8, 100u8, 101u8, 100u8, 32u8, 100u8, 101u8, 116u8, 97u8, 105u8, 108u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([7u128]),
  target: Vec::from([1u8, 2u8, 0u8, 5u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 27u16, 57u16, 96u16, 92u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl13/IDM_ACP_SELF_READ_DL8.
pub fn dl13_self_read_dl8()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 108u8, 102u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
  uuid: 281474959933444u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 115u8, 101u8, 108u8, 102u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 45u8, 32u8, 114u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 100u8, 32u8, 102u8, 111u8, 114u8, 32u8, 119u8, 104u8, 111u8, 97u8, 109u8, 105u8, 32u8, 97u8, 110u8, 100u8, 32u8, 109u8, 97u8, 110u8, 121u8, 32u8, 111u8, 116u8, 104u8, 101u8, 114u8, 32u8, 102u8, 117u8, 110u8, 99u8, 116u8, 105u8, 111u8, 110u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([54u128]),
  target: Vec::from([4u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 96u16, 27u16, 48u16, 21u16, 57u16, 53u16, 92u16, 38u16, 52u16, 100u16, 0u16, 2u16, 90u16, 108u16, 88u16, 15u16, 14u16, 97u16, 107u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl13/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1, dl14/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1, dl15/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1, dl_1_12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1.
pub fn dl13_service_account_entry_managed_by_modify_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 100u8, 95u8, 98u8, 121u8, 95u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8]),
  uuid: 281474959933538u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 100u8, 95u8, 98u8, 121u8, 32u8, 116u8, 111u8, 32u8, 98u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 110u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 101u8, 110u8, 116u8, 114u8, 105u8, 101u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([70u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 96u16, 37u16, 53u16]),
  modify_present_attrs: Vec::from([37u16]),
  modify_removed_attrs: Vec::from([37u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl13/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1, dl14/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1, dl15/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1, dl_1_12/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1.
pub fn dl13_sync_account_manage_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 121u8, 110u8, 99u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933541u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 73u8, 68u8, 77u8, 32u8, 115u8, 121u8, 110u8, 99u8, 104u8, 114u8, 111u8, 110u8, 105u8, 115u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 32u8, 47u8, 32u8, 99u8, 111u8, 110u8, 110u8, 101u8, 99u8, 116u8, 105u8, 111u8, 110u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([32u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 12u8, 0u8, 115u8, 121u8, 110u8, 99u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 26u16, 41u16, 101u16, 99u16, 102u16, 98u16]),
  modify_present_attrs: Vec::from([61u16, 26u16, 101u16, 99u16, 102u16]),
  modify_removed_attrs: Vec::from([61u16, 26u16, 41u16, 101u16, 99u16, 98u16, 102u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 26u16]),
  create_attrs: Vec::from([21u16, 61u16, 26u16]),
 }
}

/// Exact complete record for dl13/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1, dl14/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1, dl15/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1, dl_1_12/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1.
pub fn dl13_system_config_account_policy_manage_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 95u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933480u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 103u8, 114u8, 97u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8]),
  receiver: 1u8,
  groups: Vec::from([71u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 4u8, 0u8, 117u8, 117u8, 105u8, 100u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 102u8, 102u8, 102u8, 102u8, 102u8, 102u8, 48u8, 48u8, 48u8, 48u8, 50u8, 55u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 109u16, 26u16, 19u16, 25u16, 18u16, 91u16, 110u16]),
  modify_present_attrs: Vec::from([19u16, 25u16, 18u16, 91u16]),
  modify_removed_attrs: Vec::from([19u16, 25u16, 18u16, 91u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl14/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1, dl15/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1, dl_1_12/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1.
pub fn dl14_all_accounts_posix_read_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 97u8, 108u8, 108u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 95u8, 112u8, 111u8, 115u8, 105u8, 120u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
  uuid: 281474959933446u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 114u8, 101u8, 97u8, 100u8, 105u8, 110u8, 103u8, 32u8, 109u8, 105u8, 110u8, 105u8, 109u8, 97u8, 108u8, 32u8, 80u8, 79u8, 83u8, 73u8, 88u8, 32u8, 97u8, 116u8, 116u8, 114u8, 115u8, 46u8, 32u8, 82u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 100u8, 32u8, 102u8, 111u8, 114u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 115u8, 32u8, 116u8, 111u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 101u8, 32u8, 85u8, 78u8, 73u8, 88u8, 32u8, 117u8, 115u8, 101u8, 114u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([83u128]),
  target: Vec::from([1u8, 2u8, 0u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 12u8, 0u8, 112u8, 111u8, 115u8, 105u8, 120u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 10u8, 0u8, 112u8, 111u8, 115u8, 105u8, 120u8, 103u8, 114u8, 111u8, 117u8, 112u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 96u16, 27u16, 21u16, 57u16, 56u16, 35u16, 38u16, 52u16, 97u16, 89u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl14/IDM_ACP_DOMAIN_ADMIN_DL9, dl15/IDM_ACP_DOMAIN_ADMIN_DL9, dl_1_12/IDM_ACP_DOMAIN_ADMIN_DL9.
pub fn dl14_domain_admin_dl9()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]),
  uuid: 281474959933478u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 103u8, 114u8, 97u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 105u8, 110u8, 102u8, 111u8, 32u8, 97u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 108u8, 111u8, 99u8, 97u8, 108u8, 108u8, 121u8]),
  receiver: 1u8,
  groups: Vec::from([32u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 4u8, 0u8, 117u8, 117u8, 105u8, 100u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 102u8, 102u8, 102u8, 102u8, 102u8, 102u8, 48u8, 48u8, 48u8, 48u8, 50u8, 53u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 29u16, 28u16, 30u16, 32u16, 31u16, 47u16, 33u16, 34u16, 44u16, 46u16, 110u16, 39u16]),
  modify_present_attrs: Vec::from([30u16, 31u16, 47u16, 33u16, 29u16, 28u16, 46u16, 42u16, 43u16, 39u16]),
  modify_removed_attrs: Vec::from([30u16, 33u16, 31u16, 47u16, 29u16, 28u16, 46u16, 42u16, 43u16, 39u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl14/IDM_ACP_OAUTH2_MANAGE, dl15/IDM_ACP_OAUTH2_MANAGE, dl_1_12/IDM_ACP_OAUTH2_MANAGE.
pub fn dl14_oauth2_manage()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 0u16, 1u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933493u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 105u8, 110u8, 103u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 32u8, 105u8, 110u8, 116u8, 101u8, 103u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([39u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 22u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 26u16, 27u16, 61u16, 109u16, 96u16, 84u16, 80u16, 81u16, 82u16, 83u16, 77u16, 66u16, 73u16, 74u16, 75u16, 67u16, 78u16, 39u16, 85u16, 72u16, 44u16]),
  modify_present_attrs: Vec::from([26u16, 27u16, 61u16, 80u16, 81u16, 83u16, 82u16, 66u16, 73u16, 74u16, 75u16, 67u16, 78u16, 39u16, 85u16, 72u16, 42u16, 43u16]),
  modify_removed_attrs: Vec::from([26u16, 27u16, 61u16, 84u16, 80u16, 81u16, 82u16, 83u16, 77u16, 66u16, 73u16, 74u16, 75u16, 67u16, 78u16, 39u16, 85u16, 72u16, 42u16, 43u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([19u16, 5u16, 16u16, 17u16, 18u16]),
  create_attrs: Vec::from([21u16, 26u16, 61u16, 27u16, 79u16, 80u16, 81u16, 83u16, 82u16, 66u16, 73u16, 74u16, 75u16, 67u16, 78u16, 39u16, 85u16, 72u16]),
 }
}

/// Exact complete record for dl14/IDM_ACP_SELF_READ_DL8, dl15/IDM_ACP_SELF_READ_DL8, dl_1_12/IDM_ACP_SELF_READ_DL8.
pub fn dl14_self_read_dl8()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 108u8, 102u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
  uuid: 281474959933444u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 115u8, 101u8, 108u8, 102u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 45u8, 32u8, 114u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 100u8, 32u8, 102u8, 111u8, 114u8, 32u8, 119u8, 104u8, 111u8, 97u8, 109u8, 105u8, 32u8, 97u8, 110u8, 100u8, 32u8, 109u8, 97u8, 110u8, 121u8, 32u8, 111u8, 116u8, 104u8, 101u8, 114u8, 32u8, 102u8, 117u8, 110u8, 99u8, 116u8, 105u8, 111u8, 110u8, 115u8]),
  receiver: 1u8,
  groups: Vec::from([54u128]),
  target: Vec::from([4u8]),
  search_attrs: Vec::from([21u16, 61u16, 109u16, 96u16, 27u16, 48u16, 21u16, 57u16, 53u16, 92u16, 38u16, 52u16, 100u16, 0u16, 2u16, 90u16, 108u16, 88u16, 15u16, 14u16, 97u16, 107u16, 45u16, 89u16]),
  modify_present_attrs: Vec::from([]),
  modify_removed_attrs: Vec::from([]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl15/IDM_ACP_OAUTH2_ACCOUNT_ENROL, dl_1_12/IDM_ACP_OAUTH2_ACCOUNT_ENROL.
pub fn dl15_oauth2_account_enrol()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 101u8, 110u8, 114u8, 111u8, 108u8]),
  uuid: 281474959933568u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 101u8, 110u8, 114u8, 111u8, 108u8, 105u8, 110u8, 103u8, 32u8, 111u8, 116u8, 104u8, 101u8, 114u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 32u8, 97u8, 115u8, 32u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 99u8, 111u8, 110u8, 115u8, 117u8, 109u8, 101u8, 114u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([87u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 109u16, 63u16, 64u16, 65u16, 62u16]),
  modify_present_attrs: Vec::from([21u16, 63u16, 64u16, 65u16, 62u16]),
  modify_removed_attrs: Vec::from([21u16, 63u16, 64u16, 65u16, 62u16]),
  modify_classes: Vec::from([14u16]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl15/IDM_ACP_OAUTH2_CLIENT_ADMIN, dl_1_12/IDM_ACP_OAUTH2_CLIENT_ADMIN.
pub fn dl15_oauth2_client_admin()->Profile {
 Profile {
  classes: Vec::from([19u16, 0u16, 2u16, 3u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]),
  uuid: 281474959933561u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 103u8, 114u8, 97u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 32u8, 116u8, 114u8, 117u8, 115u8, 116u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8, 32u8, 97u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 114u8, 105u8, 103u8, 104u8, 116u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([86u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 13u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 3u8, 2u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 61u16, 96u16, 69u16, 70u16, 68u16, 86u16, 87u16, 76u16]),
  modify_present_attrs: Vec::from([61u16, 69u16, 70u16, 68u16, 86u16, 87u16, 76u16]),
  modify_removed_attrs: Vec::from([61u16, 69u16, 70u16, 68u16, 86u16, 87u16, 76u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([15u16]),
  create_attrs: Vec::from([21u16, 61u16, 69u16, 70u16, 68u16, 86u16, 87u16, 76u16]),
 }
}

/// Exact complete record for dl15/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1, dl_1_12/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1.
pub fn dl15_service_account_manage_v1()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933540u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 105u8, 110u8, 103u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 100u8, 97u8, 116u8, 97u8]),
  receiver: 1u8,
  groups: Vec::from([70u128]),
  target: Vec::from([1u8, 3u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 61u16, 96u16, 109u16, 37u16, 27u16, 97u16, 107u16, 90u16, 13u16, 108u16, 53u16]),
  modify_present_attrs: Vec::from([61u16, 27u16, 53u16]),
  modify_removed_attrs: Vec::from([61u16, 27u16, 53u16, 97u16, 107u16, 90u16, 13u16, 108u16, 53u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}

/// Exact complete record for dl_1_12/IDM_ACP_FEATURE_MANAGE.
pub fn dl_1_12_feature_manage()->Profile {
 Profile {
  classes: Vec::from([19u16, 3u16, 2u16, 4u16]),
  name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 112u8, 95u8, 102u8, 101u8, 97u8, 116u8, 117u8, 114u8, 101u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8]),
  uuid: 281474959933574u128,
  description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 115u8, 32u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 111u8, 118u8, 101u8, 114u8, 32u8, 101u8, 110u8, 97u8, 98u8, 108u8, 101u8, 100u8, 32u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 102u8, 101u8, 97u8, 116u8, 117u8, 114u8, 101u8, 115u8, 46u8]),
  receiver: 1u8,
  groups: Vec::from([32u128]),
  target: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 102u8, 101u8, 97u8, 116u8, 117u8, 114u8, 101u8, 3u8, 2u8, 3u8, 0u8, 0u8, 8u8, 0u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 36u8, 0u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 45u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 48u8, 49u8, 48u8, 48u8, 48u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 9u8, 0u8, 116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
  search_attrs: Vec::from([21u16, 109u16, 61u16, 26u16, 36u16]),
  modify_present_attrs: Vec::from([36u16]),
  modify_removed_attrs: Vec::from([36u16]),
  modify_classes: Vec::from([]),
  modify_present_classes: Vec::from([]),
  modify_remove_classes: Vec::from([]),
  create_classes: Vec::from([]),
  create_attrs: Vec::from([]),
 }
}
