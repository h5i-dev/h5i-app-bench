//! The registry's shell: PostgreSQL, JSON and authentication. It makes no
//! decisions of its own; the kernel decides.

use axum::extract::State;
use axum::http::{HeaderMap, HeaderValue, StatusCode};
use axum::response::Response;
use axum::routing::post;
use axum::{Json, Router};
use cratesio_kernel as k;
use i5h::{Kernel, TenantId};
use i5h_http::{error_body, reply, Actor, Api, AuthError, Authenticator, HmacAuth, I5h};
use i5h_json::Value as Out;
use i5h_pg::{delete, key, load, load_where, upsert, DbError, Engine, ReplyCodec, Store, Tx};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};

/// Marker type the framework's traits hang off.
pub struct Cratesio;

impl Kernel for Cratesio {
    type Principal = k::Principal;
    type Snapshot = k::Snapshot;
    type Command = k::Command;
    type WriteSet = Vec<k::Write>;
    type Reply = k::Reply;
    type Error = k::Error;

    fn tenant(actor: &k::Principal) -> TenantId {
        TenantId(actor.registry)
    }

    fn transition(actor: &k::Principal, snap: &k::Snapshot, cmd: &k::Command) -> Result<(Vec<k::Write>, k::Reply), k::Error> {
        k::transition(actor, snap, cmd)
    }

    fn apply(snap: &k::Snapshot, ws: &Vec<k::Write>) -> k::Snapshot {
        k::apply(snap, ws)
    }
}

// One table per row type, from the kernel's `schema!`.
cratesio_kernel::cratesio_tables!(Cratesio);

pub struct CratesStore;

/// Delete every row of `T` that belongs to crate `krate`.
async fn delete_of<T, F>(tx: &Tx<'_>, t: TenantId, krate: u64, key_of: F) -> Result<(), DbError>
where
    T: i5h_pg::Table<Cratesio>,
    F: Fn(&T) -> Result<Vec<i5h_pg::Value>, DbError>,
{
    for row in load_where::<Cratesio, T>(tx, t, "krate", key::<Cratesio, _>(&krate)?).await? {
        delete::<Cratesio, T>(tx, t, &key_of(&row)?).await?;
    }
    Ok(())
}

impl Store<Cratesio> for CratesStore {
    fn ddl() -> Vec<String> {
        schema_ddl()
    }

    fn tables() -> Vec<&'static str> {
        schema_tables()
    }

    async fn load(tx: &Tx<'_>, t: TenantId) -> Result<k::Snapshot, DbError> {
        Ok(k::Snapshot {
            counter: load::<Cratesio, k::Counter>(tx, t).await?.pop().unwrap_or_default(),
            users: load::<Cratesio, _>(tx, t).await?,
            sessions: load::<Cratesio, _>(tx, t).await?,
            tokens: load::<Cratesio, _>(tx, t).await?,
            crates: load::<Cratesio, _>(tx, t).await?,
            versions: load::<Cratesio, _>(tx, t).await?,
            owners: load::<Cratesio, _>(tx, t).await?,
            invites: load::<Cratesio, _>(tx, t).await?,
            deps: load::<Cratesio, _>(tx, t).await?,
        })
    }

    async fn write(tx: &Tx<'_>, t: TenantId, ws: &Vec<k::Write>) -> Result<(), DbError> {
        type C = Cratesio;
        for w in ws {
            match w {
                k::Write::PutUser(x) => upsert::<C, _>(tx, t, x).await?,
                k::Write::PutSession(x) => upsert::<C, _>(tx, t, x).await?,
                k::Write::PutToken(x) => upsert::<C, _>(tx, t, x).await?,
                k::Write::PutCrate(x) => upsert::<C, _>(tx, t, x).await?,
                k::Write::PutVersion(x) => upsert::<C, _>(tx, t, x).await?,
                k::Write::PutOwner(x) => upsert::<C, _>(tx, t, x).await?,
                k::Write::DelOwner(o) => {
                    let pk = [key::<C, _>(&o.krate)?, key::<C, _>(&o.owner)?, key::<C, _>(&o.team)?];
                    delete::<C, k::Owner>(tx, t, &pk).await?
                }
                k::Write::PutInvite(x) => upsert::<C, _>(tx, t, x).await?,
                k::Write::DelInvite(krate, user) => {
                    delete::<C, k::Invite>(tx, t, &[key::<C, _>(krate)?, key::<C, _>(user)?]).await?
                }
                k::Write::PutDep(x) => upsert::<C, _>(tx, t, x).await?,
                k::Write::DelCrate(krate) => {
                    delete::<C, k::Krate>(tx, t, &[key::<C, _>(krate)?]).await?;
                    delete_of::<k::Version, _>(tx, t, *krate, |v| Ok(vec![key::<C, _>(&v.krate)?, key::<C, _>(&v.num)?]))
                        .await?;
                    delete_of::<k::Owner, _>(tx, t, *krate, |o| {
                        Ok(vec![key::<C, _>(&o.krate)?, key::<C, _>(&o.owner)?, key::<C, _>(&o.team)?])
                    })
                    .await?;
                    delete_of::<k::Invite, _>(tx, t, *krate, |i| Ok(vec![key::<C, _>(&i.krate)?, key::<C, _>(&i.user)?]))
                        .await?;
                    delete_of::<k::Dep, _>(tx, t, *krate, |d| {
                        Ok(vec![key::<C, _>(&d.krate)?, key::<C, _>(&d.num)?, key::<C, _>(&d.on)?])
                    })
                    .await?;
                }
                k::Write::SetCounter(c) => upsert::<C, _>(tx, t, c).await?,
            }
        }
        Ok(())
    }
}

