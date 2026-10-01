//! The kernel against artifact-keeper's own code on the same random inputs.
use std::collections::BTreeMap;

use artifactkeeper_kernel as k;
use axum::http::HeaderMap;
use k::middleware::Outcome;

use crate::api::middleware::auth as up;
use crate::gen::*;
use crate::shell::*;

fn hist(h: &mut BTreeMap<String, usize>, key: String) {
    *h.entry(key).or_insert(0) += 1;
}

fn key(o: &Outcome) -> String {
    match o {
        Outcome::Next { auth, ticket } => format!("Next(auth={}, ticket={ticket})", auth.is_some()),
        Outcome::Respond(r) => format!("{r:?}"),
    }
}

type Kernel = fn(&k::tables::Db, &k::trusted::Oracle, Option<k::net::IpAddr>, &k::http::Request)
    -> (Vec<k::resolve::Write>, Outcome);

/// Runs `layer` upstream and `kernel` on `n` random requests; every name in
/// `must` must occur among the outcomes.
fn middleware_agrees(layer: Layer, seed: u64, n: usize, kernel: Kernel, must: &[&str]) {
    let rt = runtime();
    let mut r = Rng(seed);
    let mut h = BTreeMap::new();
    let mut skipped = 0;
    let mut writes = 0;
    for _ in 0..n {
        let db = db(&mut r);
        let mut o = oracle(&mut r, &db);
        let ip = client_ip(&mut r);
        let m = rand_method(&mut r);
        let p = path(&mut r);
        let q = query(&mut r);
        let hs = headers(&mut r);
        let Some((req, kreq)) = request(m, &p, q.as_deref(), &hs) else {
            skipped += 1;
            continue;
        };
        fill_base64(&mut o, &kreq.headers);
        let want = run(&rt, layer, &db, &o, ip, req);
        let got = kernel(&db, &o, ip, &kreq);
        assert_eq!(got, want, "{layer:?}\n{kreq:?}\n{db:?}\n{o:?}\n{ip:?}");
        writes += !want.0.is_empty() as usize;
        hist(&mut h, key(&want.1));
    }
    println!("{layer:?}: {h:#?}\nskipped {skipped}, with writes {writes}");
    assert!(skipped < n / 20, "{skipped} requests did not build");
    for name in must {
        assert!(h.get(*name).copied().unwrap_or(0) >= 20, "{name} is rare or missing: {h:#?}");
    }
}

#[test]
fn repo_visibility_middleware_agrees() {
    middleware_agrees(Layer::RepoVisibility, 1, 200_000, k::middleware::repo_visibility_middleware, &[
        "NotFound", "Unauthorized { challenge_basic: true }", "ServiceUnavailable", "PermissionServiceUnavailable",
        "ForbiddenRepo", "ForbiddenPermission", "Next(auth=true, ticket=false)", "Next(auth=true, ticket=true)",
        "Next(auth=false, ticket=false)",
    ]);
}

#[test]
fn auth_middleware_agrees() {
    middleware_agrees(Layer::Auth, 2, 100_000, |db, o, _, req| k::middleware::auth_middleware(db, o, req), &[
        "CsrfForbidden", "MustChangePassword", "ServiceUnavailable", "AuthServiceUnavailable",
        "Plain401(InvalidOrExpiredToken)", "Plain401(InvalidOrExpiredApiToken)", "Plain401(InvalidBasic)",
        "Plain401(InvalidCredentials)", "Plain401(MissingHeader)", "Plain401(InvalidHeaderFormat)",
        "Plain401(InvalidTicket)", "Next(auth=true, ticket=false)", "Next(auth=true, ticket=true)",
    ]);
}

#[test]
fn optional_auth_middleware_agrees() {
    middleware_agrees(Layer::OptionalAuth, 3, 100_000, |db, o, _, req| k::middleware::optional_auth_middleware(db, o, req), &[
        "CsrfForbidden", "ServiceUnavailable", "Unauthorized { challenge_basic: true }",
        "Unauthorized { challenge_basic: false }", "Next(auth=true, ticket=false)", "Next(auth=true, ticket=true)",
        "Next(auth=false, ticket=false)",
    ]);
}

