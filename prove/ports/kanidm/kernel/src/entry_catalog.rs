//! Exact full pinned migration entry records. See DEVIATIONS.md.
#[derive(Debug,PartialEq,Eq)]
pub struct AccountRecord {
pub account_type:u8,
pub has_entry_manager:bool,
pub entry_manager:u128,
pub name:Vec<u8>,
pub uuid:u128,
pub description:Vec<u8>,
pub displayname:Vec<u8>,
}
#[derive(Debug,PartialEq,Eq)]
pub struct EntryRecord {
pub bytes:Vec<u8>,
}

/// Exact complete record for dl11/BUILTIN_ACCOUNT_IDM_ADMIN, dl12/BUILTIN_ACCOUNT_IDM_ADMIN, dl13/BUILTIN_ACCOUNT_IDM_ADMIN, dl14/BUILTIN_ACCOUNT_IDM_ADMIN, dl15/BUILTIN_ACCOUNT_IDM_ADMIN, dl_1_12/BUILTIN_ACCOUNT_IDM_ADMIN.
pub fn dl11_builtin_account_idm_admin()->AccountRecord{
 AccountRecord{
account_type: 0u8,
has_entry_manager: false,
entry_manager: 0u128,
name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]),
uuid: 24u128,
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 46u8]),
displayname: Vec::from([73u8, 68u8, 77u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 111u8, 114u8]),
}
}

/// Exact complete record for dl11/BUILTIN_ACCOUNT_ADMIN, dl12/BUILTIN_ACCOUNT_ADMIN, dl13/BUILTIN_ACCOUNT_ADMIN, dl14/BUILTIN_ACCOUNT_ADMIN, dl15/BUILTIN_ACCOUNT_ADMIN, dl_1_12/BUILTIN_ACCOUNT_ADMIN.
pub fn dl11_builtin_account_admin()->AccountRecord{
 AccountRecord{
account_type: 0u8,
has_entry_manager: false,
entry_manager: 0u128,
name: Vec::from([97u8, 100u8, 109u8, 105u8, 110u8]),
uuid: 0u128,
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 83u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 46u8]),
displayname: Vec::from([83u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 111u8, 114u8]),
}
}

/// Exact complete record for dl11/BUILTIN_ACCOUNT_ANONYMOUS_DL6, dl12/BUILTIN_ACCOUNT_ANONYMOUS_DL6, dl13/BUILTIN_ACCOUNT_ANONYMOUS_DL6, dl14/BUILTIN_ACCOUNT_ANONYMOUS_DL6, dl15/BUILTIN_ACCOUNT_ANONYMOUS_DL6, dl_1_12/BUILTIN_ACCOUNT_ANONYMOUS_DL6.
pub fn dl11_builtin_account_anonymous_dl6()->AccountRecord{
 AccountRecord{
account_type: 0u8,
has_entry_manager: true,
entry_manager: 1u128,
name: Vec::from([97u8, 110u8, 111u8, 110u8, 121u8, 109u8, 111u8, 117u8, 115u8]),
uuid: 281474976710655u128,
description: Vec::from([65u8, 110u8, 111u8, 110u8, 121u8, 109u8, 111u8, 117u8, 115u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 46u8]),
displayname: Vec::from([65u8, 110u8, 111u8, 110u8, 121u8, 109u8, 111u8, 117u8, 115u8]),
}
}

