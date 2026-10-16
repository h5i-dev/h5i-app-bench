// Stub of `entry.rs`: the entry states carry only what the access module
// reads. `Entry`, `EntryReduced`, the `Clone` impl and the methods below the
// stubs are copied.
use crate::filter::{Filter, FilterResolved, FilterValidResolved};
use crate::prelude::*;
use crate::server::access::AccessEffectivePermission;
use std::collections::BTreeMap as Map;

pub type Eattrs = Map<Attribute, ValueSet>;

#[derive(Clone, Debug)]
pub struct EntryInit;
#[derive(Clone, Debug)]
pub struct EntryNew;
#[derive(Clone, Debug)]
pub struct EntryCommitted;
#[derive(Clone, Debug)]
pub struct EntrySealed {
    uuid: Uuid,
}

pub type EntryInitNew = Entry<EntryInit, EntryNew>;
pub type EntrySealedCommitted = Entry<EntrySealed, EntryCommitted>;
pub type EntryReducedCommitted = Entry<EntryReduced, EntryCommitted>;

impl<VALID, STATE> Entry<VALID, STATE> {
    // Stub: only logs read it.
    pub(crate) fn get_display_id(&self) -> String {
        String::new()
    }
}
