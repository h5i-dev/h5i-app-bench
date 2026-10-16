//! The test's side of the trusted boundary: a database backend that answers
//! upstream's SQL over the kernel's snapshot, the conversions between the two
//! sides' types, and runners that drive upstream's middlewares through axum.
//!
//! Each SQL statement is transcribed by hand below, from the statement text
//! upstream sends (WHERE, JOIN, EXISTS, scalar subqueries, NULL handling).
use std::sync::{Arc, Mutex};

use artifactkeeper_kernel as k;
use axum::body::Body;
use axum::extract::Request;
use axum::http::{HeaderName, HeaderValue, Method, StatusCode};
use axum::response::Response;
use axum::Router;
use k::tables::{Db, Query};
use sqlx::{PgRow, Value};
use tower::ServiceExt;
use uuid::Uuid;

use crate::api::middleware::auth::{self as up_auth, AuthExtension, DownloadTicketAuth, RepoVisibilityState};
use crate::api::middleware::guest_access::{guest_access_guard, GuestAccessState};
use crate::models::access_scope::AccessScope;
use crate::services::auth_service::{uid, AuthService, OVERLOADED};
use crate::services::permission_service::PermissionService;

pub fn kip(ip: std::net::IpAddr) -> k::net::IpAddr {
    match ip {
        std::net::IpAddr::V4(a) => k::net::IpAddr::V4(u32::from(a)),
        std::net::IpAddr::V6(a) => k::net::IpAddr::V6(u128::from(a)),
    }
}

pub fn stdip(ip: k::net::IpAddr) -> std::net::IpAddr {
    match ip {
        k::net::IpAddr::V4(a) => std::net::IpAddr::V4(a.into()),
        k::net::IpAddr::V6(a) => std::net::IpAddr::V6(a.into()),
    }
}

fn id(u: &Uuid) -> u64 {
    u.as_u128() as u64
}

fn s(b: &[u8]) -> String {
    String::from_utf8(b.to_vec()).expect("snapshot strings are UTF-8")
}

/// The database: answers each statement upstream issues, and records the
/// writes (ticket deletions, audit entries) in kernel form.
pub struct Backend {
    pub db: Db,
    pub writes: Mutex<Vec<k::resolve::Write>>,
}

fn bool_row(b: bool) -> Vec<PgRow> {
    vec![PgRow { cols: vec![("exists", Value::Bool(b))] }]
}

fn text(v: &Value) -> Option<String> {
    match v {
        Value::Text(t) => Some(t.clone()),
        Value::Null => None,
        _ => panic!("expected text, got {v:?}"),
    }
}

fn uuid(v: &Value) -> u64 {
    match v {
        Value::Uuid(u) => id(u),
        _ => panic!("expected uuid, got {v:?}"),
    }
}

/// Postgres `a::inet <<= b::inet` for a host address `a`: same family, and
/// the first `masklen(b)` bits agree. A NULL `a` is NULL, which is not true.
fn inet_within(a: Option<std::net::IpAddr>, b: &k::net::CidrRange) -> bool {
    let Some(a) = a else { return false };
    let (bits, x, y): (u32, u128, u128) = match (a, b.network) {
        (std::net::IpAddr::V4(a), k::net::IpAddr::V4(n)) => (32, u32::from(a) as u128, n as u128),
        (std::net::IpAddr::V6(a), k::net::IpAddr::V6(n)) => (128, u128::from(a), n),
        _ => return false,
    };
    (0..b.prefix_len as u32).all(|i| (x >> (bits - 1 - i)) & 1 == (y >> (bits - 1 - i)) & 1)
}

impl Backend {
    fn project(&self, repo: u64) -> Option<u64> {
        // (SELECT project_id FROM repositories WHERE id = $n)
        self.db.repositories.iter().find(|r| r.id == repo).and_then(|r| r.project_id)
    }

