//! Search access (access/search.rs).
use crate::bset::{contains_uuid, extend, intersects_uuid};
use crate::entry_impl::{
    class_contains, entry_match_no_index, get_ava_as_iutf8, get_ava_as_oauthscopemaps, get_ava_refer,
    get_ava_single_refer,
};
use crate::identity_impl::{access_scope, get_memberof, get_uuid};
use crate::migration::{sub_migration_ignore, subset_migration_entry};
use crate::profiles::{AccessControlReceiverCondition, AccessControlSearchResolved, AccessControlTargetCondition};
use crate::{AccessScope, AccessSrchResult, Attribute, Entry, IdentType, Identity, InternalRole, UUID_ANONYMOUS};

/// `SearchResult`.
#[derive(Debug, PartialEq, Eq)]
pub enum SearchResult {
    Deny,
    Grant,
    Allow(Vec<Attribute>),
}

/// `apply_search_access`.
pub fn apply_search_access(ident: &Identity, related_acp: &[AccessControlSearchResolved], entry: &Entry) -> SearchResult {
    let mut denied = false;
    let mut grant = false;
    let constrain: Vec<Attribute> = Vec::new();
    let mut allow: Vec<Attribute> = Vec::new();

    // The access control profile
    match search_filter_entry(ident, related_acp, entry) {
        AccessSrchResult::Deny => denied = true,
        AccessSrchResult::Grant => grant = true,
        AccessSrchResult::Ignore => {}
        AccessSrchResult::Allow { attr } => extend(&mut allow, &attr),
    };

    match search_oauth2_filter_entry(ident, entry) {
        AccessSrchResult::Deny => denied = true,
        AccessSrchResult::Grant => grant = true,
        AccessSrchResult::Ignore => {}
        AccessSrchResult::Allow { attr } => extend(&mut allow, &attr),
    };

    match search_applications_filter_entry(ident, entry) {
        AccessSrchResult::Deny => denied = true,
        AccessSrchResult::Grant => grant = true,
        AccessSrchResult::Ignore => {}
        AccessSrchResult::Allow { attr } => extend(&mut allow, &attr),
    };

    match search_sync_account_filter_entry(ident, entry) {
        AccessSrchResult::Deny => denied = true,
        AccessSrchResult::Grant => grant = true,
        AccessSrchResult::Ignore => {}
        AccessSrchResult::Allow { attr } => extend(&mut allow, &attr),
    };

    if denied {
        SearchResult::Deny
    } else if grant {
        SearchResult::Grant
    } else {
        let allowed_attrs = if constrain.len() != 0 {
            crate::bset::intersection(&constrain, &allow)
        } else {
            allow
        };
        SearchResult::Allow(allowed_attrs)
    }
}

/// The receiver half of the closure shared by search, modify and delete.
/// An entry without `EntryManagedBy` fails an `EntryManager` condition
/// (search and modify return `None` through `?`, delete returns `false`).
pub fn receiver_applies(
    receiver_condition: AccessControlReceiverCondition,
    ident_memberof: Option<&Vec<crate::Uuid>>,
    ident_uuid: crate::Uuid,
    entry: &Entry,
) -> bool {
    match receiver_condition {
        AccessControlReceiverCondition::GroupChecked => true,
        AccessControlReceiverCondition::EntryManager => {
            let entry_manager_uuids = match get_ava_refer(entry, b"entry_managed_by") {
                Some(u) => u,
                None => return false,
            };
            let group_check = match ident_memberof {
                Some(imo) => intersects_uuid(imo, entry_manager_uuids),
                None => false,
            };
            let user_check = contains_uuid(entry_manager_uuids, ident_uuid);
            group_check || user_check
        }
    }
}

/// Both conditions of a resolved profile hold for the entry.
pub fn acp_applies(
    receiver_condition: AccessControlReceiverCondition,
    target_condition: &AccessControlTargetCondition,
    ident_memberof: Option<&Vec<crate::Uuid>>,
    ident_uuid: crate::Uuid,
    entry: &Entry,
) -> bool {
    if !receiver_applies(receiver_condition, ident_memberof, ident_uuid, entry) {
        return false;
    }
    target_applies(target_condition, entry)
}

