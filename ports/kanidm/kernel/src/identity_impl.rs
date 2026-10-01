//! The `Identity` accessors the access module calls (server/identity.rs).
use crate::entry_impl::get_ava_refer;
use crate::{
    AccessScope, IdentType, Identity, InternalRole, Uuid, UUID_INTERNAL_ACCOUNT_REQUEST,
    UUID_INTERNAL_MESSAGE_QUEUE, UUID_INTERNAL_MIGRATION, UUID_SYSTEM,
};

/// `InternalRole::get_uuid`.
pub fn role_get_uuid(role: InternalRole) -> Uuid {
    match role {
        InternalRole::System => UUID_SYSTEM,
        InternalRole::Migration => UUID_INTERNAL_MIGRATION,
        InternalRole::AccountRequest => UUID_INTERNAL_ACCOUNT_REQUEST,
        InternalRole::MessageQueue => UUID_INTERNAL_MESSAGE_QUEUE,
    }
}

/// `Identity::access_scope`.
pub fn access_scope(ident: &Identity) -> AccessScope {
    ident.scope
}

/// `Identity::get_uuid`.
pub fn get_uuid(ident: &Identity) -> Uuid {
    match &ident.origin {
        IdentType::Internal(role) => role_get_uuid(*role),
        IdentType::User(u) => u.entry.uuid,
        IdentType::Synch(u) => *u,
    }
}

/// `Identity::get_memberof`.
pub fn get_memberof(ident: &Identity) -> Option<&Vec<Uuid>> {
    match &ident.origin {
        IdentType::Internal(_) | IdentType::Synch(_) => None,
        IdentType::User(u) => get_ava_refer(&u.entry, b"memberof"),
    }
}
