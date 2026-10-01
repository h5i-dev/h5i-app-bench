//! Random snapshots, oracle tables and requests, over small pools chosen to
//! hit the edge cases: percent escapes, the conda/ext/api key shapes, the
//! non-mutating POST routes, every credential channel, tickets, CIDR rules,
//! project inheritance and failing queries.
use artifactkeeper_kernel as k;
use base64::Engine;
use k::net::{CidrRange, IpAddr};
use k::tables::*;

/// xorshift64*, so the tests need no dependencies.
pub struct Rng(pub u64);
impl Rng {
    pub fn next(&mut self) -> u64 {
        self.0 ^= self.0 >> 12;
        self.0 ^= self.0 << 25;
        self.0 ^= self.0 >> 27;
        self.0.wrapping_mul(0x2545F4914F6CDD1D)
    }
    pub fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
    pub fn chance(&mut self, pct: u64) -> bool {
        self.below(100) < pct
    }
    pub fn pick<T: Clone>(&mut self, xs: &[T]) -> T {
        xs[self.below(xs.len() as u64) as usize].clone()
    }
    pub fn subset<T: Clone>(&mut self, xs: &[T], pct: u64) -> Vec<T> {
        xs.iter().filter(|_| self.chance(pct)).cloned().collect()
    }
}

pub fn b(s: &str) -> Vec<u8> {
    s.as_bytes().to_vec()
}

pub const USERS: [u64; 4] = [1, 2, 3, 4];
pub const NAMES: [&str; 4] = ["alice", "bob", "carol", "dave"];
pub const GROUPS: [u64; 2] = [10, 11];
pub const REPOS: [u64; 4] = [100, 101, 102, 103];
pub const KEYS: [&str; 4] = ["r1", "r2", "t", "cargo"];
pub const ACTIONS: [&str; 5] = ["read", "write", "delete", "admin", "x"];
pub const SCOPES: [&str; 9] = ["read", "write", "read:artifacts", "write:artifacts", "admin", "*", "delete",
                               "write:users", ":x"];

pub const V4A: u32 = 0x0A00_0005; // 10.0.0.5
pub const V4B: u32 = 0xC0A8_0101; // 192.168.1.1
pub const V6A: u128 = 1; // ::1

pub fn client_ip(r: &mut Rng) -> Option<IpAddr> {
    match r.below(5) {
        0 => None,
        1 => Some(IpAddr::V4(V4A)),
        2 => Some(IpAddr::V4(V4B)),
        3 => Some(IpAddr::V6(V6A)),
        _ => Some(IpAddr::V4(0x0A00_0105)),
    }
}

pub fn cidr(r: &mut Rng) -> CidrRange {
    match r.below(6) {
        0 => CidrRange { network: IpAddr::V4(0x0A00_0000), prefix_len: 8 },
        1 => CidrRange { network: IpAddr::V4(0x0A00_0000), prefix_len: 24 },
        2 => CidrRange { network: IpAddr::V4(V4B), prefix_len: 32 },
        3 => CidrRange { network: IpAddr::V4(0), prefix_len: 0 },
        4 => CidrRange { network: IpAddr::V6(0), prefix_len: 64 },
        _ => CidrRange { network: IpAddr::V4(0x0A00_0100), prefix_len: 23 },
    }
}

pub fn user(r: &mut Rng, i: usize) -> k::User {
    k::User {
        id: USERS[i],
        username: b(NAMES[i]),
        email: b(&format!("{}@x", NAMES[i])),
        is_active: r.chance(85),
        is_admin: r.chance(25),
        is_service_account: r.chance(25),
        must_change_password: r.chance(15),
    }
}

