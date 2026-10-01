//! kanidm's access control engine (kanidm/kanidm @ f608c4f,
//! `server/lib/src/server/access/`) as an h5i-app kernel.
//!
//! One kernel function per upstream function, same names, same branch order.
//! Entries are attribute -> value-set tables, filters are the resolved
//! filter enum, sets are vectors. DEVIATIONS.md lists every difference.
#![allow(clippy::all)]

pub mod access;
pub mod bset;
pub mod create_acc;
pub mod delete_acc;
pub mod entry_impl;
pub mod filter_impl;
pub mod identity_impl;
pub mod migration;
pub mod modify_acc;
pub mod profiles;
pub mod protected;
pub mod search_acc;
pub mod valueset;

/// `uuid::Uuid`; its `Ord` is the big-endian byte order, which is `u128`'s.
pub type Uuid = u128;

/// `Attribute`, by its name (`Attribute::as_str`).
pub type Attribute = Vec<u8>;

/// `UUID_SYSTEM` (constants/uuids.rs).
pub const UUID_SYSTEM: Uuid = 0xffffff000000;
/// `UUID_INTERNAL_MIGRATION`.
pub const UUID_INTERNAL_MIGRATION: Uuid = 0xffffff000082;
/// `UUID_INTERNAL_ACCOUNT_REQUEST`.
pub const UUID_INTERNAL_ACCOUNT_REQUEST: Uuid = 0xffffff000084;
/// `UUID_INTERNAL_MESSAGE_QUEUE`.
pub const UUID_INTERNAL_MESSAGE_QUEUE: Uuid = 0xffffff000085;
/// `UUID_ANONYMOUS`. Entries at or below it are builtin.
pub const UUID_ANONYMOUS: Uuid = 0xffffffffffff;

/// `PartialValue`, for the syntaxes the access module meets. Also stands for
/// `Value`: the access module only reads `Value::to_str`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum PartialValue {
    Utf8(Vec<u8>),
    Iutf8(Vec<u8>),
    Iname(Vec<u8>),
    Uuid(Uuid),
    Refer(Uuid),
    Uint32(u32),
}

/// `Value`.
pub type Value = PartialValue;

/// `ValueSet` (`Arc<dyn ValueSetT>`), one variant per implementation used.
/// `OauthScopeMap` keeps only the map's keys (the groups granted scopes).
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ValueSet {
    Utf8(Vec<Vec<u8>>),
    Iutf8(Vec<Vec<u8>>),
    Iname(Vec<Vec<u8>>),
    Uuid(Vec<Uuid>),
    Refer(Vec<Uuid>),
    Uint32(Vec<u32>),
    OauthScopeMap(Vec<Uuid>),
}

/// One `(Attribute, ValueSet)` pair of `Eattrs`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Ava {
    pub attr: Attribute,
    pub vs: ValueSet,
}

/// `Entry<_, _>`: `attrs` is `Eattrs`, a map with one pair per attribute.
/// `uuid` is `EntrySealed::uuid`; entries being created read theirs from
/// `attrs` (`Entry<EntryInit, _>::get_uuid`).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Entry {
    pub uuid: Uuid,
    pub attrs: Vec<Ava>,
}

/// `InternalRole` (server/identity.rs).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum InternalRole {
    System,
    Migration,
    AccountRequest,
    MessageQueue,
}

/// `IdentUser`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct IdentUser {
    pub entry: Entry,
}

/// `IdentType`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum IdentType {
    User(IdentUser),
    Synch(Uuid),
    Internal(InternalRole),
}

/// `AccessScope`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AccessScope {
    ReadOnly,
    ReadWrite,
    Synchronise,
}

/// `Identity`, without source, session id, limits and verification time,
/// which the access module does not read.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Identity {
    pub origin: IdentType,
    pub scope: AccessScope,
}

/// `FilterComp` (filter.rs): the inner term of a `Filter<FilterValid>`.
#[derive(Debug, PartialEq, Eq)]
pub enum FilterComp {
    Eq(Attribute, PartialValue),
    Cnt(Attribute, PartialValue),
    Stw(Attribute, PartialValue),
    Enw(Attribute, PartialValue),
    Pres(Attribute),
    LessThan(Attribute, PartialValue),
    Or(Vec<FilterComp>),
    And(Vec<FilterComp>),
    Inclusion(Vec<FilterComp>),
    AndNot(Box<FilterComp>),
    SelfUuid,
    Invalid(Attribute),
}