    fn groups_of(&self, user: u64) -> Vec<u64> {
        // SELECT group_id FROM user_group_members WHERE user_id = $1
        self.db.members.iter().filter(|m| m.0 == user).map(|m| m.1).collect()
    }

    /// `ip_condition_sql(p, ip)`.
    fn ip_ok(&self, p: &k::tables::Permission, ip: &Value) -> bool {
        let ip = text(ip).map(|t| t.parse::<std::net::IpAddr>().expect("bound IP parses"));
        match &p.allowed_cidrs {
            None => true,
            Some(cidrs) => cidrs.iter().any(|c| inet_within(ip, c)),
        }
    }

    fn principal(&self, p: &k::tables::Permission, user: u64) -> bool {
        let t = p.principal_type.as_slice();
        ((t == b"user" || t == b"service_account") && p.principal_id == user)
            || (t == b"group" && self.groups_of(user).contains(&p.principal_id))
    }

    fn on_repo(&self, p: &k::tables::Permission, repo: u64) -> bool {
        (p.target_type == b"repository" && p.target_id == repo)
            || (p.target_type == b"project" && self.project(repo) == Some(p.target_id))
    }

    /// `assigned_roles`: `role_assignments ra JOIN roles r ON r.id = ra.role_id`.
    fn assigned(&self, user: u64, repo: u64) -> Vec<&Vec<Vec<u8>>> {
        let mut out = Vec::new();
        for ra in &self.db.role_assignments {
            if ra.user_id == user && (ra.repository_id == Some(repo) || ra.repository_id.is_none()) {
                for r in &self.db.roles {
                    if r.id == ra.role_id {
                        out.push(&r.permissions);
                    }
                }
            }
        }
        out
    }

    fn fail(&self, q: Query) -> sqlx::Result<()> {
        if self.db.failing.contains(&q) { Err(sqlx::Error::PoolTimedOut) } else { Ok(()) }
    }

    fn user_row(u: &k::User) -> PgRow {
        PgRow { cols: vec![
            ("id", Value::Uuid(uid(u.id))),
            ("username", Value::Text(s(&u.username))),
            ("email", Value::Text(s(&u.email))),
            ("is_active", Value::Bool(u.is_active)),
            ("is_admin", Value::Bool(u.is_admin)),
            ("is_service_account", Value::Bool(u.is_service_account)),
            ("must_change_password", Value::Bool(u.must_change_password)),
        ] }
    }
}