/// `match &acs.target_condition { Scope(f_res) => entry.entry_match_no_index(f_res) }`.
pub fn target_applies(target_condition: &AccessControlTargetCondition, entry: &Entry) -> bool {
    match target_condition {
        AccessControlTargetCondition::Scope(f_res) => entry_match_no_index(entry, f_res),
    }
}

/// `search_filter_entry`.
pub fn search_filter_entry(ident: &Identity, related_acp: &[AccessControlSearchResolved], entry: &Entry) -> AccessSrchResult {
    // If this is an internal search, return our working set.
    match &ident.origin {
        IdentType::Internal(InternalRole::System) => {
            return AccessSrchResult::Grant;
        }
        IdentType::Internal(InternalRole::AccountRequest) => {
            let valid_account_request_class = class_contains(entry, b"account");
            if valid_account_request_class {
                return AccessSrchResult::Grant;
            } else {
                return AccessSrchResult::Deny;
            }
        }
        IdentType::Internal(InternalRole::Migration) => {
            let valid_migration_class = valid_migration_class(entry);
            if valid_migration_class {
                return AccessSrchResult::Grant;
            } else {
                return AccessSrchResult::Deny;
            }
        }
        IdentType::Internal(InternalRole::MessageQueue) => {
            return AccessSrchResult::Deny;
        }
        IdentType::Synch(_) => {
            return AccessSrchResult::Deny;
        }
        IdentType::User(_) => {}
    };

    match access_scope(ident) {
        AccessScope::Synchronise => {
            return AccessSrchResult::Deny;
        }
        AccessScope::ReadOnly | AccessScope::ReadWrite => {}
    };

    // needed for checking entry manager conditions.
    let ident_memberof = get_memberof(ident);
    let ident_uuid = get_uuid(ident);

    let allowed_attrs = search_allowed_attrs(related_acp, ident_memberof, ident_uuid, entry);

    AccessSrchResult::Allow { attr: allowed_attrs }
}

/// The `filter_map(..).flatten().collect()` of `search_filter_entry`.
pub fn search_allowed_attrs(
    related_acp: &[AccessControlSearchResolved],
    ident_memberof: Option<&Vec<crate::Uuid>>,
    ident_uuid: crate::Uuid,
    entry: &Entry,
) -> Vec<Attribute> {
    let mut allowed_attrs: Vec<Attribute> = Vec::new();
    let mut i = 0;
    while i < related_acp.len() {
        let acs = &related_acp[i];
        let ok = acp_applies(acs.receiver_condition, &acs.target_condition, ident_memberof, ident_uuid, entry);
        // -- Conditions pass -- release the attributes.
        extend_if(&mut allowed_attrs, ok, &acs.attrs);
        i += 1;
    }
    allowed_attrs
}

/// `entry.get_ava_as_iutf8(Class).map(|classes| classes.sub(&MIGRATION_IGNORE_CLASSES)
/// .is_subset(&MIGRATION_ENTRY_CLASSES)).unwrap_or(false)`.
pub fn valid_migration_class(entry: &Entry) -> bool {
    match get_ava_as_iutf8(entry, b"class") {
        Some(classes) => subset_migration_entry(&sub_migration_ignore(classes)),
        None => false,
    }
}

/// `maps.zip(ident.get_memberof()).map(|(maps, mo)| maps.keys().any(|k| mo.contains(k))).unwrap_or(false)`.
pub fn scope_member(maps: Option<&Vec<crate::Uuid>>, mo: Option<&Vec<crate::Uuid>>) -> bool {
    match maps {
        Some(m) => match mo {
            Some(g) => intersects_uuid(m, g),
            None => false,
        },
        None => false,
    }
}

/// `group.and_then(|g| ident.get_memberof().map(|mo| mo.contains(&g))).unwrap_or(false)`.
pub fn linked_group_member(group: Option<crate::Uuid>, mo: Option<&Vec<crate::Uuid>>) -> bool {
    match group {
        Some(group_uuid) => match mo {
            Some(g) => contains_uuid(g, group_uuid),
            None => false,
        },
        None => false,
    }
}

