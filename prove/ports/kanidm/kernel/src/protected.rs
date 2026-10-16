//! The protected class sets (access/protected.rs), as membership tests.
use crate::bset::bytes_eq;

/// `PROTECTED_ENTRY_CLASSES`: may not be created or deleted.
pub fn protected_entry_classes(c: &[u8]) -> bool {
    bytes_eq(c, b"system")
        || bytes_eq(c, b"domain_info")
        || bytes_eq(c, b"system_info")
        || bytes_eq(c, b"system_config")
        || bytes_eq(c, b"dyngroup")
        || bytes_eq(c, b"sync_object")
        || bytes_eq(c, b"tombstone")
        || bytes_eq(c, b"recycled")
}

/// `PROTECTED_MOD_ENTRY_CLASSES`: entries with these are modified only
/// within `modify_protected_entry_attrs`.
pub fn protected_mod_entry_classes(c: &[u8]) -> bool {
    bytes_eq(c, b"system")
        || bytes_eq(c, b"domain_info")
        || bytes_eq(c, b"system_info")
        || bytes_eq(c, b"system_config")
        || bytes_eq(c, b"dyngroup")
        || bytes_eq(c, b"tombstone")
        || bytes_eq(c, b"recycled")
}

/// `PROTECTED_MOD_PRES_ENTRY_CLASSES`: may not be added to any entry.
pub fn protected_mod_pres_entry_classes(c: &[u8]) -> bool {
    bytes_eq(c, b"system")
        || bytes_eq(c, b"domain_info")
        || bytes_eq(c, b"system_info")
        || bytes_eq(c, b"system_config")
        || bytes_eq(c, b"dyngroup")
        || bytes_eq(c, b"sync_object")
        || bytes_eq(c, b"tombstone")
        || bytes_eq(c, b"recycled")
}

/// `PROTECTED_MOD_REM_ENTRY_CLASSES`: may not be removed from any entry.
pub fn protected_mod_rem_entry_classes(c: &[u8]) -> bool {
    bytes_eq(c, b"system")
        || bytes_eq(c, b"domain_info")
        || bytes_eq(c, b"system_info")
        || bytes_eq(c, b"system_config")
        || bytes_eq(c, b"dyngroup")
        || bytes_eq(c, b"sync_object")
        || bytes_eq(c, b"tombstone")
}

/// `LOCKED_ENTRY_CLASSES`: entries with these may not be modified.
pub fn locked_entry_classes(c: &[u8]) -> bool {
    bytes_eq(c, b"tombstone")
}

/// `classes.is_disjoint(&PROTECTED_ENTRY_CLASSES)`.
pub fn disjoint_protected_entry_classes(classes: &[Vec<u8>]) -> bool {
    let mut i = 0;
    while i < classes.len() {
        if protected_entry_classes(&classes[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `classes.is_disjoint(&PROTECTED_MOD_ENTRY_CLASSES)`.
pub fn disjoint_protected_mod_entry_classes(classes: &[Vec<u8>]) -> bool {
    let mut i = 0;
    while i < classes.len() {
        if protected_mod_entry_classes(&classes[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `classes.is_disjoint(&LOCKED_ENTRY_CLASSES)`.
pub fn disjoint_locked_entry_classes(classes: &[Vec<u8>]) -> bool {
    let mut i = 0;
    while i < classes.len() {
        if locked_entry_classes(&classes[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `for c in PROTECTED_MOD_PRES_ENTRY_CLASSES { set.remove(c) }`.
pub fn remove_protected_mod_pres(set: &[Vec<u8>]) -> Vec<Vec<u8>> {
    let mut out: Vec<Vec<u8>> = Vec::new();
    let mut i = 0;
    while i < set.len() {
        let c = set[i].clone();
        if !protected_mod_pres_entry_classes(&c) {
            out.push(c);
        }
        i += 1;
    }
    out
}

/// `for c in PROTECTED_MOD_REM_ENTRY_CLASSES { set.remove(c) }`.
pub fn remove_protected_mod_rem(set: &[Vec<u8>]) -> Vec<Vec<u8>> {
    let mut out: Vec<Vec<u8>> = Vec::new();
    let mut i = 0;
    while i < set.len() {
        let c = set[i].clone();
        if !protected_mod_rem_entry_classes(&c) {
            out.push(c);
        }
        i += 1;
    }
    out
}
