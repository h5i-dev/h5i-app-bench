//! Copies spacedrive's own code at the pinned commit into OUT_DIR, so the
//! differential tests call upstream's functions, not a transcription. The
//! upstream checkout is `../upstream-src` (or `$SPACEDRIVE_SRC`); files are
//! read with `git show <commit>:<path>`, so local edits there do not count.
//!
//! Whole files are taken up to their test module. Only items the decision
//! logic does not reach are dropped (enterprise-only async IO, the permission
//! hook), and the `use` lines naming crates we do not build are redirected to
//! stand-ins in src/lib.rs. Every edit must apply exactly once, or the build fails.
use std::{env, fs, path::PathBuf, process::Command};

const COMMIT: &str = "2c4da346da529f06428fcf40488345ef8b955f15";

fn show(repo: &str, path: &str) -> String {
    let out = Command::new("git")
        .args(["-C", repo, "show", &format!("{COMMIT}:{path}")])
        .output()
        .expect("git");
    assert!(out.status.success(), "git show {path}: {}", String::from_utf8_lossy(&out.stderr));
    String::from_utf8(out.stdout).unwrap()
}

fn before_tests(src: &str) -> String {
    let i = src
        .find("\n#[cfg(test)]\nmod tests")
        .or_else(|| src.find("\n#[cfg(test)]\npub(crate) mod tests"))
        .expect("test module");
    src[..i + 1].to_string()
}

fn replace_once(src: &str, from: &str, to: &str) -> String {
    assert_eq!(src.matches(from).count(), 1, "expected exactly one {from:?}");
    src.replacen(from, to, 1)
}

/// The end (exclusive) of the item starting at `start`.
fn item_end(src: &str, start: usize) -> usize {
    let b = src.as_bytes();
    let head = src[start..].trim_start();
    let first_brace = src[start..].find('{').map(|i| start + i);
    let first_semi = src[start..].find(';').map(|i| start + i);
    let ends_at_semi = head.starts_with("use ")
        || head.starts_with("pub use ")
        || head.starts_with("const ")
        || head.starts_with("pub const ")
        || head.starts_with("static ")
        || matches!((first_semi, first_brace), (Some(s), Some(br)) if s < br)
        || first_brace.is_none();
    let mut depth = 0i32;
    let mut i = start;
    let mut in_str = false;
    while i < b.len() {
        let c = b[i];
        if in_str {
            if c == b'\\' {
                i += 1;
            } else if c == b'"' {
                in_str = false;
            }
        } else {
            match c {
                b'"' => in_str = true,
                b'[' | b'(' if ends_at_semi => depth += 1,
                b']' | b')' if ends_at_semi => depth -= 1,
                b'{' => depth += 1,
                b'}' => {
                    depth -= 1;
                    if depth == 0 && !ends_at_semi {
                        return i + 1;
                    }
                }
                b';' if depth == 0 && ends_at_semi => return i + 1,
                _ => {}
            }
        }
        i += 1;
    }
    panic!("unterminated item at {start}");
}

/// Remove every item preceded by the attribute line `attr` (and the attribute).
fn drop_attributed(src: &str, attr: &str) -> String {
    let mut s = src.to_string();
    let needle = format!("\n{attr}\n");
    let mut n = 0;
    while let Some(i) = s.find(&needle) {
        let item = i + needle.len();
        let end = item_end(&s, item);
        s.replace_range(i + 1..end, "");
        n += 1;
    }
    assert!(n > 0, "no item with {attr}");
    s
}

/// Remove the item whose first line contains `header`.
fn drop_item(src: &str, header: &str) -> String {
    let i = src.find(header).unwrap_or_else(|| panic!("not found: {header}"));
    let start = src[..i].rfind('\n').map_or(0, |j| j + 1);
    let end = item_end(src, start);
    let mut s = src.to_string();
    s.replace_range(start..end, "");
    s
}

/// The item whose first line contains `header`, through its end.
fn take_item(src: &str, header: &str) -> String {
    let i = src.find(header).unwrap_or_else(|| panic!("not found: {header}"));
    let start = src[..i].rfind('\n').map_or(0, |j| j + 1);
    src[start..item_end(src, start)].to_string() + "\n"
}

fn main() {
    let repo = env::var("SPACEDRIVE_SRC").unwrap_or_else(|_| "../upstream-src".to_string());
    println!("cargo:rerun-if-env-changed=SPACEDRIVE_SRC");
    println!("cargo:rerun-if-changed=build.rs");
    let out = PathBuf::from(env::var("OUT_DIR").unwrap());
    let head = format!("// Copied from spacedriveapp/spacedrive @ {COMMIT} by build.rs. Do not edit.\n");

    // core/src/ops/files/archive/directory.rs: the entry type and `landing`.
    let d = show(&repo, "core/src/ops/files/archive/directory.rs");
    let d = take_item(&d, "pub struct ArchiveEntry") + &take_item(&d, "impl ArchiveEntry");
    fs::write(out.join("archive_directory.rs"), format!("{head}{d}")).unwrap();

    // core/src/ops/files/archive/job.rs: the writer, verbatim.
    let j = show(&repo, "core/src/ops/files/archive/job.rs");
    let j = take_item(&j, "enum Report {") + &take_item(&j, "fn extract_entries(") + &take_item(&j, "fn zip_system_time(");
    fs::write(out.join("archive_job.rs"), format!("{head}{j}")).unwrap();
    let i = show(&repo, "core/src/ops/files/archive/input.rs");
    fs::write(out.join("archive_input.rs"), format!("{head}{}", take_item(&i, "pub enum ArchiveFormat"))).unwrap();
}
