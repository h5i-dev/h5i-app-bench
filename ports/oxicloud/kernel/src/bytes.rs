//! Byte-string operations used by the ports of upstream string predicates.

pub fn equal(a: &[u8], b: &[u8]) -> bool {
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

/// Owned representation of an upstream static wire string.
pub fn copy(a: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < a.len() {
        out.push(a[i]);
        i += 1;
    }
    out
}
