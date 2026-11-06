//! `crates/wastebin_core/src/id.rs` (the `Id` codec) and
//! `crates/wastebin_server/src/cache.rs` (`Key::from_str`, `Key`'s `Display`).

use crate::ext::valid_extension;

/// `CHAR_TABLE`, as bytes.
pub const CHAR_TABLE: [u8; 64] = [
    b'a', b'b', b'c', b'd', b'e', b'f', b'g', b'h', b'i', b'j', b'k', b'l', b'm', b'n', b'o', b'p',
    b'q', b'r', b's', b't', b'u', b'v', b'w', b'x', b'y', b'z', b'A', b'B', b'C', b'D', b'E', b'F',
    b'G', b'H', b'I', b'J', b'K', b'L', b'M', b'N', b'O', b'P', b'Q', b'R', b'S', b'T', b'U', b'V',
    b'W', b'X', b'Y', b'Z', b'0', b'1', b'2', b'3', b'4', b'5', b'6', b'7', b'8', b'9', b'-', b'+',
];

/// `id::Error`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum IdError {
    IllegalCharacters,
    WrongSize,
}

/// `Id`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Id {
    /// Six-character identifiers.
    Id32(u32),
    /// Eleven-character identifiers.
    Id64(i64),
}

/// `Id::to_i64`: the `entries.id` primary key.
pub fn to_i64(id: Id) -> i64 {
    match id {
        Id::Id32(n) => n as i64,
        Id::Id64(n) => n,
    }
}

/// `CHAR_TABLE.iter().enumerate().find_map(..)`: the position of `c`.
pub fn char_bits(c: u8) -> Option<u8> {
    let mut i: usize = 0;
    while i < 64 {
        if CHAR_TABLE[i] == c {
            return Some(i as u8);
        }
        i += 1;
    }
    None
}

/// `Display` for `Id::Id32`.
pub fn encode32(n: u32) -> Vec<u8> {
    let mut s = Vec::new();
    s.push(CHAR_TABLE[((n >> 26) & 0x3f) as usize]);
    s.push(CHAR_TABLE[((n >> 20) & 0x3f) as usize]);
    s.push(CHAR_TABLE[((n >> 14) & 0x3f) as usize]);
    s.push(CHAR_TABLE[((n >> 8) & 0x3f) as usize]);
    s.push(CHAR_TABLE[((n >> 2) & 0x3f) as usize]);
    s.push(CHAR_TABLE[(n & 0x3) as usize]);
    s
}

/// `Display` for `Id::Id64`.
pub fn encode64(n: i64) -> Vec<u8> {
    let mut s = Vec::new();
    s.push(CHAR_TABLE[((n >> 58) & 0x3f) as usize]);
    s.push(CHAR_TABLE[((n >> 52) & 0x3f) as usize]);
    s.push(CHAR_TABLE[((n >> 46) & 0x3f) as usize]);
    s.push(CHAR_TABLE[((n >> 40) & 0x3f) as usize]);
    s.push(CHAR_TABLE[((n >> 34) & 0x3f) as usize]);
    s.push(CHAR_TABLE[((n >> 28) & 0x3f) as usize]);
    s.push(CHAR_TABLE[((n >> 22) & 0x3f) as usize]);
    s.push(CHAR_TABLE[((n >> 16) & 0x3f) as usize]);
    s.push(CHAR_TABLE[((n >> 10) & 0x3f) as usize]);
    s.push(CHAR_TABLE[((n >> 4) & 0x3f) as usize]);
    s.push(CHAR_TABLE[(n & 0xf) as usize]);
    s
}

/// `Display` for `Id`.
pub fn encode(id: Id) -> Vec<u8> {
    match id {
        Id::Id32(n) => encode32(n),
        Id::Id64(n) => encode64(n),
    }
}