/// Exact complete record for dl11/E_KEY_PROVIDER_INTERNAL_DL6, dl12/E_KEY_PROVIDER_INTERNAL_DL6, dl13/E_KEY_PROVIDER_INTERNAL_DL6, dl14/e_key_provider_internal_dl6, dl15/e_key_provider_internal_dl6, dl_1_12/e_key_provider_internal_dl6.
pub fn dl11_e_key_provider_internal_dl6()->EntryRecord{
 EntryRecord{
bytes: Vec::from([5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 3u8, 0u8, 0u8, 6u8, 0u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 0u8, 12u8, 0u8, 107u8, 101u8, 121u8, 95u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8, 0u8, 21u8, 0u8, 107u8, 101u8, 121u8, 95u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8, 95u8, 105u8, 110u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 11u8, 0u8, 100u8, 101u8, 115u8, 99u8, 114u8, 105u8, 112u8, 116u8, 105u8, 111u8, 110u8, 1u8, 0u8, 2u8, 57u8, 0u8, 84u8, 104u8, 101u8, 32u8, 100u8, 101u8, 102u8, 97u8, 117u8, 108u8, 116u8, 32u8, 100u8, 97u8, 116u8, 97u8, 98u8, 97u8, 115u8, 101u8, 32u8, 105u8, 110u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 99u8, 114u8, 121u8, 112u8, 116u8, 111u8, 103u8, 114u8, 97u8, 112u8, 104u8, 105u8, 99u8, 32u8, 107u8, 101u8, 121u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8, 46u8, 4u8, 0u8, 110u8, 97u8, 109u8, 101u8, 1u8, 0u8, 3u8, 21u8, 0u8, 107u8, 101u8, 121u8, 95u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8, 95u8, 105u8, 110u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 4u8, 0u8, 117u8, 117u8, 105u8, 100u8, 1u8, 0u8, 1u8, 112u8, 0u8, 0u8, 255u8, 255u8, 255u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8]),
}
}

/// Exact complete record for dl11/E_SYSTEM_INFO_V1, dl12/E_SYSTEM_INFO_V1, dl13/E_SYSTEM_INFO_V1, dl14/e_system_info_v1, dl15/e_system_info_v1, dl_1_12/e_system_info_v1.
pub fn dl11_e_system_info_v1()->EntryRecord{
 EntryRecord{
bytes: Vec::from([5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 3u8, 0u8, 0u8, 6u8, 0u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 0u8, 6u8, 0u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 0u8, 11u8, 0u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 95u8, 105u8, 110u8, 102u8, 111u8, 11u8, 0u8, 100u8, 101u8, 115u8, 99u8, 114u8, 105u8, 112u8, 116u8, 105u8, 111u8, 110u8, 1u8, 0u8, 2u8, 40u8, 0u8, 83u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 40u8, 108u8, 111u8, 99u8, 97u8, 108u8, 41u8, 32u8, 105u8, 110u8, 102u8, 111u8, 32u8, 97u8, 110u8, 100u8, 32u8, 109u8, 101u8, 116u8, 97u8, 100u8, 97u8, 116u8, 97u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 46u8, 4u8, 0u8, 117u8, 117u8, 105u8, 100u8, 1u8, 0u8, 1u8, 1u8, 0u8, 0u8, 255u8, 255u8, 255u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 7u8, 0u8, 118u8, 101u8, 114u8, 115u8, 105u8, 111u8, 110u8, 1u8, 0u8, 4u8, 20u8, 0u8, 0u8, 0u8]),
}
}

/// Exact complete record for dl11/E_DOMAIN_INFO_DL6, dl12/E_DOMAIN_INFO_DL6.
pub fn dl11_e_domain_info_dl6()->EntryRecord{
 EntryRecord{
bytes: Vec::from([5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 0u8, 6u8, 0u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 0u8, 6u8, 0u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 0u8, 10u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 0u8, 11u8, 0u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 95u8, 105u8, 110u8, 102u8, 111u8, 0u8, 20u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 116u8, 95u8, 101u8, 115u8, 50u8, 53u8, 54u8, 0u8, 22u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 101u8, 95u8, 97u8, 49u8, 50u8, 56u8, 103u8, 99u8, 109u8, 11u8, 0u8, 100u8, 101u8, 115u8, 99u8, 114u8, 105u8, 112u8, 116u8, 105u8, 111u8, 110u8, 1u8, 0u8, 2u8, 45u8, 0u8, 84u8, 104u8, 105u8, 115u8, 32u8, 108u8, 111u8, 99u8, 97u8, 108u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 39u8, 115u8, 32u8, 105u8, 110u8, 102u8, 111u8, 32u8, 97u8, 110u8, 100u8, 32u8, 109u8, 101u8, 116u8, 97u8, 100u8, 97u8, 116u8, 97u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 46u8, 4u8, 0u8, 110u8, 97u8, 109u8, 101u8, 1u8, 0u8, 3u8, 12u8, 0u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 95u8, 108u8, 111u8, 99u8, 97u8, 108u8, 4u8, 0u8, 117u8, 117u8, 105u8, 100u8, 1u8, 0u8, 1u8, 37u8, 0u8, 0u8, 255u8, 255u8, 255u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8]),
}
}

