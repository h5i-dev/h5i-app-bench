//! `policy/utils/wildcard.rs`. `deep_match` is a loop that recurses on `*`;
//! here it is plain recursion on indices (Aeneas cannot compile a loop inside
//! a recursive function).

fn deep_match(p: &[u8], pi: usize, n: &[u8], ni: usize, simple: bool) -> bool {
    if pi >= p.len() {
        return ni >= n.len();
    }
    let c = p[pi];
    if c == b'?' {
        if ni >= n.len() {
            return simple;
        }
        return deep_match(p, pi + 1, n, ni + 1, simple);
    }
    if c == b'*' {
        return p.len() - pi == 1
            || deep_match(p, pi + 1, n, ni, simple)
            || (ni < n.len() && deep_match(p, pi, n, ni + 1, simple));
    }
    if ni >= n.len() || n[ni] != c {
        return false;
    }
    deep_match(p, pi + 1, n, ni + 1, simple)
}

fn inner_match(pattern: &[u8], name: &[u8], simple: bool) -> bool {
    if pattern.len() == 0 {
        return name.len() == 0;
    }
    if pattern.len() == 1 && pattern[0] == b'*' {
        return true;
    }
    deep_match(pattern, 0, name, 0, simple)
}

/// `is_simple_match`: `?` also matches the end of the name.
pub fn is_simple_match(pattern: &[u8], name: &[u8]) -> bool {
    inner_match(pattern, name, true)
}

/// `is_match`.
pub fn is_match(pattern: &[u8], name: &[u8]) -> bool {
    inner_match(pattern, name, false)
}
