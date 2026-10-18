//! linkding's shell on the h5i-app engine: the PostgreSQL store and the
//! server's configuration. Every decision about the state is in
//! `linkding_kernel`; `api` lists what the shell does besides decoding.

pub mod api;
pub mod logic;

use h5i_app_core::{Kernel, TenantId};
use h5i_app_pg::{DbError, EngineConfig, Lock, ReadSqlMode, Store, Tx};
use linkding_kernel as k;
use std::cell::Cell;

/// linkding is one site, so every caller is in this tenant.
pub const TENANT: u64 = 1;

tokio::task_local! {
    /// A paged listing's `count`. `api` sets up the cell; `LinkdingStore::load_for`
    /// fills it with the count of `k::list_count`'s read, in the listing's own
    /// transaction.
    pub static LIST_COUNT: Cell<Option<u64>>;
}

/// Marker type the framework's traits hang off.
pub struct Linkding;

impl Kernel for Linkding {
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

    fn read_only(cmd: &k::Command) -> bool {
        k::read_only(cmd)
    }
}

pub fn principal(token: Vec<u8>) -> k::Principal {
    k::Principal { org: TENANT, token }
}

// The tables, from the kernel's `schema!`.
linkding_kernel::linkding_tables!(Linkding);

pub struct LinkdingStore;

impl Store<Linkding> for LinkdingStore {
    /// The tables, and indexes for the reads of `k::reads`. They change no
    /// result, only speed.
    fn ddl() -> Vec<String> {
        use linkding_kernel::linkding_tables as c;
        let mut out = schema_ddl();
        out.push(schema_index(k::Bookmark::TABLE, &[c::Bookmark::id]));
        out.push(schema_index(k::Bookmark::TABLE, &[c::Bookmark::owner, c::Bookmark::url_norm]));
        out.push(schema_index(k::Bookmark::TABLE, &[c::Bookmark::owner, c::Bookmark::url]));
        out.push(schema_index(k::Bookmark::TABLE, &[c::Bookmark::shared, c::Bookmark::owner]));
        out.push(schema_index(k::Tag::TABLE, &[c::Tag::owner, c::Tag::name_lower]));
        out.push(schema_index(k::Tag::TABLE, &[c::Tag::name_lower]));
        out.push(schema_index(k::Link::TABLE, &[c::Link::tag]));
        out.push(schema_index(k::Bundle::TABLE, &[c::Bundle::owner]));
        out.push(schema_index(k::User::TABLE, &[c::User::username]));
        out
    }

    fn tables() -> Vec<&'static str> {
        schema_tables()
    }

    async fn load(tx: &Tx<'_>, t: TenantId) -> Result<k::Snapshot, DbError> {
        schema_load(tx, t).await
    }

    /// The rows `k::reads` names, each table by one declarative read. For a
    /// paged listing or the tag list it also counts the rows before paging
    /// (`k::list_count`), sent on the same connection as the plan's reads.
    async fn load_for(tx: &Tx<'_>, t: TenantId, actor: &k::Principal, cmd: &k::Command) -> Result<k::Snapshot, DbError> {
        // Keep the ordinary paged/list strategy. These reads benefit from
        // unique token lookups becoming scalar parameters for the indexed
        // bookmark predicate; the read plan and transaction stay the same.
        let mode = match cmd {
            k::Command::CreateBookmark { .. } => ReadSqlMode::ScalarWhenUnique,
            k::Command::List { filter, .. } if !k::paged(filter) => ReadSqlMode::ScalarWhenUnique,
            _ => tx.read_sql_mode(),
        };
        let scoped = tx.with_read_sql_mode(mode);
        let tx = &scoped;
        let count = k::list_count(actor, cmd).filter(|_| LIST_COUNT.try_with(|_| ()).is_ok());
        match (k::reads(actor, cmd), count) {
            (None, _) => schema_load(tx, t).await,
            (Some(plan), None) => schema_load_plan(tx, t, &plan).await,
            (Some(plan), Some(count)) => {
                let (snap, n) = futures_util::future::try_join(schema_load_plan(tx, t, &plan), schema_count(tx, t, &count)).await?;
                let _ = LIST_COUNT.try_with(|c| c.set(Some(n)));
                Ok(snap)
            }
        }
    }

    /// Writes queue on what they change: a bookmark, a tag, a bundle owner's
    /// list, the id counters. Only fewer retries ride on this; SERIALIZABLE
    /// orders the rest.
    fn lock_for(actor: &k::Principal, cmd: &k::Command) -> Lock {
        let counter = Lock::key("counter", &[]);
        match cmd {
            k::Command::UpdateBookmark { id, fields, .. } => {
                let mut keys = vec![Lock::key("bookmark", &id.to_be_bytes())];
                if fields.tags.is_some() {
                    keys.push(counter);
                }
                Lock::Keys(keys)
            }
            k::Command::DeleteBookmark { id } | k::Command::Archive { id, .. } => {
                Lock::Keys(vec![Lock::key("bookmark", &id.to_be_bytes())])
            }
            k::Command::DeleteTag { id } => Lock::Keys(vec![Lock::key("tag", &id.to_be_bytes())]),
            // Each takes ids from the counter row.
            k::Command::CreateBookmark { .. } | k::Command::CreateTag { .. } => Lock::Keys(vec![counter]),
            k::Command::CreateBundle { .. } | k::Command::UpdateBundle { .. } | k::Command::DeleteBundle { .. } => {
                Lock::Keys(vec![counter, Lock::key("bundles", &actor.token)])
            }
            _ => Lock::Tenant,
        }
    }

    async fn write(tx: &Tx<'_>, t: TenantId, ws: &Vec<k::Write>) -> Result<(), DbError> {
        schema_store(tx, t, ws).await
    }
}

/// How the server runs the engine.
pub fn engine_config() -> EngineConfig {
    EngineConfig::default()
}

/// Runs the server, configured by the environment: `DATABASE_URL`,
/// `DB_POOL` connections (default 32), `PORT` (default 8106). `GET /healthz`
/// answers `ok`. Tables live in the schema `h5iapp`; the server creates
/// them at start.
pub async fn serve_from_env() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL")?;
    let pool_size = std::env::var("DB_POOL").ok().and_then(|s| s.parse().ok()).unwrap_or(32);
    let port = std::env::var("PORT").unwrap_or_else(|_| "8106".into());
    let addr = format!("127.0.0.1:{port}");

    let pool = h5i_app_pg::pool(&h5i_app_pg::with_schema(&url, "h5iapp")?, pool_size)?;
    let engine = std::sync::Arc::new(h5i_app_pg::Engine::<Linkding, LinkdingStore>::new(pool, engine_config()));
    engine.install_schema().await?;
    let router = api::router(api::App { engine });
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    eprintln!("listening on {addr} pool={pool_size}");
    axum::serve(listener, router).await?;
    Ok(())
}

/// `main`: `serve_from_env` on `WEB_CONCURRENCY` worker threads (default 4).
pub fn main_from_env() -> Result<(), Box<dyn std::error::Error>> {
    let _ = tracing_subscriber::fmt().with_env_filter(tracing_subscriber::EnvFilter::from_default_env()).try_init();
    let workers = std::env::var("WEB_CONCURRENCY").ok().and_then(|s| s.parse::<usize>().ok()).filter(|n| *n > 0).unwrap_or(4);
    tokio::runtime::Builder::new_multi_thread().worker_threads(workers).enable_all().build()?.block_on(serve_from_env())
}
