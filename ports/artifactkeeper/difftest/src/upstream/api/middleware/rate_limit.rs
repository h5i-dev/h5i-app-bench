// Copied from artifact-keeper/artifact-keeper @ 7c42891 by extract_upstream.py. Do not edit.
use std::net::IpAddr;

/// A parsed CIDR range used for IP-based rate-limit exemption (#969).
///
/// Stored as `(network, prefix_len)` so the membership check is a constant-
/// time bitmask compare, no allocations. Supports both IPv4 and IPv6.
#[derive(Debug, Clone, Copy)]
pub struct CidrRange {
    network: IpAddr,
    prefix_len: u8,
}
impl CidrRange {
    /// Parse a CIDR string of the form `"10.0.0.0/8"` or `"fc00::/7"`.
    pub fn parse(s: &str) -> Result<Self, String> {
        let (addr_str, prefix_str) = s
            .split_once('/')
            .ok_or_else(|| format!("missing '/' in CIDR: {}", s))?;
        let network: IpAddr = addr_str
            .parse()
            .map_err(|e| format!("invalid IP '{}': {}", addr_str, e))?;
        let prefix_len: u8 = prefix_str
            .parse()
            .map_err(|e| format!("invalid prefix length '{}': {}", prefix_str, e))?;
        let max_prefix = match network {
            IpAddr::V4(_) => 32,
            IpAddr::V6(_) => 128,
        };
        if prefix_len > max_prefix {
            return Err(format!(
                "prefix length {} exceeds maximum {} for {}",
                prefix_len, max_prefix, addr_str
            ));
        }
        Ok(Self {
            network,
            prefix_len,
        })
    }