pub fn permission(r: &mut Rng) -> Permission {
    let principal_type = r.pick(&["user", "service_account", "group", "anonymous", "other"]);
    let principal_id = match principal_type {
        "group" => r.pick(&[10, 11, 1]),
        "anonymous" => if r.chance(80) { 0 } else { 1 },
        _ => r.pick(&[1, 2, 3, 4, 10]),
    };
    let target_type = r.pick(&["repository", "repository", "project", "group", "system"]);
    let target_id = match target_type {
        "project" => r.pick(&[200, 201, 100]),
        _ => r.pick(&[100, 101, 102, 103, 200]),
    };
    let mut actions = r.subset(&ACTIONS, 35);
    if actions.is_empty() {
        actions.push(r.pick(&ACTIONS));
    }
    Permission {
        principal_type: b(principal_type),
        principal_id,
        target_type: b(target_type),
        target_id,
        actions: actions.iter().map(|a| b(a)).collect(),
        allowed_cidrs: if r.chance(30) { Some((0..1 + r.below(2)).map(|_| cidr(r)).collect()) } else { None },
    }
}

pub const QUERIES: [Query; 11] = [Query::RepoByKey, Query::RoleGrant, Query::RepositoryAction, Query::AnonymousAction,
    Query::AnyRules, Query::QueryActions, Query::PrincipalExists, Query::Ticket, Query::TicketUser,
    Query::MustChangePassword, Query::InsertPermission];

pub fn db(r: &mut Rng) -> Db {
    let users = (0..4).map(|i| user(r, i)).collect();
    let mut keys = KEYS.to_vec();
    let repositories = REPOS.iter().map(|&id| {
        let key = if keys.is_empty() || r.chance(10) { format!("k{id}") } else {
            let i = r.below(keys.len() as u64) as usize;
            keys.remove(i).to_string()
        };
        Repository {
            id,
            key: b(&key),
            visibility: match r.below(10) {
                0..=2 => Some(k::Visibility::Public),
                3..=5 => Some(k::Visibility::Internal),
                6..=8 => Some(k::Visibility::Private),
                _ => None,
            },
            project_id: match r.below(3) { 0 => None, 1 => Some(200), _ => Some(201) },
        }
    }).collect();
    let perms = (0..r.below(6)).map(|_| permission(r)).collect();
    let roles = (1..=3).map(|id| Role { id, permissions: r.subset(&ACTIONS, 30).iter().map(|a| b(a)).collect() }).collect();
    let role_assignments = (0..r.below(5)).map(|_| RoleAssignment {
        user_id: r.pick(&USERS),
        role_id: r.pick(&[1, 2, 3, 9]),
        repository_id: if r.chance(30) { None } else { Some(r.pick(&[100, 101, 102, 103, 104])) },
    }).collect();
    let tickets = ["tk1", "tk2", "tk 1"].iter().filter(|_| r.chance(70)).collect::<Vec<_>>().into_iter().map(|t| Ticket {
        ticket: b(t),
        user_id: r.pick(&[1, 2, 3, 4, 5]),
        resource_path: if r.chance(50) { None } else { Some(b(r.pick(&["/pypi/r1/x", "/maven/r2/", "/npm/t/p"]))) },
        live: r.chance(80),
    }).collect();
    let failing = QUERIES.iter().filter(|_| r.chance(4)).copied().collect();
    let members = (0..r.below(4)).map(|_| (r.pick(&USERS), r.pick(&GROUPS))).collect();
    Db {
        users,
        groups: r.subset(&GROUPS, 80),
        members,
        repositories,
        permissions: perms,
        roles,
        role_assignments,
        tickets,
        failing,
    }
}

fn scopes(r: &mut Rng) -> Vec<Vec<u8>> {
    r.subset(&SCOPES, 25).iter().map(|s| b(s)).collect()
}

fn access(r: &mut Rng) -> k::AccessScope {
    if r.chance(40) { k::AccessScope::Admin } else { k::AccessScope::Restricted(r.subset(&REPOS, 40)) }
}

fn auth_err(r: &mut Rng) -> k::trusted::AuthErr {
    r.pick(&[k::trusted::AuthErr::ServiceUnavailable, k::trusted::AuthErr::PoolTimeout,
             k::trusted::AuthErr::Other, k::trusted::AuthErr::Other])
}

