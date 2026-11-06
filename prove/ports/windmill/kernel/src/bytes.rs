//! Byte-string helpers. Upstream works on `&str`; the kernel works on the UTF-8 bytes.

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

/// `s.ends_with("/*")`.
pub fn ends_with_slash_star(s: &[u8]) -> bool {
    s.len() >= 2 && s[s.len() - 2] == 47 && s[s.len() - 1] == 42
}

/// `s.contains(c)` for one byte.
pub fn contains_byte(s: &[u8], c: u8) -> bool {
    let mut i = 0;
    while i < s.len() {
        if s[i] == c {
            return true;
        }
        i += 1;
    }
    false
}

/// `s[..n].to_vec()`.
pub fn prefix(s: &[u8], n: usize) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < n && i < s.len() {
        out.push(s[i]);
        i += 1;
    }
    out
}

/// `s == "*"`.
pub fn is_star(s: &[u8]) -> bool {
    s.len() == 1 && s[0] == 42
}

/// `s.split(sep).collect()`: always at least one (possibly empty) piece.
pub fn split(s: &[u8], sep: u8) -> Vec<Vec<u8>> {
    let mut out: Vec<Vec<u8>> = Vec::new();
    let mut cur: Vec<u8> = Vec::new();
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

/// `s.chars().nth(n) == Some('/')`: the `n`-th character (not byte) of the UTF-8
/// string `s` is `/`. A character starts at every byte that is not a continuation
/// byte (`0b10xx_xxxx`); `/` is a one-byte character.
pub fn nth_char_is_slash(s: &[u8], n: usize) -> bool {
    let mut count = 0;
    let mut i = 0;
    while i < s.len() {
        let b = s[i];
        if b < 128 || b >= 192 {
            if count == n {
                return b == 47;
            }
            count += 1;
        }
        i += 1;
    }
    false
}

/// `list.iter().any(|x| x == s)`.
pub fn list_contains(list: &[Vec<u8>], s: &[u8]) -> bool {
    let mut i = 0;
    while i < list.len() {
        if eq(&list[i], s) {
            return true;
        }
        i += 1;
    }
    false
}

/// `list.iter().any(|x| x == "*")`.
pub fn list_has_star(list: &[Vec<u8>]) -> bool {
    let mut i = 0;
    while i < list.len() {
        if is_star(&list[i]) {
            return true;
        }
        i += 1;
    }
    false
}
