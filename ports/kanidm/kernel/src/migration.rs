//! What migrations may touch (access/migration.rs).
use crate::bset::{bytes_eq, contains, insert};
use crate::Attribute;

/// `MIGRATION_ENTRY_CLASSES`.
pub fn migration_entry_classes(c: &[u8]) -> bool {
    bytes_eq(c, b"object")
        || bytes_eq(c, b"memberof")
        || bytes_eq(c, b"domain_info")
        || bytes_eq(c, b"oauth2_resource_server")
        || bytes_eq(c, b"oauth2_resource_server_basic")
        || bytes_eq(c, b"oauth2_resource_server_public")
        || bytes_eq(c, b"account")
        || bytes_eq(c, b"person")
        || bytes_eq(c, b"posixaccount")
        || bytes_eq(c, b"group")
        || bytes_eq(c, b"dyngroup")
        || bytes_eq(c, b"account_policy")
        || bytes_eq(c, b"posixgroup")
        || bytes_eq(c, b"service_account")
}

/// `MIGRATION_IGNORE_CLASSES`.
pub fn migration_ignore_classes(c: &[u8]) -> bool {
    bytes_eq(c, b"key_object")
        || bytes_eq(c, b"key_object_internal")
        || bytes_eq(c, b"key_object_hkdf_s256")
        || bytes_eq(c, b"key_object_jwt_es256")
        || bytes_eq(c, b"key_object_jwt_hs256")
        || bytes_eq(c, b"key_object_jwt_rs256")
        || bytes_eq(c, b"key_object_jwe_a128gcm")
}

/// `classes.sub(&MIGRATION_IGNORE_CLASSES)`.
pub fn sub_migration_ignore(classes: &[Vec<u8>]) -> Vec<Vec<u8>> {
    let mut out: Vec<Vec<u8>> = Vec::new();
    let mut i = 0;
    while i < classes.len() {
        let c = classes[i].clone();
        if !migration_ignore_classes(&c) {
            insert(&mut out, &c);
        }
        i += 1;
    }
    out
}

/// `classes.is_subset(&MIGRATION_ENTRY_CLASSES)`.
pub fn subset_migration_entry(classes: &[Vec<u8>]) -> bool {
    let mut i = 0;
    while i < classes.len() {
        if !migration_entry_classes(&classes[i]) {
            return false;
        }
        i += 1;
    }
    true
}

fn ins(set: &mut Vec<Attribute>, a: &[u8]) {
    insert(set, a);
}

/// `migration_entry_attrs`.
pub fn migration_entry_attrs(classes: &[Vec<u8>]) -> (Vec<Attribute>, Vec<Vec<u8>>) {
    let mut allow_attrs: Vec<Attribute> = Vec::new();
    let mut allow_cls: Vec<Vec<u8>> = Vec::new();

    // Base attributes to always allow
    ins(&mut allow_attrs, b"class");
    ins(&mut allow_attrs, b"uuid");

    if contains(classes, b"domain_info") {
        ins(&mut allow_attrs, b"domain_ldap_basedn");
        ins(&mut allow_attrs, b"ldap_max_queryable_attrs");
        ins(&mut allow_attrs, b"ldap_allow_unix_pw_bind");
        ins(&mut allow_attrs, b"domain_display_name");
    }

    if contains(classes, b"group") {
        allow_cls = Vec::new();
        ins(&mut allow_cls, b"group");
        ins(&mut allow_cls, b"account_policy");
        ins(&mut allow_cls, b"posixgroup");
        ins(&mut allow_attrs, b"member");
        ins(&mut allow_attrs, b"name");
        ins(&mut allow_attrs, b"description");
        ins(&mut allow_attrs, b"entry_managed_by");
        ins(&mut allow_attrs, b"gidnumber");
    }

    if contains(classes, b"person") {
        allow_cls = Vec::new();
        ins(&mut allow_cls, b"person");
        ins(&mut allow_cls, b"account");
        ins(&mut allow_cls, b"posixaccount");
        ins(&mut allow_attrs, b"name");
        ins(&mut allow_attrs, b"displayname");
        ins(&mut allow_attrs, b"legalname");
        ins(&mut allow_attrs, b"mail");
        ins(&mut allow_attrs, b"ssh_publickey");
        ins(&mut allow_attrs, b"description");
        ins(&mut allow_attrs, b"loginshell");
        ins(&mut allow_attrs, b"gidnumber");
    }

    if contains(classes, b"service_account") {
        allow_cls = Vec::new();
        ins(&mut allow_cls, b"account");
        ins(&mut allow_cls, b"service_account");
        ins(&mut allow_attrs, b"name");
        ins(&mut allow_attrs, b"displayname");
        ins(&mut allow_attrs, b"mail");
        ins(&mut allow_attrs, b"ssh_publickey");
        ins(&mut allow_attrs, b"description");
        ins(&mut allow_attrs, b"entry_managed_by");
    }

    if contains(classes, b"account_policy") {
        ins(&mut allow_attrs, b"authsession_expiry");
        ins(&mut allow_attrs, b"auth_password_minimum_length");
        ins(&mut allow_attrs, b"credential_type_minimum");
        ins(&mut allow_attrs, b"privilege_expiry");
        ins(&mut allow_attrs, b"webauthn_attestation_ca_list");
        ins(&mut allow_attrs, b"limit_search_max_results");
        ins(&mut allow_attrs, b"limit_search_max_filter_test");
        ins(&mut allow_attrs, b"allow_primary_cred_fallback");
    }

    if contains(classes, b"oauth2_resource_server") {
        allow_cls = Vec::new();
        ins(&mut allow_cls, b"account");
        ins(&mut allow_cls, b"oauth2_resource_server");
        ins(&mut allow_cls, b"oauth2_resource_server_basic");
        ins(&mut allow_cls, b"oauth2_resource_server_public");
        ins(&mut allow_attrs, b"name");
        ins(&mut allow_attrs, b"displayname");
        ins(&mut allow_attrs, b"description");
        ins(&mut allow_attrs, b"oauth2_rs_scope_map");
        ins(&mut allow_attrs, b"oauth2_rs_sup_scope_map");
        ins(&mut allow_attrs, b"oauth2_jwt_legacy_crypto_enable");
        ins(&mut allow_attrs, b"oauth2_prefer_short_username");
        ins(&mut allow_attrs, b"oauth2_rs_claim_map");
        ins(&mut allow_attrs, b"oauth2_rs_origin");
        ins(&mut allow_attrs, b"oauth2_rs_origin_landing");
        ins(&mut allow_attrs, b"oauth2_consent_prompt_enable");
        ins(&mut allow_attrs, b"entry_managed_by");
    }

    (allow_attrs, allow_cls)
}