impl sqlx::Backend for Backend {
    fn run(&self, sql: &str, binds: &[Value]) -> sqlx::Result<Vec<PgRow>> {
        if sql.contains("WITH applicable_rules") {
            // check_repository_action
            self.fail(Query::RepositoryAction)?;
            let (user, repo, action) = (uuid(&binds[0]), uuid(&binds[1]), text(&binds[2]).unwrap());
            let applicable: Vec<_> = self.db.permissions.iter()
                .filter(|p| self.principal(p, user) && self.on_repo(p, repo) && self.ip_ok(p, &binds[3]))
                .collect();
            let assigned = self.assigned(user, repo);
            let has = |v: &Vec<Vec<u8>>, a: &str| v.iter().any(|x| x == a.as_bytes());
            let allowed = assigned.iter().any(|p| has(p, "admin")) || if !applicable.is_empty() {
                applicable.iter().any(|p| has(&p.actions, &action) || has(&p.actions, "admin"))
            } else {
                assigned.iter().any(|p| has(p, &action) || has(p, "admin"))
            };
            return Ok(bool_row(allowed));
        }
        if sql.contains("WHERE p.principal_type = 'anonymous'") {
            // check_anonymous_repository_action
            self.fail(Query::AnonymousAction)?;
            let (repo, action) = (uuid(&binds[0]), text(&binds[1]).unwrap());
            let hit = self.db.permissions.iter().any(|p| {
                p.principal_type == b"anonymous" && self.on_repo(p, repo)
                    && (p.actions.iter().any(|a| *a == action.as_bytes() || a == b"admin"))
                    && self.ip_ok(p, &binds[2])
            });
            return Ok(bool_row(hit));
        }
        if sql.contains("SELECT 1 FROM permissions") && sql.contains("target_type = $1 AND target_id = $2") {
            // has_any_rules_for_target
            self.fail(Query::AnyRules)?;
            let (tt, tid) = (text(&binds[0]).unwrap(), uuid(&binds[1]));
            let hit = self.db.permissions.iter().any(|p| {
                (p.target_type == tt.as_bytes() && p.target_id == tid)
                    || (tt == "repository" && p.target_type == b"project" && self.project(tid) == Some(p.target_id))
            });
            return Ok(bool_row(hit));
        }
        if sql.contains("SELECT DISTINCT unnest(actions)") {
            // query_actions
            self.fail(Query::QueryActions)?;
            let (user, tt, tid) = (uuid(&binds[0]), text(&binds[1]).unwrap(), uuid(&binds[2]));
            let mut out: Vec<Vec<u8>> = Vec::new();
            for p in &self.db.permissions {
                let target = (p.target_type == tt.as_bytes() && p.target_id == tid)
                    || (tt == "repository" && p.target_type == b"project" && self.project(tid) == Some(p.target_id));
                if self.principal(p, user) && target && self.ip_ok(p, &binds[3]) {
                    for a in &p.actions {
                        if !out.contains(a) {
                            out.push(a.clone());
                        }
                    }
                }
            }
            return Ok(out.iter().map(|a| PgRow { cols: vec![("action", Value::Text(s(a)))] }).collect());
        }
        if sql.contains("FROM role_assignments ra") {
            // repo_visibility_middleware: rules-less private branch
            self.fail(Query::RoleGrant)?;
            let (user, repo) = (uuid(&binds[0]), uuid(&binds[1]));
            let hit = self.db.role_assignments.iter()
                .any(|ra| ra.user_id == user && (ra.repository_id == Some(repo) || ra.repository_id.is_none()));
            return Ok(bool_row(hit));
        }
        if sql.contains("FROM repositories WHERE key = $1") {
            self.fail(Query::RepoByKey)?;
            let key = text(&binds[0]).unwrap();
            return Ok(self.db.repositories.iter().filter(|r| r.key == key.as_bytes()).map(|r| PgRow { cols: vec![
                ("id", Value::Uuid(uid(r.id))),
                ("format", Value::Text("generic".into())),
                ("repo_type", Value::Text("local".into())),
                ("upstream_url", Value::Null),
                ("storage_backend", Value::Text("filesystem".into())),
                ("storage_path", Value::Text("/data".into())),
                ("visibility", Value::Text(match r.visibility {
                    Some(k::Visibility::Public) => "public",
                    Some(k::Visibility::Internal) => "internal",
                    Some(k::Visibility::Private) => "private",
                    None => "unreadable",
                }.into())),
                ("promotion_only", Value::Bool(false)),
                ("age_gate_enabled", Value::Bool(false)),
                ("age_gate_min_age_days", Value::I32(0)),
                ("age_gate_mode", Value::Text("off".into())),
                ("curation_enabled", Value::Bool(false)),
                ("curation_default_action", Value::Text("allow".into())),
                ("index_upstream_url", Value::Null),
            ] }).collect());
        }
        if sql.contains("DELETE FROM download_tickets") {
            // validate_download_ticket: WHERE ticket = $1 AND expires_at > NOW()
            self.fail(Query::Ticket)?;
            let t = text(&binds[0]).unwrap();
            let rows: Vec<PgRow> = self.db.tickets.iter().filter(|x| x.ticket == t.as_bytes() && x.live).map(|x| PgRow { cols: vec![
                ("user_id", Value::Uuid(uid(x.user_id))),
                ("purpose", Value::Text("download".into())),
                ("resource_path", x.resource_path.as_ref().map_or(Value::Null, |p| Value::Text(s(p)))),
            ] }).collect();
            if !rows.is_empty() {
                self.writes.lock().unwrap().push(k::resolve::Write::DeleteTicket(t.into_bytes()));
            }
            return Ok(rows);
        }
        if sql.contains("SELECT must_change_password FROM users WHERE id = $1 AND is_active = true") {
            self.fail(Query::MustChangePassword)?;
            let u = uuid(&binds[0]);
            return Ok(self.db.users.iter().filter(|x| x.id == u && x.is_active)
                .map(|x| PgRow { cols: vec![("must_change_password", Value::Bool(x.must_change_password))] }).collect());
        }
        if sql.contains("FROM users") && sql.contains("WHERE id = $1 AND is_active = true") {
            // try_resolve_ticket_auth's user
            self.fail(Query::TicketUser)?;
            let u = uuid(&binds[0]);
            return Ok(self.db.users.iter().filter(|x| x.id == u && x.is_active).map(Self::user_row).collect());
        }
        if sql.contains("FROM users WHERE id = $1 AND is_service_account") {
            self.fail(Query::PrincipalExists)?;
            let (u, sa) = (uuid(&binds[0]), sql.contains("is_service_account = true"));
            return Ok(bool_row(self.db.users.iter().any(|x| x.id == u && x.is_service_account == sa)));
        }
        if sql.contains("FROM groups WHERE id = $1") {
            self.fail(Query::PrincipalExists)?;
            let g = uuid(&binds[0]);
            return Ok(bool_row(self.db.groups.contains(&g)));
        }
        panic!("statement not transcribed: {sql}");
    }