#[test]
fn admin_middleware_agrees() {
    middleware_agrees(Layer::Admin, 4, 100_000, |db, o, _, req| k::middleware::admin_middleware(db, o, req), &[
        "CsrfForbidden", "ServiceUnavailable", "AdminRequired", "MustChangePassword", "Plain401(InvalidBasic)",
        "Plain401(InvalidOrExpiredToken)", "Plain401(InvalidOrExpiredApiToken)", "Plain401(InvalidCredentials)",
        "Plain401(MissingHeader)", "Plain401(InvalidHeaderFormat)", "Next(auth=true, ticket=false)",
    ]);
}

#[test]
fn guest_access_guard_agrees() {
    for (enabled, seed) in [(false, 5), (true, 6)] {
        middleware_agrees(Layer::Guest(enabled), seed, 60_000,
            if enabled {
                |_: &k::tables::Db, o: &k::trusted::Oracle, _: Option<k::net::IpAddr>, req: &k::http::Request| {
                    (vec![], k::middleware::guest_access_guard(true, o, req))
                }
            } else {
                |_: &k::tables::Db, o: &k::trusted::Oracle, _: Option<k::net::IpAddr>, req: &k::http::Request| {
                    (vec![], k::middleware::guest_access_guard(false, o, req))
                }
            },
            if enabled { &["Next(auth=false, ticket=false)"] } else { &[
                "Next(auth=false, ticket=false)", "ServiceUnavailable", "OciUnauthorized",
                "GuestUnauthorized { for_browser: true }", "GuestUnauthorized { for_browser: false }",
            ] });
    }
}

/// Paths built from segments that hit every branch of the path
/// classifiers: format prefixes, keys, escapes, and the fixed route tails.
fn raw_path(r: &mut Rng) -> String {
    const FIRST: &[&str] = &["conda", "ext", "api", "lfs", "conan", "vscode", "pypi", "nuget", "npm", "", "x"];
    const SEG: &[&str] = &["t", "tk", "r1", "cargo", "helm", "objects", "batch", "v2", "users", "authenticate",
        "gallery", "extensionquery", "pypi", "api", "package", "", "", "%72%31", "%ZZ", "%C3%A9", "%FF", "%2F",
        "auth", "me", "password", "logout", "x", "+", "é", "%"];
    const SHAPES: &[&str] = &["nuget/r1/api/v2/package", "nuget//api/v2/package", "lfs/r1/objects/batch",
        "conan/r1/v2/users/authenticate", "vscode/r1/gallery/extensionquery", "pypi/r1/pypi", "conda/t/tk/r1",
        "conda/t/upload", "api/cargo/r1", "ext/wasm/r1"];
    let mut p = "/".repeat(r.below(3) as usize);
    let n = if r.chance(40) {
        p.push_str(r.pick(SHAPES));
        r.below(3)
    } else {
        p.push_str(r.pick(FIRST));
        r.below(6)
    };
    for _ in 0..n {
        p.push('/');
        p.push_str(r.pick(SEG));
    }
    p
}

#[test]
fn path_classifiers_agree() {
    let mut r = Rng(7);
    let mut hits = [0usize; 6];
    for _ in 0..2_000_000 {
        let p = raw_path(&mut r);
        let kp = b(&p);
        let key = k::paths::extract_repo_key(&kp);
        assert_eq!(key, up::extract_repo_key(&p).as_bytes(), "{p:?}");
        hits[0] += !key.is_empty() as usize;
        let t = k::paths::extract_conda_url_token(&kp);
        assert_eq!(t, up::extract_conda_url_token(&p).map(b), "{p:?}");
        hits[1] += t.is_some() as usize;
        let n = k::paths::is_nuget_push_path(&kp);
        assert_eq!(n, up::probe::is_nuget_push_path(&p), "{p:?}");
        hits[2] += n as usize;
        let n = k::paths::is_non_mutating_format_post(&kp);
        assert_eq!(n, up::probe::is_non_mutating_format_post(&p), "{p:?}");
        hits[3] += n as usize;
        let n = k::paths::is_anonymous_readable_format_post(&kp);
        assert_eq!(n, up::probe::is_anonymous_readable_format_post(&p), "{p:?}");
        hits[4] += n as usize;
        let n = k::paths::path_exempt_from_password_change(&kp);
        assert_eq!(n, up::probe::path_exempt_from_password_change(&p), "{p:?}");
        hits[5] += n as usize;
        assert_eq!(k::paths::is_oci_v2_path(&kp), crate::api::middleware::oci_errors::is_oci_v2_path(&p));
    }
    println!("{hits:?}");
    assert!(hits.iter().all(|&h| h >= 100), "{hits:?}");
}

