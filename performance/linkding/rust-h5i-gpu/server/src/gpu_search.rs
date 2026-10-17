//! Search a tenant's bookmarks with a GPU-resident scan.
//!
//! The authoritative data stays in PostgreSQL; this is a read-side index of the
//! searchable columns, packed into the GPU crate's SoA layout. `matching_ids`
//! evaluates linkding's parsed query against every row and returns the ids that
//! match. With the `gpu` feature the scan runs the `linkding_batch` kernel over
//! device-resident buffers; without it the identical predicate runs on the CPU,
//! so the server builds and is correct even without a GPU or the Rust-CUDA
//! toolchain. The matching rows are the same ones `search_sql` would select, so
//! the listing query (scope, sort, paging, count, JSON) is unchanged.
use linkding_gpu::BookmarkFacts;
use linkding_gpu::pack::{Query, Rows};

pub struct SearchIndex {
    ids: Vec<i64>,
    #[cfg_attr(feature = "gpu", allow(dead_code))]
    rows: Rows,
    #[cfg(feature = "gpu")]
    gpu: std::sync::Mutex<Gpu>,
}

#[cfg(feature = "gpu")]
struct Gpu {
    nvvm: linkding_gpu_nvvm::Nvvm,
    resident: linkding_gpu_nvvm::ResidentLinkding,
}

impl SearchIndex {
    /// Build the index from a tenant's bookmarks (id + searchable facts),
    /// uploading the packed columns to the device under the `gpu` feature.
    /// `ptx` is the compiled device module (ignored without `gpu`).
    pub fn build(bookmarks: Vec<(i64, BookmarkFacts)>, _ptx: &str) -> Result<Self, String> {
        let mut ids = Vec::with_capacity(bookmarks.len());
        let mut rows = Rows::default();
        for (id, facts) in &bookmarks {
            ids.push(*id);
            rows.push(facts);
        }
        #[cfg(feature = "gpu")]
        let gpu = {
            let nvvm = linkding_gpu_nvvm::Nvvm::new(_ptx).map_err(|e| e.to_string())?;
            let resident = linkding_gpu_nvvm::upload_linkding(&nvvm, &rows).map_err(|e| e.to_string())?;
            std::sync::Mutex::new(Gpu { nvvm, resident })
        };
        Ok(Self {
            ids,
            rows,
            #[cfg(feature = "gpu")]
            gpu,
        })
    }

    pub fn len(&self) -> usize {
        self.ids.len()
    }

    pub fn is_empty(&self) -> bool {
        self.ids.is_empty()
    }

    /// Bookmark ids whose row matches the query, in the index's row order.
    pub fn matching_ids(&self, query: &str, lax: bool) -> Result<Vec<i64>, String> {
        let q = Query::new(query, lax);
        let values = self.values(&q)?;
        Ok(self
            .ids
            .iter()
            .zip(values)
            .filter(|(_, v)| *v == 1)
            .map(|(id, _)| *id)
            .collect())
    }

    #[cfg(feature = "gpu")]
    fn values(&self, q: &Query) -> Result<Vec<u32>, String> {
        let mut gpu = self.gpu.lock().unwrap();
        let Gpu { nvvm, resident } = &mut *gpu;
        Ok(linkding_gpu_nvvm::linkding(nvvm, resident, q).map_err(|e| e.to_string())?.values)
    }

    #[cfg(not(feature = "gpu"))]
    fn values(&self, q: &Query) -> Result<Vec<u32>, String> {
        let threads = std::thread::available_parallelism().map(|n| n.get()).unwrap_or(1);
        Ok(self.rows.cpu(q, threads))
    }
}
