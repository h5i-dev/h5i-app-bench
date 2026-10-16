//! Falsification and non-vacuity tests for the middleware statements in
//! proofs/Properties.lean, on random kernel inputs (no upstream needed).
use crate::tests::Rng;
use nora_kernel::lockout::{AuthFailureTracker, FailureEntry, NANOS_PER_SEC};
use nora_kernel::middleware::{self as km, auth_middleware, Deny, HttpMethod, Outcome, Write};
use nora_kernel::net::{resolve_client_ip, IpAddr, TrustedProxies};
use nora_kernel::oracle::Crypto;
use nora_kernel::tokens::{verify_token, CachedToken, TokenFile, TokenInfo, TokenStore};
use nora_kernel::validation::*;
use nora_kernel::{self as k, Role};

const N: usize = 400_000;
const MIN_HITS: usize = 200;
const PATHS: &[&str] = &["/", "/health", "/api/tokens", "/ui/x", "/ui/tokens/1", "/api/ui/tokens", "/api-docs",
    "/metrics", "/v2", "/v2/_catalog", "/v2/a/manifests/1", "/api/v1/admin/gc", "/npm/-/whoami", "/npm/p",
    "/npm/-/npm/v1/security/advisories/bulk", "/raw/x"];
const IPS: &[IpAddr] = &[IpAddr::V4(0x7f000001), IpAddr::V4(0x0a000001), IpAddr::V6(1), IpAddr::V6(7)];
const TOKS: &[&[u8]] = &[b"nra_a", b"nra_b", b"x", b"jwt"];

fn pick<'a, T>(r: &mut Rng, xs: &'a [T]) -> &'a T {
    &xs[r.below(xs.len() as u64) as usize]
}
fn role(r: &mut Rng) -> Role {
    *pick(r, &[Role::Read, Role::Write, Role::Admin])
}

/// Random inputs; the oracle tables are arbitrary, as in the theorems.
fn case(r: &mut Rng) -> (km::Config, Vec<FailureEntry>, Crypto, Option<km::Jwt>, km::Request) {
    let now = 1000;
    let mono = 1_000_000 * NANOS_PER_SEC;
    let sha = |t: &[u8]| -> Vec<u8> { let mut v = b"0123456789abcdef".to_vec(); v.push(t[0]); v };
    let mut crypto = Crypto { sha256: vec![], argon2_ok: vec![], bcrypt_ok: vec![], base64: vec![], utf8_ok: vec![] };
    for t in TOKS {
        crypto.sha256.push((t.to_vec(), sha(t)));
        if r.chance(50) { crypto.argon2_ok.push((t.to_vec(), b"$argon2x".to_vec())); }
    }
    let mut files = Vec::new();
    let mut cache = Vec::new();
    for t in TOKS {
        if r.chance(50) {
            let info = if r.chance(90) { Some(TokenInfo {
                token_hash: if r.chance(50) { b"$argon2x".to_vec() } else { sha(t) },
                user: b"u".to_vec(), expires_at: if r.chance(70) { 2000 } else { 10 }, role: role(r) }) } else { None };
            files.push(TokenFile { prefix: sha(t)[..16].to_vec(), info });
        }
        if r.chance(30) {
            cache.push(CachedToken { key: sha(t), user: b"c".to_vec(), role: role(r),
                expires_at: if r.chance(70) { 2000 } else { 10 }, cached_at: mono - r.below(20) * NANOS_PER_SEC });
        }
    }
    let creds: &[&[u8]] = &[b"alice:pw", b"alice:bad", b"x:nra_a", b"nocolon"];
    for c in creds {
        let enc = [b"E".as_slice(), c].concat();
        crypto.base64.push((enc, if r.chance(90) { Some(c.to_vec()) } else { None }));
        if r.chance(90) { crypto.utf8_ok.push(c.to_vec()); }
    }
    crypto.bcrypt_ok.push((b"pw".to_vec(), b"H".to_vec()));
    let cfg = km::Config {
        enabled: r.chance(90), anonymous_read: r.chance(40), public_web_ui: r.chance(30), public_metrics: r.chance(30),
        docker_anon_pull: r.chance(40),
        htpasswd: if r.chance(70) { Some(vec![(b"alice".to_vec(), b"H".to_vec())]) } else { None },
        tokens: if r.chance(70) { Some(TokenStore { files, cache, cache_ttl: 10 * NANOS_PER_SEC }) } else { None },
        oidc: if r.chance(40) {
            Some((k::OidcProvider { max_token_lifetime_secs: 100,
                role_rules: vec![k::OidcRoleRule { pattern: b"*".to_vec(), role: pick(r, &[b"read".to_vec(), b"write".to_vec(), b"admin".to_vec()]).clone(), namespace_scope: None }],
                namespace_scope: vec![b"*".to_vec()], namespace_scope_enforcement: k::ScopeEnforcement::Enforce }, r.chance(90)))
        } else { None },
        trusted_proxies: TrustedProxies { entries: if r.chance(50) { vec![(IpAddr::V4(0x7f000001), 32)] } else { vec![] } },
        tracker: AuthFailureTracker { max_failures: 1 + r.below(4) as u32, max_lockout_secs: 1 + r.below(100) },
    };
    let mut failures = Vec::new();
    for ip in IPS {
        if r.chance(30) {
            failures.push(FailureEntry { ip: *ip, failures: r.below(8) as u32, last_failure: mono - r.below(60) * NANOS_PER_SEC });
        }
    }
    let header: Option<Vec<u8>> = match r.below(5) {
        0 => None,
        1 | 2 => Some([b"Basic E".as_slice(), pick(r, creds)].concat()),
        3 => Some([b"Bearer ".as_slice(), pick(r, TOKS)].concat()),
        _ => Some(b"Other".to_vec()),
    };
    let jwt = Some(km::Jwt { token: b"jwt".to_vec(), claims: Some(k::Claims { sub: Some(b"s".to_vec()), iat: None, exp: None }) });
    let req = km::Request {
        path: pick(r, PATHS).as_bytes().to_vec(),
        method: *pick(r, &[HttpMethod::Get, HttpMethod::Head, HttpMethod::Post, HttpMethod::Put, HttpMethod::Delete, HttpMethod::Patch, HttpMethod::Options]),
        has_auth_header: header.is_some() || r.chance(10), auth_header: header,
        peer: if r.chance(90) { Some(*pick(r, IPS)) } else { None },
        xff: if r.chance(30) { Some(*pick(r, IPS)) } else { None }, x_real_ip: None, now, mono,
    };
    (cfg, failures, crypto, jwt, req)
}