#[test]
fn percent_decode_agrees() {
    let mut r = Rng(8);
    const A: &[&str] = &["%", "4", "1", "C3", "A9", "FF", "a", "Z", "%E2%82", "%AC", "%F0%9F%98", "%80", "%ED%A0%80",
        "%C0%AF", "%f4%90%80%80", "é"];
    let (mut some, mut none) = (0, 0);
    for _ in 0..2_000_000 {
        let s: String = (0..r.below(6)).map(|_| r.pick(A)).collect();
        let got = k::paths::percent_decode_path_segment(&b(&s));
        assert_eq!(got, up::probe::percent_decode_path_segment(&s).map(|x| x.into_bytes()), "{s:?}");
        if got.is_some() { some += 1 } else { none += 1 }
    }
    assert!(some > 1000 && none > 1000);
}

#[test]
fn utf8_agrees() {
    let mut r = Rng(9);
    const A: &[u8] = &[0x41, 0x7F, 0x80, 0xBF, 0xC1, 0xC2, 0xDF, 0xE0, 0xA0, 0x9F, 0xED, 0xEF, 0xF0, 0x90, 0x8F,
                       0xF4, 0xF5, 0xFF];
    for _ in 0..3_000_000 {
        let s: Vec<u8> = (0..r.below(7)).map(|_| r.pick(A)).collect();
        assert_eq!(k::strs::is_utf8(&s), std::str::from_utf8(&s).is_ok(), "{s:?}");
    }
}

#[test]
fn ticket_query_agrees() {
    let mut r = Rng(10);
    const A: &[&str] = &["ticket", "=", "&", "tk", "%", "4", "1", "%31", "%zz", "+", "a", "x=1", "é", "%E9", "%"];
    let mut some = 0;
    for _ in 0..1_000_000 {
        let q: Option<String> = if r.chance(5) { None } else { Some((0..r.below(7)).map(|_| r.pick(A)).collect()) };
        let got = k::paths::extract_ticket_from_query(&q.as_deref().map(b));
        assert_eq!(got, up::extract_ticket_from_query(q.as_deref()).map(|s| s.into_bytes()), "{q:?}");
        some += got.is_some() as usize;
    }
    assert!(some > 1000);
}

fn scope_list(r: &mut Rng) -> Vec<String> {
    const S: &[&str] = &["read", "write", "read:artifacts", "write:artifacts", "admin", "*", "delete", "write:users",
        ":x", "write:", "", "trigger:sync", "promote:artifacts", "read:users", "Admin"];
    (0..r.below(4)).map(|_| r.pick(S).to_string()).collect()
}

#[test]
fn scopes_agree() {
    use crate::services::token_service as ts;
    let mut r = Rng(11);
    let mut granted = 0;
    for _ in 0..1_000_000 {
        let scopes = scope_list(&mut r);
        let ks: Vec<Vec<u8>> = scopes.iter().map(|s| b(s)).collect();
        let req = scope_list(&mut r).pop().unwrap_or_default();
        let g = k::token_scope::scopes_grant_access(&ks, &b(&req));
        assert_eq!(g, ts::scopes_grant_access(&scopes, &req), "{scopes:?} {req:?}");
        granted += g as usize;
        assert_eq!(k::token_scope::validate_scopes_pure(&ks).is_ok(), ts::validate_scopes_pure(&scopes).is_ok());
        let admin = r.chance(50);
        let got = k::token_scope::enforce_admin_only_scopes(&ks, admin);
        let want = ts::enforce_admin_only_scopes(&scopes, admin);
        assert_eq!(got.is_ok(), want.is_ok());
        if let (Err(s), Err(msg)) = (got, want) {
            assert!(msg.starts_with(&format!("Scope '{}'", String::from_utf8(s).unwrap())), "{msg}");
        }
    }
    assert!(granted > 1000);
}