/// Exact complete record for dl12/E_UUID_DOMAIN_ID_VERIFICATION_KEY_V1, dl13/E_UUID_DOMAIN_ID_VERIFICATION_KEY_V1, dl14/e_uuid_domain_id_verification_key_v1, dl15/e_uuid_domain_id_verification_key_v1, dl_1_12/e_uuid_domain_id_verification_key_v1.
pub fn dl12_e_uuid_domain_id_verification_key_v1()->EntryRecord{
 EntryRecord{
bytes: Vec::from([5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 3u8, 0u8, 0u8, 6u8, 0u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 0u8, 10u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 0u8, 20u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 104u8, 107u8, 100u8, 102u8, 95u8, 115u8, 50u8, 53u8, 54u8, 11u8, 0u8, 100u8, 101u8, 115u8, 99u8, 114u8, 105u8, 112u8, 116u8, 105u8, 111u8, 110u8, 1u8, 0u8, 2u8, 56u8, 0u8, 84u8, 104u8, 101u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 45u8, 108u8, 111u8, 99u8, 97u8, 108u8, 32u8, 72u8, 77u8, 65u8, 67u8, 32u8, 107u8, 101u8, 121u8, 32u8, 117u8, 115u8, 101u8, 100u8, 32u8, 102u8, 111u8, 114u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 73u8, 68u8, 32u8, 118u8, 101u8, 114u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 46u8, 4u8, 0u8, 117u8, 117u8, 105u8, 100u8, 1u8, 0u8, 1u8, 118u8, 0u8, 0u8, 255u8, 255u8, 255u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8]),
}
}

/// Exact complete record for dl12/E_HMAC_NAME_HISTORY_FEATURE, dl13/E_HMAC_NAME_HISTORY_FEATURE, dl14/e_hmac_name_history_feature, dl15/e_hmac_name_history_feature, dl_1_12/e_hmac_name_history_feature.
pub fn dl12_e_hmac_name_history_feature()->EntryRecord{
 EntryRecord{
bytes: Vec::from([5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 4u8, 0u8, 0u8, 6u8, 0u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 0u8, 7u8, 0u8, 102u8, 101u8, 97u8, 116u8, 117u8, 114u8, 101u8, 0u8, 10u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 0u8, 20u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 104u8, 107u8, 100u8, 102u8, 95u8, 115u8, 50u8, 53u8, 54u8, 11u8, 0u8, 100u8, 101u8, 115u8, 99u8, 114u8, 105u8, 112u8, 116u8, 105u8, 111u8, 110u8, 1u8, 0u8, 2u8, 47u8, 0u8, 67u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 72u8, 77u8, 65u8, 67u8, 32u8, 78u8, 97u8, 109u8, 101u8, 32u8, 72u8, 105u8, 115u8, 116u8, 111u8, 114u8, 121u8, 32u8, 70u8, 101u8, 97u8, 116u8, 117u8, 114u8, 101u8, 46u8, 4u8, 0u8, 110u8, 97u8, 109u8, 101u8, 1u8, 0u8, 3u8, 17u8, 0u8, 104u8, 109u8, 97u8, 99u8, 95u8, 110u8, 97u8, 109u8, 101u8, 95u8, 102u8, 101u8, 97u8, 116u8, 117u8, 114u8, 101u8, 4u8, 0u8, 117u8, 117u8, 105u8, 100u8, 1u8, 0u8, 1u8, 88u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8]),
}
}

