//! Shell of the example app. Nothing here decides permissions.

use axum::http::StatusCode;
use docs_kernel as k;
use i5h::{Kernel, TenantId};
use i5h_pg::{ddl, delete, key, load, table, upsert, DbError, PgField, ReplyCodec, Store, Table, Value};
use i5h_pg::tokio_postgres::Transaction;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value as Json};

pub struct DocsApp;

impl Kernel for DocsApp {
    type Principal = k::Principal;
    type Snapshot = k::Snapshot;
    type Command = k::Command;
    type WriteSet = Vec<k::Write>;
    type Reply = k::Reply;
    type Error = k::Error;

    fn tenant(actor: &k::Principal) -> TenantId {
        TenantId(actor.org)
    }

    fn transition(actor: &k::Principal, snap: &k::Snapshot, cmd: &k::Command) -> Result<(Vec<k::Write>, k::Reply), k::Error> {
        k::transition(actor, snap, cmd)
    }

    fn apply(snap: &k::Snapshot, ws: &Vec<k::Write>) -> k::Snapshot {
        k::apply(snap, ws)
    }
}

pub fn principal(org: u64, user: u64) -> k::Principal {
    k::Principal { org, user }
}

macro_rules! enum_field {
    ($t:ty { $($v:ident = $n:literal),* }) => {
        impl PgField<DocsApp> for $t {
            const KIND: i5h_pg::Kind = i5h_pg::Kind::Int;
            fn to_value(&self) -> Result<Value, DbError> {
                Ok(Value::Int(match self { $(<$t>::$v => $n),* }))
            }
            fn from_value(v: &Value) -> Result<Self, DbError> {
                match v {
                    $(Value::Int($n) => Ok(<$t>::$v),)*
                    _ => Err(DbError::Decode(format!("bad {}: {v:?}", stringify!($t)))),
                }
            }
        }
    };
}
enum_field!(k::Role { Viewer = 0, Editor = 1, Owner = 2 });
enum_field!(k::Status { Draft = 0, InReview = 1, Approved = 2, Published = 3 });

table!(DocsApp, k::Counter => "counters" { key: [], cols: [next_id] });
table!(DocsApp, k::Project => "projects" { key: [id], cols: [name] });
table!(DocsApp, k::Member => "members" { key: [project, user], cols: [role] });
table!(DocsApp, k::Document => "documents" {
    key: [id],
    cols: [project, author, title, body, status, approver, version],
});

pub struct DocsStore;

impl Store<DocsApp> for DocsStore {
    fn ddl() -> Vec<String> {
        vec![
            ddl::<DocsApp, k::Counter>(),
            ddl::<DocsApp, k::Project>(),
            ddl::<DocsApp, k::Member>(),
            ddl::<DocsApp, k::Document>(),
        ]
    }

    fn tables() -> Vec<&'static str> {
        vec![
            <k::Counter as Table<DocsApp>>::NAME,
            <k::Project as Table<DocsApp>>::NAME,
            <k::Member as Table<DocsApp>>::NAME,
            <k::Document as Table<DocsApp>>::NAME,
        ]
    }

    async fn load(tx: &Transaction<'_>, t: TenantId) -> Result<k::Snapshot, DbError> {
        let counter = load::<DocsApp, k::Counter>(tx, t).await?.pop().unwrap_or_default();
        Ok(k::Snapshot {
            counter,
            projects: load::<DocsApp, _>(tx, t).await?,
            members: load::<DocsApp, _>(tx, t).await?,
            documents: load::<DocsApp, _>(tx, t).await?,
        })
    }

    async fn write(tx: &Transaction<'_>, t: TenantId, ws: &Vec<k::Write>) -> Result<(), DbError> {
        for w in ws {
            match w {
                k::Write::PutProject(p) => upsert::<DocsApp, _>(tx, t, p).await?,
                k::Write::PutMember(m) => upsert::<DocsApp, _>(tx, t, m).await?,
                k::Write::DelMember(p, u) => {
                    delete::<DocsApp, k::Member>(tx, t, &[key::<DocsApp, _>(p)?, key::<DocsApp, _>(u)?]).await?
                }
                k::Write::PutDocument(d) => upsert::<DocsApp, _>(tx, t, d).await?,
                k::Write::DelDocument(id) => delete::<DocsApp, k::Document>(tx, t, &[key::<DocsApp, _>(id)?]).await?,
                k::Write::SetCounter(c) => upsert::<DocsApp, _>(tx, t, c).await?,
            }
        }
        Ok(())
    }
}

// ---- JSON wire format (trusted boundary) ----

#[derive(Serialize, Deserialize, Clone, Copy, Debug, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum RoleJson {
    Viewer,
    Editor,
    Owner,
}

impl From<RoleJson> for k::Role {
    fn from(r: RoleJson) -> Self {
        match r {
            RoleJson::Viewer => k::Role::Viewer,
            RoleJson::Editor => k::Role::Editor,
            RoleJson::Owner => k::Role::Owner,
        }
    }
}

