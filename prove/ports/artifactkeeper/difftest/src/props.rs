//! Falsification tests for the statements in proofs/Properties.lean. Each
//! checks the property on random inputs and counts how often its premises
//! hold, so a statement that is false, or true only because its premises
//! never hold, fails here. The spec definitions of Spec.lean are restated
//! below over Rust values.
use artifactkeeper_kernel as k;
use k::middleware::{Outcome, Response};
use k::net::{CidrRange, IpAddr};
use k::resolve::Write;
use k::tables::{Db, Permission, Query, Repository};
use k::{Method, Visibility};

use crate::gen::*;

const MIN_HITS: usize = 500;

// ---- Spec.lean, restated ----

fn project_of(db: &Db, repo: u64) -> Option<u64> {
    db.repositories.iter().find(|r| r.id == repo).and_then(|r| r.project_id)
}

fn principal_matches(db: &Db, p: &Permission, user: u64) -> bool {
    ((p.principal_type == b"user" || p.principal_type == b"service_account") && p.principal_id == user)
        || (p.principal_type == b"group" && db.members.contains(&(user, p.principal_id)))
}

fn on_repo(db: &Db, p: &Permission, repo: u64) -> bool {
    (p.target_type == b"repository" && p.target_id == repo)
        || (p.target_type == b"project" && project_of(db, repo) == Some(p.target_id))
}

/// `inCidr`: `n / 2^s = a / 2^s` with `s = width - min(prefix, width)`.
fn in_cidr(c: &CidrRange, ip: IpAddr) -> bool {
    let div = |x: u128, s: u32| if s >= 128 { 0 } else { x >> s };
    match (c.network, ip) {
        (IpAddr::V4(n), IpAddr::V4(a)) => {
            let s = 32 - (c.prefix_len as u32).min(32);
            div(n as u128, s) == div(a as u128, s)
        }
        (IpAddr::V6(n), IpAddr::V6(a)) => {
            let s = 128 - (c.prefix_len as u32).min(128);
            div(n, s) == div(a, s)
        }
        _ => false,
    }
}

fn ip_ok(p: &Permission, ip: Option<IpAddr>) -> bool {
    match (&p.allowed_cidrs, ip) {
        (None, _) => true,
        (Some(cs), Some(a)) => cs.iter().any(|c| in_cidr(c, a)),
        (Some(_), None) => false,
    }
}

fn applicable(db: &Db, ip: Option<IpAddr>, user: u64, repo: u64, p: &Permission) -> bool {
    principal_matches(db, p, user) && on_repo(db, p, repo) && ip_ok(p, ip)
}

fn carries(xs: &[Vec<u8>], a: &[u8]) -> bool {
    xs.iter().any(|x| x == a)
}

fn role_grants(db: &Db, user: u64, repo: u64, perm: &[u8]) -> bool {
    db.role_assignments.iter().any(|ra| {
        ra.user_id == user && (ra.repository_id == Some(repo) || ra.repository_id.is_none())
            && db.roles.iter().any(|r| r.id == ra.role_id && carries(&r.permissions, perm))
    })
}

fn repo_action(db: &Db, ip: Option<IpAddr>, user: u64, repo: u64, a: &[u8]) -> bool {
    let app: Vec<&Permission> = db.permissions.iter().filter(|p| applicable(db, ip, user, repo, p)).collect();
    role_grants(db, user, repo, b"admin")
        || (!app.is_empty() && app.iter().any(|p| carries(&p.actions, a) || carries(&p.actions, b"admin")))
        || (app.is_empty() && (role_grants(db, user, repo, a) || role_grants(db, user, repo, b"admin")))
}

fn anonymous_read(db: &Db, ip: Option<IpAddr>, repo: u64) -> bool {
    db.permissions.iter().any(|p| p.principal_type == b"anonymous" && on_repo(db, p, repo)
        && (carries(&p.actions, b"read") || carries(&p.actions, b"admin")) && ip_ok(p, ip))
}

fn has_grant(db: &Db, ip: Option<IpAddr>, user: u64, repo: u64) -> bool {
    db.role_assignments.iter().any(|ra| ra.user_id == user && (ra.repository_id == Some(repo) || ra.repository_id.is_none()))
        || db.permissions.iter().any(|p| applicable(db, ip, user, repo, p))
}

fn repo_of<'a>(db: &'a Db, req: &k::http::Request) -> Option<&'a Repository> {
    let key = k::paths::extract_repo_key(&req.path);
    db.repositories.iter().find(|r| r.key == key)
}