    fn log(&self, kind: &str, fields: Vec<Value>) {
        assert_eq!(kind, "audit_permission_denied");
        let method = match &fields[2] {
            Value::Text(m) => method_back(m),
            _ => unreachable!(),
        };
        self.writes.lock().unwrap().push(k::resolve::Write::AuditPermissionDenied {
            user_id: uuid(&fields[0]),
            path: text(&fields[1]).unwrap().into_bytes(),
            method,
        });
    }
}

pub fn http_method(m: k::Method) -> Method {
    match m {
        k::Method::Get => Method::GET,
        k::Method::Head => Method::HEAD,
        k::Method::Post => Method::POST,
        k::Method::Put => Method::PUT,
        k::Method::Delete => Method::DELETE,
        k::Method::Patch => Method::PATCH,
        k::Method::Options => Method::OPTIONS,
        k::Method::Other => Method::TRACE,
    }
}

fn method_back(m: &str) -> k::Method {
    match m {
        "GET" => k::Method::Get,
        "HEAD" => k::Method::Head,
        "POST" => k::Method::Post,
        "PUT" => k::Method::Put,
        "DELETE" => k::Method::Delete,
        "PATCH" => k::Method::Patch,
        "OPTIONS" => k::Method::Options,
        _ => k::Method::Other,
    }
}

/// The upstream request, and the kernel's view of it read back from it (so
/// both see the same path, query and header order).
pub fn request(m: k::Method, path: &str, query: Option<&str>, headers: &[(Vec<u8>, Vec<u8>)]) -> Option<(Request, k::http::Request)> {
    let uri = match query {
        Some(q) => format!("{path}?{q}"),
        None => path.to_string(),
    };
    let mut b = Request::builder().method(http_method(m)).uri(uri);
    for (n, v) in headers {
        b = b.header(HeaderName::from_bytes(n).ok()?, HeaderValue::from_bytes(v).ok()?);
    }
    let req = b.body(Body::empty()).ok()?;
    let kreq = k::http::Request {
        method: m,
        path: req.uri().path().as_bytes().to_vec(),
        query: req.uri().query().map(|q| q.as_bytes().to_vec()),
        headers: req.headers().iter().map(|(n, v)| (n.as_str().as_bytes().to_vec(), v.as_bytes().to_vec())).collect(),
    };
    Some((req, kreq))
}

