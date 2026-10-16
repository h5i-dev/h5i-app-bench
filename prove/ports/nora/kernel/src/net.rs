//! `config/auth.rs` `TrustedProxies` and `auth/mod.rs` `resolve_client_ip`.
//! Parsing addresses (std's `IpAddr::from_str`) is trusted: the request
//! carries parsed addresses.

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum IpAddr {
    V4(u32),
    V6(u128),
}

/// `(network address, prefix length)` entries.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct TrustedProxies {
    pub entries: Vec<(IpAddr, u8)>,
}

fn entry_contains(network: IpAddr, prefix: u8, ip: IpAddr) -> bool {
    match (network, ip) {
        (IpAddr::V4(n), IpAddr::V4(addr)) => {
            if prefix == 0 {
                return true;
            }
            if prefix >= 32 {
                return n == addr;
            }
            let mask = u32::MAX << (32 - prefix);
            (n & mask) == (addr & mask)
        }
        (IpAddr::V6(n), IpAddr::V6(addr)) => {
            if prefix == 0 {
                return true;
            }
            if prefix >= 128 {
                return n == addr;
            }
            let mask = u128::MAX << (128 - prefix);
            (n & mask) == (addr & mask)
        }
        _ => false,
    }
}

impl TrustedProxies {
    /// `TrustedProxies::contains`.
    pub fn contains(&self, ip: IpAddr) -> bool {
        let mut i = 0;
        while i < self.entries.len() {
            let (nw, prefix) = self.entries[i];
            if entry_contains(nw, prefix, ip) {
                return true;
            }
            i += 1;
        }
        false
    }
}

/// `resolve_client_ip`. `xff` is the first `X-Forwarded-For` entry and
/// `x_real_ip` the `X-Real-IP` header, each when present and parseable.
pub fn resolve_client_ip(peer: IpAddr, xff: Option<IpAddr>, x_real_ip: Option<IpAddr>,
                         trusted_proxies: &TrustedProxies) -> IpAddr {
    if !trusted_proxies.contains(peer) {
        return peer;
    }
    if let Some(ip) = xff {
        return ip;
    }
    if let Some(ip) = x_real_ip {
        return ip;
    }
    peer
}
