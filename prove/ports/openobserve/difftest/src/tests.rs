//! Differential tests: identical inputs to upstream (copied at the pinned
//! commit) and to the kernel, on accepted and refused cases. Deterministic
//! seeds; randomized testing is evidence, not a proof of equivalence.
use std::collections::HashSet;

use base64::{Engine, prelude::BASE64_URL_SAFE_NO_PAD};
use openobserve_kernel::delegation as k;

use crate::api_delegation as up;
use crate::config::meta::slack::{ExternalIdentityLink, SlackInstallation};
use crate::logcap;
use crate::stubs::AuthError;
use crate::utils::delegation as upc;

/// splitmix64.
pub struct Rng(u64);
impl Rng {
    pub fn new(seed: u64) -> Self {
        Rng(seed)
    }
    pub fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    pub fn below(&mut self, n: usize) -> usize {
        (self.next() % n as u64) as usize
    }
    pub fn chance(&mut self, num: u64, den: u64) -> bool {
        self.next() % den < num
    }
    pub fn pick<'a, T>(&mut self, xs: &'a [T]) -> &'a T {
        &xs[self.below(xs.len())]
    }
}

const NOW: i64 = 1_791_937_000;

fn kmethod(m: &http::Method) -> k::Method {
    match *m {
        http::Method::GET => k::Method::Get,
        http::Method::POST => k::Method::Post,
        http::Method::PUT => k::Method::Put,
        http::Method::DELETE => k::Method::Delete,
        http::Method::HEAD => k::Method::Head,
        http::Method::OPTIONS => k::Method::Options,
        http::Method::CONNECT => k::Method::Connect,
        http::Method::PATCH => k::Method::Patch,
        http::Method::TRACE => k::Method::Trace,
        _ => k::Method::Other,
    }
}

fn kclaims(c: &upc::Claims) -> k::Claims {
    k::Claims {
        v: c.v,
        sub: c.sub.as_bytes().to_vec(),
        org: c.org.as_bytes().to_vec(),
        lid: c.lid.as_bytes().to_vec(),
        scope: c.scope.as_bytes().to_vec(),
        iat: c.iat,
        exp: c.exp,
        jti: c.jti.as_bytes().to_vec(),
    }
}

/// The shell's half of `verify`: the decodings and MACs for this token.
fn oracle(keys: &upc::Keys, token: &str) -> k::VerifyOracle {
    let parts = token.strip_prefix(upc::TOKEN_PREFIX).and_then(|r| r.split_once('.'));
    let (claims_b64, mac_b64) = parts.unwrap_or(("", ""));
    k::VerifyOracle {
        given_mac: BASE64_URL_SAFE_NO_PAD.decode(mac_b64).ok(),
        mac_current: upc::seam_mac(&keys.current, claims_b64),
        mac_previous: keys.previous.as_ref().map(|p| upc::seam_mac(p, claims_b64)),
        claims: BASE64_URL_SAFE_NO_PAD
            .decode(claims_b64)
            .ok()
            .and_then(|j| serde_json::from_slice::<upc::Claims>(&j).ok())
            .map(|c| kclaims(&c)),
    }
}

fn kerr(e: &upc::DelegationError) -> k::DelegationError {
    use upc::DelegationError as E;
    match e {
        E::BadSignature => k::DelegationError::BadSignature,
        E::Expired => k::DelegationError::Expired,
        E::UnsupportedVersion(v) => k::DelegationError::UnsupportedVersion(*v),
        E::Malformed(m) => k::DelegationError::Malformed(if m == "expected o2dt.<claims>.<mac>" {
            k::Malformed::Shape
        } else if m.starts_with("mac: ") {
            k::Malformed::MacEncoding
        } else if m.starts_with("claims: ") {
            k::Malformed::ClaimsEncoding
        } else if m == "issued in the future" {
            k::Malformed::IssuedInFuture
        } else if m == "lifetime over an hour" {
            k::Malformed::LifetimeOverAnHour
        } else {
            panic!("unknown Malformed message {m:?}")
        }),
    }
}

