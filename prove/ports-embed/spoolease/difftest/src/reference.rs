//! Faithful host transcription of SpoolEase's on-SD-card allocator decision
//! logic, from `core/src/csvdb.rs` and `core/src/store.rs` at commit 3532f8d.
//! Only the *offset/length* decisions are reproduced (the actual byte writes to
//! the SD card are IO and out of scope). Upstream is ESP32 firmware and does not
//! link on the host, so this is a hand transcription, cited below.

//! `CsvDb::insert` (csvdb.rs:218) decides, for a record keyed by `id`:
//!   * if the id already exists with slot `(prev_offset, prev_length)`:
//!       - if `serialized_len <= prev_length`: overwrite in place at
//!         `prev_offset`, and set the tracked length to `serialized_len`
//!         (csvdb.rs:231-239, then `v.length = serialized_len` at :258);
//!       - else: fill the old slot with `-` and append at end of file
//!         (csvdb.rs:241-249, `final_offset = None` then `append_bytes` :253);
//!   * if the id is new: append at end of file (csvdb.rs:253).
//! `CsvDb::delete` (csvdb.rs:263) marks the slot `(offset, length)` empty and
//! drops the record.
//! `Store::add_spool` (store.rs:233) assigns `id = last_id + 1`.

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Rec {
    pub id: u32,
    pub offset: u32,
    pub length: u32,
}

#[derive(Clone, Debug, Default)]
pub struct RefDb {
    pub file_len: u32,
    pub last_id: u32,
    pub recs: Vec<Rec>,
}

impl RefDb {
    fn find(&self, id: u32) -> Option<usize> {
        self.recs.iter().position(|r| r.id == id)
    }

    /// `CsvDb::insert` for an existing/known `id`, serialized to `len` bytes.
    pub fn insert(&mut self, id: u32, len: u32) {
        match self.find(id) {
            Some(i) => {
                let prev = self.recs[i];
                if len <= prev.length {
                    // in place; tracked length shrinks to `len`
                    self.recs[i].length = len;
                } else {
                    // void old, append
                    let off = self.file_len;
                    self.file_len += len;
                    self.recs[i].offset = off;
                    self.recs[i].length = len;
                }
            }
            None => {
                let off = self.file_len;
                self.file_len += len;
                self.recs.push(Rec { id, offset: off, length: len });
            }
        }
    }

    /// `Store::add_spool`: fresh id, then insert.
    pub fn add(&mut self, len: u32) -> u32 {
        let id = self.last_id + 1;
        self.last_id = id;
        self.insert(id, len);
        id
    }

    /// `CsvDb::delete`.
    pub fn delete(&mut self, id: u32) {
        if let Some(i) = self.find(id) {
            self.recs.remove(i);
        }
    }

    /// Non-aliasing check: no two records' byte ranges overlap.
    pub fn disjoint(&self) -> bool {
        for a in 0..self.recs.len() {
            for b in (a + 1)..self.recs.len() {
                let x = self.recs[a];
                let y = self.recs[b];
                let overlap = x.offset < y.offset + y.length && y.offset < x.offset + x.length;
                if overlap {
                    return false;
                }
            }
        }
        true
    }
}
