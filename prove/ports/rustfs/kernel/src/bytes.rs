//! Byte-string helpers standing in for `str` methods.

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

/// `s[from..].starts_with(p)`.
pub fn starts_with_at(s: &[u8], from: usize, p: &[u8]) -> bool {
    if from > s.len() || s.len() - from < p.len() {
        return false;
    }
    let mut i = 0;
    while i < p.len() {
        if s[from + i] != p[i] {
            return false;
        }
        i += 1;
    }
    true
}

pub fn starts_with(s: &[u8], p: &[u8]) -> bool {
    starts_with_at(s, 0, p)
}

/// `s[from..].find(p)`, as an index into `s`.
pub fn find_from(s: &[u8], from: usize, p: &[u8]) -> Option<usize> {
    let mut i = from;
    while i <= s.len() && s.len() - i >= p.len() {
        if starts_with_at(s, i, p) {
            return Some(i);
        }
        i += 1;
    }
    None
}

pub fn contains(s: &[u8], p: &[u8]) -> bool {
    match find_from(s, 0, p) {
        Some(_) => true,
        None => false,
    }
}

/// `s[a..b]`, owned.
pub fn slice(s: &[u8], a: usize, b: usize) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = a;
    while i < b {
        out.push(s[i]);
        i += 1;
    }
    out
}

/// `a` followed by `b`.
pub fn concat(a: &[u8], b: &[u8]) -> Vec<u8> {
    let mut out = slice(a, 0, a.len());
    let mut i = 0;
    while i < b.len() {
        out.push(b[i]);
        i += 1;
    }
    out
}

/// `s.replace(from, to)`: every non-overlapping occurrence, left to right.
/// `from` is never empty here.
pub fn replace(s: &[u8], from: &[u8], to: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < s.len() {
        if from.len() > 0 && starts_with_at(s, i, from) {
            let mut j = 0;
            while j < to.len() {
                out.push(to[j]);
                j += 1;
            }
            i += from.len();
        } else {
            out.push(s[i]);
            i += 1;
        }
    }
    out
}

/// ASCII `to_lowercase`; non-ASCII bytes are kept (see DEVIATIONS.md).
pub fn lower(s: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
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

/// Membership in a list used as a set.
pub fn member(xs: &[Vec<u8>], x: &[u8]) -> bool {
    let mut i = 0;
    while i < xs.len() {
        if eq(&xs[i], x) {
            return true;
        }
        i += 1;
    }
    false
}

/// The digit loop of `str::parse::<i64>()`, as recursion; accumulates toward
/// the sign as std does, so `i64::MIN` parses.
fn parse_digits(s: &[u8], i: usize, acc: i64, neg: bool) -> Option<i64> {
    if i >= s.len() {
        return Some(acc);
    }
    let c = s[i];
    if c < b'0' || c > b'9' {
        return None;
    }
    let d = (c - b'0') as i64;
    let m = match acc.checked_mul(10) {
        Some(m) => m,
        None => return None,
    };
    let next = if neg { m.checked_sub(d) } else { m.checked_add(d) };
    match next {
        Some(v) => parse_digits(s, i + 1, v, neg),
        None => None,
    }
}

/// `str::parse::<i64>()`: an optional sign, then decimal digits.
pub fn parse_i64(s: &[u8]) -> Option<i64> {
    if s.len() == 0 {
        return None;
    }
    let neg = s[0] == b'-';
    let start = if s[0] == b'-' || s[0] == b'+' { 1 } else { 0 };
    if start == s.len() {
        return None;
    }
    parse_digits(s, start, 0, neg)
}
