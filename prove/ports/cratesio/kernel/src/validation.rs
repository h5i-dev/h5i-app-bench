//! `crates/crates_io_validation/src/lib.rs`: `validate_crate_name` and
//! `validate_dependency_name`.
//!
//! Upstream iterates over `char`s. On UTF-8 bytes: the length limit counts
//! characters, i.e. bytes that are not continuation bytes (`0b10xx_xxxx`);
//! every other check rejects any non-ASCII character, and the first byte of
//! a non-ASCII character is already not ASCII, so checking bytes rejects the
//! same character with the same error.

use crate::bytes::{is_alnum, is_alpha, is_digit};

/// `MAX_NAME_LENGTH`.
pub const MAX_NAME_LENGTH: usize = 64;

/// `InvalidCrateName` (and `InvalidDependencyName`), without the payload.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum InvalidName {
    TooLong,
    Empty,
    StartWithDigit,
    Start,
    Char,
}

/// `name.chars().count()`.
pub fn char_count(name: &[u8]) -> usize {
    let mut n = 0;
    let mut i = 0;
    while i < name.len() {
        if name[i] & 0xc0 != 0x80 {
            n += 1;
        }
        i += 1;
    }
    n
}

/// The bytes after the first must be ASCII alphanumerics, `-` or `_`.
pub fn rest_ok(name: &[u8]) -> bool {
    let mut i = 1;
    while i < name.len() {
        let b = name[i];
        if !(is_alnum(b) || b == b'-' || b == b'_') {
            return false;
        }
        i += 1;
    }
    true
}

/// `validate_crate_name`: at most 64 characters, non-empty, an ASCII letter
/// first, then ASCII alphanumerics, `-` and `_`.
pub fn validate_crate_name(name: &[u8]) -> Result<(), InvalidName> {
    if char_count(name) > MAX_NAME_LENGTH {
        return Err(InvalidName::TooLong);
    }
    if name.len() == 0 {
        return Err(InvalidName::Empty);
    }
    let first = name[0];
    if is_digit(first) {
        return Err(InvalidName::StartWithDigit);
    }
    if !is_alpha(first) {
        return Err(InvalidName::Start);
    }
    if !rest_ok(name) {
        return Err(InvalidName::Char);
    }
    Ok(())
}

/// `validate_dependency_name`: as a crate name, but `_` may come first.
pub fn validate_dependency_name(name: &[u8]) -> Result<(), InvalidName> {
    if char_count(name) > MAX_NAME_LENGTH {
        return Err(InvalidName::TooLong);
    }
    if name.len() == 0 {
        return Err(InvalidName::Empty);
    }
    let first = name[0];
    if is_digit(first) {
        return Err(InvalidName::StartWithDigit);
    }
    if !(is_alpha(first) || first == b'_') {
        return Err(InvalidName::Start);
    }
    if !rest_ok(name) {
        return Err(InvalidName::Char);
    }
    Ok(())
}
