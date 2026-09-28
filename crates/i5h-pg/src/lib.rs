//! A PostgreSQL engine for i5h kernels.
//!
//! [`Engine`] runs each request in one SERIALIZABLE transaction: it loads the
//! caller's tenant through a [`Store`], calls the kernel's `transition`, writes
//! the result and commits. If the transaction fails to serialize or the
//! connection drops, the engine starts again from `BEGIN`, so a decision is
//! never applied to a snapshot it was not computed from. With an idempotency
//! key, a command runs at most once and a repeated request gets the stored
//! reply; without one, a connection lost during `COMMIT` is reported as
//! [`DbError::CommitUnknown`] because the engine cannot tell whether it landed.
//!
//! Stores only see an opaque [`Tx`], and the pool is opaque as well, so
//! application code cannot run SQL of its own.
//!
//! Each attempt reads the time from the configured [`Clock`] inside its
//! transaction and hands it to [`Kernel::stamp`](i5h::Kernel::stamp) before
//! `transition`. A retry reads the clock again, so a decision is always made
//! at the time of the attempt that commits it. With
//! [`EngineConfig::monotonic`], the engine keeps the latest committed time per
//! tenant and never uses an earlier one, so time never goes back in commit
//! order within a tenant.
//!
//! # Example
//!
//! ```ignore
//! let engine = Engine::<Calc, CalcStore>::new(pool(&database_url, 8)?, EngineConfig::default());
//! engine.install_schema().await?;
//! let reply = engine.execute(&actor, &Command::Get).await?;
//! ```

pub mod migrate;
pub mod outbox;
mod roles;
mod table;

pub use roles::{lockdown, lockdown_sql};
pub use table::{column_of, create_tables, load_table, spec, store_writes, ColumnDef, Kind, PgField, Table, Value};
pub use i5h::Timestamp;
pub use i5h_sql as sql;
pub use i5h_pgsql as pgsql;

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

/// Maps snapshots and write sets to tables. Keep it to [`load_table`] and
/// [`store_writes`] calls (`schema!`'s mapping macro generates them) so the
/// mapping stays mechanical.
pub trait Store<K: Kernel>: Send + Sync + 'static {
    /// Usually `schema_ddl()`, from [`create_tables`].
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
    /// Rejects a key reused for a different command. Leave the time out: a
    /// retried request arrives later and must still match.
    fn fingerprint(cmd: &K::Command) -> Vec<u8>;
    /// Who owns a key. Keys are stored per scope, so one user cannot replay
    /// another user's reply. Must not contain `/`.
    fn scope(actor: &K::Principal) -> String;
    fn encode(reply: &K::Reply) -> Vec<u8>;
    fn decode(bytes: &[u8]) -> Result<K::Reply, String>;
}

/// Advisory lock key held while installing the schema ("i5h\0", 1).
const SCHEMA_LOCK: (i32, i32) = (0x6935_6800, 1);

pub(crate) const FRAMEWORK_TABLES: &[&str] = &["i5h_idempotency", "i5h_outbox", "i5h_clock"];

const FRAMEWORK_DDL: &str = "CREATE TABLE IF NOT EXISTS i5h_idempotency (
  tenant_id BIGINT NOT NULL,
  key TEXT NOT NULL,
  fingerprint BYTEA NOT NULL,
  reply BYTEA NOT NULL,
  PRIMARY KEY (tenant_id, key)
);
CREATE TABLE IF NOT EXISTS i5h_clock (
  tenant_id BIGINT PRIMARY KEY,
  last BIGINT NOT NULL
)";

/// Where the engine reads the time. Every attempt reads it once, inside its
/// transaction.
#[derive(Clone, Debug, Default)]
pub enum Clock {
    /// This process's system clock. Servers on several machines use several clocks.
    #[default]
    System,
    /// PostgreSQL's `transaction_timestamp()`: one clock for every server of a database.
    Database,
    /// Always this time. For tests.
    Fixed(Timestamp),
    /// Whatever the handle was last set to. For tests that move time.
    Manual(ManualClock),
}

/// A clock that tests set by hand; clones share the time.
#[derive(Clone, Debug, Default)]
pub struct ManualClock(Arc<AtomicU64>);

impl ManualClock {
    pub fn new(t: Timestamp) -> Self {
        ManualClock(Arc::new(AtomicU64::new(t.0)))
    }

    pub fn set(&self, t: Timestamp) {
        self.0.store(t.0, Ordering::SeqCst);
    }

    pub fn get(&self) -> Timestamp {
        Timestamp(self.0.load(Ordering::SeqCst))
    }
}

#[derive(Clone, Debug)]
pub struct EngineConfig {
    pub max_attempts: u32,
    /// Advisory lock per tenant. Only reduces retries; SERIALIZABLE gives correctness.
    pub tenant_lock: bool,
    /// Where each attempt reads the time.
    pub clock: Clock,
    /// Never let time go back in commit order within a tenant. The engine
    /// keeps the latest committed time in `i5h_clock` and uses the later of
    /// it and the clock. Costs one read per attempt and one write per commit,
    /// and makes a tenant's writes conflict with each other, which the tenant
    /// lock already serializes.
    pub monotonic: bool,
}

impl Default for EngineConfig {
    fn default() -> Self {
        EngineConfig { max_attempts: 20, tenant_lock: true, clock: Clock::System, monotonic: false }
    }
}