fn is_mutation(m: Method) -> bool {
    matches!(m, Method::Put | Method::Patch | Method::Delete)
}

fn write_action(m: Method) -> &'static [u8] {
    if m == Method::Delete { b"delete" } else { b"write" }
}

fn admin_scoped(s: &Option<Vec<Vec<u8>>>) -> bool {
    match s {
        None => true,
        Some(v) => carries(v, b"admin") || carries(v, b"*"),
    }
}

fn allowlisted(p: &[u8]) -> bool {
    [&b"/health"[..], b"/healthz", b"/ready", b"/readyz", b"/livez", b"/api/v1/system/config", b"/v2/token",
     b"/api/v1/auth", b"/api/v1/setup"].contains(&p)
        || p.starts_with(b"/api/v1/auth/") || p.starts_with(b"/api/v1/setup/")
}

fn no_credential(req: &k::http::Request) -> bool {
    let names: [&[u8]; 4] = [b"authorization", b"x-api-key", b"cookie", b"x-nuget-apikey"];
    let trimmed: Vec<u8> = req.path.iter().copied().skip_while(|&c| c == b'/').collect();
    req.headers.iter().all(|(n, _)| !names.contains(&n.as_slice())) && !trimmed.starts_with(b"conda/")
}

fn scope_grants(scopes: &[Vec<u8>], req: &[u8]) -> bool {
    let parent: Vec<u8> = req.iter().copied().take_while(|&c| c != b':').collect();
    carries(scopes, b"*") || carries(scopes, b"admin") || carries(scopes, req)
        || (req.contains(&b':') && !parent.is_empty() && carries(scopes, &parent))
}

// ---- Drivers ----

struct Case {
    db: Db,
    o: k::trusted::Oracle,
    ip: Option<IpAddr>,
    req: k::http::Request,
}

fn case(r: &mut Rng) -> Case {
    let db = db(r);
    let mut o = oracle(r, &db);
    let req = k::http::Request {
        method: rand_method(r),
        path: b(&path(r)),
        query: query(r).map(|q| b(&q)),
        headers: headers(r),
    };
    fill_base64(&mut o, &req.headers);
    Case { db, o, ip: client_ip(r), req }
}

/// Runs `check` on `n` cases; `check` returns whether the premises held.
fn property(seed: u64, n: usize, check: impl Fn(&Case) -> bool) {
    let mut r = Rng(seed);
    let mut hits = 0;
    for _ in 0..n {
        if check(&case(&mut r)) {
            hits += 1;
        }
    }
    println!("seed {seed}: premises held {hits} times");
    assert!(hits >= MIN_HITS, "premises held only {hits} times");
}

fn visibility(c: &Case) -> (Vec<Write>, Outcome) {
    k::middleware::repo_visibility_middleware(&c.db, &c.o, c.ip, &c.req)
}

const N: usize = 1_500_000;

#[test]
fn anonymous_never_mutates() {
    property(101, N, |c| {
        let (_, out) = visibility(c);
        let Outcome::Next { auth, ticket } = out else { return false };
        if !is_mutation(c.req.method) {
            return false;
        }
        assert!(auth.is_some() && !ticket);
        true
    });
}

#[test]
fn anonymous_needs_rule() {
    property(102, N, |c| {
        let (_, out) = visibility(c);
        let Outcome::Next { auth: None, .. } = out else { return false };
        let Some(r) = repo_of(&c.db, &c.req) else { return false };
        if r.visibility == Some(Visibility::Public) {
            return false;
        }
        assert!(anonymous_read(&c.db, c.ip, r.id));
        true
    });
}

#[test]
fn private_needs_grant() {
    property(103, N, |c| {
        let (_, out) = visibility(c);
        let Outcome::Next { auth: Some(e), .. } = out else { return false };
        let Some(r) = repo_of(&c.db, &c.req) else { return false };
        if e.is_admin || matches!(r.visibility, Some(Visibility::Public | Visibility::Internal)) {
            return false;
        }
        assert!(has_grant(&c.db, c.ip, e.user_id, r.id));
        true
    });
}

#[test]
fn mutation_needs_action() {
    property(104, N, |c| {
        let (_, out) = visibility(c);
        let Outcome::Next { auth: Some(e), .. } = out else { return false };
        let Some(r) = repo_of(&c.db, &c.req) else { return false };
        if e.is_admin || !is_mutation(c.req.method) || k::paths::is_non_mutating_format_post(&c.req.path) {
            return false;
        }
        assert!(repo_action(&c.db, c.ip, e.user_id, r.id, write_action(c.req.method)));
        true
    });
}

