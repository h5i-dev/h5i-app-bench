//! `str` methods upstream uses, over bytes. Upstream strings reaching these
//! are valid UTF-8, where each of these agrees with its `str` counterpart.

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

pub fn ends_with(s: &[u8], p: &[u8]) -> bool {
    if s.len() < p.len() {
        return false;
    }
    starts_with_at(s, s.len() - p.len(), p)
}

/// `s[a..b]`, owned; empty when the range is out of order.
pub fn sub(s: &[u8], a: usize, b: usize) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = a;
    while i < b && i < s.len() {
        out.push(s[i]);
        i += 1;
    }
    out
}

/// `s.strip_prefix(p)`.
pub fn strip_prefix(s: &[u8], p: &[u8]) -> Option<Vec<u8>> {
    if starts_with(s, p) { Some(sub(s, p.len(), s.len())) } else { None }
}

/// `s.strip_suffix(p)`.
pub fn strip_suffix(s: &[u8], p: &[u8]) -> Option<Vec<u8>> {
    if ends_with(s, p) { Some(sub(s, 0, s.len() - p.len())) } else { None }
}

pub fn contains_byte(s: &[u8], b: u8) -> bool {
    let mut i = 0;
    while i < s.len() {
        if s[i] == b {
            return true;
        }
        i += 1;
    }
    false
}

/// `s.contains(p)`.
pub fn contains(s: &[u8], p: &[u8]) -> bool {
    let mut i = 0;
    while i <= s.len() {
        if starts_with_at(s, i, p) {
            return true;
        }
        i += 1;
    }
    false
}

/// `s.find(b)`.
pub fn find_byte(s: &[u8], b: u8) -> Option<usize> {
    let mut i = 0;
    while i < s.len() {
        if s[i] == b {
            return Some(i);
        }
        i += 1;
    }
    None
}

/// `s.rfind(b)`.
pub fn rfind_byte(s: &[u8], b: u8) -> Option<usize> {
    let mut i = s.len();
    while i > 0 {
        i -= 1;
        if s[i] == b {
            return Some(i);
        }
    }
    None
}

pub fn count_byte(s: &[u8], b: u8) -> usize {
    let mut n = 0;
    let mut i = 0;
    while i < s.len() {
        if s[i] == b {
            n += 1;
        }
        i += 1;
    }
    n
}

