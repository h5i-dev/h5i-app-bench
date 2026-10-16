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

// Copied from kanidm/kanidm @ f608c4f by extract_upstream.py. Do not edit.
/// This is the filters internal representation
#[derive(Clone, Hash, PartialEq, PartialOrd, Ord, Eq)]
enum FilterComp {
    // This is attr - value
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
    // Does this mean we can add a true not to the type now?
    // Not(Box<FilterComp>),
}

impl fmt::Debug for FilterComp {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            FilterComp::Eq(attr, pv) => {
                write!(f, "{attr} eq {pv:?}")
            }
            FilterComp::Cnt(attr, pv) => {
                write!(f, "{attr} cnt {pv:?}")
            }
            FilterComp::Stw(attr, pv) => {
                write!(f, "{attr} stw {pv:?}")
            }
            FilterComp::Enw(attr, pv) => {
                write!(f, "{attr} enw {pv:?}")
            }
            FilterComp::Pres(attr) => {
                write!(f, "{attr} pres")
            }
            FilterComp::LessThan(attr, pv) => {
                write!(f, "{attr} lt {pv:?}")
            }
            FilterComp::And(list) => {
                write!(f, "(")?;
                for (i, fc) in list.iter().enumerate() {
                    write!(f, "{fc:?}")?;
                    if i != list.len() - 1 {
                        write!(f, " and ")?;
                    }
                }
                write!(f, ")")
            }
            FilterComp::Or(list) => {
                write!(f, "(")?;
                for (i, fc) in list.iter().enumerate() {
                    write!(f, "{fc:?}")?;
                    if i != list.len() - 1 {
                        write!(f, " or ")?;
                    }
                }
                write!(f, ")")
            }
            FilterComp::Inclusion(list) => {
                write!(f, "(")?;
                for (i, fc) in list.iter().enumerate() {
                    write!(f, "{fc:?}")?;
                    if i != list.len() - 1 {
                        write!(f, " inc ")?;
                    }
                }
                write!(f, ")")
            }
            FilterComp::AndNot(inner) => {
                write!(f, "not ( {inner:?} )")
            }
            FilterComp::SelfUuid => {
                write!(f, "uuid eq self")
            }
            FilterComp::Invalid(attr) => {
                write!(f, "invalid ( {attr:?} )")
            }
        }
    }
}

/// This is the fully resolved internal representation. Note the lack of Not and selfUUID
/// because these are resolved into And(Pres(class), AndNot(term)) and Eq(uuid, ...) respectively.
/// Importantly, we make this accessible to Entry so that it can then match on filters
/// internally.
///
/// Each filter that has been resolved also has been enriched with metadata about its
/// index, and index slope. For the purpose of this module, consider slope as a "weight"
/// where small value - faster index, larger value - slower index. This metadata is extremely
/// important for the query optimiser to make decisions about how to re-arrange queries
/// correctly.
#[derive(Clone, Eq)]
pub enum FilterResolved {
    // This is attr - value - indexed slope factor
    Eq(Attribute, PartialValue, Option<NonZeroU8>),
    Cnt(Attribute, PartialValue, Option<NonZeroU8>),
    Stw(Attribute, PartialValue, Option<NonZeroU8>),
    Enw(Attribute, PartialValue, Option<NonZeroU8>),
    Pres(Attribute, Option<NonZeroU8>),
    LessThan(Attribute, PartialValue, Option<NonZeroU8>),
    Or(Vec<FilterResolved>, Option<NonZeroU8>),
    And(Vec<FilterResolved>, Option<NonZeroU8>),
    Invalid(Attribute),
    // All terms must have 1 or more items, or the inclusion is false!
    Inclusion(Vec<FilterResolved>, Option<NonZeroU8>),
    AndNot(Box<FilterResolved>, Option<NonZeroU8>),
}

