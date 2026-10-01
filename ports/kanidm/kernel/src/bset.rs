//! `BTreeSet` operations on vectors. A vector stands for the set of its
//! elements; inserts skip elements already present.
use crate::Uuid;

pub fn bytes_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut i = 0;
    while i < a.len() {
        if a[i] != b[i] {
            return false;
        }
        i += 1;
    }
    true
}

/// `set.contains(x)`.
pub fn contains(set: &[Vec<u8>], x: &[u8]) -> bool {
    let mut i = 0;
    while i < set.len() {
        if bytes_eq(&set[i], x) {
            return true;
        }
        i += 1;
    }
    false
}

/// `set.insert(x)`.
pub fn insert(set: &mut Vec<Vec<u8>>, x: &[u8]) {
    if !contains(set, x) {
        set.push(x.to_vec());
    }
}

/// `set.extend(xs)` / `set.append(&mut xs)`.
pub fn extend(set: &mut Vec<Vec<u8>>, xs: &[Vec<u8>]) {
    let mut i = 0;
    while i < xs.len() {
        insert(set, &xs[i]);
        i += 1;
    }
}

/// `a.is_subset(b)`.
pub fn is_subset(a: &[Vec<u8>], b: &[Vec<u8>]) -> bool {
    let mut i = 0;
    while i < a.len() {
        if !contains(b, &a[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `a.is_disjoint(b)`.
pub fn is_disjoint(a: &[Vec<u8>], b: &[Vec<u8>]) -> bool {
    let mut i = 0;
    while i < a.len() {
        if contains(b, &a[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `a & b`.
pub fn intersection(a: &[Vec<u8>], b: &[Vec<u8>]) -> Vec<Vec<u8>> {
    let mut out: Vec<Vec<u8>> = Vec::new();
    let mut i = 0;
    while i < a.len() {
        let x = a[i].clone();
        if contains(b, &x) {
            insert(&mut out, &x);
        }
        i += 1;
    }
    out
}

/// `a.difference(b)`, `a - b`.
pub fn difference(a: &[Vec<u8>], b: &[Vec<u8>]) -> Vec<Vec<u8>> {
    let mut out: Vec<Vec<u8>> = Vec::new();
    let mut i = 0;
    while i < a.len() {
        let x = a[i].clone();
        if !contains(b, &x) {
            insert(&mut out, &x);
        }
        i += 1;
    }
    out
}

/// `set.contains(&u)` on a set of uuids.
pub fn contains_uuid(set: &[Uuid], u: Uuid) -> bool {
    let mut i = 0;
    while i < set.len() {
        if set[i] == u {
            return true;
        }
        i += 1;
    }
    false
}

/// `a.intersection(b).next().is_some()`.
pub fn intersects_uuid(a: &[Uuid], b: &[Uuid]) -> bool {
    let mut i = 0;
    while i < a.len() {
        if contains_uuid(b, a[i]) {
            return true;
        }
        i += 1;
    }
    false
}