fn random_ext(r: &mut Rng) -> k::AuthExtension {
    k::AuthExtension {
        user_id: r.pick(&USERS),
        username: b("u"),
        email: b("e"),
        is_admin: r.chance(50),
        is_api_token: r.chance(50),
        is_service_account: r.chance(20),
        scopes: if r.chance(30) { None } else { Some(scope_list(r).iter().map(|s| b(s)).collect()) },
        allowed_repo_ids: if r.chance(40) { k::AccessScope::Admin } else { k::AccessScope::Restricted(r.subset(&REPOS, 40)) },
        iat_ms: None,
    }
}

#[test]
fn auth_extension_agrees() {
    let mut r = Rng(12);
    for _ in 0..500_000 {
        let e = random_ext(&mut r);
        let u = ext_back(&e);
        let s = scope_list(&mut r).pop().unwrap_or_default();
        assert_eq!(e.has_scope(&b(&s)), u.has_scope(&s));
        assert_eq!(e.require_scope(&b(&s)).is_ok(), u.require_scope(&s).is_ok());
        let repo = r.pick(&REPOS);
        assert_eq!(e.can_access_repo(repo), u.can_access_repo(crate::services::auth_service::uid(repo)));
        let req = scope_list(&mut r);
        let kreq: Vec<Vec<u8>> = req.iter().map(|s| b(s)).collect();
        assert_eq!(e.enforce_mint_ceiling(&kreq).is_ok(), u.enforce_mint_ceiling(&req).is_ok());
        let rr = r.chance(50);
        let got = e.mint_repo_ceiling(rr);
        let want = u.mint_repo_ceiling(rr).map(|o| o.map(|v| v.iter().map(|x| x.as_u128() as u64).collect::<Vec<_>>()));
        assert_eq!(got.ok(), want.ok());
        let target = r.pick(&USERS);
        assert_eq!(e.require_self_or_admin(target).is_ok(),
                   u.require_self_or_admin(crate::services::auth_service::uid(target), "no").is_ok());
        assert_eq!(e.require_admin().is_ok(), u.require_admin().is_ok());
        assert_eq!(e.duplicate().with_scope_gated_admin(), ext(&up::probe::with_scope_gated_admin(u.clone())));
        // Format-handler helpers.
        let auth = if r.chance(20) { None } else { Some(e.clone()) };
        let uauth = auth.as_ref().map(ext_back);
        let got = k::handlers::require_auth_basic_scope(&auth, &b(&s));
        let want = up::require_auth_basic_scope(uauth.clone(), "realm", &s);
        match (&got, &want) {
            (Ok(a), Ok(b)) => assert_eq!(*a, ext(b)),
            (Err(k::handlers::GateError::Unauthorized), Err(resp)) => assert_eq!(resp.status(), 401),
            (Err(k::handlers::GateError::MissingScope), Err(resp)) => assert_eq!(resp.status(), 403),
            _ => panic!("require_auth_basic_scope: {got:?}"),
        }
        let got = k::handlers::require_scope_response(&auth, &b(&s));
        let want = up::require_scope_response(uauth.as_ref(), &s);
        assert_eq!(got.is_ok(), want.is_ok());
    }
}

