//! Copies openobserve's own code at the pinned commit into OUT_DIR, so the
//! differential tests call upstream's functions, not a transcription. The
//! upstream checkout is `../upstream-src` (or `$OPENOBSERVE_SRC`); files are
//! read with `git show <commit>:<path>`, so local edits there do not count.
//!
//! Whole files are taken up to their test module. Only items the decision
//! logic does not reach are dropped (enterprise-only async IO, the permission
//! hook), and the `use` lines naming crates we do not build are redirected to
//! stand-ins in src/lib.rs. Every edit must apply exactly once, or the build fails.
use std::{env, fs, path::PathBuf, process::Command};

const COMMIT: &str = "a7745479a44bb2dd6f3498b2b3902304600bb466";

fn show(repo: &str, path: &str) -> String {
    let out = Command::new("git")
        .args(["-C", repo, "show", &format!("{COMMIT}:{path}")])
        .output()
        .expect("git");
    assert!(out.status.success(), "git show {path}: {}", String::from_utf8_lossy(&out.stderr));
    String::from_utf8(out.stdout).unwrap()
}

fn before_tests(src: &str) -> String {
    let i = src.find("\n#[cfg(test)]\nmod tests").expect("test module");
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
    let repo = env::var("OPENOBSERVE_SRC").unwrap_or_else(|_| "../upstream-src".to_string());
    println!("cargo:rerun-if-env-changed=OPENOBSERVE_SRC");
    println!("cargo:rerun-if-changed=build.rs");
    let out = PathBuf::from(env::var("OUT_DIR").unwrap());
    let head = format!("// Copied from openobserve/openobserve @ {COMMIT} by build.rs. Do not edit.\n");

    // config/src/utils/delegation.rs: tokens, verbatim.
    let cfg = before_tests(&show(&repo, "src/config/src/utils/delegation.rs"));
    fs::write(out.join("config_delegation.rs"), format!("{head}{cfg}")).unwrap();

    // config/src/utils/str.rs: constant_time_eq; encryption.rs: decode_encryption_key.
    let s = show(&repo, "src/config/src/utils/str.rs");
    fs::write(out.join("config_str.rs"), format!("{head}{}", take_item(&s, "pub fn constant_time_eq"))).unwrap();
    let e = show(&repo, "src/config/src/utils/encryption.rs");
    let e = take_item(&e, "const AES_256_SIV_KEY_LEN") + &take_item(&e, "pub fn decode_encryption_key");
    fs::write(out.join("config_encryption.rs"), format!("{head}{e}")).unwrap();

    // api/common/src/auth/delegation.rs: route scopes and link facts.
    let mut api = before_tests(&show(&repo, "src/api/common/src/auth/delegation.rs"));
    api = drop_attributed(&api, "#[cfg(feature = \"enterprise\")]");
    api = drop_attributed(&api, "#[cfg(not(feature = \"enterprise\"))]");
    api = api.replace("#[cfg(any(feature = \"enterprise\", test))]\n", "");
    api = drop_item(&api, "pub(crate) async fn authorize(");
    api = replace_once(&api, "use axum::http::Method;", "use http::Method;");
    api = replace_once(&api, "use openobserve_core::auth::AuthExtractor;\n", "");
    api = replace_once(
        &api,
        "use super::validator::{AuthError, AuthValidationResult, check_permissions};",
        "use crate::stubs::AuthError;",
    );
    api = replace_once(&api, "use crate::common::meta::user::get_default_user_role;\n", "");
    fs::write(out.join("api_delegation.rs"), format!("{head}{api}")).unwrap();
}
