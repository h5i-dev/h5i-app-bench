//! PostgreSQL engine for i5h kernels.
//!
//! Per request: BEGIN SERIALIZABLE, optional tenant advisory lock, replay a
//! stored idempotent reply if any, load snapshot, run `transition`, write,
//! COMMIT. A serialization failure restarts from BEGIN, so a decision is never
//! reused on a snapshot it was not computed from.

mod table;

pub use table::{column_of, ddl, delete, key, load, upsert, ColumnDef, Kind, PgField, Table, Value};

use deadpool_postgres::{Config, Pool, Runtime};
use i5h::{Kernel, TenantId};
use std::future::Future;
use std::marker::PhantomData;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Duration;
use tokio_postgres::error::SqlState;
use tokio_postgres::{IsolationLevel, NoTls, Transaction};

pub use deadpool_postgres;
pub use tokio_postgres;

#[derive(Debug)]
pub enum DbError {
    Postgres(tokio_postgres::Error),
    Pool(String),
    Decode(String),
    IdempotencyConflict,
    RetriesExhausted,
}

impl std::fmt::Display for DbError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DbError::Postgres(e) => write!(f, "postgres: {e}"),
            DbError::Pool(e) => write!(f, "pool: {e}"),
            DbError::Decode(e) => write!(f, "decode: {e}"),
            DbError::IdempotencyConflict => write!(f, "idempotency key reused for a different command"),
            DbError::RetriesExhausted => write!(f, "too many serialization failures"),
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

    fn is_retryable(&self) -> bool {
        matches!(self.code(), Some(c) if *c == SqlState::T_R_SERIALIZATION_FAILURE || *c == SqlState::T_R_DEADLOCK_DETECTED)
    }
}

/// Maps snapshots and write sets to tables. Keep it to [`load`], [`upsert`]
/// and [`delete`] calls so the mapping stays mechanical.
pub trait Store<K: Kernel>: Send + Sync + 'static {
    /// Usually `vec![ddl::<A, Row>(), ...]`.
    fn ddl() -> Vec<String>;

    fn load(tx: &Transaction<'_>, tenant: TenantId) -> impl Future<Output = Result<K::Snapshot, DbError>> + Send;

    /// A later `load` must return `K::apply(before, ws)`.
    fn write(tx: &Transaction<'_>, tenant: TenantId, ws: &K::WriteSet) -> impl Future<Output = Result<(), DbError>> + Send;
}

/// Needed to replay stored replies for idempotency keys.
pub trait ReplyCodec<K: Kernel>: Send + Sync + 'static {
    /// Rejects a key reused for a different command.
    fn fingerprint(cmd: &K::Command) -> Vec<u8>;
    fn encode(reply: &K::Reply) -> Vec<u8>;
    fn decode(bytes: &[u8]) -> Result<K::Reply, String>;
}

const FRAMEWORK_DDL: &str = "CREATE TABLE IF NOT EXISTS i5h_idempotency (
  tenant_id BIGINT NOT NULL,
  key TEXT NOT NULL,
  fingerprint BYTEA NOT NULL,
  reply BYTEA NOT NULL,
  PRIMARY KEY (tenant_id, key)
)";

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
    _marker: PhantomData<fn() -> (K, S)>,
}

pub fn pool(url: &str, max_size: usize) -> Result<Pool, DbError> {
    let mut cfg = Config::new();
    cfg.url = Some(url.to_string());
    cfg.pool = Some(deadpool_postgres::PoolConfig::new(max_size));
    cfg.create_pool(Some(Runtime::Tokio1), NoTls).map_err(|e| DbError::Pool(e.to_string()))
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

    pub fn pool(&self) -> &Pool {
        &self.pool
    }

    pub async fn install_schema(&self) -> Result<(), DbError> {
        let client = self.pool.get().await.map_err(|e| DbError::Pool(e.to_string()))?;
        client.batch_execute(FRAMEWORK_DDL).await?;
        for stmt in S::ddl() {
            client.batch_execute(&stmt).await?;
        }
        Ok(())
    }

    /// Committed state of a tenant, for tests.
    pub async fn snapshot(&self, tenant: TenantId) -> Result<K::Snapshot, DbError> {
        let mut client = self.pool.get().await.map_err(|e| DbError::Pool(e.to_string()))?;
        let tx = client.build_transaction().isolation_level(IsolationLevel::Serializable).read_only(true).start().await?;
        let snap = S::load(&tx, tenant).await?;
        tx.commit().await?;
        Ok(snap)
    }

    /// Outer error: infrastructure. Inner error: the kernel refused.
    pub async fn execute(&self, actor: &K::Principal, cmd: &K::Command) -> Result<Result<K::Reply, K::Error>, DbError> {
        self.run(actor, cmd, None).await
    }

    /// At most once per `(tenant, key)`. A repeated key returns the stored reply.
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
        let idem = Idem { key, fingerprint: S::fingerprint(cmd), encode: S::encode, decode: S::decode };
        self.run(actor, cmd, Some(idem)).await
    }

    async fn run(&self, actor: &K::Principal, cmd: &K::Command, idem: Option<Idem<'_, K>>) -> Result<Result<K::Reply, K::Error>, DbError> {
        let tenant = K::tenant(actor);
        for attempt in 0..self.config.max_attempts {
            self.stats.attempts.fetch_add(1, Ordering::Relaxed);
            let mut client = self.pool.get().await.map_err(|e| DbError::Pool(e.to_string()))?;
            match self.attempt(&mut client, tenant, actor, cmd, idem.as_ref()).await {
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
                Err(e) if e.is_retryable() || (idem.is_some() && e.code() == Some(&SqlState::UNIQUE_VIOLATION)) => {
                    self.stats.retries.fetch_add(1, Ordering::Relaxed);
                    tracing::debug!(attempt, error = %e, "retrying transaction");
                    tokio::time::sleep(backoff(attempt)).await;
                }
                Err(e) => return Err(e),
            }
        }
        Err(DbError::RetriesExhausted)
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
        if self.config.tenant_lock {
            tx.execute("SELECT pg_advisory_xact_lock($1)", &[&tid]).await?;
        }
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
        let snap = S::load(&tx, tenant).await?;
        match K::transition(actor, &snap, cmd) {
            Err(refusal) => {
                tx.rollback().await?;
                Ok(Attempt::Done(Err(refusal)))
            }
            Ok((ws, reply)) => {
                S::write(&tx, tenant, &ws).await?;
                if let Some(idem) = idem {
                    tx.execute(
                        "INSERT INTO i5h_idempotency (tenant_id, key, fingerprint, reply) VALUES ($1, $2, $3, $4)",
                        &[&tid, &idem.key, &idem.fingerprint, &(idem.encode)(&reply)],
                    )
                    .await?;
                }
                tx.commit().await?;
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
