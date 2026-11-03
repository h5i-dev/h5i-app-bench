use super::*;
/// Builtin System Admin account.
pub static BUILTIN_ACCOUNT_IDM_ADMIN: BuiltinAccount = BuiltinAccount {
    account_type: AccountType::ServiceAccount,
    entry_managed_by: None,
    name: "idm_admin",
    uuid: UUID_IDM_ADMIN,
    description: "Builtin IDM Admin account.",
    displayname: "IDM Administrator",
};
/// Builtin System Admin account.
pub static BUILTIN_ACCOUNT_ADMIN: BuiltinAccount = BuiltinAccount {
    account_type: AccountType::ServiceAccount,
    entry_managed_by: None,
    name: "admin",
    uuid: UUID_ADMIN,
    description: "Builtin System Admin account.",
    displayname: "System Administrator",
};
pub static BUILTIN_ACCOUNT_ANONYMOUS_DL6: BuiltinAccount = BuiltinAccount {
    account_type: AccountType::ServiceAccount,
    entry_managed_by: Some(UUID_IDM_ADMINS),
    name: "anonymous",
    uuid: UUID_ANONYMOUS,
    description: "Anonymous access account.",
    displayname: "Anonymous",
};
pub(crate) fn e_key_provider_internal_dl6() -> EntryInitNew {
    entry_init_fn([
        (Attribute::Class, EntryClass::Object.to_value()),
        (Attribute::Class, EntryClass::KeyProvider.to_value()),
        (Attribute::Class, EntryClass::KeyProviderInternal.to_value()),
        (Attribute::Uuid, Value::Uuid(UUID_KEY_PROVIDER_INTERNAL)),
        (Attribute::Name, Value::new_iname("key_provider_internal")),
        (
            Attribute::Description,
            Value::new_utf8s("The default database internal cryptographic key provider."),
        ),
    ])
}
pub fn e_system_info_v1() -> EntryInitNew {
    entry_init_fn([
        (Attribute::Class, EntryClass::Object.to_value()),
        (Attribute::Class, EntryClass::SystemInfo.to_value()),
        (Attribute::Class, EntryClass::System.to_value()),
        (Attribute::Uuid, Value::Uuid(UUID_SYSTEM_INFO)),
        (
            Attribute::Description,
            Value::new_utf8s("System (local) info and metadata object."),
        ),
        (Attribute::Version, Value::Uint32(20)),
    ])
}
pub fn e_domain_info_dl6() -> EntryInitNew {
    entry_init_fn([
        (Attribute::Class, EntryClass::Object.to_value()),
        (Attribute::Class, EntryClass::DomainInfo.to_value()),
        (Attribute::Class, EntryClass::System.to_value()),
        (Attribute::Class, EntryClass::KeyObject.to_value()),
        (Attribute::Class, EntryClass::KeyObjectJwtEs256.to_value()),
        (Attribute::Class, EntryClass::KeyObjectJwtHs256.to_value()),
        (Attribute::Class, EntryClass::KeyObjectJweA128GCM.to_value()),
        (Attribute::Name, Value::new_iname("domain_local")),
        (Attribute::Uuid, Value::Uuid(UUID_DOMAIN_INFO)),
        (
            Attribute::Description,
            Value::new_utf8s("This local domain's info and metadata object."),
        ),
    ])
}
pub fn e_uuid_domain_id_verification_key_v1() -> EntryInitNew {
    entry_init_fn([
        (Attribute::Class, EntryClass::Object.to_value()),
        (Attribute::Class, EntryClass::KeyObject.to_value()),
        (Attribute::Class, EntryClass::KeyObjectHkdfS256.to_value()),
        (
            Attribute::Uuid,
            Value::Uuid(UUID_DOMAIN_ID_VERIFICATION_KEY),
        ),
        (
            Attribute::Description,
            Value::new_utf8s("The domain-local HMAC key used for user ID verification."),
        ),
    ])
}
pub fn e_hmac_name_history_feature() -> EntryInitNew {
    entry_init_fn([
        (Attribute::Class, EntryClass::Object.to_value()),
        (Attribute::Class, EntryClass::Feature.to_value()),
        (Attribute::Class, EntryClass::KeyObject.to_value()),
        (Attribute::Class, EntryClass::KeyObjectHkdfS256.to_value()),
        (Attribute::Uuid, Value::Uuid(UUID_HMAC_NAME_FEATURE)),
        (Attribute::Name, Value::new_iname("hmac_name_feature")),
        (
            Attribute::Description,
            Value::new_utf8s("Configuration of the HMAC Name History Feature."),
        ),
    ])
}
