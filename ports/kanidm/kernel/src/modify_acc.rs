//! Modify access (access/modify.rs).
use crate::bset::{extend, insert, intersection};
use crate::entry_impl::{get_ava_as_iutf8, get_ava_set, get_ava_single_refer};
use crate::identity_impl::{access_scope, get_memberof, get_uuid};
use crate::migration::{migration_entry_attrs, sub_migration_ignore, subset_migration_entry};
use crate::profiles::{AccessControlModifyResolved, ModifyGrants};
use crate::protected::{
    disjoint_locked_entry_classes, disjoint_protected_mod_entry_classes, remove_protected_mod_pres,
    remove_protected_mod_rem,
};
use crate::search_acc::acp_applies;
use crate::valueset::vs_contains;
use crate::{
    AccessBasicResult, AccessModResult, AccessScope, Attribute, Entry, IdentType, Identity, InternalRole,
    PartialValue, SyncAgreement, UUID_ANONYMOUS,
};

/// `ModifyResult`.
#[derive(Debug, PartialEq, Eq)]
pub enum ModifyResult {
    Deny,
    Grant,
    Allow {
        pres: Vec<Attribute>,
        rem: Vec<Attribute>,
        pres_cls: Vec<Vec<u8>>,
        rem_cls: Vec<Vec<u8>>,
    },
}

/// `apply_modify_access`.
pub fn apply_modify_access(
    ident: &Identity,
    related_acp: &[AccessControlModifyResolved],
    sync_agreements: &[SyncAgreement],
    entry: &Entry,
) -> ModifyResult {
    let mut denied = false;
    let mut grant = false;

    let mut constrain_pres: Vec<Attribute> = Vec::new();
    let mut allow_pres: Vec<Attribute> = Vec::new();
    let mut constrain_rem: Vec<Attribute> = Vec::new();
    let mut allow_rem: Vec<Attribute> = Vec::new();

    let mut constrain_pres_cls: Vec<Vec<u8>> = Vec::new();
    let mut allow_pres_cls: Vec<Vec<u8>> = Vec::new();

    let mut constrain_rem_cls: Vec<Vec<u8>> = Vec::new();
    let mut allow_rem_cls: Vec<Vec<u8>> = Vec::new();

    // Some useful references.
    //  - needed for checking entry manager conditions.
    let ident_memberof = get_memberof(ident);
    let ident_uuid = get_uuid(ident);

    match modify_ident_test(ident) {
        AccessBasicResult::Deny => denied = true,
        AccessBasicResult::Grant => grant = true,
        AccessBasicResult::Ignore => {}
    }

    // Check with protected if we should proceed.
    match modify_migration_attrs(ident, entry) {
        AccessModResult::Deny => denied = true,
        AccessModResult::Allow { pres_attr, rem_attr, pres_class, rem_class } => {
            extend(&mut allow_pres, &pres_attr);
            extend(&mut allow_rem, &rem_attr);
            extend(&mut allow_pres_cls, &pres_class);
            extend(&mut allow_rem_cls, &rem_class);
        }
        AccessModResult::Constrain { .. } | AccessModResult::Ignore => {}
    }

    // Check with protected if we should proceed.
    match modify_protected_attrs(ident, entry) {
        AccessModResult::Deny => denied = true,
        AccessModResult::Constrain { pres_attr, rem_attr, pres_cls, rem_cls } => {
            extend(&mut constrain_rem, &rem_attr);
            extend(&mut constrain_pres, &pres_attr);

            match pres_cls {
                Some(pres_cls) => extend(&mut constrain_pres_cls, &pres_cls),
                None => {}
            }

            match rem_cls {
                Some(rem_cls) => extend(&mut constrain_rem_cls, &rem_cls),
                None => {}
            }
        }
        AccessModResult::Allow { .. } | AccessModResult::Ignore => {}
    }

    if !grant && !denied {
        // If it's a sync entry, constrain it.
        match modify_sync_constrain(ident, entry, sync_agreements) {
            AccessModResult::Deny => denied = true,
            AccessModResult::Constrain { pres_attr, rem_attr, .. } => {
                extend(&mut constrain_rem, &rem_attr);
                extend(&mut constrain_pres, &pres_attr);
            }
            AccessModResult::Allow { .. } | AccessModResult::Ignore => {}
        }

        // Setup the acp's here
        let scoped_acp = modify_scoped_acp(related_acp, ident_memberof, ident_uuid, entry);

        match modify_pres_test(&scoped_acp) {
            AccessModResult::Deny => denied = true,
            AccessModResult::Ignore => {}
            AccessModResult::Constrain { .. } => {}
            AccessModResult::Allow { pres_attr, rem_attr, pres_class, rem_class } => {
                extend(&mut allow_pres, &pres_attr);
                extend(&mut allow_rem, &rem_attr);
                extend(&mut allow_pres_cls, &pres_class);
                extend(&mut allow_rem_cls, &rem_class);
            }
        }
    }

    if denied {
        ModifyResult::Deny
    } else if grant {
        ModifyResult::Grant
    } else {
        let allowed_pres = if constrain_pres.len() != 0 {
            intersection(&constrain_pres, &allow_pres)
        } else {
            allow_pres
        };

        let allowed_rem = if constrain_rem.len() != 0 {
            intersection(&constrain_rem, &allow_rem)
        } else {
            allow_rem
        };

        let allowed_pres_cls = if constrain_pres_cls.len() != 0 {
            intersection(&constrain_pres_cls, &allow_pres_cls)
        } else {
            allow_pres_cls
        };

        let allowed_rem_cls = if constrain_rem_cls.len() != 0 {
            intersection(&constrain_rem_cls, &allow_rem_cls)
        } else {
            allow_rem_cls
        };

        // Deny these classes from being part of any addition or removal to an entry
        let allowed_pres_cls = remove_protected_mod_pres(&allowed_pres_cls);
        let allowed_rem_cls = remove_protected_mod_rem(&allowed_rem_cls);

        ModifyResult::Allow {
            pres: allowed_pres,
            rem: allowed_rem,
            pres_cls: allowed_pres_cls,
            rem_cls: allowed_rem_cls,
        }
    }
}

