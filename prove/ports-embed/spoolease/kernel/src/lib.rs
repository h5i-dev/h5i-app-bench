//! SpoolEase inventory store, as an h5i-app kernel for a microcontroller.
//!
//! This is the security-critical *decision logic* of SpoolEase's on-SD-card
//! inventory database, ported from the real firmware at
//! `bberrevoets/SpoolEase @ 3532f8d`:
//!
//!   * `core/src/csvdb.rs` `CsvDb::insert` / `CsvDb::delete`: the allocator that
//!     maps a spool record's `id` to a byte slot `[offset, offset+length)` in
//!     the single append/overwrite `*.db` file. `insert` overwrites in place
//!     when the new serialization fits the old slot, otherwise voids the old
//!     slot (fills it with `-`) and appends at end of file.
//!   * `core/src/store.rs` `Store::add_spool` / `edit_spool_from_web` /
//!     `delete_spool`: assigns a fresh `id = last_id + 1`, and maintains the
//!     `tag_id -> spool_id` index, "striking out" (prefixing `-`) any record
//!     that previously held an NFC tag now claimed by another spool.
//!
//! The properties proven in `proofs/` are the ones that matter for data
//! integrity on a device that loses power mid-write and shares one file
//! between every spool:
//!   * `transition` never panics / overflows on any command (no device reset);
//!   * every byte an operation writes lands in the record's *own* old slot or
//!     in fresh space past end-of-file — never in another record's slot
//!     (`no_clobber`): two spool ids never alias the same storage;
//!   * an in-place overwrite only happens when the record fits its old slot;
//!   * the file never grows past `MAX_FILE` (bounded flash/SD usage);
//!   * a fresh spool id is strictly greater than every existing id (ids are
//!     never reused, so a new spool can never shadow an old record);
//!   * each NFC tag is claimed by at most one live spool.
//!
//! Written in the Rust subset Charon + Aeneas translate to Lean 4. It uses
//! `alloc::vec::Vec` for the record index, exactly as upstream uses a heap
//! `HashMap` on the ESP32-S3's PSRAM (see DEVIATIONS.md); the extracted logic
//! is identical to a `#![no_std]` + `extern crate alloc` build.

// The Aeneas subset: explicit comparisons and matches.
#![allow(clippy::manual_range_contains)]
#![allow(clippy::match_like_matches_macro)]
#![allow(clippy::needless_return)]

use alloc::vec::Vec;

extern crate alloc;

/// Hard cap on the inventory `.db` file, in bytes. Upstream's file lives on an
/// SD card; a real cap keeps the allocator's offsets from ever overflowing.
pub const MAX_FILE: u32 = 16_777_216; // 16 MiB
/// Maximum serialized length of one CSV record row (incl. the trailing `\n`).
/// Upstream sizes its write buffer from `max_record_width`; 4 KiB is generous.
pub const MAX_REC: u32 = 4096;
/// Largest spool id we will hand out (`last_id + 1` must not overflow).
pub const MAX_ID: u32 = 0xFFFF_FFFE;

/// Who is making the request. SpoolEase's web API encrypts every body with a
/// pre-shared key (handled in the trusted framework); a request that fails to
/// decrypt never reaches the store. We model that gate as `admin`.
#[derive(Clone, Copy, PartialEq, Eq)]
pub struct Device {
    pub admin: bool,
}

/// One spool record's storage slot in the `.db` file. `tag` is the NFC tag id
/// (0 means "no tag"); upstream stores it as hex text and strikes it out with a
/// leading `-`, which we model as clearing it to 0.
#[derive(Clone, Copy, PartialEq, Eq)]
pub struct Slot {
    pub id: u32,
    pub tag: u32,
    pub offset: u32,
    pub length: u32,
}

/// The whole inventory index: the append point (`file_len`), the last id handed
/// out, and one slot per live record. Mirrors `CsvDb.records` +
/// `Store.last_spool_id`.
#[derive(Clone)]
pub struct Store {
    pub file_len: u32,
    pub last_id: u32,
    pub slots: Vec<Slot>,
}

/// A byte range in the `.db` file. `len == 0` means "no region" (nothing
/// written).
#[derive(Clone, Copy, PartialEq, Eq)]
pub struct Region {
    pub off: u32,
    pub len: u32,
}