pub fn ext(e: &AuthExtension) -> k::AuthExtension {
    k::AuthExtension {
        user_id: id(&e.user_id),
        username: e.username.as_bytes().to_vec(),
        email: e.email.as_bytes().to_vec(),
        is_admin: e.is_admin,
        is_api_token: e.is_api_token,
        is_service_account: e.is_service_account,
        scopes: e.scopes.as_ref().map(|v| v.iter().map(|s| s.as_bytes().to_vec()).collect()),
        allowed_repo_ids: match &e.allowed_repo_ids {
            AccessScope::Admin => k::AccessScope::Admin,
            AccessScope::Restricted(ids) => k::AccessScope::Restricted(ids.iter().map(id).collect()),
        },
        iat_ms: e.iat_ms,
    }
}

pub fn ext_back(e: &k::AuthExtension) -> AuthExtension {
    AuthExtension {
        user_id: uid(e.user_id),
        username: s(&e.username),
        email: s(&e.email),
        is_admin: e.is_admin,
        is_api_token: e.is_api_token,
        is_service_account: e.is_service_account,
        scopes: e.scopes.as_ref().map(|v| v.iter().map(|x| s(x)).collect()),
        allowed_repo_ids: crate::services::auth_service::scope(&e.allowed_repo_ids),
        iat_ms: e.iat_ms,
    }
}

/// What the handler saw.
#[derive(Clone)]
struct Captured(Option<k::AuthExtension>, bool);

async fn capture(req: Request) -> Response {
    let opt = req.extensions().get::<Option<AuthExtension>>().cloned();
    let plain = req.extensions().get::<AuthExtension>().cloned();
    if let (Some(Some(a)), Some(b)) = (&opt, &plain) {
        assert_eq!(ext(a), ext(b), "the two extensions agree");
    }
    let auth = match (opt, plain) {
        (Some(o), _) => o,
        (None, p) => p,
    };
    let ticket = req.extensions().get::<DownloadTicketAuth>().is_some();
    let mut resp = Response::new(Body::empty());
    *resp.status_mut() = StatusCode::IM_USED;
    resp.extensions_mut().insert(Captured(auth.as_ref().map(ext), ticket));
    resp
}

/// Upstream's response, classified into the kernel's `Outcome`. Panics on a
/// response the kernel has no name for.
async fn outcome(resp: Response) -> k::middleware::Outcome {
    use k::middleware::{Deny, Outcome, Response as R};
    if let Some(Captured(auth, ticket)) = resp.extensions().get::<Captured>().cloned() {
        return Outcome::Next { auth, ticket };
    }
    let status = resp.status();
    let headers = resp.headers().clone();
    let body = axum::body::to_bytes(resp.into_body(), 1 << 20).await.unwrap();
    let body = String::from_utf8_lossy(&body).to_string();
    let challenges: Vec<String> = headers.get_all("www-authenticate").iter().map(|v| v.to_str().unwrap().to_string()).collect();
    let r = match (status.as_u16(), body.as_str()) {
        (404, "Repository not found") => R::NotFound,
        (401, "Authentication required") => {
            let basic = challenges.iter().any(|c| c.starts_with("Basic "));
            let want: Vec<&str> = if basic {
                vec!["Basic realm=\"artifact-keeper\"", "Bearer realm=\"artifact-keeper\", charset=\"UTF-8\"", "Cargo"]
            } else {
                vec!["Bearer realm=\"artifact-keeper\", charset=\"UTF-8\""]
            };
            assert_eq!(challenges, want);
            R::Unauthorized { challenge_basic: basic }
        }
        (503, "Authentication service is at capacity, retry shortly") => {
            assert_eq!(headers.get("retry-after").unwrap(), "1");
            R::ServiceUnavailable
        }
        (503, "permission service temporarily unavailable") => R::PermissionServiceUnavailable,
        (503, OVERLOADED) => {
            assert_eq!(headers.get("retry-after").unwrap(), "1");
            R::AuthServiceUnavailable
        }
        (403, "Token does not have access to this repository") => R::ForbiddenRepo,
        (403, "You do not have permission to perform this action on this repository") => R::ForbiddenPermission,
        (403, b) if b.starts_with("Cookie-authenticated state-changing requests") => R::CsrfForbidden,
        (428, _) => R::MustChangePassword,
        (403, "Admin access required") => R::AdminRequired,
        (401, "Invalid or expired token") => R::Plain401(Deny::InvalidOrExpiredToken),
        (401, "Invalid or expired API token") => R::Plain401(Deny::InvalidOrExpiredApiToken),
        (401, "Invalid Basic auth credentials") => R::Plain401(Deny::InvalidBasic),
        (401, "Invalid credentials") => R::Plain401(Deny::InvalidCredentials),
        (401, "Missing authorization header") => R::Plain401(Deny::MissingHeader),
        (401, "Invalid authorization header format") => R::Plain401(Deny::InvalidHeaderFormat),
        (401, "Invalid or expired download ticket") => R::Plain401(Deny::InvalidTicket),
        (401, b) if b.contains("GUEST_ACCESS_DISABLED") => {
            let basic = challenges.iter().any(|c| c.starts_with("Basic "));
            R::GuestUnauthorized { for_browser: !basic }
        }
        (401, _) if headers.get("x-stub").is_some() => R::OciUnauthorized,
        _ => panic!("unclassified response {status} {body:?} {headers:?}"),
    };
    Outcome::Respond(r)
}