/// `if ok { set.extend(xs) }`.
pub fn extend_if(set: &mut Vec<Attribute>, ok: bool, xs: &[Attribute]) {
    if ok {
        extend(set, xs);
    }
}

/// `search_oauth2_filter_entry`.
pub fn search_oauth2_filter_entry(ident: &Identity, entry: &Entry) -> AccessSrchResult {
    match &ident.origin {
        IdentType::Internal(_) | IdentType::Synch(_) => AccessSrchResult::Ignore,
        IdentType::User(iuser) => {
            if iuser.entry.uuid == UUID_ANONYMOUS {
                return AccessSrchResult::Ignore;
            }

            let contains_o2_rs = class_contains(entry, b"oauth2_resource_server");

            let contains_o2_scope_member =
                scope_member(get_ava_as_oauthscopemaps(entry, b"oauth2_rs_scope_map"), get_memberof(ident));

            if contains_o2_rs && contains_o2_scope_member {
                let mut attr: Vec<Attribute> = Vec::new();
                crate::bset::insert(&mut attr, b"class");
                crate::bset::insert(&mut attr, b"displayname");
                crate::bset::insert(&mut attr, b"uuid");
                crate::bset::insert(&mut attr, b"name");
                crate::bset::insert(&mut attr, b"oauth2_rs_origin_landing");
                crate::bset::insert(&mut attr, b"image");
                return AccessSrchResult::Allow { attr };
            }
            AccessSrchResult::Ignore
        }
    }
}

/// `search_applications_filter_entry`.
pub fn search_applications_filter_entry(ident: &Identity, entry: &Entry) -> AccessSrchResult {
    match &ident.origin {
        IdentType::Internal(_) | IdentType::Synch(_) => AccessSrchResult::Ignore,
        IdentType::User(iuser) => {
            if iuser.entry.uuid == UUID_ANONYMOUS {
                return AccessSrchResult::Ignore;
            }

            let contains_application = class_contains(entry, b"application");

            let contains_application_linked_group =
                linked_group_member(get_ava_single_refer(entry, b"linked_group"), get_memberof(ident));

            if contains_application && contains_application_linked_group {
                let mut attr: Vec<Attribute> = Vec::new();
                crate::bset::insert(&mut attr, b"class");
                crate::bset::insert(&mut attr, b"displayname");
                crate::bset::insert(&mut attr, b"uuid");
                crate::bset::insert(&mut attr, b"name");
                crate::bset::insert(&mut attr, b"linked_group");
                return AccessSrchResult::Allow { attr };
            }
            AccessSrchResult::Ignore
        }
    }
}

/// `iuser.entry.get_ava_as_iutf8(Class).map(|set| set.contains(SyncObject)
/// && set.contains(Account)).unwrap_or(false)`.
pub fn is_sync_account_user(e: &Entry) -> bool {
    if !class_contains(e, b"sync_object") {
        return false;
    }
    class_contains(e, b"account")
}

/// `search_sync_account_filter_entry`.
pub fn search_sync_account_filter_entry(ident: &Identity, entry: &Entry) -> AccessSrchResult {
    match &ident.origin {
        IdentType::Internal(_) | IdentType::Synch(_) => AccessSrchResult::Ignore,
        IdentType::User(iuser) => {
            // Is the user a synced object?
            let is_user_sync_account = is_sync_account_user(&iuser.entry);

            if is_user_sync_account {
                let is_target_sync_account = class_contains(entry, b"sync_account");

                if is_target_sync_account {
                    // Okay, now we need to check if the uuids line up.
                    let sync_uuid = entry.uuid;
                    let sync_source_match = match get_ava_single_refer(&iuser.entry, b"sync_parent_uuid") {
                        Some(sync_parent_uuid) => sync_parent_uuid == sync_uuid,
                        None => false,
                    };

                    if sync_source_match {
                        let mut attr: Vec<Attribute> = Vec::new();
                        crate::bset::insert(&mut attr, b"class");
                        crate::bset::insert(&mut attr, b"uuid");
                        crate::bset::insert(&mut attr, b"sync_credential_portal");
                        return AccessSrchResult::Allow { attr };
                    }
                }
            }
            // Fall through
            AccessSrchResult::Ignore
        }
    }
}