#[test]
fn scoped_token_confined() {
    property(105, N, |c| {
        let (_, out) = visibility(c);
        let Outcome::Next { auth: Some(e), .. } = out else { return false };
        let Some(r) = repo_of(&c.db, &c.req) else { return false };
        let k::AccessScope::Restricted(ids) = &e.allowed_repo_ids else { return false };
        if ids.contains(&r.id) {
            return false;
        }
        assert!(r.visibility == Some(Visibility::Public) && !is_mutation(c.req.method));
        true
    });
}

#[test]
fn ticket_read_only() {
    property(106, N, |c| {
        let (_, out) = visibility(c);
        let Outcome::Next { auth, ticket: true } = out else { return false };
        assert!(matches!(c.req.method, Method::Get | Method::Head));
        let e = auth.expect("a ticket names a principal");
        assert!(!e.is_admin && e.scopes == Some(vec![]));
        true
    });
}

#[test]
fn ticket_consumed_on_read() {
    property(107, N, |c| {
        let (ws, _) = visibility(c);
        let mut any = false;
        for w in &ws {
            if let Write::DeleteTicket(t) = w {
                any = true;
                assert!(matches!(c.req.method, Method::Get | Method::Head));
                assert!(c.db.tickets.iter().any(|x| x.ticket == *t && x.live));
            }
        }
        any
    });
}

#[test]
fn repo_visibility_total() {
    // Totality: no panic or overflow on any input (debug builds check
    // overflow too); every case counts.
    property(108, 100_000, |c| {
        let _ = visibility(c);
        true
    });
}

#[test]
fn check_repository_action_spec() {
    let mut r = Rng(109);
    let (mut yes, mut no) = (0, 0);
    for _ in 0..N {
        let mut db = db(&mut r);
        db.failing.retain(|q| *q != Query::RepositoryAction);
        let ip = client_ip(&mut r);
        let (user, repo) = (r.pick(&[1, 2, 3, 4, 5]), r.pick(&[100, 101, 102, 103, 104]));
        let a = b(r.pick(&ACTIONS));
        let got = k::permission::check_repository_action(&db, ip, user, repo, &a, false).expect("no failure");
        assert_eq!(got, repo_action(&db, ip, user, repo, &a), "{db:?}");
        if got { yes += 1 } else { no += 1 }
    }
    assert!(yes >= MIN_HITS && no >= MIN_HITS, "{yes} {no}");
}

#[test]
fn rule_overrides_role() {
    let mut r = Rng(110);
    let mut hits = 0;
    for _ in 0..N {
        let db = db(&mut r);
        let ip = client_ip(&mut r);
        let (user, repo) = (r.pick(&[1, 2, 3, 4, 5]), r.pick(&[100, 101, 102, 103, 104]));
        let a = b(r.pick(&ACTIONS));
        let app: Vec<&Permission> = db.permissions.iter().filter(|p| applicable(&db, ip, user, repo, p)).collect();
        if app.is_empty() || app.iter().any(|p| carries(&p.actions, &a) || carries(&p.actions, b"admin"))
            || role_grants(&db, user, repo, b"admin") {
            continue;
        }
        hits += 1;
        assert_ne!(k::permission::check_repository_action(&db, ip, user, repo, &a, false), Ok(true));
    }
    assert!(hits >= MIN_HITS, "{hits}");
}

#[test]
fn cidr_contains_spec() {
    let mut r = Rng(111);
    let (mut yes, mut no) = (0, 0);
    for _ in 0..3_000_000 {
        let network = if r.chance(50) { IpAddr::V4(r.next() as u32) } else { IpAddr::V6(((r.next() as u128) << 64) | r.next() as u128) };
        let c = CidrRange { network, prefix_len: r.below(256) as u8 };
        let near = |x: IpAddr, r: &mut Rng| match x {
            IpAddr::V4(n) => IpAddr::V4(n ^ (1u32.wrapping_shl(r.below(32) as u32))),
            IpAddr::V6(n) => IpAddr::V6(n ^ (1u128 << r.below(128))),
        };
        let ip = match r.below(4) {
            0 => network,
            1 | 2 => near(network, &mut r),
            _ => client_ip(&mut r).unwrap_or(IpAddr::V4(0)),
        };
        let got = c.contains(ip);
        assert_eq!(got, in_cidr(&c, ip), "{c:?} {ip:?}");
        if got { yes += 1 } else { no += 1 }
    }
    assert!(yes >= MIN_HITS && no >= MIN_HITS);
}

