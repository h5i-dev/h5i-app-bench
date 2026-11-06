//! `crates/atuin-server/src/client_ip.rs`: the client address of a request
//! that may arrive through trusted reverse proxies.
//!
//! Parsing is outside: the peer and the proxy networks arrive parsed, and the
//! forwarding header arrives as its entries (every header value that is
//! visible ASCII, split at `,`, trimmed, empty entries dropped), each parsed
//! with `IpAddr::from_str` (`None` when that fails).

/// `std::net::IpAddr`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Ip {
    V4(u32),
    V6(u128),
}

/// `ipnet::IpNet`; `prefix` is at most 32 (V4) or 128 (V6), as `IpNet` ensures.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Net {
    V4 { addr: u32, prefix: u8 },
    V6 { addr: u128, prefix: u8 },
}

/// `Ipv4Net::netmask`: `u32::MAX.checked_shl(32 - prefix).unwrap_or(0)`.
pub fn mask4(prefix: u8) -> u32 {
    if prefix == 0 {
        0
    } else if prefix >= 32 {
        0xffff_ffff
    } else {
        0xffff_ffff << (32 - prefix as u32)
    }
}

/// `Ipv6Net::netmask`.
pub fn mask6(prefix: u8) -> u128 {
    if prefix == 0 {
        0
    } else if prefix >= 128 {
        0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff
    } else {
        0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff << (128 - prefix as u32)
    }
}

/// `IpNet::contains(&IpAddr)`: `network() <= ip <= broadcast()` within one
/// family, never across families.
pub fn net_contains(n: &Net, ip: &Ip) -> bool {
    match n {
        Net::V4 { addr, prefix } => match ip {
            Ip::V4(x) => {
                let m = mask4(*prefix);
                (*addr & m) <= *x && *x <= (*addr | !m)
            }
            Ip::V6(_) => false,
        },
        Net::V6 { addr, prefix } => match ip {
            Ip::V6(x) => {
                let m = mask6(*prefix);
                (*addr & m) <= *x && *x <= (*addr | !m)
            }
            Ip::V4(_) => false,
        },
    }
}

/// `TrustedProxies::contains`.
pub fn trusted(nets: &Vec<Net>, ip: &Ip) -> bool {
    let mut i = 0;
    while i < nets.len() {
        if net_contains(&nets[i], ip) {
            return true;
        }
        i += 1;
    }
    false
}

/// `IpAddr::to_canonical`: an IPv4-mapped IPv6 address (`::ffff:a.b.c.d`) is
/// the IPv4 address.
pub fn canonical(ip: &Ip) -> Ip {
    match ip {
        Ip::V4(x) => Ip::V4(*x),
        Ip::V6(x) => {
            if (*x >> 32) == 0xffff {
                Ip::V4((*x & 0xffff_ffff) as u32)
            } else {
                Ip::V6(*x)
            }
        }
    }
}

/// How the right-to-left walk over the header ends.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Walk {
    /// The first untrusted hop, canonical.
    Client(Ip),
    /// An entry that does not parse: fall back to the peer.
    Unparsable,
    /// Every entry is a trusted proxy.
    AllTrusted,
}

/// The `for entry in forwarded.iter().rev()` loop, from index `i - 1` down.
pub fn walk(entries: &Vec<Option<Ip>>, nets: &Vec<Net>) -> Walk {
    let mut i = entries.len();
    while i > 0 {
        i -= 1;
        match &entries[i] {
            None => return Walk::Unparsable,
            Some(ip) => {
                let c = canonical(ip);
                if !trusted(nets, &c) {
                    return Walk::Client(c);
                }
            }
        }
    }
    Walk::AllTrusted
}

/// `resolve_client_ip`.
pub fn resolve_client_ip(peer: &Ip, entries: &Vec<Option<Ip>>, nets: &Vec<Net>) -> Ip {
    let p = canonical(peer);
    if !trusted(nets, &p) {
        return p;
    }
    match walk(entries, nets) {
        Walk::Client(c) => c,
        Walk::Unparsable => p,
        // `forwarded.first().and_then(|e| e.parse().ok()).unwrap_or(peer)`:
        // the leftmost entry as parsed, not canonicalized.
        Walk::AllTrusted => {
            if entries.len() == 0 {
                p
            } else {
                match &entries[0] {
                    None => p,
                    Some(ip) => *ip,
                }
            }
        }
    }
}