#[test]
fn from_claims_agrees() {
    let mut r = Rng(13);
    let rt = runtime();
    for _ in 0..200_000 {
        let db = db(&mut r);
        let o = oracle(&mut r, &db);
        let svc = crate::services::auth_service::AuthService::with_oracle(pool(&db).0, std::sync::Arc::new(o.clone()));
        for (t, c) in &o.jwt {
            let claims = rt.block_on(svc.validate_access_token_async(std::str::from_utf8(t).unwrap())).unwrap();
            assert_eq!(k::token_scope::from_claims(c), ext(&up::AuthExtension::from(claims)));
        }
        for (_, _, u) in &o.passwords {
            if let Ok(u) = u {
                assert_eq!(k::token_scope::from_user(u), ext(&up::AuthExtension::from(crate::services::auth_service::user(u))));
            }
        }
    }
}

#[test]
fn header_predicates_agree() {
    let mut r = Rng(14);
    let mut csrf = 0;
    for _ in 0..300_000 {
        let m = rand_method(&mut r);
        let hs = headers(&mut r);
        let Some((req, kreq)) = request(m, "/x", None, &hs) else { continue };
        let h: &HeaderMap = req.headers();
        let v = k::http::violates_csrf_contract(m, &kreq.headers);
        assert_eq!(v, up::probe::violates_csrf_contract(&http_method(m), h), "{kreq:?}");
        csrf += v as usize;
        assert_eq!(k::http::is_browser_request(&kreq.headers), up::is_browser_request(h));
        assert_eq!(k::http::has_header_credential(&kreq.headers), up::probe::has_header_credential(h));
        assert_eq!(k::http::request_carries_credentials(&kreq.headers), up::request_carries_credentials(h));
        assert_eq!(k::http::declares_same_origin(&kreq.headers), up::probe::declares_same_origin(h));
        let mut o = k::trusted::Oracle { jwt: vec![], api_tokens: vec![], passwords: vec![], base64: vec![], ip: vec![] };
        fill_base64(&mut o, &kreq.headers);
        assert_eq!(k::resolve::extract_bearer_credentials(&o, &kreq.headers),
                   up::extract_bearer_credentials(h).map(|(a, c)| (b(&a), b(&c))));
        if let Some(v) = kreq.headers.iter().find(|x| x.0 == b"authorization").map(|x| x.1.clone()) {
            if let Ok(s) = std::str::from_utf8(&v) {
                for i in 0..=s.len() {
                    if s.is_char_boundary(i) {
                        assert_eq!(k::resolve::decode_basic_credentials(&o, &v[i..]),
                                   up::probe::decode_basic_credentials(&s[i..]).map(|(a, c)| (b(&a), b(&c))));
                    }
                }
            }
        }
    }
    assert!(csrf > 100, "{csrf}");
}

#[test]
fn visibility_token_agrees() {
    let mut r = Rng(15);
    let mut h = BTreeMap::new();
    for _ in 0..300_000 {
        let Some((req, kreq)) = request(rand_method(&mut r), &path(&mut r), None, &headers(&mut r)) else { continue };
        let got = k::http::extract_visibility_token(&kreq);
        let want = up::probe::visibility_token(&req);
        let conv = match got.clone() {
            k::http::ExtractedToken::Bearer(t) => (0, Some(t)),
            k::http::ExtractedToken::ApiKey(t) => (1, Some(t)),
            k::http::ExtractedToken::Basic(t) => (2, Some(t)),
            k::http::ExtractedToken::None => (3, None),
            k::http::ExtractedToken::Invalid => (4, None),
        };
        assert_eq!(conv, (want.0, want.1.map(|s| s.into_bytes())), "{kreq:?}");
        hist(&mut h, format!("{}", want.0));
    }
    assert_eq!(h.len(), 5, "{h:?}");
}

fn cidr_string(r: &mut Rng) -> String {
    let a = r.pick(&["10.0.0.0", "10.0.0.5", "192.168.1.1", "::1", "fe80::", "::", "1.2.3", "x", "", "0.0.0.0"]);
    let p = r.pick(&["8", "+8", "033", "32", "33", "128", "129", "", "-1", "256", "0", "24", "+", "1a"]);
    if r.chance(5) { a.to_string() } else { format!("{a}/{p}") }
}

fn random_ip(r: &mut Rng) -> std::net::IpAddr {
    r.pick(&["10.0.0.5", "10.0.1.5", "192.168.1.1", "8.8.8.8", "::1", "fe80::1", "::", "0.0.0.0", "10.255.0.0"])
        .parse().unwrap()
}