#[test]
fn admin_gate() {
    property(112, N, |c| {
        let (_, out) = k::middleware::admin_middleware(&c.db, &c.o, &c.req);
        let Outcome::Next { auth, .. } = out else { return false };
        let e = auth.expect("admin_middleware names a principal");
        assert!(e.is_admin && admin_scoped(&e.scopes));
        true
    });
}

#[test]
fn admin_denial_audited() {
    property(113, N, |c| {
        let (ws, out) = k::middleware::admin_middleware(&c.db, &c.o, &c.req);
        if out != Outcome::Respond(Response::AdminRequired) {
            return false;
        }
        assert!(matches!(ws.as_slice(), [Write::AuditPermissionDenied { path, method, .. }]
            if *path == c.req.path && *method == c.req.method));
        true
    });
}

#[test]
fn guest_blocks_anonymous() {
    property(114, N, |c| {
        let out = k::middleware::guest_access_guard(false, &c.o, &c.req);
        if !matches!(out, Outcome::Next { .. }) || !no_credential(&c.req) {
            return false;
        }
        assert!(allowlisted(&c.req.path), "{:?}", c.req);
        true
    });
}

fn create_case(r: &mut Rng) -> (Db, Option<k::AuthExtension>, k::handlers::CreatePermissionRequest) {
    let db = db(r);
    let auth = if r.chance(10) { None } else {
        Some(k::AuthExtension {
            user_id: r.pick(&USERS),
            username: b("u"),
            email: b("e"),
            is_admin: r.chance(60),
            is_api_token: false,
            is_service_account: false,
            scopes: if r.chance(60) { None } else { Some(r.subset(&SCOPES, 40).iter().map(|s| b(s)).collect()) },
            allowed_repo_ids: k::AccessScope::Admin,
            iat_ms: None,
        })
    };
    let p = k::handlers::CreatePermissionRequest {
        principal_type: b(r.pick(&["user", "group", "anonymous", "anonymous", "robot"])),
        principal_id: r.pick(&[0, 0, 1, 2, 10]),
        target_type: b(r.pick(&["repository", "project", "group"])),
        target_id: r.pick(&[100, 101, 200]),
        actions: r.subset(&["read", "read", "write", "admin"], 40).iter().map(|s| b(s)).collect(),
        conditions: None,
    };
    (db, auth, p)
}

fn no_oracle() -> k::trusted::Oracle {
    k::trusted::Oracle { jwt: vec![], api_tokens: vec![], passwords: vec![], base64: vec![], ip: vec![] }
}

#[test]
fn only_admin_creates_rules() {
    let mut r = Rng(115);
    let mut hits = 0;
    for _ in 0..N {
        let (db, auth, p) = create_case(&mut r);
        let (ws, _) = k::handlers::create_permission(&db, &no_oracle(), &auth, &p);
        if ws.is_empty() {
            continue;
        }
        hits += 1;
        assert!(auth.as_ref().is_some_and(|e| e.is_admin));
    }
    assert!(hits >= MIN_HITS, "{hits}");
}

#[test]
fn anonymous_rule_read_only() {
    let mut r = Rng(116);
    let mut hits = 0;
    for _ in 0..N {
        let (db, auth, p) = create_case(&mut r);
        let (ws, _) = k::handlers::create_permission(&db, &no_oracle(), &auth, &p);
        for w in &ws {
            if let Write::InsertPermission(row) = w {
                if row.principal_type != b"anonymous" {
                    continue;
                }
                hits += 1;
                assert_eq!(row.principal_id, 0);
                assert!(row.target_type == b"repository" || row.target_type == b"project");
                assert!(row.actions.iter().all(|a| a == b"read"));
            }
        }
    }
    assert!(hits >= MIN_HITS, "{hits}");
}

#[test]
fn scopes_grant_access_spec() {
    let mut r = Rng(117);
    let (mut yes, mut no) = (0, 0);
    const S: &[&str] = &["read", "write", "read:artifacts", "write:artifacts", "admin", "*", ":x", "write:",
                         "", "a:b:c", "a", "Admin", "x:"];
    for _ in 0..2_000_000 {
        let scopes: Vec<Vec<u8>> = (0..r.below(4)).map(|_| b(r.pick(S))).collect();
        let req = b(r.pick(S));
        let got = k::token_scope::scopes_grant_access(&scopes, &req);
        assert_eq!(got, scope_grants(&scopes, &req), "{scopes:?} {req:?}");
        if got { yes += 1 } else { no += 1 }
    }
    assert!(yes >= MIN_HITS && no >= MIN_HITS);
}
