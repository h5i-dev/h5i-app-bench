//! `auth_middleware` against nora's own middleware, run through an axum
//! router with a real token directory, bcrypt, SHA-256 and Argon2. The
//! kernel gets the oracle tables computed from the same functions.
use std::collections::HashMap;
use std::net::{IpAddr as StdIp, Ipv4Addr, Ipv6Addr, SocketAddr};
use std::sync::Arc;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use axum::body::Body;
use axum::extract::ConnectInfo;
use axum::http::{HeaderValue, Request, StatusCode};
use axum::response::IntoResponse;
use axum::Router;
use base64::{engine::general_purpose::STANDARD, Engine};
use tower::ServiceExt;

use nora_kernel::lockout::{AuthFailureTracker as KTracker, FailureEntry, NANOS_PER_SEC};
use nora_kernel::middleware::{self as km, Deny, HttpMethod, Outcome, Write};
use nora_kernel::net::{IpAddr as KIp, TrustedProxies as KProxies};
use nora_kernel::oracle::Crypto;
use nora_kernel::tokens::{CachedToken, TokenFile, TokenInfo as KInfo, TokenStore as KStore, TokenWrite};
use nora_kernel::{self as k, Role as KRole};
use nora_upstream as up;
use nora_upstream::auth::oidc as uo;
use nora_upstream::tokens::{Role as URole, TokenInfo};

use crate::tests::Rng;

const TOKENS: &[&str] = &["nra_alpha", "nra_beta", "nra_gamma", "nra_delta", "plain_token", "jwt-one", "jwt-two"];
const USERS: &[(&str, &str)] = &[("alice", "pw1"), ("bob", "pw2")];
const PATHS: &[&str] = &["/", "/health", "/ready", "/api/tokens", "/api/tokens/list", "/api/tokens/revoke",
    "/ui", "/ui/repos", "/ui/tokens", "/api/ui/tokens/1", "/api/ui/stats", "/api-docs", "/metrics",
    "/v2", "/v2/", "/v2/_catalog", "/v2/lib/nginx/manifests/1", "/v2x", "/api/v1/admin/gc", "/api/v1/adminx",
    "/npm/-/whoami", "/npm/pkg", "/npm/-/npm/v1/security/advisories/bulk", "/npm/-/npm/v1/security/audits/quick",
    "/maven/org/a/1.0/a.jar", "/raw/x"];
const METHODS: &[(HttpMethod, &str)] = &[(HttpMethod::Get, "GET"), (HttpMethod::Head, "HEAD"),
    (HttpMethod::Post, "POST"), (HttpMethod::Put, "PUT"), (HttpMethod::Delete, "DELETE"),
    (HttpMethod::Patch, "PATCH"), (HttpMethod::Options, "OPTIONS")];
const IPS: &[StdIp] = &[StdIp::V4(Ipv4Addr::new(127, 0, 0, 1)), StdIp::V4(Ipv4Addr::new(10, 0, 0, 1)),
    StdIp::V4(Ipv4Addr::new(10, 0, 0, 2)), StdIp::V4(Ipv4Addr::new(192, 168, 1, 5)),
    StdIp::V6(Ipv6Addr::LOCALHOST), StdIp::V6(Ipv6Addr::new(0x2001, 0xdb8, 0, 0, 0, 0, 0, 1))];
/// Kernel monotonic time at the request; upstream's `Instant::now()` maps to it.
const MONO: u64 = 1 << 50;

fn kip(ip: StdIp) -> KIp {
    match ip {
        StdIp::V4(a) => KIp::V4(u32::from(a)),
        StdIp::V6(a) => KIp::V6(u128::from(a)),
    }
}
fn krole(r: &URole) -> KRole {
    match r {
        URole::Read => KRole::Read,
        URole::Write => KRole::Write,
        URole::Admin => KRole::Admin,
        _ => unreachable!(),
    }
}
fn urole(r: KRole) -> URole {
    match r {
        KRole::Read => URole::Read,
        KRole::Write => URole::Write,
        KRole::Admin => URole::Admin,
    }
}
fn b(s: &str) -> Vec<u8> {
    s.as_bytes().to_vec()
}