impl fmt::Debug for FilterResolved {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            FilterResolved::Eq(attr, pv, idx) => {
                write!(
                    f,
                    "(s{} {} eq {:?})",
                    idx.unwrap_or(NonZeroU8::MAX),
                    attr,
                    pv
                )
            }
            FilterResolved::Cnt(attr, pv, idx) => {
                write!(
                    f,
                    "(s{} {} cnt {:?})",
                    idx.unwrap_or(NonZeroU8::MAX),
                    attr,
                    pv
                )
            }
            FilterResolved::Stw(attr, pv, idx) => {
                write!(
                    f,
                    "(s{} {} stw {:?})",
                    idx.unwrap_or(NonZeroU8::MAX),
                    attr,
                    pv
                )
            }
            FilterResolved::Enw(attr, pv, idx) => {
                write!(
                    f,
                    "(s{} {} enw {:?})",
                    idx.unwrap_or(NonZeroU8::MAX),
                    attr,
                    pv
                )
            }
            FilterResolved::Pres(attr, idx) => {
                write!(f, "(s{} {} pres)", idx.unwrap_or(NonZeroU8::MAX), attr)
            }
            FilterResolved::LessThan(attr, pv, idx) => {
                write!(
                    f,
                    "(s{} {} lt {:?})",
                    idx.unwrap_or(NonZeroU8::MAX),
                    attr,
                    pv
                )
            }
            FilterResolved::And(list, idx) => {
                write!(f, "(s{} ", idx.unwrap_or(NonZeroU8::MAX))?;
                for (i, fc) in list.iter().enumerate() {
                    write!(f, "{fc:?}")?;
                    if i != list.len() - 1 {
                        write!(f, " and ")?;
                    }
                }
                write!(f, ")")
            }
            FilterResolved::Or(list, idx) => {
                write!(f, "(s{} ", idx.unwrap_or(NonZeroU8::MAX))?;
                for (i, fc) in list.iter().enumerate() {
                    write!(f, "{fc:?}")?;
                    if i != list.len() - 1 {
                        write!(f, " or ")?;
                    }
                }
                write!(f, ")")
            }
            FilterResolved::Inclusion(list, idx) => {
                write!(f, "(s{} ", idx.unwrap_or(NonZeroU8::MAX))?;
                for (i, fc) in list.iter().enumerate() {
                    write!(f, "{fc:?}")?;
                    if i != list.len() - 1 {
                        write!(f, " inc ")?;
                    }
                }
                write!(f, ")")
            }
            FilterResolved::AndNot(inner, idx) => {
                write!(f, "not (s{} {:?})", idx.unwrap_or(NonZeroU8::MAX), inner)
            }
            FilterResolved::Invalid(attr) => {
                write!(f, "{attr} inv")
            }
        }
    }
}

impl PartialEq for FilterResolved {
    fn eq(&self, rhs: &FilterResolved) -> bool {
        match (self, rhs) {
            (FilterResolved::Eq(a1, v1, _), FilterResolved::Eq(a2, v2, _)) => a1 == a2 && v1 == v2,
            (FilterResolved::Cnt(a1, v1, _), FilterResolved::Cnt(a2, v2, _)) => {
                a1 == a2 && v1 == v2
            }
            (FilterResolved::Pres(a1, _), FilterResolved::Pres(a2, _)) => a1 == a2,
            (FilterResolved::LessThan(a1, v1, _), FilterResolved::LessThan(a2, v2, _)) => {
                a1 == a2 && v1 == v2
            }
            (FilterResolved::And(vs1, _), FilterResolved::And(vs2, _)) => vs1 == vs2,
            (FilterResolved::Or(vs1, _), FilterResolved::Or(vs2, _)) => vs1 == vs2,
            (FilterResolved::Inclusion(vs1, _), FilterResolved::Inclusion(vs2, _)) => vs1 == vs2,
            (FilterResolved::AndNot(f1, _), FilterResolved::AndNot(f2, _)) => f1 == f2,
            (_, _) => false,
        }
    }
}

impl PartialOrd for FilterResolved {
    fn partial_cmp(&self, rhs: &FilterResolved) -> Option<Ordering> {
        Some(self.cmp(rhs))
    }
}

