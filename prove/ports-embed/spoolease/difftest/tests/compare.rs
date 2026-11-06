//! Differential test: the verified kernel's allocator decisions must match the
//! hand-transcribed upstream reference (`csvdb.rs`/`store.rs` @ 3532f8d) over
//! many random add/edit/delete sequences, and both must keep records
//! non-aliasing. Deterministic seeds; testing is evidence, not a proof.

use spoolease_difftest::reference::RefDb;
use spoolease_kernel::{apply, transition, Command, Device, Store};

const ADMIN: Device = Device { admin: true };

fn run(store: &Store, cmd: &Command) -> Store {
    match transition(&ADMIN, store, cmd) {
        Ok((w, _r)) => apply(store, &w),
        Err(_) => panic!("transition refused"),
    }
}

/// A tiny deterministic LCG.
struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        self.0 >> 33
    }
    fn range(&mut self, lo: u32, hi: u32) -> u32 {
        lo + (self.next() as u32) % (hi - lo + 1)
    }
}

fn kernel_disjoint(s: &Store) -> bool {
    for a in 0..s.slots.len() {
        for b in (a + 1)..s.slots.len() {
            let x = s.slots[a];
            let y = s.slots[b];
            if x.offset < y.offset + y.length && y.offset < x.offset + x.length {
                return false;
            }
        }
    }
    true
}

fn kernel_map(s: &Store) -> Vec<(u32, u32, u32)> {
    let mut v: Vec<(u32, u32, u32)> = s.slots.iter().map(|sl| (sl.id, sl.offset, sl.length)).collect();
    v.sort();
    v
}

fn ref_map(d: &RefDb) -> Vec<(u32, u32, u32)> {
    let mut v: Vec<(u32, u32, u32)> = d.recs.iter().map(|r| (r.id, r.offset, r.length)).collect();
    v.sort();
    v
}

#[test]
fn kernel_matches_upstream_allocator() {
    for seed in 0..400u64 {
        let mut rng = Rng(seed.wrapping_mul(0x9E3779B97F4A7C15).wrapping_add(1));
        let mut store = Store::default();
        let mut rdb = RefDb::default();

        for _ in 0..120 {
            // keep the file well below MAX_FILE so neither side rejects
            let len = rng.range(1, 64);
            let op = rng.range(0, 9);
            if op < 6 || store.slots.is_empty() {
                // Add
                let newid = store.last_id + 1;
                store = run(&store, &Command::AddSpool { tag: 0, len });
                let rid = rdb.add(len);
                assert_eq!(newid, rid, "seed {seed}: id disagreement");
            } else if op < 8 {
                // Edit an existing id
                let idx = rng.range(0, store.slots.len() as u32 - 1) as usize;
                let id = store.slots[idx].id;
                store = run(&store, &Command::EditSpool { id, tag: 0, len });
                rdb.insert(id, len);
            } else {
                // Delete an existing id
                let idx = rng.range(0, store.slots.len() as u32 - 1) as usize;
                let id = store.slots[idx].id;
                store = run(&store, &Command::DeleteSpool { id });
                rdb.delete(id);
            }

            assert_eq!(store.file_len, rdb.file_len, "seed {seed}: file_len diverged");
            assert_eq!(kernel_map(&store), ref_map(&rdb), "seed {seed}: record slots diverged");
            assert!(kernel_disjoint(&store), "seed {seed}: KERNEL produced aliasing slots");
            assert!(rdb.disjoint(), "seed {seed}: reference produced aliasing slots");
        }
    }
}

#[test]
fn query_is_read_only() {
    let store = Store::default();
    let store = run(&store, &Command::AddSpool { tag: 7, len: 20 });
    let before = kernel_map(&store);
    let after = run(&store, &Command::Query);
    assert_eq!(before, kernel_map(&after), "Query must not change state");
}

#[test]
fn unauthenticated_cannot_mutate() {
    let guest = Device { admin: false };
    let store = Store::default();
    assert!(transition(&guest, &store, &Command::AddSpool { tag: 1, len: 10 }).is_err());
    assert!(transition(&guest, &store, &Command::EditSpool { id: 1, tag: 1, len: 10 }).is_err());
    assert!(transition(&guest, &store, &Command::DeleteSpool { id: 1 }).is_err());
    // but reading is open
    assert!(transition(&guest, &store, &Command::Query).is_ok());
}

#[test]
fn tag_is_unique_after_claim() {
    // Two spools claiming the same NFC tag: the second claim strikes the first.
    let mut store = Store::default();
    store = run(&store, &Command::AddSpool { tag: 42, len: 10 });
    store = run(&store, &Command::AddSpool { tag: 42, len: 10 });
    let holders = store.slots.iter().filter(|s| s.tag == 42).count();
    assert_eq!(holders, 1, "an NFC tag must be held by at most one spool");
}