/// Hashes computed once: Argon2 and bcrypt are slow.
struct Pool {
    sha: HashMap<&'static str, String>,
    argon: HashMap<&'static str, String>,
    bcrypt: HashMap<&'static str, String>,
}
fn pool() -> Pool {
    Pool {
        sha: TOKENS.iter().map(|t| (*t, up::tokens::seam_sha256_hex(t))).collect(),
        argon: TOKENS.iter().map(|t| (*t, up::tokens::seam_hash_argon2(t))).collect(),
        bcrypt: USERS.iter().map(|(u, p)| (*u, bcrypt::hash(p, 4).unwrap())).collect(),
    }
}

/// One random scenario, in both representations.
struct Case {
    kcfg: km::Config,
    kfail: Vec<FailureEntry>,
    crypto: Crypto,
    jwt: Option<km::Jwt>,
    kreq: km::Request,
    state: up::AppState,
    req: Request<Body>,
    dir: tempfile::TempDir,
}

fn pick<'a, T>(r: &mut Rng, xs: &'a [T]) -> &'a T {
    &xs[r.below(xs.len() as u64) as usize]
}

fn scope(r: &mut Rng) -> Vec<String> {
    const S: &[&str] = &["*", "lib/**", "lib/*", "team-*", "npm/pkg", "**", ""];
    (0..r.below(3)).map(|_| pick(r, S).to_string()).collect()
}