impl Ord for FilterResolved {
    /// Ordering of filters for optimisation and subsequent dead term elimination.
    fn cmp(&self, rhs: &FilterResolved) -> Ordering {
        let left_slopey = self.get_slopeyness_factor();
        let right_slopey = rhs.get_slopeyness_factor();

        let r = match (left_slopey, right_slopey) {
            (Some(sfl), Some(sfr)) => sfl.cmp(&sfr),
            (Some(_), None) => Ordering::Less,
            (None, Some(_)) => Ordering::Greater,
            (None, None) => Ordering::Equal,
        };

        // If they are equal, compare other elements for determining the order. This is what
        // allows dead term elimination to occur.
        //
        // In almost all cases, we'll miss this step though as slopes will vary distinctly.
        //
        // We do NOT need to check for indexed vs unindexed here, we already did it in the slope check!
        if r == Ordering::Equal {
            match (self, rhs) {
                (FilterResolved::Eq(a1, v1, _), FilterResolved::Eq(a2, v2, _))
                | (FilterResolved::Cnt(a1, v1, _), FilterResolved::Cnt(a2, v2, _))
                | (FilterResolved::LessThan(a1, v1, _), FilterResolved::LessThan(a2, v2, _)) => {
                    match a1.cmp(a2) {
                        Ordering::Equal => v1.cmp(v2),
                        o => o,
                    }
                }
                (FilterResolved::Pres(a1, _), FilterResolved::Pres(a2, _)) => a1.cmp(a2),
                // Now sort these into the generally "best" order.
                (FilterResolved::Eq(_, _, _), _) => Ordering::Less,
                (_, FilterResolved::Eq(_, _, _)) => Ordering::Greater,
                (FilterResolved::Pres(_, _), _) => Ordering::Less,
                (_, FilterResolved::Pres(_, _)) => Ordering::Greater,
                (FilterResolved::LessThan(_, _, _), _) => Ordering::Less,
                (_, FilterResolved::LessThan(_, _, _)) => Ordering::Greater,
                (FilterResolved::Cnt(_, _, _), _) => Ordering::Less,
                (_, FilterResolved::Cnt(_, _, _)) => Ordering::Greater,
                // They can't be re-arranged, they don't move!
                (_, _) => Ordering::Equal,
            }
        } else {
            r
        }
    }
}

impl Filter<FilterValidResolved> {
    pub fn to_inner(&self) -> &FilterResolved {
        &self.state.inner
    }
}

impl Filter<FilterValid> {
    pub fn resolve(
        &self,
        ev: &Identity,
        idxmeta: Option<&IdxMeta>,
        mut rsv_cache: Option<&mut ResolveFilterCacheReadTxn<'_>>,
    ) -> Result<Filter<FilterValidResolved>, OperationError> {
        // Given a filter, resolve Not and SelfUuid to real terms.
        //
        // The benefit of moving optimisation to this step is from various inputs, we can
        // get to a resolved + optimised filter, and then we can cache those outputs in many
        // cases! The exception is *large* filters, especially from the memberof plugin. We
        // want to skip these because they can really jam up the server.

        // Don't cache anything unless we have valid indexing metadata.
        let cacheable = idxmeta.is_some() && FilterResolved::resolve_cacheable(&self.state.inner);

        let cache_key = if cacheable {
            // do we have a cache?
            if let Some(rcache) = rsv_cache.as_mut() {
                // construct the key. For now it's expensive because we have to clone, but ... eh.
                let cache_key = (ev.get_event_origin_id(), Arc::new(self.clone()));
                if let Some(f) = rcache.get(&cache_key) {
                    // Got it? Shortcut and return!
                    trace!("shortcut: a resolved filter already exists.");
                    return Ok(f.as_ref().clone());
                };
                // Not in cache? Set the cache_key.
                Some(cache_key)
            } else {
                None
            }
        } else {
            // Not cacheable, lets just bail.
            None
        };

        // If we got here, nothing in cache - resolve it the hard way.

        let resolved_filt = Filter {
            state: FilterValidResolved {
                inner: match idxmeta {
                    Some(idx) => {
                        FilterResolved::resolve_idx(self.state.inner.clone(), ev, &idx.idxkeys)
                    }
                    None => FilterResolved::resolve_no_idx(self.state.inner.clone(), ev),
                }
                .map(|f| {
                    match idxmeta {
                        // Do a proper optimise if we have idxmeta.
                        Some(_) => f.optimise(),
                        // Only do this if we don't have idxmeta.
                        None => f.fast_optimise(),
                    }
                })
                .ok_or(OperationError::FilterUuidResolution)?,
            },
        };

        // Now it's computed, inject it. Remember, we won't have a cache_key here
        // if cacheable == false.
        if let Some(cache_key) = cache_key {
            if let Some(rcache) = rsv_cache.as_mut() {
                trace!(?resolved_filt, "inserting filter to resolved cache");
                rcache.insert(cache_key, Arc::new(resolved_filt.clone()));
            }
        }

        Ok(resolved_filt)
    }

