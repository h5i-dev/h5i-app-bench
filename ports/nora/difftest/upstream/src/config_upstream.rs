// Copied from getnora-io/nora @ f864a9a by extract_upstream.py. Do not edit.
/// CIDR-aware trusted proxy list for X-Forwarded-For validation.
///
/// Only connections from trusted proxies have their XFF/X-Real-IP headers
/// honored. Untrusted sources always use the peer (TCP) IP address.
#[derive(Debug, Clone)]
pub struct TrustedProxies {
    entries: Vec<(std::net::IpAddr, u8)>, // (network address, prefix length)
}
impl TrustedProxies {
    /// Parse a comma-separated list of IPs/CIDRs. Invalid entries are skipped with a warning.
    pub fn parse(input: &str) -> Self {
        let mut entries = Vec::new();
        for item in input.split(',') {
            let item = item.trim();
            if item.is_empty() {
                continue;
            }
            if let Some((addr_str, prefix_str)) = item.split_once('/') {
                if let (Ok(addr), Ok(prefix)) = (
                    addr_str.parse::<std::net::IpAddr>(),
                    prefix_str.parse::<u8>(),
                ) {
                    let max_prefix = if addr.is_ipv4() { 32 } else { 128 };
                    if prefix <= max_prefix {
                        if prefix == 0 {
                            tracing::warn!(
                                value = %item,
                                "CIDR /0 matches ALL addresses in this family — all peers will be \
                                 trusted proxies (X-Forwarded-For honored, IP-based rate limiting disabled)"
                            );
                        }
                        entries.push((addr, prefix));
                    } else {
                        tracing::warn!(value = %item, "Invalid CIDR prefix length, skipping");
                    }
                } else {
                    tracing::warn!(value = %item, "Cannot parse CIDR, skipping");
                }
            } else if let Ok(addr) = item.parse::<std::net::IpAddr>() {
                let prefix = if addr.is_ipv4() { 32 } else { 128 };
                entries.push((addr, prefix));
            } else {
                tracing::warn!(value = %item, "Cannot parse IP address, skipping");
            }
        }
        Self { entries }
    }

    /// Default: loopback only (127.0.0.1 and ::1).
    pub fn default_loopback() -> Self {
        Self {
            entries: vec![
                (std::net::IpAddr::V4(std::net::Ipv4Addr::LOCALHOST), 32),
                (std::net::IpAddr::V6(std::net::Ipv6Addr::LOCALHOST), 128),
            ],
        }
    }

    /// Check if an IP address is within the trusted proxy list.
    pub fn contains(&self, ip: std::net::IpAddr) -> bool {
        self.entries.iter().any(|(network, prefix)| {
            match (network, ip) {
                (std::net::IpAddr::V4(net), std::net::IpAddr::V4(addr)) => {
                    // /0 matches all addresses in this family (RFC 4632).
                    // Must check before shift: u32::MAX << 32 overflows.
                    if *prefix == 0 {
                        return true;
                    }
                    if *prefix >= 32 {
                        return *net == addr;
                    }
                    let net_bits = u32::from(*net);
                    let addr_bits = u32::from(addr);
                    let mask = u32::MAX << (32 - prefix);
                    (net_bits & mask) == (addr_bits & mask)
                }
                (std::net::IpAddr::V6(net), std::net::IpAddr::V6(addr)) => {
                    // /0 matches all addresses in this family (RFC 4632).
                    // Must check before shift: u128::MAX << 128 overflows.
                    if *prefix == 0 {
                        return true;
                    }
                    if *prefix >= 128 {
                        return *net == addr;
                    }
                    let net_bits = u128::from(*net);
                    let addr_bits = u128::from(addr);
                    let mask = u128::MAX << (128 - prefix);
                    (net_bits & mask) == (addr_bits & mask)
                }
                _ => false, // v4 vs v6 mismatch
            }
        })
    }

    /// Returns true if any entry uses prefix /0 (matches all addresses in its family).
    pub fn has_prefix_zero(&self) -> bool {
        self.entries.iter().any(|(_, prefix)| *prefix == 0)
    }
}
/// How an OIDC provider's `namespace_scope` is applied on writes.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum ScopeEnforcement {
    /// Deny out-of-scope writes with HTTP 403 (default, fail-closed).
    #[default]
    Enforce,
    /// Allow out-of-scope writes but log and count them as `would_deny`. Used to
    /// stage a rollout before turning on hard denial.
    Audit,
}
