//! PostgreSQL engine for i5h kernels.
//!
//! Per request: BEGIN SERIALIZABLE, optional tenant advisory lock, replay a
//! stored idempotent reply if any, load snapshot, run `transition`, write,
//! COMMIT. A serialization failure or lost connection restarts from BEGIN, so a
//! decision is never reused on a snapshot it was not computed from. A connection
//! lost during COMMIT is retried only under an idempotency key; otherwise the
//! caller gets `DbError::CommitUnknown`.

pub mod migrate;
pub mod outbox;
mod roles;
mod table;

pub use roles::{lockdown, lockdown_sql};
pub use table::{column_of, ddl, delete, key, load, load_rows, load_rows_where, load_where, run_planned, upsert, ColumnDef, Kind, PgField, Table, Value};
pub use i5h_sql as sql;

use deadpool_postgres::{Config, Runtime};
use i5h::{Kernel, TenantId};
use std::future::Future;
use std::marker::PhantomData;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use std::time::Duration;
use tokio_postgres::error::SqlState;
use tokio_postgres::{IsolationLevel, NoTls, Transaction};

/// The transaction a `Store` works in. It only offers the table operations
/// in this crate, so a store cannot run arbitrary SQL.
pub struct Tx<'a>(pub(crate) &'a Transaction<'a>);

impl Tx<'_> {
    /// Backend process id, so fault tests can kill this connection.
    #[cfg(feature = "testing")]
    pub async fn backend_pid(&self) -> Result<i32, DbError> {
        Ok(self.0.query_one("SELECT pg_backend_pid()", &[]).await?.get(0))
    }
}

/// Connection pool owned by an `Engine`. Opaque, so app code cannot take a
/// raw connection from it.
#[derive(Clone)]
pub struct Pool(pub(crate) deadpool_postgres::Pool);

#[derive(Debug)]
pub enum DbError {
    Postgres(tokio_postgres::Error),
    Pool(String),
    Decode(String),
    IdempotencyConflict,
    RetriesExhausted,
    /// The connection dropped during COMMIT, so it may or may not have committed.
    CommitUnknown(tokio_postgres::Error),
    /// A migration left `tenant` failing the invariant check; it was rolled back.
    InvariantViolated { tenant: u64, migrations: String },
}

impl std::fmt::Display for DbError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DbError::Postgres(e) => write!(f, "postgres: {e}"),
            DbError::Pool(e) => write!(f, "pool: {e}"),
            DbError::Decode(e) => write!(f, "decode: {e}"),
            DbError::IdempotencyConflict => write!(f, "idempotency key reused for a different command"),
            DbError::RetriesExhausted => write!(f, "too many serialization failures"),
            DbError::CommitUnknown(e) => write!(f, "commit outcome unknown: {e}"),
            DbError::InvariantViolated { tenant, migrations } => {
                write!(f, "migrations [{migrations}] break the invariants of tenant {tenant}; rolled back")
            }
        }
    }
}

impl std::error::Error for DbError {}

impl From<tokio_postgres::Error> for DbError {
    fn from(e: tokio_postgres::Error) -> Self {
        DbError::Postgres(e)
    }
}

impl DbError {
    fn code(&self) -> Option<&SqlState> {
        match self {
            DbError::Postgres(e) => e.code(),
            _ => None,
        }
    }

    /// Safe to rerun from BEGIN: the attempt certainly did not commit.
    fn is_retryable(&self) -> bool {
        match self {
            DbError::Postgres(e) => {
                e.is_closed()
                    || matches!(e.code(), Some(c) if *c == SqlState::T_R_SERIALIZATION_FAILURE
                        || *c == SqlState::T_R_DEADLOCK_DETECTED
                        || *c == SqlState::ADMIN_SHUTDOWN
                        || *c == SqlState::CRASH_SHUTDOWN)
            }
            _ => false,
        }
    }
}

/// An error from COMMIT without a server error code means the connection was lost
/// after COMMIT may have reached the server.
fn commit_error(e: tokio_postgres::Error) -> DbError {
    if e.code().is_some() {
        DbError::Postgres(e)
    } else {
        DbError::CommitUnknown(e)
    }
}