    pub fn get_attr_set(&self) -> BTreeSet<Attribute> {
        // Recurse through the filter getting an attribute set.
        let mut r_set = BTreeSet::new();
        self.state.inner.get_attr_set(&mut r_set);
        r_set
    }
}

impl FilterComp {
    fn get_attr_set(&self, r_set: &mut BTreeSet<Attribute>) {
        match self {
            FilterComp::Eq(attr, _)
            | FilterComp::Cnt(attr, _)
            | FilterComp::Stw(attr, _)
            | FilterComp::Enw(attr, _)
            | FilterComp::Pres(attr)
            | FilterComp::LessThan(attr, _)
            | FilterComp::Invalid(attr) => {
                r_set.insert(attr.clone());
            }
            FilterComp::Or(vs) => vs.iter().for_each(|f| f.get_attr_set(r_set)),
            FilterComp::And(vs) => vs.iter().for_each(|f| f.get_attr_set(r_set)),
            FilterComp::Inclusion(vs) => vs.iter().for_each(|f| f.get_attr_set(r_set)),
            FilterComp::AndNot(f) => f.get_attr_set(r_set),
            FilterComp::SelfUuid => {
                r_set.insert(Attribute::Uuid);
            }
        }
    }
}

impl FilterResolved {
    fn resolve_cacheable(fc: &FilterComp) -> bool {
        match fc {
            FilterComp::Or(vs) | FilterComp::And(vs) | FilterComp::Inclusion(vs) => {
                if vs.len() < 8 {
                    vs.iter().all(FilterResolved::resolve_cacheable)
                } else {
                    // Too lorge.
                    false
                }
            }
            FilterComp::AndNot(f) => FilterResolved::resolve_cacheable(f.as_ref()),
            FilterComp::Eq(..)
            | FilterComp::SelfUuid
            | FilterComp::Cnt(..)
            | FilterComp::Stw(..)
            | FilterComp::Enw(..)
            | FilterComp::Pres(_)
            | FilterComp::Invalid(_)
            | FilterComp::LessThan(..) => true,
        }
    }

    fn resolve_no_idx(fc: FilterComp, ev: &Identity) -> Option<Self> {
        // ⚠️  ⚠️  ⚠️  ⚠️
        // Remember, this function means we have NO INDEX METADATA so we can only
        // assign slopes to values we can GUARANTEE will EXIST.
        match fc {
            FilterComp::Eq(a, v) => {
                // Since we have no index data, we manually configure a reasonable
                // slope and indicate the presence of some expected basic
                // indexes.
                let idx = matches!(a.as_str(), ATTR_NAME | ATTR_UUID);
                let idx = NonZeroU8::new(idx as u8);
                Some(FilterResolved::Eq(a, v, idx))
            }
            FilterComp::SelfUuid => {
                let uuid = ev.get_uuid();
                Some(FilterResolved::Eq(
                    Attribute::Uuid,
                    PartialValue::Uuid(uuid),
                    NonZeroU8::new(true as u8),
                ))
            }
            FilterComp::Cnt(a, v) => Some(FilterResolved::Cnt(a, v, None)),
            FilterComp::Stw(a, v) => Some(FilterResolved::Stw(a, v, None)),
            FilterComp::Enw(a, v) => Some(FilterResolved::Enw(a, v, None)),
            FilterComp::Pres(a) => Some(FilterResolved::Pres(a, None)),
            FilterComp::LessThan(a, v) => Some(FilterResolved::LessThan(a, v, None)),
            FilterComp::Or(vs) => {
                let fi: Option<Vec<_>> = vs
                    .into_iter()
                    .map(|f| FilterResolved::resolve_no_idx(f, ev))
                    .collect();
                fi.map(|fi| FilterResolved::Or(fi, None))
            }
            FilterComp::And(vs) => {
                let fi: Option<Vec<_>> = vs
                    .into_iter()
                    .map(|f| FilterResolved::resolve_no_idx(f, ev))
                    .collect();
                fi.map(|fi| FilterResolved::And(fi, None))
            }
            FilterComp::Inclusion(vs) => {
                let fi: Option<Vec<_>> = vs
                    .into_iter()
                    .map(|f| FilterResolved::resolve_no_idx(f, ev))
                    .collect();
                fi.map(|fi| FilterResolved::Inclusion(fi, None))
            }
            FilterComp::AndNot(f) => {
                // TODO: pattern match box here. (AndNot(box f)).
                // We have to clone f into our space here because pattern matching can
                // not today remove the box, and we need f in our ownership. Since
                // AndNot currently is a rare request, cloning is not the worst thing
                // here ...
                FilterResolved::resolve_no_idx((*f).clone(), ev)
                    .map(|fi| FilterResolved::AndNot(Box::new(fi), None))
            }
            FilterComp::Invalid(attr) => Some(FilterResolved::Invalid(attr)),
        }
    }

