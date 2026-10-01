//! The `ValueSetT` methods the access module reaches, from
//! server/lib/src/valueset/{utf8,iutf8,iname,uuid,uint32,oauth}.rs.
use crate::bset::{contains, contains_uuid};
use crate::{PartialValue, Uuid, ValueSet};

/// `str::contains`.
pub fn str_contains(hay: &[u8], needle: &[u8]) -> bool {
    if needle.len() > hay.len() {
        return false;
    }
    let mut i = 0;
    while i + needle.len() <= hay.len() {
        if starts_at(hay, i, needle) {
            return true;
        }
        i += 1;
    }
    false
}

fn starts_at(hay: &[u8], at: usize, needle: &[u8]) -> bool {
    let mut j = 0;
    while j < needle.len() {
        if hay[at + j] != needle[j] {
            return false;
        }
        j += 1;
    }
    true
}

/// `str::starts_with`.
pub fn str_starts_with(hay: &[u8], needle: &[u8]) -> bool {
    if needle.len() > hay.len() {
        return false;
    }
    starts_at(hay, 0, needle)
}

/// `str::ends_with`.
pub fn str_ends_with(hay: &[u8], needle: &[u8]) -> bool {
    if needle.len() > hay.len() {
        return false;
    }
    starts_at(hay, hay.len() - needle.len(), needle)
}

/// `str::to_lowercase`, for ASCII.
pub fn to_lowercase(s: &[u8]) -> Vec<u8> {
    let mut out: Vec<u8> = Vec::new();
    let mut i = 0;
    while i < s.len() {
        let c = s[i];
        if c >= b'A' && c <= b'Z' {
            out.push(c + 32);
        } else {
            out.push(c);
        }
        i += 1;
    }
    out
}

fn any_contains(set: &[Vec<u8>], s2: &[u8]) -> bool {
    let mut i = 0;
    while i < set.len() {
        if str_contains(&set[i], s2) {
            return true;
        }
        i += 1;
    }
    false
}

fn any_starts_with(set: &[Vec<u8>], s2: &[u8]) -> bool {
    let mut i = 0;
    while i < set.len() {
        if str_starts_with(&set[i], s2) {
            return true;
        }
        i += 1;
    }
    false
}

fn any_ends_with(set: &[Vec<u8>], s2: &[u8]) -> bool {
    let mut i = 0;
    while i < set.len() {
        if str_ends_with(&set[i], s2) {
            return true;
        }
        i += 1;
    }
    false
}

fn any_contains_lower(set: &[Vec<u8>], s2_lower: &[u8]) -> bool {
    let mut i = 0;
    while i < set.len() {
        if str_contains(&to_lowercase(&set[i]), s2_lower) {
            return true;
        }
        i += 1;
    }
    false
}

fn any_starts_with_lower(set: &[Vec<u8>], s2_lower: &[u8]) -> bool {
    let mut i = 0;
    while i < set.len() {
        if str_starts_with(&to_lowercase(&set[i]), s2_lower) {
            return true;
        }
        i += 1;
    }
    false
}

fn any_ends_with_lower(set: &[Vec<u8>], s2_lower: &[u8]) -> bool {
    let mut i = 0;
    while i < set.len() {
        if str_ends_with(&to_lowercase(&set[i]), s2_lower) {
            return true;
        }
        i += 1;
    }
    false
}

fn any_less_uuid(set: &[Uuid], u: Uuid) -> bool {
    let mut i = 0;
    while i < set.len() {
        if set[i] < u {
            return true;
        }
        i += 1;
    }
    false
}

fn any_less_u32(set: &[u32], u: u32) -> bool {
    let mut i = 0;
    while i < set.len() {
        if set[i] < u {
            return true;
        }
        i += 1;
    }
    false
}

fn contains_u32(set: &[u32], u: u32) -> bool {
    let mut i = 0;
    while i < set.len() {
        if set[i] == u {
            return true;
        }
        i += 1;
    }
    false
}

/// `ValueSetT::contains`.
pub fn vs_contains(vs: &ValueSet, pv: &PartialValue) -> bool {
    match vs {
        ValueSet::Utf8(set) => match pv {
            PartialValue::Utf8(s) => contains(set, s),
            _ => false,
        },
        ValueSet::Iutf8(set) => match pv {
            PartialValue::Iutf8(s) => contains(set, s),
            _ => false,
        },
        ValueSet::Iname(set) => match pv {
            PartialValue::Iname(s) => contains(set, s),
            _ => false,
        },
        ValueSet::Uuid(set) => match pv {
            PartialValue::Uuid(u) => contains_uuid(set, *u),
            _ => false,
        },
        ValueSet::Refer(set) => match pv {
            PartialValue::Refer(u) => contains_uuid(set, *u),
            _ => false,
        },
        ValueSet::Uint32(set) => match pv {
            PartialValue::Uint32(u) => contains_u32(set, *u),
            _ => false,
        },
        // `ValueSetOauthScopeMap::contains`: `self.map.contains_key(u)`.
        ValueSet::OauthScopeMap(keys) => match pv {
            PartialValue::Refer(u) => contains_uuid(keys, *u),
            _ => false,
        },
    }
}

