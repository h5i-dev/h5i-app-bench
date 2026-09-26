//! The core types of i5h: the [`Kernel`] trait and an in-memory reference engine.
//!
//! An i5h application implements [`Kernel`] by pointing it at a pure
//! `transition` function, which decides what a command does, and an `apply`
//! function, which says what committing its writes means. Both are written in
//! the subset of Rust that Aeneas translates to Lean, so that properties of the
//! application can be proven about the code that runs.
//!
//! [`MemoryEngine`] runs a kernel in memory, one command at a time. Any real
//! engine, such as the PostgreSQL engine in `i5h-pg`, must behave like it on
//! its committed requests, which makes it useful as a reference in tests.
//!
//! # Example
//!
//! ```ignore
//! impl Kernel for Calc {
//!     type Principal = Principal;
//!     type Snapshot = Snapshot;
//!     type Command = Command;
//!     type WriteSet = Option<Memory>;
//!     type Reply = Reply;
//!     type Error = Error;
//!
//!     fn tenant(actor: &Principal) -> TenantId {
//!         TenantId(actor.org)
//!     }
//!
//!     fn transition(actor: &Principal, snap: &Snapshot, cmd: &Command) -> Result<(Option<Memory>, Reply), Error> {
//!         kernel::transition(actor, snap, cmd)
//!     }
//!
//!     fn apply(snap: &Snapshot, w: &Option<Memory>) -> Snapshot {
//!         kernel::apply(snap, w)
//!     }
//! }
//! ```

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
