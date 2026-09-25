//! Core contract of i5h: a pure, verified kernel driven by an untrusted shell.
//!
//! The kernel crate has no dependencies and stays inside the Rust subset that
//! Aeneas translates to Lean. The shell authenticates, loads a snapshot, calls
//! `transition`, and commits the returned write set. See `docs/TRUST.md`.

use std::collections::HashMap;
use std::sync::Mutex;

/// An organization. Every row and every SQL statement is scoped by one.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct TenantId(pub u64);

/// Implement on a marker type in the server crate, delegating to the kernel crate.
pub trait Kernel: Send + Sync + 'static {
    type Principal: Send + Sync + Clone;
    /// One tenant's state.
    type Snapshot: Send + Sync + Clone + Default;
    type Command: Send + Sync;
    type WriteSet: Send + Sync;
    type Reply: Send + Sync;
    /// A refusal. Nothing is committed.
    type Error: Send + Sync;

    /// The only tenant this principal may read or write.
    fn tenant(actor: &Self::Principal) -> TenantId;

    /// Pure and deterministic. This is what the Lean proofs are about.
    fn transition(
        actor: &Self::Principal,
        snap: &Self::Snapshot,
        cmd: &Self::Command,
    ) -> Result<(Self::WriteSet, Self::Reply), Self::Error>;

    /// Meaning of a write set. After a commit, loading must return `apply(snap, ws)`.
    fn apply(snap: &Self::Snapshot, ws: &Self::WriteSet) -> Self::Snapshot;
}

/// Runs commands one at a time in memory. A real engine must behave like this
/// on its committed requests, in some serial order.
pub struct MemoryEngine<K: Kernel> {
    tenants: Mutex<HashMap<TenantId, K::Snapshot>>,
}

impl<K: Kernel> Default for MemoryEngine<K> {
    fn default() -> Self {
        MemoryEngine { tenants: Mutex::new(HashMap::new()) }
    }
}

impl<K: Kernel> MemoryEngine<K> {
    pub fn execute(&self, actor: &K::Principal, cmd: &K::Command) -> Result<K::Reply, K::Error> {
        let tenant = K::tenant(actor);
        let mut tenants = self.tenants.lock().unwrap();
        let snap = tenants.entry(tenant).or_default();
        let (ws, reply) = K::transition(actor, snap, cmd)?;
        *snap = K::apply(snap, &ws);
        Ok(reply)
    }

    pub fn snapshot(&self, tenant: TenantId) -> K::Snapshot {
        self.tenants.lock().unwrap().get(&tenant).cloned().unwrap_or_default()
    }
}

/// Sort rows by key, for comparing snapshots.
pub fn sorted_by_key<T: Clone, O: Ord, F: Fn(&T) -> O>(rows: &[T], key: F) -> Vec<T> {
    let mut v = rows.to_vec();
    v.sort_by_key(|r| key(r));
    v
}