/// `s.split(sep).collect()`, owning the pieces.
pub fn split(s: &[u8], sep: u8) -> Vec<Vec<u8>> {
    let mut out = Vec::new();
    let mut cur = Vec::new();
    let mut i = 0;
    while i < s.len() {
        if s[i] == sep {
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

/// `s.split_once(sep)`.
pub fn split_once(s: &[u8], sep: u8) -> Option<(Vec<u8>, Vec<u8>)> {
    match find_byte(s, sep) {
        Some(i) => Some((sub(s, 0, i), sub(s, i + 1, s.len()))),
        None => None,
    }
}

/// `s.rsplit_once(sep)`.
pub fn rsplit_once(s: &[u8], sep: u8) -> Option<(Vec<u8>, Vec<u8>)> {
    match rfind_byte(s, sep) {
        Some(i) => Some((sub(s, 0, i), sub(s, i + 1, s.len()))),
        None => None,
    }
}

/// `char::is_whitespace` on an ASCII byte.
pub fn is_ws(b: u8) -> bool {
    b == b' ' || (b >= 9 && b <= 13)
}

/// `s.trim()` on ASCII input: every caller trims a header value that
/// passed `to_str`.
pub fn trim(s: &[u8]) -> Vec<u8> {
    let mut a = 0;
    while a < s.len() && is_ws(s[a]) {
        a += 1;
    }
    let mut b = s.len();
    while b > a && is_ws(s[b - 1]) {
        b -= 1;
    }
    sub(s, a, b)
}

/// `s.trim_start_matches(c)`.
pub fn trim_start_byte(s: &[u8], c: u8) -> Vec<u8> {
    let mut a = 0;
    while a < s.len() && s[a] == c {
        a += 1;
    }
    sub(s, a, s.len())
}

pub fn to_ascii_lower(b: u8) -> u8 {
    if b >= b'A' && b <= b'Z' { b + 32 } else { b }
}

/// `a.eq_ignore_ascii_case(b)`.
pub fn eq_ignore_ascii_case(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut i = 0;
    while i < a.len() {
        if to_ascii_lower(a[i]) != to_ascii_lower(b[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `s.to_ascii_lowercase()`.
pub fn ascii_lowercase(s: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < s.len() {
        out.push(to_ascii_lower(s[i]));
        i += 1;
    }
    out
}

/// `list.iter().any(|x| x == s)`.
pub fn any_eq(list: &[Vec<u8>], s: &[u8]) -> bool {
    let mut i = 0;
    while i < list.len() {
        if bytes_eq(&list[i], s) {
            return true;
        }
        i += 1;
    }
    false
}

pub fn contains_id(list: &[u64], x: u64) -> bool {
    let mut i = 0;
    while i < list.len() {
        if list[i] == x {
            return true;
        }
        i += 1;
    }
    false
}

/// The piece `i` of `split`, as `segments.nth(i)` would yield it.
pub fn seg_is(segs: &[Vec<u8>], i: usize, lit: &[u8]) -> bool {
    i < segs.len() && bytes_eq(&segs[i], lit)
}

/// `matches!(segments.nth(i), Some(k) if !k.is_empty())`.
pub fn seg_nonempty(segs: &[Vec<u8>], i: usize) -> bool {
    i < segs.len() && segs[i].len() > 0
}

/// Continuation byte `10xxxxxx`.
fn is_cont_byte(b: u8) -> bool {
    b >= 0x80 && b <= 0xBF
}

/// Length of the UTF-8 sequence at `s[i..]`, or 0 when it is not well
/// formed (the table of the Unicode standard, 3.9, D92).
fn utf8_seq(s: &[u8], i: usize) -> usize {
    let n = s.len() - i;
    let b = s[i];
    if b < 0x80 {
        return 1;
    }
    if b >= 0xC2 && b <= 0xDF {
        return if n >= 2 && is_cont_byte(s[i + 1]) { 2 } else { 0 };
    }
    if b >= 0xE0 && b <= 0xEF {
        if n < 3 {
            return 0;
        }
        let c = s[i + 1];
        let ok1 = if b == 0xE0 {
            c >= 0xA0 && c <= 0xBF
        } else if b == 0xED {
            c >= 0x80 && c <= 0x9F
        } else {
            is_cont_byte(c)
        };
        return if ok1 && is_cont_byte(s[i + 2]) { 3 } else { 0 };
    }
    if b >= 0xF0 && b <= 0xF4 {
        if n < 4 {
            return 0;
        }
        let c = s[i + 1];
        let ok1 = if b == 0xF0 {
            c >= 0x90 && c <= 0xBF
        } else if b == 0xF4 {
            c >= 0x80 && c <= 0x8F
        } else {
            is_cont_byte(c)
        };
        return if ok1 && is_cont_byte(s[i + 2]) && is_cont_byte(s[i + 3]) { 4 } else { 0 };
    }
    0
}

/// `std::str::from_utf8(s).is_ok()`.
pub fn is_utf8(s: &[u8]) -> bool {
    let mut i = 0;
    while i < s.len() {
        let k = utf8_seq(s, i);
        if k == 0 {
            return false;
        }
        i += k;
    }
    true
}

/// Push `b as char` (a Latin-1 code point) as UTF-8.
pub fn push_latin1(out: &mut Vec<u8>, b: u8) {
    if b < 0x80 {
        out.push(b);
    } else {
        out.push(0xC0 | (b >> 6));
        out.push(0x80 | (b & 0x3F));
    }
}