    fn fast_optimise(self) -> Self {
        match self {
            FilterResolved::Inclusion(mut f_list, _) => {
                f_list.sort_unstable();
                f_list.dedup();
                let sf = f_list.last().and_then(|f| f.get_slopeyness_factor());
                FilterResolved::Inclusion(f_list, sf)
            }
            FilterResolved::And(mut f_list, _) => {
                f_list.sort_unstable();
                f_list.dedup();
                let sf = f_list.first().and_then(|f| f.get_slopeyness_factor());
                FilterResolved::And(f_list, sf)
            }
            v => v,
        }
    }

    fn optimise(&self) -> Self {
        // Most optimisations only matter around or/and terms.
        match self {
            FilterResolved::Inclusion(f_list, _) => {
                // first, optimise all our inner elements
                let (f_list_inc, mut f_list_new): (Vec<_>, Vec<_>) = f_list
                    .iter()
                    .map(|f_ref| f_ref.optimise())
                    .partition(|f| matches!(f, FilterResolved::Inclusion(_, _)));

                f_list_inc.into_iter().for_each(|fc| {
                    if let FilterResolved::Inclusion(mut l, _) = fc {
                        f_list_new.append(&mut l)
                    }
                });
                // finally, optimise this list by sorting.
                f_list_new.sort_unstable();
                f_list_new.dedup();
                // Inclusions are similar to or, so what's our worst case?
                let sf = f_list_new.last().and_then(|f| f.get_slopeyness_factor());
                FilterResolved::Inclusion(f_list_new, sf)
            }
            FilterResolved::And(f_list, _) => {
                // first, optimise all our inner elements
                let (f_list_and, mut f_list_new): (Vec<_>, Vec<_>) = f_list
                    .iter()
                    .map(|f_ref| f_ref.optimise())
                    .partition(|f| matches!(f, FilterResolved::And(_, _)));

                // now, iterate over this list - for each "and" term, fold
                // it's elements to this level.
                // This is one of the most important improvements because it means
                // that we can compare terms such that:
                //
                // (&(class=*)(&(uid=foo)))
                // if we did not and fold, this would remain as is. However, by and
                // folding, we can optimise to:
                // (&(uid=foo)(class=*))
                // Which will be faster when indexed as the uid=foo will trigger
                // shortcutting

                f_list_and.into_iter().for_each(|fc| {
                    if let FilterResolved::And(mut l, _) = fc {
                        f_list_new.append(&mut l)
                    }
                });

                // If the f_list_and only has one element, pop it and return.
                if f_list_new.len() == 1 {
                    f_list_new.remove(0)
                } else {
                    // finally, optimise this list by sorting.
                    f_list_new.sort_unstable();
                    f_list_new.dedup();
                    // Which ever element as the head is first must be the min SF
                    // so we use this in our And to represent the "best possible" value
                    // of how indexes will perform.
                    let sf = f_list_new.first().and_then(|f| f.get_slopeyness_factor());
                    //
                    // return!
                    FilterResolved::And(f_list_new, sf)
                }
            }
            FilterResolved::Or(f_list, _) => {
                let (f_list_or, mut f_list_new): (Vec<_>, Vec<_>) = f_list
                    .iter()
                    // Optimise all inner items.
                    .map(|f_ref| f_ref.optimise())
                    // Split out inner-or terms to fold into this term.
                    .partition(|f| matches!(f, FilterResolved::Or(_, _)));

                // Append the inner terms.
                f_list_or.into_iter().for_each(|fc| {
                    if let FilterResolved::Or(mut l, _) = fc {
                        f_list_new.append(&mut l)
                    }
                });

                // If the f_list_or only has one element, pop it and return.
                if f_list_new.len() == 1 {
                    f_list_new.remove(0)
                } else {
                    // sort, but reverse so that sub-optimal elements are earlier
                    // to promote fast-failure.
                    // We have to allow this on clippy, which attempts to suggest:
                    //   f_list_new.sort_unstable_by_key(|&b| Reverse(b))
                    // However, because these are references, it causes a lifetime
                    // issue, and fails to compile.
                    #[allow(clippy::unnecessary_sort_by)]
                    f_list_new.sort_unstable_by(|a, b| b.cmp(a));
                    f_list_new.dedup();
                    // The *last* element is the most here, and our worst case factor.
                    let sf = f_list_new.last().and_then(|f| f.get_slopeyness_factor());
                    FilterResolved::Or(f_list_new, sf)
                }
            }
            f => f.clone(),
        }
    }