/* ---------- JSON ---------- */

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct ScopesJson {
    /// Omitted: a legacy token with no scopes, as in crates.io.
    endpoint_scopes: Option<Vec<String>>,
    #[serde(rename = "crate")]
    krate: Option<u64>,
    #[serde(default)]
    expires: u64,
}

/// The JSON a client sends, e.g. `{"cmd":"publish","crate":10,"vers":1,"deps":[]}`.
#[derive(Deserialize)]
#[serde(tag = "cmd", rename_all = "snake_case", deny_unknown_fields)]
enum CommandJson {
    VerifyEmail,
    RevokeToken { id: u64 },
    Publish { #[serde(rename = "crate")] krate: u64, vers: u64, #[serde(default)] deps: Vec<u64> },
    Yank { #[serde(rename = "crate")] krate: u64, vers: u64 },
    Unyank { #[serde(rename = "crate")] krate: u64, vers: u64 },
    InviteOwner { #[serde(rename = "crate")] krate: u64, user: u64 },
    AddTeam { #[serde(rename = "crate")] krate: u64, team: u64 },
    RemoveOwner { #[serde(rename = "crate")] krate: u64, owner: u64, #[serde(default)] team: bool },
    AcceptInvite { #[serde(rename = "crate")] krate: u64 },
    DeclineInvite { #[serde(rename = "crate")] krate: u64 },
    DeleteCrate { #[serde(rename = "crate")] krate: u64 },
    Lock { user: u64, #[serde(default)] until: u64 },
    Unlock { user: u64 },
    SetAdmin { user: u64, admin: bool },
}

/// The download counts the kernel is told about. crates.io keeps them in a
/// separate table fed by its CDN logs; here the operator supplies them.
pub type Downloads = Arc<HashMap<u64, u64>>;

fn command(c: CommandJson, downloads: &HashMap<u64, u64>) -> k::Command {
    use k::Command as K;
    match c {
        CommandJson::VerifyEmail => K::VerifyEmail,
        CommandJson::RevokeToken { id } => K::RevokeToken { id },
        CommandJson::Publish { krate, vers, deps } => K::Publish { krate, num: vers, deps },
        CommandJson::Yank { krate, vers } => K::Yank { krate, num: vers, yanked: true },
        CommandJson::Unyank { krate, vers } => K::Yank { krate, num: vers, yanked: false },
        CommandJson::InviteOwner { krate, user } => K::InviteOwner { krate, user },
        CommandJson::AddTeam { krate, team } => K::AddTeam { krate, team },
        CommandJson::RemoveOwner { krate, owner, team } => K::RemoveOwner { krate, owner, team },
        CommandJson::AcceptInvite { krate } => K::HandleInvite { krate, accept: true },
        CommandJson::DeclineInvite { krate } => K::HandleInvite { krate, accept: false },
        CommandJson::DeleteCrate { krate } => {
            K::DeleteCrate { krate, downloads: downloads.get(&krate).copied().unwrap_or(0) }
        }
        CommandJson::Lock { user, until } => K::Lock { user, until },
        CommandJson::Unlock { user } => K::Unlock { user },
        CommandJson::SetAdmin { user, admin } => K::SetAdmin { user, admin },
    }
}

fn scopes(s: ScopesJson) -> Result<k::NewToken, String> {
    let mut t = k::NewToken {
        legacy: s.endpoint_scopes.is_none(),
        publish_new: false,
        publish_update: false,
        yank: false,
        change_owners: false,
        krate: s.krate,
        expires: s.expires,
    };
    for e in s.endpoint_scopes.unwrap_or_default() {
        match e.as_str() {
            "publish-new" => t.publish_new = true,
            "publish-update" => t.publish_update = true,
            "yank" => t.yank = true,
            "change-owners" => t.change_owners = true,
            _ => return Err(format!("invalid endpoint scope `{e}`")),
        }
    }
    Ok(t)
}

impl Api<Cratesio> for CratesStore {
    fn decode_command(body: serde_json::Value) -> Result<k::Command, String> {
        // `/rpc` has no download counts; `delete_crate` goes through `/crates/delete`.
        serde_json::from_value::<CommandJson>(body).map(|c| command(c, &HashMap::new())).map_err(|e| e.to_string())
    }

    fn encode_reply(r: &k::Reply) -> Out {
        match r {
            k::Reply::Done => Out::obj([("ok", true.into())]),
            k::Reply::SignedIn { user, session } => Out::obj([("user", (*user).into()), ("session", (*session).into())]),
            k::Reply::TokenCreated(id) => Out::obj([("token", (*id).into())]),
            k::Reply::AlreadyInvited => Out::obj([("ok", true.into()), ("already_invited", true.into())]),
        }
    }

    fn encode_error(e: &k::Error) -> (StatusCode, Out) {
        use k::Error as E;
        let (status, code) = match e {
            E::Unauthenticated => (StatusCode::FORBIDDEN, "authentication failed"),
            E::AccountLocked => (StatusCode::FORBIDDEN, "account locked"),
            E::TokenNotAllowed => (StatusCode::FORBIDDEN, "this action can only be performed on the crates.io website"),
            E::ScopeMismatch => {
                (StatusCode::FORBIDDEN, "this token does not have the required permissions to perform this action")
            }
            E::NotOwner => (StatusCode::FORBIDDEN, "only owners have permission to do this"),
            E::TeamMember => (StatusCode::FORBIDDEN, "team members don't have permission to do this"),
            E::NotFound => (StatusCode::NOT_FOUND, "not found"),
            E::AlreadyUploaded => (StatusCode::BAD_REQUEST, "crate version is already uploaded"),
            E::AlreadyOwner => (StatusCode::BAD_REQUEST, "already an owner"),
            E::EmailNotVerified => (StatusCode::BAD_REQUEST, "a verified email address is required"),
            E::InviteExpired => (StatusCode::GONE, "the invitation has expired"),
            E::LastUserOwner => (StatusCode::BAD_REQUEST, "cannot remove all individual owners of a crate"),
            E::NotTeamMember => (StatusCode::FORBIDDEN, "only members of a team can add it as an owner"),
            E::TooManyDeps => (StatusCode::BAD_REQUEST, "too many dependencies"),
            E::UnknownDep => (StatusCode::BAD_REQUEST, "no known crate for a dependency"),
            E::MultipleOwners => {
                (StatusCode::UNPROCESSABLE_ENTITY, "only crates with a single owner can be deleted after 72 hours")
            }
            E::TooManyDownloads => (StatusCode::UNPROCESSABLE_ENTITY, "too many downloads to delete after 72 hours"),
            E::HasReverseDeps => (StatusCode::UNPROCESSABLE_ENTITY, "only crates without reverse dependencies can be deleted"),
            E::NotOperator => (StatusCode::FORBIDDEN, "operator only"),
            E::Overflow => (StatusCode::INTERNAL_SERVER_ERROR, "overflow"),
        };
        (status, error_body(code))
    }
}

/// Stored replies for idempotent retries.
#[derive(Serialize, Deserialize)]
enum StoredReply {
    Done,
    SignedIn(u64, u64),
    TokenCreated(u64),
    AlreadyInvited,
}

impl ReplyCodec<Cratesio> for CratesStore {
    fn fingerprint(cmd: &k::Command) -> Vec<u8> {
        format!("{cmd:?}").into_bytes()
    }

    fn scope(actor: &k::Principal) -> String {
        format!("u{}", actor.user)
    }

    fn encode(r: &k::Reply) -> Vec<u8> {
        let stored = match r {
            k::Reply::Done => StoredReply::Done,
            k::Reply::SignedIn { user, session } => StoredReply::SignedIn(*user, *session),
            k::Reply::TokenCreated(id) => StoredReply::TokenCreated(*id),
            k::Reply::AlreadyInvited => StoredReply::AlreadyInvited,
        };
        serde_json::to_vec(&stored).expect("stored replies serialize")
    }

    fn decode(b: &[u8]) -> Result<k::Reply, String> {
        Ok(match serde_json::from_slice(b).map_err(|e| e.to_string())? {
            StoredReply::Done => k::Reply::Done,
            StoredReply::SignedIn(user, session) => k::Reply::SignedIn { user, session },
            StoredReply::TokenCreated(id) => k::Reply::TokenCreated(id),
            StoredReply::AlreadyInvited => k::Reply::AlreadyInvited,
        })
    }
}

/* ---------- authentication ---------- */

fn principal(user: u64, via: k::Via) -> k::Principal {
    k::Principal { registry: 0, user, via, now: 0, teams: Vec::new() }
}

/// Four kinds of signed credentials, each with its own key so one cannot
/// stand in for another. The signed pair is (id, user): a session id, an
/// API token id, or 0.
pub struct CratesAuth {
    session: HmacAuth<Cratesio>,
    token: HmacAuth<Cratesio>,
    github: HmacAuth<Cratesio>,
    operator: HmacAuth<Cratesio>,
    /// user -> GitHub teams. Stands in for GitHub's team membership API,
    /// whose answer the kernel trusts.
    teams: HashMap<u64, Vec<u64>>,
    /// The registry (tenant) this server runs; crates.io is a single one.
    registry: u64,
}

impl CratesAuth {
    pub fn new(secret: &str, registry: u64, teams: HashMap<u64, Vec<u64>>) -> Self {
        CratesAuth {
            session: HmacAuth::new(format!("{secret}/session"), |sid, user| principal(user, k::Via::Cookie(sid))),
            token: HmacAuth::new(format!("{secret}/token"), |tid, user| principal(user, k::Via::Token(tid))),
            github: HmacAuth::new(format!("{secret}/github"), |_, user| principal(user, k::Via::GitHub)),
            operator: HmacAuth::new(format!("{secret}/operator"), |_, user| principal(user, k::Via::Operator)),
            teams,
            registry,
        }
    }

    /// The session cookie for session `sid` of `user`.
    pub fn session_cookie(&self, sid: u64, user: u64) -> String {
        self.session.issue(sid, user, 30 * 86_400)
    }

    /// The secret of API token `tid`.
    pub fn api_token(&self, tid: u64, user: u64) -> String {
        self.token.issue(tid, user, 365 * 86_400)
    }

    /// What the OAuth callback hands over once GitHub has vouched for `user`.
    pub fn github_login(&self, user: u64) -> String {
        self.github.issue(0, user, 600)
    }

    pub fn operator(&self) -> String {
        self.operator.issue(0, 0, 3600)
    }
}

/// Parse `I5H_TEAMS`, e.g. `2:7,8;3:7` (user 2 is in teams 7 and 8).
pub fn parse_teams(spec: &str) -> Result<HashMap<u64, Vec<u64>>, String> {
    let mut out = HashMap::new();
    for entry in spec.split(';').filter(|e| !e.is_empty()) {
        let (user, teams) = entry.split_once(':').ok_or("expected user:team,team")?;
        let user = user.trim().parse::<u64>().map_err(|e| e.to_string())?;
        let teams = teams.split(',').filter(|t| !t.is_empty()).map(|t| t.trim().parse::<u64>()).collect::<Result<Vec<_>, _>>();
        out.insert(user, teams.map_err(|e| e.to_string())?);
    }
    Ok(out)
}

fn bearer(v: &HeaderValue) -> Result<HeaderMap, AuthError> {
    let s = v.to_str().map_err(|_| AuthError("bad header".into()))?;
    let mut h = HeaderMap::new();
    let value = HeaderValue::from_str(&format!("Bearer {}", s.trim())).map_err(|_| AuthError("bad header".into()))?;
    h.insert("authorization", value);
    Ok(h)
}

fn cookie_session(headers: &HeaderMap) -> Option<&str> {
    let cookies = headers.get("cookie")?.to_str().ok()?;
    cookies.split(';').find_map(|c| c.trim().strip_prefix("session="))
}

impl Authenticator<Cratesio> for CratesAuth {
    fn authenticate(&self, headers: &HeaderMap) -> Result<k::Principal, AuthError> {
        let mut p = if let Some(s) = cookie_session(headers) {
            self.session.authenticate(&bearer(&HeaderValue::from_str(s).map_err(|_| AuthError("bad cookie".into()))?)?)?
        } else if let Some(v) = headers.get("x-github-login") {
            self.github.authenticate(&bearer(v)?)?
        } else if let Some(v) = headers.get("x-operator") {
            self.operator.authenticate(&bearer(v)?)?
        } else {
            // Cargo sends the API token in `Authorization`, with or without `Bearer`.
            let v = headers.get("authorization").ok_or_else(|| AuthError("this action requires authentication".into()))?;
            let raw = v.to_str().map_err(|_| AuthError("bad header".into()))?;
            let raw = raw.strip_prefix("Bearer ").unwrap_or(raw);
            self.token.authenticate(&bearer(&HeaderValue::from_str(raw).map_err(|_| AuthError("bad header".into()))?)?)?
        };
        p.registry = self.registry;
        p.now = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0);
        p.teams = self.teams.get(&p.user).cloned().unwrap_or_default();
        Ok(p)
    }
}

/* ---------- routes ---------- */

#[derive(Clone)]
pub struct AppState {
    pub app: I5h<Cratesio, CratesStore>,
    pub auth: Arc<CratesAuth>,
    pub downloads: Downloads,
}

impl axum::extract::FromRef<AppState> for i5h_http::Auth<Cratesio> {
    fn from_ref(s: &AppState) -> Self {
        i5h_http::Auth(s.auth.clone())
    }
}

async fn run(state: &AppState, actor: &Actor<Cratesio>, cmd: k::Command) -> Result<k::Reply, Response> {
    match state.app.engine().execute(&actor.0, &cmd).await {
        Ok(Ok(r)) => Ok(r),
        Ok(Err(e)) => {
            let (status, body) = CratesStore::encode_error(&e);
            Err(reply(status, body))
        }
        Err(e) => {
            tracing::error!(error = %e, "request failed");
            Err(reply(StatusCode::SERVICE_UNAVAILABLE, error_body("unavailable")))
        }
    }
}

/// The end of the OAuth flow: sign in and set the session cookie.
async fn authorize(State(state): State<AppState>, actor: Actor<Cratesio>) -> Response {
    match run(&state, &actor, k::Command::Authorize).await {
        Ok(k::Reply::SignedIn { user, session }) => {
            let cookie = state.auth.session_cookie(session, user);
            let mut res = reply(StatusCode::OK, Out::obj([("user", user.into())]));
            let value = HeaderValue::from_str(&format!("session={cookie}; HttpOnly; SameSite=Lax; Path=/"));
            res.headers_mut().insert("set-cookie", value.expect("cookies are ascii"));
            res
        }
        Ok(r) => reply(StatusCode::OK, CratesStore::encode_reply(&r)),
        Err(res) => res,
    }
}

/// Create an API token and return its secret, once.
async fn new_token(State(state): State<AppState>, actor: Actor<Cratesio>, Json(body): Json<serde_json::Value>) -> Response {
    let scopes = match serde_json::from_value::<ScopesJson>(body).map_err(|e| e.to_string()).and_then(scopes) {
        Ok(s) => s,
        Err(m) => return reply(StatusCode::BAD_REQUEST, error_body(&m)),
    };
    let user = actor.0.user;
    match run(&state, &actor, k::Command::CreateToken { scopes }).await {
        Ok(k::Reply::TokenCreated(id)) => {
            let secret = state.auth.api_token(id, user);
            reply(StatusCode::OK, Out::obj([("id", id.into()), ("token", Out::str(&secret))]))
        }
        Ok(r) => reply(StatusCode::OK, CratesStore::encode_reply(&r)),
        Err(res) => res,
    }
}

#[derive(Deserialize)]
struct DeleteJson {
    #[serde(rename = "crate")]
    krate: u64,
}

/// Delete a crate. The download count comes from the operator's table.
async fn delete_crate(State(state): State<AppState>, actor: Actor<Cratesio>, Json(body): Json<DeleteJson>) -> Response {
    let downloads = state.downloads.get(&body.krate).copied().unwrap_or(0);
    match run(&state, &actor, k::Command::DeleteCrate { krate: body.krate, downloads }).await {
        Ok(r) => reply(StatusCode::OK, CratesStore::encode_reply(&r)),
        Err(res) => res,
    }
}

async fn rpc(State(state): State<AppState>, actor: Actor<Cratesio>, headers: HeaderMap, Json(body): Json<serde_json::Value>) -> Response {
    match CratesStore::decode_command(body) {
        Ok(k::Command::DeleteCrate { .. }) => reply(StatusCode::BAD_REQUEST, error_body("use /crates/delete")),
        Ok(cmd) => state.app.respond(&actor, cmd, &headers).await,
        Err(m) => reply(StatusCode::BAD_REQUEST, error_body(&m)),
    }
}

pub fn router(engine: Arc<Engine<Cratesio, CratesStore>>, auth: Arc<CratesAuth>, downloads: Downloads) -> Router {
    let app = I5h::new(engine, SharedAuth(auth.clone()));
    let state = AppState { app, auth, downloads };
    Router::new()
        .route("/session/authorize", post(authorize))
        .route("/tokens", post(new_token))
        .route("/crates/delete", post(delete_crate))
        .route("/rpc", post(rpc))
        .with_state(state)
}

/// Lets the engine handle and the routes share one authenticator.
struct SharedAuth(Arc<CratesAuth>);

impl Authenticator<Cratesio> for SharedAuth {
    fn authenticate(&self, headers: &HeaderMap) -> Result<k::Principal, AuthError> {
        self.0.authenticate(headers)
    }
}