const DELTAS: &[i64] = &[
    -100_000, -3661, -3660, -3600, -61, -60, -59, -1, 0, 1, 59, 60, 61, 62, 3599, 3600, 3601, 3659, 3660,
    3661, 3720, 7200, 100_000,
];

fn rand_text(r: &mut Rng, pool: &[&str]) -> String {
    if r.chance(1, 4) {
        let n = r.below(6);
        (0..n).map(|_| *r.pick(&['a', 'b', 'z', '_', '-', '.', '/', 'A', '0', 'é'])).collect()
    } else {
        r.pick(pool).to_string()
    }
}

fn rand_claims(r: &mut Rng) -> upc::Claims {
    let iat = NOW + *r.pick(DELTAS);
    let exp = if r.chance(1, 2) { iat + *r.pick(DELTAS) } else { NOW + *r.pick(DELTAS) };
    upc::Claims {
        v: *r.pick(&[1, 1, 1, 1, 0, 2, 255]),
        sub: rand_text(r, &["alice@acme.io", "bob@acme.io", ""]),
        org: rand_text(r, &["default", "acme", "v2", "api", ""]),
        lid: rand_text(r, &["lnk_01", "lnk_02", ""]),
        scope: rand_text(r, &["assistant", "slack_action", "Assistant", ""]),
        iat,
        exp,
        jti: rand_text(r, &["jti-0001", ""]),
    }
}

fn key(b: u8) -> Vec<u8> {
    vec![b; 32]
}

/// A token: honestly signed, signed by another or the previous key, or damaged.
fn rand_token(r: &mut Rng, keys: &upc::Keys) -> String {
    let claims = rand_claims(r);
    let signer = match r.below(4) {
        0 | 1 => keys.current.clone(),
        2 => keys.previous.clone().unwrap_or_else(|| key(9)),
        _ => key(9),
    };
    let sign_keys = upc::Keys { current: signer.clone(), previous: None };
    let good = upc::sign(&sign_keys, &claims);
    match r.below(12) {
        0 => good.replacen("o2dt.", "o2dx.", 1),
        1 => good.replace('.', ""),
        2 => format!("{good}.extra"),
        3 => good[..good.len() - r.below(5) - 1].to_string(),
        4 => {
            let junk = rand_text(r, &["e30", "bm90IGpzb24", "!!", ""]);
            let mac = BASE64_URL_SAFE_NO_PAD.encode(upc::seam_mac(&signer, &junk));
            format!("o2dt.{junk}.{mac}")
        }
        5 => format!("o2dt.{}", rand_text(r, &["", ".", "a.b"])),
        6 => good.replacen("o2dt.", "", 1),
        _ => good,
    }
}

#[test]
fn verify_agrees() {
    let mut r = Rng::new(0x0b5e_0001);
    let mut kinds = std::collections::BTreeMap::<String, usize>::new();
    for case in 0..60_000 {
        let keys = upc::Keys {
            current: key(5),
            previous: if r.chance(1, 2) { Some(key(6)) } else { None },
        };
        let token = rand_token(&mut r, &keys);
        let up = upc::verify(&keys, &token, NOW);
        let kr = k::verify(token.as_bytes(), &oracle(&keys, &token), NOW);
        let expect = up.as_ref().map(kclaims).map_err(kerr);
        assert_eq!(kr, expect, "case {case}: token {token:?}");
        *kinds.entry(format!("{:?}", expect.map(|_| ()))).or_default() += 1;
    }
    eprintln!("verify outcomes: {kinds:?}");
    assert!(kinds.len() >= 8, "too few distinct outcomes: {kinds:?}");
}

/// Upstream's `exp - iat` wraps in openobserve's release profiles (overflow
/// checks off), so a signed token with `exp = i64::MAX` and a negative `iat`
/// passes the one-hour lifetime check. The extracted kernel fails instead
/// (`check_claims_overflow` in Properties.lean). Run with `--release`.
#[cfg(not(debug_assertions))]
#[test]
fn upstream_release_wraps_lifetime_check() {
    let keys = upc::Keys { current: key(5), previous: None };
    let claims = upc::Claims {
        v: 1,
        sub: "alice@acme.io".into(),
        org: "default".into(),
        lid: "lnk_01".into(),
        scope: "assistant".into(),
        iat: -10,
        exp: i64::MAX,
        jti: "j".into(),
    };
    let token = upc::sign(&keys, &claims);
    let got = upc::verify(&keys, &token, NOW).expect("upstream accepts the wrapped lifetime");
    assert_eq!(got.exp, i64::MAX);
}

