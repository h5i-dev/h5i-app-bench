//! Create access (access/create.rs).
use crate::bset::{contains, extend, insert, intersection, is_subset};
use crate::entry_impl::{get_ava_as_iutf8, get_ava_names, get_uuid_init};
use crate::identity_impl::access_scope;
use crate::migration::{migration_entry_attrs, sub_migration_ignore, subset_migration_entry};
use crate::profiles::{AccessControlCreateResolved, AccessControlReceiverCondition};
use crate::protected::{disjoint_protected_entry_classes, remove_protected_mod_pres};
use crate::search_acc::target_applies;
use crate::{AccessScope, Attribute, Entry, IdentType, Identity, InternalRole, UUID_ANONYMOUS};

/// `CreateResult`.
#[derive(Debug, PartialEq, Eq)]
pub enum CreateResult {
    Deny,
    Grant,
    Allow { pres: Vec<Attribute>, pres_cls: Vec<Vec<u8>> },
}

/// `create.rs`'s `IResult`.
pub enum IResult {
    Deny,
    Grant,
    Ignore,
    Allow { pres: Vec<Attribute>, pres_cls: Vec<Vec<u8>> },
}

/// `apply_create_access`.
pub fn apply_create_access(ident: &Identity, related_acp: &[AccessControlCreateResolved], entry: &Entry) -> CreateResult {
    let mut denied = false;
    let mut grant = false;

    let constrain_pres: Vec<Attribute> = Vec::new();
    let mut allow_pres: Vec<Attribute> = Vec::new();

    let constrain_pres_cls: Vec<Vec<u8>> = Vec::new();
    let mut allow_pres_cls: Vec<Vec<u8>> = Vec::new();

    // This module can never yield a grant.
    match protected_filter_entry(ident, entry) {
        IResult::Deny => denied = true,
        IResult::Grant | IResult::Ignore | IResult::Allow { .. } => {}
    }

    match message_queue(ident, entry) {
        IResult::Deny => denied = true,
        IResult::Grant => grant = true,
        IResult::Ignore => {}
        IResult::Allow { pres, pres_cls } => {
            extend(&mut allow_pres, &pres);
            extend(&mut allow_pres_cls, &pres_cls);
        }
    }

    match migration_filter_entry(ident, entry) {
        IResult::Deny => denied = true,
        IResult::Grant => grant = true,
        IResult::Ignore => {}
        IResult::Allow { pres, pres_cls } => {
            extend(&mut allow_pres, &pres);
            extend(&mut allow_pres_cls, &pres_cls);
        }
    }

    match create_filter_entry(ident, related_acp, entry) {
        IResult::Deny => denied = true,
        IResult::Grant => grant = true,
        IResult::Ignore => {}
        IResult::Allow { pres, pres_cls } => {
            extend(&mut allow_pres, &pres);
            extend(&mut allow_pres_cls, &pres_cls);
        }
    }

    if denied {
        // Something explicitly said no.
        CreateResult::Deny
    } else if grant {
        // Something said yes
        CreateResult::Grant
    } else {
        let allowed_pres = if constrain_pres.len() != 0 {
            intersection(&constrain_pres, &allow_pres)
        } else {
            allow_pres
        };

        let allowed_pres_cls = if constrain_pres_cls.len() != 0 {
            intersection(&constrain_pres_cls, &allow_pres_cls)
        } else {
            allow_pres_cls
        };

        let allowed_pres_cls = remove_protected_mod_pres(&allowed_pres_cls);

        CreateResult::Allow { pres: allowed_pres, pres_cls: allowed_pres_cls }
    }
}

/// `create_filter_entry`.
pub fn create_filter_entry(ident: &Identity, related_acp: &[AccessControlCreateResolved], entry: &Entry) -> IResult {
    match &ident.origin {
        IdentType::Internal(InternalRole::System) => {
            return IResult::Grant;
        }
        IdentType::Internal(InternalRole::Migration) => {
            // Checked in a separate function.
            return IResult::Ignore;
        }
        IdentType::Internal(InternalRole::AccountRequest) => {
            let mut pres: Vec<Attribute> = Vec::new();
            insert(&mut pres, b"class");
            insert(&mut pres, b"delete_after");
            insert(&mut pres, b"displayname");
            insert(&mut pres, b"mail");
            insert(&mut pres, b"name");
            insert(&mut pres, b"uuid");

            let mut pres_cls: Vec<Vec<u8>> = Vec::new();
            insert(&mut pres_cls, b"object");
            insert(&mut pres_cls, b"account_signup_request");

            // We may create account signup requests.
            return IResult::Allow { pres, pres_cls };
        }
        IdentType::Internal(InternalRole::MessageQueue) => {
            // No current rules.
            return IResult::Ignore;
        }
        IdentType::Synch(_) => {
            return IResult::Deny;
        }
        IdentType::User(_) => {}
    };

    match access_scope(ident) {
        AccessScope::ReadOnly | AccessScope::Synchronise => {
            return IResult::Deny;
        }
        AccessScope::ReadWrite => {}
    };

    // Build the set of requested classes and attrs here.
    let create_attrs = get_ava_names(entry);

    let create_classes = match get_ava_as_iutf8(entry, b"class") {
        Some(s) => s,
        None => {
            return IResult::Deny;
        }
    };

    let allow = create_any_acp(related_acp, entry, &create_attrs, create_classes);

    if allow { IResult::Grant } else { IResult::Ignore }
}