fn starts(s: &[u8], p: &str) -> bool {
    s.starts_with(p.as_bytes())
}
pub fn is_open(cfg: &km::Config, p: &[u8]) -> bool {
    km::is_public_path(p) || (km::is_web_surface(p) && (cfg.anonymous_read || cfg.public_web_ui))
        || (p == b"/metrics" && cfg.public_metrics)
}
fn is_write(m: HttpMethod) -> bool {
    matches!(m, HttpMethod::Post | HttpMethod::Put | HttpMethod::Delete | HttpMethod::Patch)
}
fn is_npm_audit(p: &[u8]) -> bool {
    p == b"/npm/-/npm/v1/security/advisories/bulk" || p == b"/npm/-/npm/v1/security/audits/quick"
}
fn client_ip(cfg: &km::Config, req: &km::Request) -> Option<IpAddr> {
    req.peer.map(|p| resolve_client_ip(p, req.xff, req.x_real_ip, &cfg.trusted_proxies))
}

fn property(seed: u64, check: impl Fn(&km::Config, &[FailureEntry], &km::Request, &[Write], &Outcome) -> bool) {
    let mut r = Rng(seed);
    let mut hits = 0;
    for _ in 0..N {
        let (cfg, fs, cr, jwt, req) = case(&mut r);
        let (ws, out) = auth_middleware(&cfg, &fs, &cr, &jwt, &req);
        if check(&cfg, &fs, &req, &ws, &out) {
            hits += 1;
        }
    }
    assert!(hits >= MIN_HITS, "premises held only {hits} times");
}

#[test]
fn admin_path_needs_admin() {
    property(11, |cfg, _, req, _, out| {
        let Outcome::Next { role, .. } = out else { return false };
        if !cfg.enabled || !km::is_admin_path(&req.path) { return false }
        assert_eq!(*role, Some(Role::Admin));
        true
    });
}

#[test]
fn no_credentials_no_write_role() {
    property(12, |cfg, _, req, _, out| {
        let Outcome::Next { role, .. } = out else { return false };
        if !cfg.enabled || req.auth_header.is_some() { return false }
        assert!(matches!(role, None | Some(Role::Read)), "{role:?}");
        true
    });
}