/// The same token in a build with overflow checks: upstream panics.
#[cfg(debug_assertions)]
#[test]
fn upstream_debug_panics_on_lifetime_overflow() {
    let keys = upc::Keys { current: key(5), previous: None };
    let claims = upc::Claims {
        v: 1,
        sub: "a".into(),
        org: "default".into(),
        lid: "l".into(),
        scope: "assistant".into(),
        iat: -10,
        exp: i64::MAX,
        jti: "j".into(),
    };
    let token = upc::sign(&keys, &claims);
    assert!(std::panic::catch_unwind(|| upc::verify(&keys, &token, NOW)).is_err());
}

#[test]
fn constant_time_eq_agrees() {
    let mut r = Rng::new(0x0b5e_0002);
    for _ in 0..50_000 {
        let n = r.below(5);
        let a: Vec<u8> = (0..n).map(|_| *r.pick(&[0u8, 1, 2, 255, 128])).collect();
        let b: Vec<u8> = if r.chance(1, 3) {
            a.clone()
        } else {
            (0..r.below(5)).map(|_| *r.pick(&[0u8, 1, 2, 255, 128])).collect()
        };
        assert_eq!(openobserve_kernel::bytes::constant_time_eq(&a, &b), crate::utils::str::constant_time_eq(&a, &b));
    }
}

/// Upstream's refusal reason, from its debug log.
fn reason(e: &AuthError, log: &[String]) -> k::AuthError {
    match e {
        AuthError::Unauthorized(_) => k::AuthError::Unauthorized,
        AuthError::Unavailable(_) => k::AuthError::Unavailable,
        AuthError::Forbidden(_) => {
            let line = log
                .iter()
                .rev()
                .find_map(|l| l.strip_prefix("delegated token refused: "))
                .expect("a logged reason");
            use k::Forbidden as F;
            k::AuthError::Forbidden(match line {
                "unknown token scope" => F::UnknownScope,
                "proxy routes are not delegated" => F::Proxy,
                "route has no org" => F::NoOrg,
                "token is for another org" => F::OtherOrg,
                "route is outside the token scope" => F::OutOfScope,
                "unknown link" => F::UnknownLink,
                "link revoked" => F::LinkRevoked,
                "installation revoked" => F::InstallationRevoked,
                "token subject is not the linked user" => F::NotLinkedUser,
                "org is not connected to the installation" => F::OrgNotConnected,
                other => panic!("unknown reason {other:?}"),
            })
        }
        other => panic!("unexpected {other:?}"),
    }
}

/// Every literal the route tables and slot exclusions mention, plus noise.
fn segment_pool() -> Vec<String> {
    let mut pool: Vec<String> = Vec::new();
    for routes in [openobserve_kernel::tables::assistant_scope(), openobserve_kernel::tables::slack_action_scope()] {
        for route in routes {
            for s in route.segments {
                if let k::Seg::Lit(l) = s {
                    pool.push(String::from_utf8(l).unwrap());
                }
            }
        }
    }
    for l in openobserve_kernel::tables::reserved_stream_slots()
        .into_iter()
        .chain(openobserve_kernel::tables::alert_id_literals())
    {
        pool.push(String::from_utf8(l).unwrap());
    }
    for s in ["", "v2", "v1", "api", "default", "acme", "logs", "x", "proxy", "Streams", "alerts"] {
        pool.push(s.to_string());
    }
    pool.sort();
    pool.dedup();
    pool
}

const METHODS: &[&str] = &["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS", "LIST", "TRACE"];

