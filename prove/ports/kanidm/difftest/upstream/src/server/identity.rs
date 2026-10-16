// Stub of `server/identity.rs`: `Identity` keeps the fields the access module
// reads. The enums and methods below the stub are copied.
use crate::prelude::*;
use serde::{Deserialize, Serialize};
use std::{collections::BTreeSet, hash::Hash, sync::Arc};

#[derive(Debug, Clone)]
pub struct Identity {
    pub origin: IdentType,
    pub(crate) scope: AccessScope,
}

impl Identity {
    pub fn difftest_new(origin: IdentType, scope: AccessScope) -> Self {
        Identity { origin, scope }
    }
}

// Copied from kanidm/kanidm @ f608c4f by extract_upstream.py. Do not edit.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AccessScope {
    ReadOnly,
    ReadWrite,
    Synchronise,
}

#[derive(Debug, Clone)]
/// Metadata and the entry of the current Identity which is an external account/user.
pub struct IdentUser {
    pub entry: Arc<EntrySealedCommitted>,
    // IpAddr?
    // Other metadata?
}

#[derive(Debug, Clone)]
/// The internal role being used for this operation.
pub enum InternalRole {
    /// The internal database system. This has unlimited crab power.
    System,
    /// A migration operation being performed on the system.
    Migration,

    /// An anonymous account action - this could be a credential reset
    /// request, or a request to create a new account.
    AccountRequest,

    /// An internal role than can manage the outbound message queue.
    MessageQueue,
}

impl InternalRole {
    pub fn get_uuid(&self) -> Uuid {
        match self {
            Self::System => UUID_SYSTEM,
            Self::Migration => UUID_INTERNAL_MIGRATION,
            Self::AccountRequest => UUID_INTERNAL_ACCOUNT_REQUEST,
            Self::MessageQueue => UUID_INTERNAL_MESSAGE_QUEUE,
        }
    }
}

#[derive(Debug, Clone)]
/// The type of Identity that is related to this session.
pub enum IdentType {
    User(IdentUser),
    Synch(Uuid),
    Internal(InternalRole),
}

#[derive(Debug, Clone, PartialEq, Hash, Ord, PartialOrd, Eq, Serialize, Deserialize)]
/// A unique identifier of this Identity, that can be associated to various
/// caching components.
pub enum IdentityId {
    // Time stamp of the originating event.
    // The uuid of the originating user
    User(Uuid),
    Synch(Uuid),
    Internal(Uuid),
}

impl From<&IdentType> for IdentityId {
    fn from(idt: &IdentType) -> Self {
        match idt {
            IdentType::Internal(role) => IdentityId::Internal(role.get_uuid()),
            IdentType::User(u) => IdentityId::User(u.entry.get_uuid()),
            IdentType::Synch(u) => IdentityId::Synch(*u),
        }
    }
}

impl Identity {
    pub fn access_scope(&self) -> AccessScope {
        self.scope
    }

    pub fn get_uuid(&self) -> Uuid {
        match &self.origin {
            IdentType::Internal(role) => role.get_uuid(),
            IdentType::User(u) => u.entry.get_uuid(),
            IdentType::Synch(u) => *u,
        }
    }

    pub fn get_event_origin_id(&self) -> IdentityId {
        IdentityId::from(&self.origin)
    }

    pub fn get_memberof(&self) -> Option<&BTreeSet<Uuid>> {
        match &self.origin {
            IdentType::Internal(_) | IdentType::Synch(_) => None,
            IdentType::User(u) => u.entry.get_ava_refer(Attribute::MemberOf),
        }
    }
}
