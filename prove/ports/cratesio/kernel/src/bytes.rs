//! Byte-string helpers standing for the `str` methods upstream calls.

/// `a == b`.
pub fn eq(a: &[u8], b: &[u8]) -> bool {
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

/// `s.starts_with(p)`.
pub fn starts_with(s: &[u8], p: &[u8]) -> bool {
    if p.len() > s.len() {
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

/// ASCII lowercase of one byte.
pub fn lower(b: u8) -> u8 {
    if b >= b'A' && b <= b'Z' { b + 32 } else { b }
}

/// `a.eq_ignore_ascii_case(b)`.
pub fn eq_ignore_ascii_case(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut i = 0;
    while i < a.len() {
        if lower(a[i]) != lower(b[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `u8::is_ascii_alphanumeric`.
pub fn is_alnum(b: u8) -> bool {
    (b >= b'0' && b <= b'9') || (b >= b'A' && b <= b'Z') || (b >= b'a' && b <= b'z')
}

/// `u8::is_ascii_alphabetic`.
pub fn is_alpha(b: u8) -> bool {
    (b >= b'A' && b <= b'Z') || (b >= b'a' && b <= b'z')
}

/// `u8::is_ascii_digit`.
pub fn is_digit(b: u8) -> bool {
    b >= b'0' && b <= b'9'
}
