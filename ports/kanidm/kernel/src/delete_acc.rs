//! Delete access (access/delete.rs).
use crate::entry_impl::get_ava_as_iutf8;
use crate::identity_impl::{access_scope, get_memberof, get_uuid};
use crate::profiles::AccessControlDeleteResolved;
use crate::protected::disjoint_protected_entry_classes;
use crate::search_acc::acp_applies;
use crate::{AccessScope, Entry, IdentType, Identity, InternalRole, Uuid, UUID_ANONYMOUS};

/// `DeleteResult`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum DeleteResult {
    Deny,
    Grant,
}

/// `delete.rs`'s `IResult`.
pub enum IResult {
    Deny,
    Grant,
    Ignore,
}

/// `apply_delete_access`.
pub fn apply_delete_access(ident: &Identity, related_acp: &[AccessControlDeleteResolved], entry: &Entry) -> DeleteResult {
    let mut denied = false;
    let mut grant = false;

    match protected_filter_entry(ident, entry) {
        IResult::Deny => denied = true,
        IResult::Grant | IResult::Ignore => {}
    }

    match delete_filter_entry(ident, related_acp, entry) {
        IResult::Deny => denied = true,
        IResult::Grant => grant = true,
        IResult::Ignore => {}
    }

    if denied {
        // Something explicitly said no.
        DeleteResult::Deny
    } else if grant {
        // Something said yes
        DeleteResult::Grant
    } else {
        // Nothing said yes.
        DeleteResult::Deny
    }
}

/// `delete_filter_entry`.
pub fn delete_filter_entry(ident: &Identity, related_acp: &[AccessControlDeleteResolved], entry: &Entry) -> IResult {
    match &ident.origin {
        IdentType::Internal(InternalRole::System) => {
            return IResult::Grant;
        }
        IdentType::Internal(InternalRole::Migration) => {
            let valid_migration_class = crate::search_acc::valid_migration_class(entry);

            if valid_migration_class {
                // Can proceed.
                return IResult::Grant;
            } else {
                return IResult::Deny;
            }
        }
        IdentType::Internal(InternalRole::AccountRequest) | IdentType::Internal(InternalRole::MessageQueue) => {
            return IResult::Deny;
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

    let ident_memberof = get_memberof(ident);
    let ident_uuid = get_uuid(ident);

    let allow = delete_any_acp(related_acp, ident_memberof, ident_uuid, entry);

    if allow { IResult::Grant } else { IResult::Ignore }
}

/// The `related_acp.iter().any(..)` of `delete_filter_entry`.
pub fn delete_any_acp(
    related_acp: &[AccessControlDeleteResolved],
    ident_memberof: Option<&Vec<Uuid>>,
    ident_uuid: Uuid,
    entry: &Entry,
) -> bool {
    let mut i = 0;
    while i < related_acp.len() {
        let acd = &related_acp[i];
        if acp_applies(acd.receiver_condition, &acd.target_condition, ident_memberof, ident_uuid, entry) {
            return true;
        }
        i += 1;
    }
    false
}

/// `delete.rs`'s `protected_filter_entry`.
pub fn protected_filter_entry(ident: &Identity, entry: &Entry) -> IResult {
    match &ident.origin {
        IdentType::Internal(InternalRole::System) => IResult::Ignore,
        IdentType::Synch(_) => IResult::Deny,
        IdentType::Internal(InternalRole::AccountRequest) | IdentType::Internal(InternalRole::MessageQueue) => {
            IResult::Deny
        }
        IdentType::Internal(InternalRole::Migration) | IdentType::User(_) => {
            // Prevent deletion of entries that exist in the system controlled entry range.
            if entry.uuid <= UUID_ANONYMOUS {
                return IResult::Deny;
            }

            // Prevent deleting some protected types.
            match get_ava_as_iutf8(entry, b"class") {
                Some(classes) => {
                    if disjoint_protected_entry_classes(classes) {
                        IResult::Ignore
                    } else {
                        IResult::Deny
                    }
                }
                None => IResult::Ignore,
            }
        }
    }
}