/// A current-thread runtime shared by a test.
pub fn runtime() -> tokio::runtime::Runtime {
    tokio::runtime::Builder::new_current_thread().build().unwrap()
}

pub fn pool(db: &Db) -> (sqlx::PgPool, Arc<Backend>) {
    let backend = Arc::new(Backend { db: db.clone(), writes: Mutex::new(Vec::new()) });
    (sqlx::PgPool { backend: backend.clone() }, backend)
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Layer {
    RepoVisibility,
    Auth,
    OptionalAuth,
    Admin,
    Guest(bool),
}

/// Run one upstream middleware on `req` in front of the capturing handler,
/// inside `client_ip`'s request scope. Fresh service state (and so empty
/// caches) per call.
pub fn run(rt: &tokio::runtime::Runtime, layer: Layer, db: &Db, oracle: &k::trusted::Oracle,
           client_ip: Option<k::net::IpAddr>, req: Request) -> (Vec<k::resolve::Write>, k::middleware::Outcome) {
    let (pool, backend) = pool(db);
    let auth_service = Arc::new(AuthService::with_oracle(pool.clone(), Arc::new(oracle.clone())));
    let router = Router::new().fallback(capture);
    let router = match layer {
        Layer::RepoVisibility => {
            let state = RepoVisibilityState {
                auth_service,
                db: pool.clone(),
                repo_cache: Default::default(),
                repo_miss_cache: Default::default(),
                permission_service: Arc::new(PermissionService::new(pool.clone())),
            };
            router.layer(axum::middleware::from_fn_with_state(state, up_auth::repo_visibility_middleware))
        }
        Layer::Auth => router.layer(axum::middleware::from_fn_with_state(auth_service, up_auth::auth_middleware)),
        Layer::OptionalAuth => {
            router.layer(axum::middleware::from_fn_with_state(auth_service, up_auth::optional_auth_middleware))
        }
        Layer::Admin => router.layer(axum::middleware::from_fn_with_state(auth_service, up_auth::admin_middleware)),
        Layer::Guest(enabled) => router.layer(axum::middleware::from_fn_with_state(
            GuestAccessState { guest_access_enabled: enabled, auth_service }, guest_access_guard)),
    };
    let fut = async move {
        let resp = router.oneshot(req).await.unwrap();
        outcome(resp).await
    };
    let out = rt.block_on(crate::api::middleware::client_ip::with_client_ip_scope(client_ip.map(stdip), fut));
    let writes = backend.writes.lock().unwrap().clone();
    (writes, out)
}