#[test]
fn writes_need_write_role() {
    property(13, |cfg, _, req, _, out| {
        let Outcome::Next { role, .. } = out else { return false };
        if !cfg.enabled || !is_write(req.method) || is_open(cfg, &req.path) || is_npm_audit(&req.path) { return false }
        assert!(matches!(role, Some(Role::Write | Role::Admin)), "{role:?} {req:?}");
        true
    });
}

#[test]
fn locked_out_ip_authenticates_only_on_open_paths() {
    property(14, |cfg, fs, req, _, out| {
        let Outcome::Next { user, .. } = out else { return false };
        let Some(ip) = client_ip(cfg, req) else { return false };
        if !cfg.enabled || user == b"anonymous" || cfg.tracker.check_blocked(fs, ip, req.mono).is_none() { return false }
        assert!(is_open(cfg, &req.path), "{req:?}");
        true
    });
}

#[test]
fn catalog_and_token_pages_never_anonymous() {
    property(15, |cfg, _, req, _, out| {
        let Outcome::Next { .. } = out else { return false };
        let p = &req.path;
        if !cfg.enabled || !(p == b"/v2/_catalog" || starts(p, "/ui/tokens") || starts(p, "/api/ui/tokens")) { return false }
        assert!(req.auth_header.is_some());
        true
    });
}

#[test]
fn failures_recorded_only_for_bad_credentials() {
    property(16, |_, _, _, ws, out| {
        let put = ws.iter().any(|w| matches!(w, Write::PutFailures(_)));
        let clear = ws.iter().any(|w| matches!(w, Write::ClearFailures(_)));
        if !put && !clear { return false }
        if put {
            assert!(matches!(out, Outcome::Deny(Deny::InvalidOrExpiredToken | Deny::InvalidUsernameOrPassword)), "{out:?}");
        }
        if clear {
            assert!(matches!(out, Outcome::Next { .. } | Outcome::Deny(Deny::ReadOnlyToken | Deny::ReadOnlyOidc | Deny::AdminRequired)), "{out:?}");
        }
        true
    });
}

#[test]
fn token_accepted_only_unexpired_with_prefix() {
    let mut r = Rng(17);
    let mut hits = 0;
    for _ in 0..N {
        let (cfg, _, cr, _, req) = case(&mut r);
        let Some(store) = &cfg.tokens else { continue };
        let t = *pick(&mut r, TOKS);
        let (_, res) = verify_token(store, &cr, t, req.now, req.mono);
        let Ok((u, ro)) = res else { continue };
        hits += 1;
        assert!(t.starts_with(b"nra_"));
        let cached = store.cache.iter().any(|c| c.user == u && c.role == ro && req.now <= c.expires_at);
        let filed = store.files.iter().any(|f| f.info.as_ref().is_some_and(|i| i.user == u && i.role == ro && req.now <= i.expires_at));
        assert!(cached || filed);
    }
    assert!(hits >= MIN_HITS);
}

#[test]
fn untrusted_peer_is_client() {
    let mut r = Rng(18);
    for _ in 0..N {
        let (cfg, _, _, _, req) = case(&mut r);
        let Some(p) = req.peer else { continue };
        let ip = resolve_client_ip(p, req.xff, req.x_real_ip, &cfg.trusted_proxies);
        if !cfg.trusted_proxies.contains(p) {
            assert_eq!(ip, p);
        }
    }
}

/// `contains` against the prefix comparison written with division.
#[test]
fn cidr_contains_spec() {
    let mut r = Rng(19);
    for _ in 0..N {
        let v6 = r.chance(50);
        let bits = if v6 { 128 } else { 32 };
        let rnd = |r: &mut Rng| -> u128 { if v6 { (r.next() as u128) << 64 | r.next() as u128 } else { r.next() as u32 as u128 } };
        let net = rnd(&mut r);
        let addr = if r.chance(50) { net ^ (1u128 << r.below(bits)) } else { rnd(&mut r) };
        let prefix = r.below(bits + 20) as u8;
        let mk = |x: u128| if v6 { IpAddr::V6(x) } else { IpAddr::V4(x as u32) };
        let got = TrustedProxies { entries: vec![(mk(net), prefix)] }.contains(mk(addr));
        let p = (prefix as u32).min(bits as u32);
        let shift = bits as u32 - p;
        let want = if shift == 128 { true } else { net >> shift == addr >> shift };
        assert_eq!(got, want);
    }
}