/// A path that usually instantiates one of the scope routes, sometimes damaged.
fn rand_path(r: &mut Rng, pool: &[String], org: &str) -> (String, http::Method) {
    let routes = if r.chance(1, 2) { openobserve_kernel::tables::assistant_scope() } else { openobserve_kernel::tables::slack_action_scope() };
    let route = r.pick(&routes).clone();
    let mut cols: Vec<String> = Vec::new();
    for (i, s) in route.segments.iter().enumerate() {
        cols.push(match s {
            k::Seg::Lit(l) => String::from_utf8(l.clone()).unwrap(),
            _ if i == 0 && r.chance(4, 5) => org.to_string(),
            _ if r.chance(1, 2) => r.pick(&["logs", "x", "a1", "default"]).to_string(),
            _ => r.pick(pool).clone(),
        });
    }
    match r.below(10) {
        0 => {
            cols.remove(r.below(cols.len()));
        }
        1 => cols.insert(r.below(cols.len() + 1), r.pick(pool).clone()),
        2 => {
            let i = r.below(cols.len());
            cols[i] = r.pick(pool).clone();
        }
        _ => {}
    }
    let v2 = route.v2 != r.chance(1, 10);
    let mut path = cols.join("/");
    if v2 {
        path = format!("v2/{path}");
    }
    if r.chance(1, 2) {
        path = format!("/{path}");
    }
    if r.chance(1, 20) {
        path = format!("{path}/");
    }
    let m = if r.chance(4, 5) {
        match route.methods[r.below(route.methods.len())] {
            k::Method::Get => "GET",
            k::Method::Post => "POST",
            _ => "PATCH",
        }
    } else {
        *r.pick(METHODS)
    };
    (path, http::Method::from_bytes(m.as_bytes()).unwrap())
}

#[test]
fn check_route_agrees() {
    let pool = segment_pool();
    let mut r = Rng::new(0x0b5e_0003);
    let mut kinds = std::collections::BTreeMap::<String, usize>::new();
    for case in 0..200_000 {
        let mut claims = rand_claims(&mut r);
        claims.scope = r.pick(&["assistant", "assistant", "slack_action", "slack_action", "other"]).to_string();
        claims.org = r.pick(&["default", "acme", "v2", "api", "alerts", ""]).to_string();
        let org = if r.chance(9, 10) { claims.org.clone() } else { r.pick(&pool).clone() };
        let (path, method) = rand_path(&mut r, &pool, &org);
        let prefix = *r.pick(&["/api/", "/api/", "/api/", "/proxy/", "/proxy", ""]);
        logcap::start();
        let up = up::seam_check_route(&path, prefix, &method, &claims);
        let log = logcap::take();
        let expect = up.as_ref().map(|_| ()).map_err(|e| reason(e, &log));
        let kr = k::check_route(path.as_bytes(), prefix.as_bytes(), kmethod(&method), &kclaims(&claims));
        assert_eq!(kr, expect, "case {case}: {method} {path:?} prefix {prefix:?} claims {claims:?}");
        *kinds.entry(format!("{expect:?}")).or_default() += 1;

        let rel = up::seam_relative_path(&path);
        assert_eq!(k::relative_path(path.as_bytes()), rel.as_bytes());
        assert_eq!(
            k::path_org(rel.as_bytes()),
            up::seam_path_org(rel).map(|o| o.as_bytes().to_vec()),
            "path_org {rel:?}"
        );
        assert_eq!(k::in_assistant_scope(kmethod(&method), rel.as_bytes()), up::in_assistant_scope(&method, rel));
        assert_eq!(
            k::in_slack_action_scope(kmethod(&method), rel.as_bytes()),
            up::in_slack_action_scope(&method, rel)
        );
    }
    eprintln!("check_route outcomes: {kinds:?}");
    assert!(kinds.len() >= 6, "too few distinct outcomes: {kinds:?}");
    assert!(kinds.get("Ok(())").copied().unwrap_or(0) > 10_000, "too few accepted routes: {kinds:?}");
}