/// The credential tables. `base64` and `ip` are filled per request.
pub fn oracle(r: &mut Rng, db: &Db) -> k::trusted::Oracle {
    let jwt = ["j1", "j2"].iter().filter(|_| r.chance(80)).collect::<Vec<_>>().into_iter().map(|t| (b(t), k::Claims {
        sub: r.pick(&USERS),
        username: b(r.pick(&NAMES)),
        email: b("e@x"),
        is_admin: r.chance(40),
        allowed_repo_ids: if r.chance(50) { None } else { Some(r.subset(&REPOS, 40)) },
        iat: match r.below(4) { 0 => i64::MAX / 999, 1 => i64::MIN / 999, _ => r.below(1000) as i64 },
        iat_ms: if r.chance(30) { Some(r.below(5000) as i64) } else { None },
        scopes: if r.chance(40) { None } else { Some(scopes(r)) },
    })).collect();
    let api_tokens = ["t1", "t2", "t3"].iter().filter(|_| r.chance(85)).collect::<Vec<_>>().into_iter().map(|t| (b(t), if r.chance(75) {
        Ok(k::trusted::ApiTokenValidation {
            user: db.users[r.below(4) as usize].clone(),
            scopes: scopes(r),
            allowed_repo_ids: access(r),
        })
    } else {
        Err(auth_err(r))
    })).collect();
    let passwords = [("alice", "pw"), ("bob", "j1"), ("carol", "t2"), ("dave", "bad")].iter()
        .filter(|_| r.chance(85))
        .collect::<Vec<_>>().into_iter()
        .map(|(u, p)| (b(u), b(p), if r.chance(55) { Ok(db.users[r.below(4) as usize].clone()) } else { Err(auth_err(r)) }))
        .collect();
    k::trusted::Oracle { jwt, api_tokens, passwords, base64: vec![], ip: vec![] }
}

pub fn b64(s: &[u8]) -> String {
    base64::engine::general_purpose::STANDARD.encode(s)
}

pub fn credential(r: &mut Rng) -> String {
    match r.below(15) {
        0 => "j1".into(),
        1 => "j2".into(),
        2 => "t1".into(),
        3 => "t2".into(),
        4 => "t3".into(),
        5 => "zz".into(),
        6 => "".into(),
        7 => b64(b"alice:pw"),
        8 => b64(b"bob:j1"),
        9 => b64(b"carol:t2"),
        10 => b64(b"dave:bad"),
        11 => b64(b"nocolon"),
        12 => b64(&[0xff, b':', b'x']),
        13 => "@@@".into(),
        _ => b64(b"eve:t1"),
    }
}

pub fn auth_value(r: &mut Rng) -> String {
    match r.below(12) {
        0 => "a b".into(),
        1 => "".into(),
        _ => {
            let p = r.pick(&["Bearer ", "Token ", "ApiKey ", "Basic ", "basic ", "bearer ", "", "Digest "]);
            format!("{p}{}", credential(r))
        }
    }
}

pub fn path(r: &mut Rng) -> String {
    if r.chance(12) {
        return r.pick(&["/health", "/v2/token", "/v2", "/v2/", "/v2/r1/manifests/x", "/api/v1/auth/login",
                        "/api/v1/auth", "/api/v1/setup/", "/api/v1/users/1/password/", "/api/v1/auth/me",
                        "/api/v1/admin/x", "/", "/api/v1/system/config", "/v2/tokenX"]).to_string();
    }
    let format = r.pick(&["pypi", "npm", "conda", "ext", "api", "lfs", "conan", "vscode", "nuget", "maven", "", "v2"]);
    let mut p = if r.chance(10) { format!("//{format}") } else { format!("/{format}") };
    const SEGS: &[&str] = &["r1", "r2", "t", "cargo", "helm", "%72%31", "r%31", "%ZZ", "%C3%A9", "%FF", "%",
        "%2", "objects", "batch", "v2", "users", "authenticate", "gallery", "extensionquery", "pypi", "api",
        "package", "", "simple", "tk1", "t1", "x", "k100"];
    // Keys first more often, so paths name a repository.
    if r.chance(70) {
        p.push('/');
        p.push_str(r.pick(&["r1", "r2", "t", "cargo", "%72%31", "k101"]));
    }
    for _ in 0..r.below(5) {
        p.push('/');
        p.push_str(r.pick(SEGS));
    }
    p
}