/// Exact complete record for dl13/E_DOMAIN_INFO_DL6, dl14/e_domain_info_dl6, dl15/e_domain_info_dl6.
pub fn dl13_e_domain_info_dl6()->EntryRecord{
 EntryRecord{
bytes: Vec::from([5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 0u8, 6u8, 0u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 0u8, 6u8, 0u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 0u8, 10u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 0u8, 11u8, 0u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 95u8, 105u8, 110u8, 102u8, 111u8, 0u8, 20u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 116u8, 95u8, 101u8, 115u8, 50u8, 53u8, 54u8, 0u8, 20u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 116u8, 95u8, 104u8, 115u8, 50u8, 53u8, 54u8, 0u8, 22u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 101u8, 95u8, 97u8, 49u8, 50u8, 56u8, 103u8, 99u8, 109u8, 11u8, 0u8, 100u8, 101u8, 115u8, 99u8, 114u8, 105u8, 112u8, 116u8, 105u8, 111u8, 110u8, 1u8, 0u8, 2u8, 45u8, 0u8, 84u8, 104u8, 105u8, 115u8, 32u8, 108u8, 111u8, 99u8, 97u8, 108u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 39u8, 115u8, 32u8, 105u8, 110u8, 102u8, 111u8, 32u8, 97u8, 110u8, 100u8, 32u8, 109u8, 101u8, 116u8, 97u8, 100u8, 97u8, 116u8, 97u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 46u8, 4u8, 0u8, 110u8, 97u8, 109u8, 101u8, 1u8, 0u8, 3u8, 12u8, 0u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 95u8, 108u8, 111u8, 99u8, 97u8, 108u8, 4u8, 0u8, 117u8, 117u8, 105u8, 100u8, 1u8, 0u8, 1u8, 37u8, 0u8, 0u8, 255u8, 255u8, 255u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8]),
}
}

/// Exact complete record for dl_1_12/e_domain_info_dl6.
pub fn dl_1_12_e_domain_info_dl6()->EntryRecord{
 EntryRecord{
bytes: Vec::from([5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 8u8, 0u8, 0u8, 6u8, 0u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 0u8, 6u8, 0u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 0u8, 10u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 0u8, 11u8, 0u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 95u8, 105u8, 110u8, 102u8, 111u8, 0u8, 20u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 116u8, 95u8, 101u8, 115u8, 50u8, 53u8, 54u8, 0u8, 20u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 116u8, 95u8, 104u8, 115u8, 50u8, 53u8, 54u8, 0u8, 22u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 101u8, 95u8, 97u8, 49u8, 50u8, 56u8, 103u8, 99u8, 109u8, 0u8, 22u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 101u8, 95u8, 97u8, 50u8, 53u8, 54u8, 103u8, 99u8, 109u8, 11u8, 0u8, 100u8, 101u8, 115u8, 99u8, 114u8, 105u8, 112u8, 116u8, 105u8, 111u8, 110u8, 1u8, 0u8, 2u8, 45u8, 0u8, 84u8, 104u8, 105u8, 115u8, 32u8, 108u8, 111u8, 99u8, 97u8, 108u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 39u8, 115u8, 32u8, 105u8, 110u8, 102u8, 111u8, 32u8, 97u8, 110u8, 100u8, 32u8, 109u8, 101u8, 116u8, 97u8, 100u8, 97u8, 116u8, 97u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 46u8, 4u8, 0u8, 110u8, 97u8, 109u8, 101u8, 1u8, 0u8, 3u8, 12u8, 0u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 95u8, 108u8, 111u8, 99u8, 97u8, 108u8, 4u8, 0u8, 117u8, 117u8, 105u8, 100u8, 1u8, 0u8, 1u8, 37u8, 0u8, 0u8, 255u8, 255u8, 255u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8]),
}
}

/// Exact complete record for dl_1_12/e_account_signup_feature.
pub fn dl_1_12_e_account_signup_feature()->EntryRecord{
 EntryRecord{
bytes: Vec::from([5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 2u8, 0u8, 0u8, 6u8, 0u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 0u8, 7u8, 0u8, 102u8, 101u8, 97u8, 116u8, 117u8, 114u8, 101u8, 11u8, 0u8, 100u8, 101u8, 115u8, 99u8, 114u8, 105u8, 112u8, 116u8, 105u8, 111u8, 110u8, 1u8, 0u8, 2u8, 44u8, 0u8, 67u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 115u8, 105u8, 103u8, 110u8, 117u8, 112u8, 32u8, 70u8, 101u8, 97u8, 116u8, 117u8, 114u8, 101u8, 46u8, 4u8, 0u8, 110u8, 97u8, 109u8, 101u8, 1u8, 0u8, 3u8, 22u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 115u8, 105u8, 103u8, 110u8, 117u8, 112u8, 95u8, 102u8, 101u8, 97u8, 116u8, 117u8, 114u8, 101u8, 4u8, 0u8, 117u8, 117u8, 105u8, 100u8, 1u8, 0u8, 1u8, 89u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8]),
}
}
