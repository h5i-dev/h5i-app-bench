//! Differential tests: identical inputs to upstream (copied at the pinned
//! commit) and to the kernel. Deterministic seeds; randomized testing is
//! evidence, not a proof of equivalence.
use std::path::{Component, PathBuf};

use crate::archive as up;
use spacedrive_kernel::archive as k;

/// splitmix64.
pub struct Rng(u64);
impl Rng {
    pub fn new(seed: u64) -> Self {
        Rng(seed)
    }
    pub fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    pub fn below(&mut self, n: usize) -> usize {
        (self.next() % n as u64) as usize
    }
    pub fn pick<'a, T>(&mut self, xs: &'a [T]) -> &'a T {
        &xs[self.below(xs.len())]
    }
}

fn entry(name: &str) -> up::ArchiveEntry {
    up::ArchiveEntry { index: 0, name: name.to_string(), size: 0, is_dir: false, modified_ms: None }
}

/// The segments of an upstream landing path (Unix semantics: all `Normal`).
fn segments(p: &PathBuf) -> Vec<Vec<u8>> {
    use std::os::unix::ffi::OsStrExt;
    p.components()
        .map(|c| match c {
            Component::Normal(s) => s.as_bytes().to_vec(),
            other => panic!("non-normal component {other:?} in {p:?}"),
        })
        .collect()
}

#[test]
fn landing_agrees() {
    let mut r = Rng::new(0x5d_0001);
    let atoms = ["a", "b", ".", "..", "/", "\\", "\0", "C:", "é", "x.txt", "//", "./", "../"];
    let mut kinds = [0usize; 2];
    for case in 0..200_000 {
        let n = r.below(8);
        let name: String = (0..n).map(|_| *r.pick(&atoms)).collect();
        let strip = r.below(4) as u32;
        let up = entry(&name).landing(strip);
        let kr = k::landing(name.as_bytes(), strip);
        assert_eq!(kr, up.as_ref().map(segments), "case {case}: {name:?} strip {strip}");
        kinds[up.is_some() as usize] += 1;
    }
    eprintln!("landing: {} none, {} some", kinds[0], kinds[1]);
    assert!(kinds[0] > 10_000 && kinds[1] > 10_000);
}

/// FINDINGS F1. A `.tar.zst` whose first entry is a symlink `lnk -> <outside>`
/// and whose second entry is `lnk/pwned.txt`: both land beneath the
/// destination by `landing`, and upstream's own `extract_entries` (verbatim)
/// writes the second through the symlink, outside the destination.
#[test]
fn tar_symlink_entry_writes_outside_destination() {
    let root = std::env::temp_dir().join(format!("sd-tar-escape-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&root);
    let dest = root.join("dest");
    let outside = root.join("outside");
    std::fs::create_dir_all(&dest).unwrap();
    std::fs::create_dir_all(&outside).unwrap();

    let archive = root.join("evil.tar.zst");
    {
        let file = std::fs::File::create(&archive).unwrap();
        let enc = zstd::stream::write::Encoder::new(file, 3).unwrap().auto_finish();
        let mut b = tar::Builder::new(enc);
        let mut h = tar::Header::new_gnu();
        h.set_entry_type(tar::EntryType::Symlink);
        h.set_size(0);
        h.set_mode(0o777);
        b.append_link(&mut h, "lnk", &outside).unwrap();
        let data = b"pwned";
        let mut h = tar::Header::new_gnu();
        h.set_size(data.len() as u64);
        h.set_mode(0o644);
        b.append_data(&mut h, "lnk/pwned.txt", &data[..]).unwrap();
        b.into_inner().unwrap();
    }

    // The plan as `decide` (plan.rs) builds it for a fresh destination:
    // every entry lands, nothing exists yet, so each is a Create.
    let names = [("lnk", false), ("lnk/pwned.txt", false)];
    let plan: Vec<(usize, PathBuf, bool)> = names
        .iter()
        .enumerate()
        .map(|(i, (name, is_dir))| (i, dest.join(entry(name).landing(0).expect("lands")), *is_dir))
        .collect();
    let reports = up::seam_extract_entries(&archive, up::ArchiveFormat::TarZstd, &plan).unwrap();
    eprintln!("reports: {reports:?}");
    let escaped = outside.join("pwned.txt");
    assert!(escaped.exists(), "expected a write outside the destination");
    assert_eq!(std::fs::read(&escaped).unwrap(), b"pwned");
    let _ = std::fs::remove_dir_all(&root);
}