    #[inline(always)]
    fn get_slopeyness_factor(&self) -> Option<NonZeroU8> {
        match self {
            FilterResolved::Eq(_, _, sf)
            | FilterResolved::Cnt(_, _, sf)
            | FilterResolved::Stw(_, _, sf)
            | FilterResolved::Enw(_, _, sf)
            | FilterResolved::Pres(_, sf)
            | FilterResolved::LessThan(_, _, sf)
            | FilterResolved::Or(_, sf)
            | FilterResolved::And(_, sf)
            | FilterResolved::Inclusion(_, sf)
            | FilterResolved::AndNot(_, sf) => *sf,
            // We hard code 1 because there is no slope for an invalid filter
            FilterResolved::Invalid(_) => NonZeroU8::new(1),
        }
    }
}

// ---- Test seam (not upstream): `FilterComp` is private; build it from a
// public mirror. ----

#[derive(Clone, Debug)]
pub enum DFilter {
    Eq(Attribute, PartialValue),
    Cnt(Attribute, PartialValue),
    Stw(Attribute, PartialValue),
    Enw(Attribute, PartialValue),
    Pres(Attribute),
    LessThan(Attribute, PartialValue),
    Or(Vec<DFilter>),
    And(Vec<DFilter>),
    Inclusion(Vec<DFilter>),
    AndNot(Box<DFilter>),
    SelfUuid,
    Invalid(Attribute),
}

fn dfc(f: DFilter) -> FilterComp {
    match f {
        DFilter::Eq(a, v) => FilterComp::Eq(a, v),
        DFilter::Cnt(a, v) => FilterComp::Cnt(a, v),
        DFilter::Stw(a, v) => FilterComp::Stw(a, v),
        DFilter::Enw(a, v) => FilterComp::Enw(a, v),
        DFilter::Pres(a) => FilterComp::Pres(a),
        DFilter::LessThan(a, v) => FilterComp::LessThan(a, v),
        DFilter::Or(l) => FilterComp::Or(l.into_iter().map(dfc).collect()),
        DFilter::And(l) => FilterComp::And(l.into_iter().map(dfc).collect()),
        DFilter::Inclusion(l) => FilterComp::Inclusion(l.into_iter().map(dfc).collect()),
        DFilter::AndNot(b) => FilterComp::AndNot(Box::new(dfc(*b))),
        DFilter::SelfUuid => FilterComp::SelfUuid,
        DFilter::Invalid(a) => FilterComp::Invalid(a),
    }
}

impl Filter<FilterValid> {
    pub fn difftest_new(f: DFilter) -> Self {
        Filter { state: FilterValid { inner: dfc(f) } }
    }
}