#[test]
fn cidr_agrees() {
    use crate::api::middleware::rate_limit::CidrRange;
    let mut r = Rng(16);
    let mut ok = 0;
    for _ in 0..300_000 {
        let s = cidr_string(&mut r);
        let mut o = k::trusted::Oracle { jwt: vec![], api_tokens: vec![], passwords: vec![], base64: vec![], ip: vec![] };
        fill_ip(&mut o, &[b(&s)]);
        let got = k::net::CidrRange::parse(&o, &b(&s));
        let want = CidrRange::parse(&s);
        assert_eq!(got.is_ok(), want.is_ok(), "{s:?}");
        if let (Ok(g), Ok(w)) = (got, want) {
            ok += 1;
            for _ in 0..4 {
                let ip = random_ip(&mut r);
                assert_eq!(g.contains(kip(ip)), w.contains(ip), "{s:?} {ip}");
            }
        }
        // `PermissionConditions::validate` over lists of these.
        let list: Option<Vec<String>> = if r.chance(20) { None } else { Some((0..r.below(3)).map(|_| cidr_string(&mut r)).collect()) };
        let mut o = k::trusted::Oracle { jwt: vec![], api_tokens: vec![], passwords: vec![], base64: vec![], ip: vec![] };
        let kl = list.as_ref().map(|l| l.iter().map(|s| b(s)).collect::<Vec<_>>());
        fill_ip(&mut o, kl.as_deref().unwrap_or(&[]));
        let cond = crate::services::permission_service::PermissionConditions { allowed_cidrs: list.clone() };
        assert_eq!(k::permission::validate_conditions(&o, &kl).is_ok(), cond.validate().is_ok(), "{list:?}");
    }
    assert!(ok > 10_000);
}

#[test]
fn client_ip_agrees() {
    use crate::api::middleware::rate_limit::{resolve_client_ip_addr, CidrRange};
    let mut r = Rng(17);
    let mut h = BTreeMap::new();
    for _ in 0..300_000 {
        let proxies: Vec<String> = (0..r.below(3)).map(|_| r.pick(&["10.0.0.0/8", "::1/128", "192.168.1.0/24", "0.0.0.0/0"]).to_string()).collect();
        let up_proxies: Vec<CidrRange> = proxies.iter().map(|p| CidrRange::parse(p).unwrap()).collect();
        let mut o = k::trusted::Oracle { jwt: vec![], api_tokens: vec![], passwords: vec![], base64: vec![], ip: vec![] };
        let kp: Vec<Vec<u8>> = proxies.iter().map(|p| b(p)).collect();
        fill_ip(&mut o, &kp);
        let k_proxies: Vec<k::net::CidrRange> = kp.iter().map(|p| k::net::CidrRange::parse(&o, p).unwrap()).collect();
        let mut hs = Vec::new();
        for _ in 0..r.below(4) {
            let v = if r.chance(5) { let mut v = b(&xff(&mut r)); v.push(0xE9); v } else { b(&xff(&mut r)) };
            hs.push((b(if r.chance(90) { "x-forwarded-for" } else { "x-other" }), v));
        }
        let Some((req, kreq)) = request(k::Method::Get, "/", None, &hs) else { continue };
        let xs: Vec<Vec<u8>> = kreq.headers.iter().map(|x| x.1.clone()).collect();
        fill_ip(&mut o, &xs);
        let peer = if r.chance(15) { None } else { Some(random_ip(&mut r)) };
        let got = k::net::resolve_client_ip_addr(&o, &kreq.headers, peer.map(kip), &k_proxies);
        let want = resolve_client_ip_addr(req.headers(), peer, &up_proxies);
        assert_eq!(got, want.map(kip), "{kreq:?} {peer:?} {proxies:?}");
        hist(&mut h, format!("{}", match (got, peer) {
            (None, _) => "none",
            (Some(g), Some(p)) if g == kip(p) => "peer",
            _ => "forwarded",
        }));
    }
    assert!(h.values().all(|&v| v > 1000) && h.len() == 3, "{h:?}");
}

