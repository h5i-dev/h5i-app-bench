//! One bounded queue owns the resident indices and their CUDA contexts on a
//! dedicated OS thread. No CUDA handle crosses a Tokio task/thread boundary.
use crate::gpu_search::SearchIndex;
use linkding_gpu::BookmarkFacts;
use std::collections::VecDeque;
use std::sync::{
    atomic::{AtomicU64, Ordering},
    Arc,
};
use tokio::sync::{mpsc, oneshot};

type Bookmarks = Vec<(i64, BookmarkFacts)>;
type Reply = Result<Option<Vec<i64>>, String>;

struct Request {
    owner: i64,
    generation: u64,
    query: String,
    lax: bool,
    bookmarks: Option<Bookmarks>,
    reply: oneshot::Sender<Reply>,
}

#[derive(Clone)]
pub struct SearchWorker {
    tx: mpsc::Sender<Request>,
    generation: Arc<AtomicU64>,
    fallbacks: Arc<AtomicU64>,
}

struct ResidentCache {
    entries: VecDeque<(i64, SearchIndex)>,
    generation: u64,
    max_entries: usize,
    max_bytes: usize,
    bytes: usize,
}

impl ResidentCache {
    fn new(max_entries: usize, max_bytes: usize) -> Self {
        Self {
            entries: VecDeque::new(),
            generation: 0,
            max_entries,
            max_bytes,
            bytes: 0,
        }
    }

    fn clear(&mut self, generation: u64) {
        self.entries.clear();
        self.bytes = 0;
        self.generation = generation;
    }

    fn evict(&mut self) {
        if let Some((_, index)) = self.entries.pop_front() {
            self.bytes -= index.bytes();
        }
    }

    fn search(&mut self, request: &mut Request, ptx: &str) -> Reply {
        if self.max_entries == 0 || self.max_bytes == 0 {
            return Err("resident search cache disabled".into());
        }
        let position = self
            .entries
            .iter()
            .position(|(owner, _)| *owner == request.owner);
        if let Some(position) = position {
            let entry = self.entries.remove(position).unwrap();
            self.entries.push_back(entry);
        } else {
            let Some(bookmarks) = request.bookmarks.take() else {
                return Ok(None);
            };
            // Bound rows before packing or uploading. Reserve for Vec growth
            // and both host/device copies; actual capacities are checked too.
            let estimate = bookmarks
                .len()
                .checked_mul(2048)
                .ok_or("index size overflow")?;
            if self.max_entries == 0 || estimate > self.max_bytes || bookmarks.len() > 1_000_000 {
                return Err("search index exceeds resident cache budget".into());
            }
            while !self.entries.is_empty()
                && (self.entries.len() >= self.max_entries
                    || self.bytes.saturating_add(estimate) > self.max_bytes)
            {
                self.evict();
            }
            let index = SearchIndex::build(bookmarks, ptx)?;
            let bytes = index.bytes();
            if bytes > self.max_bytes {
                return Err("search index exceeds resident cache budget".into());
            }
            while self.bytes.saturating_add(bytes) > self.max_bytes {
                self.evict();
            }
            self.bytes += bytes;
            self.entries.push_back((request.owner, index));
        }
        self.entries
            .back()
            .unwrap()
            .1
            .matching_ids(&request.query, request.lax)
            .map(Some)
    }
}

impl SearchWorker {
    pub fn start(
        ptx: String,
        queue: usize,
        max_entries: usize,
        max_bytes: usize,
    ) -> std::io::Result<Self> {
        let (tx, mut rx) = mpsc::channel::<Request>(queue.max(1));
        let generation = Arc::new(AtomicU64::new(0));
        let current = generation.clone();
        std::thread::Builder::new()
            .name("linkding-search".into())
            .spawn(move || {
                let mut cache = ResidentCache::new(max_entries, max_bytes);
                while let Some(mut request) = rx.blocking_recv() {
                    if request.reply.is_closed() {
                        continue;
                    }
                    let epoch = current.load(Ordering::SeqCst);
                    if cache.generation != epoch {
                        cache.clear(epoch);
                    }
                    let result = if request.generation != epoch {
                        Err("search index invalidated during request".into())
                    } else {
                        cache.search(&mut request, &ptx)
                    };
                    // A write may commit while an upload or scan is in progress.
                    // Never publish that scan as a current result after invalidation.
                    let result = if current.load(Ordering::SeqCst) != request.generation {
                        cache.clear(current.load(Ordering::SeqCst));
                        Err("search index invalidated during execution".into())
                    } else {
                        result
                    };
                    let _ = request.reply.send(result);
                }
            })?;
        Ok(Self {
            tx,
            generation,
            fallbacks: Arc::new(AtomicU64::new(0)),
        })
    }

    pub fn generation(&self) -> u64 {
        self.generation.load(Ordering::SeqCst)
    }

    /// Writes conservatively invalidate every tenant, as the previous server
    /// did. Old in-flight loads cannot repopulate the current generation.
    pub fn invalidate(&self) {
        self.generation.fetch_add(1, Ordering::SeqCst);
    }

    /// Log exponentially spaced failures so a saturated queue does not turn
    /// fallback logging into an additional request bottleneck. No query data.
    pub fn record_fallback(&self, reason: &str) {
        let count = self
            .fallbacks
            .fetch_add(1, Ordering::Relaxed)
            .wrapping_add(1);
        if count.is_power_of_two() {
            eprintln!("search SQL fallback total={count}: {reason}");
        }
    }