fn case(r: &mut Rng, pool: &Pool) -> Case {
    let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
    let base = Instant::now();
    let dir = tempfile::tempdir().unwrap();
    // Seconds plus a half, so `as_secs()` of a slightly longer elapsed time agrees.
    let age = |r: &mut Rng| r.below(40) * NANOS_PER_SEC + NANOS_PER_SEC / 2;

    // Token files and cache.
    let mut files = Vec::new();
    let mut cache = Vec::new();
    let cache_ttl_s = 1 + r.below(30);
    let tokens_on = r.chance(80);
    let store = up::tokens::TokenStore::with_cache_ttl(dir.path(), Duration::from_secs(cache_ttl_s));
    for t in TOKENS {
        let sha = &pool.sha[t];
        if r.chance(60) {
            let prefix = &sha[..16];
            let role = pick(r, &[URole::Read, URole::Write, URole::Admin]).clone();
            let expires_at = if r.chance(70) { now + 1000 } else { now - 1000 };
            let user = pick(r, &["ci", "dev", "ops"]).to_string();
            let hash = match r.below(4) {
                0 => sha.clone(),
                1 => pool.argon[t].clone(),
                2 => pool.argon[pick(r, TOKENS)].clone(),
                _ => "not-a-hash".to_string(),
            };
            let path = dir.path().join(format!("{prefix}.json"));
            if r.chance(10) {
                std::fs::write(&path, "{ broken").unwrap();
                files.push(TokenFile { prefix: b(prefix), info: None });
            } else {
                let info = TokenInfo { token_hash: hash.clone(), user: user.clone(), created_at: 0, expires_at,
                    last_used: None, description: None, role: role.clone() };
                std::fs::write(&path, serde_json::to_string(&info).unwrap()).unwrap();
                files.push(TokenFile { prefix: b(prefix),
                    info: Some(KInfo { token_hash: b(&hash), user: b(&user), expires_at, role: krole(&role) }) });
            }
        }
        if r.chance(30) {
            let a = age(r);
            let role = pick(r, &[URole::Read, URole::Write, URole::Admin]).clone();
            let expires_at = if r.chance(70) { now + 1000 } else { now - 1000 };
            store.seed_cache(sha, "cached", role.clone(), expires_at, base - Duration::from_nanos(a));
            cache.push(CachedToken { key: b(sha), user: b("cached"), role: krole(&role), expires_at, cached_at: MONO - a });
        }
    }
    let kstore = KStore { files, cache, cache_ttl: cache_ttl_s * NANOS_PER_SEC };

    // htpasswd.
    let htpasswd_on = r.chance(70);
    let htpasswd_text: String = USERS.iter().map(|(u, _)| format!("{u}:{}\n", pool.bcrypt[u])).collect();
    let hp = dir.path().join("htpasswd");
    std::fs::write(&hp, &htpasswd_text).unwrap();
    let kusers: Vec<(Vec<u8>, Vec<u8>)> = USERS.iter().map(|(u, _)| (b(u), b(&pool.bcrypt[u]))).collect();

    // OIDC.
    let oidc_on = r.chance(40);
    let active = r.chance(85);
    const RR: &[&str] = &["read", "write", "admin", "bogus"];
    let rules: Vec<uo::OidcRoleRule> = (0..r.below(3)).map(|_| uo::OidcRoleRule {
        pattern: pick(r, &["*", "repo:org/*", "ci-*", "user"]).to_string(),
        role: pick(r, RR).to_string(),
        namespace_scope: if r.chance(40) { Some(scope(r)) } else { None },
    }).collect();
    let mode = if r.chance(20) { up::config::ScopeEnforcement::Audit } else { up::config::ScopeEnforcement::Enforce };
    let provider = uo::OidcProvider { name: "p".into(), issuer: "i".into(), max_token_lifetime_secs: 3600,
        role_rules: rules, namespace_scope: scope(r), namespace_scope_enforcement: mode };
    let mut jwt_table = HashMap::new();
    for t in ["jwt-one", "jwt-two", "nra_alpha"] {
        if r.chance(60) {
            let sub = pick(r, &["repo:org/app", "ci-7", "user", ""]).to_string();
            let (iat, exp) = if r.chance(80) { (Some(0), Some(if r.chance(80) { 100 } else { 9999 })) } else { (None, None) };
            jwt_table.insert(t.to_string(), uo::Claims { sub: if r.chance(90) { Some(sub) } else { None }, iat, exp });
        }
    }
    let kprovider = k::OidcProvider {
        max_token_lifetime_secs: provider.max_token_lifetime_secs,
        role_rules: provider.role_rules.iter().map(|x| k::OidcRoleRule { pattern: b(&x.pattern), role: b(&x.role),
            namespace_scope: x.namespace_scope.as_ref().map(|s| s.iter().map(|p| b(p)).collect()) }).collect(),
        namespace_scope: provider.namespace_scope.iter().map(|p| b(p)).collect(),
        namespace_scope_enforcement: match mode {
            up::config::ScopeEnforcement::Enforce => k::ScopeEnforcement::Enforce,
            up::config::ScopeEnforcement::Audit => k::ScopeEnforcement::Audit,
        },
    };

    // Trusted proxies and the failure tracker.
    let proxies: Vec<(StdIp, u8)> = (0..r.below(3)).map(|_| {
        let ip = *pick(r, IPS);
        let max = if ip.is_ipv4() { 32 } else { 128 };
        (ip, pick(r, &[0u8, 8, 16, 24, 31, 32, 64, 127, 128]).min(&max).to_owned())
    }).collect();
    let proxy_str: String = proxies.iter().map(|(ip, p)| format!("{ip}/{p},")).collect();
    let max_failures = 1 + r.below(5) as u32;
    let max_lockout = 1 + r.below(900);
    let tracker = up::auth::AuthFailureTracker::new(max_failures, max_lockout);
    let mut kfail = Vec::new();
    for ip in IPS {
        if r.chance(15) {
            let n = r.below(8) as u32;
            let a = age(r);
            tracker.seed(*ip, n, base - Duration::from_nanos(a));
            kfail.push(FailureEntry { ip: kip(*ip), failures: n, last_failure: MONO - a });
        }
    }

    let cfg = up::config::Config {
        auth: up::config::AuthConfig {
            enabled: r.chance(92), anonymous_read: r.chance(30), public_web_ui: r.chance(20),
            public_metrics: r.chance(30), docker_anon_pull: r.chance(30),
            trusted_proxies: up::config::TrustedProxies::parse(&proxy_str),
        },
        server: up::config::ServerConfig { public_url: None },
    };
    let kcfg = km::Config {
        enabled: cfg.auth.enabled, anonymous_read: cfg.auth.anonymous_read, public_web_ui: cfg.auth.public_web_ui,
        public_metrics: cfg.auth.public_metrics, docker_anon_pull: cfg.auth.docker_anon_pull,
        htpasswd: if htpasswd_on { Some(kusers) } else { None },
        tokens: if tokens_on { Some(kstore) } else { None },
        oidc: if oidc_on { Some((kprovider, active)) } else { None },
        trusted_proxies: KProxies { entries: proxies.iter().map(|(ip, p)| (kip(*ip), *p)).collect() },
        tracker: KTracker { max_failures, max_lockout_secs: max_lockout },
    };
    let state = up::AppState {
        config: Arc::new(cfg),
        auth: if htpasswd_on { up::auth::HtpasswdAuth::from_file(&hp).map(Arc::new) } else { None },
        tokens: if tokens_on { Some(Arc::new(store)) } else { None },
        auth_failures: Arc::new(tracker),
        oidc: if oidc_on {
            Some(Arc::new(uo::OidcValidator { provider, active, jwt: jwt_table.clone() }))
        } else {
            None
        },
    };

    // The request.
    let path = pick(r, PATHS).to_string();
    let (kmethod, method) = *pick(r, METHODS);
    let creds = |r: &mut Rng| -> String {
        match r.below(6) {
            0 => format!("{}:{}", pick(r, &["alice", "bob", "carol"]), pick(r, &["pw1", "pw2", "nope"])),
            1 => format!("{}:{}", pick(r, &["ci", "x"]), pick(r, TOKENS)),
            2 => "no-colon".to_string(),
            3 => "alice:".to_string(),
            _ => format!("alice:{}", pick(r, &["pw1", "pw2"])),
        }
    };
    let header: Option<Vec<u8>> = match r.below(9) {
        0 => None,
        1 | 2 => Some(format!("Basic {}", STANDARD.encode(creds(r))).into_bytes()),
        3 => Some(b"Basic !!!notbase64".to_vec()),
        4 => Some(format!("Basic {}", STANDARD.encode([0xffu8, 0xfe, b':', b'a'])).into_bytes()),
        5 | 6 => Some(format!("Bearer {}", pick(r, TOKENS)).into_bytes()),
        7 => Some(b"Token abc".to_vec()),
        _ => Some(b"Basic \x80".to_vec()),
    };
    let peer = if r.chance(90) { Some(*pick(r, IPS)) } else { None };
    let xff = if r.chance(40) { Some(if r.chance(80) { format!("{}, 1.2.3.4", pick(r, IPS)) } else { "garbage".into() }) } else { None };
    let xri = if r.chance(30) { Some(if r.chance(80) { pick(r, IPS).to_string() } else { "bad".into() }) } else { None };

    let mut rb = Request::builder().method(method).uri(&path);
    if let Some(h) = &header {
        rb = rb.header("authorization", HeaderValue::from_bytes(h).unwrap());
    }
    if let Some(x) = &xff {
        rb = rb.header("x-forwarded-for", x.as_str());
    }
    if let Some(x) = &xri {
        rb = rb.header("x-real-ip", x.as_str());
    }
    let mut req = rb.body(Body::empty()).unwrap();
    if let Some(p) = peer {
        req.extensions_mut().insert(ConnectInfo(SocketAddr::new(p, 5000)));
    }

    // Oracle tables for what this request can ask about.
    let mut crypto = Crypto { sha256: vec![], argon2_ok: vec![], bcrypt_ok: vec![], base64: vec![], utf8_ok: vec![] };
    let visible = header.as_ref().map_or(false, |h| h.iter().all(|&c| c >= 0x20 && c < 0x7f));
    let header_str = header.as_ref().filter(|_| visible).map(|h| String::from_utf8(h.clone()).unwrap());
    let mut presented: Vec<String> = Vec::new();
    if let Some(h) = &header_str {
        if let Some(t) = h.strip_prefix("Bearer ") {
            presented.push(t.to_string());
        }
        if let Some(enc) = h.strip_prefix("Basic ") {
            let dec = STANDARD.decode(enc).ok();
            crypto.base64.push((b(enc), dec.clone()));
            if let Some(d) = dec {
                if let Ok(s) = String::from_utf8(d.clone()) {
                    crypto.utf8_ok.push(d);
                    if let Some((_, p)) = s.split_once(':') {
                        presented.push(p.to_string());
                        for (u, _) in USERS {
                            if bcrypt::verify(p, &pool.bcrypt[u]).unwrap_or(false) {
                                crypto.bcrypt_ok.push((b(p), b(&pool.bcrypt[u])));
                            }
                        }
                    }
                }
            }
        }
    }
    for t in &presented {
        let sha = up::tokens::seam_sha256_hex(t);
        crypto.sha256.push((b(t), b(&sha)));
        if let Some(store) = &kcfg.tokens {
            for f in &store.files {
                if let Some(i) = &f.info {
                    let h = String::from_utf8(i.token_hash.clone()).unwrap();
                    if f.prefix == b(&sha[..16]) && h.starts_with("$argon2") && argon_ok(t, &h) {
                        crypto.argon2_ok.push((b(t), i.token_hash.clone()));
                    }
                }
            }
        }
    }
    let jwt = header_str.as_ref().and_then(|h| h.strip_prefix("Bearer "))
        .map(|t| km::Jwt { token: b(t), claims: jwt_table.get(t).map(|c| k::Claims {
            sub: c.sub.as_deref().map(b), iat: c.iat, exp: c.exp }) });

    let kreq = km::Request {
        path: b(&path), method: kmethod, has_auth_header: header.is_some(),
        auth_header: if visible { header.clone() } else { None },
        peer: peer.map(kip),
        xff: xff.as_ref().and_then(|x| x.split(',').next()).and_then(|s| s.trim().parse::<StdIp>().ok()).map(kip),
        x_real_ip: xri.as_ref().and_then(|x| x.trim().parse::<StdIp>().ok()).map(kip),
        now, mono: MONO,
    };
    Case { kcfg, kfail, crypto, jwt, kreq, state, req, dir }
}