fn scoped<F: std::future::Future>(rt: &tokio::runtime::Runtime, ip: Option<k::net::IpAddr>, f: F) -> F::Output {
    rt.block_on(crate::api::middleware::client_ip::with_client_ip_scope(ip.map(stdip), f))
}

#[test]
fn permission_service_agrees() {
    use crate::services::auth_service::uid;
    use crate::services::permission_service::PermissionService;
    let rt = runtime();
    let mut r = Rng(18);
    let mut h = BTreeMap::new();
    for _ in 0..200_000 {
        let db = db(&mut r);
        let ip = client_ip(&mut r);
        let svc = PermissionService::new(pool(&db).0);
        let user = r.pick(&[1, 2, 3, 4, 5]);
        let repo = r.pick(&[100, 101, 102, 103, 104]);
        let action = r.pick(&ACTIONS);
        let tt = r.pick(&["repository", "project", "group"]);
        let tid = r.pick(&[100, 101, 200, 201]);
        let admin = r.chance(10);
        let conv = |x: crate::error::Result<bool>| x.map_err(|_| k::AppError::Database);

        let got = k::permission::check_repository_action(&db, ip, user, repo, b(action).as_slice(), admin);
        assert_eq!(got, conv(scoped(&rt, ip, svc.check_repository_action(uid(user), uid(repo), action, admin))), "{db:?}");
        hist(&mut h, format!("repo_action {got:?}"));

        let got = k::permission::check_anonymous_repository_action(&db, ip, repo, b(action).as_slice());
        assert_eq!(got, conv(scoped(&rt, ip, svc.check_anonymous_repository_action(uid(repo), action))), "{db:?}");
        hist(&mut h, format!("anonymous {got:?}"));

        let got = k::permission::check_permission(&db, ip, user, b(tt).as_slice(), tid, b(action).as_slice(), admin);
        assert_eq!(got, conv(scoped(&rt, ip, svc.check_permission(uid(user), tt, uid(tid), action, admin))), "{db:?}");
        hist(&mut h, format!("permission {got:?}"));

        let got = k::permission::has_any_rules_for_target(&db, b(tt).as_slice(), tid);
        assert_eq!(got, conv(scoped(&rt, ip, svc.has_any_rules_for_target(tt, uid(tid)))), "{db:?}");
        hist(&mut h, format!("any_rules {got:?}"));

        let pt = r.pick(&["user", "service_account", "group", "anonymous", "robot"]);
        let pid = r.pick(&[0, 1, 2, 3, 4, 10, 11, 12]);
        let got = k::permission::validate_principal(&db, b(pt).as_slice(), pid);
        let want = scoped(&rt, ip, svc.validate_principal(pt, uid(pid))).map_err(|e| match e {
            crate::error::AppError::Validation(_) => k::AppError::Validation,
            crate::error::AppError::Database(_) => k::AppError::Database,
            e => panic!("{e:?}"),
        });
        assert_eq!(got, want, "{pt} {pid} {db:?}");
        hist(&mut h, format!("principal {got:?}"));
    }
    println!("{h:#?}");
    assert_eq!(h.len(), 15, "{h:#?}");
}

