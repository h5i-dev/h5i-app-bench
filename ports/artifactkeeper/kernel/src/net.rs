//! Client-IP resolution and CIDR ranges: `api/middleware/rate_limit.rs`.
use crate::strs::*;
use crate::http::{header_str, visible_ascii};
use crate::trusted::Oracle;

/// `std::net::IpAddr` as its integer value.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum IpAddr {
    V4(u32),
    V6(u128),
}

/// `CidrRange`: `prefix_len` is at most 32 (v4) or 128 (v6), which `parse`
/// guarantees.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct CidrRange {
    pub network: IpAddr,
    pub prefix_len: u8,
}

/// `u8::from_str`: an optional `+`, then one or more decimal digits, at
/// most 255.
pub fn parse_u8(s: &[u8]) -> Option<u8> {
    let start = if s.len() > 0 && s[0] == b'+' { 1 } else { 0 };
    if start >= s.len() {
        return None;
    }
    decimal_from(s, start)
}

/// The digits `s[i..]` as a `u8`, `None` on a non-digit or overflow.
fn decimal_from(s: &[u8], start: usize) -> Option<u8> {
    let mut v: u32 = 0;
    let mut i = start;
    while i < s.len() {
        let b = s[i];
        if b < b'0' || b > b'9' {
            return None;
        }
        v = v * 10 + (b - b'0') as u32;
        if v > 255 {
            return None;
        }
        i += 1;
    }
    Some(v as u8)
}

impl CidrRange {
    /// `CidrRange::parse`; the error message is dropped.
    pub fn parse(oracle: &Oracle, s: &[u8]) -> Result<CidrRange, ()> {
        let (addr_str, prefix_str) = match split_once(s, b'/') {
            Some(p) => p,
            None => return Err(()),
        };
        let network = match oracle.parse_ip(&addr_str) {
            Some(ip) => ip,
            None => return Err(()),
        };
        let prefix_len = match parse_u8(&prefix_str) {
            Some(p) => p,
            None => return Err(()),
        };
        let max_prefix = match network {
            IpAddr::V4(_) => 32,
            IpAddr::V6(_) => 128,
        };
        if prefix_len > max_prefix {
            return Err(());
        }
        Ok(CidrRange { network, prefix_len })
    }

    /// `CidrRange::contains`. `checked_shl(w - p).unwrap_or(0)` never
    /// fails for `1 <= p <= w`; a prefix over the width (not constructible)
    /// is read as the full width.
    pub fn contains(&self, ip: IpAddr) -> bool {
        match (self.network, ip) {
            (IpAddr::V4(nw), IpAddr::V4(ip)) => {
                let mask: u32 = if self.prefix_len == 0 {
                    0
                } else if self.prefix_len >= 32 {
                    u32::MAX
                } else {
                    u32::MAX << (32 - self.prefix_len as u32)
                };
                (nw & mask) == (ip & mask)
            }
            (IpAddr::V6(nw), IpAddr::V6(ip)) => {
                let mask: u128 = if self.prefix_len == 0 {
                    0
                } else if self.prefix_len >= 128 {
                    u128::MAX
                } else {
                    u128::MAX << (128 - self.prefix_len as u32)
                };
                (nw & mask) == (ip & mask)
            }
            _ => false,
        }
    }
}

/// `trusted_proxies.iter().any(|cidr| cidr.contains(ip))`.
pub fn any_contains(ranges: &[CidrRange], ip: IpAddr) -> bool {
    let mut i = 0;
    while i < ranges.len() {
        if ranges[i].contains(ip) {
            return true;
        }
        i += 1;
    }
    false
}

/// `first_xff_token_in`.
pub fn first_xff_token_in(headers: &[(Vec<u8>, Vec<u8>)]) -> Option<Vec<u8>> {
    let v = match header_str(headers, b"x-forwarded-for") {
        Some(v) => v,
        None => return None,
    };
    let first = match find_byte(&v, b',') {
        Some(i) => sub(&v, 0, i),
        None => v,
    };
    let t = trim(&first);
    if t.len() > 0 { Some(t) } else { None }
}

/// `normalize_xff_token`.
pub fn normalize_xff_token(token: &[u8]) -> Vec<u8> {
    let t = trim(token);
    if let Some(rest) = strip_prefix(&t, b"[") {
        return match find_byte(&rest, b']') {
            Some(end) => sub(&rest, 0, end),
            None => t,
        };
    }
    if count_byte(&t, b':') == 1 {
        if let Some((host, _port)) = rsplit_once(&t, b':') {
            return host;
        }
    }
    t
}

/// One step of the right-to-left walk in `rightmost_untrusted_xff_token`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Walk {
    /// Empty or trusted token: keep walking left.
    Next,
    Found(IpAddr),
    /// Unparseable token: stop, fall back to the peer.
    Abort,
}

fn walk_token(oracle: &Oracle, proxies: &[CidrRange], raw: &[u8]) -> Walk {
    let token = normalize_xff_token(raw);
    if token.len() == 0 {
        return Walk::Next;
    }
    match oracle.parse_ip(&token) {
        Some(ip) => {
            if any_contains(proxies, ip) { Walk::Next } else { Walk::Found(ip) }
        }
        None => Walk::Abort,
    }
}

/// The tokens of one field line, right to left.
fn walk_line(oracle: &Oracle, proxies: &[CidrRange], line: &[u8]) -> Walk {
    let tokens = split(line, b',');
    let mut k = tokens.len();
    while k > 0 {
        k -= 1;
        let w = walk_token(oracle, proxies, &tokens[k]);
        if w != Walk::Next {
            return w;
        }
    }
    Walk::Next
}

fn is_xff_line(h: &(Vec<u8>, Vec<u8>)) -> bool {
    bytes_eq(&h.0, b"x-forwarded-for") && visible_ascii(&h.1)
}

/// `headers.get_all("x-forwarded-for")` values that pass `to_str`.
fn xff_lines(headers: &[(Vec<u8>, Vec<u8>)]) -> Vec<Vec<u8>> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < headers.len() {
        let h = &headers[i];
        if is_xff_line(h) {
            out.push(h.1.clone());
        }
        i += 1;
    }
    out
}

/// `rightmost_untrusted_xff_token`: last line first.
pub fn rightmost_untrusted_xff_token(oracle: &Oracle, headers: &[(Vec<u8>, Vec<u8>)],
                                     trusted_proxies: &[CidrRange]) -> Option<IpAddr> {
    let lines = xff_lines(headers);
    let mut k = lines.len();
    while k > 0 {
        k -= 1;
        match walk_line(oracle, trusted_proxies, &lines[k]) {
            Walk::Found(ip) => return Some(ip),
            Walk::Abort => return None,
            Walk::Next => {}
        }
    }
    None
}

/// `resolve_client_ip_addr`.
pub fn resolve_client_ip_addr(oracle: &Oracle, headers: &[(Vec<u8>, Vec<u8>)], peer: Option<IpAddr>,
                              trusted_proxies: &[CidrRange]) -> Option<IpAddr> {
    if let Some(peer) = peer {
        if any_contains(trusted_proxies, peer) {
            if let Some(ip) = rightmost_untrusted_xff_token(oracle, headers, trusted_proxies) {
                return Some(ip);
            }
        }
        return Some(peer);
    }
    if let Some(first) = first_xff_token_in(headers) {
        if let Some(ip) = oracle.parse_ip(&first) {
            return Some(ip);
        }
    }
    None
}