fn argon_ok(t: &str, h: &str) -> bool {
    use argon2::{password_hash::{PasswordHash, PasswordVerifier}, Argon2};
    PasswordHash::new(h).map(|p| Argon2::default().verify_password(t.as_bytes(), &p).is_ok()).unwrap_or(false)
}

/// The handler behind the middleware: report the extensions it received.
async fn handler(req: Request<Body>) -> axum::response::Response {
    use up::auth::{AuthenticatedRole, AuthenticatedUser, NamespaceAuthority};
    let a = match req.extensions().get::<NamespaceAuthority>() {
        Some(NamespaceAuthority::Unrestricted) => "U".to_string(),
        Some(NamespaceAuthority::Scoped { scopes, mode, .. }) => format!("S{:?}{:?}", scopes, mode),
        None => "none".to_string(),
    };
    let u = req.extensions().get::<AuthenticatedUser>().map(|x| x.0.clone()).unwrap_or_default();
    let role = req.extensions().get::<AuthenticatedRole>().map(|x| format!("{:?}", x.0)).unwrap_or("none".into());
    // A header too: HEAD responses lose their body.
    let v = format!("{a}|{u}|{role}");
    (StatusCode::IM_A_TEAPOT, [("x-ext", v.clone())], v).into_response()
}

/// The kernel outcome in the same shape as the upstream response.
fn render(o: &Outcome) -> String {
    match o {
        Outcome::Next { authority, user, role } => {
            let a = match authority {
                k::NamespaceAuthority::Unrestricted => "U".to_string(),
                k::NamespaceAuthority::Scoped { scopes, mode } => {
                    let s: Vec<Vec<String>> = scopes.iter()
                        .map(|x| x.iter().map(|p| String::from_utf8(p.clone()).unwrap()).collect()).collect();
                    let s: Vec<std::sync::Arc<[String]>> = s.into_iter().map(|v| v.into()).collect();
                    format!("S{:?}{:?}", std::sync::Arc::<[std::sync::Arc<[String]>]>::from(s), mode)
                }
            };
            let role = role.map(|r| format!("{:?}", urole(r))).unwrap_or("none".into());
            format!("418 {a}|{}|{role}", String::from_utf8(user.clone()).unwrap())
        }
        Outcome::Deny(d) => match d {
            Deny::AuthenticationRequired => "401 {\"error\":\"Authentication required\"}".into(),
            Deny::InvalidOrExpiredToken => "401 {\"error\":\"Invalid or expired token\"}".into(),
            Deny::BasicOrBearerRequired => "401 {\"error\":\"Basic or Bearer authentication required\"}".into(),
            Deny::BasicNotConfigured => "401 {\"error\":\"Basic auth not configured\"}".into(),
            Deny::InvalidCredentialsEncoding => "401 {\"error\":\"Invalid credentials encoding\"}".into(),
            Deny::InvalidCredentialsFormat => "401 {\"error\":\"Invalid credentials format\"}".into(),
            Deny::InvalidUsernameOrPassword => "401 {\"error\":\"Invalid username or password\"}".into(),
            Deny::WebChallenge => "401 Authentication required".into(),
            Deny::ReadOnlyToken => "403 Read-only token".into(),
            Deny::ReadOnlyOidc => "403 Read-only OIDC identity".into(),
            Deny::AdminRequired => "403 Admin role required".into(),
            Deny::NamespaceDenied => "403 namespace".into(),
            Deny::TooManyRequests(n) => format!(
                "429 {{\"error\":\"Too many failed attempts. Retry after {n} seconds.\"}}"),
            Deny::TokenStoreUnavailable => "503 Token verification unavailable".into(),
        },
    }
}