/// `create_permission` up to its INSERT, transcribed (it takes axum state):
/// the copied gates in upstream's order, then the INSERT's unique key.
fn upstream_create(rt: &tokio::runtime::Runtime, db: &k::tables::Db, auth: Option<up::AuthExtension>,
                   p: crate::api::handlers::permissions::CreatePermissionRequest) -> Result<(), k::AppError> {
    use crate::api::handlers::permissions::probe;
    use crate::error::AppError as E;
    use crate::services::permission_service::PermissionService;
    let conv = |e: E| match e {
        E::Authentication(_) => k::AppError::Authentication,
        E::Authorization(_) => k::AppError::Authorization,
        E::Validation(_) => k::AppError::Validation,
        E::Database(_) => k::AppError::Database,
        e => panic!("{e:?}"),
    };
    let auth = probe::require_auth(auth).map_err(conv)?;
    auth.require_scope("write").map_err(conv)?;
    auth.require_admin().map_err(conv)?;
    let svc = PermissionService::new(pool(db).0);
    rt.block_on(svc.validate_principal(&p.principal_type, p.principal_id)).map_err(conv)?;
    if let Some(conditions) = &p.conditions {
        conditions.validate().map_err(conv)?;
    }
    probe::validate_anonymous_rule(&p).map_err(conv)?;
    if db.failing.contains(&k::tables::Query::InsertPermission) {
        return Err(k::AppError::Database);
    }
    // UNIQUE(principal_type, principal_id, target_type, target_id)
    if db.permissions.iter().any(|x| x.principal_type == p.principal_type.as_bytes()
        && x.principal_id == p.principal_id.as_u128() as u64 && x.target_type == p.target_type.as_bytes()
        && x.target_id == p.target_id.as_u128() as u64) {
        return Err(k::AppError::Conflict);
    }
    Ok(())
}

#[test]
fn create_permission_agrees() {
    use crate::services::auth_service::uid;
    let rt = runtime();
    let mut r = Rng(19);
    let mut h = BTreeMap::new();
    for _ in 0..200_000 {
        let db = db(&mut r);
        let auth = if r.chance(10) { None } else { Some(random_ext(&mut r)) };
        let actions: Vec<String> = r.subset(&ACTIONS, 30).iter().map(|s| s.to_string()).collect();
        let cidrs: Option<Option<Vec<String>>> = match r.below(4) {
            0 => None,
            1 => Some(None),
            _ => Some(Some((0..r.below(3)).map(|_| cidr_string(&mut r)).collect())),
        };
        let p = k::handlers::CreatePermissionRequest {
            principal_type: b(r.pick(&["user", "service_account", "group", "anonymous", "robot"])),
            principal_id: r.pick(&[0, 1, 2, 10, 11]),
            target_type: b(r.pick(&["repository", "project", "group"])),
            target_id: r.pick(&[100, 101, 200]),
            actions: actions.iter().map(|s| b(s)).collect(),
            conditions: cidrs.clone().map(|c| k::handlers::Conditions {
                allowed_cidrs: c.map(|l| l.iter().map(|s| b(s)).collect()),
            }),
        };
        let mut o = k::trusted::Oracle { jwt: vec![], api_tokens: vec![], passwords: vec![], base64: vec![], ip: vec![] };
        if let Some(Some(l)) = &cidrs {
            fill_ip(&mut o, &l.iter().map(|s| b(s)).collect::<Vec<_>>());
        }
        let (writes, got) = k::handlers::create_permission(&db, &o, &auth, &p);
        let up_p = crate::api::handlers::permissions::CreatePermissionRequest {
            principal_type: String::from_utf8(p.principal_type.clone()).unwrap(),
            principal_id: uid(p.principal_id),
            target_type: String::from_utf8(p.target_type.clone()).unwrap(),
            target_id: uid(p.target_id),
            actions: actions.clone(),
            conditions: cidrs.clone().map(|c| crate::services::permission_service::PermissionConditions { allowed_cidrs: c }),
        };
        let want = upstream_create(&rt, &db, auth.as_ref().map(ext_back), up_p);
        assert_eq!(got, want, "{p:?} {auth:?}");
        assert_eq!(writes.len(), got.is_ok() as usize);
        if let Some(k::resolve::Write::InsertPermission(row)) = writes.first() {
            assert_eq!((&row.principal_type, row.principal_id, &row.target_type, row.target_id, &row.actions),
                       (&p.principal_type, p.principal_id, &p.target_type, p.target_id, &p.actions));
            // One stored range per listed CIDR.
            assert_eq!(row.allowed_cidrs.as_ref().map(|v| v.len()),
                       cidrs.clone().flatten().map(|l| l.len()));
        }
        hist(&mut h, format!("{got:?}"));
    }
    println!("{h:#?}");
    assert_eq!(h.len(), 6, "{h:#?}");
}