/// One character of a six-character id: `n = (n << shift) | bits`.
fn acc32(n: u32, c: u8, shift: u32) -> Option<u32> {
    match char_bits(c) {
        None => None,
        Some(bits) => Some((n << shift) | (bits as u32)),
    }
}

/// One character of an eleven-character id.
fn acc64(n: i64, c: u8, shift: u32) -> Option<i64> {
    match char_bits(c) {
        None => None,
        Some(bits) => Some((n << shift) | (bits as i64)),
    }
}

/// `FromStr` for six characters, the loop unrolled: positions 0 to 4 shift
/// by 6, position 5 by 2.
fn decode32(s: &[u8]) -> Option<u32> {
    let mut n: u32 = 0;
    let mut pos: usize = 0;
    while pos < 6 {
        let shift = if pos < 5 { 6 } else { 2 };
        match acc32(n, s[pos], shift) {
            None => return None,
            Some(m) => n = m,
        }
        pos += 1;
    }
    Some(n)
}

/// `FromStr` for eleven characters: positions 0 to 9 shift by 6, position 10
/// by 4.
fn decode64(s: &[u8]) -> Option<i64> {
    let mut n: i64 = 0;
    let mut pos: usize = 0;
    while pos < 11 {
        let shift = if pos < 10 { 6 } else { 4 };
        match acc64(n, s[pos], shift) {
            None => return None,
            Some(m) => n = m,
        }
        pos += 1;
    }
    Some(n)
}

/// `Id::from_str`. `value.len()` is the byte length; a byte outside
/// `CHAR_TABLE` (including every byte of a multi-byte character) is an
/// illegal character, as the `chars()` loop finds.
pub fn decode(value: &[u8]) -> Result<Id, IdError> {
    if value.len() == 6 {
        match decode32(value) {
            None => Err(IdError::IllegalCharacters),
            Some(n) => Ok(Id::Id32(n)),
        }
    } else if value.len() == 11 {
        match decode64(value) {
            None => Err(IdError::IllegalCharacters),
            Some(n) => Ok(Id::Id64(n)),
        }
    } else {
        Err(IdError::WrongSize)
    }
}

/// `cache::Key`: an id and an optional extension.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Key {
    pub id: Id,
    pub ext: Option<Vec<u8>>,
}

/// The position of the first `.`, as `split_once('.')` finds it.
pub fn find_dot(s: &[u8]) -> Option<usize> {
    let mut i = 0;
    while i < s.len() {
        if s[i] == b'.' {
            return Some(i);
        }
        i += 1;
    }
    None
}

/// `s[from..to]`, copied.
pub fn sub(s: &[u8], from: usize, to: usize) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = from;
    while i < to {
        out.push(s[i]);
        i += 1;
    }
    out
}

/// `Key::from_str`: split at the first `.`; the part after it must be a
/// valid extension (checked before the id is decoded) and the part before it
/// an id. Every failure is `Error::Id(_)` upstream; the kernel keeps the
/// `id::Error` it carries.
pub fn parse_key(value: &[u8]) -> Result<Key, IdError> {
    match find_dot(value) {
        None => match decode(value) {
            Err(e) => Err(e),
            Ok(id) => Ok(Key { id, ext: None }),
        },
        Some(i) => {
            let tail = sub(value, i + 1, value.len());
            if !valid_extension(&tail) {
                return Err(IdError::IllegalCharacters);
            }
            let head = sub(value, 0, i);
            match decode(&head) {
                Err(e) => Err(e),
                Ok(id) => Ok(Key { id, ext: Some(tail) }),
            }
        }
    }
}

/// `Key`'s `Display` and `Id::to_url_path`: the id, then `.` and the
/// extension if there is one.
pub fn key_path(key: &Key) -> Vec<u8> {
    let mut s = encode(key.id);
    match &key.ext {
        None => {}
        Some(e) => {
            s.push(b'.');
            let mut i = 0;
            while i < e.len() {
                s.push(e[i]);
                i += 1;
            }
        }
    }
    s
}
