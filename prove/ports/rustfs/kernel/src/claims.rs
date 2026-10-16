//! Pure claim helpers from policy/{policy,utils}.rs; JSON values are already decoded.
use crate::{bytes, unicode};
pub enum Value {
    Null,
    Bool(bool),
    Number(Vec<u8>),
    String(Vec<u8>),
    Array(Vec<Value>),
    Object(Vec<(Vec<u8>, Value)>),
}
pub type Claims = Vec<(Vec<u8>, Value)>;
/// Found carries a table index instead of a borrowed JSON value.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ClaimLookup {
    Missing,
    Found(usize),
    Ambiguous,
}
/// `case_insensitive_eq`: Unicode flat_map(char::to_lowercase).
pub fn case_insensitive_eq(left: &[u8], right: &[u8]) -> bool {
    bytes::eq(&unicode::lower(left), &unicode::lower(right))
}
/// Exact-name lookup before Unicode case-insensitive lookup, with ambiguity rejection.
pub fn get_claim_case_insensitive(table: &Claims, name: &[u8]) -> ClaimLookup {
    match find(table, name) {
        Some(i) => ClaimLookup::Found(i),
        None => case_fold_lookup(table, name),
    }
}
fn case_fold_lookup(table: &Claims, name: &[u8]) -> ClaimLookup {
    let mut matched = ClaimLookup::Missing;
    let mut j = 0;
    while j < table.len() {
        if case_insensitive_eq(&table[j].0, name) {
            match matched {
                ClaimLookup::Found(_) => return ClaimLookup::Ambiguous,
                _ => matched = ClaimLookup::Found(j),
            }
        }
        j += 1;
    }
    matched
}
/// Exact map lookup; None refers to absence, not JSON null.
pub fn find(table: &Claims, name: &[u8]) -> Option<usize> {
    let mut i = 0;
    while i < table.len() {
        if bytes::eq(&table[i].0, name) {
            return Some(i);
        }
        i += 1;
    }
    None
}
/// The split(',').trim() loop, preserving duplicates until the caller deduplicates.
pub fn split_values(s: &[u8]) -> Vec<Vec<u8>> {
    let mut out = Vec::new();
    let mut start = 0;
    let mut i = 0;
    while i <= s.len() {
        if i == s.len() || s[i] == b',' {
            let part = unicode::trim(&bytes::slice(s, start, i));
            if part.len() != 0 {
                out.push(part);
            }
            start = i + 1;
        }
        i += 1;
    }
    out
}
fn append_string_values(out: &mut Vec<Vec<u8>>, value: &Value) {
    if let Value::String(s) = value {
        let parts = split_values(s);
        let mut i = 0;
        while i < parts.len() {
            out.push(parts[i].clone());
            i += 1;
        }
    }
}
fn value_strings(value: &Value) -> (Vec<Vec<u8>>, bool) {
    let mut out = Vec::new();
    match value {
        Value::Array(array) => {
            let mut i = 0;
            while i < array.len() {
                append_string_values(&mut out, &array[i]);
                i += 1;
            }
            (out, true)
        }
        Value::String(_) => {
            append_string_values(&mut out, value);
            (out, true)
        }
        _ => (out, false),
    }
}
/// `_get_values_from_claims`: exact key lookup and a list retaining duplicates.
pub fn values_from_claims(table: &Claims, name: &[u8]) -> (Vec<Vec<u8>>, bool) {
    match find(table, name) {
        Some(i) => value_strings(&table[i].1),
        None => (Vec::new(), false),
    }
}
/// `get_values_from_claims`: case-insensitive lookup and a set.
fn lookup_strings(table: &Claims, name: &[u8]) -> (Vec<Vec<u8>>, bool) {
    match get_claim_case_insensitive(table, name) {
        ClaimLookup::Found(i) => value_strings(&table[i].1),
        _ => (Vec::new(), false),
    }
}
fn unique_values(values: &[Vec<u8>]) -> Vec<Vec<u8>> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < values.len() {
        if !bytes::member(&out, &values[i]) {
            out.push(values[i].clone());
        }
        i += 1;
    }
    out
}
pub fn get_values_from_claims(table: &Claims, name: &[u8]) -> (Vec<Vec<u8>>, bool) {
    let (values, present) = lookup_strings(table, name);
    (unique_values(&values), present)
}
/// `get_policies_from_claims`.
pub fn get_policies_from_claims(table: &Claims, name: &[u8]) -> (Vec<Vec<u8>>, bool) {
    get_values_from_claims(table, name)
}
/// `Args::get_policies`.
pub fn args_get_policies(table: &Claims, name: &[u8]) -> (Vec<Vec<u8>>, bool) {
    get_policies_from_claims(table, name)
}
/// `Args::get_role_arn`: exact key and string type, not a case-insensitive lookup.
pub fn get_role_arn(table: &Claims) -> Option<Vec<u8>> {
    match find(table, b"roleArn") {
        Some(i) => match &table[i].1 {
            Value::String(s) => Some(s.clone()),
            _ => None,
        },
        None => None,
    }
}
/// `iam_policy_claim_name_sa`.
pub fn iam_policy_claim_name_sa() -> Vec<u8> {
    b"sa-policy".to_vec()
}
/// `_split_path`: include the selected slash in the left part.
pub fn split_path(path: &[u8], second: bool) -> (Vec<u8>, Vec<u8>) {
    let first = match bytes::find_from(path, 0, b"/") {
        Some(i) => i,
        None => return (path.to_vec(), Vec::new()),
    };
    let index = if second {
        match bytes::find_from(path, first + 1, b"/") {
            Some(i) => i,
            None => return (path.to_vec(), Vec::new()),
        }
    } else {
        first
    };
    (
        bytes::slice(path, 0, index + 1),
        bytes::slice(path, index + 1, path.len()),
    )
}
/// `is_existing_object_tag_condition_key`.
pub fn is_existing_object_tag_condition_key(key: &[u8]) -> bool {
    bytes::eq(key, b"ExistingObjectTag")
        || bytes::eq(key, b"s3:ExistingObjectTag")
        || bytes::starts_with(key, b"ExistingObjectTag/")
        || bytes::starts_with(key, b"s3:ExistingObjectTag/")
}
/// `value_uses_existing_object_tag_condition_key`, with recursive list scans.
pub fn value_uses_existing_object_tag(value: &Value) -> bool {
    match value {
        Value::Object(entries) => object_uses_tag(entries, 0),
        Value::Array(entries) => array_uses_tag(entries, 0),
        _ => false,
    }
}
fn object_uses_tag(entries: &[(Vec<u8>, Value)], i: usize) -> bool {
    if i >= entries.len() {
        return false;
    }
    is_existing_object_tag_condition_key(&entries[i].0)
        || value_uses_existing_object_tag(&entries[i].1)
        || object_uses_tag(entries, i + 1)
}
fn array_uses_tag(entries: &[Value], i: usize) -> bool {
    if i >= entries.len() {
        return false;
    }
    value_uses_existing_object_tag(&entries[i]) || array_uses_tag(entries, i + 1)
}