pub fn query(r: &mut Rng) -> Option<String> {
    if r.chance(55) {
        return None;
    }
    Some(r.pick(&["ticket=tk1", "ticket=tk%31", "a=b&ticket=tk2", "ticket=", "ticket", "x=1", "ticket=tk+1",
                  "ticket=%zz", "ticket=tk1&ticket=tk2", "ticket=%E9"]).to_string())
}

pub fn rand_method(r: &mut Rng) -> k::Method {
    r.pick(&[k::Method::Get, k::Method::Head, k::Method::Post, k::Method::Put, k::Method::Delete, k::Method::Patch,
             k::Method::Options, k::Method::Other, k::Method::Get, k::Method::Put, k::Method::Post])
}

fn maybe_bad(r: &mut Rng, mut v: Vec<u8>) -> Vec<u8> {
    if r.chance(4) {
        v.push(0xE9);
    }
    v
}

pub fn headers(r: &mut Rng) -> Vec<(Vec<u8>, Vec<u8>)> {
    let mut h = Vec::new();
    for _ in 0..r.below(5) {
        let (n, v) = match r.below(12) {
            0..=3 => ("authorization", auth_value(r)),
            4 => ("x-api-key", credential(r)),
            5 => ("cookie", r.pick(&["ak_access_token=j1; x=y", " x=1 ; ak_access_token=t1", "foo=bar",
                                     "ak_access_token=", "ak_access_token=j2"]).to_string()),
            6 => ("x-nuget-apikey", r.pick(&["t1", "", "zz"]).to_string()),
            7 => ("sec-fetch-mode", "navigate".to_string()),
            8 => ("sec-fetch-site", r.pick(&["same-origin", " None ", "cross-site", "SAME-ORIGIN"]).to_string()),
            9 => ("accept", r.pick(&["text/html", "application/json", "TEXT/HTML;q=0.9", "*/*"]).to_string()),
            10 => ("x-requested-with", "XMLHttpRequest".to_string()),
            _ => ("x-forwarded-for", xff(r)),
        };
        let v = maybe_bad(r, b(&v));
        h.push((b(n), v));
    }
    h
}

pub fn xff(r: &mut Rng) -> String {
    let n = 1 + r.below(3);
    (0..n).map(|_| r.pick(&["10.0.0.5", " 192.168.1.1 ", "[::1]:80", "10.0.1.7:443", "junk", "", "::1",
                            "10.0.0.9", "8.8.8.8"]).to_string()).collect::<Vec<_>>().join(",")
}

/// Every suffix of every authorization value and every session cookie
/// token, decoded with the real base64: the strings the kernel may decode.
pub fn fill_base64(o: &mut k::trusted::Oracle, headers: &[(Vec<u8>, Vec<u8>)]) {
    let mut cands: Vec<Vec<u8>> = Vec::new();
    for (n, v) in headers {
        if n == b"authorization" {
            for i in 0..=v.len() {
                cands.push(v[i..].to_vec());
            }
        }
        if n == b"cookie" {
            for piece in v.split(|&c| c == b';') {
                let s = String::from_utf8_lossy(piece).trim().to_string();
                if let Some(t) = s.strip_prefix("ak_access_token=") {
                    cands.push(b(t));
                }
            }
        }
    }
    for c in cands {
        if o.base64.iter().any(|(k, _)| *k == c) {
            continue;
        }
        if let Ok(d) = base64::engine::general_purpose::STANDARD.decode(&c) {
            o.base64.push((c, Some(d)));
        }
    }
}

/// Every substring of every `x-forwarded-for` value that parses as an
/// address, parsed by std.
pub fn fill_ip(o: &mut k::trusted::Oracle, strings: &[Vec<u8>]) {
    for v in strings {
        for i in 0..v.len() {
            for j in i + 1..=v.len() {
                let s = &v[i..j];
                if o.ip.iter().any(|(k, _)| k == s) {
                    continue;
                }
                if let Some(ip) = std::str::from_utf8(s).ok().and_then(|t| t.parse::<std::net::IpAddr>().ok()) {
                    o.ip.push((s.to_vec(), crate::shell::kip(ip)));
                }
            }
        }
    }
}