/// The `filter_map(..).collect()` that builds `scoped_acp` in
/// `apply_modify_access`.
pub fn modify_scoped_acp(
    related_acp: &[AccessControlModifyResolved],
    ident_memberof: Option<&Vec<crate::Uuid>>,
    ident_uuid: crate::Uuid,
    entry: &Entry,
) -> Vec<ModifyGrants> {
    let mut scoped_acp: Vec<ModifyGrants> = Vec::new();
    let mut i = 0;
    while i < related_acp.len() {
        let acm = &related_acp[i];
        let ok = acp_applies(acm.receiver_condition, &acm.target_condition, ident_memberof, ident_uuid, entry);
        push_if(&mut scoped_acp, ok, &acm.acp);
        i += 1;
    }
    scoped_acp
}

/// `if ok { scoped_acp.push(g.clone()) }`.
pub fn push_if(scoped_acp: &mut Vec<ModifyGrants>, ok: bool, g: &ModifyGrants) {
    if ok {
        scoped_acp.push(g.clone());
    }
}

/// `modify_ident_test`.
pub fn modify_ident_test(ident: &Identity) -> AccessBasicResult {
    match &ident.origin {
        IdentType::Internal(InternalRole::System) => {
            return AccessBasicResult::Grant;
        }
        IdentType::Internal(InternalRole::Migration) => {
            return AccessBasicResult::Ignore;
        }
        IdentType::Internal(InternalRole::MessageQueue) | IdentType::Internal(InternalRole::AccountRequest) => {
            return AccessBasicResult::Deny;
        }
        IdentType::Synch(_) => {
            return AccessBasicResult::Deny;
        }
        IdentType::User(_) => {}
    };

    match access_scope(ident) {
        AccessScope::ReadOnly | AccessScope::Synchronise => {
            return AccessBasicResult::Deny;
        }
        AccessScope::ReadWrite => {}
    };

    AccessBasicResult::Ignore
}

/// `modify_pres_test`.
pub fn modify_pres_test(scoped_acp: &[ModifyGrants]) -> AccessModResult {
    let mut pres_attr: Vec<Attribute> = Vec::new();
    let mut rem_attr: Vec<Attribute> = Vec::new();
    let mut pres_class: Vec<Vec<u8>> = Vec::new();
    let mut rem_class: Vec<Vec<u8>> = Vec::new();
    let mut i = 0;
    while i < scoped_acp.len() {
        extend(&mut pres_attr, &scoped_acp[i].presattrs);
        extend(&mut rem_attr, &scoped_acp[i].remattrs);
        extend(&mut pres_class, &scoped_acp[i].pres_classes);
        extend(&mut rem_class, &scoped_acp[i].rem_classes);
        i += 1;
    }

    AccessModResult::Allow { pres_attr, rem_attr, pres_class, rem_class }
}

