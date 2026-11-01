//! Exact full pinned migration schema records. See DEVIATIONS.md.
#[derive(Debug,PartialEq,Eq)]
pub struct AttributeRecord {
pub name:u16,
pub uuid:u128,
pub description:Vec<u8>,
pub multivalue:bool,
pub unique:bool,
pub phantom:bool,
pub sync_allowed:bool,
pub replicated:bool,
pub indexed:bool,
pub syntax:u16,
}
#[derive(Debug,PartialEq,Eq)]
pub struct ClassRecord {
pub name:Vec<u8>,
pub uuid:u128,
pub description:Vec<u8>,
pub sync_allowed:bool,
pub systemmay:Vec<u16>,
pub may:Vec<u16>,
pub systemmust:Vec<u16>,
pub must:Vec<u16>,
pub systemsupplements:Vec<u8>,
pub supplements:Vec<u8>,
pub systemexcludes:Vec<u8>,
pub excludes:Vec<u8>,
}

/// Exact complete record for system/SCHEMA_ATTR_CLASS.
pub fn system_attr_class()->AttributeRecord{
 AttributeRecord{
name: 29u16,
uuid: 281470681743360u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 101u8, 115u8, 32u8, 100u8, 101u8, 102u8, 105u8, 110u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_UUID.
pub fn system_attr_uuid()->AttributeRecord{
 AttributeRecord{
name: 175u16,
uuid: 281470681743361u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 117u8, 110u8, 105u8, 118u8, 101u8, 114u8, 115u8, 97u8, 108u8, 32u8, 117u8, 110u8, 105u8, 113u8, 117u8, 101u8, 32u8, 105u8, 100u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 2u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_SOURCE_UUID.
pub fn system_attr_source_uuid()->AttributeRecord{
 AttributeRecord{
name: 150u16,
uuid: 281470681743680u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 117u8, 110u8, 105u8, 118u8, 101u8, 114u8, 115u8, 97u8, 108u8, 32u8, 117u8, 110u8, 105u8, 113u8, 117u8, 101u8, 32u8, 105u8, 100u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 40u8, 115u8, 41u8, 32u8, 119u8, 104u8, 105u8, 99u8, 104u8, 32u8, 99u8, 111u8, 110u8, 102u8, 108u8, 105u8, 99u8, 116u8, 101u8, 100u8, 32u8, 119u8, 105u8, 116u8, 104u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 2u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_CREATED_AT_CID.
pub fn system_attr_created_at_cid()->AttributeRecord{
 AttributeRecord{
name: 32u16,
uuid: 281470681743748u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 105u8, 100u8, 32u8, 119u8, 104u8, 101u8, 110u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 119u8, 97u8, 115u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 101u8, 100u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 13u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_LAST_MODIFIED_CID.
pub fn system_attr_last_modified_cid()->AttributeRecord{
 AttributeRecord{
name: 81u16,
uuid: 281470681743459u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 105u8, 100u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 108u8, 97u8, 115u8, 116u8, 32u8, 99u8, 104u8, 97u8, 110u8, 103u8, 101u8, 32u8, 116u8, 111u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 13u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_NAME.
pub fn system_attr_name()->AttributeRecord{
 AttributeRecord{
name: 100u16,
uuid: 281470681743362u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 104u8, 111u8, 114u8, 116u8, 102u8, 111u8, 114u8, 109u8, 32u8, 110u8, 97u8, 109u8, 101u8, 32u8, 111u8, 102u8, 32u8, 97u8, 110u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
multivalue: false,
unique: true,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: true,
syntax: 14u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_SPN.
pub fn system_attr_spn()->AttributeRecord{
 AttributeRecord{
name: 151u16,
uuid: 281470681743363u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 83u8, 101u8, 99u8, 117u8, 114u8, 105u8, 116u8, 121u8, 32u8, 80u8, 114u8, 105u8, 110u8, 99u8, 105u8, 112u8, 97u8, 108u8, 32u8, 78u8, 97u8, 109u8, 101u8, 32u8, 111u8, 102u8, 32u8, 97u8, 110u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 44u8, 32u8, 117u8, 110u8, 105u8, 113u8, 117u8, 101u8, 32u8, 97u8, 99u8, 114u8, 111u8, 115u8, 115u8, 32u8, 97u8, 108u8, 108u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 116u8, 114u8, 117u8, 115u8, 116u8, 115u8]),
multivalue: false,
unique: true,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 11u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ATTRIBUTE_NAME.
pub fn system_attr_attribute_name()->AttributeRecord{
 AttributeRecord{
name: 21u16,
uuid: 281470681743432u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 110u8, 97u8, 109u8, 101u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 115u8, 99u8, 104u8, 101u8, 109u8, 97u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8]),
multivalue: false,
unique: true,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_CLASS_NAME.
pub fn system_attr_class_name()->AttributeRecord{
 AttributeRecord{
name: 30u16,
uuid: 281470681743433u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 110u8, 97u8, 109u8, 101u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 115u8, 99u8, 104u8, 101u8, 109u8, 97u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8]),
multivalue: false,
unique: true,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_DESCRIPTION.
pub fn system_attr_description()->AttributeRecord{
 AttributeRecord{
name: 37u16,
uuid: 281470681743364u128,
description: Vec::from([65u8, 32u8, 100u8, 101u8, 115u8, 99u8, 114u8, 105u8, 112u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 110u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 44u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 111u8, 114u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: false,
syntax: 0u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_MULTI_VALUE.
pub fn system_attr_multi_value()->AttributeRecord{
 AttributeRecord{
name: 98u16,
uuid: 281470681743365u128,
description: Vec::from([73u8, 102u8, 32u8, 116u8, 114u8, 117u8, 101u8, 44u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 105u8, 115u8, 32u8, 97u8, 98u8, 108u8, 101u8, 32u8, 116u8, 111u8, 32u8, 115u8, 116u8, 111u8, 114u8, 101u8, 32u8, 109u8, 117u8, 108u8, 116u8, 105u8, 112u8, 108u8, 101u8, 32u8, 118u8, 97u8, 108u8, 117u8, 101u8, 115u8, 32u8, 114u8, 97u8, 116u8, 104u8, 101u8, 114u8, 32u8, 116u8, 104u8, 97u8, 110u8, 32u8, 106u8, 117u8, 115u8, 116u8, 32u8, 97u8, 32u8, 115u8, 105u8, 110u8, 103u8, 108u8, 101u8, 32u8, 118u8, 97u8, 108u8, 117u8, 101u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_PHANTOM.
pub fn system_attr_phantom()->AttributeRecord{
 AttributeRecord{
name: 137u16,
uuid: 281470681743460u128,
description: Vec::from([73u8, 102u8, 32u8, 116u8, 114u8, 117u8, 101u8, 44u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 109u8, 117u8, 115u8, 116u8, 32u8, 78u8, 79u8, 84u8, 32u8, 98u8, 101u8, 32u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 32u8, 105u8, 110u8, 32u8, 97u8, 110u8, 121u8, 32u8, 109u8, 97u8, 121u8, 47u8, 109u8, 117u8, 115u8, 116u8, 32u8, 115u8, 101u8, 116u8, 115u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 97u8, 115u8, 46u8, 32u8, 84u8, 104u8, 105u8, 115u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 115u8, 32u8, 103u8, 101u8, 110u8, 101u8, 114u8, 97u8, 116u8, 101u8, 100u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_SYNC_ALLOWED.
pub fn system_attr_sync_allowed()->AttributeRecord{
 AttributeRecord{
name: 155u16,
uuid: 281470681743653u128,
description: Vec::from([73u8, 102u8, 32u8, 116u8, 114u8, 117u8, 101u8, 44u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 111u8, 114u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 99u8, 97u8, 110u8, 32u8, 98u8, 121u8, 32u8, 115u8, 121u8, 110u8, 99u8, 104u8, 114u8, 111u8, 110u8, 105u8, 115u8, 101u8, 100u8, 32u8, 98u8, 121u8, 32u8, 97u8, 110u8, 32u8, 101u8, 120u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 115u8, 99u8, 105u8, 109u8, 32u8, 105u8, 109u8, 112u8, 111u8, 114u8, 116u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_REPLICATED.
pub fn system_attr_replicated()->AttributeRecord{
 AttributeRecord{
name: 144u16,
uuid: 281470681743657u128,
description: Vec::from([73u8, 102u8, 32u8, 116u8, 114u8, 117u8, 101u8, 44u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 111u8, 114u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 99u8, 97u8, 110u8, 32u8, 98u8, 121u8, 32u8, 114u8, 101u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 101u8, 100u8, 32u8, 98u8, 101u8, 116u8, 119u8, 101u8, 101u8, 110u8, 32u8, 110u8, 111u8, 100u8, 101u8, 115u8, 32u8, 105u8, 110u8, 32u8, 116u8, 104u8, 101u8, 32u8, 116u8, 111u8, 112u8, 111u8, 108u8, 111u8, 103u8, 121u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_UNIQUE.
pub fn system_attr_unique()->AttributeRecord{
 AttributeRecord{
name: 171u16,
uuid: 281470681743431u128,
description: Vec::from([73u8, 102u8, 32u8, 116u8, 114u8, 117u8, 101u8, 44u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 109u8, 117u8, 115u8, 116u8, 32u8, 115u8, 116u8, 111u8, 114u8, 101u8, 32u8, 97u8, 32u8, 117u8, 110u8, 105u8, 113u8, 117u8, 101u8, 32u8, 118u8, 97u8, 108u8, 117u8, 101u8, 32u8, 116u8, 104u8, 114u8, 111u8, 117u8, 103u8, 104u8, 32u8, 111u8, 117u8, 116u8, 32u8, 116u8, 104u8, 101u8, 32u8, 100u8, 97u8, 116u8, 97u8, 98u8, 97u8, 115u8, 101u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_INDEX.
pub fn system_attr_index()->AttributeRecord{
 AttributeRecord{
name: 72u16,
uuid: 281470681743366u128,
description: Vec::from([68u8, 101u8, 115u8, 99u8, 114u8, 105u8, 98u8, 101u8, 32u8, 116u8, 104u8, 101u8, 32u8, 105u8, 110u8, 100u8, 101u8, 120u8, 101u8, 115u8, 32u8, 116u8, 111u8, 32u8, 97u8, 112u8, 112u8, 108u8, 121u8, 32u8, 116u8, 111u8, 32u8, 105u8, 110u8, 115u8, 116u8, 97u8, 110u8, 99u8, 101u8, 115u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 5u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_INDEXED.
pub fn system_attr_indexed()->AttributeRecord{
 AttributeRecord{
name: 73u16,
uuid: 281470681743752u128,
description: Vec::from([65u8, 32u8, 98u8, 111u8, 111u8, 108u8, 101u8, 97u8, 110u8, 32u8, 115u8, 116u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 105u8, 102u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 119u8, 105u8, 108u8, 108u8, 32u8, 98u8, 101u8, 32u8, 105u8, 110u8, 100u8, 101u8, 120u8, 101u8, 100u8, 32u8, 97u8, 99u8, 99u8, 111u8, 114u8, 100u8, 105u8, 110u8, 103u8, 32u8, 116u8, 111u8, 32u8, 105u8, 116u8, 115u8, 32u8, 115u8, 121u8, 110u8, 116u8, 97u8, 120u8, 32u8, 114u8, 117u8, 108u8, 101u8, 115u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_SYNTAX.
pub fn system_attr_syntax()->AttributeRecord{
 AttributeRecord{
name: 163u16,
uuid: 281470681743367u128,
description: Vec::from([68u8, 101u8, 115u8, 99u8, 114u8, 105u8, 98u8, 101u8, 32u8, 116u8, 104u8, 101u8, 32u8, 115u8, 121u8, 110u8, 116u8, 97u8, 120u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 46u8, 32u8, 84u8, 104u8, 105u8, 115u8, 32u8, 97u8, 102u8, 102u8, 101u8, 99u8, 116u8, 115u8, 32u8, 105u8, 110u8, 100u8, 101u8, 120u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 100u8, 32u8, 115u8, 111u8, 114u8, 116u8, 105u8, 110u8, 103u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 4u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_SYSTEM_MAY.
pub fn system_attr_system_may()->AttributeRecord{
 AttributeRecord{
name: 165u16,
uuid: 281470681743368u128,
description: Vec::from([65u8, 32u8, 108u8, 105u8, 115u8, 116u8, 32u8, 111u8, 102u8, 32u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 100u8, 32u8, 111u8, 112u8, 116u8, 105u8, 111u8, 110u8, 97u8, 108u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 99u8, 97u8, 110u8, 32u8, 115u8, 116u8, 111u8, 114u8, 101u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_MAY.
pub fn system_attr_may()->AttributeRecord{
 AttributeRecord{
name: 94u16,
uuid: 281470681743369u128,
description: Vec::from([65u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 105u8, 97u8, 98u8, 108u8, 101u8, 32u8, 108u8, 105u8, 115u8, 116u8, 32u8, 111u8, 102u8, 32u8, 111u8, 112u8, 116u8, 105u8, 111u8, 110u8, 97u8, 108u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 99u8, 97u8, 110u8, 32u8, 115u8, 116u8, 111u8, 114u8, 101u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_SYSTEM_MUST.
pub fn system_attr_system_must()->AttributeRecord{
 AttributeRecord{
name: 166u16,
uuid: 281470681743376u128,
description: Vec::from([65u8, 32u8, 108u8, 105u8, 115u8, 116u8, 32u8, 111u8, 102u8, 32u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 100u8, 32u8, 114u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 100u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 109u8, 117u8, 115u8, 116u8, 32u8, 115u8, 116u8, 111u8, 114u8, 101u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_MUST.
pub fn system_attr_must()->AttributeRecord{
 AttributeRecord{
name: 99u16,
uuid: 281470681743377u128,
description: Vec::from([65u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 105u8, 97u8, 98u8, 108u8, 101u8, 32u8, 108u8, 105u8, 115u8, 116u8, 32u8, 111u8, 102u8, 32u8, 114u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 100u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 109u8, 117u8, 115u8, 116u8, 32u8, 115u8, 116u8, 111u8, 114u8, 101u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_SYSTEM_SUPPLEMENTS.
pub fn system_attr_system_supplements()->AttributeRecord{
 AttributeRecord{
name: 167u16,
uuid: 281470681743617u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 116u8, 121u8, 112u8, 101u8, 32u8, 115u8, 117u8, 112u8, 112u8, 108u8, 101u8, 109u8, 101u8, 110u8, 116u8, 115u8, 44u8, 32u8, 119u8, 104u8, 101u8, 114u8, 101u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 99u8, 97u8, 110u8, 39u8, 116u8, 32u8, 101u8, 120u8, 105u8, 115u8, 116u8, 32u8, 119u8, 105u8, 116u8, 104u8, 111u8, 117u8, 116u8, 32u8, 116u8, 104u8, 101u8, 105u8, 114u8, 32u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 99u8, 101u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_SUPPLEMENTS.
pub fn system_attr_supplements()->AttributeRecord{
 AttributeRecord{
name: 154u16,
uuid: 281470681743618u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 105u8, 97u8, 98u8, 108u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 101u8, 115u8, 44u8, 32u8, 119u8, 104u8, 101u8, 114u8, 101u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 100u8, 101u8, 116u8, 101u8, 114u8, 109u8, 105u8, 110u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 97u8, 116u8, 32u8, 108u8, 101u8, 97u8, 115u8, 116u8, 32u8, 111u8, 110u8, 101u8, 32u8, 111u8, 116u8, 104u8, 101u8, 114u8, 32u8, 116u8, 121u8, 112u8, 101u8, 32u8, 109u8, 117u8, 115u8, 116u8, 32u8, 115u8, 117u8, 112u8, 112u8, 108u8, 101u8, 109u8, 101u8, 110u8, 116u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 116u8, 121u8, 112u8, 101u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_SYSTEM_EXCLUDES.
pub fn system_attr_system_excludes()->AttributeRecord{
 AttributeRecord{
name: 164u16,
uuid: 281470681743619u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 97u8, 114u8, 101u8, 32u8, 100u8, 101u8, 110u8, 105u8, 101u8, 100u8, 32u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 99u8, 101u8, 32u8, 105u8, 110u8, 32u8, 99u8, 111u8, 110u8, 110u8, 101u8, 99u8, 116u8, 105u8, 111u8, 110u8, 32u8, 116u8, 111u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_EXCLUDES.
pub fn system_attr_excludes()->AttributeRecord{
 AttributeRecord{
name: 61u16,
uuid: 281470681743620u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 105u8, 97u8, 98u8, 108u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 97u8, 114u8, 101u8, 32u8, 100u8, 101u8, 110u8, 105u8, 101u8, 100u8, 32u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 99u8, 101u8, 32u8, 105u8, 110u8, 32u8, 99u8, 111u8, 110u8, 110u8, 101u8, 99u8, 116u8, 105u8, 111u8, 110u8, 32u8, 116u8, 111u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ACP_ENABLE.
pub fn system_attr_acp_enable()->AttributeRecord{
 AttributeRecord{
name: 6u16,
uuid: 281470681743383u128,
description: Vec::from([65u8, 32u8, 102u8, 108u8, 97u8, 103u8, 32u8, 116u8, 111u8, 32u8, 100u8, 101u8, 116u8, 101u8, 114u8, 109u8, 105u8, 110u8, 101u8, 32u8, 105u8, 102u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 65u8, 67u8, 80u8, 32u8, 105u8, 115u8, 32u8, 97u8, 99u8, 116u8, 105u8, 118u8, 101u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 46u8, 32u8, 84u8, 114u8, 117u8, 101u8, 32u8, 105u8, 115u8, 32u8, 101u8, 110u8, 97u8, 98u8, 108u8, 101u8, 100u8, 44u8, 32u8, 97u8, 110u8, 100u8, 32u8, 101u8, 110u8, 102u8, 111u8, 114u8, 99u8, 101u8, 100u8, 46u8, 32u8, 70u8, 97u8, 108u8, 115u8, 101u8, 32u8, 105u8, 115u8, 32u8, 99u8, 104u8, 101u8, 99u8, 107u8, 101u8, 100u8, 32u8, 98u8, 117u8, 116u8, 32u8, 110u8, 111u8, 116u8, 32u8, 101u8, 110u8, 102u8, 111u8, 114u8, 99u8, 101u8, 100u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 3u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ACP_RECEIVER.
pub fn system_attr_acp_receiver()->AttributeRecord{
 AttributeRecord{
name: 12u16,
uuid: 281470681743384u128,
description: Vec::from([87u8, 104u8, 111u8, 32u8, 116u8, 104u8, 101u8, 32u8, 65u8, 67u8, 80u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 101u8, 115u8, 32u8, 116u8, 111u8, 44u8, 32u8, 99u8, 111u8, 110u8, 115u8, 116u8, 114u8, 97u8, 105u8, 110u8, 105u8, 110u8, 103u8, 32u8, 111u8, 114u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 32u8, 111u8, 112u8, 101u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 7u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ACP_RECEIVER_GROUP.
pub fn system_attr_acp_receiver_group()->AttributeRecord{
 AttributeRecord{
name: 13u16,
uuid: 281470681743640u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 114u8, 101u8, 99u8, 101u8, 105u8, 118u8, 101u8, 115u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 116u8, 111u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 6u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ACP_TARGET_SCOPE.
pub fn system_attr_acp_target_scope()->AttributeRecord{
 AttributeRecord{
name: 15u16,
uuid: 281470681743385u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 101u8, 102u8, 102u8, 101u8, 99u8, 116u8, 105u8, 118u8, 101u8, 32u8, 116u8, 97u8, 114u8, 103u8, 101u8, 116u8, 115u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 65u8, 67u8, 80u8, 44u8, 32u8, 101u8, 46u8, 103u8, 46u8, 32u8, 119u8, 104u8, 97u8, 116u8, 32u8, 119u8, 105u8, 108u8, 108u8, 32u8, 98u8, 101u8, 32u8, 97u8, 99u8, 116u8, 101u8, 100u8, 32u8, 117u8, 112u8, 111u8, 110u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 7u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ACP_SEARCH_ATTR.
pub fn system_attr_acp_search_attr()->AttributeRecord{
 AttributeRecord{
name: 14u16,
uuid: 281470681743392u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 109u8, 97u8, 121u8, 32u8, 98u8, 101u8, 32u8, 118u8, 105u8, 101u8, 119u8, 101u8, 100u8, 32u8, 111u8, 114u8, 32u8, 115u8, 101u8, 97u8, 114u8, 99u8, 104u8, 101u8, 100u8, 32u8, 98u8, 121u8, 32u8, 116u8, 104u8, 101u8, 32u8, 114u8, 101u8, 99u8, 101u8, 105u8, 118u8, 101u8, 114u8, 32u8, 111u8, 110u8, 32u8, 116u8, 97u8, 114u8, 103u8, 101u8, 116u8, 115u8, 99u8, 111u8, 112u8, 101u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ACP_CREATE_CLASS.
pub fn system_attr_acp_create_class()->AttributeRecord{
 AttributeRecord{
name: 5u16,
uuid: 281470681743393u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 97u8, 110u8, 32u8, 98u8, 101u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 101u8, 100u8, 32u8, 111u8, 110u8, 32u8, 97u8, 32u8, 110u8, 101u8, 119u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ACP_CREATE_ATTR.
pub fn system_attr_acp_create_attr()->AttributeRecord{
 AttributeRecord{
name: 4u16,
uuid: 281470681743394u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 116u8, 121u8, 112u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 97u8, 110u8, 32u8, 98u8, 101u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 101u8, 100u8, 32u8, 111u8, 110u8, 32u8, 97u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ACP_MODIFY_REMOVED_ATTR.
pub fn system_attr_acp_modify_removed_attr()->AttributeRecord{
 AttributeRecord{
name: 11u16,
uuid: 281470681743395u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 116u8, 121u8, 112u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 111u8, 117u8, 108u8, 100u8, 32u8, 98u8, 101u8, 32u8, 114u8, 101u8, 109u8, 111u8, 118u8, 101u8, 100u8, 32u8, 111u8, 114u8, 32u8, 112u8, 117u8, 114u8, 103u8, 101u8, 100u8, 32u8, 105u8, 110u8, 32u8, 97u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ACP_MODIFY_PRESENT_ATTR.
pub fn system_attr_acp_modify_present_attr()->AttributeRecord{
 AttributeRecord{
name: 8u16,
uuid: 281470681743396u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 116u8, 121u8, 112u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 111u8, 117u8, 108u8, 100u8, 32u8, 98u8, 101u8, 32u8, 97u8, 100u8, 100u8, 101u8, 100u8, 32u8, 111u8, 114u8, 32u8, 97u8, 115u8, 115u8, 101u8, 114u8, 116u8, 101u8, 100u8, 32u8, 105u8, 110u8, 32u8, 97u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ACP_MODIFY_CLASS.
pub fn system_attr_acp_modify_class()->AttributeRecord{
 AttributeRecord{
name: 7u16,
uuid: 281470681743397u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 118u8, 97u8, 108u8, 117u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 111u8, 117u8, 108u8, 100u8, 32u8, 98u8, 101u8, 32u8, 97u8, 115u8, 115u8, 101u8, 114u8, 116u8, 101u8, 100u8, 32u8, 111u8, 114u8, 32u8, 97u8, 100u8, 100u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 97u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 46u8, 32u8, 79u8, 110u8, 108u8, 121u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 101u8, 115u8, 32u8, 116u8, 111u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 58u8, 58u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 32u8, 111u8, 112u8, 101u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 32u8, 111u8, 110u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ACP_MODIFY_PRESENT_CLASS.
pub fn system_attr_acp_modify_present_class()->AttributeRecord{
 AttributeRecord{
name: 9u16,
uuid: 281470681743753u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 118u8, 97u8, 108u8, 117u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 111u8, 117u8, 108u8, 100u8, 32u8, 98u8, 101u8, 32u8, 97u8, 115u8, 115u8, 101u8, 114u8, 116u8, 101u8, 100u8, 32u8, 111u8, 114u8, 32u8, 97u8, 100u8, 100u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 97u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 46u8, 32u8, 79u8, 110u8, 108u8, 121u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 101u8, 115u8, 32u8, 116u8, 111u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 58u8, 58u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 32u8, 111u8, 112u8, 101u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 32u8, 111u8, 110u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ACP_MODIFY_REMOVE_CLASS.
pub fn system_attr_acp_modify_remove_class()->AttributeRecord{
 AttributeRecord{
name: 10u16,
uuid: 281470681743760u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 118u8, 97u8, 108u8, 117u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 111u8, 117u8, 108u8, 100u8, 32u8, 98u8, 101u8, 32u8, 97u8, 115u8, 115u8, 101u8, 114u8, 116u8, 101u8, 100u8, 32u8, 111u8, 114u8, 32u8, 97u8, 100u8, 100u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 97u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 46u8, 32u8, 79u8, 110u8, 108u8, 121u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 101u8, 115u8, 32u8, 116u8, 111u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 58u8, 58u8, 114u8, 101u8, 109u8, 111u8, 118u8, 101u8, 32u8, 111u8, 112u8, 101u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 32u8, 111u8, 110u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ENTRY_MANAGED_BY.
pub fn system_attr_entry_managed_by()->AttributeRecord{
 AttributeRecord{
name: 58u16,
uuid: 281470681743702u128,
description: Vec::from([65u8, 32u8, 114u8, 101u8, 102u8, 101u8, 114u8, 101u8, 110u8, 99u8, 101u8, 32u8, 116u8, 111u8, 32u8, 97u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 104u8, 97u8, 115u8, 32u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 116u8, 111u8, 32u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 32u8, 116u8, 104u8, 101u8, 32u8, 99u8, 111u8, 110u8, 116u8, 101u8, 110u8, 116u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 6u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_MEMBER_OF.
pub fn system_attr_member_of()->AttributeRecord{
 AttributeRecord{
name: 96u16,
uuid: 281470681743378u128,
description: Vec::from([114u8, 101u8, 118u8, 101u8, 114u8, 115u8, 101u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 115u8, 104u8, 105u8, 112u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: false,
indexed: true,
syntax: 6u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_DIRECT_MEMBER_OF.
pub fn system_attr_direct_member_of()->AttributeRecord{
 AttributeRecord{
name: 38u16,
uuid: 281470681743380u128,
description: Vec::from([114u8, 101u8, 118u8, 101u8, 114u8, 115u8, 101u8, 32u8, 100u8, 105u8, 114u8, 101u8, 99u8, 116u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 115u8, 104u8, 105u8, 112u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: false,
indexed: true,
syntax: 6u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_RECYCLED_DIRECT_MEMBER_OF.
pub fn system_attr_recycled_direct_member_of()->AttributeRecord{
 AttributeRecord{
name: 142u16,
uuid: 281470681743712u128,
description: Vec::from([114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 32u8, 114u8, 101u8, 118u8, 101u8, 114u8, 115u8, 101u8, 32u8, 100u8, 105u8, 114u8, 101u8, 99u8, 116u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 115u8, 104u8, 105u8, 112u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 116u8, 111u8, 32u8, 97u8, 115u8, 115u8, 105u8, 115u8, 116u8, 32u8, 105u8, 110u8, 32u8, 114u8, 101u8, 118u8, 105u8, 118u8, 101u8, 32u8, 111u8, 112u8, 101u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 6u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_MEMBER.
pub fn system_attr_member()->AttributeRecord{
 AttributeRecord{
name: 95u16,
uuid: 281470681743379u128,
description: Vec::from([76u8, 105u8, 115u8, 116u8, 32u8, 111u8, 102u8, 32u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 115u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: true,
syntax: 6u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_DYN_MEMBER.
pub fn system_attr_dyn_member()->AttributeRecord{
 AttributeRecord{
name: 52u16,
uuid: 281470681743666u128,
description: Vec::from([76u8, 105u8, 115u8, 116u8, 32u8, 111u8, 102u8, 32u8, 100u8, 121u8, 110u8, 97u8, 109u8, 105u8, 99u8, 32u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 115u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: true,
replicated: false,
indexed: true,
syntax: 6u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_REFERS.
pub fn system_attr_refers()->AttributeRecord{
 AttributeRecord{
name: 143u16,
uuid: 281470681743735u128,
description: Vec::from([65u8, 32u8, 114u8, 101u8, 102u8, 101u8, 114u8, 101u8, 110u8, 99u8, 101u8, 32u8, 116u8, 111u8, 32u8, 97u8, 110u8, 111u8, 116u8, 104u8, 101u8, 114u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 6u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_CASCADE_DELETED.
pub fn system_attr_cascade_deleted()->AttributeRecord{
 AttributeRecord{
name: 26u16,
uuid: 281470681743764u128,
description: Vec::from([65u8, 32u8, 109u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 100u8, 101u8, 110u8, 111u8, 116u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 119u8, 97u8, 115u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 101u8, 100u8, 32u8, 98u8, 121u8, 32u8, 99u8, 97u8, 115u8, 99u8, 97u8, 100u8, 101u8, 32u8, 119u8, 104u8, 101u8, 110u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 85u8, 85u8, 73u8, 68u8, 32u8, 119u8, 97u8, 115u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 101u8, 100u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 2u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_VERSION.
pub fn system_attr_version()->AttributeRecord{
 AttributeRecord{
name: 176u16,
uuid: 281470681743381u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 115u8, 32u8, 105u8, 110u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 109u8, 105u8, 103u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 118u8, 101u8, 114u8, 115u8, 105u8, 111u8, 110u8, 32u8, 102u8, 111u8, 114u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 100u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 115u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 12u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_DOMAIN.
pub fn system_attr_domain()->AttributeRecord{
 AttributeRecord{
name: 41u16,
uuid: 281470681743382u128,
description: Vec::from([65u8, 32u8, 68u8, 78u8, 83u8, 32u8, 68u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 110u8, 97u8, 109u8, 101u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 14u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_CLAIM.
pub fn system_attr_claim()->AttributeRecord{
 AttributeRecord{
name: 28u16,
uuid: 281470681743461u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 116u8, 114u8, 105u8, 110u8, 103u8, 32u8, 105u8, 100u8, 101u8, 110u8, 116u8, 105u8, 102u8, 105u8, 101u8, 114u8, 32u8, 111u8, 102u8, 32u8, 97u8, 110u8, 32u8, 101u8, 120u8, 116u8, 114u8, 97u8, 99u8, 116u8, 101u8, 100u8, 32u8, 99u8, 108u8, 97u8, 105u8, 109u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 97u8, 110u8, 32u8, 98u8, 101u8, 32u8, 102u8, 105u8, 108u8, 116u8, 101u8, 114u8, 101u8, 100u8]),
multivalue: true,
unique: false,
phantom: true,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_SCOPE.
pub fn system_attr_scope()->AttributeRecord{
 AttributeRecord{
name: 147u16,
uuid: 281470681743621u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 116u8, 114u8, 105u8, 110u8, 103u8, 32u8, 105u8, 100u8, 101u8, 110u8, 116u8, 105u8, 102u8, 105u8, 101u8, 114u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 112u8, 101u8, 114u8, 109u8, 105u8, 115u8, 115u8, 105u8, 111u8, 110u8, 32u8, 115u8, 99u8, 111u8, 112u8, 101u8, 32u8, 105u8, 110u8, 32u8, 97u8, 32u8, 115u8, 101u8, 115u8, 115u8, 105u8, 111u8, 110u8]),
multivalue: true,
unique: false,
phantom: true,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_SYNC_EXTERNAL_ID.
pub fn system_attr_sync_external_id()->AttributeRecord{
 AttributeRecord{
name: 159u16,
uuid: 281470681743649u128,
description: Vec::from([65u8, 110u8, 32u8, 101u8, 120u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 115u8, 116u8, 114u8, 105u8, 110u8, 103u8, 32u8, 73u8, 68u8, 32u8, 111u8, 102u8, 32u8, 97u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 105u8, 109u8, 112u8, 111u8, 114u8, 116u8, 101u8, 100u8, 32u8, 102u8, 114u8, 111u8, 109u8, 32u8, 97u8, 32u8, 115u8, 121u8, 110u8, 99u8, 32u8, 97u8, 103u8, 114u8, 101u8, 101u8, 109u8, 101u8, 110u8, 116u8]),
multivalue: false,
unique: true,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_SYNC_PARENT_UUID.
pub fn system_attr_sync_parent_uuid()->AttributeRecord{
 AttributeRecord{
name: 160u16,
uuid: 281470681743650u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 85u8, 85u8, 73u8, 68u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 112u8, 97u8, 114u8, 101u8, 110u8, 116u8, 32u8, 115u8, 121u8, 110u8, 99u8, 32u8, 97u8, 103u8, 114u8, 101u8, 101u8, 109u8, 101u8, 110u8, 116u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 101u8, 100u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 6u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_SYNC_CLASS.
pub fn system_attr_sync_class()->AttributeRecord{
 AttributeRecord{
name: 156u16,
uuid: 281470681743652u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 101u8, 115u8, 32u8, 114u8, 101u8, 113u8, 117u8, 101u8, 115u8, 116u8, 101u8, 100u8, 32u8, 98u8, 121u8, 32u8, 116u8, 104u8, 101u8, 32u8, 115u8, 121u8, 110u8, 99u8, 32u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_PASSWORD_IMPORT.
pub fn system_attr_password_import()->AttributeRecord{
 AttributeRecord{
name: 135u16,
uuid: 281470681743462u128,
description: Vec::from([65u8, 110u8, 32u8, 105u8, 109u8, 112u8, 111u8, 114u8, 116u8, 101u8, 100u8, 32u8, 112u8, 97u8, 115u8, 115u8, 119u8, 111u8, 114u8, 100u8, 32u8, 104u8, 97u8, 115u8, 104u8, 32u8, 102u8, 114u8, 111u8, 109u8, 32u8, 97u8, 110u8, 32u8, 101u8, 120u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 46u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: true,
replicated: false,
indexed: false,
syntax: 0u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_UNIX_PASSWORD_IMPORT.
pub fn system_attr_unix_password_import()->AttributeRecord{
 AttributeRecord{
name: 173u16,
uuid: 281470681743703u128,
description: Vec::from([65u8, 110u8, 32u8, 105u8, 109u8, 112u8, 111u8, 114u8, 116u8, 101u8, 100u8, 32u8, 117u8, 110u8, 105u8, 120u8, 32u8, 112u8, 97u8, 115u8, 115u8, 119u8, 111u8, 114u8, 100u8, 32u8, 104u8, 97u8, 115u8, 104u8, 32u8, 102u8, 114u8, 111u8, 109u8, 32u8, 97u8, 110u8, 32u8, 101u8, 120u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 46u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: true,
replicated: false,
indexed: false,
syntax: 0u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_TOTP_IMPORT.
pub fn system_attr_totp_import()->AttributeRecord{
 AttributeRecord{
name: 168u16,
uuid: 281470681743656u128,
description: Vec::from([65u8, 110u8, 32u8, 105u8, 109u8, 112u8, 111u8, 114u8, 116u8, 101u8, 100u8, 32u8, 116u8, 111u8, 116u8, 112u8, 32u8, 115u8, 101u8, 99u8, 114u8, 101u8, 116u8, 32u8, 102u8, 114u8, 111u8, 109u8, 32u8, 97u8, 110u8, 32u8, 101u8, 120u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 46u8]),
multivalue: true,
unique: false,
phantom: true,
sync_allowed: true,
replicated: false,
indexed: false,
syntax: 30u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_DN.
pub fn system_attr_dn()->AttributeRecord{
 AttributeRecord{
name: 40u16,
uuid: 281470681743464u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 68u8, 78u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ENTRY_DN.
pub fn system_attr_entry_dn()->AttributeRecord{
 AttributeRecord{
name: 57u16,
uuid: 281470681743476u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 69u8, 110u8, 116u8, 114u8, 121u8, 68u8, 78u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_ENTRY_UUID.
pub fn system_attr_entry_uuid()->AttributeRecord{
 AttributeRecord{
name: 59u16,
uuid: 281470681743472u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 85u8, 85u8, 73u8, 68u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 2u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_OBJECT_CLASS.
pub fn system_attr_object_class()->AttributeRecord{
 AttributeRecord{
name: 132u16,
uuid: 281470681743473u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 67u8, 108u8, 97u8, 115u8, 115u8]),
multivalue: true,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_CN.
pub fn system_attr_cn()->AttributeRecord{
 AttributeRecord{
name: 31u16,
uuid: 281470681743495u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 67u8, 108u8, 97u8, 115u8, 115u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 14u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_LDAP_KEYS.
pub fn system_attr_ldap_keys()->AttributeRecord{
 AttributeRecord{
name: 84u16,
uuid: 281470681743479u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 107u8, 101u8, 121u8, 115u8, 32u8, 40u8, 115u8, 115u8, 104u8, 41u8]),
multivalue: true,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 10u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_LDAP_SSH_PUBLIC_KEYS.
pub fn system_attr_ldap_ssh_public_keys()->AttributeRecord{
 AttributeRecord{
name: 86u16,
uuid: 281470681743480u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 115u8, 115u8, 104u8, 80u8, 117u8, 98u8, 108u8, 105u8, 99u8, 75u8, 101u8, 121u8]),
multivalue: true,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 10u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_EMAIL.
pub fn system_attr_email()->AttributeRecord{
 AttributeRecord{
name: 53u16,
uuid: 281470681743477u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 101u8, 109u8, 97u8, 105u8, 108u8]),
multivalue: true,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 17u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_EMAIL_PRIMARY.
pub fn system_attr_email_primary()->AttributeRecord{
 AttributeRecord{
name: 55u16,
uuid: 281470681743654u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 112u8, 114u8, 105u8, 109u8, 97u8, 114u8, 121u8, 32u8, 101u8, 109u8, 97u8, 105u8, 108u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 17u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_EMAIL_ALTERNATIVE.
pub fn system_attr_email_alternative()->AttributeRecord{
 AttributeRecord{
name: 54u16,
uuid: 281470681743655u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 97u8, 108u8, 116u8, 101u8, 114u8, 110u8, 97u8, 116u8, 105u8, 118u8, 101u8, 32u8, 101u8, 109u8, 97u8, 105u8, 108u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 17u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_LDAP_EMAIL_ADDRESS.
pub fn system_attr_ldap_email_address()->AttributeRecord{
 AttributeRecord{
name: 83u16,
uuid: 281470681743478u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 101u8, 109u8, 97u8, 105u8, 108u8, 65u8, 100u8, 100u8, 114u8, 101u8, 115u8, 115u8]),
multivalue: true,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 17u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_GECOS.
pub fn system_attr_gecos()->AttributeRecord{
 AttributeRecord{
name: 63u16,
uuid: 281470681743697u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 103u8, 101u8, 99u8, 111u8, 115u8, 46u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 0u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_UID.
pub fn system_attr_uid()->AttributeRecord{
 AttributeRecord{
name: 169u16,
uuid: 281470681743696u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 117u8, 105u8, 100u8, 46u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 0u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_UID_NUMBER.
pub fn system_attr_uid_number()->AttributeRecord{
 AttributeRecord{
name: 170u16,
uuid: 281470681743481u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 117u8, 105u8, 100u8, 78u8, 117u8, 109u8, 98u8, 101u8, 114u8, 46u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 12u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_SUDO_HOST.
pub fn system_attr_sudo_host()->AttributeRecord{
 AttributeRecord{
name: 153u16,
uuid: 281470681743689u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 115u8, 117u8, 100u8, 111u8, 104u8, 111u8, 115u8, 116u8, 46u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 0u16,
}
}

/// Exact complete record for system/SCHEMA_ATTR_HOME_DIRECTORY.
pub fn system_attr_home_directory()->AttributeRecord{
 AttributeRecord{
name: 68u16,
uuid: 281470681743896u128,
description: Vec::from([65u8, 110u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 67u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 108u8, 101u8, 32u8, 104u8, 111u8, 109u8, 101u8, 68u8, 105u8, 114u8, 101u8, 99u8, 116u8, 111u8, 114u8, 121u8, 46u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: false,
replicated: false,
indexed: false,
syntax: 0u16,
}
}

/// Exact complete record for system/SCHEMA_CLASS_ATTRIBUTE_TYPE.
pub fn system_class_attribute_type()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 116u8, 121u8, 112u8, 101u8]),
uuid: 281470681743398u128,
description: Vec::from([68u8, 101u8, 102u8, 105u8, 110u8, 105u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 115u8, 99u8, 104u8, 101u8, 109u8, 97u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8]),
sync_allowed: false,
systemmay: Vec::from([144u16, 137u16, 155u16, 72u16, 73u16]),
may: Vec::from([]),
systemmust: Vec::from([29u16, 21u16, 98u16, 171u16, 163u16, 37u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([9u8, 0u8, 99u8, 108u8, 97u8, 115u8, 115u8, 116u8, 121u8, 112u8, 101u8]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_CLASS_TYPE.
pub fn system_class_class_type()->ClassRecord{
 ClassRecord{
name: Vec::from([99u8, 108u8, 97u8, 115u8, 115u8, 116u8, 121u8, 112u8, 101u8]),
uuid: 281470681743399u128,
description: Vec::from([68u8, 101u8, 102u8, 105u8, 110u8, 105u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 115u8, 99u8, 104u8, 101u8, 109u8, 97u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 116u8, 121u8, 112u8, 101u8]),
sync_allowed: false,
systemmay: Vec::from([155u16, 165u16, 94u16, 166u16, 99u16, 167u16, 154u16, 164u16, 61u16]),
may: Vec::from([]),
systemmust: Vec::from([29u16, 30u16, 37u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([13u8, 0u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 116u8, 121u8, 112u8, 101u8]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_OBJECT.
pub fn system_class_object()->ClassRecord{
 ClassRecord{
name: Vec::from([111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
uuid: 281470681743400u128,
description: Vec::from([65u8, 32u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 99u8, 114u8, 101u8, 97u8, 116u8, 101u8, 100u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 97u8, 108u8, 108u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 115u8, 32u8, 109u8, 117u8, 115u8, 116u8, 32u8, 99u8, 111u8, 110u8, 116u8, 97u8, 105u8, 110u8]),
sync_allowed: false,
systemmay: Vec::from([37u16, 58u16, 96u16, 38u16]),
may: Vec::from([]),
systemmust: Vec::from([29u16, 175u16, 81u16, 32u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_BUILTIN.
pub fn system_class_builtin()->ClassRecord{
 ClassRecord{
name: Vec::from([98u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8]),
uuid: 281470681743715u128,
description: Vec::from([65u8, 32u8, 109u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 100u8, 101u8, 110u8, 111u8, 116u8, 105u8, 110u8, 103u8, 32u8, 98u8, 117u8, 105u8, 108u8, 116u8, 105u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 105u8, 101u8, 115u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_MEMBER_OF.
pub fn system_class_member_of()->ClassRecord{
 ClassRecord{
name: Vec::from([109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8]),
uuid: 281470681743408u128,
description: Vec::from([67u8, 108u8, 97u8, 115u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 105u8, 115u8, 32u8, 100u8, 121u8, 110u8, 97u8, 109u8, 105u8, 99u8, 97u8, 108u8, 108u8, 121u8, 32u8, 97u8, 100u8, 100u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 99u8, 105u8, 112u8, 105u8, 101u8, 110u8, 116u8, 115u8, 32u8, 111u8, 102u8, 32u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 32u8, 111u8, 114u8, 32u8, 100u8, 105u8, 114u8, 101u8, 99u8, 116u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 111u8, 102u8, 46u8, 32u8, 84u8, 79u8, 32u8, 66u8, 69u8, 32u8, 82u8, 69u8, 77u8, 79u8, 86u8, 69u8, 68u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_EXTENSIBLE_OBJECT.
pub fn system_class_extensible_object()->ClassRecord{
 ClassRecord{
name: Vec::from([101u8, 120u8, 116u8, 101u8, 110u8, 115u8, 105u8, 98u8, 108u8, 101u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
uuid: 281470681743401u128,
description: Vec::from([65u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 116u8, 121u8, 112u8, 101u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 104u8, 97u8, 115u8, 32u8, 103u8, 114u8, 101u8, 101u8, 110u8, 32u8, 104u8, 97u8, 105u8, 114u8, 32u8, 97u8, 110u8, 100u8, 32u8, 116u8, 117u8, 114u8, 110u8, 115u8, 32u8, 111u8, 102u8, 102u8, 32u8, 97u8, 108u8, 108u8, 32u8, 114u8, 117u8, 108u8, 101u8, 115u8, 32u8, 46u8, 46u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_RECYCLED.
pub fn system_class_recycled()->ClassRecord{
 ClassRecord{
name: Vec::from([114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8]),
uuid: 281470681743409u128,
description: Vec::from([65u8, 110u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 104u8, 97u8, 115u8, 32u8, 98u8, 101u8, 101u8, 110u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 101u8, 100u8, 44u8, 32u8, 98u8, 117u8, 116u8, 32u8, 115u8, 116u8, 105u8, 108u8, 108u8, 32u8, 114u8, 101u8, 99u8, 111u8, 118u8, 101u8, 114u8, 97u8, 98u8, 108u8, 101u8, 32u8, 118u8, 105u8, 97u8, 32u8, 116u8, 104u8, 101u8, 32u8, 114u8, 101u8, 118u8, 105u8, 118u8, 101u8, 32u8, 111u8, 112u8, 101u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 46u8, 32u8, 82u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 115u8, 32u8, 97u8, 114u8, 101u8, 32u8, 110u8, 111u8, 116u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 105u8, 97u8, 98u8, 108u8, 101u8, 44u8, 32u8, 111u8, 110u8, 108u8, 121u8, 32u8, 114u8, 101u8, 118u8, 105u8, 118u8, 97u8, 98u8, 108u8, 101u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([142u16, 26u16]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_TOMBSTONE.
pub fn system_class_tombstone()->ClassRecord{
 ClassRecord{
name: Vec::from([116u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8]),
uuid: 281470681743410u128,
description: Vec::from([65u8, 110u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 105u8, 115u8, 32u8, 112u8, 117u8, 114u8, 103u8, 101u8, 100u8, 32u8, 102u8, 114u8, 111u8, 109u8, 32u8, 116u8, 104u8, 101u8, 32u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 32u8, 98u8, 105u8, 110u8, 46u8, 32u8, 84u8, 104u8, 105u8, 115u8, 32u8, 105u8, 115u8, 32u8, 97u8, 32u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 105u8, 110u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 115u8, 116u8, 97u8, 116u8, 101u8, 46u8, 32u8, 84u8, 111u8, 109u8, 98u8, 115u8, 116u8, 111u8, 110u8, 101u8, 115u8, 32u8, 104u8, 97u8, 118u8, 101u8, 32u8, 110u8, 111u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 32u8, 98u8, 101u8, 115u8, 105u8, 100u8, 101u8, 32u8, 85u8, 85u8, 73u8, 68u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([29u16, 175u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_CONFLICT.
pub fn system_class_conflict()->ClassRecord{
 ClassRecord{
name: Vec::from([99u8, 111u8, 110u8, 102u8, 108u8, 105u8, 99u8, 116u8]),
uuid: 281470681743673u128,
description: Vec::from([65u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 99u8, 111u8, 110u8, 102u8, 108u8, 105u8, 99u8, 116u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 111u8, 99u8, 99u8, 117u8, 114u8, 114u8, 101u8, 100u8, 32u8, 100u8, 117u8, 114u8, 105u8, 110u8, 103u8, 32u8, 114u8, 101u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([150u16]),
must: Vec::from([]),
systemsupplements: Vec::from([8u8, 0u8, 114u8, 101u8, 99u8, 121u8, 99u8, 108u8, 101u8, 100u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_SYSTEM_INFO.
pub fn system_class_system_info()->ClassRecord{
 ClassRecord{
name: Vec::from([115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 95u8, 105u8, 110u8, 102u8, 111u8]),
uuid: 281470681743411u128,
description: Vec::from([83u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 109u8, 101u8, 116u8, 97u8, 100u8, 97u8, 116u8, 97u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([176u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_ACCESS_CONTROL_SEARCH.
pub fn system_class_access_control_search()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 115u8, 101u8, 97u8, 114u8, 99u8, 104u8]),
uuid: 281470681743413u128,
description: Vec::from([83u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 65u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 83u8, 101u8, 97u8, 114u8, 99u8, 104u8, 32u8, 67u8, 108u8, 97u8, 115u8, 115u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([14u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_ACCESS_CONTROL_DELETE.
pub fn system_class_access_control_delete()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 100u8, 101u8, 108u8, 101u8, 116u8, 101u8]),
uuid: 281470681743414u128,
description: Vec::from([83u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 65u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 68u8, 69u8, 76u8, 69u8, 84u8, 69u8, 32u8, 67u8, 108u8, 97u8, 115u8, 115u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_ACCESS_CONTROL_MODIFY.
pub fn system_class_access_control_modify()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8]),
uuid: 281470681743415u128,
description: Vec::from([83u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 65u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 77u8, 111u8, 100u8, 105u8, 102u8, 121u8, 32u8, 67u8, 108u8, 97u8, 115u8, 115u8]),
sync_allowed: false,
systemmay: Vec::from([11u16, 8u16, 7u16, 9u16, 10u16]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_ACCESS_CONTROL_CREATE.
pub fn system_class_access_control_create()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 99u8, 114u8, 101u8, 97u8, 116u8, 101u8]),
uuid: 281470681743416u128,
description: Vec::from([83u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 65u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 67u8, 114u8, 101u8, 97u8, 116u8, 101u8, 32u8, 67u8, 108u8, 97u8, 115u8, 115u8]),
sync_allowed: false,
systemmay: Vec::from([5u16, 4u16]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_ACCESS_CONTROL_PROFILE.
pub fn system_class_access_control_profile()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 112u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8]),
uuid: 281470681743412u128,
description: Vec::from([83u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 65u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 80u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8, 32u8, 67u8, 108u8, 97u8, 115u8, 115u8]),
sync_allowed: false,
systemmay: Vec::from([6u16, 37u16]),
may: Vec::from([]),
systemmust: Vec::from([100u16]),
must: Vec::from([]),
systemsupplements: Vec::from([21u8, 0u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 115u8, 101u8, 97u8, 114u8, 99u8, 104u8, 21u8, 0u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 100u8, 101u8, 108u8, 101u8, 116u8, 101u8, 21u8, 0u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 109u8, 111u8, 100u8, 105u8, 102u8, 121u8, 21u8, 0u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 99u8, 114u8, 101u8, 97u8, 116u8, 101u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_ACCESS_CONTROL_RECEIVER_ENTRY_MANAGER.
pub fn system_class_access_control_receiver_entry_manager()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 114u8, 101u8, 99u8, 101u8, 105u8, 118u8, 101u8, 114u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]),
uuid: 281470681743700u128,
description: Vec::from([83u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 65u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 80u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8, 32u8, 82u8, 101u8, 99u8, 101u8, 105u8, 118u8, 101u8, 114u8, 32u8, 45u8, 32u8, 69u8, 110u8, 116u8, 114u8, 121u8, 32u8, 77u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([22u8, 0u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 112u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([29u8, 0u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 114u8, 101u8, 99u8, 101u8, 105u8, 118u8, 101u8, 114u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_ACCESS_CONTROL_RECEIVER_GROUP.
pub fn system_class_access_control_receiver_group()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 114u8, 101u8, 99u8, 101u8, 105u8, 118u8, 101u8, 114u8, 95u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
uuid: 281470681743699u128,
description: Vec::from([83u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 65u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 80u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8, 32u8, 82u8, 101u8, 99u8, 101u8, 105u8, 118u8, 101u8, 114u8, 32u8, 45u8, 32u8, 71u8, 114u8, 111u8, 117u8, 112u8]),
sync_allowed: false,
systemmay: Vec::from([12u16]),
may: Vec::from([]),
systemmust: Vec::from([13u16]),
must: Vec::from([]),
systemsupplements: Vec::from([22u8, 0u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 112u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([37u8, 0u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 114u8, 101u8, 99u8, 101u8, 105u8, 118u8, 101u8, 114u8, 95u8, 101u8, 110u8, 116u8, 114u8, 121u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_ACCESS_COUNTROL_TARGET_SCOPE.
pub fn system_class_access_countrol_target_scope()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 116u8, 97u8, 114u8, 103u8, 101u8, 116u8, 95u8, 115u8, 99u8, 111u8, 112u8, 101u8]),
uuid: 281470681743701u128,
description: Vec::from([83u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 65u8, 99u8, 99u8, 101u8, 115u8, 115u8, 32u8, 67u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 32u8, 80u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8, 32u8, 84u8, 97u8, 114u8, 103u8, 101u8, 116u8, 32u8, 45u8, 32u8, 83u8, 99u8, 111u8, 112u8, 101u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([15u16]),
must: Vec::from([]),
systemsupplements: Vec::from([22u8, 0u8, 97u8, 99u8, 99u8, 101u8, 115u8, 115u8, 95u8, 99u8, 111u8, 110u8, 116u8, 114u8, 111u8, 108u8, 95u8, 112u8, 114u8, 111u8, 102u8, 105u8, 108u8, 101u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_SYSTEM.
pub fn system_class_system()->ClassRecord{
 ClassRecord{
name: Vec::from([115u8, 121u8, 115u8, 116u8, 101u8, 109u8]),
uuid: 281470681743417u128,
description: Vec::from([65u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 100u8, 101u8, 110u8, 111u8, 116u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 97u8, 32u8, 116u8, 121u8, 112u8, 101u8, 32u8, 105u8, 115u8, 32u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 103u8, 101u8, 110u8, 101u8, 114u8, 97u8, 116u8, 101u8, 100u8, 32u8, 97u8, 110u8, 100u8, 32u8, 112u8, 114u8, 111u8, 116u8, 101u8, 99u8, 116u8, 101u8, 100u8, 46u8, 32u8, 73u8, 116u8, 32u8, 104u8, 97u8, 115u8, 32u8, 115u8, 112u8, 101u8, 99u8, 105u8, 97u8, 108u8, 32u8, 105u8, 110u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 98u8, 101u8, 104u8, 97u8, 118u8, 105u8, 111u8, 117u8, 114u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for system/SCHEMA_CLASS_SYNC_OBJECT.
pub fn system_class_sync_object()->ClassRecord{
 ClassRecord{
name: Vec::from([115u8, 121u8, 110u8, 99u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
uuid: 281470681743651u128,
description: Vec::from([65u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 100u8, 101u8, 110u8, 111u8, 116u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 97u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 105u8, 115u8, 32u8, 115u8, 121u8, 110u8, 99u8, 104u8, 114u8, 111u8, 110u8, 105u8, 115u8, 101u8, 100u8, 32u8, 102u8, 114u8, 111u8, 109u8, 32u8, 97u8, 110u8, 32u8, 101u8, 120u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 46u8, 32u8, 84u8, 104u8, 105u8, 115u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 109u8, 97u8, 121u8, 32u8, 110u8, 111u8, 116u8, 32u8, 98u8, 101u8, 32u8, 109u8, 111u8, 100u8, 105u8, 102u8, 105u8, 97u8, 98u8, 108u8, 101u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([159u16, 156u16]),
may: Vec::from([]),
systemmust: Vec::from([160u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_DISPLAYNAME_DL7, dl12/SCHEMA_ATTR_DISPLAYNAME_DL7, dl13/SCHEMA_ATTR_DISPLAYNAME_DL7, dl14/SCHEMA_ATTR_DISPLAYNAME_DL7, dl15/SCHEMA_ATTR_DISPLAYNAME_DL7, dl_1_12/SCHEMA_ATTR_DISPLAYNAME_DL7.
pub fn dl11_attr_displayname_dl7()->AttributeRecord{
 AttributeRecord{
name: 39u16,
uuid: 281470681743424u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 112u8, 117u8, 98u8, 108u8, 105u8, 99u8, 108u8, 121u8, 32u8, 118u8, 105u8, 115u8, 105u8, 98u8, 108u8, 101u8, 32u8, 100u8, 105u8, 115u8, 112u8, 108u8, 97u8, 121u8, 32u8, 110u8, 97u8, 109u8, 101u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: true,
syntax: 0u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_MAIL_DL7, dl12/SCHEMA_ATTR_MAIL_DL7, dl13/SCHEMA_ATTR_MAIL_DL7, dl14/SCHEMA_ATTR_MAIL_DL7, dl15/SCHEMA_ATTR_MAIL_DL7, dl_1_12/SCHEMA_ATTR_MAIL_DL7.
pub fn dl11_attr_mail_dl7()->AttributeRecord{
 AttributeRecord{
name: 92u16,
uuid: 281470681743425u128,
description: Vec::from([77u8, 97u8, 105u8, 108u8, 32u8, 97u8, 100u8, 100u8, 114u8, 101u8, 115u8, 115u8, 101u8, 115u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
multivalue: true,
unique: true,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: true,
syntax: 17u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_EC_KEY_PRIVATE, dl12/SCHEMA_ATTR_EC_KEY_PRIVATE.
pub fn dl11_attr_ec_key_private()->AttributeRecord{
 AttributeRecord{
name: 69u16,
uuid: 281470681743668u128,
description: Vec::from([65u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 118u8, 101u8, 114u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 112u8, 114u8, 105u8, 118u8, 97u8, 116u8, 101u8, 32u8, 107u8, 101u8, 121u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 9u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_SSH_PUBLICKEY, dl12/SCHEMA_ATTR_SSH_PUBLICKEY, dl13/SCHEMA_ATTR_SSH_PUBLICKEY, dl14/SCHEMA_ATTR_SSH_PUBLICKEY, dl15/SCHEMA_ATTR_SSH_PUBLICKEY, dl_1_12/SCHEMA_ATTR_SSH_PUBLICKEY.
pub fn dl11_attr_ssh_publickey()->AttributeRecord{
 AttributeRecord{
name: 152u16,
uuid: 281470681743426u128,
description: Vec::from([83u8, 83u8, 72u8, 32u8, 112u8, 117u8, 98u8, 108u8, 105u8, 99u8, 32u8, 107u8, 101u8, 121u8, 115u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: false,
syntax: 10u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_PRIMARY_CREDENTIAL, dl12/SCHEMA_ATTR_PRIMARY_CREDENTIAL, dl13/SCHEMA_ATTR_PRIMARY_CREDENTIAL, dl14/SCHEMA_ATTR_PRIMARY_CREDENTIAL, dl15/SCHEMA_ATTR_PRIMARY_CREDENTIAL, dl_1_12/SCHEMA_ATTR_PRIMARY_CREDENTIAL.
pub fn dl11_attr_primary_credential()->AttributeRecord{
 AttributeRecord{
name: 138u16,
uuid: 281470681743427u128,
description: Vec::from([80u8, 114u8, 105u8, 109u8, 97u8, 114u8, 121u8, 32u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 32u8, 109u8, 97u8, 116u8, 101u8, 114u8, 105u8, 97u8, 108u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 105u8, 110u8, 116u8, 101u8, 114u8, 97u8, 99u8, 116u8, 105u8, 118u8, 101u8, 108u8, 121u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: true,
syntax: 8u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_LEGALNAME_DL7, dl12/SCHEMA_ATTR_LEGALNAME_DL7, dl13/SCHEMA_ATTR_LEGALNAME_DL7, dl14/SCHEMA_ATTR_LEGALNAME_DL7, dl15/SCHEMA_ATTR_LEGALNAME_DL7, dl_1_12/SCHEMA_ATTR_LEGALNAME_DL7.
pub fn dl11_attr_legalname_dl7()->AttributeRecord{
 AttributeRecord{
name: 87u16,
uuid: 281470681743440u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 112u8, 114u8, 105u8, 118u8, 97u8, 116u8, 101u8, 32u8, 97u8, 110u8, 100u8, 32u8, 115u8, 101u8, 110u8, 115u8, 105u8, 116u8, 105u8, 118u8, 101u8, 32u8, 108u8, 101u8, 103u8, 97u8, 108u8, 32u8, 110u8, 97u8, 109u8, 101u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: true,
syntax: 0u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_NAME_HISTORY, dl12/SCHEMA_ATTR_NAME_HISTORY, dl13/SCHEMA_ATTR_NAME_HISTORY, dl14/SCHEMA_ATTR_NAME_HISTORY, dl15/SCHEMA_ATTR_NAME_HISTORY, dl_1_12/SCHEMA_ATTR_NAME_HISTORY.
pub fn dl11_attr_name_history()->AttributeRecord{
 AttributeRecord{
name: 101u16,
uuid: 281470681743667u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 104u8, 105u8, 115u8, 116u8, 111u8, 114u8, 121u8, 32u8, 111u8, 102u8, 32u8, 110u8, 97u8, 109u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 97u8, 32u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 32u8, 104u8, 97u8, 115u8, 32u8, 104u8, 97u8, 100u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: true,
syntax: 32u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_RADIUS_SECRET, dl12/SCHEMA_ATTR_RADIUS_SECRET, dl13/SCHEMA_ATTR_RADIUS_SECRET, dl14/SCHEMA_ATTR_RADIUS_SECRET, dl15/SCHEMA_ATTR_RADIUS_SECRET, dl_1_12/SCHEMA_ATTR_RADIUS_SECRET.
pub fn dl11_attr_radius_secret()->AttributeRecord{
 AttributeRecord{
name: 141u16,
uuid: 281470681743441u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 32u8, 103u8, 101u8, 110u8, 101u8, 114u8, 97u8, 116u8, 101u8, 100u8, 32u8, 114u8, 97u8, 100u8, 105u8, 117u8, 115u8, 32u8, 115u8, 101u8, 99u8, 114u8, 101u8, 116u8, 32u8, 102u8, 111u8, 114u8, 32u8, 100u8, 101u8, 118u8, 105u8, 99u8, 101u8, 32u8, 110u8, 101u8, 116u8, 119u8, 111u8, 114u8, 107u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: false,
syntax: 9u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_DOMAIN_NAME, dl12/SCHEMA_ATTR_DOMAIN_NAME, dl13/SCHEMA_ATTR_DOMAIN_NAME, dl14/SCHEMA_ATTR_DOMAIN_NAME, dl15/SCHEMA_ATTR_DOMAIN_NAME, dl_1_12/SCHEMA_ATTR_DOMAIN_NAME.
pub fn dl11_attr_domain_name()->AttributeRecord{
 AttributeRecord{
name: 47u16,
uuid: 281470681743443u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 39u8, 115u8, 32u8, 68u8, 78u8, 83u8, 32u8, 110u8, 97u8, 109u8, 101u8, 32u8, 102u8, 111u8, 114u8, 32u8, 119u8, 101u8, 98u8, 97u8, 117u8, 116u8, 104u8, 110u8, 32u8, 97u8, 110u8, 100u8, 32u8, 83u8, 80u8, 78u8, 32u8, 103u8, 101u8, 110u8, 101u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 112u8, 117u8, 114u8, 112u8, 111u8, 115u8, 101u8, 115u8]),
multivalue: false,
unique: true,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 14u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_LDAP_ALLOW_UNIX_PW_BIND, dl12/SCHEMA_ATTR_LDAP_ALLOW_UNIX_PW_BIND, dl13/SCHEMA_ATTR_LDAP_ALLOW_UNIX_PW_BIND, dl14/SCHEMA_ATTR_LDAP_ALLOW_UNIX_PW_BIND, dl15/SCHEMA_ATTR_LDAP_ALLOW_UNIX_PW_BIND, dl_1_12/SCHEMA_ATTR_LDAP_ALLOW_UNIX_PW_BIND.
pub fn dl11_attr_ldap_allow_unix_pw_bind()->AttributeRecord{
 AttributeRecord{
name: 82u16,
uuid: 281470681743685u128,
description: Vec::from([67u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 116u8, 111u8, 32u8, 101u8, 110u8, 97u8, 98u8, 108u8, 101u8, 32u8, 98u8, 105u8, 110u8, 100u8, 115u8, 32u8, 116u8, 111u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 115u8, 32u8, 117u8, 115u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 101u8, 105u8, 114u8, 32u8, 85u8, 78u8, 73u8, 88u8, 32u8, 112u8, 97u8, 115u8, 115u8, 119u8, 111u8, 114u8, 100u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_DOMAIN_LDAP_BASEDN, dl12/SCHEMA_ATTR_DOMAIN_LDAP_BASEDN, dl13/SCHEMA_ATTR_DOMAIN_LDAP_BASEDN, dl14/SCHEMA_ATTR_DOMAIN_LDAP_BASEDN, dl15/SCHEMA_ATTR_DOMAIN_LDAP_BASEDN, dl_1_12/SCHEMA_ATTR_DOMAIN_LDAP_BASEDN.
pub fn dl11_attr_domain_ldap_basedn()->AttributeRecord{
 AttributeRecord{
name: 46u16,
uuid: 281470681743665u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 39u8, 115u8, 32u8, 111u8, 112u8, 116u8, 105u8, 111u8, 110u8, 97u8, 108u8, 32u8, 108u8, 100u8, 97u8, 112u8, 32u8, 98u8, 97u8, 115u8, 101u8, 100u8, 110u8, 46u8, 32u8, 73u8, 102u8, 32u8, 117u8, 110u8, 115u8, 101u8, 116u8, 32u8, 100u8, 101u8, 102u8, 97u8, 117u8, 108u8, 116u8, 115u8, 32u8, 116u8, 111u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 99u8, 111u8, 109u8, 112u8, 111u8, 110u8, 101u8, 110u8, 116u8, 115u8, 32u8, 111u8, 102u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 110u8, 97u8, 109u8, 101u8]),
multivalue: false,
unique: true,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_LDAP_MAXIMUM_QUERYABLE_ATTRIBUTES, dl12/SCHEMA_ATTR_LDAP_MAXIMUM_QUERYABLE_ATTRIBUTES, dl13/SCHEMA_ATTR_LDAP_MAXIMUM_QUERYABLE_ATTRIBUTES, dl14/SCHEMA_ATTR_LDAP_MAXIMUM_QUERYABLE_ATTRIBUTES, dl15/SCHEMA_ATTR_LDAP_MAXIMUM_QUERYABLE_ATTRIBUTES, dl_1_12/SCHEMA_ATTR_LDAP_MAXIMUM_QUERYABLE_ATTRIBUTES.
pub fn dl11_attr_ldap_maximum_queryable_attributes()->AttributeRecord{
 AttributeRecord{
name: 85u16,
uuid: 281470681743751u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 109u8, 97u8, 120u8, 105u8, 109u8, 117u8, 109u8, 32u8, 110u8, 117u8, 109u8, 98u8, 101u8, 114u8, 32u8, 111u8, 102u8, 32u8, 76u8, 68u8, 65u8, 80u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 97u8, 110u8, 32u8, 98u8, 101u8, 32u8, 113u8, 117u8, 101u8, 114u8, 105u8, 101u8, 100u8, 32u8, 105u8, 110u8, 32u8, 111u8, 110u8, 101u8, 32u8, 111u8, 112u8, 101u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: false,
syntax: 12u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_IMAGE, dl12/SCHEMA_ATTR_IMAGE, dl13/SCHEMA_ATTR_IMAGE, dl14/SCHEMA_ATTR_IMAGE, dl15/SCHEMA_ATTR_IMAGE, dl_1_12/SCHEMA_ATTR_IMAGE.
pub fn dl11_attr_image()->AttributeRecord{
 AttributeRecord{
name: 70u16,
uuid: 281470681743683u128,
description: Vec::from([65u8, 110u8, 32u8, 105u8, 109u8, 97u8, 103u8, 101u8, 32u8, 102u8, 111u8, 114u8, 32u8, 100u8, 105u8, 115u8, 112u8, 108u8, 97u8, 121u8, 32u8, 116u8, 111u8, 32u8, 101u8, 110u8, 100u8, 32u8, 117u8, 115u8, 101u8, 114u8, 115u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 34u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_DOMAIN_DISPLAY_NAME, dl12/SCHEMA_ATTR_DOMAIN_DISPLAY_NAME, dl13/SCHEMA_ATTR_DOMAIN_DISPLAY_NAME, dl14/SCHEMA_ATTR_DOMAIN_DISPLAY_NAME, dl15/SCHEMA_ATTR_DOMAIN_DISPLAY_NAME, dl_1_12/SCHEMA_ATTR_DOMAIN_DISPLAY_NAME.
pub fn dl11_attr_domain_display_name()->AttributeRecord{
 AttributeRecord{
name: 45u16,
uuid: 281470681743512u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 117u8, 115u8, 101u8, 114u8, 45u8, 102u8, 97u8, 99u8, 105u8, 110u8, 103u8, 32u8, 100u8, 105u8, 115u8, 112u8, 108u8, 97u8, 121u8, 32u8, 110u8, 97u8, 109u8, 101u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 75u8, 97u8, 110u8, 105u8, 100u8, 109u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 0u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_DOMAIN_UUID, dl12/SCHEMA_ATTR_DOMAIN_UUID, dl13/SCHEMA_ATTR_DOMAIN_UUID, dl14/SCHEMA_ATTR_DOMAIN_UUID, dl15/SCHEMA_ATTR_DOMAIN_UUID, dl_1_12/SCHEMA_ATTR_DOMAIN_UUID.
pub fn dl11_attr_domain_uuid()->AttributeRecord{
 AttributeRecord{
name: 50u16,
uuid: 281470681743444u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 39u8, 115u8, 32u8, 117u8, 117u8, 105u8, 100u8, 44u8, 32u8, 117u8, 115u8, 101u8, 100u8, 32u8, 105u8, 110u8, 32u8, 67u8, 83u8, 78u8, 32u8, 97u8, 110u8, 100u8, 32u8, 116u8, 114u8, 117u8, 115u8, 116u8, 32u8, 114u8, 101u8, 108u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8, 104u8, 105u8, 112u8, 115u8]),
multivalue: false,
unique: true,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 2u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_DOMAIN_SSID, dl12/SCHEMA_ATTR_DOMAIN_SSID, dl13/SCHEMA_ATTR_DOMAIN_SSID, dl14/SCHEMA_ATTR_DOMAIN_SSID, dl15/SCHEMA_ATTR_DOMAIN_SSID, dl_1_12/SCHEMA_ATTR_DOMAIN_SSID.
pub fn dl11_attr_domain_ssid()->AttributeRecord{
 AttributeRecord{
name: 48u16,
uuid: 281470681743445u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 115u8, 32u8, 115u8, 105u8, 116u8, 101u8, 45u8, 119u8, 105u8, 100u8, 101u8, 32u8, 83u8, 83u8, 73u8, 68u8, 32u8, 102u8, 111u8, 114u8, 32u8, 100u8, 101u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 117u8, 116u8, 111u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 119u8, 105u8, 114u8, 101u8, 108u8, 101u8, 115u8, 115u8]),
multivalue: false,
unique: true,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 0u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_DENIED_NAME_DL10, dl12/SCHEMA_ATTR_DENIED_NAME_DL10, dl13/SCHEMA_ATTR_DENIED_NAME_DL10, dl14/SCHEMA_ATTR_DENIED_NAME_DL10, dl15/SCHEMA_ATTR_DENIED_NAME_DL10, dl_1_12/SCHEMA_ATTR_DENIED_NAME_DL10.
pub fn dl11_attr_denied_name_dl10()->AttributeRecord{
 AttributeRecord{
name: 36u16,
uuid: 281470681743684u128,
description: Vec::from([73u8, 110u8, 97u8, 109u8, 101u8, 32u8, 118u8, 97u8, 108u8, 117u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 97u8, 114u8, 101u8, 32u8, 110u8, 111u8, 116u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 98u8, 101u8, 32u8, 117u8, 115u8, 101u8, 100u8, 32u8, 105u8, 110u8, 32u8, 39u8, 110u8, 97u8, 109u8, 101u8, 39u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 14u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_DOMAIN_TOKEN_KEY, dl12/SCHEMA_ATTR_DOMAIN_TOKEN_KEY, dl13/SCHEMA_ATTR_DOMAIN_TOKEN_KEY, dl14/SCHEMA_ATTR_DOMAIN_TOKEN_KEY, dl15/SCHEMA_ATTR_DOMAIN_TOKEN_KEY, dl_1_12/SCHEMA_ATTR_DOMAIN_TOKEN_KEY.
pub fn dl11_attr_domain_token_key()->AttributeRecord{
 AttributeRecord{
name: 49u16,
uuid: 281470681743496u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 116u8, 111u8, 107u8, 101u8, 110u8, 32u8, 101u8, 110u8, 99u8, 114u8, 121u8, 112u8, 116u8, 105u8, 111u8, 110u8, 32u8, 112u8, 114u8, 105u8, 118u8, 97u8, 116u8, 101u8, 32u8, 107u8, 101u8, 121u8, 32u8, 40u8, 78u8, 79u8, 84u8, 32u8, 85u8, 83u8, 69u8, 68u8, 41u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 9u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_FERNET_PRIVATE_KEY_STR, dl12/SCHEMA_ATTR_FERNET_PRIVATE_KEY_STR, dl13/SCHEMA_ATTR_FERNET_PRIVATE_KEY_STR, dl14/SCHEMA_ATTR_FERNET_PRIVATE_KEY_STR, dl15/SCHEMA_ATTR_FERNET_PRIVATE_KEY_STR, dl_1_12/SCHEMA_ATTR_FERNET_PRIVATE_KEY_STR.
pub fn dl11_attr_fernet_private_key_str()->AttributeRecord{
 AttributeRecord{
name: 62u16,
uuid: 281470681743509u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 116u8, 111u8, 107u8, 101u8, 110u8, 32u8, 101u8, 110u8, 99u8, 114u8, 121u8, 112u8, 116u8, 105u8, 111u8, 110u8, 32u8, 112u8, 114u8, 105u8, 118u8, 97u8, 116u8, 101u8, 32u8, 107u8, 101u8, 121u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 9u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_GIDNUMBER, dl12/SCHEMA_ATTR_GIDNUMBER, dl13/SCHEMA_ATTR_GIDNUMBER, dl14/SCHEMA_ATTR_GIDNUMBER, dl15/SCHEMA_ATTR_GIDNUMBER, dl_1_12/SCHEMA_ATTR_GIDNUMBER.
pub fn dl11_attr_gidnumber()->AttributeRecord{
 AttributeRecord{
name: 64u16,
uuid: 281470681743446u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 105u8, 100u8, 32u8, 40u8, 117u8, 105u8, 100u8, 41u8, 32u8, 110u8, 117u8, 109u8, 98u8, 101u8, 114u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 111u8, 114u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 46u8, 116u8, 111u8, 95u8, 115u8, 116u8, 114u8, 105u8, 110u8, 103u8, 40u8, 41u8, 46u8, 32u8, 84u8, 104u8, 105u8, 115u8, 32u8, 105u8, 115u8, 32u8, 116u8, 104u8, 101u8, 32u8, 115u8, 97u8, 109u8, 101u8, 32u8, 118u8, 97u8, 108u8, 117u8, 101u8, 32u8, 97u8, 115u8, 32u8, 116u8, 104u8, 101u8, 32u8, 85u8, 73u8, 68u8, 32u8, 110u8, 117u8, 109u8, 98u8, 101u8, 114u8, 32u8, 111u8, 110u8, 32u8, 112u8, 111u8, 115u8, 105u8, 120u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 32u8, 102u8, 111u8, 114u8, 32u8, 115u8, 101u8, 99u8, 117u8, 114u8, 105u8, 116u8, 121u8, 32u8, 114u8, 101u8, 97u8, 115u8, 111u8, 110u8, 115u8]),
multivalue: false,
unique: true,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: true,
syntax: 12u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_BADLIST_PASSWORD, dl12/SCHEMA_ATTR_BADLIST_PASSWORD, dl13/SCHEMA_ATTR_BADLIST_PASSWORD, dl14/SCHEMA_ATTR_BADLIST_PASSWORD, dl15/SCHEMA_ATTR_BADLIST_PASSWORD, dl_1_12/SCHEMA_ATTR_BADLIST_PASSWORD.
pub fn dl11_attr_badlist_password()->AttributeRecord{
 AttributeRecord{
name: 25u16,
uuid: 281470681743449u128,
description: Vec::from([65u8, 32u8, 112u8, 97u8, 115u8, 115u8, 119u8, 111u8, 114u8, 100u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 105u8, 115u8, 32u8, 98u8, 97u8, 100u8, 108u8, 105u8, 115u8, 116u8, 101u8, 100u8, 32u8, 109u8, 101u8, 97u8, 110u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 105u8, 116u8, 32u8, 99u8, 97u8, 110u8, 32u8, 110u8, 111u8, 116u8, 32u8, 98u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 97u8, 115u8, 32u8, 97u8, 32u8, 118u8, 97u8, 108u8, 105u8, 100u8, 32u8, 112u8, 97u8, 115u8, 115u8, 119u8, 111u8, 114u8, 100u8, 32u8, 98u8, 121u8, 32u8, 97u8, 110u8, 121u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_AUTH_SESSION_EXPIRY, dl12/SCHEMA_ATTR_AUTH_SESSION_EXPIRY, dl13/SCHEMA_ATTR_AUTH_SESSION_EXPIRY, dl14/SCHEMA_ATTR_AUTH_SESSION_EXPIRY, dl15/SCHEMA_ATTR_AUTH_SESSION_EXPIRY, dl_1_12/SCHEMA_ATTR_AUTH_SESSION_EXPIRY.
pub fn dl11_attr_auth_session_expiry()->AttributeRecord{
 AttributeRecord{
name: 24u16,
uuid: 281470681743681u128,
description: Vec::from([65u8, 110u8, 32u8, 101u8, 120u8, 112u8, 105u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 116u8, 105u8, 109u8, 101u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 110u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 115u8, 101u8, 115u8, 115u8, 105u8, 111u8, 110u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 12u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_AUTH_PRIVILEGE_EXPIRY, dl12/SCHEMA_ATTR_AUTH_PRIVILEGE_EXPIRY, dl13/SCHEMA_ATTR_AUTH_PRIVILEGE_EXPIRY, dl14/SCHEMA_ATTR_AUTH_PRIVILEGE_EXPIRY, dl15/SCHEMA_ATTR_AUTH_PRIVILEGE_EXPIRY, dl_1_12/SCHEMA_ATTR_AUTH_PRIVILEGE_EXPIRY.
pub fn dl11_attr_auth_privilege_expiry()->AttributeRecord{
 AttributeRecord{
name: 140u16,
uuid: 281470681743682u128,
description: Vec::from([65u8, 110u8, 32u8, 101u8, 120u8, 112u8, 105u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 116u8, 105u8, 109u8, 101u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 32u8, 112u8, 114u8, 105u8, 118u8, 105u8, 108u8, 101u8, 103u8, 101u8, 100u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 115u8, 101u8, 115u8, 115u8, 105u8, 111u8, 110u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 12u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_AUTH_PASSWORD_MINIMUM_LENGTH, dl12/SCHEMA_ATTR_AUTH_PASSWORD_MINIMUM_LENGTH, dl13/SCHEMA_ATTR_AUTH_PASSWORD_MINIMUM_LENGTH, dl14/SCHEMA_ATTR_AUTH_PASSWORD_MINIMUM_LENGTH, dl15/SCHEMA_ATTR_AUTH_PASSWORD_MINIMUM_LENGTH, dl_1_12/SCHEMA_ATTR_AUTH_PASSWORD_MINIMUM_LENGTH.
pub fn dl11_attr_auth_password_minimum_length()->AttributeRecord{
 AttributeRecord{
name: 23u16,
uuid: 281470681743687u128,
description: Vec::from([77u8, 105u8, 110u8, 105u8, 109u8, 117u8, 109u8, 32u8, 108u8, 101u8, 110u8, 103u8, 116u8, 104u8, 32u8, 111u8, 102u8, 32u8, 112u8, 97u8, 115u8, 115u8, 119u8, 111u8, 114u8, 100u8, 115u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 12u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_LOGINSHELL, dl12/SCHEMA_ATTR_LOGINSHELL, dl13/SCHEMA_ATTR_LOGINSHELL, dl14/SCHEMA_ATTR_LOGINSHELL, dl15/SCHEMA_ATTR_LOGINSHELL, dl_1_12/SCHEMA_ATTR_LOGINSHELL.
pub fn dl11_attr_loginshell()->AttributeRecord{
 AttributeRecord{
name: 91u16,
uuid: 281470681743457u128,
description: Vec::from([65u8, 32u8, 80u8, 79u8, 83u8, 73u8, 88u8, 32u8, 117u8, 115u8, 101u8, 114u8, 39u8, 115u8, 32u8, 85u8, 78u8, 73u8, 88u8, 32u8, 108u8, 111u8, 103u8, 105u8, 110u8, 32u8, 115u8, 104u8, 101u8, 108u8, 108u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_UNIX_PASSWORD, dl12/SCHEMA_ATTR_UNIX_PASSWORD, dl13/SCHEMA_ATTR_UNIX_PASSWORD, dl14/SCHEMA_ATTR_UNIX_PASSWORD, dl15/SCHEMA_ATTR_UNIX_PASSWORD, dl_1_12/SCHEMA_ATTR_UNIX_PASSWORD.
pub fn dl11_attr_unix_password()->AttributeRecord{
 AttributeRecord{
name: 172u16,
uuid: 281470681743458u128,
description: Vec::from([65u8, 32u8, 80u8, 79u8, 83u8, 73u8, 88u8, 32u8, 117u8, 115u8, 101u8, 114u8, 39u8, 115u8, 32u8, 85u8, 78u8, 73u8, 88u8, 32u8, 108u8, 111u8, 103u8, 105u8, 110u8, 32u8, 112u8, 97u8, 115u8, 115u8, 119u8, 111u8, 114u8, 100u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 8u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_NSUNIQUEID, dl12/SCHEMA_ATTR_NSUNIQUEID, dl13/SCHEMA_ATTR_NSUNIQUEID, dl14/SCHEMA_ATTR_NSUNIQUEID, dl15/SCHEMA_ATTR_NSUNIQUEID, dl_1_12/SCHEMA_ATTR_NSUNIQUEID.
pub fn dl11_attr_nsuniqueid()->AttributeRecord{
 AttributeRecord{
name: 102u16,
uuid: 281470681743463u128,
description: Vec::from([65u8, 32u8, 117u8, 110u8, 105u8, 113u8, 117u8, 101u8, 32u8, 105u8, 100u8, 32u8, 99u8, 111u8, 109u8, 112u8, 97u8, 116u8, 105u8, 98u8, 105u8, 108u8, 105u8, 116u8, 121u8, 32u8, 102u8, 111u8, 114u8, 32u8, 51u8, 56u8, 57u8, 45u8, 100u8, 115u8, 47u8, 100u8, 115u8, 101u8, 101u8]),
multivalue: false,
unique: true,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: true,
syntax: 15u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_ACCOUNT_EXPIRE, dl12/SCHEMA_ATTR_ACCOUNT_EXPIRE, dl13/SCHEMA_ATTR_ACCOUNT_EXPIRE, dl14/SCHEMA_ATTR_ACCOUNT_EXPIRE, dl15/SCHEMA_ATTR_ACCOUNT_EXPIRE, dl_1_12/SCHEMA_ATTR_ACCOUNT_EXPIRE.
pub fn dl11_attr_account_expire()->AttributeRecord{
 AttributeRecord{
name: 1u16,
uuid: 281470681743474u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 97u8, 116u8, 101u8, 116u8, 105u8, 109u8, 101u8, 32u8, 97u8, 102u8, 116u8, 101u8, 114u8, 32u8, 119u8, 104u8, 105u8, 99u8, 104u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 110u8, 111u8, 32u8, 108u8, 111u8, 110u8, 103u8, 101u8, 114u8, 32u8, 109u8, 97u8, 121u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 101u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: false,
syntax: 16u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_ACCOUNT_VALID_FROM, dl12/SCHEMA_ATTR_ACCOUNT_VALID_FROM, dl13/SCHEMA_ATTR_ACCOUNT_VALID_FROM, dl14/SCHEMA_ATTR_ACCOUNT_VALID_FROM, dl15/SCHEMA_ATTR_ACCOUNT_VALID_FROM, dl_1_12/SCHEMA_ATTR_ACCOUNT_VALID_FROM.
pub fn dl11_attr_account_valid_from()->AttributeRecord{
 AttributeRecord{
name: 3u16,
uuid: 281470681743475u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 97u8, 116u8, 101u8, 116u8, 105u8, 109u8, 101u8, 32u8, 97u8, 102u8, 116u8, 101u8, 114u8, 32u8, 119u8, 104u8, 105u8, 99u8, 104u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 109u8, 97u8, 121u8, 32u8, 99u8, 111u8, 109u8, 109u8, 101u8, 110u8, 99u8, 101u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 110u8, 103u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: false,
syntax: 16u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_WEBAUTHN_ATTESTATION_CA_LIST, dl12/SCHEMA_ATTR_WEBAUTHN_ATTESTATION_CA_LIST, dl13/SCHEMA_ATTR_WEBAUTHN_ATTESTATION_CA_LIST, dl14/SCHEMA_ATTR_WEBAUTHN_ATTESTATION_CA_LIST, dl15/SCHEMA_ATTR_WEBAUTHN_ATTESTATION_CA_LIST, dl_1_12/SCHEMA_ATTR_WEBAUTHN_ATTESTATION_CA_LIST.
pub fn dl11_attr_webauthn_attestation_ca_list()->AttributeRecord{
 AttributeRecord{
name: 177u16,
uuid: 281470681743698u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 67u8, 65u8, 39u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 108u8, 105u8, 109u8, 105u8, 116u8, 32u8, 100u8, 101u8, 118u8, 105u8, 99u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 97u8, 110u8, 32u8, 98u8, 101u8, 32u8, 117u8, 115u8, 101u8, 100u8, 32u8, 119u8, 105u8, 116u8, 104u8, 32u8, 119u8, 101u8, 98u8, 97u8, 117u8, 116u8, 104u8, 110u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 36u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_RS_NAME, dl12/SCHEMA_ATTR_OAUTH2_RS_NAME, dl13/SCHEMA_ATTR_OAUTH2_RS_NAME, dl14/SCHEMA_ATTR_OAUTH2_RS_NAME, dl15/SCHEMA_ATTR_OAUTH2_RS_NAME, dl_1_12/SCHEMA_ATTR_OAUTH2_RS_NAME.
pub fn dl11_attr_oauth2_rs_name()->AttributeRecord{
 AttributeRecord{
name: 122u16,
uuid: 281470681743488u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 117u8, 110u8, 105u8, 113u8, 117u8, 101u8, 32u8, 110u8, 97u8, 109u8, 101u8, 32u8, 111u8, 102u8, 32u8, 97u8, 110u8, 32u8, 101u8, 120u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 79u8, 97u8, 117u8, 116u8, 104u8, 50u8, 32u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8]),
multivalue: false,
unique: true,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 14u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_RS_ORIGIN_DL7, dl12/SCHEMA_ATTR_OAUTH2_RS_ORIGIN_DL7, dl13/SCHEMA_ATTR_OAUTH2_RS_ORIGIN_DL7, dl14/SCHEMA_ATTR_OAUTH2_RS_ORIGIN_DL7, dl15/SCHEMA_ATTR_OAUTH2_RS_ORIGIN_DL7, dl_1_12/SCHEMA_ATTR_OAUTH2_RS_ORIGIN_DL7.
pub fn dl11_attr_oauth2_rs_origin_dl7()->AttributeRecord{
 AttributeRecord{
name: 123u16,
uuid: 281470681743489u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 111u8, 114u8, 105u8, 103u8, 105u8, 110u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 110u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 18u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_RS_ORIGIN_LANDING, dl12/SCHEMA_ATTR_OAUTH2_RS_ORIGIN_LANDING, dl13/SCHEMA_ATTR_OAUTH2_RS_ORIGIN_LANDING, dl14/SCHEMA_ATTR_OAUTH2_RS_ORIGIN_LANDING, dl15/SCHEMA_ATTR_OAUTH2_RS_ORIGIN_LANDING, dl_1_12/SCHEMA_ATTR_OAUTH2_RS_ORIGIN_LANDING.
pub fn dl11_attr_oauth2_rs_origin_landing()->AttributeRecord{
 AttributeRecord{
name: 124u16,
uuid: 281470681743648u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 108u8, 97u8, 110u8, 100u8, 105u8, 110u8, 103u8, 32u8, 112u8, 97u8, 103u8, 101u8, 32u8, 111u8, 102u8, 32u8, 97u8, 110u8, 32u8, 82u8, 83u8, 44u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 119u8, 105u8, 108u8, 108u8, 32u8, 97u8, 117u8, 116u8, 111u8, 109u8, 97u8, 116u8, 105u8, 99u8, 97u8, 108u8, 108u8, 121u8, 32u8, 116u8, 114u8, 105u8, 103u8, 103u8, 101u8, 114u8, 32u8, 116u8, 104u8, 101u8, 32u8, 97u8, 117u8, 116u8, 104u8, 32u8, 112u8, 114u8, 111u8, 99u8, 101u8, 115u8, 115u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 18u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_ALLOW_LOCALHOST_REDIRECT_DL4, dl12/SCHEMA_ATTR_OAUTH2_ALLOW_LOCALHOST_REDIRECT_DL4, dl13/SCHEMA_ATTR_OAUTH2_ALLOW_LOCALHOST_REDIRECT_DL4, dl14/SCHEMA_ATTR_OAUTH2_ALLOW_LOCALHOST_REDIRECT_DL4, dl15/SCHEMA_ATTR_OAUTH2_ALLOW_LOCALHOST_REDIRECT_DL4, dl_1_12/SCHEMA_ATTR_OAUTH2_ALLOW_LOCALHOST_REDIRECT_DL4.
pub fn dl11_attr_oauth2_allow_localhost_redirect_dl4()->AttributeRecord{
 AttributeRecord{
name: 108u16,
uuid: 281470681743704u128,
description: Vec::from([65u8, 108u8, 108u8, 111u8, 119u8, 32u8, 112u8, 117u8, 98u8, 108u8, 105u8, 99u8, 32u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 115u8, 32u8, 97u8, 115u8, 115u8, 111u8, 99u8, 105u8, 97u8, 116u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 82u8, 83u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 100u8, 105u8, 114u8, 101u8, 99u8, 116u8, 32u8, 116u8, 111u8, 32u8, 108u8, 111u8, 99u8, 97u8, 108u8, 104u8, 111u8, 115u8, 116u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_RS_CLAIM_MAP_DL4, dl12/SCHEMA_ATTR_OAUTH2_RS_CLAIM_MAP_DL4, dl13/SCHEMA_ATTR_OAUTH2_RS_CLAIM_MAP_DL4, dl14/SCHEMA_ATTR_OAUTH2_RS_CLAIM_MAP_DL4, dl15/SCHEMA_ATTR_OAUTH2_RS_CLAIM_MAP_DL4, dl_1_12/SCHEMA_ATTR_OAUTH2_RS_CLAIM_MAP_DL4.
pub fn dl11_attr_oauth2_rs_claim_map_dl4()->AttributeRecord{
 AttributeRecord{
name: 120u16,
uuid: 281470681743705u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 99u8, 117u8, 115u8, 116u8, 111u8, 109u8, 32u8, 99u8, 108u8, 97u8, 105u8, 109u8, 115u8, 32u8, 109u8, 97u8, 112u8, 112u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 115u8, 104u8, 105u8, 112u8, 115u8, 32u8, 111u8, 102u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 37u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_RS_SCOPE_MAP, dl12/SCHEMA_ATTR_OAUTH2_RS_SCOPE_MAP, dl13/SCHEMA_ATTR_OAUTH2_RS_SCOPE_MAP, dl14/SCHEMA_ATTR_OAUTH2_RS_SCOPE_MAP, dl15/SCHEMA_ATTR_OAUTH2_RS_SCOPE_MAP, dl_1_12/SCHEMA_ATTR_OAUTH2_RS_SCOPE_MAP.
pub fn dl11_attr_oauth2_rs_scope_map()->AttributeRecord{
 AttributeRecord{
name: 125u16,
uuid: 281470681743490u128,
description: Vec::from([65u8, 32u8, 114u8, 101u8, 102u8, 101u8, 114u8, 101u8, 110u8, 99u8, 101u8, 32u8, 116u8, 111u8, 32u8, 97u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 109u8, 97u8, 112u8, 112u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 115u8, 99u8, 111u8, 112u8, 101u8, 115u8, 32u8, 102u8, 111u8, 114u8, 32u8, 116u8, 104u8, 101u8, 32u8, 97u8, 115u8, 115u8, 111u8, 99u8, 105u8, 97u8, 116u8, 101u8, 100u8, 32u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 32u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 20u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_RS_SUP_SCOPE_MAP, dl12/SCHEMA_ATTR_OAUTH2_RS_SUP_SCOPE_MAP, dl13/SCHEMA_ATTR_OAUTH2_RS_SUP_SCOPE_MAP, dl14/SCHEMA_ATTR_OAUTH2_RS_SUP_SCOPE_MAP, dl15/SCHEMA_ATTR_OAUTH2_RS_SUP_SCOPE_MAP, dl_1_12/SCHEMA_ATTR_OAUTH2_RS_SUP_SCOPE_MAP.
pub fn dl11_attr_oauth2_rs_sup_scope_map()->AttributeRecord{
 AttributeRecord{
name: 126u16,
uuid: 281470681743634u128,
description: Vec::from([65u8, 32u8, 114u8, 101u8, 102u8, 101u8, 114u8, 101u8, 110u8, 99u8, 101u8, 32u8, 116u8, 111u8, 32u8, 97u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 109u8, 97u8, 112u8, 112u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 115u8, 99u8, 111u8, 112u8, 101u8, 115u8, 32u8, 102u8, 111u8, 114u8, 32u8, 116u8, 104u8, 101u8, 32u8, 97u8, 115u8, 115u8, 111u8, 99u8, 105u8, 97u8, 116u8, 101u8, 100u8, 32u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 32u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 20u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_RS_BASIC_SECRET, dl12/SCHEMA_ATTR_OAUTH2_RS_BASIC_SECRET, dl13/SCHEMA_ATTR_OAUTH2_RS_BASIC_SECRET, dl14/SCHEMA_ATTR_OAUTH2_RS_BASIC_SECRET, dl15/SCHEMA_ATTR_OAUTH2_RS_BASIC_SECRET, dl_1_12/SCHEMA_ATTR_OAUTH2_RS_BASIC_SECRET.
pub fn dl11_attr_oauth2_rs_basic_secret()->AttributeRecord{
 AttributeRecord{
name: 119u16,
uuid: 281470681743491u128,
description: Vec::from([87u8, 104u8, 101u8, 110u8, 32u8, 117u8, 115u8, 105u8, 110u8, 103u8, 32u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 32u8, 98u8, 97u8, 115u8, 105u8, 99u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 44u8, 32u8, 116u8, 104u8, 101u8, 32u8, 115u8, 101u8, 99u8, 114u8, 101u8, 116u8, 32u8, 115u8, 116u8, 114u8, 105u8, 110u8, 103u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 9u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_RS_TOKEN_KEY, dl12/SCHEMA_ATTR_OAUTH2_RS_TOKEN_KEY, dl13/SCHEMA_ATTR_OAUTH2_RS_TOKEN_KEY, dl14/SCHEMA_ATTR_OAUTH2_RS_TOKEN_KEY, dl15/SCHEMA_ATTR_OAUTH2_RS_TOKEN_KEY, dl_1_12/SCHEMA_ATTR_OAUTH2_RS_TOKEN_KEY.
pub fn dl11_attr_oauth2_rs_token_key()->AttributeRecord{
 AttributeRecord{
name: 127u16,
uuid: 281470681743492u128,
description: Vec::from([65u8, 110u8, 32u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 32u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 115u8, 32u8, 117u8, 110u8, 105u8, 113u8, 117u8, 101u8, 32u8, 116u8, 111u8, 107u8, 101u8, 110u8, 32u8, 115u8, 105u8, 103u8, 110u8, 105u8, 110u8, 103u8, 32u8, 107u8, 101u8, 121u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 9u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_RS_IMPLICIT_SCOPES, dl12/SCHEMA_ATTR_OAUTH2_RS_IMPLICIT_SCOPES, dl13/SCHEMA_ATTR_OAUTH2_RS_IMPLICIT_SCOPES, dl14/SCHEMA_ATTR_OAUTH2_RS_IMPLICIT_SCOPES, dl15/SCHEMA_ATTR_OAUTH2_RS_IMPLICIT_SCOPES, dl_1_12/SCHEMA_ATTR_OAUTH2_RS_IMPLICIT_SCOPES.
pub fn dl11_attr_oauth2_rs_implicit_scopes()->AttributeRecord{
 AttributeRecord{
name: 121u16,
uuid: 281470681743497u128,
description: Vec::from([65u8, 110u8, 32u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 32u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 115u8, 32u8, 115u8, 99u8, 111u8, 112u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 97u8, 114u8, 101u8, 32u8, 105u8, 109u8, 112u8, 108u8, 105u8, 99u8, 105u8, 116u8, 108u8, 121u8, 32u8, 103u8, 114u8, 97u8, 110u8, 116u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 97u8, 108u8, 108u8, 32u8, 117u8, 115u8, 101u8, 114u8, 115u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 19u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_CONSENT_SCOPE_MAP, dl12/SCHEMA_ATTR_OAUTH2_CONSENT_SCOPE_MAP, dl13/SCHEMA_ATTR_OAUTH2_CONSENT_SCOPE_MAP, dl14/SCHEMA_ATTR_OAUTH2_CONSENT_SCOPE_MAP, dl15/SCHEMA_ATTR_OAUTH2_CONSENT_SCOPE_MAP, dl_1_12/SCHEMA_ATTR_OAUTH2_CONSENT_SCOPE_MAP.
pub fn dl11_attr_oauth2_consent_scope_map()->AttributeRecord{
 AttributeRecord{
name: 113u16,
uuid: 281470681743511u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 115u8, 99u8, 111u8, 112u8, 101u8, 115u8, 32u8, 109u8, 97u8, 112u8, 112u8, 101u8, 100u8, 32u8, 102u8, 114u8, 111u8, 109u8, 32u8, 97u8, 32u8, 114u8, 101u8, 108u8, 121u8, 105u8, 110u8, 103u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 32u8, 116u8, 111u8, 32u8, 97u8, 32u8, 117u8, 115u8, 101u8, 114u8, 44u8, 32u8, 119u8, 104u8, 101u8, 114u8, 101u8, 32u8, 116u8, 104u8, 101u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 104u8, 97u8, 115u8, 32u8, 112u8, 114u8, 101u8, 118u8, 105u8, 111u8, 117u8, 115u8, 108u8, 121u8, 32u8, 99u8, 111u8, 110u8, 115u8, 101u8, 110u8, 116u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 116u8, 104u8, 101u8, 32u8, 102u8, 111u8, 108u8, 108u8, 111u8, 119u8, 105u8, 110u8, 103u8, 46u8, 32u8, 73u8, 102u8, 32u8, 99u8, 104u8, 97u8, 110u8, 103u8, 101u8, 100u8, 32u8, 111u8, 114u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 101u8, 100u8, 44u8, 32u8, 99u8, 111u8, 110u8, 115u8, 101u8, 110u8, 116u8, 32u8, 119u8, 105u8, 108u8, 108u8, 32u8, 98u8, 101u8, 32u8, 114u8, 101u8, 45u8, 115u8, 111u8, 117u8, 103u8, 104u8, 116u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 20u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_STRICT_REDIRECT_URI_DL7, dl12/SCHEMA_ATTR_OAUTH2_STRICT_REDIRECT_URI_DL7, dl13/SCHEMA_ATTR_OAUTH2_STRICT_REDIRECT_URI_DL7, dl14/SCHEMA_ATTR_OAUTH2_STRICT_REDIRECT_URI_DL7, dl15/SCHEMA_ATTR_OAUTH2_STRICT_REDIRECT_URI_DL7, dl_1_12/SCHEMA_ATTR_OAUTH2_STRICT_REDIRECT_URI_DL7.
pub fn dl11_attr_oauth2_strict_redirect_uri_dl7()->AttributeRecord{
 AttributeRecord{
name: 129u16,
uuid: 281470681743744u128,
description: Vec::from([82u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 115u8, 32u8, 105u8, 102u8, 32u8, 115u8, 116u8, 114u8, 105u8, 99u8, 116u8, 32u8, 114u8, 101u8, 100u8, 105u8, 114u8, 101u8, 99u8, 116u8, 32u8, 117u8, 114u8, 105u8, 32u8, 101u8, 110u8, 102u8, 111u8, 114u8, 99u8, 101u8, 109u8, 101u8, 110u8, 116u8, 32u8, 105u8, 115u8, 32u8, 101u8, 110u8, 97u8, 98u8, 108u8, 101u8, 100u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_DEVICE_FLOW_ENABLE_DL9.
pub fn dl11_attr_oauth2_device_flow_enable_dl9()->AttributeRecord{
 AttributeRecord{
name: 114u16,
uuid: 281474959933557u128,
description: Vec::from([82u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 115u8, 32u8, 105u8, 102u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 68u8, 101u8, 118u8, 105u8, 99u8, 101u8, 32u8, 70u8, 108u8, 111u8, 119u8, 32u8, 105u8, 115u8, 32u8, 112u8, 101u8, 114u8, 109u8, 105u8, 116u8, 116u8, 101u8, 100u8, 194u8, 160u8, 111u8, 110u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_ES256_PRIVATE_KEY_DER, dl12/SCHEMA_ATTR_ES256_PRIVATE_KEY_DER, dl13/SCHEMA_ATTR_ES256_PRIVATE_KEY_DER, dl14/SCHEMA_ATTR_ES256_PRIVATE_KEY_DER, dl15/SCHEMA_ATTR_ES256_PRIVATE_KEY_DER, dl_1_12/SCHEMA_ATTR_ES256_PRIVATE_KEY_DER.
pub fn dl11_attr_es256_private_key_der()->AttributeRecord{
 AttributeRecord{
name: 60u16,
uuid: 281470681743504u128,
description: Vec::from([65u8, 110u8, 32u8, 101u8, 115u8, 50u8, 53u8, 54u8, 32u8, 112u8, 114u8, 105u8, 118u8, 97u8, 116u8, 101u8, 32u8, 107u8, 101u8, 121u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 21u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_RS256_PRIVATE_KEY_DER, dl12/SCHEMA_ATTR_RS256_PRIVATE_KEY_DER, dl13/SCHEMA_ATTR_RS256_PRIVATE_KEY_DER, dl14/SCHEMA_ATTR_RS256_PRIVATE_KEY_DER, dl15/SCHEMA_ATTR_RS256_PRIVATE_KEY_DER, dl_1_12/SCHEMA_ATTR_RS256_PRIVATE_KEY_DER.
pub fn dl11_attr_rs256_private_key_der()->AttributeRecord{
 AttributeRecord{
name: 145u16,
uuid: 281470681743507u128,
description: Vec::from([65u8, 110u8, 32u8, 114u8, 115u8, 50u8, 53u8, 54u8, 32u8, 112u8, 114u8, 105u8, 118u8, 97u8, 116u8, 101u8, 32u8, 107u8, 101u8, 121u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 21u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_JWS_ES256_PRIVATE_KEY, dl12/SCHEMA_ATTR_JWS_ES256_PRIVATE_KEY, dl13/SCHEMA_ATTR_JWS_ES256_PRIVATE_KEY, dl14/SCHEMA_ATTR_JWS_ES256_PRIVATE_KEY, dl15/SCHEMA_ATTR_JWS_ES256_PRIVATE_KEY, dl_1_12/SCHEMA_ATTR_JWS_ES256_PRIVATE_KEY.
pub fn dl11_attr_jws_es256_private_key()->AttributeRecord{
 AttributeRecord{
name: 74u16,
uuid: 281470681743632u128,
description: Vec::from([65u8, 110u8, 32u8, 101u8, 115u8, 50u8, 53u8, 54u8, 32u8, 112u8, 114u8, 105u8, 118u8, 97u8, 116u8, 101u8, 32u8, 107u8, 101u8, 121u8, 32u8, 102u8, 111u8, 114u8, 32u8, 106u8, 119u8, 115u8]),
multivalue: false,
unique: true,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 26u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_PRIVATE_COOKIE_KEY, dl12/SCHEMA_ATTR_PRIVATE_COOKIE_KEY, dl13/SCHEMA_ATTR_PRIVATE_COOKIE_KEY, dl14/SCHEMA_ATTR_PRIVATE_COOKIE_KEY, dl15/SCHEMA_ATTR_PRIVATE_COOKIE_KEY, dl_1_12/SCHEMA_ATTR_PRIVATE_COOKIE_KEY.
pub fn dl11_attr_private_cookie_key()->AttributeRecord{
 AttributeRecord{
name: 139u16,
uuid: 281470681743664u128,
description: Vec::from([65u8, 110u8, 32u8, 112u8, 114u8, 105u8, 118u8, 97u8, 116u8, 101u8, 32u8, 99u8, 111u8, 111u8, 107u8, 105u8, 101u8, 32u8, 104u8, 109u8, 97u8, 99u8, 32u8, 107u8, 101u8, 121u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 21u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_ALLOW_INSECURE_CLIENT_DISABLE_PKCE, dl12/SCHEMA_ATTR_OAUTH2_ALLOW_INSECURE_CLIENT_DISABLE_PKCE, dl13/SCHEMA_ATTR_OAUTH2_ALLOW_INSECURE_CLIENT_DISABLE_PKCE, dl14/SCHEMA_ATTR_OAUTH2_ALLOW_INSECURE_CLIENT_DISABLE_PKCE, dl15/SCHEMA_ATTR_OAUTH2_ALLOW_INSECURE_CLIENT_DISABLE_PKCE, dl_1_12/SCHEMA_ATTR_OAUTH2_ALLOW_INSECURE_CLIENT_DISABLE_PKCE.
pub fn dl11_attr_oauth2_allow_insecure_client_disable_pkce()->AttributeRecord{
 AttributeRecord{
name: 107u16,
uuid: 281470681743505u128,
description: Vec::from([65u8, 108u8, 108u8, 111u8, 119u8, 115u8, 32u8, 100u8, 105u8, 115u8, 97u8, 98u8, 108u8, 105u8, 110u8, 103u8, 32u8, 111u8, 102u8, 32u8, 80u8, 75u8, 67u8, 69u8, 32u8, 102u8, 111u8, 114u8, 32u8, 105u8, 110u8, 115u8, 101u8, 99u8, 117u8, 114u8, 101u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 115u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_JWT_LEGACY_CRYPTO_ENABLE.
pub fn dl11_attr_oauth2_jwt_legacy_crypto_enable()->AttributeRecord{
 AttributeRecord{
name: 115u16,
uuid: 281470681743506u128,
description: Vec::from([65u8, 108u8, 108u8, 111u8, 119u8, 115u8, 32u8, 101u8, 110u8, 97u8, 98u8, 108u8, 105u8, 110u8, 103u8, 32u8, 108u8, 101u8, 103u8, 97u8, 99u8, 121u8, 32u8, 74u8, 87u8, 84u8, 32u8, 99u8, 114u8, 121u8, 112u8, 116u8, 111u8, 103u8, 114u8, 97u8, 112u8, 104u8, 121u8, 32u8, 102u8, 111u8, 114u8, 32u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 115u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_CREDENTIAL_UPDATE_INTENT_TOKEN, dl12/SCHEMA_ATTR_CREDENTIAL_UPDATE_INTENT_TOKEN, dl13/SCHEMA_ATTR_CREDENTIAL_UPDATE_INTENT_TOKEN, dl14/SCHEMA_ATTR_CREDENTIAL_UPDATE_INTENT_TOKEN, dl15/SCHEMA_ATTR_CREDENTIAL_UPDATE_INTENT_TOKEN, dl_1_12/SCHEMA_ATTR_CREDENTIAL_UPDATE_INTENT_TOKEN.
pub fn dl11_attr_credential_update_intent_token()->AttributeRecord{
 AttributeRecord{
name: 34u16,
uuid: 281470681743510u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 116u8, 97u8, 116u8, 117u8, 115u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 32u8, 117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 32u8, 105u8, 110u8, 116u8, 101u8, 110u8, 116u8, 32u8, 116u8, 111u8, 107u8, 101u8, 110u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 22u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_PASSKEYS, dl12/SCHEMA_ATTR_PASSKEYS, dl13/SCHEMA_ATTR_PASSKEYS, dl14/SCHEMA_ATTR_PASSKEYS, dl15/SCHEMA_ATTR_PASSKEYS, dl_1_12/SCHEMA_ATTR_PASSKEYS.
pub fn dl11_attr_passkeys()->AttributeRecord{
 AttributeRecord{
name: 133u16,
uuid: 281470681743513u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 114u8, 101u8, 103u8, 105u8, 115u8, 116u8, 101u8, 114u8, 101u8, 100u8, 32u8, 112u8, 97u8, 115u8, 115u8, 107u8, 101u8, 121u8, 115u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: true,
syntax: 20u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_ATTESTED_PASSKEYS, dl12/SCHEMA_ATTR_ATTESTED_PASSKEYS, dl13/SCHEMA_ATTR_ATTESTED_PASSKEYS, dl14/SCHEMA_ATTR_ATTESTED_PASSKEYS, dl15/SCHEMA_ATTR_ATTESTED_PASSKEYS, dl_1_12/SCHEMA_ATTR_ATTESTED_PASSKEYS.
pub fn dl11_attr_attested_passkeys()->AttributeRecord{
 AttributeRecord{
name: 20u16,
uuid: 281470681743616u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 114u8, 101u8, 103u8, 105u8, 115u8, 116u8, 101u8, 114u8, 101u8, 100u8, 32u8, 100u8, 101u8, 118u8, 105u8, 99u8, 101u8, 32u8, 107u8, 101u8, 121u8, 115u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: true,
syntax: 30u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_DYNGROUP_FILTER, dl12/SCHEMA_ATTR_DYNGROUP_FILTER, dl13/SCHEMA_ATTR_DYNGROUP_FILTER, dl14/SCHEMA_ATTR_DYNGROUP_FILTER, dl15/SCHEMA_ATTR_DYNGROUP_FILTER, dl_1_12/SCHEMA_ATTR_DYNGROUP_FILTER.
pub fn dl11_attr_dyngroup_filter()->AttributeRecord{
 AttributeRecord{
name: 51u16,
uuid: 281470681743624u128,
description: Vec::from([65u8, 32u8, 102u8, 105u8, 108u8, 116u8, 101u8, 114u8, 32u8, 100u8, 101u8, 115u8, 99u8, 114u8, 105u8, 98u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 101u8, 110u8, 116u8, 114u8, 105u8, 101u8, 115u8, 32u8, 116u8, 111u8, 32u8, 97u8, 100u8, 100u8, 32u8, 116u8, 111u8, 32u8, 97u8, 32u8, 100u8, 121u8, 110u8, 97u8, 109u8, 105u8, 99u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 7u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_PREFER_SHORT_USERNAME, dl12/SCHEMA_ATTR_OAUTH2_PREFER_SHORT_USERNAME, dl13/SCHEMA_ATTR_OAUTH2_PREFER_SHORT_USERNAME, dl14/SCHEMA_ATTR_OAUTH2_PREFER_SHORT_USERNAME, dl15/SCHEMA_ATTR_OAUTH2_PREFER_SHORT_USERNAME, dl_1_12/SCHEMA_ATTR_OAUTH2_PREFER_SHORT_USERNAME.
pub fn dl11_attr_oauth2_prefer_short_username()->AttributeRecord{
 AttributeRecord{
name: 116u16,
uuid: 281470681743625u128,
description: Vec::from([85u8, 115u8, 101u8, 32u8, 39u8, 110u8, 97u8, 109u8, 101u8, 39u8, 32u8, 105u8, 110u8, 115u8, 116u8, 101u8, 97u8, 100u8, 32u8, 111u8, 102u8, 32u8, 39u8, 115u8, 112u8, 110u8, 39u8, 32u8, 105u8, 110u8, 32u8, 116u8, 104u8, 101u8, 32u8, 112u8, 114u8, 101u8, 102u8, 101u8, 114u8, 114u8, 101u8, 100u8, 95u8, 117u8, 115u8, 101u8, 114u8, 110u8, 97u8, 109u8, 101u8, 32u8, 99u8, 108u8, 97u8, 105u8, 109u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_API_TOKEN_SESSION, dl12/SCHEMA_ATTR_API_TOKEN_SESSION, dl13/SCHEMA_ATTR_API_TOKEN_SESSION, dl14/SCHEMA_ATTR_API_TOKEN_SESSION, dl15/SCHEMA_ATTR_API_TOKEN_SESSION, dl_1_12/SCHEMA_ATTR_API_TOKEN_SESSION.
pub fn dl11_attr_api_token_session()->AttributeRecord{
 AttributeRecord{
name: 17u16,
uuid: 281470681743633u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 115u8, 115u8, 105u8, 111u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 114u8, 101u8, 108u8, 97u8, 116u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 97u8, 110u8, 32u8, 105u8, 115u8, 115u8, 117u8, 101u8, 100u8, 32u8, 65u8, 80u8, 73u8, 32u8, 116u8, 111u8, 107u8, 101u8, 110u8]),
multivalue: true,
unique: true,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 31u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_USER_AUTH_TOKEN_SESSION, dl12/SCHEMA_ATTR_USER_AUTH_TOKEN_SESSION, dl13/SCHEMA_ATTR_USER_AUTH_TOKEN_SESSION, dl14/SCHEMA_ATTR_USER_AUTH_TOKEN_SESSION, dl15/SCHEMA_ATTR_USER_AUTH_TOKEN_SESSION, dl_1_12/SCHEMA_ATTR_USER_AUTH_TOKEN_SESSION.
pub fn dl11_attr_user_auth_token_session()->AttributeRecord{
 AttributeRecord{
name: 174u16,
uuid: 281470681743635u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 115u8, 115u8, 105u8, 111u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 114u8, 101u8, 108u8, 97u8, 116u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 97u8, 110u8, 32u8, 105u8, 115u8, 115u8, 117u8, 101u8, 100u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 97u8, 117u8, 116u8, 104u8, 32u8, 116u8, 111u8, 107u8, 101u8, 110u8]),
multivalue: true,
unique: true,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 25u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_OAUTH2_SESSION, dl12/SCHEMA_ATTR_OAUTH2_SESSION, dl13/SCHEMA_ATTR_OAUTH2_SESSION, dl14/SCHEMA_ATTR_OAUTH2_SESSION, dl15/SCHEMA_ATTR_OAUTH2_SESSION, dl_1_12/SCHEMA_ATTR_OAUTH2_SESSION.
pub fn dl11_attr_oauth2_session()->AttributeRecord{
 AttributeRecord{
name: 128u16,
uuid: 281470681743639u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 115u8, 115u8, 105u8, 111u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 116u8, 111u8, 32u8, 97u8, 110u8, 32u8, 97u8, 99u8, 116u8, 105u8, 118u8, 101u8, 32u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 32u8, 115u8, 101u8, 115u8, 115u8, 105u8, 111u8, 110u8, 44u8, 32u8, 98u8, 111u8, 117u8, 110u8, 100u8, 32u8, 116u8, 111u8, 32u8, 97u8, 32u8, 112u8, 97u8, 114u8, 101u8, 110u8, 116u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 97u8, 117u8, 116u8, 104u8, 32u8, 116u8, 111u8, 107u8, 101u8, 110u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 28u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_SYNC_TOKEN_SESSION, dl12/SCHEMA_ATTR_SYNC_TOKEN_SESSION, dl13/SCHEMA_ATTR_SYNC_TOKEN_SESSION, dl14/SCHEMA_ATTR_SYNC_TOKEN_SESSION, dl15/SCHEMA_ATTR_SYNC_TOKEN_SESSION, dl_1_12/SCHEMA_ATTR_SYNC_TOKEN_SESSION.
pub fn dl11_attr_sync_token_session()->AttributeRecord{
 AttributeRecord{
name: 161u16,
uuid: 281470681743637u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 115u8, 115u8, 105u8, 111u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 114u8, 101u8, 108u8, 97u8, 116u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 97u8, 110u8, 32u8, 105u8, 115u8, 115u8, 117u8, 101u8, 100u8, 32u8, 115u8, 121u8, 110u8, 99u8, 32u8, 116u8, 111u8, 107u8, 101u8, 110u8]),
multivalue: false,
unique: true,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 31u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_SYNC_COOKIE, dl12/SCHEMA_ATTR_SYNC_COOKIE, dl13/SCHEMA_ATTR_SYNC_COOKIE, dl14/SCHEMA_ATTR_SYNC_COOKIE, dl15/SCHEMA_ATTR_SYNC_COOKIE, dl_1_12/SCHEMA_ATTR_SYNC_COOKIE.
pub fn dl11_attr_sync_cookie()->AttributeRecord{
 AttributeRecord{
name: 157u16,
uuid: 281470681743638u128,
description: Vec::from([65u8, 32u8, 112u8, 114u8, 105u8, 118u8, 97u8, 116u8, 101u8, 32u8, 115u8, 121u8, 110u8, 99u8, 32u8, 99u8, 111u8, 111u8, 107u8, 105u8, 101u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 32u8, 114u8, 101u8, 109u8, 111u8, 116u8, 101u8, 32u8, 73u8, 68u8, 77u8, 32u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 21u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_GRANT_UI_HINT, dl12/SCHEMA_ATTR_GRANT_UI_HINT, dl13/SCHEMA_ATTR_GRANT_UI_HINT, dl14/SCHEMA_ATTR_GRANT_UI_HINT, dl15/SCHEMA_ATTR_GRANT_UI_HINT, dl_1_12/SCHEMA_ATTR_GRANT_UI_HINT.
pub fn dl11_attr_grant_ui_hint()->AttributeRecord{
 AttributeRecord{
name: 65u16,
uuid: 281470681743641u128,
description: Vec::from([65u8, 32u8, 85u8, 73u8, 32u8, 104u8, 105u8, 110u8, 116u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 105u8, 115u8, 32u8, 103u8, 114u8, 97u8, 110u8, 116u8, 101u8, 100u8, 32u8, 118u8, 105u8, 97u8, 32u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 115u8, 104u8, 105u8, 112u8, 32u8, 116u8, 111u8, 32u8, 97u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 29u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_SYNC_CREDENTIAL_PORTAL, dl12/SCHEMA_ATTR_SYNC_CREDENTIAL_PORTAL, dl13/SCHEMA_ATTR_SYNC_CREDENTIAL_PORTAL, dl14/SCHEMA_ATTR_SYNC_CREDENTIAL_PORTAL, dl15/SCHEMA_ATTR_SYNC_CREDENTIAL_PORTAL, dl_1_12/SCHEMA_ATTR_SYNC_CREDENTIAL_PORTAL.
pub fn dl11_attr_sync_credential_portal()->AttributeRecord{
 AttributeRecord{
name: 158u16,
uuid: 281470681743670u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 117u8, 114u8, 108u8, 32u8, 111u8, 102u8, 32u8, 97u8, 110u8, 32u8, 101u8, 120u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 32u8, 112u8, 111u8, 114u8, 116u8, 97u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 115u8, 121u8, 110u8, 99u8, 101u8, 100u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 32u8, 116u8, 111u8, 32u8, 118u8, 105u8, 115u8, 105u8, 116u8, 32u8, 116u8, 111u8, 32u8, 117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 32u8, 116u8, 104u8, 101u8, 105u8, 114u8, 32u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 115u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 18u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_SYNC_YIELD_AUTHORITY, dl12/SCHEMA_ATTR_SYNC_YIELD_AUTHORITY, dl13/SCHEMA_ATTR_SYNC_YIELD_AUTHORITY, dl14/SCHEMA_ATTR_SYNC_YIELD_AUTHORITY, dl15/SCHEMA_ATTR_SYNC_YIELD_AUTHORITY, dl_1_12/SCHEMA_ATTR_SYNC_YIELD_AUTHORITY.
pub fn dl11_attr_sync_yield_authority()->AttributeRecord{
 AttributeRecord{
name: 162u16,
uuid: 281470681743672u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 104u8, 97u8, 118u8, 101u8, 32u8, 116u8, 104u8, 101u8, 105u8, 114u8, 32u8, 97u8, 117u8, 116u8, 104u8, 111u8, 114u8, 105u8, 116u8, 121u8, 32u8, 121u8, 105u8, 101u8, 108u8, 100u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 75u8, 97u8, 110u8, 105u8, 100u8, 109u8, 32u8, 105u8, 110u8, 32u8, 97u8, 32u8, 115u8, 121u8, 110u8, 99u8, 32u8, 97u8, 103u8, 114u8, 101u8, 101u8, 109u8, 101u8, 110u8, 116u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 1u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_CREDENTIAL_TYPE_MINIMUM, dl12/SCHEMA_ATTR_CREDENTIAL_TYPE_MINIMUM, dl13/SCHEMA_ATTR_CREDENTIAL_TYPE_MINIMUM, dl14/SCHEMA_ATTR_CREDENTIAL_TYPE_MINIMUM, dl15/SCHEMA_ATTR_CREDENTIAL_TYPE_MINIMUM, dl_1_12/SCHEMA_ATTR_CREDENTIAL_TYPE_MINIMUM.
pub fn dl11_attr_credential_type_minimum()->AttributeRecord{
 AttributeRecord{
name: 33u16,
uuid: 281470681743688u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 109u8, 105u8, 110u8, 105u8, 109u8, 117u8, 109u8, 32u8, 108u8, 101u8, 118u8, 101u8, 108u8, 32u8, 111u8, 102u8, 32u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 32u8, 116u8, 121u8, 112u8, 101u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 97u8, 110u8, 32u8, 115u8, 97u8, 116u8, 105u8, 115u8, 102u8, 121u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 35u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_LIMIT_SEARCH_MAX_RESULTS_DL6, dl12/SCHEMA_ATTR_LIMIT_SEARCH_MAX_RESULTS_DL6, dl13/SCHEMA_ATTR_LIMIT_SEARCH_MAX_RESULTS_DL6, dl14/SCHEMA_ATTR_LIMIT_SEARCH_MAX_RESULTS_DL6, dl15/SCHEMA_ATTR_LIMIT_SEARCH_MAX_RESULTS_DL6, dl_1_12/SCHEMA_ATTR_LIMIT_SEARCH_MAX_RESULTS_DL6.
pub fn dl11_attr_limit_search_max_results_dl6()->AttributeRecord{
 AttributeRecord{
name: 89u16,
uuid: 281470681743713u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 109u8, 97u8, 120u8, 105u8, 109u8, 117u8, 109u8, 32u8, 110u8, 117u8, 109u8, 98u8, 101u8, 114u8, 32u8, 111u8, 102u8, 32u8, 113u8, 117u8, 101u8, 114u8, 121u8, 32u8, 114u8, 101u8, 115u8, 117u8, 108u8, 116u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 109u8, 97u8, 121u8, 32u8, 98u8, 101u8, 32u8, 114u8, 101u8, 116u8, 117u8, 114u8, 110u8, 101u8, 100u8, 32u8, 105u8, 110u8, 32u8, 97u8, 32u8, 115u8, 105u8, 110u8, 103u8, 108u8, 101u8, 32u8, 111u8, 112u8, 101u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 12u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_LIMIT_SEARCH_MAX_FILTER_TEST_DL6, dl12/SCHEMA_ATTR_LIMIT_SEARCH_MAX_FILTER_TEST_DL6, dl13/SCHEMA_ATTR_LIMIT_SEARCH_MAX_FILTER_TEST_DL6, dl14/SCHEMA_ATTR_LIMIT_SEARCH_MAX_FILTER_TEST_DL6, dl15/SCHEMA_ATTR_LIMIT_SEARCH_MAX_FILTER_TEST_DL6, dl_1_12/SCHEMA_ATTR_LIMIT_SEARCH_MAX_FILTER_TEST_DL6.
pub fn dl11_attr_limit_search_max_filter_test_dl6()->AttributeRecord{
 AttributeRecord{
name: 88u16,
uuid: 281470681743714u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 109u8, 97u8, 120u8, 105u8, 109u8, 117u8, 109u8, 32u8, 110u8, 117u8, 109u8, 98u8, 101u8, 114u8, 32u8, 111u8, 102u8, 32u8, 101u8, 110u8, 116u8, 114u8, 105u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 109u8, 97u8, 121u8, 32u8, 98u8, 101u8, 32u8, 101u8, 120u8, 97u8, 109u8, 105u8, 110u8, 101u8, 100u8, 32u8, 105u8, 110u8, 32u8, 97u8, 32u8, 112u8, 97u8, 114u8, 116u8, 105u8, 97u8, 108u8, 108u8, 121u8, 32u8, 105u8, 110u8, 100u8, 101u8, 120u8, 101u8, 100u8, 32u8, 113u8, 117u8, 101u8, 114u8, 121u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 12u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_KEY_INTERNAL_DATA_DL6, dl12/SCHEMA_ATTR_KEY_INTERNAL_DATA_DL6, dl13/SCHEMA_ATTR_KEY_INTERNAL_DATA_DL6.
pub fn dl11_attr_key_internal_data_dl6()->AttributeRecord{
 AttributeRecord{
name: 79u16,
uuid: 281470681743721u128,
description: Vec::from([45u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 38u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_KEY_PROVIDER_DL6, dl12/SCHEMA_ATTR_KEY_PROVIDER_DL6, dl13/SCHEMA_ATTR_KEY_PROVIDER_DL6.
pub fn dl11_attr_key_provider_dl6()->AttributeRecord{
 AttributeRecord{
name: 80u16,
uuid: 281470681743728u128,
description: Vec::from([45u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 6u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_KEY_ACTION_ROTATE_DL6, dl12/SCHEMA_ATTR_KEY_ACTION_ROTATE_DL6, dl13/SCHEMA_ATTR_KEY_ACTION_ROTATE_DL6.
pub fn dl11_attr_key_action_rotate_dl6()->AttributeRecord{
 AttributeRecord{
name: 78u16,
uuid: 281470681743730u128,
description: Vec::from([45u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 16u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_KEY_ACTION_REVOKE_DL6, dl12/SCHEMA_ATTR_KEY_ACTION_REVOKE_DL6, dl13/SCHEMA_ATTR_KEY_ACTION_REVOKE_DL6.
pub fn dl11_attr_key_action_revoke_dl6()->AttributeRecord{
 AttributeRecord{
name: 77u16,
uuid: 281470681743729u128,
description: Vec::from([45u8]),
multivalue: true,
unique: false,
phantom: true,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 39u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_KEY_ACTION_IMPORT_JWS_ES256_DL6, dl12/SCHEMA_ATTR_KEY_ACTION_IMPORT_JWS_ES256_DL6, dl13/SCHEMA_ATTR_KEY_ACTION_IMPORT_JWS_ES256_DL6.
pub fn dl11_attr_key_action_import_jws_es256_dl6()->AttributeRecord{
 AttributeRecord{
name: 75u16,
uuid: 281470681743731u128,
description: Vec::from([45u8]),
multivalue: true,
unique: false,
phantom: true,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 21u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_KEY_ACTION_IMPORT_JWS_RS256_DL6, dl12/SCHEMA_ATTR_KEY_ACTION_IMPORT_JWS_RS256_DL6, dl13/SCHEMA_ATTR_KEY_ACTION_IMPORT_JWS_RS256_DL6.
pub fn dl11_attr_key_action_import_jws_rs256_dl6()->AttributeRecord{
 AttributeRecord{
name: 76u16,
uuid: 281470681743761u128,
description: Vec::from([45u8]),
multivalue: true,
unique: false,
phantom: true,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 21u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_PATCH_LEVEL_DL7, dl12/SCHEMA_ATTR_PATCH_LEVEL_DL7, dl13/SCHEMA_ATTR_PATCH_LEVEL_DL7.
pub fn dl11_attr_patch_level_dl7()->AttributeRecord{
 AttributeRecord{
name: 136u16,
uuid: 281470681743733u128,
description: Vec::from([45u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 12u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_DOMAIN_DEVELOPMENT_TAINT_DL7, dl12/SCHEMA_ATTR_DOMAIN_DEVELOPMENT_TAINT_DL7, dl13/SCHEMA_ATTR_DOMAIN_DEVELOPMENT_TAINT_DL7, dl14/SCHEMA_ATTR_DOMAIN_DEVELOPMENT_TAINT_DL7, dl15/SCHEMA_ATTR_DOMAIN_DEVELOPMENT_TAINT_DL7, dl_1_12/SCHEMA_ATTR_DOMAIN_DEVELOPMENT_TAINT_DL7.
pub fn dl11_attr_domain_development_taint_dl7()->AttributeRecord{
 AttributeRecord{
name: 44u16,
uuid: 281470681743734u128,
description: Vec::from([65u8, 32u8, 102u8, 108u8, 97u8, 103u8, 32u8, 116u8, 111u8, 32u8, 115u8, 104u8, 111u8, 119u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 116u8, 104u8, 101u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 104u8, 97u8, 115u8, 32u8, 98u8, 101u8, 101u8, 110u8, 32u8, 114u8, 117u8, 110u8, 32u8, 111u8, 110u8, 32u8, 97u8, 32u8, 100u8, 101u8, 118u8, 101u8, 108u8, 111u8, 112u8, 109u8, 101u8, 110u8, 116u8, 32u8, 98u8, 117u8, 105u8, 108u8, 100u8, 44u8, 32u8, 97u8, 110u8, 100u8, 32u8, 119u8, 105u8, 108u8, 108u8, 32u8, 110u8, 101u8, 101u8, 100u8, 32u8, 97u8, 100u8, 100u8, 105u8, 116u8, 105u8, 111u8, 110u8, 97u8, 108u8, 32u8, 119u8, 111u8, 114u8, 107u8, 32u8, 116u8, 111u8, 32u8, 117u8, 112u8, 103u8, 114u8, 97u8, 100u8, 101u8, 47u8, 109u8, 105u8, 103u8, 114u8, 97u8, 116u8, 101u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_DOMAIN_ALLOW_EASTER_EGGS_DL9, dl12/SCHEMA_ATTR_DOMAIN_ALLOW_EASTER_EGGS_DL9, dl13/SCHEMA_ATTR_DOMAIN_ALLOW_EASTER_EGGS_DL9, dl14/SCHEMA_ATTR_DOMAIN_ALLOW_EASTER_EGGS_DL9, dl15/SCHEMA_ATTR_DOMAIN_ALLOW_EASTER_EGGS_DL9, dl_1_12/SCHEMA_ATTR_DOMAIN_ALLOW_EASTER_EGGS_DL9.
pub fn dl11_attr_domain_allow_easter_eggs_dl9()->AttributeRecord{
 AttributeRecord{
name: 43u16,
uuid: 281470681743750u128,
description: Vec::from([65u8, 32u8, 102u8, 108u8, 97u8, 103u8, 32u8, 116u8, 111u8, 32u8, 101u8, 110u8, 97u8, 98u8, 108u8, 101u8, 32u8, 101u8, 97u8, 115u8, 116u8, 101u8, 114u8, 32u8, 101u8, 103u8, 103u8, 115u8, 32u8, 105u8, 110u8, 32u8, 116u8, 104u8, 101u8, 32u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 109u8, 97u8, 121u8, 32u8, 110u8, 111u8, 116u8, 32u8, 97u8, 108u8, 119u8, 97u8, 121u8, 115u8, 32u8, 98u8, 101u8, 32u8, 119u8, 97u8, 110u8, 116u8, 101u8, 100u8, 32u8, 98u8, 121u8, 32u8, 97u8, 108u8, 108u8, 32u8, 117u8, 115u8, 101u8, 114u8, 115u8, 47u8, 100u8, 101u8, 112u8, 108u8, 111u8, 121u8, 109u8, 101u8, 110u8, 116u8, 115u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_REFERS_DL7.
pub fn dl11_attr_refers_dl7()->AttributeRecord{
 AttributeRecord{
name: 143u16,
uuid: 281470681743735u128,
description: Vec::from([65u8, 32u8, 114u8, 101u8, 102u8, 101u8, 114u8, 101u8, 110u8, 99u8, 101u8, 32u8, 116u8, 111u8, 32u8, 108u8, 105u8, 110u8, 107u8, 101u8, 100u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 6u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_LINKED_GROUP_DL8, dl12/SCHEMA_ATTR_LINKED_GROUP_DL8, dl13/SCHEMA_ATTR_LINKED_GROUP_DL8, dl14/SCHEMA_ATTR_LINKED_GROUP_DL8, dl15/SCHEMA_ATTR_LINKED_GROUP_DL8, dl_1_12/SCHEMA_ATTR_LINKED_GROUP_DL8.
pub fn dl11_attr_linked_group_dl8()->AttributeRecord{
 AttributeRecord{
name: 90u16,
uuid: 281470681743746u128,
description: Vec::from([65u8, 32u8, 114u8, 101u8, 102u8, 101u8, 114u8, 101u8, 110u8, 99u8, 101u8, 32u8, 108u8, 105u8, 110u8, 107u8, 105u8, 110u8, 103u8, 32u8, 97u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 32u8, 116u8, 111u8, 32u8, 97u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 6u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_ALLOW_PRIMARY_CRED_FALLBACK_DL8, dl12/SCHEMA_ATTR_ALLOW_PRIMARY_CRED_FALLBACK_DL8, dl13/SCHEMA_ATTR_ALLOW_PRIMARY_CRED_FALLBACK_DL8, dl14/SCHEMA_ATTR_ALLOW_PRIMARY_CRED_FALLBACK_DL8, dl15/SCHEMA_ATTR_ALLOW_PRIMARY_CRED_FALLBACK_DL8, dl_1_12/SCHEMA_ATTR_ALLOW_PRIMARY_CRED_FALLBACK_DL8.
pub fn dl11_attr_allow_primary_cred_fallback_dl8()->AttributeRecord{
 AttributeRecord{
name: 16u16,
uuid: 281470681743749u128,
description: Vec::from([65u8, 108u8, 108u8, 111u8, 119u8, 32u8, 102u8, 97u8, 108u8, 108u8, 98u8, 97u8, 99u8, 107u8, 32u8, 116u8, 111u8, 32u8, 112u8, 114u8, 105u8, 109u8, 97u8, 114u8, 121u8, 32u8, 112u8, 97u8, 115u8, 115u8, 119u8, 111u8, 114u8, 100u8, 32u8, 105u8, 102u8, 32u8, 110u8, 111u8, 32u8, 80u8, 79u8, 83u8, 73u8, 88u8, 32u8, 112u8, 97u8, 115u8, 115u8, 119u8, 111u8, 114u8, 100u8, 32u8, 101u8, 120u8, 105u8, 115u8, 116u8, 115u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_CERTIFICATE_DL7, dl12/SCHEMA_ATTR_CERTIFICATE_DL7, dl13/SCHEMA_ATTR_CERTIFICATE_DL7, dl14/SCHEMA_ATTR_CERTIFICATE_DL7, dl15/SCHEMA_ATTR_CERTIFICATE_DL7, dl_1_12/SCHEMA_ATTR_CERTIFICATE_DL7.
pub fn dl11_attr_certificate_dl7()->AttributeRecord{
 AttributeRecord{
name: 27u16,
uuid: 281470681743736u128,
description: Vec::from([65u8, 110u8, 32u8, 120u8, 53u8, 48u8, 57u8, 32u8, 67u8, 101u8, 114u8, 116u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 101u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 40u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_APPLICATION_PASSWORD_DL8, dl12/SCHEMA_ATTR_APPLICATION_PASSWORD_DL8, dl13/SCHEMA_ATTR_APPLICATION_PASSWORD_DL8, dl14/SCHEMA_ATTR_APPLICATION_PASSWORD_DL8, dl15/SCHEMA_ATTR_APPLICATION_PASSWORD_DL8, dl_1_12/SCHEMA_ATTR_APPLICATION_PASSWORD_DL8.
pub fn dl11_attr_application_password_dl8()->AttributeRecord{
 AttributeRecord{
name: 18u16,
uuid: 281470681743747u128,
description: Vec::from([65u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 112u8, 97u8, 115u8, 115u8, 119u8, 111u8, 114u8, 100u8, 115u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 41u16,
}
}

/// Exact complete record for dl11/SCHEMA_ATTR_APPLICATION_URL, dl12/SCHEMA_ATTR_APPLICATION_URL, dl13/SCHEMA_ATTR_APPLICATION_URL, dl14/SCHEMA_ATTR_APPLICATION_URL, dl15/SCHEMA_ATTR_APPLICATION_URL, dl_1_12/SCHEMA_ATTR_APPLICATION_URL.
pub fn dl11_attr_application_url()->AttributeRecord{
 AttributeRecord{
name: 19u16,
uuid: 281470681743763u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 85u8, 82u8, 76u8, 32u8, 111u8, 102u8, 32u8, 97u8, 110u8, 32u8, 101u8, 120u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 18u16,
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_PERSON_DL8.
pub fn dl11_class_person_dl8()->ClassRecord{
 ClassRecord{
name: Vec::from([112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
uuid: 281470681743428u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
sync_allowed: true,
systemmay: Vec::from([138u16, 133u16, 20u16, 34u16, 152u16, 141u16, 113u16, 174u16, 128u16, 92u16, 87u16, 18u16]),
may: Vec::from([]),
systemmust: Vec::from([69u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 11u8, 0u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_ORGPERSON, dl12/SCHEMA_CLASS_ORGPERSON, dl13/SCHEMA_CLASS_ORGPERSON, dl14/SCHEMA_CLASS_ORGPERSON, dl15/SCHEMA_CLASS_ORGPERSON, dl_1_12/SCHEMA_CLASS_ORGPERSON.
pub fn dl11_class_orgperson()->ClassRecord{
 ClassRecord{
name: Vec::from([111u8, 114u8, 103u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
uuid: 281470681743508u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 110u8, 32u8, 111u8, 114u8, 103u8, 32u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
sync_allowed: false,
systemmay: Vec::from([87u16]),
may: Vec::from([]),
systemmust: Vec::from([92u16, 39u16, 100u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_GROUP_DL6.
pub fn dl11_class_group_dl6()->ClassRecord{
 ClassRecord{
name: Vec::from([103u8, 114u8, 111u8, 117u8, 112u8]),
uuid: 281470681743429u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
sync_allowed: true,
systemmay: Vec::from([95u16, 65u16, 37u16, 92u16]),
may: Vec::from([]),
systemmust: Vec::from([100u16, 151u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_DYNGROUP, dl12/SCHEMA_CLASS_DYNGROUP, dl13/SCHEMA_CLASS_DYNGROUP, dl14/SCHEMA_CLASS_DYNGROUP, dl15/SCHEMA_CLASS_DYNGROUP, dl_1_12/SCHEMA_CLASS_DYNGROUP.
pub fn dl11_class_dyngroup()->ClassRecord{
 ClassRecord{
name: Vec::from([100u8, 121u8, 110u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
uuid: 281470681743623u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 100u8, 121u8, 110u8, 97u8, 109u8, 105u8, 99u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
sync_allowed: false,
systemmay: Vec::from([52u16]),
may: Vec::from([]),
systemmust: Vec::from([51u16]),
must: Vec::from([]),
systemsupplements: Vec::from([5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_ACCOUNT_POLICY_DL8, dl12/SCHEMA_CLASS_ACCOUNT_POLICY_DL8, dl13/SCHEMA_CLASS_ACCOUNT_POLICY_DL8, dl14/SCHEMA_CLASS_ACCOUNT_POLICY_DL8, dl15/SCHEMA_CLASS_ACCOUNT_POLICY_DL8, dl_1_12/SCHEMA_CLASS_ACCOUNT_POLICY_DL8.
pub fn dl11_class_account_policy_dl8()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 112u8, 111u8, 108u8, 105u8, 99u8, 121u8]),
uuid: 281470681743686u128,
description: Vec::from([80u8, 111u8, 108u8, 105u8, 99u8, 105u8, 101u8, 115u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 97u8, 114u8, 101u8, 32u8, 109u8, 101u8, 109u8, 98u8, 101u8, 114u8, 115u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
sync_allowed: false,
systemmay: Vec::from([24u16, 140u16, 23u16, 33u16, 177u16, 89u16, 88u16, 16u16]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_ACCOUNT_DL5.
pub fn dl11_class_account_dl5()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
uuid: 281470681743430u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 110u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
sync_allowed: true,
systemmay: Vec::from([1u16, 3u16, 101u16]),
may: Vec::from([]),
systemmust: Vec::from([39u16, 100u16, 151u16]),
must: Vec::from([]),
systemsupplements: Vec::from([6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 22u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_SERVICE_ACCOUNT_DL7.
pub fn dl11_class_service_account_dl7()->ClassRecord{
 ClassRecord{
name: Vec::from([115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
uuid: 281470681743622u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
sync_allowed: true,
systemmay: Vec::from([152u16, 174u16, 128u16, 113u16, 37u16, 92u16, 138u16, 17u16]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_SYNC_ACCOUNT_DL7, dl12/SCHEMA_CLASS_SYNC_ACCOUNT_DL7, dl13/SCHEMA_CLASS_SYNC_ACCOUNT_DL7, dl14/SCHEMA_CLASS_SYNC_ACCOUNT_DL7, dl15/SCHEMA_CLASS_SYNC_ACCOUNT_DL7, dl_1_12/SCHEMA_CLASS_SYNC_ACCOUNT_DL7.
pub fn dl11_class_sync_account_dl7()->ClassRecord{
 ClassRecord{
name: Vec::from([115u8, 121u8, 110u8, 99u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
uuid: 281470681743636u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 115u8, 121u8, 110u8, 99u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
sync_allowed: false,
systemmay: Vec::from([161u16, 157u16, 158u16, 162u16]),
may: Vec::from([]),
systemmust: Vec::from([100u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_DOMAIN_INFO_DL10, dl12/SCHEMA_CLASS_DOMAIN_INFO_DL10, dl13/SCHEMA_CLASS_DOMAIN_INFO_DL10.
pub fn dl11_class_domain_info_dl10()->ClassRecord{
 ClassRecord{
name: Vec::from([100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 95u8, 105u8, 110u8, 102u8, 111u8]),
uuid: 281470681743442u128,
description: Vec::from([76u8, 111u8, 99u8, 97u8, 108u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 105u8, 110u8, 102u8, 111u8, 114u8, 109u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 97u8, 110u8, 100u8, 32u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
sync_allowed: false,
systemmay: Vec::from([48u16, 46u16, 85u16, 82u16, 70u16, 136u16, 44u16, 43u16, 45u16]),
may: Vec::from([]),
systemmust: Vec::from([100u16, 50u16, 47u16, 176u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_POSIXGROUP, dl12/SCHEMA_CLASS_POSIXGROUP, dl13/SCHEMA_CLASS_POSIXGROUP, dl14/SCHEMA_CLASS_POSIXGROUP, dl15/SCHEMA_CLASS_POSIXGROUP, dl_1_12/SCHEMA_CLASS_POSIXGROUP.
pub fn dl11_class_posixgroup()->ClassRecord{
 ClassRecord{
name: Vec::from([112u8, 111u8, 115u8, 105u8, 120u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
uuid: 281470681743448u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 112u8, 111u8, 115u8, 105u8, 120u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8, 44u8, 32u8, 114u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 115u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
sync_allowed: true,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([64u16]),
must: Vec::from([]),
systemsupplements: Vec::from([5u8, 0u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_POSIXACCOUNT, dl12/SCHEMA_CLASS_POSIXACCOUNT, dl13/SCHEMA_CLASS_POSIXACCOUNT, dl14/SCHEMA_CLASS_POSIXACCOUNT, dl15/SCHEMA_CLASS_POSIXACCOUNT, dl_1_12/SCHEMA_CLASS_POSIXACCOUNT.
pub fn dl11_class_posixaccount()->ClassRecord{
 ClassRecord{
name: Vec::from([112u8, 111u8, 115u8, 105u8, 120u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
uuid: 281470681743447u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 112u8, 111u8, 115u8, 105u8, 120u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 44u8, 32u8, 114u8, 101u8, 113u8, 117u8, 105u8, 114u8, 101u8, 115u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
sync_allowed: true,
systemmay: Vec::from([91u16, 172u16]),
may: Vec::from([]),
systemmust: Vec::from([64u16]),
must: Vec::from([]),
systemsupplements: Vec::from([7u8, 0u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_SYSTEM_CONFIG, dl12/SCHEMA_CLASS_SYSTEM_CONFIG, dl13/SCHEMA_CLASS_SYSTEM_CONFIG, dl14/SCHEMA_CLASS_SYSTEM_CONFIG, dl15/SCHEMA_CLASS_SYSTEM_CONFIG, dl_1_12/SCHEMA_CLASS_SYSTEM_CONFIG.
pub fn dl11_class_system_config()->ClassRecord{
 ClassRecord{
name: Vec::from([115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 95u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8]),
uuid: 281470681743456u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 32u8, 115u8, 121u8, 115u8, 116u8, 101u8, 109u8, 32u8, 40u8, 116u8, 111u8, 112u8, 111u8, 108u8, 111u8, 103u8, 105u8, 101u8, 115u8, 41u8, 32u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 112u8, 116u8, 105u8, 111u8, 110u8, 115u8]),
sync_allowed: false,
systemmay: Vec::from([37u16, 25u16, 24u16, 140u16, 36u16]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_OAUTH2_RS_DL9.
pub fn dl11_class_oauth2_rs_dl9()->ClassRecord{
 ClassRecord{
name: Vec::from([111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8]),
uuid: 281470681743493u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 32u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 101u8, 100u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 67u8, 108u8, 105u8, 101u8, 110u8, 116u8]),
sync_allowed: false,
systemmay: Vec::from([37u16, 125u16, 126u16, 115u16, 116u16, 70u16, 120u16, 128u16, 123u16, 129u16, 114u16, 145u16, 127u16, 60u16]),
may: Vec::from([]),
systemmust: Vec::from([124u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_OAUTH2_RS_BASIC_DL5, dl12/SCHEMA_CLASS_OAUTH2_RS_BASIC_DL5, dl13/SCHEMA_CLASS_OAUTH2_RS_BASIC_DL5, dl14/SCHEMA_CLASS_OAUTH2_RS_BASIC_DL5, dl15/SCHEMA_CLASS_OAUTH2_RS_BASIC_DL5, dl_1_12/SCHEMA_CLASS_OAUTH2_RS_BASIC_DL5.
pub fn dl11_class_oauth2_rs_basic_dl5()->ClassRecord{
 ClassRecord{
name: Vec::from([111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 95u8, 98u8, 97u8, 115u8, 105u8, 99u8]),
uuid: 281470681743494u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 32u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 101u8, 100u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 101u8, 100u8, 32u8, 119u8, 105u8, 116u8, 104u8, 32u8, 72u8, 84u8, 84u8, 80u8, 32u8, 98u8, 97u8, 115u8, 105u8, 99u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
sync_allowed: false,
systemmay: Vec::from([107u16]),
may: Vec::from([]),
systemmust: Vec::from([119u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([29u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 95u8, 112u8, 117u8, 98u8, 108u8, 105u8, 99u8]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_OAUTH2_RS_PUBLIC_DL4, dl12/SCHEMA_CLASS_OAUTH2_RS_PUBLIC_DL4, dl13/SCHEMA_CLASS_OAUTH2_RS_PUBLIC_DL4, dl14/SCHEMA_CLASS_OAUTH2_RS_PUBLIC_DL4, dl15/SCHEMA_CLASS_OAUTH2_RS_PUBLIC_DL4, dl_1_12/SCHEMA_CLASS_OAUTH2_RS_PUBLIC_DL4.
pub fn dl11_class_oauth2_rs_public_dl4()->ClassRecord{
 ClassRecord{
name: Vec::from([111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 95u8, 112u8, 117u8, 98u8, 108u8, 105u8, 99u8]),
uuid: 281470681743671u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 32u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 101u8, 100u8, 32u8, 80u8, 117u8, 98u8, 108u8, 105u8, 99u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 67u8, 108u8, 105u8, 101u8, 110u8, 116u8, 32u8, 119u8, 105u8, 116u8, 104u8, 32u8, 80u8, 75u8, 67u8, 69u8, 32u8, 118u8, 101u8, 114u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
sync_allowed: false,
systemmay: Vec::from([108u16]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([28u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8, 95u8, 98u8, 97u8, 115u8, 105u8, 99u8]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_KEY_PROVIDER_DL6, dl12/SCHEMA_CLASS_KEY_PROVIDER_DL6, dl13/SCHEMA_CLASS_KEY_PROVIDER_DL6, dl14/SCHEMA_CLASS_KEY_PROVIDER_DL6, dl15/SCHEMA_CLASS_KEY_PROVIDER_DL6, dl_1_12/SCHEMA_CLASS_KEY_PROVIDER_DL6.
pub fn dl11_class_key_provider_dl6()->ClassRecord{
 ClassRecord{
name: Vec::from([107u8, 101u8, 121u8, 95u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8]),
uuid: 281470681743716u128,
description: Vec::from([65u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8, 32u8, 102u8, 111u8, 114u8, 32u8, 99u8, 114u8, 121u8, 112u8, 116u8, 111u8, 103u8, 114u8, 97u8, 112u8, 104u8, 105u8, 99u8, 32u8, 107u8, 101u8, 121u8, 32u8, 115u8, 116u8, 111u8, 114u8, 97u8, 103u8, 101u8, 32u8, 97u8, 110u8, 100u8, 32u8, 111u8, 112u8, 101u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 115u8]),
sync_allowed: false,
systemmay: Vec::from([37u16]),
may: Vec::from([]),
systemmust: Vec::from([100u16]),
must: Vec::from([]),
systemsupplements: Vec::from([21u8, 0u8, 107u8, 101u8, 121u8, 95u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8, 95u8, 105u8, 110u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_KEY_PROVIDER_INTERNAL_DL6, dl12/SCHEMA_CLASS_KEY_PROVIDER_INTERNAL_DL6, dl13/SCHEMA_CLASS_KEY_PROVIDER_INTERNAL_DL6, dl14/SCHEMA_CLASS_KEY_PROVIDER_INTERNAL_DL6, dl15/SCHEMA_CLASS_KEY_PROVIDER_INTERNAL_DL6, dl_1_12/SCHEMA_CLASS_KEY_PROVIDER_INTERNAL_DL6.
pub fn dl11_class_key_provider_internal_dl6()->ClassRecord{
 ClassRecord{
name: Vec::from([107u8, 101u8, 121u8, 95u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8, 95u8, 105u8, 110u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8]),
uuid: 281470681743717u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 75u8, 97u8, 110u8, 105u8, 100u8, 109u8, 32u8, 105u8, 110u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 99u8, 114u8, 121u8, 112u8, 116u8, 111u8, 103u8, 114u8, 97u8, 112u8, 104u8, 105u8, 99u8, 32u8, 107u8, 101u8, 121u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_KEY_OBJECT_DL6, dl12/SCHEMA_CLASS_KEY_OBJECT_DL6, dl13/SCHEMA_CLASS_KEY_OBJECT_DL6, dl14/SCHEMA_CLASS_KEY_OBJECT_DL6, dl15/SCHEMA_CLASS_KEY_OBJECT_DL6, dl_1_12/SCHEMA_CLASS_KEY_OBJECT_DL6.
pub fn dl11_class_key_object_dl6()->ClassRecord{
 ClassRecord{
name: Vec::from([107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
uuid: 281470681743718u128,
description: Vec::from([65u8, 32u8, 99u8, 114u8, 121u8, 112u8, 116u8, 111u8, 103u8, 114u8, 97u8, 112u8, 104u8, 105u8, 99u8, 32u8, 107u8, 101u8, 121u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 97u8, 110u8, 32u8, 98u8, 101u8, 32u8, 117u8, 115u8, 101u8, 100u8, 32u8, 98u8, 121u8, 32u8, 97u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([80u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_KEY_OBJECT_JWT_ES256_DL6, dl12/SCHEMA_CLASS_KEY_OBJECT_JWT_ES256_DL6, dl13/SCHEMA_CLASS_KEY_OBJECT_JWT_ES256_DL6, dl14/SCHEMA_CLASS_KEY_OBJECT_JWT_ES256_DL6, dl15/SCHEMA_CLASS_KEY_OBJECT_JWT_ES256_DL6, dl_1_12/SCHEMA_CLASS_KEY_OBJECT_JWT_ES256_DL6.
pub fn dl11_class_key_object_jwt_es256_dl6()->ClassRecord{
 ClassRecord{
name: Vec::from([107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 116u8, 95u8, 101u8, 115u8, 50u8, 53u8, 54u8]),
uuid: 281470681743720u128,
description: Vec::from([65u8, 32u8, 109u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 105u8, 110u8, 100u8, 105u8, 99u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 107u8, 101u8, 121u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 109u8, 117u8, 115u8, 116u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 32u8, 106u8, 119u8, 116u8, 32u8, 101u8, 115u8, 50u8, 53u8, 54u8, 32u8, 99u8, 97u8, 112u8, 97u8, 98u8, 105u8, 108u8, 105u8, 116u8, 121u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([10u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_KEY_OBJECT_JWT_RS256, dl12/SCHEMA_CLASS_KEY_OBJECT_JWT_RS256, dl13/SCHEMA_CLASS_KEY_OBJECT_JWT_RS256, dl14/SCHEMA_CLASS_KEY_OBJECT_JWT_RS256, dl15/SCHEMA_CLASS_KEY_OBJECT_JWT_RS256, dl_1_12/SCHEMA_CLASS_KEY_OBJECT_JWT_RS256.
pub fn dl11_class_key_object_jwt_rs256()->ClassRecord{
 ClassRecord{
name: Vec::from([107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 116u8, 95u8, 114u8, 115u8, 50u8, 53u8, 54u8]),
uuid: 281470681743762u128,
description: Vec::from([65u8, 32u8, 109u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 105u8, 110u8, 100u8, 105u8, 99u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 107u8, 101u8, 121u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 109u8, 117u8, 115u8, 116u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 32u8, 106u8, 119u8, 116u8, 32u8, 114u8, 115u8, 50u8, 53u8, 54u8, 32u8, 99u8, 97u8, 112u8, 97u8, 98u8, 105u8, 108u8, 105u8, 116u8, 121u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([10u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_KEY_OBJECT_JWE_A128GCM_DL6, dl12/SCHEMA_CLASS_KEY_OBJECT_JWE_A128GCM_DL6, dl13/SCHEMA_CLASS_KEY_OBJECT_JWE_A128GCM_DL6, dl14/SCHEMA_CLASS_KEY_OBJECT_JWE_A128GCM_DL6, dl15/SCHEMA_CLASS_KEY_OBJECT_JWE_A128GCM_DL6.
pub fn dl11_class_key_object_jwe_a128gcm_dl6()->ClassRecord{
 ClassRecord{
name: Vec::from([107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 101u8, 95u8, 97u8, 49u8, 50u8, 56u8, 103u8, 99u8, 109u8]),
uuid: 281470681743732u128,
description: Vec::from([65u8, 32u8, 109u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 105u8, 110u8, 100u8, 105u8, 99u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 107u8, 101u8, 121u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 109u8, 117u8, 115u8, 116u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 32u8, 106u8, 119u8, 101u8, 32u8, 97u8, 101u8, 115u8, 45u8, 50u8, 53u8, 54u8, 45u8, 103u8, 99u8, 109u8, 32u8, 99u8, 97u8, 112u8, 97u8, 98u8, 105u8, 108u8, 105u8, 116u8, 121u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([10u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_KEY_OBJECT_INTERNAL_DL6, dl12/SCHEMA_CLASS_KEY_OBJECT_INTERNAL_DL6, dl13/SCHEMA_CLASS_KEY_OBJECT_INTERNAL_DL6, dl14/SCHEMA_CLASS_KEY_OBJECT_INTERNAL_DL6, dl15/SCHEMA_CLASS_KEY_OBJECT_INTERNAL_DL6, dl_1_12/SCHEMA_CLASS_KEY_OBJECT_INTERNAL_DL6.
pub fn dl11_class_key_object_internal_dl6()->ClassRecord{
 ClassRecord{
name: Vec::from([107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 105u8, 110u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8]),
uuid: 281470681743719u128,
description: Vec::from([65u8, 32u8, 99u8, 114u8, 121u8, 112u8, 116u8, 111u8, 103u8, 114u8, 97u8, 112u8, 104u8, 105u8, 99u8, 32u8, 107u8, 101u8, 121u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 97u8, 110u8, 32u8, 98u8, 101u8, 32u8, 117u8, 115u8, 101u8, 100u8, 32u8, 98u8, 121u8, 32u8, 116u8, 104u8, 101u8, 32u8, 105u8, 110u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8]),
sync_allowed: false,
systemmay: Vec::from([79u16]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([10u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_CLIENT_CERTIFICATE_DL7, dl12/SCHEMA_CLASS_CLIENT_CERTIFICATE_DL7, dl13/SCHEMA_CLASS_CLIENT_CERTIFICATE_DL7, dl14/SCHEMA_CLASS_CLIENT_CERTIFICATE_DL7, dl15/SCHEMA_CLASS_CLIENT_CERTIFICATE_DL7, dl_1_12/SCHEMA_CLASS_CLIENT_CERTIFICATE_DL7.
pub fn dl11_class_client_certificate_dl7()->ClassRecord{
 ClassRecord{
name: Vec::from([99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 95u8, 99u8, 101u8, 114u8, 116u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 101u8]),
uuid: 281470681743737u128,
description: Vec::from([65u8, 32u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 99u8, 101u8, 114u8, 116u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 101u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([27u16, 143u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl11/SCHEMA_CLASS_APPLICATION, dl12/SCHEMA_CLASS_APPLICATION, dl13/SCHEMA_CLASS_APPLICATION, dl14/SCHEMA_CLASS_APPLICATION, dl15/SCHEMA_CLASS_APPLICATION, dl_1_12/SCHEMA_CLASS_APPLICATION.
pub fn dl11_class_application()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
uuid: 281470681743745u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 110u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
sync_allowed: false,
systemmay: Vec::from([19u16]),
may: Vec::from([]),
systemmust: Vec::from([90u16]),
must: Vec::from([]),
systemsupplements: Vec::from([15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_OAUTH2_JWT_LEGACY_CRYPTO_ENABLE, dl13/SCHEMA_ATTR_OAUTH2_JWT_LEGACY_CRYPTO_ENABLE, dl14/SCHEMA_ATTR_OAUTH2_JWT_LEGACY_CRYPTO_ENABLE, dl15/SCHEMA_ATTR_OAUTH2_JWT_LEGACY_CRYPTO_ENABLE, dl_1_12/SCHEMA_ATTR_OAUTH2_JWT_LEGACY_CRYPTO_ENABLE.
pub fn dl12_attr_oauth2_jwt_legacy_crypto_enable()->AttributeRecord{
 AttributeRecord{
name: 115u16,
uuid: 281470681743506u128,
description: Vec::from([65u8, 108u8, 108u8, 111u8, 119u8, 115u8, 32u8, 101u8, 110u8, 97u8, 98u8, 108u8, 105u8, 110u8, 103u8, 32u8, 108u8, 101u8, 103u8, 97u8, 99u8, 121u8, 32u8, 74u8, 87u8, 84u8, 32u8, 99u8, 114u8, 121u8, 112u8, 116u8, 111u8, 103u8, 114u8, 97u8, 104u8, 112u8, 121u8, 32u8, 102u8, 111u8, 114u8, 32u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 115u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_OAUTH2_DEVICE_FLOW_ENABLE, dl13/SCHEMA_ATTR_OAUTH2_DEVICE_FLOW_ENABLE, dl14/SCHEMA_ATTR_OAUTH2_DEVICE_FLOW_ENABLE, dl15/SCHEMA_ATTR_OAUTH2_DEVICE_FLOW_ENABLE, dl_1_12/SCHEMA_ATTR_OAUTH2_DEVICE_FLOW_ENABLE.
pub fn dl12_attr_oauth2_device_flow_enable()->AttributeRecord{
 AttributeRecord{
name: 114u16,
uuid: 281474959933557u128,
description: Vec::from([69u8, 110u8, 97u8, 98u8, 108u8, 101u8, 32u8, 116u8, 104u8, 101u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 68u8, 101u8, 118u8, 105u8, 99u8, 101u8, 32u8, 70u8, 108u8, 111u8, 119u8, 32u8, 102u8, 111u8, 114u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_MESSAGE_TEMPLATE, dl13/SCHEMA_ATTR_MESSAGE_TEMPLATE, dl14/SCHEMA_ATTR_MESSAGE_TEMPLATE, dl15/SCHEMA_ATTR_MESSAGE_TEMPLATE, dl_1_12/SCHEMA_ATTR_MESSAGE_TEMPLATE.
pub fn dl12_attr_message_template()->AttributeRecord{
 AttributeRecord{
name: 97u16,
uuid: 281470681743766u128,
description: Vec::from([65u8, 32u8, 74u8, 83u8, 79u8, 78u8, 32u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 99u8, 111u8, 110u8, 116u8, 97u8, 105u8, 110u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 101u8, 32u8, 110u8, 97u8, 109u8, 101u8, 100u8, 32u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 32u8, 116u8, 101u8, 109u8, 112u8, 108u8, 97u8, 116u8, 101u8, 32u8, 97u8, 110u8, 100u8, 32u8, 102u8, 105u8, 101u8, 108u8, 100u8, 115u8, 32u8, 114u8, 101u8, 108u8, 97u8, 116u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 97u8, 32u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 99u8, 97u8, 110u8, 32u8, 98u8, 101u8, 32u8, 115u8, 117u8, 98u8, 115u8, 116u8, 105u8, 116u8, 117u8, 116u8, 101u8, 100u8, 32u8, 105u8, 110u8, 116u8, 111u8, 32u8, 116u8, 104u8, 101u8, 32u8, 116u8, 101u8, 109u8, 112u8, 108u8, 97u8, 116u8, 101u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 43u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_SEND_AFTER, dl13/SCHEMA_ATTR_SEND_AFTER, dl14/SCHEMA_ATTR_SEND_AFTER, dl15/SCHEMA_ATTR_SEND_AFTER, dl_1_12/SCHEMA_ATTR_SEND_AFTER.
pub fn dl12_attr_send_after()->AttributeRecord{
 AttributeRecord{
name: 148u16,
uuid: 281470681743767u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 97u8, 116u8, 101u8, 116u8, 105u8, 109u8, 101u8, 32u8, 97u8, 102u8, 116u8, 101u8, 114u8, 32u8, 119u8, 104u8, 105u8, 99u8, 104u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 32u8, 105u8, 115u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 98u8, 101u8, 32u8, 114u8, 101u8, 108u8, 101u8, 97u8, 115u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 116u8, 104u8, 101u8, 32u8, 100u8, 101u8, 115u8, 116u8, 105u8, 110u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 16u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_DELETE_AFTER, dl13/SCHEMA_ATTR_DELETE_AFTER, dl14/SCHEMA_ATTR_DELETE_AFTER, dl15/SCHEMA_ATTR_DELETE_AFTER, dl_1_12/SCHEMA_ATTR_DELETE_AFTER.
pub fn dl12_attr_delete_after()->AttributeRecord{
 AttributeRecord{
name: 35u16,
uuid: 281470681743768u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 97u8, 116u8, 101u8, 116u8, 105u8, 109u8, 101u8, 32u8, 97u8, 102u8, 116u8, 101u8, 114u8, 32u8, 119u8, 104u8, 105u8, 99u8, 104u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 119u8, 105u8, 108u8, 108u8, 32u8, 98u8, 101u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 101u8, 100u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 16u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_SENT_AT, dl13/SCHEMA_ATTR_SENT_AT, dl14/SCHEMA_ATTR_SENT_AT, dl15/SCHEMA_ATTR_SENT_AT, dl_1_12/SCHEMA_ATTR_SENT_AT.
pub fn dl12_attr_sent_at()->AttributeRecord{
 AttributeRecord{
name: 149u16,
uuid: 281470681743769u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 97u8, 116u8, 101u8, 116u8, 105u8, 109u8, 101u8, 32u8, 119u8, 104u8, 101u8, 110u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 32u8, 119u8, 97u8, 115u8, 32u8, 115u8, 101u8, 110u8, 116u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 16u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_MAIL_DESTINATION, dl13/SCHEMA_ATTR_MAIL_DESTINATION, dl14/SCHEMA_ATTR_MAIL_DESTINATION, dl15/SCHEMA_ATTR_MAIL_DESTINATION, dl_1_12/SCHEMA_ATTR_MAIL_DESTINATION.
pub fn dl12_attr_mail_destination()->AttributeRecord{
 AttributeRecord{
name: 93u16,
uuid: 281470681743872u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 101u8, 115u8, 116u8, 105u8, 110u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 97u8, 100u8, 100u8, 114u8, 101u8, 115u8, 115u8, 101u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 119u8, 105u8, 108u8, 108u8, 32u8, 114u8, 101u8, 99u8, 105u8, 101u8, 118u8, 101u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 17u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_OAUTH2_ACCOUNT_PROVIDER.
pub fn dl12_attr_oauth2_account_provider()->AttributeRecord{
 AttributeRecord{
name: 104u16,
uuid: 281470681743889u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 114u8, 101u8, 102u8, 101u8, 114u8, 101u8, 110u8, 99u8, 101u8, 32u8, 116u8, 111u8, 32u8, 116u8, 104u8, 101u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 115u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 102u8, 111u8, 114u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 6u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_OAUTH2_ACCOUNT_CREDENTIAL_UUID, dl13/SCHEMA_ATTR_OAUTH2_ACCOUNT_CREDENTIAL_UUID, dl14/SCHEMA_ATTR_OAUTH2_ACCOUNT_CREDENTIAL_UUID, dl15/SCHEMA_ATTR_OAUTH2_ACCOUNT_CREDENTIAL_UUID, dl_1_12/SCHEMA_ATTR_OAUTH2_ACCOUNT_CREDENTIAL_UUID.
pub fn dl12_attr_oauth2_account_credential_uuid()->AttributeRecord{
 AttributeRecord{
name: 103u16,
uuid: 281470681743878u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 117u8, 117u8, 105u8, 100u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 99u8, 114u8, 101u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 32u8, 102u8, 111u8, 114u8, 32u8, 115u8, 101u8, 115u8, 115u8, 105u8, 111u8, 110u8, 32u8, 116u8, 114u8, 97u8, 99u8, 107u8, 105u8, 110u8, 103u8, 32u8, 119u8, 104u8, 101u8, 110u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 105u8, 115u8, 32u8, 117u8, 115u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 101u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 2u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_OAUTH2_ACCOUNT_UNIQUE_USER_ID.
pub fn dl12_attr_oauth2_account_unique_user_id()->AttributeRecord{
 AttributeRecord{
name: 105u16,
uuid: 281470681743874u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 117u8, 110u8, 105u8, 113u8, 117u8, 101u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 105u8, 100u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 97u8, 115u8, 32u8, 107u8, 110u8, 111u8, 119u8, 110u8, 32u8, 98u8, 121u8, 32u8, 116u8, 104u8, 101u8, 32u8, 114u8, 101u8, 109u8, 111u8, 116u8, 101u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 0u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_OAUTH2_CLIENT_ID, dl13/SCHEMA_ATTR_OAUTH2_CLIENT_ID, dl14/SCHEMA_ATTR_OAUTH2_CLIENT_ID, dl15/SCHEMA_ATTR_OAUTH2_CLIENT_ID, dl_1_12/SCHEMA_ATTR_OAUTH2_CLIENT_ID.
pub fn dl12_attr_oauth2_client_id()->AttributeRecord{
 AttributeRecord{
name: 110u16,
uuid: 281470681743875u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 67u8, 108u8, 105u8, 101u8, 110u8, 116u8, 32u8, 73u8, 68u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 0u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_OAUTH2_CLIENT_SECRET, dl13/SCHEMA_ATTR_OAUTH2_CLIENT_SECRET, dl14/SCHEMA_ATTR_OAUTH2_CLIENT_SECRET, dl15/SCHEMA_ATTR_OAUTH2_CLIENT_SECRET, dl_1_12/SCHEMA_ATTR_OAUTH2_CLIENT_SECRET.
pub fn dl12_attr_oauth2_client_secret()->AttributeRecord{
 AttributeRecord{
name: 111u16,
uuid: 281470681743879u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 67u8, 108u8, 105u8, 101u8, 110u8, 116u8, 32u8, 83u8, 101u8, 99u8, 114u8, 101u8, 116u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 0u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_OAUTH2_AUTHORISATION_ENDPOINT, dl13/SCHEMA_ATTR_OAUTH2_AUTHORISATION_ENDPOINT, dl14/SCHEMA_ATTR_OAUTH2_AUTHORISATION_ENDPOINT, dl15/SCHEMA_ATTR_OAUTH2_AUTHORISATION_ENDPOINT, dl_1_12/SCHEMA_ATTR_OAUTH2_AUTHORISATION_ENDPOINT.
pub fn dl12_attr_oauth2_authorisation_endpoint()->AttributeRecord{
 AttributeRecord{
name: 109u16,
uuid: 281470681743876u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 97u8, 117u8, 116u8, 104u8, 111u8, 114u8, 105u8, 115u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 117u8, 114u8, 108u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 18u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_OAUTH2_TOKEN_ENDPOINT, dl13/SCHEMA_ATTR_OAUTH2_TOKEN_ENDPOINT, dl14/SCHEMA_ATTR_OAUTH2_TOKEN_ENDPOINT, dl15/SCHEMA_ATTR_OAUTH2_TOKEN_ENDPOINT, dl_1_12/SCHEMA_ATTR_OAUTH2_TOKEN_ENDPOINT.
pub fn dl12_attr_oauth2_token_endpoint()->AttributeRecord{
 AttributeRecord{
name: 130u16,
uuid: 281470681743877u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 116u8, 111u8, 107u8, 101u8, 110u8, 32u8, 117u8, 114u8, 108u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 18u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_OAUTH2_REQUEST_SCOPES, dl13/SCHEMA_ATTR_OAUTH2_REQUEST_SCOPES, dl14/SCHEMA_ATTR_OAUTH2_REQUEST_SCOPES, dl15/SCHEMA_ATTR_OAUTH2_REQUEST_SCOPES, dl_1_12/SCHEMA_ATTR_OAUTH2_REQUEST_SCOPES.
pub fn dl12_attr_oauth2_request_scopes()->AttributeRecord{
 AttributeRecord{
name: 118u16,
uuid: 281470681743880u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 115u8, 99u8, 111u8, 112u8, 101u8, 115u8, 32u8, 116u8, 111u8, 32u8, 114u8, 101u8, 113u8, 117u8, 101u8, 115u8, 116u8, 32u8, 100u8, 117u8, 114u8, 105u8, 110u8, 103u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 97u8, 117u8, 116u8, 104u8, 111u8, 114u8, 105u8, 115u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 114u8, 101u8, 113u8, 117u8, 101u8, 115u8, 116u8, 115u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 19u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_HMAC_NAME_HISTORY, dl13/SCHEMA_ATTR_HMAC_NAME_HISTORY, dl14/SCHEMA_ATTR_HMAC_NAME_HISTORY, dl15/SCHEMA_ATTR_HMAC_NAME_HISTORY, dl_1_12/SCHEMA_ATTR_HMAC_NAME_HISTORY.
pub fn dl12_attr_hmac_name_history()->AttributeRecord{
 AttributeRecord{
name: 67u16,
uuid: 281470681743890u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 115u8, 101u8, 116u8, 32u8, 111u8, 102u8, 32u8, 97u8, 108u8, 108u8, 32u8, 110u8, 97u8, 109u8, 101u8, 115u8, 32u8, 117u8, 115u8, 101u8, 100u8, 32u8, 111u8, 110u8, 32u8, 97u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 44u8, 32u8, 72u8, 77u8, 65u8, 67u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 112u8, 114u8, 101u8, 115u8, 101u8, 114u8, 118u8, 101u8, 32u8, 112u8, 114u8, 105u8, 118u8, 97u8, 99u8, 121u8, 46u8]),
multivalue: true,
unique: true,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 44u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_IN_MEMORIAM, dl13/SCHEMA_ATTR_IN_MEMORIAM, dl14/SCHEMA_ATTR_IN_MEMORIAM, dl15/SCHEMA_ATTR_IN_MEMORIAM, dl_1_12/SCHEMA_ATTR_IN_MEMORIAM.
pub fn dl12_attr_in_memoriam()->AttributeRecord{
 AttributeRecord{
name: 71u16,
uuid: 281470681743894u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 117u8, 117u8, 105u8, 100u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 109u8, 101u8, 109u8, 111u8, 114u8, 105u8, 97u8, 108u8, 32u8, 105u8, 115u8, 32u8, 100u8, 101u8, 100u8, 105u8, 99u8, 97u8, 116u8, 101u8, 100u8, 32u8, 116u8, 111u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 2u16,
}
}

/// Exact complete record for dl12/SCHEMA_ATTR_ENABLED, dl13/SCHEMA_ATTR_ENABLED, dl14/SCHEMA_ATTR_ENABLED, dl15/SCHEMA_ATTR_ENABLED, dl_1_12/SCHEMA_ATTR_ENABLED.
pub fn dl12_attr_enabled()->AttributeRecord{
 AttributeRecord{
name: 56u16,
uuid: 281470681743891u128,
description: Vec::from([65u8, 32u8, 102u8, 108u8, 97u8, 103u8, 32u8, 100u8, 101u8, 115u8, 99u8, 114u8, 105u8, 98u8, 105u8, 110u8, 103u8, 32u8, 105u8, 102u8, 32u8, 97u8, 32u8, 102u8, 101u8, 97u8, 116u8, 117u8, 114u8, 101u8, 32u8, 105u8, 115u8, 32u8, 101u8, 110u8, 97u8, 98u8, 108u8, 101u8, 100u8, 32u8, 111u8, 114u8, 32u8, 100u8, 105u8, 115u8, 97u8, 98u8, 108u8, 101u8, 100u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl12/SCHEMA_CLASS_PERSON_DL8.
pub fn dl12_class_person_dl8()->ClassRecord{
 ClassRecord{
name: Vec::from([112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
uuid: 281470681743428u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
sync_allowed: true,
systemmay: Vec::from([138u16, 133u16, 20u16, 34u16, 152u16, 141u16, 113u16, 174u16, 128u16, 92u16, 87u16, 18u16, 69u16]),
may: Vec::from([]),
systemmust: Vec::from([100u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 11u8, 0u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl12/SCHEMA_CLASS_OAUTH2_ACCOUNT, dl13/SCHEMA_CLASS_OAUTH2_ACCOUNT, dl14/SCHEMA_CLASS_OAUTH2_ACCOUNT.
pub fn dl12_class_oauth2_account()->ClassRecord{
 ClassRecord{
name: Vec::from([111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
uuid: 281470681743881u128,
description: Vec::from([77u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 100u8, 101u8, 115u8, 105u8, 103u8, 110u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 97u8, 110u8, 32u8, 99u8, 97u8, 110u8, 32u8, 117u8, 115u8, 101u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 46u8]),
sync_allowed: true,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([104u16, 105u16, 103u16]),
must: Vec::from([]),
systemsupplements: Vec::from([6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl12/SCHEMA_CLASS_GROUP_DL6, dl13/SCHEMA_CLASS_GROUP_DL6, dl14/SCHEMA_CLASS_GROUP_DL6, dl15/SCHEMA_CLASS_GROUP_DL6, dl_1_12/SCHEMA_CLASS_GROUP_DL6.
pub fn dl12_class_group_dl6()->ClassRecord{
 ClassRecord{
name: Vec::from([103u8, 114u8, 111u8, 117u8, 112u8]),
uuid: 281470681743429u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 103u8, 114u8, 111u8, 117u8, 112u8]),
sync_allowed: true,
systemmay: Vec::from([95u16, 65u16, 37u16, 92u16, 100u16]),
may: Vec::from([]),
systemmust: Vec::from([151u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl12/SCHEMA_CLASS_ACCOUNT_DL5.
pub fn dl12_class_account_dl5()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
uuid: 281470681743430u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 110u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
sync_allowed: true,
systemmay: Vec::from([1u16, 3u16, 101u16, 67u16]),
may: Vec::from([]),
systemmust: Vec::from([39u16, 151u16]),
must: Vec::from([]),
systemsupplements: Vec::from([6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 22u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl12/SCHEMA_CLASS_SERVICE_ACCOUNT_DL7, dl13/SCHEMA_CLASS_SERVICE_ACCOUNT_DL7, dl14/SCHEMA_CLASS_SERVICE_ACCOUNT_DL7, dl15/SCHEMA_CLASS_SERVICE_ACCOUNT_DL7, dl_1_12/SCHEMA_CLASS_SERVICE_ACCOUNT_DL7.
pub fn dl12_class_service_account_dl7()->ClassRecord{
 ClassRecord{
name: Vec::from([115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
uuid: 281470681743622u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
sync_allowed: true,
systemmay: Vec::from([152u16, 174u16, 128u16, 113u16, 37u16, 92u16, 138u16, 17u16]),
may: Vec::from([]),
systemmust: Vec::from([100u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl12/SCHEMA_CLASS_OAUTH2_RS_DL9.
pub fn dl12_class_oauth2_rs_dl9()->ClassRecord{
 ClassRecord{
name: Vec::from([111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8]),
uuid: 281470681743493u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 32u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 101u8, 100u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 67u8, 108u8, 105u8, 101u8, 110u8, 116u8]),
sync_allowed: false,
systemmay: Vec::from([37u16, 125u16, 126u16, 115u16, 116u16, 70u16, 120u16, 128u16, 123u16, 129u16, 114u16, 145u16, 127u16, 60u16]),
may: Vec::from([]),
systemmust: Vec::from([124u16, 100u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl12/SCHEMA_CLASS_OAUTH2_CLIENT, dl13/SCHEMA_CLASS_OAUTH2_CLIENT, dl14/SCHEMA_CLASS_OAUTH2_CLIENT.
pub fn dl12_class_oauth2_client()->ClassRecord{
 ClassRecord{
name: Vec::from([111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8]),
uuid: 281470681743888u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 32u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 101u8, 100u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 67u8, 111u8, 110u8, 102u8, 105u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 32u8, 67u8, 108u8, 105u8, 101u8, 110u8, 116u8, 32u8, 97u8, 99u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 115u8, 32u8, 97u8, 110u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([100u16, 110u16, 111u16, 109u16, 130u16, 118u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl12/SCHEMA_CLASS_KEY_OBJECT_HKDF_S256, dl13/SCHEMA_CLASS_KEY_OBJECT_HKDF_S256, dl14/SCHEMA_CLASS_KEY_OBJECT_HKDF_S256, dl15/SCHEMA_CLASS_KEY_OBJECT_HKDF_S256, dl_1_12/SCHEMA_CLASS_KEY_OBJECT_HKDF_S256.
pub fn dl12_class_key_object_hkdf_s256()->ClassRecord{
 ClassRecord{
name: Vec::from([107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 104u8, 107u8, 100u8, 102u8, 95u8, 115u8, 50u8, 53u8, 54u8]),
uuid: 281470681743765u128,
description: Vec::from([65u8, 32u8, 109u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 105u8, 110u8, 100u8, 105u8, 99u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 107u8, 101u8, 121u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 109u8, 117u8, 115u8, 116u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 32u8, 104u8, 109u8, 97u8, 99u8, 32u8, 107u8, 100u8, 102u8, 32u8, 115u8, 104u8, 97u8, 50u8, 53u8, 54u8, 32u8, 99u8, 97u8, 112u8, 97u8, 98u8, 105u8, 108u8, 105u8, 116u8, 121u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([10u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl12/SCHEMA_CLASS_OUTBOUND_MESSAGE, dl13/SCHEMA_CLASS_OUTBOUND_MESSAGE, dl14/SCHEMA_CLASS_OUTBOUND_MESSAGE, dl15/SCHEMA_CLASS_OUTBOUND_MESSAGE, dl_1_12/SCHEMA_CLASS_OUTBOUND_MESSAGE.
pub fn dl12_class_outbound_message()->ClassRecord{
 ClassRecord{
name: Vec::from([111u8, 117u8, 116u8, 98u8, 111u8, 117u8, 110u8, 100u8, 95u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8]),
uuid: 281470681743873u128,
description: Vec::from([65u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 32u8, 109u8, 101u8, 115u8, 115u8, 97u8, 103u8, 101u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 105u8, 115u8, 32u8, 116u8, 111u8, 32u8, 98u8, 101u8, 32u8, 115u8, 101u8, 110u8, 116u8, 32u8, 101u8, 120u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 108u8, 121u8, 32u8, 116u8, 111u8, 32u8, 97u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 105u8, 110u8, 32u8, 115u8, 111u8, 109u8, 101u8, 32u8, 119u8, 97u8, 121u8, 44u8, 32u8, 103u8, 101u8, 110u8, 101u8, 114u8, 97u8, 108u8, 108u8, 121u8, 32u8, 118u8, 105u8, 97u8, 32u8, 101u8, 109u8, 97u8, 105u8, 108u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([149u16, 93u16]),
may: Vec::from([]),
systemmust: Vec::from([97u16, 148u16, 35u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl12/SCHEMA_CLASS_FEATURE, dl13/SCHEMA_CLASS_FEATURE, dl14/SCHEMA_CLASS_FEATURE, dl15/SCHEMA_CLASS_FEATURE, dl_1_12/SCHEMA_CLASS_FEATURE.
pub fn dl12_class_feature()->ClassRecord{
 ClassRecord{
name: Vec::from([102u8, 101u8, 97u8, 116u8, 117u8, 114u8, 101u8]),
uuid: 281470681743892u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 101u8, 32u8, 115u8, 116u8, 97u8, 116u8, 101u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 102u8, 101u8, 97u8, 116u8, 117u8, 114u8, 101u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([56u16]),
may: Vec::from([]),
systemmust: Vec::from([100u16, 37u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl12/SCHEMA_CLASS_MEMORIAL, dl13/SCHEMA_CLASS_MEMORIAL, dl14/SCHEMA_CLASS_MEMORIAL, dl15/SCHEMA_CLASS_MEMORIAL, dl_1_12/SCHEMA_CLASS_MEMORIAL.
pub fn dl12_class_memorial()->ClassRecord{
 ClassRecord{
name: Vec::from([109u8, 101u8, 109u8, 111u8, 114u8, 105u8, 97u8, 108u8]),
uuid: 281470681743893u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 32u8, 109u8, 101u8, 109u8, 111u8, 114u8, 105u8, 97u8, 108u8, 32u8, 116u8, 111u8, 32u8, 97u8, 110u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 104u8, 97u8, 115u8, 32u8, 98u8, 101u8, 101u8, 110u8, 32u8, 100u8, 101u8, 108u8, 101u8, 116u8, 101u8, 100u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([67u16]),
may: Vec::from([]),
systemmust: Vec::from([71u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl13/SCHEMA_ATTR_ACCOUNT_SOFTLOCK_EXPIRE, dl14/SCHEMA_ATTR_ACCOUNT_SOFTLOCK_EXPIRE, dl15/SCHEMA_ATTR_ACCOUNT_SOFTLOCK_EXPIRE, dl_1_12/SCHEMA_ATTR_ACCOUNT_SOFTLOCK_EXPIRE.
pub fn dl13_attr_account_softlock_expire()->AttributeRecord{
 AttributeRecord{
name: 2u16,
uuid: 281470681743906u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 97u8, 116u8, 101u8, 116u8, 105u8, 109u8, 101u8, 32u8, 97u8, 102u8, 116u8, 101u8, 114u8, 32u8, 119u8, 104u8, 105u8, 99u8, 104u8, 32u8, 115u8, 111u8, 102u8, 116u8, 108u8, 111u8, 99u8, 107u8, 115u8, 32u8, 110u8, 111u8, 32u8, 108u8, 111u8, 110u8, 103u8, 101u8, 114u8, 32u8, 97u8, 114u8, 101u8, 32u8, 118u8, 97u8, 108u8, 105u8, 100u8, 32u8, 45u8, 32u8, 97u8, 108u8, 108u8, 111u8, 119u8, 115u8, 32u8, 116u8, 104u8, 101u8, 109u8, 32u8, 116u8, 111u8, 32u8, 98u8, 101u8, 32u8, 114u8, 101u8, 115u8, 101u8, 116u8, 32u8, 102u8, 114u8, 111u8, 109u8, 32u8, 39u8, 110u8, 111u8, 119u8, 39u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: false,
syntax: 16u16,
}
}

/// Exact complete record for dl13/SCHEMA_ATTR_OAUTH2_ACCOUNT_PROVIDER, dl14/SCHEMA_ATTR_OAUTH2_ACCOUNT_PROVIDER, dl15/SCHEMA_ATTR_OAUTH2_ACCOUNT_PROVIDER, dl_1_12/SCHEMA_ATTR_OAUTH2_ACCOUNT_PROVIDER.
pub fn dl13_attr_oauth2_account_provider()->AttributeRecord{
 AttributeRecord{
name: 104u16,
uuid: 281470681743889u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 114u8, 101u8, 102u8, 101u8, 114u8, 101u8, 110u8, 99u8, 101u8, 32u8, 116u8, 111u8, 32u8, 116u8, 104u8, 101u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 115u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 102u8, 111u8, 114u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 101u8, 110u8, 116u8, 114u8, 121u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: false,
syntax: 6u16,
}
}

/// Exact complete record for dl13/SCHEMA_ATTR_OAUTH2_ACCOUNT_UNIQUE_USER_ID, dl14/SCHEMA_ATTR_OAUTH2_ACCOUNT_UNIQUE_USER_ID, dl15/SCHEMA_ATTR_OAUTH2_ACCOUNT_UNIQUE_USER_ID, dl_1_12/SCHEMA_ATTR_OAUTH2_ACCOUNT_UNIQUE_USER_ID.
pub fn dl13_attr_oauth2_account_unique_user_id()->AttributeRecord{
 AttributeRecord{
name: 105u16,
uuid: 281470681743874u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 117u8, 110u8, 105u8, 113u8, 117u8, 101u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 105u8, 100u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 97u8, 115u8, 32u8, 107u8, 110u8, 111u8, 119u8, 110u8, 32u8, 98u8, 121u8, 32u8, 116u8, 104u8, 101u8, 32u8, 114u8, 101u8, 109u8, 111u8, 116u8, 101u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: false,
syntax: 0u16,
}
}

/// Exact complete record for dl13/SCHEMA_ATTR_OAUTH2_CONSENT_PROMPT_ENABLE, dl14/SCHEMA_ATTR_OAUTH2_CONSENT_PROMPT_ENABLE, dl15/SCHEMA_ATTR_OAUTH2_CONSENT_PROMPT_ENABLE, dl_1_12/SCHEMA_ATTR_OAUTH2_CONSENT_PROMPT_ENABLE.
pub fn dl13_attr_oauth2_consent_prompt_enable()->AttributeRecord{
 AttributeRecord{
name: 112u16,
uuid: 281470681743895u128,
description: Vec::from([69u8, 110u8, 97u8, 98u8, 108u8, 101u8, 32u8, 116u8, 104u8, 101u8, 32u8, 99u8, 111u8, 110u8, 115u8, 101u8, 110u8, 116u8, 32u8, 112u8, 114u8, 111u8, 109u8, 112u8, 116u8, 32u8, 119u8, 104u8, 101u8, 110u8, 32u8, 97u8, 117u8, 116u8, 104u8, 111u8, 114u8, 105u8, 115u8, 105u8, 110u8, 103u8, 32u8, 102u8, 111u8, 114u8, 32u8, 116u8, 104u8, 101u8, 32u8, 102u8, 105u8, 114u8, 115u8, 116u8, 32u8, 116u8, 105u8, 109u8, 101u8, 32u8, 111u8, 114u8, 32u8, 119u8, 104u8, 101u8, 110u8, 32u8, 115u8, 99u8, 111u8, 112u8, 101u8, 115u8, 32u8, 99u8, 104u8, 97u8, 110u8, 103u8, 101u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl13/SCHEMA_ATTR_S256, dl14/SCHEMA_ATTR_S256.
pub fn dl13_attr_s256()->AttributeRecord{
 AttributeRecord{
name: 146u16,
uuid: 281470681743897u128,
description: Vec::from([65u8, 32u8, 83u8, 104u8, 97u8, 50u8, 53u8, 54u8, 32u8, 111u8, 117u8, 116u8, 112u8, 117u8, 116u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 44u16,
}
}

/// Exact complete record for dl13/SCHEMA_CLASS_PERSON_DL8.
pub fn dl13_class_person_dl8()->ClassRecord{
 ClassRecord{
name: Vec::from([112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
uuid: 281470681743428u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
sync_allowed: true,
systemmay: Vec::from([138u16, 133u16, 20u16, 34u16, 152u16, 141u16, 113u16, 174u16, 128u16, 92u16, 87u16, 18u16]),
may: Vec::from([]),
systemmust: Vec::from([100u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 11u8, 0u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl13/SCHEMA_CLASS_ACCOUNT_DL5, dl14/SCHEMA_CLASS_ACCOUNT_DL5, dl15/SCHEMA_CLASS_ACCOUNT_DL5, dl_1_12/SCHEMA_CLASS_ACCOUNT_DL5.
pub fn dl13_class_account_dl5()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
uuid: 281470681743430u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 110u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
sync_allowed: true,
systemmay: Vec::from([1u16, 3u16, 101u16, 67u16, 2u16]),
may: Vec::from([]),
systemmust: Vec::from([39u16, 151u16]),
must: Vec::from([]),
systemsupplements: Vec::from([6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8, 15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 22u8, 0u8, 111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl13/SCHEMA_CLASS_OAUTH2_RS_DL9.
pub fn dl13_class_oauth2_rs_dl9()->ClassRecord{
 ClassRecord{
name: Vec::from([111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8]),
uuid: 281470681743493u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 32u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 101u8, 100u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 67u8, 108u8, 105u8, 101u8, 110u8, 116u8]),
sync_allowed: false,
systemmay: Vec::from([37u16, 125u16, 126u16, 115u16, 116u16, 70u16, 120u16, 128u16, 123u16, 129u16, 114u16, 112u16, 145u16, 127u16, 60u16]),
may: Vec::from([]),
systemmust: Vec::from([124u16, 100u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl13/SCHEMA_CLASS_KEY_OBJECT_JWT_HS256_DL6, dl14/SCHEMA_CLASS_KEY_OBJECT_JWT_HS256_DL6, dl15/SCHEMA_CLASS_KEY_OBJECT_JWT_HS256_DL6, dl_1_12/SCHEMA_CLASS_KEY_OBJECT_JWT_HS256_DL6.
pub fn dl13_class_key_object_jwt_hs256_dl6()->ClassRecord{
 ClassRecord{
name: Vec::from([107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 116u8, 95u8, 104u8, 115u8, 50u8, 53u8, 54u8]),
uuid: 281470681743904u128,
description: Vec::from([65u8, 32u8, 109u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 105u8, 110u8, 100u8, 105u8, 99u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 107u8, 101u8, 121u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 109u8, 117u8, 115u8, 116u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 32u8, 106u8, 119u8, 116u8, 32u8, 104u8, 115u8, 50u8, 53u8, 54u8, 32u8, 99u8, 97u8, 112u8, 97u8, 98u8, 105u8, 108u8, 105u8, 116u8, 121u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([10u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl13/SCHEMA_CLASS_ASSERTION_NONCE, dl14/SCHEMA_CLASS_ASSERTION_NONCE, dl15/SCHEMA_CLASS_ASSERTION_NONCE, dl_1_12/SCHEMA_CLASS_ASSERTION_NONCE.
pub fn dl13_class_assertion_nonce()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 115u8, 115u8, 101u8, 114u8, 116u8, 105u8, 111u8, 110u8, 95u8, 110u8, 111u8, 110u8, 99u8, 101u8]),
uuid: 281470681743905u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 101u8, 32u8, 110u8, 111u8, 110u8, 99u8, 101u8, 32u8, 116u8, 105u8, 101u8, 100u8, 32u8, 116u8, 111u8, 32u8, 97u8, 110u8, 32u8, 97u8, 115u8, 115u8, 101u8, 114u8, 116u8, 105u8, 111u8, 110u8, 32u8, 101u8, 118u8, 101u8, 110u8, 116u8, 32u8, 115u8, 111u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 105u8, 116u8, 32u8, 105u8, 115u8, 32u8, 111u8, 110u8, 108u8, 121u8, 32u8, 97u8, 112u8, 112u8, 108u8, 105u8, 101u8, 100u8, 32u8, 111u8, 110u8, 99u8, 101u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([175u16, 146u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl14/SCHEMA_ATTR_PASSWORD_CHANGED_TIME, dl15/SCHEMA_ATTR_PASSWORD_CHANGED_TIME, dl_1_12/SCHEMA_ATTR_PASSWORD_CHANGED_TIME.
pub fn dl14_attr_password_changed_time()->AttributeRecord{
 AttributeRecord{
name: 134u16,
uuid: 281470681743907u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 116u8, 105u8, 109u8, 101u8, 32u8, 119u8, 104u8, 101u8, 110u8, 32u8, 116u8, 104u8, 101u8, 32u8, 112u8, 97u8, 115u8, 115u8, 119u8, 111u8, 114u8, 100u8, 32u8, 119u8, 97u8, 115u8, 32u8, 108u8, 97u8, 115u8, 116u8, 32u8, 99u8, 104u8, 97u8, 110u8, 103u8, 101u8, 100u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 16u16,
}
}

/// Exact complete record for dl14/SCHEMA_ATTR_OAUTH2_REFRESH_TOKEN_EXPIRY, dl15/SCHEMA_ATTR_OAUTH2_REFRESH_TOKEN_EXPIRY, dl_1_12/SCHEMA_ATTR_OAUTH2_REFRESH_TOKEN_EXPIRY.
pub fn dl14_attr_oauth2_refresh_token_expiry()->AttributeRecord{
 AttributeRecord{
name: 117u16,
uuid: 281470681743909u128,
description: Vec::from([68u8, 101u8, 102u8, 105u8, 110u8, 101u8, 115u8, 32u8, 116u8, 104u8, 101u8, 32u8, 100u8, 117u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 105u8, 110u8, 32u8, 115u8, 101u8, 99u8, 111u8, 110u8, 100u8, 115u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 97u8, 32u8, 114u8, 101u8, 102u8, 114u8, 101u8, 115u8, 104u8, 32u8, 116u8, 111u8, 107u8, 101u8, 110u8, 32u8, 105u8, 115u8, 32u8, 118u8, 97u8, 108u8, 105u8, 100u8, 32u8, 102u8, 111u8, 114u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 12u16,
}
}

/// Exact complete record for dl14/SCHEMA_ATTR_KEY_INTERNAL_DATA_DL6, dl15/SCHEMA_ATTR_KEY_INTERNAL_DATA_DL6, dl_1_12/SCHEMA_ATTR_KEY_INTERNAL_DATA_DL6.
pub fn dl14_attr_key_internal_data_dl6()->AttributeRecord{
 AttributeRecord{
name: 79u16,
uuid: 281470681743721u128,
description: Vec::from([73u8, 110u8, 116u8, 101u8, 114u8, 110u8, 97u8, 108u8, 32u8, 75u8, 101u8, 121u8, 32u8, 68u8, 97u8, 116u8, 97u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 38u16,
}
}

/// Exact complete record for dl14/SCHEMA_ATTR_KEY_PROVIDER_DL6, dl15/SCHEMA_ATTR_KEY_PROVIDER_DL6, dl_1_12/SCHEMA_ATTR_KEY_PROVIDER_DL6.
pub fn dl14_attr_key_provider_dl6()->AttributeRecord{
 AttributeRecord{
name: 80u16,
uuid: 281470681743728u128,
description: Vec::from([67u8, 114u8, 121u8, 112u8, 116u8, 111u8, 103u8, 114u8, 97u8, 112u8, 104u8, 105u8, 99u8, 32u8, 75u8, 101u8, 121u8, 32u8, 80u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: true,
syntax: 6u16,
}
}

/// Exact complete record for dl14/SCHEMA_ATTR_KEY_ACTION_ROTATE_DL6, dl15/SCHEMA_ATTR_KEY_ACTION_ROTATE_DL6, dl_1_12/SCHEMA_ATTR_KEY_ACTION_ROTATE_DL6.
pub fn dl14_attr_key_action_rotate_dl6()->AttributeRecord{
 AttributeRecord{
name: 78u16,
uuid: 281470681743730u128,
description: Vec::from([77u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 100u8, 101u8, 110u8, 111u8, 116u8, 101u8, 115u8, 32u8, 97u8, 32u8, 107u8, 101u8, 121u8, 32u8, 114u8, 111u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 115u8, 104u8, 111u8, 117u8, 108u8, 100u8, 32u8, 111u8, 99u8, 99u8, 117u8, 114u8, 46u8]),
multivalue: false,
unique: false,
phantom: true,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 16u16,
}
}

/// Exact complete record for dl14/SCHEMA_ATTR_KEY_ACTION_REVOKE_DL6, dl15/SCHEMA_ATTR_KEY_ACTION_REVOKE_DL6, dl_1_12/SCHEMA_ATTR_KEY_ACTION_REVOKE_DL6.
pub fn dl14_attr_key_action_revoke_dl6()->AttributeRecord{
 AttributeRecord{
name: 77u16,
uuid: 281470681743729u128,
description: Vec::from([77u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 100u8, 101u8, 110u8, 111u8, 116u8, 101u8, 115u8, 32u8, 97u8, 32u8, 107u8, 101u8, 121u8, 32u8, 115u8, 104u8, 111u8, 117u8, 108u8, 100u8, 32u8, 98u8, 101u8, 32u8, 114u8, 101u8, 118u8, 111u8, 107u8, 101u8, 100u8, 46u8]),
multivalue: true,
unique: false,
phantom: true,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 39u16,
}
}

/// Exact complete record for dl14/SCHEMA_ATTR_KEY_ACTION_IMPORT_JWS_ES256_DL6, dl15/SCHEMA_ATTR_KEY_ACTION_IMPORT_JWS_ES256_DL6, dl_1_12/SCHEMA_ATTR_KEY_ACTION_IMPORT_JWS_ES256_DL6.
pub fn dl14_attr_key_action_import_jws_es256_dl6()->AttributeRecord{
 AttributeRecord{
name: 75u16,
uuid: 281470681743731u128,
description: Vec::from([77u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 100u8, 101u8, 110u8, 111u8, 116u8, 101u8, 115u8, 32u8, 97u8, 32u8, 106u8, 119u8, 115u8, 32u8, 101u8, 115u8, 50u8, 53u8, 54u8, 32u8, 107u8, 101u8, 121u8, 32u8, 116u8, 111u8, 32u8, 98u8, 101u8, 32u8, 105u8, 109u8, 112u8, 111u8, 114u8, 116u8, 101u8, 100u8, 46u8]),
multivalue: true,
unique: false,
phantom: true,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 21u16,
}
}

/// Exact complete record for dl14/SCHEMA_ATTR_KEY_ACTION_IMPORT_JWS_RS256_DL6, dl15/SCHEMA_ATTR_KEY_ACTION_IMPORT_JWS_RS256_DL6, dl_1_12/SCHEMA_ATTR_KEY_ACTION_IMPORT_JWS_RS256_DL6.
pub fn dl14_attr_key_action_import_jws_rs256_dl6()->AttributeRecord{
 AttributeRecord{
name: 76u16,
uuid: 281470681743761u128,
description: Vec::from([77u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 97u8, 116u8, 116u8, 114u8, 105u8, 98u8, 117u8, 116u8, 101u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 100u8, 101u8, 110u8, 111u8, 116u8, 101u8, 115u8, 32u8, 97u8, 32u8, 106u8, 119u8, 115u8, 32u8, 114u8, 115u8, 50u8, 53u8, 54u8, 32u8, 107u8, 101u8, 121u8, 32u8, 116u8, 111u8, 32u8, 98u8, 101u8, 32u8, 105u8, 109u8, 112u8, 111u8, 114u8, 116u8, 101u8, 100u8, 46u8]),
multivalue: true,
unique: false,
phantom: true,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 21u16,
}
}

/// Exact complete record for dl14/SCHEMA_ATTR_PATCH_LEVEL_DL7, dl15/SCHEMA_ATTR_PATCH_LEVEL_DL7, dl_1_12/SCHEMA_ATTR_PATCH_LEVEL_DL7.
pub fn dl14_attr_patch_level_dl7()->AttributeRecord{
 AttributeRecord{
name: 136u16,
uuid: 281470681743733u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 39u8, 115u8, 32u8, 112u8, 97u8, 116u8, 99u8, 104u8, 32u8, 108u8, 101u8, 118u8, 101u8, 108u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 12u16,
}
}

/// Exact complete record for dl14/SCHEMA_ATTR_DOMAIN_ALLOW_ACCOUNT_RECOVERY, dl15/SCHEMA_ATTR_DOMAIN_ALLOW_ACCOUNT_RECOVERY, dl_1_12/SCHEMA_ATTR_DOMAIN_ALLOW_ACCOUNT_RECOVERY.
pub fn dl14_attr_domain_allow_account_recovery()->AttributeRecord{
 AttributeRecord{
name: 42u16,
uuid: 281470681743908u128,
description: Vec::from([65u8, 32u8, 102u8, 108u8, 97u8, 103u8, 32u8, 116u8, 111u8, 32u8, 101u8, 110u8, 97u8, 98u8, 108u8, 101u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 114u8, 101u8, 99u8, 111u8, 118u8, 101u8, 114u8, 121u8, 32u8, 114u8, 101u8, 113u8, 117u8, 101u8, 115u8, 116u8, 115u8, 32u8, 116u8, 111u8, 32u8, 98u8, 101u8, 32u8, 115u8, 117u8, 98u8, 109u8, 105u8, 116u8, 116u8, 101u8, 100u8, 32u8, 98u8, 121u8, 32u8, 117u8, 115u8, 101u8, 114u8, 115u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 3u16,
}
}

/// Exact complete record for dl14/SCHEMA_CLASS_PERSON_DL14, dl15/SCHEMA_CLASS_PERSON_DL14, dl_1_12/SCHEMA_CLASS_PERSON_DL14.
pub fn dl14_class_person_dl14()->ClassRecord{
 ClassRecord{
name: Vec::from([112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
uuid: 281470681743428u128,
description: Vec::from([79u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 111u8, 102u8, 32u8, 97u8, 32u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
sync_allowed: true,
systemmay: Vec::from([138u16, 133u16, 20u16, 34u16, 152u16, 141u16, 113u16, 174u16, 128u16, 92u16, 87u16, 18u16, 134u16]),
may: Vec::from([]),
systemmust: Vec::from([100u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([15u8, 0u8, 115u8, 101u8, 114u8, 118u8, 105u8, 99u8, 101u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 11u8, 0u8, 97u8, 112u8, 112u8, 108u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl14/SCHEMA_CLASS_DOMAIN_INFO_DL10, dl15/SCHEMA_CLASS_DOMAIN_INFO_DL10, dl_1_12/SCHEMA_CLASS_DOMAIN_INFO_DL10.
pub fn dl14_class_domain_info_dl10()->ClassRecord{
 ClassRecord{
name: Vec::from([100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 95u8, 105u8, 110u8, 102u8, 111u8]),
uuid: 281470681743442u128,
description: Vec::from([76u8, 111u8, 99u8, 97u8, 108u8, 32u8, 100u8, 111u8, 109u8, 97u8, 105u8, 110u8, 32u8, 105u8, 110u8, 102u8, 111u8, 114u8, 109u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 97u8, 110u8, 100u8, 32u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
sync_allowed: false,
systemmay: Vec::from([48u16, 46u16, 85u16, 82u16, 70u16, 136u16, 44u16, 43u16, 42u16, 45u16]),
may: Vec::from([]),
systemmust: Vec::from([100u16, 50u16, 47u16, 176u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl14/SCHEMA_CLASS_OAUTH2_RS_DL9, dl15/SCHEMA_CLASS_OAUTH2_RS_DL9, dl_1_12/SCHEMA_CLASS_OAUTH2_RS_DL9.
pub fn dl14_class_oauth2_rs_dl9()->ClassRecord{
 ClassRecord{
name: Vec::from([111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 114u8, 101u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8, 95u8, 115u8, 101u8, 114u8, 118u8, 101u8, 114u8]),
uuid: 281470681743493u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 32u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 101u8, 100u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 67u8, 108u8, 105u8, 101u8, 110u8, 116u8]),
sync_allowed: false,
systemmay: Vec::from([37u16, 125u16, 126u16, 115u16, 116u16, 117u16, 70u16, 120u16, 128u16, 123u16, 129u16, 114u16, 112u16, 145u16, 127u16, 60u16]),
may: Vec::from([]),
systemmust: Vec::from([124u16, 100u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl15/SCHEMA_ATTR_OAUTH2_ACCOUNT_UNIQUE_USER_SUB, dl_1_12/SCHEMA_ATTR_OAUTH2_ACCOUNT_UNIQUE_USER_SUB.
pub fn dl15_attr_oauth2_account_unique_user_sub()->AttributeRecord{
 AttributeRecord{
name: 106u16,
uuid: 281470681743910u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 117u8, 110u8, 105u8, 113u8, 117u8, 101u8, 32u8, 117u8, 115u8, 101u8, 114u8, 32u8, 115u8, 117u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 97u8, 115u8, 32u8, 107u8, 110u8, 111u8, 119u8, 110u8, 32u8, 98u8, 121u8, 32u8, 116u8, 104u8, 101u8, 32u8, 114u8, 101u8, 109u8, 111u8, 116u8, 101u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8, 46u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: true,
replicated: true,
indexed: false,
syntax: 0u16,
}
}

/// Exact complete record for dl15/SCHEMA_ATTR_OAUTH2_TOKEN_INTROSPECT_ENDPOINT, dl_1_12/SCHEMA_ATTR_OAUTH2_TOKEN_INTROSPECT_ENDPOINT.
pub fn dl15_attr_oauth2_token_introspect_endpoint()->AttributeRecord{
 AttributeRecord{
name: 131u16,
uuid: 281470681743911u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 114u8, 102u8, 99u8, 55u8, 54u8, 54u8, 50u8, 32u8, 116u8, 111u8, 107u8, 101u8, 110u8, 32u8, 105u8, 110u8, 116u8, 114u8, 111u8, 115u8, 112u8, 101u8, 99u8, 116u8, 32u8, 117u8, 114u8, 108u8, 32u8, 111u8, 102u8, 32u8, 116u8, 104u8, 101u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 114u8]),
multivalue: false,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 18u16,
}
}

/// Exact complete record for dl15/SCHEMA_ATTR_S256, dl_1_12/SCHEMA_ATTR_S256.
pub fn dl15_attr_s256()->AttributeRecord{
 AttributeRecord{
name: 146u16,
uuid: 281470681743897u128,
description: Vec::from([65u8, 32u8, 83u8, 104u8, 97u8, 50u8, 53u8, 54u8, 32u8, 111u8, 117u8, 116u8, 112u8, 117u8, 116u8, 46u8]),
multivalue: true,
unique: false,
phantom: false,
sync_allowed: false,
replicated: true,
indexed: false,
syntax: 44u16,
}
}

/// Exact complete record for dl15/SCHEMA_CLASS_OAUTH2_ACCOUNT, dl_1_12/SCHEMA_CLASS_OAUTH2_ACCOUNT.
pub fn dl15_class_oauth2_account()->ClassRecord{
 ClassRecord{
name: Vec::from([111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8]),
uuid: 281470681743881u128,
description: Vec::from([77u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 100u8, 101u8, 115u8, 105u8, 103u8, 110u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 97u8, 110u8, 32u8, 99u8, 97u8, 110u8, 32u8, 117u8, 115u8, 101u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 102u8, 111u8, 114u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 46u8]),
sync_allowed: true,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([104u16, 105u16, 106u16, 103u16]),
must: Vec::from([]),
systemsupplements: Vec::from([6u8, 0u8, 112u8, 101u8, 114u8, 115u8, 111u8, 110u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl15/SCHEMA_CLASS_OAUTH2_CLIENT, dl_1_12/SCHEMA_CLASS_OAUTH2_CLIENT.
pub fn dl15_class_oauth2_client()->ClassRecord{
 ClassRecord{
name: Vec::from([111u8, 97u8, 117u8, 116u8, 104u8, 50u8, 95u8, 99u8, 108u8, 105u8, 101u8, 110u8, 116u8]),
uuid: 281470681743888u128,
description: Vec::from([84u8, 104u8, 101u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 32u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 117u8, 114u8, 101u8, 100u8, 32u8, 79u8, 65u8, 117u8, 116u8, 104u8, 50u8, 32u8, 67u8, 111u8, 110u8, 102u8, 105u8, 100u8, 101u8, 110u8, 116u8, 105u8, 97u8, 108u8, 32u8, 67u8, 108u8, 105u8, 101u8, 110u8, 116u8, 32u8, 97u8, 99u8, 116u8, 105u8, 110u8, 103u8, 32u8, 97u8, 115u8, 32u8, 97u8, 110u8, 32u8, 97u8, 117u8, 116u8, 104u8, 101u8, 110u8, 116u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8, 32u8, 115u8, 111u8, 117u8, 114u8, 99u8, 101u8]),
sync_allowed: false,
systemmay: Vec::from([131u16]),
may: Vec::from([]),
systemmust: Vec::from([100u16, 110u16, 111u16, 109u16, 130u16, 118u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl_1_12/SCHEMA_CLASS_KEY_OBJECT_JWE_A128GCM_DL6.
pub fn dl_1_12_class_key_object_jwe_a128gcm_dl6()->ClassRecord{
 ClassRecord{
name: Vec::from([107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 101u8, 95u8, 97u8, 49u8, 50u8, 56u8, 103u8, 99u8, 109u8]),
uuid: 281470681743732u128,
description: Vec::from([65u8, 32u8, 109u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 105u8, 110u8, 100u8, 105u8, 99u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 107u8, 101u8, 121u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 109u8, 117u8, 115u8, 116u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 32u8, 106u8, 119u8, 101u8, 32u8, 97u8, 101u8, 115u8, 45u8, 49u8, 50u8, 56u8, 45u8, 103u8, 99u8, 109u8, 32u8, 99u8, 97u8, 112u8, 97u8, 98u8, 105u8, 108u8, 105u8, 116u8, 121u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([10u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl_1_12/SCHEMA_CLASS_KEY_OBJECT_JWE_A256GCM.
pub fn dl_1_12_class_key_object_jwe_a256gcm()->ClassRecord{
 ClassRecord{
name: Vec::from([107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 95u8, 106u8, 119u8, 101u8, 95u8, 97u8, 50u8, 53u8, 54u8, 103u8, 99u8, 109u8]),
uuid: 281470681743913u128,
description: Vec::from([65u8, 32u8, 109u8, 97u8, 114u8, 107u8, 101u8, 114u8, 32u8, 99u8, 108u8, 97u8, 115u8, 115u8, 32u8, 105u8, 110u8, 100u8, 105u8, 99u8, 97u8, 116u8, 105u8, 110u8, 103u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 116u8, 104u8, 105u8, 115u8, 32u8, 107u8, 101u8, 121u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8, 32u8, 109u8, 117u8, 115u8, 116u8, 32u8, 112u8, 114u8, 111u8, 118u8, 105u8, 100u8, 101u8, 32u8, 106u8, 119u8, 101u8, 32u8, 97u8, 101u8, 115u8, 45u8, 50u8, 53u8, 54u8, 45u8, 103u8, 99u8, 109u8, 32u8, 99u8, 97u8, 112u8, 97u8, 98u8, 105u8, 108u8, 105u8, 116u8, 121u8, 46u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([]),
must: Vec::from([]),
systemsupplements: Vec::from([10u8, 0u8, 107u8, 101u8, 121u8, 95u8, 111u8, 98u8, 106u8, 101u8, 99u8, 116u8]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}

/// Exact complete record for dl_1_12/SCHEMA_CLASS_ACCOUNT_SIGNUP_REQUEST.
pub fn dl_1_12_class_account_signup_request()->ClassRecord{
 ClassRecord{
name: Vec::from([97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 95u8, 115u8, 105u8, 103u8, 110u8, 117u8, 112u8, 95u8, 114u8, 101u8, 113u8, 117u8, 101u8, 115u8, 116u8]),
uuid: 281470681743912u128,
description: Vec::from([65u8, 32u8, 112u8, 101u8, 110u8, 100u8, 105u8, 110u8, 103u8, 32u8, 97u8, 99u8, 99u8, 111u8, 117u8, 110u8, 116u8, 32u8, 115u8, 105u8, 103u8, 110u8, 117u8, 112u8, 32u8, 114u8, 101u8, 113u8, 117u8, 101u8, 115u8, 116u8, 32u8, 116u8, 104u8, 97u8, 116u8, 32u8, 105u8, 115u8, 32u8, 112u8, 101u8, 110u8, 100u8, 105u8, 110u8, 103u8, 32u8, 114u8, 101u8, 118u8, 105u8, 101u8, 119u8, 32u8, 97u8, 110u8, 100u8, 47u8, 111u8, 114u8, 32u8, 118u8, 101u8, 114u8, 105u8, 102u8, 105u8, 99u8, 97u8, 116u8, 105u8, 111u8, 110u8]),
sync_allowed: false,
systemmay: Vec::from([]),
may: Vec::from([]),
systemmust: Vec::from([100u16, 39u16, 92u16, 35u16]),
must: Vec::from([]),
systemsupplements: Vec::from([]),
supplements: Vec::from([]),
systemexcludes: Vec::from([]),
excludes: Vec::from([]),
}
}