impl From<k::Role> for RoleJson {
    fn from(r: k::Role) -> Self {
        match r {
            k::Role::Viewer => RoleJson::Viewer,
            k::Role::Editor => RoleJson::Editor,
            k::Role::Owner => RoleJson::Owner,
        }
    }
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq)]
#[serde(tag = "cmd", rename_all = "snake_case", deny_unknown_fields)]
pub enum CommandJson {
    CreateProject { name: String },
    SetMember { project: u64, user: u64, role: RoleJson },
    RemoveMember { project: u64, user: u64 },
    CreateDocument { project: u64, title: String, body: String },
    EditDocument { doc: u64, body: String, expected_version: u64 },
    Submit { doc: u64 },
    Approve { doc: u64 },
    Publish { doc: u64 },
    DeleteDocument { doc: u64 },
    GetDocument { doc: u64 },
    ListDocuments { project: u64 },
}

impl From<CommandJson> for k::Command {
    fn from(c: CommandJson) -> Self {
        use CommandJson as J;
        let t = |s: String| s.into_bytes();
        match c {
            J::CreateProject { name } => k::Command::CreateProject { name: t(name) },
            J::SetMember { project, user, role } => k::Command::SetMember { project, user, role: role.into() },
            J::RemoveMember { project, user } => k::Command::RemoveMember { project, user },
            J::CreateDocument { project, title, body } => k::Command::CreateDocument { project, title: t(title), body: t(body) },
            J::EditDocument { doc, body, expected_version } => k::Command::EditDocument { doc, body: t(body), expected_version },
            J::Submit { doc } => k::Command::Submit { doc },
            J::Approve { doc } => k::Command::Approve { doc },
            J::Publish { doc } => k::Command::Publish { doc },
            J::DeleteDocument { doc } => k::Command::DeleteDocument { doc },
            J::GetDocument { doc } => k::Command::GetDocument { doc },
            J::ListDocuments { project } => k::Command::ListDocuments { project },
        }
    }
}

fn text(b: &[u8]) -> String {
    // Kernel text only ever comes from JSON strings, so this is lossless.
    String::from_utf8_lossy(b).into_owned()
}

fn status_str(s: k::Status) -> &'static str {
    match s {
        k::Status::Draft => "draft",
        k::Status::InReview => "in_review",
        k::Status::Approved => "approved",
        k::Status::Published => "published",
    }
}

fn doc_json(d: &k::Document) -> Json {
    json!({
        "id": d.id, "project": d.project, "author": d.author,
        "title": text(&d.title), "body": text(&d.body),
        "status": status_str(d.status), "approver": d.approver, "version": d.version,
    })
}

impl i5h_http::Api<DocsApp> for DocsStore {
    fn decode_command(body: Json) -> Result<k::Command, String> {
        serde_json::from_value::<CommandJson>(body).map(Into::into).map_err(|e| e.to_string())
    }

    fn encode_reply(r: &k::Reply) -> Json {
        match r {
            k::Reply::Created(id) => json!({ "created": id }),
            k::Reply::Done => json!({ "ok": true }),
            k::Reply::Version(v) => json!({ "version": v }),
            k::Reply::Doc(d) => doc_json(d),
            k::Reply::Docs(ds) => Json::Array(ds.iter().map(doc_json).collect()),
        }
    }

    fn encode_error(e: &k::Error) -> (StatusCode, Json) {
        let (status, code) = match e {
            k::Error::NotFound => (StatusCode::NOT_FOUND, "not_found"),
            k::Error::Forbidden => (StatusCode::FORBIDDEN, "forbidden"),
            k::Error::Conflict => (StatusCode::CONFLICT, "version_conflict"),
            k::Error::BadState => (StatusCode::CONFLICT, "bad_state"),
            k::Error::LastOwner => (StatusCode::CONFLICT, "last_owner"),
            k::Error::SelfApproval => (StatusCode::FORBIDDEN, "self_approval"),
            k::Error::Overflow => (StatusCode::INTERNAL_SERVER_ERROR, "overflow"),
        };
        (status, json!({ "error": code }))
    }
}

/// Stored idempotent replies are the JSON rendering. Replay decodes back to
/// an opaque reply that re-renders identically.
impl ReplyCodec<DocsApp> for DocsStore {
    fn fingerprint(cmd: &k::Command) -> Vec<u8> {
        format!("{cmd:?}").into_bytes()
    }

    fn encode(r: &k::Reply) -> Vec<u8> {
        serde_json::to_vec(&<DocsStore as i5h_http::Api<DocsApp>>::encode_reply(r)).unwrap_or_default()
    }

    fn decode(b: &[u8]) -> Result<k::Reply, String> {
        decode_reply(b)
    }
}

fn decode_reply(b: &[u8]) -> Result<k::Reply, String> {
    let v: Json = serde_json::from_slice(b).map_err(|e| e.to_string())?;
    let num = |f: &str| v.get(f).and_then(Json::as_u64);
    if let Some(id) = num("created") {
        return Ok(k::Reply::Created(id));
    }
    if let Some(ver) = num("version") {
        return Ok(k::Reply::Version(ver));
    }
    if v.get("ok").is_some() {
        return Ok(k::Reply::Done);
    }
    Err(format!("not a replayable reply: {v}"))
}