/// Maps snapshots and write sets to tables. Keep it to [`load`], [`upsert`]
/// and [`delete`] calls so the mapping stays mechanical.
pub trait Store<K: Kernel>: Send + Sync + 'static {
    /// Usually `vec![ddl::<A, Row>(), ...]`.
    fn ddl() -> Vec<String>;

    /// Names of the tables created by `ddl`, for [`lockdown`].
    fn tables() -> Vec<&'static str>;

    fn load(tx: &Tx<'_>, tenant: TenantId) -> impl Future<Output = Result<K::Snapshot, DbError>> + Send;

    /// The rows `cmd` reads. Defaults to the whole tenant; a store may load
    /// less only if the kernel's result is provably the same (a frame theorem).
    fn load_for(tx: &Tx<'_>, tenant: TenantId, cmd: &K::Command) -> impl Future<Output = Result<K::Snapshot, DbError>> + Send {
        let _ = cmd;
        Self::load(tx, tenant)
    }

    /// A later `load` must return `K::apply(before, ws)`.
    fn write(tx: &Tx<'_>, tenant: TenantId, ws: &K::WriteSet) -> impl Future<Output = Result<(), DbError>> + Send;
}

/// Needed to replay stored replies for idempotency keys.
pub trait ReplyCodec<K: Kernel>: Send + Sync + 'static {
    /// Rejects a key reused for a different command.
    fn fingerprint(cmd: &K::Command) -> Vec<u8>;
    /// Who owns a key. Keys are stored per scope, so one user cannot replay
    /// another user's reply. Must not contain `/`.
    fn scope(actor: &K::Principal) -> String;
    fn encode(reply: &K::Reply) -> Vec<u8>;
    fn decode(bytes: &[u8]) -> Result<K::Reply, String>;
}

/// Advisory lock key held while installing the schema ("i5h\0", 1).
const SCHEMA_LOCK: (i32, i32) = (0x6935_6800, 1);

pub(crate) const FRAMEWORK_TABLES: &[&str] = &["i5h_idempotency", "i5h_outbox"];

const FRAMEWORK_DDL: &str = "CREATE TABLE IF NOT EXISTS i5h_idempotency (
  tenant_id BIGINT NOT NULL,
  key TEXT NOT NULL,
  fingerprint BYTEA NOT NULL,
  reply BYTEA NOT NULL,
  PRIMARY KEY (tenant_id, key)
)";

/// One protocol step, for checking runs against the Lean model in `lean/Engine`.
/// Strings are hex so traces stay plain ASCII.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Event {
    /// A request enters the engine. `cmd` is the fingerprint (keyed) or `req<id>`.
    Start { tenant: u64, req: u64, cmd: String, key: Option<String> },
    /// The attempt's snapshot sees `ver` commits.
    Begin { tenant: u64, req: u64, ver: u64 },
    /// The kernel's verdict on that snapshot. Not a model step; feeds the checker's kernel table.
    Kernel { tenant: u64, req: u64, ver: u64, write: bool, reply: String },
    Replay { tenant: u64, req: u64, reply: String },
    Conflict { tenant: u64, req: u64 },
    Refuse { tenant: u64, req: u64 },
    /// Committed as version `ver`.
    Commit { tenant: u64, req: u64, ver: u64, reply: String },
    /// COMMIT outcome unknown; the attempt's snapshot was `ver`.
    Lost { tenant: u64, req: u64, ver: u64 },
    Abort { tenant: u64, req: u64 },
}