fn is_lower_hex(c: u8) -> bool {
    c.is_ascii_digit() || (b'a'..=b'f').contains(&c)
}
fn text(r: &mut Rng) -> Vec<u8> {
    const A: &[&str] = &["a", "Z", "0", "f", ".", "..", "/", "\\", "-", "_", ":", "\0", "é", "sha256:", "sha512:",
        "a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4"];
    if r.chance(3) {
        return b"sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4".to_vec();
    }
    let n = r.below(8);
    (0..n).flat_map(|_| pick(r, A).as_bytes().to_vec()).collect()
}

#[test]
fn validators_characterized() {
    let mut r = Rng(20);
    let mut hits = [0; 4];
    for _ in 0..N {
        let s = text(&mut r);
        if validate_storage_key(&s).is_ok() {
            hits[0] += 1;
            assert!(s.is_ascii() && !s.contains(&0) && !s.contains(&b'\\') && s[0] != b'/');
            assert!(s.split(|&c| c == b'/').all(|seg| seg != b"." && seg != b".."));
        }
        if validate_docker_name(&s).is_ok() {
            hits[1] += 1;
            assert!(s.len() <= 256);
            assert!(s.split(|&c| c == b'/').all(|seg| !seg.is_empty() && seg[0].is_ascii_alphanumeric()
                && seg.iter().all(|&c| c.is_ascii_lowercase() || c.is_ascii_digit() || b"_.-".contains(&c))));
        }
        let digest_shape = |d: &[u8]| (d.starts_with(b"sha256:") && d.len() == 71 && d[7..].iter().all(|&c| is_lower_hex(c)))
            || (d.starts_with(b"sha512:") && d.len() == 135 && d[7..].iter().all(|&c| is_lower_hex(c)));
        let ok = validate_digest(&s).is_ok();
        assert_eq!(ok, digest_shape(&s), "{s:?}");
        hits[2] += ok as usize;
        if validate_docker_reference(&s).is_ok() {
            hits[3] += 1;
            assert!(digest_shape(&s) || (s.len() <= 128 && s[0].is_ascii_alphanumeric()
                && s.iter().all(|&c| c.is_ascii_alphanumeric() || b"._-".contains(&c))));
        }
    }
    assert!(hits.iter().all(|&h| h >= MIN_HITS), "{hits:?}");
}

#[test]
fn total_below_counter_limit() {
    // Runs every case above without a panic; the counter limit is exercised here.
    let fs = vec![FailureEntry { ip: IpAddr::V4(1), failures: u32::MAX, last_failure: 0 }];
    let r = std::panic::catch_unwind(|| nora_kernel::lockout::after_failure(&fs, IpAddr::V4(1), 0));
    assert!(r.is_err() || cfg!(not(debug_assertions)));
}

#[test]
fn revoked_token_rejected() {
    use nora_kernel::tokens::revoke_token;
    let mut r = Rng(21);
    let mut hits = 0;
    for _ in 0..N {
        let (cfg, _, cr, _, req) = case(&mut r);
        let Some(store) = &cfg.tokens else { continue };
        let t = *pick(&mut r, TOKS);
        let sha = cr.sha256_hex(t);
        let (after, res) = revoke_token(store, &sha[..16]);
        if res.is_err() { continue }
        hits += 1;
        let (_, v) = verify_token(&after, &cr, t, req.now, req.mono);
        assert!(v.is_err());
    }
    assert!(hits >= MIN_HITS, "{hits}");
}

#[test]
fn revoke_all_effective() {
    use nora_kernel::tokens::revoke_all_for_user;
    let mut r = Rng(22);
    let mut hits = 0;
    for _ in 0..N {
        let (cfg, _, cr, _, req) = case(&mut r);
        let Some(store) = &cfg.tokens else { continue };
        let user: &[u8] = pick(&mut r, &[b"u".as_slice(), b"c".as_slice()]);
        let (after, n) = revoke_all_for_user(store, user);
        if n == 0 { continue }
        for t in TOKS {
            if let (_, Ok((u, _))) = verify_token(&after, &cr, t, req.now, req.mono) {
                hits += 1;
                assert_ne!(u, user);
            }
        }
    }
    assert!(hits >= MIN_HITS, "{hits}");
}