    /// None means cache miss; errors (including a full queue) use SQL fallback.
    pub async fn search(
        &self,
        owner: i64,
        generation: u64,
        query: String,
        lax: bool,
        bookmarks: Option<Bookmarks>,
    ) -> Reply {
        let result = self.submit(owner, generation, query, lax, bookmarks).await;
        if let Err(reason) = &result {
            self.record_fallback(reason);
        }
        result
    }

    async fn submit(
        &self,
        owner: i64,
        generation: u64,
        query: String,
        lax: bool,
        bookmarks: Option<Bookmarks>,
    ) -> Reply {
        let (reply, result) = oneshot::channel();
        self.tx
            .try_send(Request {
                owner,
                generation,
                query,
                lax,
                bookmarks,
                reply,
            })
            .map_err(|e| format!("search worker unavailable: {e}"))?;
        let result = result.await.map_err(|_| "search worker stopped")?;
        if self.generation() != generation {
            return Err("search index invalidated before response".into());
        }
        result
    }
}

#[cfg(all(test, not(feature = "gpu")))]
mod tests {
    use super::*;

    fn bookmarks() -> Bookmarks {
        vec![(91, linkding_gpu::pack::fixture(50))]
    }

    #[tokio::test]
    async fn cache_hit_and_write_invalidation_reject_an_old_load() {
        let worker = SearchWorker::start(String::new(), 2, 2, 1 << 20).unwrap();
        let epoch = worker.generation();
        assert_eq!(
            worker
                .search(1, epoch, "alpha".into(), false, None)
                .await
                .unwrap(),
            None
        );
        assert_eq!(
            worker
                .search(1, epoch, "alpha".into(), false, Some(bookmarks()))
                .await
                .unwrap(),
            Some(vec![91])
        );
        assert_eq!(
            worker
                .search(1, epoch, "alpha".into(), false, None)
                .await
                .unwrap(),
            Some(vec![91])
        );
        worker.invalidate();
        assert!(worker
            .search(1, epoch, "alpha".into(), false, Some(bookmarks()))
            .await
            .is_err());
        assert_eq!(
            worker
                .search(1, worker.generation(), "alpha".into(), false, None)
                .await
                .unwrap(),
            None
        );
    }

    #[tokio::test]
    async fn lru_eviction_and_budget_failures_leave_sql_fallback_available() {
        let worker = SearchWorker::start(String::new(), 2, 1, 4096).unwrap();
        for owner in [1, 2] {
            assert!(worker
                .search(owner, 0, "alpha".into(), false, Some(bookmarks()))
                .await
                .unwrap()
                .is_some());
        }
        assert_eq!(
            worker
                .search(1, 0, "alpha".into(), false, None)
                .await
                .unwrap(),
            None
        );
        assert!(worker
            .search(
                3,
                0,
                "alpha".into(),
                false,
                Some(vec![
                    (1, linkding_gpu::pack::fixture(1)),
                    (2, linkding_gpu::pack::fixture(2)),
                    (3, linkding_gpu::pack::fixture(3)),
                ])
            )
            .await
            .is_err());
        assert!(worker
            .search(2, 0, "alpha".into(), false, None)
            .await
            .unwrap()
            .is_some());
    }

    #[tokio::test]
    async fn a_full_queue_fails_without_waiting_for_the_worker() {
        let (tx, _rx) = mpsc::channel(1);
        let (reply, _result) = oneshot::channel();
        tx.try_send(Request {
            owner: 1,
            generation: 0,
            query: "alpha".into(),
            lax: false,
            bookmarks: None,
            reply,
        })
        .unwrap();
        let worker = SearchWorker {
            tx,
            generation: Arc::new(AtomicU64::new(0)),
            fallbacks: Arc::new(AtomicU64::new(0)),
        };
        assert!(worker
            .search(1, 0, "alpha".into(), false, None)
            .await
            .is_err());
        assert_eq!(worker.fallbacks.load(Ordering::Relaxed), 1);
    }
}

#[cfg(all(test, feature = "gpu"))]
mod gpu_tests {
    use super::*;

    #[tokio::test]
    #[ignore = "requires CUDA and LINKDING_TEST_PTX pointing to linkding_gpu_device.ptx"]
    async fn resident_gpu_worker_reuses_indices_and_rejects_row_errors() {
        let ptx = std::fs::read_to_string(std::env::var("LINKDING_TEST_PTX").unwrap()).unwrap();
        let worker = SearchWorker::start(ptx, 2, 2, 1 << 20).unwrap();
        for owner in [1, 2] {
            let rows = vec![(91, linkding_gpu::pack::fixture(50))];
            assert_eq!(
                worker
                    .search(owner, 0, "alpha".into(), false, Some(rows))
                    .await
                    .unwrap(),
                Some(vec![91])
            );
        }
        assert_eq!(
            worker
                .search(1, 0, "alpha".into(), false, None)
                .await
                .unwrap(),
            Some(vec![91])
        );
        let mut bad = linkding_gpu::pack::fixture(1);
        bad.title = vec![b'a'; 129];
        assert!(worker
            .search(3, 0, "alpha".into(), false, Some(vec![(1, bad)]))
            .await
            .is_err());
        worker.invalidate();
        assert_eq!(
            worker
                .search(1, worker.generation(), "alpha".into(), false, None)
                .await
                .unwrap(),
            None
        );
    }
}