impl Event {
    /// One JSON object, no whitespace.
    pub fn json(&self) -> String {
        let q = |s: &str| format!("\"{s}\"");
        let key = |k: &Option<String>| k.as_deref().map(q).unwrap_or_else(|| "null".into());
        match self {
            Event::Start { tenant, req, cmd, key: k } => {
                format!(r#"{{"ev":"start","tenant":{tenant},"req":{req},"cmd":{},"key":{}}}"#, q(cmd), key(k))
            }
            Event::Begin { tenant, req, ver } => format!(r#"{{"ev":"begin","tenant":{tenant},"req":{req},"ver":{ver}}}"#),
            Event::Kernel { tenant, req, ver, write, reply } => format!(
                r#"{{"ev":"kernel","tenant":{tenant},"req":{req},"ver":{ver},"write":{write},"reply":{}}}"#,
                q(reply)
            ),
            Event::Replay { tenant, req, reply } => {
                format!(r#"{{"ev":"replay","tenant":{tenant},"req":{req},"reply":{}}}"#, q(reply))
            }
            Event::Conflict { tenant, req } => format!(r#"{{"ev":"conflict","tenant":{tenant},"req":{req}}}"#),
            Event::Refuse { tenant, req } => format!(r#"{{"ev":"refuse","tenant":{tenant},"req":{req}}}"#),
            Event::Commit { tenant, req, ver, reply } => format!(
                r#"{{"ev":"commit","tenant":{tenant},"req":{req},"ver":{ver},"reply":{}}}"#,
                q(reply)
            ),
            Event::Lost { tenant, req, ver } => format!(r#"{{"ev":"lost","tenant":{tenant},"req":{req},"ver":{ver}}}"#),
            Event::Abort { tenant, req } => format!(r#"{{"ev":"abort","tenant":{tenant},"req":{req}}}"#),
        }
    }
}

fn hex(b: &[u8]) -> String {
    b.iter().map(|x| format!("{x:02x}")).collect()
}

type Tracer = Arc<dyn Fn(Event) + Send + Sync>;

// Only with tracing: counts commits per tenant, so events carry versions.
const TRACE_DDL: &str = "CREATE TABLE IF NOT EXISTS i5h_trace_version (
  tenant_id BIGINT PRIMARY KEY,
  ver BIGINT NOT NULL
)";

/// Per-request trace context.
struct Tr<'a> {
    f: &'a Tracer,
    tenant: u64,
    req: u64,
    /// Snapshot version of the current attempt, once `Begin` was emitted.
    ver: Option<u64>,
}

#[derive(Clone, Debug)]
pub struct EngineConfig {
    pub max_attempts: u32,
    /// Advisory lock per tenant. Only reduces retries; SERIALIZABLE gives correctness.
    pub tenant_lock: bool,
}

impl Default for EngineConfig {
    fn default() -> Self {
        EngineConfig { max_attempts: 20, tenant_lock: true }
    }
}

#[derive(Default, Debug)]
pub struct EngineStats {
    pub attempts: AtomicU64,
    pub retries: AtomicU64,
    pub commits: AtomicU64,
    pub replays: AtomicU64,
}

pub struct Engine<K: Kernel, S: Store<K>> {
    pool: Pool,
    config: EngineConfig,
    pub stats: EngineStats,
    trace: Option<Tracer>,
    next_req: AtomicU64,
    _marker: PhantomData<fn() -> (K, S)>,
}

pub fn pool(url: &str, max_size: usize) -> Result<Pool, DbError> {
    let mut cfg = Config::new();
    cfg.url = Some(url.to_string());
    cfg.pool = Some(deadpool_postgres::PoolConfig::new(max_size));
    cfg.create_pool(Some(Runtime::Tokio1), NoTls).map(Pool).map_err(|e| DbError::Pool(e.to_string()))
}

struct Idem<'a, K: Kernel> {
    key: &'a str,
    fingerprint: Vec<u8>,
    encode: fn(&K::Reply) -> Vec<u8>,
    decode: fn(&[u8]) -> Result<K::Reply, String>,
}

enum Attempt<K: Kernel> {
    Done(Result<K::Reply, K::Error>),
    Replayed(K::Reply),
}

impl<K: Kernel, S: Store<K>> Engine<K, S> {
    pub fn new(pool: Pool, config: EngineConfig) -> Self {
        Engine { pool, config, stats: EngineStats::default(), trace: None, next_req: AtomicU64::new(0), _marker: PhantomData }
    }

    /// Emit an [`Event`] per protocol step. Adds a per-tenant commit counter, so
    /// every write also updates one row; call before `install_schema`.
    pub fn with_trace(mut self, f: impl Fn(Event) + Send + Sync + 'static) -> Self {
        self.trace = Some(Arc::new(f));
        self
    }

    /// Idempotent. Concurrent callers serialize on an advisory lock, since
    /// `CREATE TABLE IF NOT EXISTS` itself races on a fresh database.
    /// A dispatcher for effects queued with [`outbox::enqueue`], sharing this engine's pool.
    pub fn dispatcher<E: Send + Sync, D: outbox::Deliver<E>>(
        &self,
        registry: std::collections::HashMap<u64, E>,
        deliver: D,
        config: outbox::DispatchConfig,
    ) -> outbox::Dispatcher<E, D> {
        outbox::Dispatcher::new(self.pool.clone(), registry, deliver, config)
    }

    pub async fn install_schema(&self) -> Result<(), DbError> {
        let mut client = self.pool.0.get().await.map_err(|e| DbError::Pool(e.to_string()))?;
        let tx = client.transaction().await?;
        // Two-int form: a separate key space from the per-tenant bigint locks.
        tx.execute("SELECT pg_advisory_xact_lock($1, $2)", &[&SCHEMA_LOCK.0, &SCHEMA_LOCK.1]).await?;
        tx.batch_execute(FRAMEWORK_DDL).await?;
        tx.batch_execute(outbox::OUTBOX_DDL).await?;
        if self.trace.is_some() {
            tx.batch_execute(TRACE_DDL).await?;
        }
        for stmt in S::ddl() {
            tx.batch_execute(&stmt).await?;
        }
        tx.commit().await?;
        Ok(())
    }

    /// Committed state of a tenant, for tests. Read-only and deferrable, so it
    /// never fails with a serialization error.
    pub async fn snapshot(&self, tenant: TenantId) -> Result<K::Snapshot, DbError> {
        let mut client = self.pool.0.get().await.map_err(|e| DbError::Pool(e.to_string()))?;
        let tx = client.build_transaction().isolation_level(IsolationLevel::Serializable).read_only(true).deferrable(true).start().await?;
        let snap = S::load(&Tx(&tx), tenant).await?;
        tx.commit().await?;
        Ok(snap)
    }

    /// What `cmd` would read for this tenant, for tests of `Store::load_for`.
    pub async fn snapshot_for(&self, tenant: TenantId, cmd: &K::Command) -> Result<K::Snapshot, DbError> {
        let mut client = self.pool.0.get().await.map_err(|e| DbError::Pool(e.to_string()))?;
        let tx = client.build_transaction().isolation_level(IsolationLevel::Serializable).read_only(true).deferrable(true).start().await?;
        let snap = S::load_for(&Tx(&tx), tenant, cmd).await?;
        tx.commit().await?;
        Ok(snap)
    }

    /// Outer error: infrastructure. Inner error: the kernel refused.
    pub async fn execute(&self, actor: &K::Principal, cmd: &K::Command) -> Result<Result<K::Reply, K::Error>, DbError> {
        self.run(actor, cmd, None).await
    }

    /// At most once per `(tenant, scope, key)`. A repeated key returns the stored reply.
    /// Refusals are not stored.
    pub async fn execute_idempotent(
        &self,
        actor: &K::Principal,
        key: &str,
        cmd: &K::Command,
    ) -> Result<Result<K::Reply, K::Error>, DbError>
    where
        S: ReplyCodec<K>,
    {
        let scope = S::scope(actor);
        if scope.contains('/') {
            return Err(DbError::Decode(format!("idempotency scope {scope:?} contains '/'")));
        }
        let key = format!("{scope}/{key}");
        let idem = Idem { key: &key, fingerprint: S::fingerprint(cmd), encode: S::encode, decode: S::decode };
        self.run(actor, cmd, Some(idem)).await
    }

    async fn run(&self, actor: &K::Principal, cmd: &K::Command, idem: Option<Idem<'_, K>>) -> Result<Result<K::Reply, K::Error>, DbError> {
        let tenant = K::tenant(actor);
        let mut tr = self.trace.as_ref().map(|f| {
            let req = self.next_req.fetch_add(1, Ordering::Relaxed);
            // The kernel depends on the actor too, so the model's command is scope + fingerprint.
            let cmd = idem
                .as_ref()
                .map(|i| {
                    let scope = i.key.split('/').next().unwrap_or("");
                    format!("{}.{}", hex(scope.as_bytes()), hex(&i.fingerprint))
                })
                .unwrap_or_else(|| format!("req{req}"));
            let key = idem.as_ref().map(|i| hex(i.key.as_bytes()));
            f(Event::Start { tenant: tenant.0, req, cmd, key });
            Tr { f, tenant: tenant.0, req, ver: None }
        });
        for attempt in 0..self.config.max_attempts {
            self.stats.attempts.fetch_add(1, Ordering::Relaxed);
            let mut client = self.pool.0.get().await.map_err(|e| DbError::Pool(e.to_string()))?;
            let result = match self.lock(&client, tenant).await {
                Ok(()) => {
                    let r = self.attempt(&mut client, tenant, actor, cmd, idem.as_ref(), tr.as_mut()).await;
                    self.unlock(&client, tenant).await;
                    r
                }
                Err(e) => Err(e),
            };
            if let (Some(t), Err(e)) = (tr.as_mut(), &result) {
                if let Some(ver) = t.ver.take() {
                    let (tenant, req) = (t.tenant, t.req);
                    if matches!(e, DbError::CommitUnknown(_)) {
                        (t.f)(Event::Lost { tenant, req, ver });
                    } else if e.is_retryable() || (idem.is_some() && e.code() == Some(&SqlState::UNIQUE_VIOLATION)) {
                        (t.f)(Event::Abort { tenant, req });
                    }
                }
            }
            match result {
                Ok(Attempt::Done(r)) => {
                    if r.is_ok() {
                        self.stats.commits.fetch_add(1, Ordering::Relaxed);
                    }
                    return Ok(r);
                }
                Ok(Attempt::Replayed(r)) => {
                    self.stats.replays.fetch_add(1, Ordering::Relaxed);
                    return Ok(Ok(r));
                }
                // With a key, a retry after an unknown commit replays or reruns safely.
                Err(e)
                    if e.is_retryable()
                        || (idem.is_some()
                            && (e.code() == Some(&SqlState::UNIQUE_VIOLATION) || matches!(e, DbError::CommitUnknown(_)))) =>
                {
                    self.stats.retries.fetch_add(1, Ordering::Relaxed);
                    tracing::debug!(attempt, error = %e, "retrying transaction");
                    tokio::time::sleep(backoff(attempt)).await;
                }
                Err(e) => return Err(e),
            }
        }
        Err(DbError::RetriesExhausted)
    }

    /// Session lock taken before BEGIN, so the snapshot is read after the
    /// wait. A lost connection releases it.
    async fn lock(&self, client: &deadpool_postgres::Object, tenant: TenantId) -> Result<(), DbError> {
        if self.config.tenant_lock {
            client.execute("SELECT pg_advisory_lock($1)", &[&table::tenant_param(tenant)?]).await?;
        }
        Ok(())
    }

    async fn unlock(&self, client: &deadpool_postgres::Object, tenant: TenantId) {
        if self.config.tenant_lock {
            if let Ok(tid) = table::tenant_param(tenant) {
                let _ = client.execute("SELECT pg_advisory_unlock($1)", &[&tid]).await;
            }
        }
    }

    async fn attempt(
        &self,
        client: &mut deadpool_postgres::Object,
        tenant: TenantId,
        actor: &K::Principal,
        cmd: &K::Command,
        idem: Option<&Idem<'_, K>>,
        mut tr: Option<&mut Tr<'_>>,
    ) -> Result<Attempt<K>, DbError> {
        let tid = table::tenant_param(tenant)?;
        let tx = client.build_transaction().isolation_level(IsolationLevel::Serializable).start().await?;
        if let Some(t) = tr.as_deref_mut() {
            let row = tx.query_opt("SELECT ver FROM i5h_trace_version WHERE tenant_id = $1", &[&tid]).await?;
            let ver = row.map(|r| r.get::<_, i64>(0)).unwrap_or(0) as u64;
            (t.f)(Event::Begin { tenant: t.tenant, req: t.req, ver });
            t.ver = Some(ver);
        }
        let emit = |tr: &Option<&mut Tr<'_>>, ev: fn(u64, u64) -> Event| {
            if let Some(t) = tr {
                (t.f)(ev(t.tenant, t.req));
            }
        };
        if let Some(idem) = idem {
            let stored = tx
                .query_opt("SELECT fingerprint, reply FROM i5h_idempotency WHERE tenant_id = $1 AND key = $2", &[&tid, &idem.key])
                .await?;
            if let Some(row) = stored {
                let fp: Vec<u8> = row.try_get(0)?;
                if fp != idem.fingerprint {
                    emit(&tr, |tenant, req| Event::Conflict { tenant, req });
                    if let Some(t) = tr {
                        t.ver = None;
                    }
                    return Err(DbError::IdempotencyConflict);
                }
                let bytes: Vec<u8> = row.try_get(1)?;
                let reply = (idem.decode)(&bytes).map_err(DbError::Decode)?;
                tx.commit().await?;
                if let Some(t) = tr {
                    (t.f)(Event::Replay { tenant: t.tenant, req: t.req, reply: hex(&bytes) });
                    t.ver = None;
                }
                return Ok(Attempt::Replayed(reply));
            }
        }
        let snap = S::load_for(&Tx(&tx), tenant, cmd).await?;
        let decision = K::transition(actor, &snap, cmd);
        // Replies are only comparable when a codec exists (keyed requests).
        let encoded = match (&decision, idem) {
            (Ok((_, reply)), Some(idem)) => Some((idem.encode)(reply)),
            _ => None,
        };
        let reply_repr = encoded.as_deref().map(hex).unwrap_or_default();
        if let Some(t) = tr.as_deref() {
            let ver = t.ver.unwrap_or(0);
            (t.f)(Event::Kernel { tenant: t.tenant, req: t.req, ver, write: decision.is_ok(), reply: reply_repr.clone() });
        }
        match decision {
            Err(refusal) => {
                tx.rollback().await?;
                emit(&tr, |tenant, req| Event::Refuse { tenant, req });
                if let Some(t) = tr {
                    t.ver = None;
                }
                Ok(Attempt::Done(Err(refusal)))
            }
            Ok((ws, reply)) => {
                S::write(&Tx(&tx), tenant, &ws).await?;
                if let (Some(idem), Some(bytes)) = (idem, &encoded) {
                    tx.execute(
                        "INSERT INTO i5h_idempotency (tenant_id, key, fingerprint, reply) VALUES ($1, $2, $3, $4)",
                        &[&tid, &idem.key, &idem.fingerprint, bytes],
                    )
                    .await?;
                }
                let new_ver = match tr.as_deref() {
                    Some(_) => {
                        let row = tx
                            .query_one(
                                "INSERT INTO i5h_trace_version (tenant_id, ver) VALUES ($1, 1)
                                 ON CONFLICT (tenant_id) DO UPDATE SET ver = i5h_trace_version.ver + 1 RETURNING ver",
                                &[&tid],
                            )
                            .await?;
                        row.get::<_, i64>(0) as u64
                    }
                    None => 0,
                };
                tx.commit().await.map_err(commit_error)?;
                if let Some(t) = tr {
                    (t.f)(Event::Commit { tenant: t.tenant, req: t.req, ver: new_ver, reply: reply_repr });
                    t.ver = None;
                }
                Ok(Attempt::Done(Ok(reply)))
            }
        }
    }
}

fn backoff(attempt: u32) -> Duration {
    let cap_ms = 1u64 << attempt.min(8);
    let nanos = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).map(|d| d.subsec_nanos()).unwrap_or(0);
    Duration::from_micros(u64::from(nanos) % (cap_ms * 1000) + 100)
}