#[test]
fn verified_claims_agrees() {
    let mut r = Rng::new(0x0b5e_0004);
    let mut kinds = std::collections::BTreeMap::<String, usize>::new();
    for case in 0..40_000 {
        let keys = upc::Keys { current: key(5), previous: None };
        let token = rand_token(&mut r, &keys);
        let slack_on = r.chance(9, 10);
        let keys_ok = r.chance(9, 10);
        let disabled: Vec<String> =
            (0..r.below(3)).map(|_| r.pick(&["default", "acme", "v2", ""]).to_string()).collect();
        logcap::start();
        let up = up::seam_verified_claims(&token, slack_on, keys_ok.then(|| keys.clone()), NOW, &disabled);
        let log = logcap::take();
        let expect = up.as_ref().map(kclaims).map_err(|e| reason(e, &log));
        let kdis: Vec<Vec<u8>> = disabled.iter().map(|s| s.as_bytes().to_vec()).collect();
        let kr = k::verified_claims(token.as_bytes(), slack_on, keys_ok, &oracle(&keys, &token), NOW, &kdis);
        assert_eq!(kr, expect, "case {case}: {token:?}");
        *kinds.entry(format!("{:?}", expect.map(|_| ()))).or_default() += 1;
    }
    eprintln!("verified_claims outcomes: {kinds:?}");
    assert!(kinds.len() >= 3);
}

#[test]
fn link_facts_agree() {
    let mut r = Rng::new(0x0b5e_0005);
    let mut kinds = std::collections::BTreeMap::<String, usize>::new();
    let emails = ["alice@acme.io", "bob@acme.io", "Alice@acme.io", ""];
    let orgs = ["default", "acme", "v2", ""];
    for case in 0..50_000 {
        let link = r.chance(9, 10).then(|| ExternalIdentityLink {
            id: "lnk_01".into(),
            installation_id: r.pick(&["inst_1", "inst_2"]).to_string(),
            user_email: r.pick(&emails).to_string(),
            last_used_at: r.next() as i64 >> 8,
            revoked_at: r.chance(1, 5).then_some(5),
        });
        let inst = r.chance(9, 10).then(|| SlackInstallation { id: "inst_1".into(), revoked_at: r.chance(1, 5).then_some(7) });
        let served: Vec<String> = (0..r.below(4)).map(|_| r.pick(&orgs).to_string()).collect();
        let mut claims = rand_claims(&mut r);
        claims.sub = r.pick(&emails).to_string();
        claims.org = r.pick(&orgs).to_string();
        logcap::start();
        let (up, up_inst, up_last) =
            up::seam_admit_rows(link.clone(), inst.clone(), served.iter().cloned().collect::<HashSet<_>>(), &claims);
        let log = logcap::take();
        let expect = up.as_ref().map(|_| ()).map_err(|e| reason(e, &log));
        let kfacts = k::from_rows(
            link.map(|l| k::LinkRow {
                id: l.id.into_bytes(),
                installation_id: l.installation_id.into_bytes(),
                user_email: l.user_email.into_bytes(),
                revoked: l.revoked_at.is_some(),
                last_used_at: l.last_used_at,
            }),
            inst.map(|i| k::Installation { id: i.id.into_bytes(), revoked: i.revoked_at.is_some(), served_orgs: Vec::new() }),
            served.iter().map(|s| s.as_bytes().to_vec()).collect(),
        );
        assert_eq!(k::admit(&kfacts, &kclaims(&claims)), expect, "case {case}");
        assert_eq!(kfacts.installation_id, up_inst.into_bytes());
        assert_eq!(kfacts.last_used_at, up_last);
        *kinds.entry(format!("{expect:?}")).or_default() += 1;
    }
    eprintln!("admit outcomes: {kinds:?}");
    assert!(kinds.len() >= 6);
}

#[test]
fn touch_due_agrees() {
    let mut r = Rng::new(0x0b5e_0006);
    for _ in 0..50_000 {
        let last = (r.next() >> 12) as i64;
        let now = last + *r.pick(&[-1, 0, 1, 59_999_999, 60_000_000, 60_000_001, 1 << 40]);
        assert_eq!(k::touch_due(last, now), up::seam_touch_due(last, now));
    }
}
