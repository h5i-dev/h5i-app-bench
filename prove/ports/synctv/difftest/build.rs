//! Copies the private upstream items the difftest calls from the pinned commit
//! (`git show <COMMIT>:<path>` in `../upstream-src`), verbatim, into `OUT_DIR`.
//! Public upstream items are called through the `synctv-core` crate itself.
use std::{env, fs, path::Path, process::Command};

const COMMIT: &str = "38970e0215753a034de6b6659be577fd7e0479c2";

fn show(path: &str) -> String {
    let out = Command::new("git")
        .args(["-C", "../upstream-src", "show", &format!("{COMMIT}:{path}")])
        .output()
        .expect("git show");
    assert!(out.status.success(), "git show {path} failed: {}", String::from_utf8_lossy(&out.stderr));
    String::from_utf8(out.stdout).expect("utf-8")
}

/// The item starting at the first line that begins with `header` (after
/// indentation), through its closing brace or semicolon.
fn item(src: &str, header: &str) -> String {
    let start = src
        .lines()
        .scan(0usize, |off, l| {
            let here = *off;
            *off += l.len() + 1;
            Some((here, l))
        })
        .find(|(_, l)| l.trim_start().starts_with(header))
        .map(|(o, _)| o)
        .unwrap_or_else(|| panic!("not found: {header}"));
    let rest = &src[start..];
    let brace = rest.find('{');
    let semi = rest.find(';');
    if let (Some(s), true) = (semi, brace.map_or(true, |b| semi.unwrap() < b)) {
        return rest[..=s].to_string() + "\n";
    }
    let b = brace.unwrap();
    let mut depth = 0i32;
    for (j, c) in rest[b..].char_indices() {
        match c {
            '{' => depth += 1,
            '}' => {
                depth -= 1;
                if depth == 0 {
                    return rest[..b + j + 1].to_string() + "\n";
                }
            }
            _ => {}
        }
    }
    panic!("unbalanced: {header}")
}

fn main() {
    let out = env::var("OUT_DIR").unwrap();
    let head = format!("// Copied from synctv-org/synctv @ {COMMIT} by build.rs. Do not edit.\n");
    let w = |name: &str, body: String| {
        fs::write(Path::new(&out).join(name), head.clone() + &body).unwrap();
    };

    w(
        "member_role_policy.rs",
        show("synctv-core/src/service/room/member_role_policy.rs"),
    );

    let kick = show("synctv-core/src/service/room/member_kick.rs");
    w(
        "member_kick.rs",
        item(&kick, "pub const MAX_KICK_COOLDOWN_SECONDS") + &item(&kick, "fn validate_kick_cooldown_seconds"),
    );

    let jwt = show("synctv-core/src/service/auth/jwt.rs");
    w("jwt_expiration.rs", item(&jwt, "fn validate_expiration"));

    println!("cargo:rerun-if-changed=build.rs");
}
