//! The `Entry` accessors and the filter matcher the access module calls
//! (server/lib/src/entry.rs).
use crate::bset::{bytes_eq, contains};
use crate::valueset::{
    as_iutf8_set, as_oauthscopemap, as_refer_set, to_refer_single, to_uuid_single, vs_contains,
    vs_endswith, vs_lessthan, vs_startswith, vs_substring,
};
use crate::{AccessEffectivePermission, Attribute, Ava, Entry, EntryReduced, FilterResolved, PartialValue, Uuid, ValueSet};

/// `get_ava_set`: `self.attrs.get(attr)`.
pub fn get_ava_set<'a>(e: &'a Entry, attr: &[u8]) -> Option<&'a ValueSet> {
    let mut i = 0;
    while i < e.attrs.len() {
        if bytes_eq(&e.attrs[i].attr, attr) {
            return Some(&e.attrs[i].vs);
        }
        i += 1;
    }
    None
}

/// `get_ava_refer`.
pub fn get_ava_refer<'a>(e: &'a Entry, attr: &[u8]) -> Option<&'a Vec<Uuid>> {
    match get_ava_set(e, attr) {
        Some(vs) => as_refer_set(vs),
        None => None,
    }
}

/// `get_ava_as_iutf8` (and `get_ava_iter_iutf8`).
pub fn get_ava_as_iutf8<'a>(e: &'a Entry, attr: &[u8]) -> Option<&'a Vec<Vec<u8>>> {
    match get_ava_set(e, attr) {
        Some(vs) => as_iutf8_set(vs),
        None => None,
    }
}

/// `get_ava_single_refer`.
pub fn get_ava_single_refer(e: &Entry, attr: &[u8]) -> Option<Uuid> {
    match get_ava_set(e, attr) {
        Some(vs) => to_refer_single(vs),
        None => None,
    }
}

/// `get_ava_as_oauthscopemaps`, the map's keys.
pub fn get_ava_as_oauthscopemaps<'a>(e: &'a Entry, attr: &[u8]) -> Option<&'a Vec<Uuid>> {
    match get_ava_set(e, attr) {
        Some(vs) => as_oauthscopemap(vs),
        None => None,
    }
}

/// `get_ava_names` / `attr_keys`.
pub fn get_ava_names(e: &Entry) -> Vec<Attribute> {
    let mut out: Vec<Attribute> = Vec::new();
    let mut i = 0;
    while i < e.attrs.len() {
        out.push(e.attrs[i].attr.clone());
        i += 1;
    }
    out
}

/// `Entry<EntryInit, _>::get_uuid`.
pub fn get_uuid_init(e: &Entry) -> Option<Uuid> {
    match get_ava_set(e, b"uuid") {
        Some(vs) => to_uuid_single(vs),
        None => None,
    }
}

/// `get_ava_as_iutf8(Attribute::Class).map(|set| set.contains(class)).unwrap_or(false)`.
pub fn class_contains(e: &Entry, class: &[u8]) -> bool {
    match get_ava_as_iutf8(e, b"class") {
        Some(set) => contains(set, class),
        None => false,
    }
}

/// `attribute_pres`.
pub fn attribute_pres(e: &Entry, attr: &[u8]) -> bool {
    match get_ava_set(e, attr) {
        Some(_) => true,
        None => false,
    }
}

/// `attribute_equality`.
pub fn attribute_equality(e: &Entry, attr: &[u8], value: &PartialValue) -> bool {
    match get_ava_set(e, attr) {
        Some(v_list) => vs_contains(v_list, value),
        None => false,
    }
}

/// `attribute_substring`.
pub fn attribute_substring(e: &Entry, attr: &[u8], subvalue: &PartialValue) -> bool {
    match get_ava_set(e, attr) {
        Some(vset) => vs_substring(vset, subvalue),
        None => false,
    }
}

/// `attribute_startswith`.
pub fn attribute_startswith(e: &Entry, attr: &[u8], subvalue: &PartialValue) -> bool {
    match get_ava_set(e, attr) {
        Some(vset) => vs_startswith(vset, subvalue),
        None => false,
    }
}

/// `attribute_endswith`.
pub fn attribute_endswith(e: &Entry, attr: &[u8], subvalue: &PartialValue) -> bool {
    match get_ava_set(e, attr) {
        Some(vset) => vs_endswith(vset, subvalue),
        None => false,
    }
}

/// `attribute_lessthan`.
pub fn attribute_lessthan(e: &Entry, attr: &[u8], subvalue: &PartialValue) -> bool {
    match get_ava_set(e, attr) {
        Some(vset) => vs_lessthan(vset, subvalue),
        None => false,
    }
}

/// `entry_match_no_index`.
pub fn entry_match_no_index(e: &Entry, filter: &FilterResolved) -> bool {
    entry_match_no_index_inner(e, filter)
}

/// `entry_match_no_index_inner`.
pub fn entry_match_no_index_inner(e: &Entry, filter: &FilterResolved) -> bool {
    match filter {
        FilterResolved::Eq(attr, value) => attribute_equality(e, attr, value),
        FilterResolved::Cnt(attr, subvalue) => attribute_substring(e, attr, subvalue),
        FilterResolved::Stw(attr, subvalue) => attribute_startswith(e, attr, subvalue),
        FilterResolved::Enw(attr, subvalue) => attribute_endswith(e, attr, subvalue),
        FilterResolved::Pres(attr) => attribute_pres(e, attr),
        FilterResolved::LessThan(attr, subvalue) => attribute_lessthan(e, attr, subvalue),
        // `l.iter().any(..)`
        FilterResolved::Or(l) => match_any(e, l, 0),
        // `l.iter().all(..)`
        FilterResolved::And(l) => match_all(e, l, 0),
        FilterResolved::Inclusion(_) => false,
        FilterResolved::AndNot(f) => !entry_match_no_index_inner(e, f),
        FilterResolved::Invalid(_) => false,
    }
}

/// `l[i..].iter().any(|f| self.entry_match_no_index_inner(f))`.
pub fn match_any(e: &Entry, l: &Vec<FilterResolved>, i: usize) -> bool {
    if i >= l.len() {
        false
    } else if entry_match_no_index_inner(e, &l[i]) {
        true
    } else {
        match_any(e, l, i + 1)
    }
}

/// `l[i..].iter().all(|f| self.entry_match_no_index_inner(f))`.
pub fn match_all(e: &Entry, l: &Vec<FilterResolved>, i: usize) -> bool {
    if i >= l.len() {
        true
    } else if !entry_match_no_index_inner(e, &l[i]) {
        false
    } else {
        match_all(e, l, i + 1)
    }
}

/// `reduce_attributes`: keep the pairs whose attribute is allowed.
pub fn reduce_attributes(
    e: &Entry,
    allowed_attrs: &[Attribute],
    effective_access: Option<AccessEffectivePermission>,
) -> EntryReduced {
    let mut f_attrs: Vec<Ava> = Vec::new();
    let mut i = 0;
    while i < e.attrs.len() {
        let kv = e.attrs[i].clone();
        if contains(allowed_attrs, &kv.attr) {
            f_attrs.push(kv);
        }
        i += 1;
    }
    EntryReduced { uuid: e.uuid, attrs: f_attrs, effective_access }
}
