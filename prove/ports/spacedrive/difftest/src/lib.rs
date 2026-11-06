//! spacedrive's own code at the pinned commit (copied by build.rs into
//! OUT_DIR, never committed), and the differential tests in tests.rs.
#![allow(dead_code, unused_imports)]

/// `core/src/ops/files/archive/{directory,input,job}.rs`, the parts used here.
pub mod archive {
    use std::{
        io,
        path::{Path, PathBuf},
        sync::atomic::{AtomicBool, Ordering},
    };
    use tokio::sync::mpsc;

    include!(concat!(env!("OUT_DIR"), "/archive_input.rs"));
    include!(concat!(env!("OUT_DIR"), "/archive_directory.rs"));
    include!(concat!(env!("OUT_DIR"), "/archive_job.rs"));

    pub fn seam_extract_entries(archive: &Path, format: ArchiveFormat, plan: &[(usize, PathBuf, bool)]) -> io::Result<Vec<String>> {
        let cancel = AtomicBool::new(false);
        let (tx, mut rx) = mpsc::unbounded_channel();
        extract_entries(archive, format, plan, &cancel, &tx)?;
        drop(tx);
        let mut out = Vec::new();
        while let Ok(r) = rx.try_recv() {
            out.push(match r {
                Report::Entry { index, bytes } => format!("entry {index} {bytes}"),
                Report::Failed { index, error } => format!("failed {index} {error}"),
                Report::Done(r) => format!("done {r:?}"),
            });
        }
        Ok(out)
    }
}

#[cfg(test)]
mod tests;