/// The kernel's writes applied to the tracker entries it was given.
fn failures_after(before: &[FailureEntry], ws: &[Write]) -> Vec<(KIp, u32, bool)> {
    let mut m: Vec<(KIp, u32, bool)> = before.iter().map(|e| (e.ip, e.failures, false)).collect();
    for w in ws {
        match w {
            Write::ClearFailures(ip) => m.retain(|e| e.0 != *ip),
            Write::PutFailures(e) => {
                m.retain(|x| x.0 != e.ip);
                m.push((e.ip, e.failures, true));
            }
            _ => {}
        }
    }
    m.sort_by_key(|e| format!("{:?}", e.0));
    m
}

#[test]
fn middleware_agrees() {
    let pool = pool();
    let rt = tokio::runtime::Builder::new_current_thread().enable_all().build().unwrap();
    let mut r = Rng(0x5EED_0F_A11);
    let mut seen: HashMap<String, usize> = HashMap::new();
    let n: usize = std::env::var("MIDDLEWARE_CASES").ok().and_then(|s| s.parse().ok()).unwrap_or(20000);
    for i in 0..n {
        let c = case(&mut r, &pool);
        let (ws, out) = km::auth_middleware(&c.kcfg, &c.kfail, &c.crypto, &c.jwt, &c.kreq);
        let want = render(&out);
        let label: String = want.split('|').next().unwrap().chars().take(60).collect();
        let state = c.state.clone();
        let app = Router::new().fallback(handler)
            .layer(axum::middleware::from_fn_with_state(state.clone(), up::auth::auth_middleware))
            .with_state(state.clone());
        let resp = rt.block_on(app.oneshot(c.req)).unwrap();
        let status = resp.status().as_u16();
        let ext = resp.headers().get("x-ext").map(|v| v.to_str().unwrap().to_string());
        let json = resp.headers().get("content-type").map_or(false, |v| v == "application/json");
        let retry = resp.headers().get("retry-after").map(|v| v.to_str().unwrap().to_string());
        let body = rt.block_on(axum::body::to_bytes(resp.into_body(), 1 << 20)).unwrap();
        let body = ext.unwrap_or_else(|| String::from_utf8_lossy(&body).into_owned());
        let mut got = format!("{status} {body}");
        let mut want = want;
        if c.kreq.method == HttpMethod::Head && status != 418 {
            // HEAD responses have no body: compare the status, whether it is
            // JSON and the Retry-After header.
            got = format!("{status} json={json} retry={retry:?}");
            let kretry = match &out {
                Outcome::Deny(Deny::TooManyRequests(n)) => Some(n.to_string()),
                _ => None,
            };
            want = format!("{} json={} retry={kretry:?}", &want[..3], want[4..].starts_with('{'));
        }
        assert_eq!(got, want, "case {i}: {:?}", c.kreq);

        // State after the request.
        let up_fail: Vec<(KIp, u32, bool)> = {
            let mut v: Vec<_> = state.auth_failures.entries_now().into_iter()
                .map(|(ip, n, t)| (kip(ip), n, t.elapsed() < Duration::from_millis(900))).collect();
            v.sort_by_key(|e| format!("{:?}", e.0));
            v
        };
        let k_fail = failures_after(&c.kfail, &ws);
        let strip = |v: &[(KIp, u32, bool)]| v.iter().map(|e| (e.0, e.1)).collect::<Vec<_>>();
        assert_eq!(strip(&up_fail), strip(&k_fail), "case {i} failures: {:?}", c.kreq);
        for (u, kk) in up_fail.iter().zip(&k_fail) {
            if kk.2 {
                assert!(u.2, "case {i}: failure time not updated");
            }
        }
        if let (Some(store), Some(kstore)) = (&state.tokens, &c.kcfg.tokens) {
            let mut kc: Vec<(String, String, KRole, u64)> = kstore.cache.iter()
                .map(|x| (String::from_utf8(x.key.clone()).unwrap(), String::from_utf8(x.user.clone()).unwrap(), x.role, x.expires_at)).collect();
            let mut pend: Vec<(String, u64)> = vec![];
            for w in &ws {
                match w {
                    Write::Token(TokenWrite::CacheInsert(x)) => {
                        let key = String::from_utf8(x.key.clone()).unwrap();
                        kc.retain(|e| e.0 != key);
                        kc.push((key, String::from_utf8(x.user.clone()).unwrap(), x.role, x.expires_at));
                    }
                    Write::Token(TokenWrite::LastUsed(p, t)) => {
                        let p = String::from_utf8(p.clone()).unwrap();
                        pend.retain(|e| e.0 != p);
                        pend.push((p, *t));
                    }
                    _ => {}
                }
            }
            kc.sort_by(|a, b| a.0.cmp(&b.0));
            pend.sort();
            let uc: Vec<_> = store.cache_entries().into_iter().map(|(k, u, r, e)| (k, u, krole(&r), e)).collect();
            assert_eq!(uc, kc, "case {i} cache: {:?}", c.kreq);
            // The wall clock may tick between the kernel's `now` and upstream's.
            let up_pend = store.pending_entries();
            assert_eq!(up_pend.len(), pend.len(), "case {i} last_used: {:?}", c.kreq);
            for (u, kk) in up_pend.iter().zip(&pend) {
                assert!(u.0 == kk.0 && u.1.abs_diff(kk.1) <= 2, "case {i} last_used {u:?} {kk:?}");
            }
        }
        let label = if label.starts_with("429") { "429".to_string() } else { label };
        *seen.entry(label).or_default() += 1;
    }
    // Every kind of response occurs.
    let kinds: Vec<_> = seen.keys().collect();
    println!("{seen:?}");
    for must in ["418 U", "418 S", "401 {\"error\":\"Authentication required", "401 {\"error\":\"Invalid or expired",
        "401 {\"error\":\"Basic or Bearer", "401 {\"error\":\"Basic auth not configured", "401 {\"error\":\"Invalid credentials encoding",
        "401 {\"error\":\"Invalid credentials format", "401 {\"error\":\"Invalid username", "401 Authentication required",
        "403 Read-only token", "403 Read-only OIDC", "403 Admin role", "429", "503"] {
        assert!(seen.keys().any(|k| k.starts_with(must)), "never saw {must}: {kinds:?}");
    }
}