/// What an operation writes to the file: an optional `void` region (old slot
/// overwritten with `-` padding) and the `data` region (the record's new
/// bytes, possibly padded). Either is empty when `len == 0`.
#[derive(Clone, Copy, PartialEq, Eq)]
pub struct Plan {
    pub void: Region,
    pub data: Region,
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Command {
    /// Add a brand-new spool whose serialized row is `len` bytes, optionally
    /// carrying NFC tag `tag` (0 = none).
    AddSpool { tag: u32, len: u32 },
    /// Rewrite spool `id`'s row (now `len` bytes) and set its tag to `tag`.
    EditSpool { id: u32, tag: u32, len: u32 },
    /// Delete spool `id`.
    DeleteSpool { id: u32 },
    /// Read the inventory (no write).
    Query,
}

#[derive(Clone, PartialEq, Eq)]
pub enum Reply {
    Added { id: u32, plan: Plan },
    Wrote { plan: Plan },
    Deleted { plan: Plan },
    Listing,
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Error {
    /// A record length of 0 or more than `MAX_REC`.
    BadLen,
    /// The file would grow past `MAX_FILE`, or ids are exhausted.
    Full,
    /// No such spool id.
    NotFound,
    /// The caller did not authenticate.
    Forbidden,
}

const NO_REGION: Region = Region { off: 0, len: 0 };

/// Find the slot for `id`, if any.
fn lookup(slots: &[Slot], id: u32) -> Option<Slot> {
    let mut i = 0;
    while i < slots.len() {
        if slots[i].id == id {
            return Some(slots[i]);
        }
        i += 1;
    }
    None
}

/// Does any slot already hold `id`?
fn has_id(slots: &[Slot], id: u32) -> bool {
    let mut i = 0;
    while i < slots.len() {
        if slots[i].id == id {
            return true;
        }
        i += 1;
    }
    false
}

/// Decide where a record of serialized length `len` goes, given the slot it may
/// already occupy (`prev`). Returns the record's new slot and the write plan,
/// plus the new end-of-file. This is the heart of `CsvDb::insert`.
///
/// `len` has already been range-checked to `1..=MAX_REC`.
fn place(file_len: u32, prev: Option<Slot>, len: u32) -> Result<(Slot, u32, Plan, u32), Error> {
    // `prev` carries the id/tag; `place` only decides offset/length.
    match prev {
        None => {
            if file_len > MAX_FILE - len {
                return Err(Error::Full);
            }
            let slot = Slot { id: 0, tag: 0, offset: file_len, length: len };
            let plan = Plan { void: NO_REGION, data: Region { off: file_len, len } };
            Ok((slot, file_len, plan, file_len + len))
        }
        Some(p) => {
            if len <= p.length {
                // Fits: overwrite in place. The disk write covers the whole old
                // slot (`p.length` bytes: `len` of data then `-` padding), but
                // the record's tracked length shrinks to `len`.
                let slot = Slot { id: p.id, tag: p.tag, offset: p.offset, length: len };
                let plan = Plan { void: NO_REGION, data: Region { off: p.offset, len: p.length } };
                Ok((slot, p.offset, plan, file_len))
            } else {
                // Too big: void the old slot and append at end of file.
                if file_len > MAX_FILE - len {
                    return Err(Error::Full);
                }
                let slot = Slot { id: p.id, tag: p.tag, offset: file_len, length: len };
                let plan = Plan {
                    void: Region { off: p.offset, len: p.length },
                    data: Region { off: file_len, len },
                };
                Ok((slot, file_len, plan, file_len + len))
            }
        }
    }
}

/// Rebuild `slots` with the slot for `id` replaced by `ns` (same id).
fn replace_slot(slots: &[Slot], id: u32, ns: Slot) -> Vec<Slot> {
    let mut out: Vec<Slot> = Vec::new();
    let mut i = 0;
    while i < slots.len() {
        let s = slots[i];
        if s.id == id {
            out.push(ns);
        } else {
            out.push(s);
        }
        i += 1;
    }
    out
}

/// Rebuild `slots` without the slot for `id`.
fn remove_id(slots: &[Slot], id: u32) -> Vec<Slot> {
    let mut out: Vec<Slot> = Vec::new();
    let mut i = 0;
    while i < slots.len() {
        let s = slots[i];
        if s.id != id {
            out.push(s);
        }
        i += 1;
    }
    out
}

/// Give `tag` (if non-zero) solely to `keeper`: strike it from every other slot
/// and set it on `keeper`'s slot. Mirrors the strike-out in `Store::add_spool`
/// / `update_spool`. `keeper` must already be present.
fn claim_tag(slots: &[Slot], keeper: u32, tag: u32) -> Vec<Slot> {
    let mut out: Vec<Slot> = Vec::new();
    let mut i = 0;
    while i < slots.len() {
        let mut s = slots[i];
        if s.id == keeper {
            s.tag = tag;
        } else if tag != 0 && s.tag == tag {
            s.tag = 0;
        }
        out.push(s);
        i += 1;
    }
    out
}

/// Append `slot` to a freshly built copy of `slots`.
fn append_slot(slots: &[Slot], slot: Slot) -> Vec<Slot> {
    let mut out: Vec<Slot> = Vec::new();
    let mut i = 0;
    while i < slots.len() {
        out.push(slots[i]);
        i += 1;
    }
    out.push(slot);
    out
}

fn len_ok(len: u32) -> bool {
    len >= 1 && len <= MAX_REC
}

/// The decision: from the actor, the store snapshot and a command, produce the
/// write set (`Some` new store, or `None` for a read) and the reply.
pub fn transition(actor: &Device, s: &Store, cmd: &Command) -> Result<(Option<Store>, Reply), Error> {
    match cmd {
        Command::Query => Ok((None, Reply::Listing)),
        Command::AddSpool { tag, len } => {
            if !actor.admin {
                return Err(Error::Forbidden);
            }
            if !len_ok(*len) {
                return Err(Error::BadLen);
            }
            if s.last_id >= MAX_ID {
                return Err(Error::Full);
            }
            let id = s.last_id + 1;
            let (slot0, _off, plan, file_len) = place(s.file_len, None, *len)?;
            let slot = Slot { id, tag: *tag, offset: slot0.offset, length: slot0.length };
            let appended = append_slot(&s.slots, slot);
            let slots = claim_tag(&appended, id, *tag);
            let ns = Store { file_len, last_id: id, slots };
            Ok((Some(ns), Reply::Added { id, plan }))
        }
        Command::EditSpool { id, tag, len } => {
            if !actor.admin {
                return Err(Error::Forbidden);
            }
            if !len_ok(*len) {
                return Err(Error::BadLen);
            }
            let prev = lookup(&s.slots, *id);
            match prev {
                None => Err(Error::NotFound),
                Some(p) => {
                    let (slot0, _off, plan, file_len) = place(s.file_len, Some(p), *len)?;
                    let ns_slot = Slot { id: *id, tag: *tag, offset: slot0.offset, length: slot0.length };
                    let replaced = replace_slot(&s.slots, *id, ns_slot);
                    let slots = claim_tag(&replaced, *id, *tag);
                    let ns = Store { file_len, last_id: s.last_id, slots };
                    Ok((Some(ns), Reply::Wrote { plan }))
                }
            }
        }
        Command::DeleteSpool { id } => {
            if !actor.admin {
                return Err(Error::Forbidden);
            }
            let prev = lookup(&s.slots, *id);
            match prev {
                None => Err(Error::NotFound),
                Some(p) => {
                    let slots = remove_id(&s.slots, *id);
                    let plan = Plan { void: Region { off: p.offset, len: p.length }, data: NO_REGION };
                    let ns = Store { file_len: s.file_len, last_id: s.last_id, slots };
                    Ok((Some(ns), Reply::Deleted { plan }))
                }
            }
        }
    }
}

/// Commit the write set, as `MemoryEngine::execute` does.
pub fn apply(s: &Store, w: &Option<Store>) -> Store {
    match w {
        Some(n) => n.clone(),
        None => s.clone(),
    }
}

/// `Query` writes nothing.
pub fn read_only(cmd: &Command) -> bool {
    match cmd {
        Command::Query => true,
        _ => false,
    }
}
