//! Byte-string helpers standing in for the `str` methods upstream calls.
//! Text is `&[u8]` (UTF-8 bytes); every helper is an index loop.

/// `a == b` on byte strings.
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

/// `config::utils::str::constant_time_eq` (`utils/str.rs`): equal lengths,
/// then the OR of every byte's XOR is zero. No early exit inside the loop.
pub fn constant_time_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut diff: u8 = 0;
    let mut i = 0;
    while i < a.len() {
        diff = diff | (a[i] ^ b[i]);
        i += 1;
    }
    diff == 0
}

/// `s.starts_with(p)`.
pub fn starts_with(s: &[u8], p: &[u8]) -> bool {
    if s.len() < p.len() {
        return false;
    }
    let mut i = 0;
    while i < p.len() {
        if s[i] != p[i] {
            return false;
        }
        i += 1;
    }
    true
}

/// `s[from..].to_vec()`.
pub fn suffix(s: &[u8], from: usize) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = from;
    while i < s.len() {
        out.push(s[i]);
        i += 1;
    }
    out
}

/// `s[..to].to_vec()`.
pub fn prefix(s: &[u8], to: usize) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < to && i < s.len() {
        out.push(s[i]);
        i += 1;
    }
    out
}

/// `s.strip_prefix(p)`.
pub fn strip_prefix(s: &[u8], p: &[u8]) -> Option<Vec<u8>> {
    if starts_with(s, p) {
        Some(suffix(s, p.len()))
    } else {
        None
    }
}

/// The index of the first `c` in `s`, or `s.len()`.
pub fn find_byte(s: &[u8], c: u8) -> usize {
    let mut i = 0;
    while i < s.len() {
        if s[i] == c {
            return i;
        }
        i += 1;
    }
    s.len()
}

/// `s.split_once(c)` for an ASCII `c`.
pub fn split_once(s: &[u8], c: u8) -> Option<(Vec<u8>, Vec<u8>)> {
    let i = find_byte(s, c);
    if i < s.len() {
        Some((prefix(s, i), suffix(s, i + 1)))
    } else {
        None
    }
}

/// `s.split('/').collect::<Vec<&str>>()`: always at least one piece.
pub fn split_slash(s: &[u8]) -> Vec<Vec<u8>> {
    let mut out: Vec<Vec<u8>> = Vec::new();
    let mut cur: Vec<u8> = Vec::new();
    let mut i = 0;
    while i < s.len() {
        if s[i] == b'/' {
            out.push(cur);
            cur = Vec::new();
        } else {
            cur.push(s[i]);
        }
        i += 1;
    }
    out.push(cur);
    out
}

/// `list.contains(x)` for a list of byte strings.
pub fn contains(list: &[Vec<u8>], x: &[u8]) -> bool {
    let mut i = 0;
    while i < list.len() {
        if bytes_eq(&list[i], x) {
            return true;
        }
        i += 1;
    }
    false
}