/// The token files on disk, as the kernel sees them.
fn files_on_disk(dir: &std::path::Path) -> Vec<(String, Option<(String, String, u64)>)> {
    let mut v = Vec::new();
    for e in std::fs::read_dir(dir).unwrap() {
        let p = e.unwrap().path();
        let name = p.file_name().unwrap().to_str().unwrap().to_string();
        let Some(prefix) = name.strip_suffix(".json") else { continue };
        let info = std::fs::read_to_string(&p).ok().and_then(|c| serde_json::from_str::<TokenInfo>(&c).ok())
            .map(|i| (i.token_hash, i.user, i.expires_at));
        v.push((prefix.to_string(), info));
    }
    v.sort();
    v
}

fn kfiles(store: &KStore) -> Vec<(String, Option<(String, String, u64)>)> {
    let s = |x: &Vec<u8>| String::from_utf8(x.clone()).unwrap();
    let mut v: Vec<_> = store.files.iter().map(|f| (s(&f.prefix),
        f.info.as_ref().map(|i| (s(&i.token_hash), s(&i.user), i.expires_at)))).collect();
    v.sort();
    v
}

#[test]
fn revoke_agrees() {
    use nora_kernel::tokens::{revoke_all_for_user, revoke_token, TokenError as KErr};
    let pool = pool();
    let mut r = Rng(0xDEC0DE);
    let (mut ok, mut all) = (0, 0);
    for i in 0..3000 {
        let c = case(&mut r, &pool);
        let (Some(store), Some(kstore)) = (&c.state.tokens, &c.kcfg.tokens) else { continue };
        let s = |x: &Vec<u8>| String::from_utf8(x.clone()).unwrap();
        let kc = |st: &KStore| { let mut v: Vec<_> = st.cache.iter().map(|x| (s(&x.key), s(&x.user))).collect(); v.sort(); v };
        let after = if r.chance(60) {
            let prefix = match r.below(4) {
                0 => "../../etc/passwd".to_string(),
                1 => "ABCDEF0123456789".to_string(),
                _ => match kstore.files.get(r.below(kstore.files.len().max(1) as u64) as usize) {
                    Some(f) => s(&f.prefix),
                    None => up::tokens::seam_sha256_hex(pick(&mut r, TOKENS))[..16].to_string(),
                },
            };
            let want = store.revoke_token(&prefix).map_err(|e| match e {
                up::tokens::TokenError::NotFound => KErr::NotFound,
                e => panic!("{e:?}"),
            });
            let (after, got) = revoke_token(kstore, prefix.as_bytes());
            assert_eq!(got, want, "case {i} revoke {prefix}");
            ok += got.is_ok() as usize;
            after
        } else {
            let user = pick(&mut r, &["ci", "dev", "ops", "cached", "nobody"]).to_string();
            let want = store.revoke_all_for_user(&user);
            let (after, got) = revoke_all_for_user(kstore, user.as_bytes());
            assert_eq!(got, want, "case {i} revoke all {user}");
            all += (got > 0) as usize;
            after
        };
        assert_eq!(files_on_disk(c.dir.path()), kfiles(&after), "case {i} files");
        let uc: Vec<(String, String)> = store.cache_entries().into_iter().map(|(k, u, _, _)| (k, u)).collect();
        assert_eq!(uc, kc(&after), "case {i} cache");
    }
    assert!(ok > 100 && all > 100, "{ok} {all}");
}
