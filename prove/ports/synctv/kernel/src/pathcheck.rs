//! Path-traversal validation.
//!
//! Ported from `synctv-common/src/validation.rs` @ 38970e0:
//! `validate_path_for_traversal` (also re-exported with a different error type by
//! `synctv-core/src/validation.rs:685`). It gates provider paths (`provider/alist.rs`).
//!
//! On bytes. `path.get(i + 1..i + 3)` followed by `u8::from_str_radix(hex, 16)` decodes
//! to a value exactly when both bytes are hex digits, or when the first is `+` and the
//! second a hex digit (Rust accepts a leading `+`). A `+x` value is at most 15, so it
//! can never be `0x2E` or `0x25` and never changes the outcome. The kernel therefore
//! decodes only two hex digits. A byte range that is not on a character boundary
//! (`get` returns `None`) contains a non-ASCII byte, so it is not a pair of hex digits
//! either.

/// The value of an ASCII hex digit, or 16 for any other byte.
pub fn hex_val(b: u8) -> u8 {
    if b >= 48 && b <= 57 {
        b - 48
    } else if b >= 97 && b <= 102 {
        b - 87
    } else if b >= 65 && b <= 70 {
        b - 55
    } else {
        16
    }
}

/// `u8::from_str_radix(&[a, b], 16)` when it equals `target` (`target` is `0x2E` or `0x25`).
pub fn hex_pair_is(a: u8, b: u8, target: u8) -> bool {
    let h = hex_val(a);
    let l = hex_val(b);
    h < 16 && l < 16 && h * 16 + l == target
}

/// `s.contains(pat)` for a two- or three-byte pattern given as bytes.
pub fn contains2(s: &[u8], a: u8, b: u8) -> bool {
    let mut i = 0;
    while i + 1 < s.len() {
        if s[i] == a && s[i + 1] == b {
            return true;
        }
        i += 1;
    }
    false
}

pub fn contains3(s: &[u8], a: u8, b: u8, c: u8) -> bool {
    let mut i = 0;
    while i + 2 < s.len() {
        if s[i] == a && s[i + 1] == b && s[i + 2] == c {
            return true;
        }
        i += 1;
    }
    false
}

pub fn contains1(s: &[u8], a: u8) -> bool {
    let mut i = 0;
    while i < s.len() {
        if s[i] == a {
            return true;
        }
        i += 1;
    }
    false
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TraversalError {
    DotDot,
    NullByte,
    MixedDots,
    EncodedDot,
    DoubleEncodedDot,
    TripleEncodedDot,
}

/// One position of the Check 4 loop: the error found at `i`, if any.
pub fn encoded_at(p: &[u8], i: usize) -> Option<TraversalError> {
    if p[i] == 37 && i + 2 < p.len() {
        if hex_pair_is(p[i + 1], p[i + 2], 46) {
            return Some(TraversalError::EncodedDot);
        }
        if hex_pair_is(p[i + 1], p[i + 2], 37) && i + 4 < p.len() {
            if hex_pair_is(p[i + 3], p[i + 4], 46) {
                return Some(TraversalError::DoubleEncodedDot);
            }
            if hex_pair_is(p[i + 3], p[i + 4], 37) && i + 6 < p.len() {
                if hex_pair_is(p[i + 5], p[i + 6], 46) {
                    return Some(TraversalError::TripleEncodedDot);
                }
            }
        }
    }
    None
}

/// Check 4: the first encoded-dot error, scanning left to right.
pub fn first_encoded(p: &[u8]) -> Option<TraversalError> {
    let mut i = 0;
    while i < p.len() {
        match encoded_at(p, i) {
            Some(e) => return Some(e),
            None => {}
        }
        i += 1;
    }
    None
}

/// `validate_path_for_traversal(path)`; the error kind stands for the upstream reason.
pub fn validate_path_for_traversal(p: &[u8]) -> Result<(), TraversalError> {
    if contains2(p, 46, 46) {
        return Err(TraversalError::DotDot);
    }
    if contains1(p, 0) || contains3(p, 37, 48, 48) {
        return Err(TraversalError::NullByte);
    }
    if contains3(p, 46, 47, 46) {
        return Err(TraversalError::MixedDots);
    }
    match first_encoded(p) {
        Some(e) => Err(e),
        None => Ok(()),
    }
}
