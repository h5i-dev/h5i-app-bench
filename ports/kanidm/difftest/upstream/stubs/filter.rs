// Stub of `filter.rs`: the filter states, the index metadata and the
// resolve cache. `FilterComp`, `FilterResolved`, their trait impls and the
// functions below the stubs are copied.
use crate::prelude::*;
use crate::server::identity::IdentityId;
use hashbrown::HashMap;
use std::cmp::{Ordering, PartialOrd};
use std::fmt;
use std::num::NonZeroU8;

#[derive(Clone, Debug)]
pub struct FilterInvalid {
    inner: FilterComp,
}
#[derive(Clone, Debug)]
pub struct FilterValid {
    inner: FilterComp,
}
#[derive(Clone, Debug)]
pub struct FilterValidResolved {
    pub(crate) inner: FilterResolved,
}
#[derive(Clone, Debug)]
pub struct Filter<STATE> {
    pub(crate) state: STATE,
}

pub type IdxKey = (Attribute, u8);
pub type IdxSlope = u8;

pub struct IdxMeta {
    pub idxkeys: HashMap<IdxKey, IdxSlope>,
}

#[derive(Default)]
pub struct ResolveFilterCacheReadTxn<'a> {
    _p: std::marker::PhantomData<&'a ()>,
}

impl ResolveFilterCacheReadTxn<'_> {
    pub fn get<K>(&mut self, _k: &K) -> Option<&Arc<Filter<FilterValidResolved>>> {
        None
    }
    pub fn insert<K>(&mut self, _k: K, _v: Arc<Filter<FilterValidResolved>>) {}
}

impl FilterResolved {
    // Stub: only reached with index metadata, which the access module never passes.
    fn resolve_idx(_fc: FilterComp, _ev: &Identity, _idxmeta: &HashMap<IdxKey, IdxSlope>) -> Option<Self> {
        unreachable!()
    }
}