/// `sync_agreements.get(&sync_uuid)`.
pub fn sync_agreement_get(sync_agreements: &[SyncAgreement], sync_uuid: crate::Uuid) -> Option<&Vec<Attribute>> {
    let mut i = 0;
    while i < sync_agreements.len() {
        if sync_agreements[i].uuid == sync_uuid {
            return Some(&sync_agreements[i].attrs);
        }
        i += 1;
    }
    None
}

/// `entry.get_ava_set(Class).map(|classes| classes.contains(pv)).unwrap_or(false)`.
pub fn class_set_contains(entry: &Entry, pv: &PartialValue) -> bool {
    match get_ava_set(entry, b"class") {
        Some(classes) => vs_contains(classes, pv),
        None => false,
    }
}

/// `if let Some(a) = sync_agreements.get(&sync_uuid) { set.extend(a.iter().cloned()) }`.
pub fn extend_sync_yield_authority(set: &mut Vec<Attribute>, sync_agreements: &[SyncAgreement], sync_uuid: crate::Uuid) {
    match sync_agreement_get(sync_agreements, sync_uuid) {
        Some(sync_yield_authority) => extend(set, sync_yield_authority),
        None => {}
    }
}

/// `modify_sync_constrain`.
pub fn modify_sync_constrain(ident: &Identity, entry: &Entry, sync_agreements: &[SyncAgreement]) -> AccessModResult {
    match &ident.origin {
        IdentType::Internal(_) => AccessModResult::Ignore,
        IdentType::Synch(_) => AccessModResult::Ignore,
        IdentType::User(_) => {
            // We need to meet these conditions.
            // * We are a sync object
            // * We have a sync_parent_uuid
            let is_sync = class_set_contains(entry, &PartialValue::Iutf8(b"sync_object".to_vec()));

            if !is_sync {
                return AccessModResult::Ignore;
            }

            match get_ava_single_refer(entry, b"sync_parent_uuid") {
                Some(sync_uuid) => {
                    let mut set: Vec<Attribute> = Vec::new();
                    insert(&mut set, b"user_auth_token_session");
                    insert(&mut set, b"oauth2_session");
                    insert(&mut set, b"oauth2_consent_scope_map");
                    insert(&mut set, b"credential_update_intent_token");

                    extend_sync_yield_authority(&mut set, sync_agreements, sync_uuid);

                    AccessModResult::Constrain { pres_attr: set.clone(), rem_attr: set, pres_cls: None, rem_cls: None }
                }
                None => AccessModResult::Deny,
            }
        }
    }
}

/// `modify_protected_attrs`.
pub fn modify_protected_attrs(ident: &Identity, entry: &Entry) -> AccessModResult {
    match &ident.origin {
        IdentType::Internal(InternalRole::System) | IdentType::Synch(_) => {
            // We don't constraint or influence these.
            AccessModResult::Ignore
        }
        IdentType::Internal(InternalRole::AccountRequest)
        | IdentType::Internal(InternalRole::MessageQueue)
        | IdentType::Internal(InternalRole::Migration)
        | IdentType::User(_) => match get_ava_as_iutf8(entry, b"class") {
            Some(classes) => {
                if entry.uuid > UUID_ANONYMOUS && disjoint_protected_mod_entry_classes(classes) {
                    // Not protected, go ahead
                    AccessModResult::Ignore
                } else {
                    // Okay, the entry is protected, apply the full ruleset.
                    modify_protected_entry_attrs(classes)
                }
            }
            // Nothing to check - this entry will fail to modify anyway because it has
            // no classes
            None => AccessModResult::Ignore,
        },
    }
}