/// The `related_acp.iter().any(..)` of `create_filter_entry`.
pub fn create_any_acp(
    related_acp: &[AccessControlCreateResolved],
    entry: &Entry,
    create_attrs: &[Attribute],
    create_classes: &[Vec<u8>],
) -> bool {
    let mut i = 0;
    while i < related_acp.len() {
        if create_acp_allows(&related_acp[i], entry, create_attrs, create_classes) {
            return true;
        }
        i += 1;
    }
    false
}

/// The closure of `create_filter_entry`'s `any`.
pub fn create_acp_allows(
    accr: &AccessControlCreateResolved,
    entry: &Entry,
    create_attrs: &[Attribute],
    create_classes: &[Vec<u8>],
) -> bool {
    // Assert that the receiver condition applies.
    match accr.receiver_condition {
        AccessControlReceiverCondition::GroupChecked => {}
        AccessControlReceiverCondition::EntryManager => {
            // Currently, this is unsatisfiable for creates.
            return false;
        }
    };

    if !target_applies(&accr.target_condition, entry) {
        // Does not match, fail this rule.
        return false;
    }

    // It matches, so now we have to check attrs and classes.
    // Remember, we have to match ALL requested attrs
    // and classes to pass!
    if !is_subset(create_attrs, &accr.attrs) {
        false
    } else if !is_subset(create_classes, &accr.classes) {
        false
    } else {
        true
    }
}

/// `create.rs`'s `protected_filter_entry`.
pub fn protected_filter_entry(ident: &Identity, entry: &Entry) -> IResult {
    match &ident.origin {
        IdentType::Internal(InternalRole::System)
        | IdentType::Internal(InternalRole::AccountRequest)
        | IdentType::Internal(InternalRole::MessageQueue) => IResult::Ignore,
        IdentType::Synch(_) => IResult::Deny,
        IdentType::Internal(InternalRole::Migration) | IdentType::User(_) => {
            match get_uuid_init(entry) {
                Some(entry_uuid) => {
                    if entry_uuid <= UUID_ANONYMOUS {
                        return IResult::Deny;
                    }
                }
                None => {}
            }

            // Now check things ...
            match get_ava_as_iutf8(entry, b"class") {
                Some(classes) => {
                    if disjoint_protected_entry_classes(classes) {
                        // It's different, go ahead
                        IResult::Ignore
                    } else {
                        // Block the mod, something is present
                        IResult::Deny
                    }
                }
                // Nothing to check - this entry will fail to create anyway because it has
                // no classes
                None => IResult::Ignore,
            }
        }
    }
}

/// `migration_filter_entry`.
pub fn migration_filter_entry(ident: &Identity, entry: &Entry) -> IResult {
    match &ident.origin {
        IdentType::Internal(InternalRole::Migration) => {
            match get_ava_as_iutf8(entry, b"class") {
                Some(classes) => {
                    let classes = sub_migration_ignore(classes);
                    if subset_migration_entry(&classes) {
                        // Check what may be allowed
                        let (allow_attrs, allow_cls) = migration_entry_attrs(&classes);

                        if allow_attrs.len() == 0 {
                            return IResult::Deny;
                        } else {
                            return IResult::Allow { pres: allow_attrs, pres_cls: allow_cls };
                        }
                    }
                }
                None => {}
            }
            IResult::Deny
        }
        _ => IResult::Ignore,
    }
}

/// `message_queue`.
pub fn message_queue(ident: &Identity, entry: &Entry) -> IResult {
    match &ident.origin {
        IdentType::Internal(InternalRole::MessageQueue) => {
            match get_ava_as_iutf8(entry, b"class") {
                Some(classes) => {
                    if contains(classes, b"outbound_message") {
                        let mut allow_attrs: Vec<Attribute> = Vec::new();
                        insert(&mut allow_attrs, b"class");
                        insert(&mut allow_attrs, b"delete_after");
                        insert(&mut allow_attrs, b"mail_destination");
                        insert(&mut allow_attrs, b"message_template");
                        insert(&mut allow_attrs, b"send_after");

                        let mut allow_cls: Vec<Vec<u8>> = Vec::new();
                        insert(&mut allow_cls, b"object");
                        insert(&mut allow_cls, b"outbound_message");

                        return IResult::Allow { pres: allow_attrs, pres_cls: allow_cls };
                    }
                }
                None => {}
            }
            IResult::Deny
        }
        _ => IResult::Ignore,
    }
}