/// `FilterResolved`, without the index slope (`Option<NonZeroU8>`), which
/// only orders terms.
#[derive(Debug, PartialEq, Eq)]
pub enum FilterResolved {
    Eq(Attribute, PartialValue),
    Cnt(Attribute, PartialValue),
    Stw(Attribute, PartialValue),
    Enw(Attribute, PartialValue),
    Pres(Attribute),
    LessThan(Attribute, PartialValue),
    Or(Vec<FilterResolved>),
    And(Vec<FilterResolved>),
    Invalid(Attribute),
    Inclusion(Vec<FilterResolved>),
    AndNot(Box<FilterResolved>),
}

/// `Modify` (modify.rs).
#[derive(Debug, PartialEq, Eq)]
pub enum Modify {
    Present(Attribute, Value),
    Removed(Attribute, PartialValue),
    Purged(Attribute),
    Assert(Attribute, PartialValue),
    Set(Attribute, ValueSet),
}

/// `OperationError`, the variants the access module returns.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum OperationError {
    InvalidState,
}

/// `Access` (access/mod.rs).
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Access {
    Grant,
    Deny,
    Allow(Vec<Attribute>),
}

/// `AccessClass`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum AccessClass {
    Grant,
    Deny,
    Allow(Vec<Vec<u8>>),
}

/// `AccessEffectivePermission`.
#[derive(Debug, PartialEq, Eq)]
pub struct AccessEffectivePermission {
    pub ident: Uuid,
    pub target: Uuid,
    pub delete: bool,
    pub search: Access,
    pub modify_pres: Access,
    pub modify_rem: Access,
    pub modify_pres_class: AccessClass,
    pub modify_rem_class: AccessClass,
}

/// `Entry<EntryReduced, EntryCommitted>`.
#[derive(Debug, PartialEq, Eq)]
pub struct EntryReduced {
    pub uuid: Uuid,
    pub attrs: Vec<Ava>,
    pub effective_access: Option<AccessEffectivePermission>,
}

/// `AccessBasicResult`.
pub enum AccessBasicResult {
    Deny,
    Grant,
    Ignore,
}

/// `AccessSrchResult`.
pub enum AccessSrchResult {
    Deny,
    Grant,
    Ignore,
    Allow { attr: Vec<Attribute> },
}

/// `AccessModResult`.
pub enum AccessModResult {
    Deny,
    Ignore,
    Constrain {
        pres_attr: Vec<Attribute>,
        rem_attr: Vec<Attribute>,
        pres_cls: Option<Vec<Vec<u8>>>,
        rem_cls: Option<Vec<Vec<u8>>>,
    },
    Allow {
        pres_attr: Vec<Attribute>,
        rem_attr: Vec<Attribute>,
        pres_class: Vec<Vec<u8>>,
        rem_class: Vec<Vec<u8>>,
    },
}

/// One `(Uuid, BTreeSet<Attribute>)` of the sync agreements map: the
/// attributes a sync agreement yields authority over.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SyncAgreement {
    pub uuid: Uuid,
    pub attrs: Vec<Attribute>,
}

/// `AccessControlsInner`: the loaded profiles and the sync agreements.
pub struct AccessControlsInner {
    pub acps_search: Vec<profiles::AccessControlSearch>,
    pub acps_create: Vec<profiles::AccessControlCreate>,
    pub acps_modify: Vec<profiles::AccessControlModify>,
    pub acps_delete: Vec<profiles::AccessControlDelete>,
    pub sync_agreements: Vec<SyncAgreement>,
}

/// `SearchEvent`, the fields the access module reads.
pub struct SearchEvent {
    pub ident: Identity,
    pub filter_orig: FilterComp,
    pub attrs: Option<Vec<Attribute>>,
    pub effective_access_check: bool,
}

/// `ModifyEvent`.
pub struct ModifyEvent {
    pub ident: Identity,
    pub modlist: Vec<Modify>,
}

/// One `(Uuid, ModifyList)` of `BatchModifyEvent::modset`.
pub struct ModSetEntry {
    pub uuid: Uuid,
    pub modlist: Vec<Modify>,
}

/// `BatchModifyEvent`.
pub struct BatchModifyEvent {
    pub ident: Identity,
    pub modset: Vec<ModSetEntry>,
}

/// `CreateEvent`.
pub struct CreateEvent {
    pub ident: Identity,
}

/// `DeleteEvent`.
pub struct DeleteEvent {
    pub ident: Identity,
}