/// `ValueSetT::substring`.
pub fn vs_substring(vs: &ValueSet, pv: &PartialValue) -> bool {
    match vs {
        ValueSet::Utf8(set) => match pv {
            PartialValue::Utf8(s2) => {
                let s2_lower = to_lowercase(s2);
                any_contains_lower(set, &s2_lower)
            }
            _ => false,
        },
        ValueSet::Iutf8(set) => match pv {
            PartialValue::Iutf8(s2) => any_contains(set, s2),
            _ => false,
        },
        ValueSet::Iname(set) => match pv {
            PartialValue::Iname(s2) => any_contains(set, s2),
            _ => false,
        },
        ValueSet::Uuid(_) | ValueSet::Refer(_) | ValueSet::Uint32(_) | ValueSet::OauthScopeMap(_) => false,
    }
}

/// `ValueSetT::startswith`.
pub fn vs_startswith(vs: &ValueSet, pv: &PartialValue) -> bool {
    match vs {
        ValueSet::Utf8(set) => match pv {
            PartialValue::Utf8(s2) => {
                let s2_lower = to_lowercase(s2);
                any_starts_with_lower(set, &s2_lower)
            }
            _ => false,
        },
        ValueSet::Iutf8(set) => match pv {
            PartialValue::Iutf8(s2) => any_starts_with(set, s2),
            _ => false,
        },
        ValueSet::Iname(set) => match pv {
            PartialValue::Iname(s2) => any_starts_with(set, s2),
            _ => false,
        },
        ValueSet::Uuid(_) | ValueSet::Refer(_) | ValueSet::Uint32(_) | ValueSet::OauthScopeMap(_) => false,
    }
}

/// `ValueSetT::endswith`.
pub fn vs_endswith(vs: &ValueSet, pv: &PartialValue) -> bool {
    match vs {
        ValueSet::Utf8(set) => match pv {
            PartialValue::Utf8(s2) => {
                let s2_lower = to_lowercase(s2);
                any_ends_with_lower(set, &s2_lower)
            }
            _ => false,
        },
        ValueSet::Iutf8(set) => match pv {
            PartialValue::Iutf8(s2) => any_ends_with(set, s2),
            _ => false,
        },
        ValueSet::Iname(set) => match pv {
            PartialValue::Iname(s2) => any_ends_with(set, s2),
            _ => false,
        },
        ValueSet::Uuid(_) | ValueSet::Refer(_) | ValueSet::Uint32(_) | ValueSet::OauthScopeMap(_) => false,
    }
}

/// `ValueSetT::lessthan`.
pub fn vs_lessthan(vs: &ValueSet, pv: &PartialValue) -> bool {
    match vs {
        ValueSet::Uuid(set) => match pv {
            PartialValue::Uuid(u) => any_less_uuid(set, *u),
            _ => false,
        },
        ValueSet::Refer(set) => match pv {
            PartialValue::Refer(u) => any_less_uuid(set, *u),
            _ => false,
        },
        ValueSet::Uint32(set) => match pv {
            PartialValue::Uint32(u) => any_less_u32(set, *u),
            _ => false,
        },
        ValueSet::Utf8(_) | ValueSet::Iutf8(_) | ValueSet::Iname(_) | ValueSet::OauthScopeMap(_) => false,
    }
}

/// `ValueSetT::as_iutf8_set` (and `as_iutf8_iter`).
pub fn as_iutf8_set(vs: &ValueSet) -> Option<&Vec<Vec<u8>>> {
    match vs {
        ValueSet::Iutf8(set) => Some(set),
        _ => None,
    }
}

/// `ValueSetT::as_refer_set`.
pub fn as_refer_set(vs: &ValueSet) -> Option<&Vec<Uuid>> {
    match vs {
        ValueSet::Refer(set) => Some(set),
        _ => None,
    }
}

/// `ValueSetT::to_refer_single`.
pub fn to_refer_single(vs: &ValueSet) -> Option<Uuid> {
    match vs {
        ValueSet::Refer(set) => {
            if set.len() == 1 {
                Some(set[0])
            } else {
                None
            }
        }
        _ => None,
    }
}

/// `ValueSetT::to_uuid_single`.
pub fn to_uuid_single(vs: &ValueSet) -> Option<Uuid> {
    match vs {
        ValueSet::Uuid(set) => {
            if set.len() == 1 {
                Some(set[0])
            } else {
                None
            }
        }
        _ => None,
    }
}

/// `ValueSetT::as_oauthscopemap`, its keys.
pub fn as_oauthscopemap(vs: &ValueSet) -> Option<&Vec<Uuid>> {
    match vs {
        ValueSet::OauthScopeMap(keys) => Some(keys),
        _ => None,
    }
}

/// `PartialValue::to_str` / `Value::to_str`.
pub fn to_str(v: &PartialValue) -> Option<&Vec<u8>> {
    match v {
        PartialValue::Utf8(s) => Some(s),
        PartialValue::Iutf8(s) => Some(s),
        PartialValue::Iname(s) => Some(s),
        _ => None,
    }
}

