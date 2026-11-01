//! Exact full pinned migration group records. See DEVIATIONS.md.
#[derive(Debug,PartialEq,Eq)]
pub struct GroupRecord {
pub name:Vec<u8>,
pub description:Vec<u8>,
pub uuid:u128,
pub members:Vec<u128>,
pub member_create_once:Vec<u128>,
pub has_entry_manager:bool,
pub entry_manager:u128,
pub dyngroup:bool,
pub filter:Vec<u8>,
pub extra_attributes:Vec<u8>,
}

/// Exact complete record for dl11/BUILTIN_GROUP_SYSTEM_ADMINS_V1, dl12/BUILTIN_GROUP_SYSTEM_ADMINS_V1, dl13/BUILTIN_GROUP_SYSTEM_ADMINS_V1, dl14/BUILTIN_GROUP_SYSTEM_ADMINS_V1, dl15/BUILTIN_GROUP_SYSTEM_ADMINS_V1, dl_1_12/BUILTIN_GROUP_SYSTEM_ADMINS_V1.
pub fn dl11_builtin_group_system_admins_v1()->GroupRecord{
 GroupRecord{
name: Vec::from([115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 83u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 111u8, 114u8, 115u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 25u128,
members: Vec::from([0u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 25u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_IDM_ADMINS_V1, dl12/BUILTIN_GROUP_IDM_ADMINS_V1, dl13/BUILTIN_GROUP_IDM_ADMINS_V1, dl14/BUILTIN_GROUP_IDM_ADMINS_V1, dl15/BUILTIN_GROUP_IDM_ADMINS_V1, dl_1_12/BUILTIN_GROUP_IDM_ADMINS_V1.
pub fn dl11_builtin_group_idm_admins_v1()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 111u8, 114u8, 115u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 1u128,
members: Vec::from([24u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_SERVICE_DESK, dl12/BUILTIN_GROUP_SERVICE_DESK, dl13/BUILTIN_GROUP_SERVICE_DESK, dl14/BUILTIN_GROUP_SERVICE_DESK, dl15/BUILTIN_GROUP_SERVICE_DESK, dl_1_12/BUILTIN_GROUP_SERVICE_DESK.
pub fn dl11_builtin_group_service_desk()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 100u8, 101u8, 115u8, 107u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 83u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 68u8, 101u8, 115u8, 107u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 65u128,
members: Vec::from([]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_RECYCLE_BIN_ADMINS, dl12/BUILTIN_GROUP_RECYCLE_BIN_ADMINS, dl13/BUILTIN_GROUP_RECYCLE_BIN_ADMINS, dl14/BUILTIN_GROUP_RECYCLE_BIN_ADMINS, dl15/BUILTIN_GROUP_RECYCLE_BIN_ADMINS, dl_1_12/BUILTIN_GROUP_RECYCLE_BIN_ADMINS.
pub fn dl11_builtin_group_recycle_bin_admins()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 95u8, 98u8, 105u8, 110u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 82u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 32u8, 66u8, 105u8, 110u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 111u8, 114u8, 115u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 66u128,
members: Vec::from([25u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 25u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_DOMAIN_ADMINS, dl12/BUILTIN_GROUP_DOMAIN_ADMINS, dl13/BUILTIN_GROUP_DOMAIN_ADMINS, dl14/BUILTIN_GROUP_DOMAIN_ADMINS, dl15/BUILTIN_GROUP_DOMAIN_ADMINS, dl_1_12/BUILTIN_GROUP_DOMAIN_ADMINS.
pub fn dl11_builtin_group_domain_admins()->GroupRecord{
 GroupRecord{
name: Vec::from([100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 32u8, 102u8, 111u8, 114u8, 32u8, 103u8, 114u8, 97u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 108u8, 111u8, 99u8, 97u8, 108u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 97u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 114u8, 105u8, 103u8, 104u8, 116u8, 115u8, 32u8, 97u8, 110u8, 100u8, 32u8, 116u8, 114u8, 117u8, 115u8, 116u8, 32u8, 97u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 114u8, 105u8, 103u8, 104u8, 116u8, 115u8, 46u8]),
uuid: 32u128,
members: Vec::from([25u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 25u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_SCHEMA_ADMINS, dl12/BUILTIN_GROUP_SCHEMA_ADMINS, dl13/BUILTIN_GROUP_SCHEMA_ADMINS, dl14/BUILTIN_GROUP_SCHEMA_ADMINS, dl15/BUILTIN_GROUP_SCHEMA_ADMINS, dl_1_12/BUILTIN_GROUP_SCHEMA_ADMINS.
pub fn dl11_builtin_group_schema_admins()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 115u8, 99u8, 104u8, 101u8, 109u8, 97u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 83u8, 99u8, 104u8, 101u8, 109u8, 97u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 16u128,
members: Vec::from([25u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 25u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_ACCESS_CONTROL_ADMINS, dl12/BUILTIN_GROUP_ACCESS_CONTROL_ADMINS, dl13/BUILTIN_GROUP_ACCESS_CONTROL_ADMINS, dl14/BUILTIN_GROUP_ACCESS_CONTROL_ADMINS, dl15/BUILTIN_GROUP_ACCESS_CONTROL_ADMINS, dl_1_12/BUILTIN_GROUP_ACCESS_CONTROL_ADMINS.
pub fn dl11_builtin_group_access_control_admins()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 65u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 17u128,
members: Vec::from([25u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 25u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_PEOPLE_ADMINS, dl12/BUILTIN_GROUP_PEOPLE_ADMINS, dl13/BUILTIN_GROUP_PEOPLE_ADMINS, dl14/BUILTIN_GROUP_PEOPLE_ADMINS, dl15/BUILTIN_GROUP_PEOPLE_ADMINS, dl_1_12/BUILTIN_GROUP_PEOPLE_ADMINS.
pub fn dl11_builtin_group_people_admins()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 80u8, 101u8, 111u8, 112u8, 108u8, 101u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 19u128,
members: Vec::from([1u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_PEOPLE_ON_BOARDING, dl12/BUILTIN_GROUP_PEOPLE_ON_BOARDING, dl13/BUILTIN_GROUP_PEOPLE_ON_BOARDING, dl14/BUILTIN_GROUP_PEOPLE_ON_BOARDING, dl15/BUILTIN_GROUP_PEOPLE_ON_BOARDING, dl_1_12/BUILTIN_GROUP_PEOPLE_ON_BOARDING.
pub fn dl11_builtin_group_people_on_boarding()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 111u8, 110u8, 95u8, 98u8, 111u8, 97u8, 114u8, 100u8, 105u8, 110u8, 103u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 80u8, 101u8, 111u8, 112u8, 108u8, 101u8, 32u8, 79u8, 110u8, 32u8, 66u8, 111u8, 97u8, 114u8, 100u8, 105u8, 110u8, 103u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 69u128,
members: Vec::from([]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_PEOPLE_PII_READ, dl12/BUILTIN_GROUP_PEOPLE_PII_READ, dl13/BUILTIN_GROUP_PEOPLE_PII_READ, dl14/BUILTIN_GROUP_PEOPLE_PII_READ, dl15/BUILTIN_GROUP_PEOPLE_PII_READ, dl_1_12/BUILTIN_GROUP_PEOPLE_PII_READ.
pub fn dl11_builtin_group_people_pii_read()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 112u8, 105u8, 105u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 32u8, 102u8, 111u8, 114u8, 32u8, 103u8, 114u8, 97u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 101u8, 108u8, 101u8, 118u8, 97u8, 116u8, 101u8, 100u8, 32u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 32u8, 40u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 97u8, 108u8, 32u8, 100u8, 97u8, 116u8, 97u8, 41u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 112u8, 101u8, 114u8, 109u8, 105u8, 115u8, 115u8, 105u8, 111u8, 110u8, 115u8, 46u8]),
uuid: 2u128,
members: Vec::from([]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_PEOPLE_SELF_NAME_WRITE_DL7, dl12/BUILTIN_GROUP_PEOPLE_SELF_NAME_WRITE_DL7, dl13/BUILTIN_GROUP_PEOPLE_SELF_NAME_WRITE_DL7.
pub fn dl11_builtin_group_people_self_name_write_dl7()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 115u8, 101u8, 108u8, 102u8, 95u8, 110u8, 97u8, 109u8, 101u8, 95u8, 119u8, 114u8, 105u8, 116u8, 101u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 32u8, 100u8, 101u8, 110u8, 111u8, 116u8, 105u8, 110u8, 103u8, 32u8, 117u8, 115u8, 101u8, 114u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 97u8, 110u8, 32u8, 119u8, 114u8, 105u8, 116u8, 101u8, 32u8, 116u8, 111u8, 32u8, 116u8, 104u8, 101u8, 105u8, 114u8, 32u8, 111u8, 119u8, 110u8, 32u8, 110u8, 97u8, 109u8, 101u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 46u8]),
uuid: 72u128,
members: Vec::from([53u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_SERVICE_ACCOUNT_ADMINS, dl12/BUILTIN_GROUP_SERVICE_ACCOUNT_ADMINS, dl13/BUILTIN_GROUP_SERVICE_ACCOUNT_ADMINS, dl14/BUILTIN_GROUP_SERVICE_ACCOUNT_ADMINS, dl15/BUILTIN_GROUP_SERVICE_ACCOUNT_ADMINS, dl_1_12/BUILTIN_GROUP_SERVICE_ACCOUNT_ADMINS.
pub fn dl11_builtin_group_service_account_admins()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 83u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 65u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 70u128,
members: Vec::from([1u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_OAUTH2_ADMINS, dl12/BUILTIN_GROUP_OAUTH2_ADMINS, dl13/BUILTIN_GROUP_OAUTH2_ADMINS, dl14/BUILTIN_GROUP_OAUTH2_ADMINS, dl15/BUILTIN_GROUP_OAUTH2_ADMINS, dl_1_12/BUILTIN_GROUP_OAUTH2_ADMINS.
pub fn dl11_builtin_group_oauth2_admins()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 79u8, 97u8, 117u8, 116u8, 104u8, 50u8, 32u8, 73u8, 110u8, 116u8, 101u8, 103u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 39u128,
members: Vec::from([1u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_RADIUS_SERVICE_ADMINS, dl12/BUILTIN_GROUP_RADIUS_SERVICE_ADMINS, dl13/BUILTIN_GROUP_RADIUS_SERVICE_ADMINS, dl14/BUILTIN_GROUP_RADIUS_SERVICE_ADMINS, dl15/BUILTIN_GROUP_RADIUS_SERVICE_ADMINS, dl_1_12/BUILTIN_GROUP_RADIUS_SERVICE_ADMINS.
pub fn dl11_builtin_group_radius_service_admins()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 114u8, 97u8, 100u8, 105u8, 117u8, 115u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 82u8, 97u8, 100u8, 105u8, 117u8, 115u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 67u128,
members: Vec::from([1u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_IDM_RADIUS_SERVERS_V1, dl12/BUILTIN_IDM_RADIUS_SERVERS_V1, dl13/BUILTIN_IDM_RADIUS_SERVERS_V1, dl14/BUILTIN_IDM_RADIUS_SERVERS_V1, dl15/BUILTIN_IDM_RADIUS_SERVERS_V1, dl_1_12/BUILTIN_IDM_RADIUS_SERVERS_V1.
pub fn dl11_builtin_idm_radius_servers_v1()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 114u8, 97u8, 100u8, 105u8, 117u8, 115u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 32u8, 102u8, 111u8, 114u8, 32u8, 82u8, 65u8, 68u8, 73u8, 85u8, 83u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 100u8, 101u8, 108u8, 101u8, 103u8, 97u8, 116u8, 105u8, 111u8, 110u8, 46u8]),
uuid: 7u128,
members: Vec::from([]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 67u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_MAIL_SERVICE_ADMINS_DL8, dl12/BUILTIN_GROUP_MAIL_SERVICE_ADMINS_DL8, dl13/BUILTIN_GROUP_MAIL_SERVICE_ADMINS_DL8, dl14/BUILTIN_GROUP_MAIL_SERVICE_ADMINS_DL8, dl15/BUILTIN_GROUP_MAIL_SERVICE_ADMINS_DL8, dl_1_12/BUILTIN_GROUP_MAIL_SERVICE_ADMINS_DL8.
pub fn dl11_builtin_group_mail_service_admins_dl8()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 109u8, 97u8, 105u8, 108u8, 95u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 77u8, 97u8, 105u8, 108u8, 32u8, 83u8, 101u8, 114u8, 118u8, 101u8, 114u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 81u128,
members: Vec::from([1u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_IDM_MAIL_SERVERS_DL8, dl12/BUILTIN_IDM_MAIL_SERVERS_DL8, dl13/BUILTIN_IDM_MAIL_SERVERS_DL8, dl14/BUILTIN_IDM_MAIL_SERVERS_DL8, dl15/BUILTIN_IDM_MAIL_SERVERS_DL8, dl_1_12/BUILTIN_IDM_MAIL_SERVERS_DL8.
pub fn dl11_builtin_idm_mail_servers_dl8()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 109u8, 97u8, 105u8, 108u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 32u8, 102u8, 111u8, 114u8, 32u8, 77u8, 65u8, 73u8, 76u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 100u8, 101u8, 108u8, 101u8, 103u8, 97u8, 116u8, 105u8, 111u8, 110u8, 46u8]),
uuid: 82u128,
members: Vec::from([]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 81u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_ACCOUNT_POLICY_ADMINS, dl12/BUILTIN_GROUP_ACCOUNT_POLICY_ADMINS, dl13/BUILTIN_GROUP_ACCOUNT_POLICY_ADMINS, dl14/BUILTIN_GROUP_ACCOUNT_POLICY_ADMINS, dl15/BUILTIN_GROUP_ACCOUNT_POLICY_ADMINS, dl_1_12/BUILTIN_GROUP_ACCOUNT_POLICY_ADMINS.
pub fn dl11_builtin_group_account_policy_admins()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 65u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 80u8, 111u8, 108u8, 105u8, 99u8, 121u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 71u128,
members: Vec::from([1u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_UNIX_ADMINS, dl12/BUILTIN_GROUP_UNIX_ADMINS, dl13/BUILTIN_GROUP_UNIX_ADMINS, dl14/BUILTIN_GROUP_UNIX_ADMINS, dl15/BUILTIN_GROUP_UNIX_ADMINS, dl_1_12/BUILTIN_GROUP_UNIX_ADMINS.
pub fn dl11_builtin_group_unix_admins()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 117u8, 110u8, 105u8, 120u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 85u8, 110u8, 105u8, 120u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 68u128,
members: Vec::from([1u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_CLIENT_CERTIFICATE_ADMINS_DL7, dl12/BUILTIN_GROUP_CLIENT_CERTIFICATE_ADMINS_DL7, dl13/BUILTIN_GROUP_CLIENT_CERTIFICATE_ADMINS_DL7, dl14/BUILTIN_GROUP_CLIENT_CERTIFICATE_ADMINS_DL7, dl15/BUILTIN_GROUP_CLIENT_CERTIFICATE_ADMINS_DL7, dl_1_12/BUILTIN_GROUP_CLIENT_CERTIFICATE_ADMINS_DL7.
pub fn dl11_builtin_group_client_certificate_admins_dl7()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 95u8, 99u8, 101u8, 114u8, 116u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 101u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 67u8, 108u8, 105u8, 101u8, 110u8, 116u8, 32u8, 67u8, 101u8, 114u8, 116u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 101u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 73u128,
members: Vec::from([1u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/IDM_GROUP_ADMINS_V1, dl12/IDM_GROUP_ADMINS_V1, dl13/IDM_GROUP_ADMINS_V1, dl14/IDM_GROUP_ADMINS_V1, dl15/IDM_GROUP_ADMINS_V1, dl_1_12/IDM_GROUP_ADMINS_V1.
pub fn dl11_idm_group_admins_v1()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 32u8, 102u8, 111u8, 114u8, 32u8, 103u8, 114u8, 97u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 101u8, 108u8, 101u8, 118u8, 97u8, 116u8, 101u8, 100u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 119u8, 114u8, 105u8, 116u8, 101u8, 32u8, 97u8, 110u8, 100u8, 32u8, 108u8, 105u8, 102u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 32u8, 112u8, 101u8, 114u8, 109u8, 105u8, 115u8, 115u8, 105u8, 111u8, 110u8, 115u8, 46u8]),
uuid: 21u128,
members: Vec::from([1u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/IDM_PEOPLE_SELF_MAIL_WRITE_DL7, dl12/IDM_PEOPLE_SELF_MAIL_WRITE_DL7, dl13/IDM_PEOPLE_SELF_MAIL_WRITE_DL7, dl14/IDM_PEOPLE_SELF_MAIL_WRITE_DL7, dl15/IDM_PEOPLE_SELF_MAIL_WRITE_DL7, dl_1_12/IDM_PEOPLE_SELF_MAIL_WRITE_DL7.
pub fn dl11_idm_people_self_mail_write_dl7()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 115u8, 101u8, 108u8, 102u8, 95u8, 109u8, 97u8, 105u8, 108u8, 95u8, 119u8, 114u8, 105u8, 116u8, 101u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 32u8, 102u8, 111u8, 114u8, 32u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 32u8, 116u8, 111u8, 32u8, 117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 32u8, 116u8, 104u8, 101u8, 105u8, 114u8, 32u8, 111u8, 119u8, 110u8, 32u8, 109u8, 97u8, 105u8, 108u8, 46u8]),
uuid: 51u128,
members: Vec::from([]),
member_create_once: Vec::from([]),
has_entry_manager: false,
entry_manager: 0u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/IDM_ALL_PERSONS, dl12/IDM_ALL_PERSONS, dl13/IDM_ALL_PERSONS, dl14/IDM_ALL_PERSONS, dl15/IDM_ALL_PERSONS, dl_1_12/IDM_ALL_PERSONS.
pub fn dl11_idm_all_persons()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 108u8, 108u8, 95u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 100u8, 121u8, 110u8, 97u8, 109u8, 105u8, 99u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 99u8, 111u8, 110u8, 116u8, 97u8, 105u8, 110u8, 105u8, 110u8, 103u8, 32u8, 97u8, 108u8, 108u8, 32u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 115u8, 46u8]),
uuid: 53u128,
members: Vec::from([]),
member_create_once: Vec::from([]),
has_entry_manager: false,
entry_manager: 0u128,
dyngroup: true,
filter: Vec::from([1u8, 2u8, 0u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
extra_attributes: Vec::from([5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 0u8, 14u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 0u8, 6u8, 0u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 23u8, 0u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 95u8, 116u8, 121u8, 112u8, 101u8, 95u8, 109u8, 105u8, 110u8, 105u8, 109u8, 117u8, 109u8, 1u8, 10u8, 0u8]),
}
}

/// Exact complete record for dl11/IDM_ALL_ACCOUNTS, dl12/IDM_ALL_ACCOUNTS, dl13/IDM_ALL_ACCOUNTS, dl14/IDM_ALL_ACCOUNTS, dl15/IDM_ALL_ACCOUNTS, dl_1_12/IDM_ALL_ACCOUNTS.
pub fn dl11_idm_all_accounts()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 108u8, 108u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 100u8, 121u8, 110u8, 97u8, 109u8, 105u8, 99u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 99u8, 111u8, 110u8, 116u8, 97u8, 105u8, 110u8, 105u8, 110u8, 103u8, 32u8, 97u8, 108u8, 108u8, 32u8, 101u8, 110u8, 116u8, 114u8, 105u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 97u8, 110u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 101u8, 46u8]),
uuid: 54u128,
members: Vec::from([]),
member_create_once: Vec::from([]),
has_entry_manager: false,
entry_manager: 0u128,
dyngroup: true,
filter: Vec::from([0u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
extra_attributes: Vec::from([5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 0u8, 14u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8, 5u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 0u8, 6u8, 0u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8]),
}
}

/// Exact complete record for dl11/IDM_UI_ENABLE_EXPERIMENTAL_FEATURES, dl12/IDM_UI_ENABLE_EXPERIMENTAL_FEATURES, dl13/IDM_UI_ENABLE_EXPERIMENTAL_FEATURES, dl14/IDM_UI_ENABLE_EXPERIMENTAL_FEATURES, dl15/IDM_UI_ENABLE_EXPERIMENTAL_FEATURES, dl_1_12/IDM_UI_ENABLE_EXPERIMENTAL_FEATURES.
pub fn dl11_idm_ui_enable_experimental_features()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 117u8, 105u8, 95u8, 101u8, 110u8, 97u8, 98u8, 108u8, 101u8, 95u8, 101u8, 120u8, 112u8, 101u8, 114u8, 105u8, 109u8, 101u8, 110u8, 116u8, 97u8, 108u8, 95u8, 102u8, 101u8, 97u8, 116u8, 117u8, 114u8, 101u8, 115u8]),
description: Vec::from([77u8, 101u8, 109u8, 98u8, 101u8, 114u8, 115u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 119u8, 105u8, 108u8, 108u8, 32u8, 104u8, 97u8, 118u8, 101u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 116u8, 111u8, 32u8, 101u8, 120u8, 112u8, 101u8, 114u8, 105u8, 109u8, 101u8, 110u8, 116u8, 97u8, 108u8, 32u8, 119u8, 101u8, 98u8, 32u8, 85u8, 73u8, 32u8, 102u8, 101u8, 97u8, 116u8, 117u8, 114u8, 101u8, 115u8, 46u8]),
uuid: 56u128,
members: Vec::from([]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([13u8, 0u8, 103u8, 114u8, 97u8, 110u8, 116u8, 95u8, 117u8, 105u8, 95u8, 104u8, 105u8, 110u8, 116u8, 2u8]),
}
}

/// Exact complete record for dl11/IDM_ACCOUNT_MAIL_READ, dl12/IDM_ACCOUNT_MAIL_READ, dl13/IDM_ACCOUNT_MAIL_READ, dl14/IDM_ACCOUNT_MAIL_READ, dl15/IDM_ACCOUNT_MAIL_READ, dl_1_12/IDM_ACCOUNT_MAIL_READ.
pub fn dl11_idm_account_mail_read()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 109u8, 97u8, 105u8, 108u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
description: Vec::from([77u8, 101u8, 109u8, 98u8, 101u8, 114u8, 115u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 119u8, 105u8, 108u8, 108u8, 32u8, 104u8, 97u8, 118u8, 101u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 116u8, 104u8, 101u8, 32u8, 109u8, 97u8, 105u8, 108u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 111u8, 102u8, 32u8, 97u8, 108u8, 108u8, 32u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 115u8, 32u8, 97u8, 110u8, 100u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 46u8]),
uuid: 57u128,
members: Vec::from([]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 17u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/IDM_HIGH_PRIVILEGE_DL8.
pub fn dl11_idm_high_privilege_dl8()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 104u8, 105u8, 103u8, 104u8, 95u8, 112u8, 114u8, 105u8, 118u8, 105u8, 108u8, 101u8, 103u8, 101u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 100u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 115u8, 32u8, 119u8, 105u8, 116u8, 104u8, 32u8, 104u8, 105u8, 103u8, 104u8, 32u8, 108u8, 101u8, 118u8, 101u8, 108u8, 115u8, 32u8, 111u8, 102u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 115u8, 104u8, 111u8, 117u8, 108u8, 100u8, 32u8, 98u8, 101u8, 32u8, 97u8, 117u8, 100u8, 105u8, 116u8, 101u8, 100u8, 32u8, 97u8, 110u8, 100u8, 32u8, 108u8, 105u8, 109u8, 105u8, 116u8, 101u8, 100u8, 32u8, 105u8, 110u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 46u8]),
uuid: 4096u128,
members: Vec::from([25u128, 1u128, 32u128, 65u128, 66u128, 16u128, 17u128, 39u128, 67u128, 71u128, 7u128, 21u128, 68u128, 2u128, 19u128, 69u128, 70u128, 73u128, 80u128, 81u128, 4096u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 17u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl11/BUILTIN_GROUP_APPLICATION_ADMINS_DL8, dl12/BUILTIN_GROUP_APPLICATION_ADMINS_DL8, dl13/BUILTIN_GROUP_APPLICATION_ADMINS_DL8, dl14/BUILTIN_GROUP_APPLICATION_ADMINS_DL8, dl15/BUILTIN_GROUP_APPLICATION_ADMINS_DL8, dl_1_12/BUILTIN_GROUP_APPLICATION_ADMINS_DL8.
pub fn dl11_builtin_group_application_admins_dl8()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 65u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 80u128,
members: Vec::from([1u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl12/BUILTIN_GROUP_IDM_UNIX_AUTHENTICATION_READ_V1, dl13/BUILTIN_GROUP_IDM_UNIX_AUTHENTICATION_READ_V1, dl14/BUILTIN_GROUP_IDM_UNIX_AUTHENTICATION_READ_V1, dl15/BUILTIN_GROUP_IDM_UNIX_AUTHENTICATION_READ_V1, dl_1_12/BUILTIN_GROUP_IDM_UNIX_AUTHENTICATION_READ_V1.
pub fn dl12_builtin_group_idm_unix_authentication_read_v1()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 117u8, 110u8, 105u8, 120u8, 95u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 95u8, 114u8, 101u8, 97u8, 100u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 97u8, 110u8, 100u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 101u8, 32u8, 117u8, 110u8, 105u8, 120u8, 32u8, 117u8, 115u8, 101u8, 114u8, 115u8, 46u8]),
uuid: 83u128,
members: Vec::from([281474976710655u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 68u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl12/BUILTIN_GROUP_MESSAGE_ADMINS, dl13/BUILTIN_GROUP_MESSAGE_ADMINS, dl14/BUILTIN_GROUP_MESSAGE_ADMINS, dl15/BUILTIN_GROUP_MESSAGE_ADMINS, dl_1_12/BUILTIN_GROUP_MESSAGE_ADMINS.
pub fn dl12_builtin_group_message_admins()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 77u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 84u128,
members: Vec::from([1u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl12/BUILTIN_GROUP_MESSAGE_SENDERS, dl13/BUILTIN_GROUP_MESSAGE_SENDERS, dl14/BUILTIN_GROUP_MESSAGE_SENDERS, dl15/BUILTIN_GROUP_MESSAGE_SENDERS, dl_1_12/BUILTIN_GROUP_MESSAGE_SENDERS.
pub fn dl12_builtin_group_message_senders()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 95u8, 115u8, 101u8, 110u8, 100u8, 101u8, 114u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 32u8, 102u8, 111u8, 114u8, 32u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 32u8, 115u8, 101u8, 110u8, 100u8, 101u8, 114u8, 115u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 97u8, 100u8, 32u8, 97u8, 110u8, 100u8, 32u8, 112u8, 114u8, 111u8, 99u8, 101u8, 115u8, 115u8, 32u8, 113u8, 117u8, 101u8, 117u8, 101u8, 100u8, 32u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 115u8, 46u8]),
uuid: 85u128,
members: Vec::from([]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 84u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl12/BUILTIN_GROUP_OAUTH2_CLIENT_ADMINS, dl13/BUILTIN_GROUP_OAUTH2_CLIENT_ADMINS, dl14/BUILTIN_GROUP_OAUTH2_CLIENT_ADMINS, dl15/BUILTIN_GROUP_OAUTH2_CLIENT_ADMINS, dl_1_12/BUILTIN_GROUP_OAUTH2_CLIENT_ADMINS.
pub fn dl12_builtin_group_oauth2_client_admins()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 68u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 84u8, 114u8, 117u8, 115u8, 116u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 86u128,
members: Vec::from([25u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 25u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl12/BUILTIN_GROUP_OAUTH2_ACCOUNT_ADMINS, dl13/BUILTIN_GROUP_OAUTH2_ACCOUNT_ADMINS, dl14/BUILTIN_GROUP_OAUTH2_ACCOUNT_ADMINS, dl15/BUILTIN_GROUP_OAUTH2_ACCOUNT_ADMINS, dl_1_12/BUILTIN_GROUP_OAUTH2_ACCOUNT_ADMINS.
pub fn dl12_builtin_group_oauth2_account_admins()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8, 115u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 68u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 84u8, 114u8, 117u8, 115u8, 116u8, 32u8, 65u8, 100u8, 109u8, 105u8, 110u8, 105u8, 115u8, 116u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 46u8]),
uuid: 87u128,
members: Vec::from([1u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl12/IDM_HIGH_PRIVILEGE_DL8, dl13/IDM_HIGH_PRIVILEGE_DL8, dl14/IDM_HIGH_PRIVILEGE_DL8, dl15/IDM_HIGH_PRIVILEGE_DL8, dl_1_12/IDM_HIGH_PRIVILEGE_DL8.
pub fn dl12_idm_high_privilege_dl8()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 104u8, 105u8, 103u8, 104u8, 95u8, 112u8, 114u8, 105u8, 118u8, 105u8, 108u8, 101u8, 103u8, 101u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 100u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 115u8, 32u8, 119u8, 105u8, 116u8, 104u8, 32u8, 104u8, 105u8, 103u8, 104u8, 32u8, 108u8, 101u8, 118u8, 101u8, 108u8, 115u8, 32u8, 111u8, 102u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 115u8, 104u8, 111u8, 117u8, 108u8, 100u8, 32u8, 98u8, 101u8, 32u8, 97u8, 117u8, 100u8, 105u8, 116u8, 101u8, 100u8, 32u8, 97u8, 110u8, 100u8, 32u8, 108u8, 105u8, 109u8, 105u8, 116u8, 101u8, 100u8, 32u8, 105u8, 110u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 46u8]),
uuid: 4096u128,
members: Vec::from([25u128, 1u128, 32u128, 65u128, 66u128, 16u128, 17u128, 39u128, 67u128, 71u128, 7u128, 21u128, 68u128, 2u128, 19u128, 69u128, 70u128, 73u128, 80u128, 81u128, 84u128, 85u128, 86u128, 87u128, 4096u128]),
member_create_once: Vec::from([]),
has_entry_manager: true,
entry_manager: 17u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}

/// Exact complete record for dl14/BUILTIN_GROUP_PEOPLE_SELF_NAME_WRITE_DL7, dl15/BUILTIN_GROUP_PEOPLE_SELF_NAME_WRITE_DL7, dl_1_12/BUILTIN_GROUP_PEOPLE_SELF_NAME_WRITE_DL7.
pub fn dl14_builtin_group_people_self_name_write_dl7()->GroupRecord{
 GroupRecord{
name: Vec::from([105u8, 100u8, 109u8, 95u8, 112u8, 101u8, 111u8, 112u8, 108u8, 101u8, 95u8, 115u8, 101u8, 108u8, 102u8, 95u8, 110u8, 97u8, 109u8, 101u8, 95u8, 119u8, 114u8, 105u8, 116u8, 101u8]),
description: Vec::from([66u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 73u8, 68u8, 77u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8, 32u8, 100u8, 101u8, 110u8, 111u8, 116u8, 105u8, 110u8, 103u8, 32u8, 117u8, 115u8, 101u8, 114u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 97u8, 110u8, 32u8, 119u8, 114u8, 105u8, 116u8, 101u8, 32u8, 116u8, 111u8, 32u8, 116u8, 104u8, 101u8, 105u8, 114u8, 32u8, 111u8, 119u8, 110u8, 32u8, 110u8, 97u8, 109u8, 101u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 46u8]),
uuid: 72u128,
members: Vec::from([]),
member_create_once: Vec::from([53u128]),
has_entry_manager: true,
entry_manager: 1u128,
dyngroup: false,
filter: Vec::from([]),
extra_attributes: Vec::from([]),
}
}
