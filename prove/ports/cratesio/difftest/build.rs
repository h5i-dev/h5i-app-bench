//! Copies the pinned upstream items the kernel follows, which live in crates
//! too heavy to link (Postgres, axum, GitHub API), into `$OUT_DIR/upstream_*.rs`.
//! Items are taken verbatim from `git show <REV>:<file>` of the checkout
//! `../upstream-src`, so a moved checkout cannot change what is tested.

use std::{env, fs, path::PathBuf, process::Command};

const REV: &str = "e0fc83aa64e4d53b5447576f8018e3287d4e8982";

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

fn write(name: &str, items: &[(&str, &str)]) {
    let mut out = format!("// Copied by build.rs from rust-lang/crates.io @ {REV}. Do not edit.\n");
    let mut cache: std::collections::HashMap<&str, String> = Default::default();
    for (file, head) in items {
        let src = cache.entry(file).or_insert_with(|| show(file));
        out.push_str(&format!("// --- {file}\n"));
        out.push_str(&item(src, head));
        out.push_str("\n\n");
    }
    fs::write(PathBuf::from(env::var("OUT_DIR").unwrap()).join(name), out).unwrap();
}

fn main() {
    let scopes = "crates/crates_io_database/src/models/token/scopes.rs";
    let auth = "src/auth.rs";
    let tp = "crates/crates_io_trustpub/src/access_token.rs";
    let wf = "crates/crates_io_trustpub/src/github/workflows.rs";
    write("upstream_scopes.rs", &[
        (scopes, "pub struct CrateScope"),
        (scopes, "impl TryFrom<&str> for CrateScope"),
        (scopes, "impl CrateScope {"),
    ]);
    // The methods are wrapped in their `impl` blocks again.
    let a = show(auth);
    let out = format!(
        "// Copied by build.rs from rust-lang/crates.io @ {REV}:{auth}. Do not edit.\n{}\n\nimpl AuthHeader {{\n{}\n}}\n\nimpl AuthCheck {{\n{}\n\n{}\n}}\n\n{}\n",
        item(&a, "pub struct AuthHeader"),
        item(&a, "pub async fn optional_from_request_parts"),
        item(&a, "fn endpoint_scope_matches"),
        item(&a, "fn crate_scope_matches"),
        item(&a, "pub fn ensure_not_locked"),
    );
    fs::write(PathBuf::from(env::var("OUT_DIR").unwrap()).join("upstream_auth_items.rs"), out).unwrap();
    write("upstream_trustpub.rs", &[
        (tp, "pub struct AccessToken"),
        (tp, "impl AccessToken {"),
        (tp, "impl FromStr for AccessToken"),
        (tp, "pub enum AccessTokenError"),
        (tp, "fn checksum"),
        (wf, "pub(crate) fn extract_workflow_filename"),
    ]);
    println!("cargo:rerun-if-changed=build.rs");
}
