//! Copies the pinned upstream items the server crate keeps private
//! (`wastebin_server` is a binary crate) into `$OUT_DIR/upstream_server.rs`.
//! Items are taken verbatim from `git show <REV>:<file>` of the checkout
//! `../upstream-src`, so a moved checkout cannot change what is tested.

use std::{env, fs, path::PathBuf, process::Command};

const REV: &str = "c0ec9687ba41e8806654f34841e9a739f0264ced";

fn show(path: &str) -> String {
    let repo = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap()).join("../upstream-src");
    let out = Command::new("git")
        .arg("-C")
        .arg(&repo)
        .args(["show", &format!("{REV}:{path}")])
        .output()
        .expect("git");
    assert!(out.status.success(), "pinned upstream {REV} must be available in ../upstream-src");
    String::from_utf8(out.stdout).unwrap()
}

/// The item whose first line starts (after indentation) with `head`, with
/// the attribute lines right above it, up to its matching closing brace (or
/// `;` for an item without a body). String and char literals are skipped
/// when counting braces.
fn item(src: &str, head: &str) -> String {
    let lines: Vec<&str> = src.lines().collect();
    let start = lines
        .iter()
        .position(|l| l.trim_start().starts_with(head))
        .unwrap_or_else(|| panic!("item `{head}` not found"));
    let mut first = start;
    while first > 0 && lines[first - 1].trim_start().starts_with("#[") {
        first -= 1;
    }
    let text: String = lines[start..].join("\n");
    let b = text.as_bytes();
    let mut depth = 0i32;
    let mut i = 0;
    let mut end = None;
    while i < b.len() {
        match b[i] {
            b'"' => {
                i += 1;
                while b[i] != b'"' {
                    if b[i] == b'\\' {
                        i += 1;
                    }
                    i += 1;
                }
            }
            b'\'' if i + 2 < b.len() && (b[i + 2] == b'\'' || b[i + 1] == b'\\') => {
                i += 1;
                if b[i] == b'\\' {
                    i += 1;
                }
                while b[i] != b'\'' {
                    i += 1;
                }
            }
            b'{' => depth += 1,
            b'}' => {
                depth -= 1;
                if depth == 0 {
                    end = Some(i + 1);
                    break;
                }
            }
            b';' if depth == 0 => {
                end = Some(i + 1);
                break;
            }
            _ => {}
        }
        i += 1;
    }
    let body = &text[..end.expect("unbalanced item")];
    let mut out = lines[first..start].join("\n");
    if !out.is_empty() {
        out.push('\n');
    }
    out.push_str(body);
    out
}

fn main() {
    let cache = show("crates/wastebin_server/src/cache.rs");
    let download = show("crates/wastebin_server/src/handlers/download.rs");
    let extract = show("crates/wastebin_server/src/handlers/extract.rs");
    let mut out = String::new();
    out.push_str(&format!("// Copied by build.rs from matze/wastebin @ {REV}. Do not edit.\n"));
    out.push_str("// --- crates/wastebin_server/src/cache.rs\n");
    for head in [
        "pub(crate) struct Key",
        "const MAX_EXTENSION_LEN",
        "pub(crate) fn valid_extension",
        "impl Key {",
        "impl Display for Key",
        "impl FromStr for Key",
    ] {
        out.push_str(&item(&cache, head));
        out.push_str("\n\n");
    }
    out.push_str("// --- crates/wastebin_server/src/handlers/download.rs\n");
    out.push_str(&item(&download, "fn make_content_disposition"));
    out.push_str("\n\n// --- crates/wastebin_server/src/handlers/extract.rs\n");
    for head in ["pub(crate) fn parse_uids", "pub(crate) fn serialize_uids"] {
        out.push_str(&item(&extract, head));
        out.push_str("\n\n");
    }
    let path = PathBuf::from(env::var("OUT_DIR").unwrap()).join("upstream_server.rs");
    fs::write(path, out).unwrap();
    println!("cargo:rerun-if-changed=build.rs");
}