impl EngineConfig {
    /// The database's clock, never going back. Apps whose kernels decide on
    /// time should use this.
    pub fn database_time(self) -> Self {
        EngineConfig { clock: Clock::Database, monotonic: true, ..self }
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
    _marker: PhantomData<fn() -> (K, S)>,
}

/// `url` with the app's tables in PostgreSQL schema `schema`, so apps that
/// share a database never share a table (or the idempotency and outbox
/// tables). `install_schema` creates the schema; pass the same schema in
/// `lockdown`'s admin URL.
pub fn with_schema(url: &str, schema: &str) -> Result<String, DbError> {
    roles::ident(schema)?;
    let sep = if url.contains('?') { '&' } else { '?' };
    Ok(format!("{url}{sep}options=-c%20search_path%3D{schema}"))
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
        Engine { pool, config, stats: EngineStats::default(), _marker: PhantomData }
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
        // The first schema on the search path, as set by `with_schema`.
        let path: String = tx.query_one("SELECT current_setting('search_path')", &[]).await?.get(0);
        if let Some(first) = path.split(',').next().map(|s| s.trim().trim_matches('"')) {
            if first != "$user" && first != "public" {
                tx.batch_execute(&format!("CREATE SCHEMA IF NOT EXISTS \"{}\"", roles::ident(first)?)).await?;
            }
        }
        tx.batch_execute(FRAMEWORK_DDL).await?;
        tx.batch_execute(outbox::OUTBOX_DDL).await?;
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
        for attempt in 0..self.config.max_attempts {
            self.stats.attempts.fetch_add(1, Ordering::Relaxed);
            let mut client = self.pool.0.get().await.map_err(|e| DbError::Pool(e.to_string()))?;
            let result = match self.lock(&client, tenant).await {
                Ok(()) => {
                    let r = self.attempt(&mut client, tenant, actor, cmd, idem.as_ref()).await;
                    self.unlock(&client, tenant).await;
                    r
                }
                Err(e) => Err(e),
            };
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
    ) -> Result<Attempt<K>, DbError> {
        let tid = table::tenant_param(tenant)?;
        let tx = client.build_transaction().isolation_level(IsolationLevel::Serializable).start().await?;
        let now = self.read_clock(&tx, tid).await?;
        if let Some(idem) = idem {
            let stored = tx
                .query_opt("SELECT fingerprint, reply FROM i5h_idempotency WHERE tenant_id = $1 AND key = $2", &[&tid, &idem.key])
                .await?;
            if let Some(row) = stored {
                let fp: Vec<u8> = row.try_get(0)?;
                if fp != idem.fingerprint {
                    return Err(DbError::IdempotencyConflict);
                }
                let bytes: Vec<u8> = row.try_get(1)?;
                let reply = (idem.decode)(&bytes).map_err(DbError::Decode)?;
                tx.commit().await?;
                return Ok(Attempt::Replayed(reply));
            }
        }
        let snap = S::load_for(&Tx(&tx), tenant, cmd).await?;
        let mut actor = actor.clone();
        K::stamp(&mut actor, now);
        let decision = K::transition(&actor, &snap, cmd);
        // Replies are only comparable when a codec exists (keyed requests).
        let encoded = match (&decision, idem) {
            (Ok((_, reply)), Some(idem)) => Some((idem.encode)(reply)),
            _ => None,
        };
        match decision {
            Err(refusal) => {
                tx.rollback().await?;
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
                if self.config.monotonic {
                    tx.execute(
                        "INSERT INTO i5h_clock (tenant_id, last) VALUES ($1, $2)
                         ON CONFLICT (tenant_id) DO UPDATE SET last = EXCLUDED.last",
                        &[&tid, &time_param(now)?],
                    )
                    .await?;
                }
                tx.commit().await.map_err(commit_error)?;
                Ok(Attempt::Done(Ok(reply)))
            }
        }
    }
}

impl<K: Kernel, S: Store<K>> Engine<K, S> {
    /// The attempt's time. Under `monotonic`, never before the tenant's latest
    /// commit. This transaction reads that commit's row, so a concurrent
    /// commit makes this attempt fail to serialize and retry with a new time.
    async fn read_clock(&self, tx: &Transaction<'_>, tid: i64) -> Result<Timestamp, DbError> {
        let clock = match &self.config.clock {
            Clock::System => Timestamp::now(),
            Clock::Database => {
                let row = tx
                    .query_one("SELECT (extract(epoch FROM transaction_timestamp()) * 1000000)::bigint", &[])
                    .await?;
                Timestamp(row.get::<_, i64>(0).max(0) as u64)
            }
            Clock::Fixed(t) => *t,
            Clock::Manual(m) => m.get(),
        };
        if !self.config.monotonic {
            return Ok(clock);
        }
        let last = tx.query_opt("SELECT last FROM i5h_clock WHERE tenant_id = $1", &[&tid]).await?;
        let last = Timestamp(last.map(|r| r.get::<_, i64>(0)).unwrap_or(0).max(0) as u64);
        Ok(clock.max(last))
    }
}

fn time_param(t: Timestamp) -> Result<i64, DbError> {
    i64::try_from(t.0).map_err(|_| DbError::Decode(format!("time {} does not fit in BIGINT", t.0)))
}

fn backoff(attempt: u32) -> Duration {
    let cap_ms = 1u64 << attempt.min(8);
    let nanos = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).map(|d| d.subsec_nanos()).unwrap_or(0);
    Duration::from_micros(u64::from(nanos) % (cap_ms * 1000) + 100)
}