/// `modify_protected_entry_attrs`.
pub fn modify_protected_entry_attrs(classes: &[Vec<u8>]) -> AccessModResult {
    // First check for the hard-deny rules.
    if !disjoint_locked_entry_classes(classes) {
        // Hard deny attribute modifications to these types.
        return AccessModResult::Deny;
    }

    let mut constrain_attrs: Vec<Attribute> = Vec::new();

    // Allows removal of the recycled class specifically on recycled entries.
    if crate::bset::contains(classes, b"recycled") {
        insert(&mut constrain_attrs, b"class");
    }

    if crate::bset::contains(classes, b"classtype") {
        insert(&mut constrain_attrs, b"may");
        insert(&mut constrain_attrs, b"must");
    }

    if crate::bset::contains(classes, b"system_config") {
        insert(&mut constrain_attrs, b"badlist_password");
    }

    // Allow domain settings.
    if crate::bset::contains(classes, b"domain_info") {
        insert(&mut constrain_attrs, b"domain_ssid");
        insert(&mut constrain_attrs, b"domain_ldap_basedn");
        insert(&mut constrain_attrs, b"ldap_max_queryable_attrs");
        insert(&mut constrain_attrs, b"ldap_allow_unix_pw_bind");
        insert(&mut constrain_attrs, b"fernet_private_key_str");
        insert(&mut constrain_attrs, b"es256_private_key_der");
        insert(&mut constrain_attrs, b"key_action_revoke");
        insert(&mut constrain_attrs, b"key_action_rotate");
        insert(&mut constrain_attrs, b"id_verification_eckey");
        insert(&mut constrain_attrs, b"denied_name");
        insert(&mut constrain_attrs, b"domain_display_name");
        insert(&mut constrain_attrs, b"image");
        insert(&mut constrain_attrs, b"domain_allow_easter_eggs");
        insert(&mut constrain_attrs, b"domain_allow_account_recovery");
    }

    if crate::bset::contains(classes, b"account") {
        insert(&mut constrain_attrs, b"account_expire");
        insert(&mut constrain_attrs, b"account_valid_from");
    }

    if crate::bset::contains(classes, b"service_account") {
        insert(&mut constrain_attrs, b"ssh_publickey");
        insert(&mut constrain_attrs, b"user_auth_token_session");
        insert(&mut constrain_attrs, b"oauth2_session");
        insert(&mut constrain_attrs, b"mail");
        insert(&mut constrain_attrs, b"primary_credential");
        insert(&mut constrain_attrs, b"api_token_session");
    }

    if crate::bset::contains(classes, b"group") {
        insert(&mut constrain_attrs, b"member");
    }

    // Allow account policy related attributes to be changed on dyngroup
    if crate::bset::contains(classes, b"dyngroup") {
        insert(&mut constrain_attrs, b"authsession_expiry");
        insert(&mut constrain_attrs, b"auth_password_minimum_length");
        insert(&mut constrain_attrs, b"credential_type_minimum");
        insert(&mut constrain_attrs, b"privilege_expiry");
        insert(&mut constrain_attrs, b"webauthn_attestation_ca_list");
        insert(&mut constrain_attrs, b"limit_search_max_results");
        insert(&mut constrain_attrs, b"limit_search_max_filter_test");
        insert(&mut constrain_attrs, b"allow_primary_cred_fallback");
    }

    if crate::bset::contains(classes, b"feature") {
        insert(&mut constrain_attrs, b"enabled");
    }

    // If we don't constrain the attributes at all, we have to deny the change
    // from proceeding.
    if constrain_attrs.len() == 0 {
        AccessModResult::Deny
    } else {
        AccessModResult::Constrain {
            pres_attr: constrain_attrs.clone(),
            rem_attr: constrain_attrs,
            pres_cls: None,
            rem_cls: None,
        }
    }
}

/// `modify_migration_attrs`.
pub fn modify_migration_attrs(ident: &Identity, entry: &Entry) -> AccessModResult {
    match &ident.origin {
        IdentType::Internal(InternalRole::Migration) => {
            match get_ava_as_iutf8(entry, b"class") {
                Some(classes) => {
                    let classes = sub_migration_ignore(classes);
                    if classes.len() != 0 && subset_migration_entry(&classes) {
                        // Check what may be allowed
                        let (allow_attrs, allow_cls) = migration_entry_attrs(&classes);

                        if allow_attrs.len() == 0 {
                            return AccessModResult::Deny;
                        } else {
                            return AccessModResult::Allow {
                                pres_attr: allow_attrs.clone(),
                                rem_attr: allow_attrs,
                                pres_class: allow_cls.clone(),
                                rem_class: allow_cls,
                            };
                        }
                    }
                }
                None => {}
            }
            AccessModResult::Deny
        }
        _ => {
            // We don't constraint or influence these.
            AccessModResult::Ignore
        }
    }
}