    /// Whether `ip` falls within this CIDR range.
    pub fn contains(&self, ip: IpAddr) -> bool {
        match (self.network, ip) {
            (IpAddr::V4(net), IpAddr::V4(ip)) => {
                let net_bits = u32::from(net);
                let ip_bits = u32::from(ip);
                let mask = if self.prefix_len == 0 {
                    0
                } else {
                    u32::MAX
                        .checked_shl(32 - self.prefix_len as u32)
                        .unwrap_or(0)
                };
                (net_bits & mask) == (ip_bits & mask)
            }
            (IpAddr::V6(net), IpAddr::V6(ip)) => {
                let net_bits = u128::from(net);
                let ip_bits = u128::from(ip);
                let mask = if self.prefix_len == 0 {
                    0
                } else {
                    u128::MAX
                        .checked_shl(128 - self.prefix_len as u32)
                        .unwrap_or(0)
                };
                (net_bits & mask) == (ip_bits & mask)
            }
            // Mixed family: a v4 CIDR never contains a v6 address (and
            // vice versa). Operators wanting to cover both must list both.
            _ => false,
        }
    }
}
/// First `X-Forwarded-For` token, trimmed, as a string (may be a hostname or
/// otherwise non-parseable). `None` when the header is absent or empty. Used
/// only by the no-`ConnectInfo` (test-harness) fallback in
/// [`resolve_client_ip_addr`]; trusted-proxy resolution never takes the
/// leftmost token — see [`rightmost_untrusted_xff_token`]
/// (GHSA-8jm4-4x6c-6787).
fn first_xff_token_in(headers: &axum::http::HeaderMap) -> Option<&str> {
    headers
        .get("x-forwarded-for")?
        .to_str()
        .ok()?
        .split(',')
        .next()
        .map(str::trim)
        .filter(|s| !s.is_empty())
}
/// Rightmost `X-Forwarded-For` token that is NOT itself a trusted proxy —
/// the right-side-aware client-IP selection for GHSA-8jm4-4x6c-6787.
///
/// Trusted appending proxies (Caddy in the default compose deployment)
/// preserve any client-supplied `XFF` prefix and append the address they
/// actually observed, so the LEFTMOST token is attacker-controlled while the
/// RIGHT side of the chain is appended by hops we trust. Walk the tokens
/// right-to-left from the immediate peer: skip tokens inside a trusted-proxy
/// CIDR (appends by hops in our own chain) and select the first token outside
/// every trusted range — the address the outermost trusted proxy observed for
/// the downstream client.
///
/// An attacker prefix token can never be selected: it always sits LEFT of the
/// trusted proxy's own append, and the walk stops at the first non-trusted
/// token from the right. A non-empty token that fails to parse as an `IpAddr`
/// aborts the walk (`None` → caller falls back to the TCP peer) rather than
/// diving further left into attacker-controlled text; empty tokens carry no
/// information and are skipped. `None` is also returned when every token is
/// trusted (no client IP recoverable from the header).
///
/// ⚠️ Walks **every** `X-Forwarded-For` field line, last line first, not just
/// the first one (#3372). RFC 9110 §5.2 makes repeated field lines equivalent
/// to the comma-joined value *in order*, and proxies differ in which they
/// emit: Caddy merges into one line, but HAProxy (`option forwardfor`), Go
/// `net/http` reverse proxies and some Envoy configurations `Add` a second
/// line. Reading only `headers.get()` there returns the ATTACKER's line —
/// theirs arrives first — and the walk never sees the trusted proxy's own
/// append, leaving GHSA-8jm4-4x6c-6787 unmitigated for those topologies.
///
/// Tokens are stripped of an optional `:port` suffix and `[..]` brackets
/// before parsing: Azure Application Gateway appends `1.2.3.4:5678` and some
/// proxies append `[2001:db8::1]`, and treating either as unparseable aborted
/// the walk and silently collapsed every client onto the shared peer bucket.
/// Strip the decorations real proxies add to an `X-Forwarded-For` token so it
/// parses as a bare `IpAddr`: surrounding whitespace, `[..]` brackets around an
/// IPv6 literal, and a trailing `:port`.
///
/// A bare IPv6 address contains multiple colons and must NOT be truncated at
/// one, so a `:port` is only stripped when the remainder still looks like an
/// address (bracketed form, or a single colon as in `1.2.3.4:5678`).
fn normalize_xff_token(token: &str) -> &str {
    let t = token.trim();
    if let Some(rest) = t.strip_prefix('[') {
        // `[2001:db8::1]` or `[2001:db8::1]:443`
        if let Some(end) = rest.find(']') {
            return &rest[..end];
        }
        return t;
    }
    if t.matches(':').count() == 1 {
        // `1.2.3.4:5678` — an IPv4 address with a port. A bare IPv6 always
        // has two or more colons, so this cannot truncate one.
        if let Some((host, _port)) = t.rsplit_once(':') {
            return host;
        }
    }
    t
}
fn rightmost_untrusted_xff_token(
    headers: &axum::http::HeaderMap,
    trusted_proxies: &[CidrRange],
) -> Option<IpAddr> {
    // Last field line first, then tokens right-to-left within each line.
    let lines: Vec<&str> = headers
        .get_all("x-forwarded-for")
        .iter()
        .filter_map(|v| v.to_str().ok())
        .collect();
    if lines.is_empty() {
        return None;
    }
    for token in lines.iter().rev().flat_map(|line| line.split(',').rev()) {
        let token = normalize_xff_token(token);
        if token.is_empty() {
            continue;
        }
        match token.parse::<IpAddr>() {
            // Trusted proxy hop: keep walking left toward the client.
            Ok(ip) if trusted_proxies.iter().any(|cidr| cidr.contains(ip)) => continue,
            // First non-trusted IP from the right: the client as observed by
            // the outermost trusted proxy.
            Ok(ip) => return Some(ip),
            // Unparseable token: the chain is not a well-formed trusted
            // append; bail to the TCP peer instead of trusting text further
            // left.
            Err(_) => return None,
        }
    }
    None
}
/// Core client-IP resolution over bare request parts (#2365).
///
/// Same trusted-proxy contract as [`extract_client_ip_addr`], which delegates
/// here: the socket `peer` is authoritative; `X-Forwarded-For` overrides it
/// **only** when the peer falls inside a configured trusted-proxy CIDR
/// (#2023), and then the client is the rightmost token outside the trusted
/// ranges — never the attacker-controlled leftmost token
/// (GHSA-8jm4-4x6c-6787, see [`rightmost_untrusted_xff_token`]). With no peer
/// at all (test harness / pre-`ConnectInfo` topology), a parseable `XFF`
/// first token is a last-resort fallback. Returns `None` when nothing
/// resolves — callers must record "unknown", never a sentinel.
pub(crate) fn resolve_client_ip_addr(
    headers: &axum::http::HeaderMap,
    peer: Option<IpAddr>,
    trusted_proxies: &[CidrRange],
) -> Option<IpAddr> {
    if let Some(peer) = peer {
        // Believe XFF only when the immediate peer is a trusted proxy.
        if trusted_proxies.iter().any(|cidr| cidr.contains(peer)) {
            // GHSA-8jm4-4x6c-6787: select the rightmost non-trusted token,
            // NOT the leftmost. An appending trusted proxy preserves any
            // client-supplied XFF prefix, so the leftmost token is attacker-
            // controlled; the proxy's own append sits on the right. On any
            // parse/trust failure the walk yields None and the real TCP peer
            // remains the key.
            if let Some(ip) = rightmost_untrusted_xff_token(headers, trusted_proxies) {
                return Some(ip);
            }
        }
        // Untrusted peer (or trusted peer with no/unparseable/all-trusted
        // XFF): the real TCP peer is the key.
        return Some(peer);
    }

    // No ConnectInfo (test harness / pre-ConnectInfo topology): fall back to a
    // parseable XFF first token so keying still distinguishes callers.
    if let Some(first) = first_xff_token_in(headers) {
        if let Ok(ip) = first.parse::<IpAddr>() {
            return Some(ip);
        }
    }
    None
}
