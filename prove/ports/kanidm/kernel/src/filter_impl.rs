//! Filter resolution and attribute sets (server/lib/src/filter.rs).
use crate::bset::insert;
use crate::identity_impl::get_uuid;
use crate::{Attribute, FilterComp, FilterResolved, Identity, PartialValue};

/// `Filter<FilterValid>::resolve(ev, None, cache)`: `resolve_no_idx`, then
/// `fast_optimise`, which only sorts and dedups `And`/`Inclusion` terms and
/// is left out. `None` is `Err(OperationError::FilterUuidResolution)`.
pub fn resolve(filter: &FilterComp, ev: &Identity) -> Option<FilterResolved> {
    resolve_no_idx(filter, ev)
}

/// `FilterResolved::resolve_no_idx`.
pub fn resolve_no_idx(fc: &FilterComp, ev: &Identity) -> Option<FilterResolved> {
    match fc {
        FilterComp::Eq(a, v) => Some(FilterResolved::Eq(a.clone(), v.clone())),
        FilterComp::SelfUuid => {
            let uuid = get_uuid(ev);
            Some(FilterResolved::Eq(b"uuid".to_vec(), PartialValue::Uuid(uuid)))
        }
        FilterComp::Cnt(a, v) => Some(FilterResolved::Cnt(a.clone(), v.clone())),
        FilterComp::Stw(a, v) => Some(FilterResolved::Stw(a.clone(), v.clone())),
        FilterComp::Enw(a, v) => Some(FilterResolved::Enw(a.clone(), v.clone())),
        FilterComp::Pres(a) => Some(FilterResolved::Pres(a.clone())),
        FilterComp::LessThan(a, v) => Some(FilterResolved::LessThan(a.clone(), v.clone())),
        FilterComp::Or(vs) => match resolve_no_idx_list(vs, ev, 0, Vec::new()) {
            Some(fi) => Some(FilterResolved::Or(fi)),
            None => None,
        },
        FilterComp::And(vs) => match resolve_no_idx_list(vs, ev, 0, Vec::new()) {
            Some(fi) => Some(FilterResolved::And(fi)),
            None => None,
        },
        FilterComp::Inclusion(vs) => match resolve_no_idx_list(vs, ev, 0, Vec::new()) {
            Some(fi) => Some(FilterResolved::Inclusion(fi)),
            None => None,
        },
        FilterComp::AndNot(f) => match resolve_no_idx(f, ev) {
            Some(fi) => Some(FilterResolved::AndNot(Box::new(fi))),
            None => None,
        },
        FilterComp::Invalid(attr) => Some(FilterResolved::Invalid(attr.clone())),
    }
}

/// `vs[i..].map(|f| resolve_no_idx(f, ev)).collect::<Option<Vec<_>>>()`,
/// appended to `acc`.
pub fn resolve_no_idx_list(
    vs: &Vec<FilterComp>,
    ev: &Identity,
    i: usize,
    mut acc: Vec<FilterResolved>,
) -> Option<Vec<FilterResolved>> {
    if i >= vs.len() {
        Some(acc)
    } else {
        match resolve_no_idx(&vs[i], ev) {
            Some(f) => {
                acc.push(f);
                resolve_no_idx_list(vs, ev, i + 1, acc)
            }
            None => None,
        }
    }
}

/// `Filter<FilterValid>::get_attr_set`.
pub fn get_attr_set(filter: &FilterComp) -> Vec<Attribute> {
    let mut r_set: Vec<Attribute> = Vec::new();
    fc_get_attr_set(filter, &mut r_set);
    r_set
}

/// `FilterComp::get_attr_set`.
pub fn fc_get_attr_set(fc: &FilterComp, r_set: &mut Vec<Attribute>) {
    match fc {
        FilterComp::Eq(attr, _)
        | FilterComp::Cnt(attr, _)
        | FilterComp::Stw(attr, _)
        | FilterComp::Enw(attr, _)
        | FilterComp::Pres(attr)
        | FilterComp::LessThan(attr, _)
        | FilterComp::Invalid(attr) => {
            insert(r_set, attr);
        }
        FilterComp::Or(vs) => fc_get_attr_set_list(vs, r_set, 0),
        FilterComp::And(vs) => fc_get_attr_set_list(vs, r_set, 0),
        FilterComp::Inclusion(vs) => fc_get_attr_set_list(vs, r_set, 0),
        FilterComp::AndNot(f) => fc_get_attr_set(f, r_set),
        FilterComp::SelfUuid => {
            insert(r_set, b"uuid");
        }
    }
}

/// `vs[i..].iter().for_each(|f| f.get_attr_set(r_set))`.
pub fn fc_get_attr_set_list(vs: &Vec<FilterComp>, r_set: &mut Vec<Attribute>, i: usize) {
    if i < vs.len() {
        fc_get_attr_set(&vs[i], r_set);
        fc_get_attr_set_list(vs, r_set, i + 1);
    }
}
